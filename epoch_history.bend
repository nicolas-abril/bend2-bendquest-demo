# Exact mixed-history prefixes ending at the first actual respawn.
import Base
import ./numeric.bend as N
import ./combat_history.bend as H
import ./permanent_history.bend as PH
import ./tick_life.bend as TL
import ./live_tick.bend as Tick
import ./live_combat.bend as L
import ./live_dead.bend as LD
import ./dead_rewards.bend as Dead
import ./combat.bend as C
import ./monsters.bend as M
import ./vitals.bend as V
import ./ai.bend as A
import ./roster.bend as R
import ./zones.bend as Z
import ./identity.bend as I
import ./combat_targets.bend as Member
import ./battle.bend as B
import ./terrain.bend as T
import ./simulation.bend as S
import ./world_clock.bend as Clock
import ./seeded_world.bend as SW
import ./sessions.bend as Sess

type Epoch.Path<-entries: List<&2,H.History.Entry>,-world: T.Terrain.World,-last: T.Terrain.World> is Data:
  Epoch.End{start: T.Terrain.World,world_same: {start == world : T.Terrain.World},empty: {entries == Nil{} : List<&2,H.History.Entry>},same: {start == last : T.Terrain.World}}
  Epoch.Next{start: T.Terrain.World,world_same: {start == world : T.Terrain.World},operation: H.History.Operation,rest: List<&2,H.History.Entry>,shape: {entries == Con{H.History.Entry{start,operation,H.History.step(start,operation)},rest} : List<&2,H.History.Entry>},tail: Epoch.Path<rest,H.History.step(start,operation),last>}

type Epoch.Record<-run: H.History.Run,-world: T.Terrain.World> is Data:
  Epoch.Record{actual: H.History.Run,same: {actual == run : H.History.Run},path: Epoch.Path<H.History.entries(actual),world,H.History.world(actual)>}

law Epoch.record_add:
  for +world: T.Terrain.World
  for +operation: H.History.Operation
  for -run: H.History.Run
  for +record: Epoch.Record<run,H.History.step(world,operation)>
  Epoch.Record<H.History.prepend(H.History.Entry{world,operation,H.History.step(world,operation)},run),world>

def Epoch.record_add(world,operation,run,record):
  match record:
    case Epoch.Record{actual,same,path}:
      %same : Epoch.Record<H.History.prepend(H.History.Entry{world,operation,H.History.step(world,operation)},_),world>
      Epoch.Record{H.History.prepend(H.History.Entry{world,operation,H.History.step(world,operation)},actual),{==},Epoch.Next{world,{==},operation,H.History.entries(actual),{==},path}}

law Epoch.record:
  for requests: List<&1,H.History.Request>
  for +world: T.Terrain.World
  Epoch.Record<H.History.trace(requests,world),world>

def Epoch.record(requests,world):
  match requests:
    case Nil{}: Epoch.Record{H.History.Run{world,Nil{}},{==},Epoch.End{world,{==},{==},{==}}}
    case Con{head,rest}:
      match head:
        case H.History.TickRequest{timer}:
          +operation = {H.History.Tick{timer} : H.History.Operation}
          Epoch.record_add(world,operation,H.History.trace(rest,H.History.step(world,operation)),Epoch.record(rest,H.History.step(world,operation)))
        case H.History.CommandRequest{now,kind,pid,score,planner}:
          +now = now
          +kind = kind
          +pid = pid
          +score = score
          +plan = planner(L.LiveCombat.prepare(Clock.WorldClock.set(world,now),kind,pid,score))
          +operation = {H.History.Command{now,kind,pid,score,plan} : H.History.Operation}
          Epoch.record_add(world,operation,H.History.trace(rest,H.History.step(world,operation)),Epoch.record(rest,H.History.step(world,operation)))

# Every tick carries the real plan and updated full record. No future reward
# exclusion is asserted after Birth; its untouched rest is explicitly retained.
type Epoch.Follow<-entries: List<&2,H.History.Entry>,-world: T.Terrain.World,-monster: M.Monsters.State> is Data:
  Epoch.Done{empty: {entries == Nil{} : List<&2,H.History.Entry>},inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>,unique: I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(world))),dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}}
  Epoch.Birth{timer: U32,rest: List<&2,H.History.Entry>,shape: {entries == Con{H.History.Entry{world,H.History.Tick{timer},H.History.step(world,H.History.Tick{timer})},rest} : List<&2,H.History.Entry>},zone: Z.Zones.Valid<R.Roster.zone_of(monster)>,inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>,dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32},mode: Maybe<&2,A.AI.Plan>,chosen: {mode == TL.TickLife.decision(world,timer,monster,zone,inside) : Maybe<&2,A.AI.Plan>},tracked: TL.TickLife.Tracked<monster,mode,S.Simulation.monsters(T.Terrain.simulation(H.History.step(world,H.History.Tick{timer})))>,born: {TL.TickLife.event(monster,mode) == True{} : Bool}}
  Epoch.Wait{timer: U32,rest: List<&2,H.History.Entry>,shape: {entries == Con{H.History.Entry{world,H.History.Tick{timer},H.History.step(world,H.History.Tick{timer})},rest} : List<&2,H.History.Entry>},zone: Z.Zones.Valid<R.Roster.zone_of(monster)>,inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>,dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32},mode: Maybe<&2,A.AI.Plan>,chosen: {mode == TL.TickLife.decision(world,timer,monster,zone,inside) : Maybe<&2,A.AI.Plan>},tracked: TL.TickLife.Tracked<monster,mode,S.Simulation.monsters(T.Terrain.simulation(H.History.step(world,H.History.Tick{timer})))>,none: {TL.TickLife.event(monster,mode) == False{} : Bool},same_id: {R.Roster.id(TL.TickLife.after(monster,mode)) == R.Roster.id(monster) : U32},tail: Epoch.Follow<rest,H.History.step(world,H.History.Tick{timer}),TL.TickLife.after(monster,mode)>}
  Epoch.Command{now: U32,kind: C.Combat.Kind,pid: U32,score: U32,plan: L.LiveCombat.Plan,rest: List<&2,H.History.Entry>,shape: {entries == Con{H.History.Entry{world,H.History.Command{now,kind,pid,score,plan},H.History.step(world,H.History.Command{now,kind,pid,score,plan})},rest} : List<&2,H.History.Entry>},dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32},actual: L.LiveCombat.Result,same: {actual == L.LiveCombat.at(Clock.WorldClock.set(world,now),kind,pid,score,plan) : L.LiveCombat.Result},safe: LD.LiveDead.Safe<monster,actual>,tail: Epoch.Follow<rest,H.History.step(world,H.History.Command{now,kind,pid,score,plan}),monster>}

law Epoch.wait_from:
  for +world: T.Terrain.World
  for +timer: U32
  for +rest: List<&2,H.History.Entry>
  for +monster: M.Monsters.State
  for +zone: Z.Zones.Valid<R.Roster.zone_of(monster)>
  for +inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  for +mode: Maybe<&2,A.AI.Plan>
  for +chosen: {mode == TL.TickLife.decision(world,timer,monster,zone,inside) : Maybe<&2,A.AI.Plan>}
  for +tracked: TL.TickLife.Tracked<monster,mode,S.Simulation.monsters(T.Terrain.simulation(H.History.step(world,H.History.Tick{timer})))>
  for +none: {TL.TickLife.event(monster,mode) == False{} : Bool}
  for tail: (@+after: M.Monsters.State -> @+present: Member.Targets.In<after,S.Simulation.monsters(T.Terrain.simulation(H.History.step(world,H.History.Tick{timer})))> -> @+is_dead: {V.Vitals.dead(M.Monsters.vitals(after)) == 1 : U32} -> Epoch.Follow<rest,H.History.step(world,H.History.Tick{timer}),after>)
  Epoch.Follow<Con{H.History.Entry{world,H.History.Tick{timer},H.History.step(world,H.History.Tick{timer})},rest},world,monster>

def Epoch.wait_from(world,timer,rest,monster,zone,inside,dead,mode,chosen,tracked,none,tail):
  match tracked:
    case TL.TickLife.Tracked{present,key,status,quiet,unique}:
      +tracked = {TL.TickLife.Tracked{present,key,status,quiet,unique} : TL.TickLife.Tracked<monster,mode,S.Simulation.monsters(T.Terrain.simulation(H.History.step(world,H.History.Tick{timer})))>}
      Epoch.Wait{timer,rest,{==},zone,inside,dead,mode,chosen,tracked,none,TL.TickLife.after_id(monster,mode),tail(TL.TickLife.after(monster,mode),present,TL.TickLife.no_event_dead(monster,mode,S.Simulation.monsters(T.Terrain.simulation(H.History.step(world,H.History.Tick{timer}))),tracked,none))}

law Epoch.tick_branch:
  for +born: Bool
  for +world: T.Terrain.World
  for +timer: U32
  for +rest: List<&2,H.History.Entry>
  for +monster: M.Monsters.State
  for +zone: Z.Zones.Valid<R.Roster.zone_of(monster)>
  for +inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  for +mode: Maybe<&2,A.AI.Plan>
  for +chosen: {mode == TL.TickLife.decision(world,timer,monster,zone,inside) : Maybe<&2,A.AI.Plan>}
  for +same: {TL.TickLife.event(monster,mode) == born : Bool}
  for +tracked: TL.TickLife.Tracked<monster,mode,S.Simulation.monsters(T.Terrain.simulation(H.History.step(world,H.History.Tick{timer})))>
  for tail: (@+after: M.Monsters.State -> @+present: Member.Targets.In<after,S.Simulation.monsters(T.Terrain.simulation(H.History.step(world,H.History.Tick{timer})))> -> @+is_dead: {V.Vitals.dead(M.Monsters.vitals(after)) == 1 : U32} -> Epoch.Follow<rest,H.History.step(world,H.History.Tick{timer}),after>)
  Epoch.Follow<Con{H.History.Entry{world,H.History.Tick{timer},H.History.step(world,H.History.Tick{timer})},rest},world,monster>

def Epoch.tick_branch(born,world,timer,rest,monster,zone,inside,dead,mode,chosen,same,tracked,tail):
  match born:
    case True{}: Epoch.Birth{timer,rest,{==},zone,inside,dead,mode,chosen,tracked,same}
    case False{}:
      Epoch.wait_from(world,timer,rest,monster,zone,inside,dead,mode,chosen,tracked,same,tail)

law Epoch.step_follow:
  for +world: T.Terrain.World
  for +operation: H.History.Operation
  for +rest: List<&2,H.History.Entry>
  for +bounds: PH.Permanent.Bounds<world>
  for tail: (@+monster: M.Monsters.State -> @+inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(H.History.step(world,operation)))> -> @+dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32} -> Epoch.Follow<rest,H.History.step(world,operation),monster>)
  for +monster: M.Monsters.State
  for +inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  Epoch.Follow<Con{H.History.Entry{world,operation,H.History.step(world,operation)},rest},world,monster>

def Epoch.step_follow(world,operation,rest,bounds,tail,monster,inside,dead):
  match operation:
    case H.History.Tick{timer}:
      match bounds:
        case PH.Permanent.Bounds{zones,unique}:
          +zone = PH.Permanent.member_zone(monster,S.Simulation.monsters(T.Terrain.simulation(world)),inside,zones)
          +mode = TL.TickLife.decision(world,timer,monster,zone,inside)
          Epoch.tick_branch(TL.TickLife.event(monster,mode),world,timer,rest,monster,zone,inside,dead,mode,{==},{==},TL.TickLife.run(world,timer,monster,zone,inside,dead,zones,unique),tail)
    case H.History.Command{now,kind,pid,score,plan}:
      match bounds:
        case PH.Permanent.Bounds{zones,unique}:
          +safe = LD.LiveDead.timed_safe(world,now,kind,pid,score,plan,monster,inside,unique,dead)
          LD.LiveDead.eliminate(Epoch.Follow<Con{H.History.Entry{world,H.History.Command{now,kind,pid,score,plan},H.History.step(world,H.History.Command{now,kind,pid,score,plan})},rest},world,monster>,monster,L.LiveCombat.at(Clock.WorldClock.set(world,now),kind,pid,score,plan),safe,(present => (next_unique => (clear => Epoch.Command{now,kind,pid,score,plan,rest,{==},dead,L.LiveCombat.at(Clock.WorldClock.set(world,now),kind,pid,score,plan),{==},safe,tail(monster,present,dead)}))))

law Epoch.empty:
  for +world: T.Terrain.World
  for +bounds: PH.Permanent.Bounds<world>
  for +monster: M.Monsters.State
  for +inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  Epoch.Follow<Nil{},world,monster>

def Epoch.empty(world,bounds,monster,inside,dead):
  match bounds:
    case PH.Permanent.Bounds{zones,unique}: Epoch.Done{{==},inside,unique,dead}

law Epoch.follow:
  for -entries: List<&2,H.History.Entry>
  for -world: T.Terrain.World
  for -last: T.Terrain.World
  for +states: List<&2,Sess.Sessions.State>
  for +path: Epoch.Path<entries,world,last>
  for +valid: SW.SeededWorld.OK<world,states>
  (@+monster: M.Monsters.State -> @+inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))> -> @+dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32} -> Epoch.Follow<entries,world,monster>)

def Epoch.follow(entries,world,last,states,path,valid):
  match path:
    case Epoch.End{start,world_same,empty,same}:
      %world_same : (@+monster: M.Monsters.State -> @+inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(_))> -> @+dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32} -> Epoch.Follow<entries,_,monster>)
      +valid = {(%Equal.sym(T.Terrain.World,start,world,world_same) : SW.SeededWorld.OK<_,states>; valid) : SW.SeededWorld.OK<start,states>}
      %Equal.sym(List<&2,H.History.Entry>,entries,Nil{},empty) : (@+monster: M.Monsters.State -> @+inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(start))> -> @+dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32} -> Epoch.Follow<_,start,monster>)
      (monster => (inside => (dead => Epoch.empty(start,PH.Permanent.bounds(start,states,valid),monster,inside,dead))))
    case Epoch.Next{start,world_same,operation,rest,shape,tail}:
      %world_same : (@+monster: M.Monsters.State -> @+inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(_))> -> @+dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32} -> Epoch.Follow<entries,_,monster>)
      +valid = {(%Equal.sym(T.Terrain.World,start,world,world_same) : SW.SeededWorld.OK<_,states>; valid) : SW.SeededWorld.OK<start,states>}
      %Equal.sym(List<&2,H.History.Entry>,entries,Con{H.History.Entry{start,operation,H.History.step(start,operation)},rest},shape) : (@+monster: M.Monsters.State -> @+inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(start))> -> @+dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32} -> Epoch.Follow<_,start,monster>)
      +bounds = PH.Permanent.bounds(start,states,valid)
      later = Epoch.follow(rest,H.History.step(start,operation),last,states,tail,H.History.step_seeded(start,operation,states,valid))
      (monster => (inside => (dead => Epoch.step_follow(start,operation,rest,bounds,later,monster,inside,dead))))

type Epoch.Report<-run: H.History.Run,-world: T.Terrain.World,-monster: M.Monsters.State> is Data:
  Epoch.Report{actual: H.History.Run,same: {actual == run : H.History.Run},follow: Epoch.Follow<H.History.entries(actual),world,monster>}

law Epoch.from_record:
  for -run: H.History.Run
  for +world: T.Terrain.World
  for +states: List<&2,Sess.Sessions.State>
  for +monster: M.Monsters.State
  for +record: Epoch.Record<run,world>
  for +valid: SW.SeededWorld.OK<world,states>
  for +inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  Epoch.Report<run,world,monster>

def Epoch.from_record(run,world,states,monster,record,valid,inside,dead):
  match record:
    case Epoch.Record{actual,same,path}: Epoch.Report{actual,same,Epoch.follow(H.History.entries(actual),world,H.History.world(actual),states,path,valid)(monster,inside,dead)}

law Epoch.report:
  for requests: List<&1,H.History.Request>
  for +world: T.Terrain.World
  for +states: List<&2,Sess.Sessions.State>
  for +monster: M.Monsters.State
  for +valid: SW.SeededWorld.OK<world,states>
  for +inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  Epoch.Report<H.History.trace(requests,world),world,monster>

def Epoch.report(requests,world,states,monster,valid,inside,dead):
  Epoch.from_record(H.History.trace(requests,world),world,states,monster,Epoch.record(requests,world),valid,inside,dead)


def Epoch.concat(left: List<&2,H.History.Entry>,right: List<&2,H.History.Entry>) -> List<&2,H.History.Entry>:
  match left:
    case Nil{}: right
    case Con{head,rest}: Con{head,Epoch.concat(rest,right)}

# The prefix producer is structurally recursive in its certificate. Its runtime
# world/monster arguments are supplied after that recursion, matching the indices.
def Epoch.prefix(-entries: List<&2,H.History.Entry>,-world: T.Terrain.World,-monster: M.Monsters.State,follow: Epoch.Follow<entries,world,monster>) -> (@+start: T.Terrain.World -> @+current: M.Monsters.State -> List<&2,H.History.Entry>):
  match follow:
    case Epoch.Done{empty,inside,unique,dead}: (start => (current => Nil{}))
    case Epoch.Birth{timer,rest,shape,zone,inside,dead,mode,chosen,tracked,born}:
      +operation = {H.History.Tick{timer} : H.History.Operation}
      (start => (current => [H.History.Entry{start,operation,H.History.step(start,operation)}]))
    case Epoch.Wait{timer,rest,shape,zone,inside,dead,mode,chosen,tracked,none,same_id,tail}:
      later = Epoch.prefix(rest,H.History.step(world,H.History.Tick{timer}),TL.TickLife.after(monster,mode),tail)
      +operation = {H.History.Tick{timer} : H.History.Operation}
      +mode = mode
      (start => (current => Con{H.History.Entry{start,operation,H.History.step(start,operation)},later(H.History.step(start,operation),TL.TickLife.after(current,mode))}))
    case Epoch.Command{now,kind,pid,score,plan,rest,shape,dead,actual,same,safe,tail}:
      later = Epoch.prefix(rest,H.History.step(world,H.History.Command{now,kind,pid,score,plan}),monster,tail)
      +operation = {H.History.Command{now,kind,pid,score,plan} : H.History.Operation}
      (start => (current => Con{H.History.Entry{start,operation,H.History.step(start,operation)},later(H.History.step(start,operation),current)}))

def Epoch.remaining(-entries: List<&2,H.History.Entry>,-world: T.Terrain.World,-monster: M.Monsters.State,follow: Epoch.Follow<entries,world,monster>) -> List<&2,H.History.Entry>:
  match follow:
    case Epoch.Done{empty,inside,unique,dead}: Nil{}
    case Epoch.Birth{timer,rest,shape,zone,inside,dead,mode,chosen,tracked,born}: rest
    case Epoch.Wait{timer,rest,shape,zone,inside,dead,mode,chosen,tracked,none,same_id,tail}: Epoch.remaining(rest,H.History.step(world,H.History.Tick{timer}),TL.TickLife.after(monster,mode),tail)
    case Epoch.Command{now,kind,pid,score,plan,rest,shape,dead,actual,same,safe,tail}: Epoch.remaining(rest,H.History.step(world,H.History.Command{now,kind,pid,score,plan}),monster,tail)

def Epoch.notices(-entries: List<&2,H.History.Entry>,-world: T.Terrain.World,-monster: M.Monsters.State,follow: Epoch.Follow<entries,world,monster>) -> List<&2,B.Battle.Notice>:
  match follow:
    case Epoch.Done{empty,inside,unique,dead}: Nil{}
    case Epoch.Birth{timer,rest,shape,zone,inside,dead,mode,chosen,tracked,born}: Nil{}
    case Epoch.Wait{timer,rest,shape,zone,inside,dead,mode,chosen,tracked,none,same_id,tail}: Epoch.notices(rest,H.History.step(world,H.History.Tick{timer}),TL.TickLife.after(monster,mode),tail)
    case Epoch.Command{now,kind,pid,score,plan,rest,shape,dead,actual,same,safe,tail}: B.Battle.concat(L.LiveCombat.notices(actual),Epoch.notices(rest,H.History.step(world,H.History.Command{now,kind,pid,score,plan}),monster,tail))

law Epoch.split:
  for -entries: List<&2,H.History.Entry>
  for -world: T.Terrain.World
  for -monster: M.Monsters.State
  for +follow: Epoch.Follow<entries,world,monster>
  {entries == Epoch.concat(Epoch.prefix(entries,world,monster,follow)(world,monster),Epoch.remaining(entries,world,monster,follow)) : List<&2,H.History.Entry>}

def Epoch.split(entries,world,monster,follow):
  match follow:
    case Epoch.Done{empty,inside,unique,dead}: empty
    case Epoch.Birth{timer,rest,shape,zone,inside,dead,mode,chosen,tracked,born}: shape
    case Epoch.Wait{timer,rest,shape,zone,inside,dead,mode,chosen,tracked,none,same_id,tail}:
      %Epoch.split(rest,H.History.step(world,H.History.Tick{timer}),TL.TickLife.after(monster,mode),tail) : {entries == Con{H.History.Entry{world,H.History.Tick{timer},H.History.step(world,H.History.Tick{timer})},_} : List<&2,H.History.Entry>}
      shape
    case Epoch.Command{now,kind,pid,score,plan,rest,shape,dead,actual,same,safe,tail}:
      %Epoch.split(rest,H.History.step(world,H.History.Command{now,kind,pid,score,plan}),monster,tail) : {entries == Con{H.History.Entry{world,H.History.Command{now,kind,pid,score,plan},H.History.step(world,H.History.Command{now,kind,pid,score,plan})},_} : List<&2,H.History.Entry>}
      shape

law Epoch.notices_exact:
  for -entries: List<&2,H.History.Entry>
  for -world: T.Terrain.World
  for -monster: M.Monsters.State
  for +follow: Epoch.Follow<entries,world,monster>
  {Epoch.notices(entries,world,monster,follow) == PH.Permanent.notices(Epoch.prefix(entries,world,monster,follow)(world,monster)) : List<&2,B.Battle.Notice>}

def Epoch.notices_exact(entries,world,monster,follow):
  match follow:
    case Epoch.Done{empty,inside,unique,dead}: {==}
    case Epoch.Birth{timer,rest,shape,zone,inside,dead,mode,chosen,tracked,born}: {==}
    case Epoch.Wait{timer,rest,shape,zone,inside,dead,mode,chosen,tracked,none,same_id,tail}: Epoch.notices_exact(rest,H.History.step(world,H.History.Tick{timer}),TL.TickLife.after(monster,mode),tail)
    case Epoch.Command{now,kind,pid,score,plan,rest,shape,dead,actual,same,safe,tail}:
      %Epoch.notices_exact(rest,H.History.step(world,H.History.Command{now,kind,pid,score,plan}),monster,tail) : {B.Battle.concat(L.LiveCombat.notices(actual),Epoch.notices(rest,H.History.step(world,H.History.Command{now,kind,pid,score,plan}),monster,tail)) == B.Battle.concat(L.LiveCombat.notices(L.LiveCombat.at(Clock.WorldClock.set(world,now),kind,pid,score,plan)),_) : List<&2,B.Battle.Notice>}
      %same : {B.Battle.concat(L.LiveCombat.notices(actual),Epoch.notices(rest,H.History.step(world,H.History.Command{now,kind,pid,score,plan}),monster,tail)) == B.Battle.concat(L.LiveCombat.notices(_),Epoch.notices(rest,H.History.step(world,H.History.Command{now,kind,pid,score,plan}),monster,tail)) : List<&2,B.Battle.Notice>}
      {==}

law Epoch.clear:
  for +mid: U32
  for -entries: List<&2,H.History.Entry>
  for -world: T.Terrain.World
  for -monster: M.Monsters.State
  for +follow: Epoch.Follow<entries,world,monster>
  for +same_id: {R.Roster.id(monster) == mid : U32}
  Dead.Dead.Clear(mid,Epoch.notices(entries,world,monster,follow))

def Epoch.clear(mid,entries,world,monster,follow,same_id):
  match follow:
    case Epoch.Done{empty,inside,unique,dead}: Unit{}
    case Epoch.Birth{timer,rest,shape,zone,inside,dead,mode,chosen,tracked,born}: Unit{}
    case Epoch.Wait{timer,rest,shape,zone,inside,dead,mode,chosen,tracked,none,after_id,tail}:
      Epoch.clear(mid,rest,H.History.step(world,H.History.Tick{timer}),TL.TickLife.after(monster,mode),tail,Equal.trans(U32,R.Roster.id(TL.TickLife.after(monster,mode)),R.Roster.id(monster),mid,after_id,same_id))
    case Epoch.Command{now,kind,pid,score,plan,rest,shape,dead,actual,same,safe,tail}:
      match safe:
        case LD.LiveDead.Safe{inside,unique,clear}:
          Dead.Dead.concat_clear(L.LiveCombat.notices(actual),Epoch.notices(rest,H.History.step(world,H.History.Command{now,kind,pid,score,plan}),monster,tail),mid,(%same_id : Dead.Dead.Clear(_,L.LiveCombat.notices(actual)); clear),Epoch.clear(mid,rest,H.History.step(world,H.History.Command{now,kind,pid,score,plan}),monster,tail,same_id))

law Epoch.zero:
  for +monster: M.Monsters.State
  for -entries: List<&2,H.History.Entry>
  for -world: T.Terrain.World
  for +follow: Epoch.Follow<entries,world,monster>
  {Dead.Dead.count(R.Roster.id(monster),PH.Permanent.notices(Epoch.prefix(entries,world,monster,follow)(world,monster))) == 0n : Nat}

def Epoch.zero(monster,entries,world,follow):
  %Epoch.notices_exact(entries,world,monster,follow) : {Dead.Dead.count(R.Roster.id(monster),_) == 0n : Nat}
  Dead.Dead.clear_zero(Epoch.notices(entries,world,monster,follow),R.Roster.id(monster),Epoch.clear(R.Roster.id(monster),entries,world,monster,follow,{==}))


def Epoch.reborn(-entries: List<&2,H.History.Entry>,-world: T.Terrain.World,-monster: M.Monsters.State,follow: Epoch.Follow<entries,world,monster>) -> Bool:
  match follow:
    case Epoch.Done{empty,inside,unique,dead}: False{}
    case Epoch.Birth{timer,rest,shape,zone,inside,dead,mode,chosen,tracked,born}: True{}
    case Epoch.Wait{timer,rest,shape,zone,inside,dead,mode,chosen,tracked,none,same_id,tail}: Epoch.reborn(rest,H.History.step(world,H.History.Tick{timer}),TL.TickLife.after(monster,mode),tail)
    case Epoch.Command{now,kind,pid,score,plan,rest,shape,dead,actual,same,safe,tail}: Epoch.reborn(rest,H.History.step(world,H.History.Command{now,kind,pid,score,plan}),monster,tail)

law Epoch.exhausted:
  for -entries: List<&2,H.History.Entry>
  for -world: T.Terrain.World
  for -monster: M.Monsters.State
  for +follow: Epoch.Follow<entries,world,monster>
  for +none: {Epoch.reborn(entries,world,monster,follow) == False{} : Bool}
  {Epoch.remaining(entries,world,monster,follow) == Nil{} : List<&2,H.History.Entry>}

def Epoch.exhausted(entries,world,monster,follow,none):
  match follow:
    case Epoch.Done{empty,inside,unique,dead}: {==}
    case Epoch.Birth{timer,rest,shape,zone,inside,dead,mode,chosen,tracked,born}: Empty.absurd({rest == Nil{} : List<&2,H.History.Entry>},N.Numeric.true_ne_false(none))
    case Epoch.Wait{timer,rest,shape,zone,inside,dead,mode,chosen,tracked,none_here,same_id,tail}: Epoch.exhausted(rest,H.History.step(world,H.History.Tick{timer}),TL.TickLife.after(monster,mode),tail,none)
    case Epoch.Command{now,kind,pid,score,plan,rest,shape,dead,actual,same,safe,tail}: Epoch.exhausted(rest,H.History.step(world,H.History.Command{now,kind,pid,score,plan}),monster,tail,none)

type Epoch.Cut<-run: H.History.Run,-world: T.Terrain.World,-monster: M.Monsters.State> is Data:
  Epoch.Cut{actual: H.History.Run,same: {actual == run : H.History.Run},follow: Epoch.Follow<H.History.entries(actual),world,monster>,prefix: List<&2,H.History.Entry>,prefix_same: {prefix == Epoch.prefix(H.History.entries(actual),world,monster,follow)(world,monster) : List<&2,H.History.Entry>},remaining: List<&2,H.History.Entry>,remaining_same: {remaining == Epoch.remaining(H.History.entries(actual),world,monster,follow) : List<&2,H.History.Entry>},split: {H.History.entries(actual) == Epoch.concat(prefix,remaining) : List<&2,H.History.Entry>},zero: {Dead.Dead.count(R.Roster.id(monster),PH.Permanent.notices(prefix)) == 0n : Nat}}

law Epoch.cut_from:
  for -run: H.History.Run
  for +world: T.Terrain.World
  for +monster: M.Monsters.State
  for +report: Epoch.Report<run,world,monster>
  Epoch.Cut<run,world,monster>

def Epoch.cut_from(run,world,monster,report):
  match report:
    case Epoch.Report{actual,same,follow}:
      Epoch.Cut{actual,same,follow,Epoch.prefix(H.History.entries(actual),world,monster,follow)(world,monster),{==},Epoch.remaining(H.History.entries(actual),world,monster,follow),{==},Epoch.split(H.History.entries(actual),world,monster,follow),Epoch.zero(monster,H.History.entries(actual),world,follow)}

law Epoch.cut:
  for requests: List<&1,H.History.Request>
  for +world: T.Terrain.World
  for +states: List<&2,Sess.Sessions.State>
  for +monster: M.Monsters.State
  for +valid: SW.SeededWorld.OK<world,states>
  for +inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  Epoch.Cut<H.History.trace(requests,world),world,monster>

def Epoch.cut(requests,world,states,monster,valid,inside,dead):
  Epoch.cut_from(H.History.trace(requests,world),world,monster,Epoch.report(requests,world,states,monster,valid,inside,dead))

