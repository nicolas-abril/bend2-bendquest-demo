# Permanent death through the actual mixed live tick/combat history.
import Base
import ./reward_once.bend as Once
import ./attack_once.bend as AO
import ./combat_history.bend as H
import ./tick_life.bend as TL
import ./monster_life.bend as Life
import ./live_tick.bend as Tick
import ./live_combat.bend as L
import ./live_dead.bend as LD
import ./dead_rewards.bend as Dead
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
import ./connections.bend as Conn
import ./worldstate.bend as WS
import ./sessions.bend as Sess

type Permanent.Bounds<-world: T.Terrain.World> is Data:
  Permanent.Bounds{zones: Z.Zones.All(S.Simulation.monsters(T.Terrain.simulation(world))),unique: I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(world)))}

law Permanent.bounds:
  for -world: T.Terrain.World
  for -states: List<&2,Sess.Sessions.State>
  for +valid: SW.SeededWorld.OK<world,states>
  Permanent.Bounds<world>

def Permanent.bounds(world,states,valid):
  match valid:
    case SW.SeededWorld.OK{world_ok,maps}:
      match world_ok:
        case Conn.Connections.WorldOK{world_valid,connections}:
          match world_valid:
            case WS.WorldState.OK{health,positions,monsters,players,nonzero,references}:
              match health:
                case S.Simulation.OK{player_health,monster_health,zones}: Permanent.Bounds{zones,monsters}

law Permanent.member_zone:
  for +monster: M.Monsters.State
  for -monsters: List<&2,M.Monsters.State>
  for +inside: Member.Targets.In<monster,monsters>
  for +zones: Z.Zones.All(monsters)
  Z.Zones.Valid<R.Roster.zone_of(monster)>

def Permanent.member_zone(monster,monsters,inside,zones):
  match inside:
    case Member.Targets.Here{rest,shape}:
      Z.Zones.all_head(monster,rest,(%shape : Z.Zones.All(_); zones))
    case Member.Targets.There{head,rest,shape,later}:
      Permanent.member_zone(monster,rest,later,Z.Zones.all_tail(head,rest,(%shape : Z.Zones.All(_); zones)))

law Permanent.after:
  for +monster: M.Monsters.State
  for +mode: Maybe<&2,A.AI.Plan>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  for +permanent: {M.Monsters.timer(monster) == 4294967295 : U32}
  {TL.TickLife.after(monster,mode) == monster : M.Monsters.State}

def Permanent.after(monster,mode,dead,permanent):
  match mode:
    case None{}: {==}
    case Some{plan}:
      %Equal.sym(M.Monsters.Tick,M.Monsters.tick(monster),M.Monsters.Tick{monster,M.Monsters.Dormant{}},M.Monsters.permanent_death_stays(monster,dead,permanent)) : {A.AI.monster(A.AI.commit(_,plan)) == monster : M.Monsters.State}
      {==}

law Permanent.event:
  for +monster: M.Monsters.State
  for +mode: Maybe<&2,A.AI.Plan>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  for +permanent: {M.Monsters.timer(monster) == 4294967295 : U32}
  {TL.TickLife.event(monster,mode) == False{} : Bool}

def Permanent.event(monster,mode,dead,permanent):
  match mode:
    case None{}: {==}
    case Some{plan}: Life.Life.permanent_event(monster,plan,dead,permanent)

# Notices are from each entry's actual recorded plan and pre-command world.
def Permanent.operation_notices(+world: T.Terrain.World,operation: H.History.Operation) -> List<&2,B.Battle.Notice>:
  match operation:
    case H.History.Tick{timer}: Nil{}
    case H.History.Command{now,kind,pid,score,plan}: L.LiveCombat.notices(L.LiveCombat.at(Clock.WorldClock.set(world,now),kind,pid,score,plan))

def Permanent.notices(entries: List<&2,H.History.Entry>) -> List<&2,B.Battle.Notice>:
  match entries:
    case Nil{}: Nil{}
    case Con{head,rest}:
      match head:
        case H.History.Entry{before,operation,after}: B.Battle.concat(Permanent.operation_notices(before,operation),Permanent.notices(rest))

type Permanent.Step<-monster: M.Monsters.State,-world: T.Terrain.World,-operation: H.History.Operation> is Data:
  Permanent.Step{inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(H.History.step(world,operation)))>,unique: I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(H.History.step(world,operation)))),clear: Dead.Dead.Clear(R.Roster.id(monster),Permanent.operation_notices(world,operation))}

law Permanent.tick_from:
  for +world: T.Terrain.World
  for +timer: U32
  for +monster: M.Monsters.State
  for +mode: Maybe<&2,A.AI.Plan>
  for +tracked: TL.TickLife.Tracked<monster,mode,S.Simulation.monsters(T.Terrain.simulation(Tick.LiveTick.world(Tick.LiveTick.run(world,timer))))>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  for +permanent: {M.Monsters.timer(monster) == 4294967295 : U32}
  Permanent.Step<monster,world,H.History.Tick{timer}>

def Permanent.tick_from(world,timer,monster,mode,tracked,dead,permanent):
  match tracked:
    case TL.TickLife.Tracked{inside,key,alive,quiet,unique}:
      Permanent.Step{(%Permanent.after(monster,mode,dead,permanent) : Member.Targets.In<_,S.Simulation.monsters(T.Terrain.simulation(Tick.LiveTick.world(Tick.LiveTick.run(world,timer))))>; inside),unique,Unit{}}

law Permanent.tick:
  for +world: T.Terrain.World
  for +timer: U32
  for +monster: M.Monsters.State
  for +inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>
  for +bounds: Permanent.Bounds<world>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  for +permanent: {M.Monsters.timer(monster) == 4294967295 : U32}
  Permanent.Step<monster,world,H.History.Tick{timer}>

def Permanent.tick(world,timer,monster,inside,bounds,dead,permanent):
  match bounds:
    case Permanent.Bounds{zones,unique}:
      +zone = Permanent.member_zone(monster,S.Simulation.monsters(T.Terrain.simulation(world)),inside,zones)
      +mode = TL.TickLife.decision(world,timer,monster,zone,inside)
      Permanent.tick_from(world,timer,monster,mode,TL.TickLife.run(world,timer,monster,zone,inside,dead,zones,unique),dead,permanent)

law Permanent.step:
  for +world: T.Terrain.World
  for +operation: H.History.Operation
  for +monster: M.Monsters.State
  for +inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>
  for +bounds: Permanent.Bounds<world>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  for +permanent: {M.Monsters.timer(monster) == 4294967295 : U32}
  Permanent.Step<monster,world,operation>

def Permanent.step(world,operation,monster,inside,bounds,dead,permanent):
  match operation:
    case H.History.Tick{timer}: Permanent.tick(world,timer,monster,inside,bounds,dead,permanent)
    case H.History.Command{now,kind,pid,score,plan}:
      match bounds:
        case Permanent.Bounds{zones,unique}:
          LD.LiveDead.eliminate(Permanent.Step<monster,world,H.History.Command{now,kind,pid,score,plan}>,monster,L.LiveCombat.at(Clock.WorldClock.set(world,now),kind,pid,score,plan),LD.LiveDead.timed_safe(world,now,kind,pid,score,plan,monster,inside,unique,dead),(present => (next_unique => (clear => Permanent.Step{present,next_unique,clear}))))

# Retain the actual Data result so affine request callbacks are consumed once.
type Permanent.Safe<-monster: M.Monsters.State,-run: H.History.Run> is Data:
  Permanent.Safe{actual: H.History.Run,same: {actual == run : H.History.Run},inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(H.History.world(actual)))>,unique: I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(H.History.world(actual)))),clear: Dead.Dead.Clear(R.Roster.id(monster),Permanent.notices(H.History.entries(actual)))}

law Permanent.add:
  for +monster: M.Monsters.State
  for +world: T.Terrain.World
  for +operation: H.History.Operation
  for -tail: H.History.Run
  for +clear: Dead.Dead.Clear(R.Roster.id(monster),Permanent.operation_notices(world,operation))
  for +safe: Permanent.Safe<monster,tail>
  Permanent.Safe<monster,H.History.prepend(H.History.Entry{world,operation,H.History.step(world,operation)},tail)>

def Permanent.add(monster,world,operation,tail,clear,safe):
  match safe:
    case Permanent.Safe{actual,same,inside,unique,later}:
      %same : Permanent.Safe<monster,H.History.prepend(H.History.Entry{world,operation,H.History.step(world,operation)},_)>
      Permanent.Safe{H.History.prepend(H.History.Entry{world,operation,H.History.step(world,operation)},actual),{==},inside,unique,Dead.Dead.concat_clear(Permanent.operation_notices(world,operation),Permanent.notices(H.History.entries(actual)),R.Roster.id(monster),clear,later)}

law Permanent.eliminate:
  for -Result: Data
  for +monster: M.Monsters.State
  for +world: T.Terrain.World
  for +operation: H.History.Operation
  for +step: Permanent.Step<monster,world,operation>
  for use: (@+inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(H.History.step(world,operation)))> -> @+clear: Dead.Dead.Clear(R.Roster.id(monster),Permanent.operation_notices(world,operation)) -> Result)
  Result

def Permanent.eliminate(Result,monster,world,operation,step,use):
  match step:
    case Permanent.Step{inside,unique,clear}: use(inside,clear)

def Permanent.empty_from(+world: T.Terrain.World,monster: M.Monsters.State,inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>,bounds: Permanent.Bounds<world>) -> Permanent.Safe<monster,H.History.Run{world,Nil{}}>:
  match bounds:
    case Permanent.Bounds{zones,unique}: Permanent.Safe{H.History.Run{world,Nil{}},{==},inside,unique,Unit{}}

law Permanent.empty:
  for +world: T.Terrain.World
  for +states: List<&2,Sess.Sessions.State>
  for +monster: M.Monsters.State
  for +inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>
  for +valid: SW.SeededWorld.OK<world,states>
  Permanent.Safe<monster,H.History.Run{world,Nil{}}>

def Permanent.empty(world,states,monster,inside,valid):
  Permanent.empty_from(world,monster,inside,Permanent.bounds(world,states,valid))

law Permanent.safe:
  for requests: List<&1,H.History.Request>
  for +world: T.Terrain.World
  for +states: List<&2,Sess.Sessions.State>
  for +monster: M.Monsters.State
  for +inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>
  for +valid: SW.SeededWorld.OK<world,states>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  for +permanent: {M.Monsters.timer(monster) == 4294967295 : U32}
  Permanent.Safe<monster,H.History.trace(requests,world)>

def Permanent.safe(requests,world,states,monster,inside,valid,dead,permanent):
  match requests:
    case Nil{}: Permanent.empty(world,states,monster,inside,valid)
    case Con{head,rest}:
      match head:
        case H.History.TickRequest{timer}:
          +operation = {H.History.Tick{timer} : H.History.Operation}
          +after = H.History.step(world,operation)
          Permanent.eliminate(Permanent.Safe<monster,H.History.prepend(H.History.Entry{world,operation,after},H.History.trace(rest,after))>,monster,world,operation,Permanent.step(world,operation,monster,inside,Permanent.bounds(world,states,valid),dead,permanent),(present => (clear => Permanent.add(monster,world,operation,H.History.trace(rest,after),clear,Permanent.safe(rest,after,states,monster,present,H.History.step_seeded(world,operation,states,valid),dead,permanent)))))
        case H.History.CommandRequest{now,kind,pid,score,planner}:
          +now = now
          +kind = kind
          +pid = pid
          +score = score
          +plan = planner(L.LiveCombat.prepare(Clock.WorldClock.set(world,now),kind,pid,score))
          +operation = {H.History.Command{now,kind,pid,score,plan} : H.History.Operation}
          +after = H.History.step(world,operation)
          Permanent.eliminate(Permanent.Safe<monster,H.History.prepend(H.History.Entry{world,operation,after},H.History.trace(rest,after))>,monster,world,operation,Permanent.step(world,operation,monster,inside,Permanent.bounds(world,states,valid),dead,permanent),(present => (clear => Permanent.add(monster,world,operation,H.History.trace(rest,after),clear,Permanent.safe(rest,after,states,monster,present,H.History.step_seeded(world,operation,states,valid),dead,permanent)))))

law Permanent.zero:
  for +monster: M.Monsters.State
  for -run: H.History.Run
  for +safe: Permanent.Safe<monster,run>
  {Dead.Dead.count(R.Roster.id(monster),Permanent.notices(H.History.entries(run))) == 0n : Nat}

def Permanent.zero(monster,run,safe):
  match safe:
    case Permanent.Safe{actual,same,inside,unique,clear}:
      %same : {Dead.Dead.count(R.Roster.id(monster),Permanent.notices(H.History.entries(_))) == 0n : Nat}
      Dead.Dead.clear_zero(Permanent.notices(H.History.entries(actual)),R.Roster.id(monster),clear)

law Permanent.lookup:
  for +monster: M.Monsters.State
  for -run: H.History.Run
  for +safe: Permanent.Safe<monster,run>
  {R.Roster.found(R.Roster.take(S.Simulation.monsters(T.Terrain.simulation(H.History.world(run))),R.Roster.id(monster))) == Some{monster} : Maybe<&2,M.Monsters.State>}

def Permanent.lookup(monster,run,safe):
  match safe:
    case Permanent.Safe{actual,same,inside,unique,clear}:
      %same : {R.Roster.found(R.Roster.take(S.Simulation.monsters(T.Terrain.simulation(H.History.world(_))),R.Roster.id(monster))) == Some{monster} : Maybe<&2,M.Monsters.State>}
      Member.Targets.lookup_member(monster,S.Simulation.monsters(T.Terrain.simulation(H.History.world(actual))),inside,unique)

type Permanent.OnceTrace<-monster: M.Monsters.State,-damage: U32,-first: L.LiveCombat.Result,-run: H.History.Run> is Data:
  Permanent.OnceTrace{suffix: Permanent.Safe<Once.Once.after(monster,damage),run>,count: {Dead.Dead.count(R.Roster.id(monster),B.Battle.concat(L.LiveCombat.notices(first),Permanent.notices(H.History.entries(run)))) == 1n : Nat}}

law Permanent.compose_once:
  for +monster: M.Monsters.State
  for +damage: U32
  for +first: L.LiveCombat.Result
  for -run: H.History.Run
  for +one: {Dead.Dead.count(R.Roster.id(monster),L.LiveCombat.notices(first)) == 1n : Nat}
  for +safe: Permanent.Safe<Once.Once.after(monster,damage),run>
  Permanent.OnceTrace<monster,damage,first,run>

def Permanent.compose_once(monster,damage,first,run,one,safe):
  match safe:
    case Permanent.Safe{actual,same,inside,unique,clear}:
      +zero = {(%Once.Once.after_id(monster,damage) : {Dead.Dead.count(_,Permanent.notices(H.History.entries(actual))) == 0n : Nat}; Dead.Dead.clear_zero(Permanent.notices(H.History.entries(actual)),R.Roster.id(Once.Once.after(monster,damage)),clear)) : {Dead.Dead.count(R.Roster.id(monster),Permanent.notices(H.History.entries(actual))) == 0n : Nat}}
      Permanent.OnceTrace{Permanent.Safe{actual,same,inside,unique,clear},(%same : {Dead.Dead.count(R.Roster.id(monster),B.Battle.concat(L.LiveCombat.notices(first),Permanent.notices(H.History.entries(_)))) == 1n : Nat}; LD.LiveDead.one_plus_zero(L.LiveCombat.notices(first),Permanent.notices(H.History.entries(actual)),R.Roster.id(monster),one,zero))}

law Permanent.after_once:
  for requests: List<&1,H.History.Request>
  for +monster: M.Monsters.State
  for +damage: U32
  for +first: L.LiveCombat.Result
  for +states: List<&2,Sess.Sessions.State>
  for +certificate: Once.Once.Certificate<monster,damage,AO.AttackOnce.view(first)>
  for +valid: SW.SeededWorld.OK<L.LiveCombat.world(first),states>
  for +permanent: {M.Monsters.timer(Once.Once.after(monster,damage)) == 4294967295 : U32}
  Permanent.OnceTrace<monster,damage,first,H.History.trace(requests,L.LiveCombat.world(first))>

def Permanent.after_once(requests,monster,damage,first,states,certificate,valid,permanent):
  match certificate:
    case Once.Once.Certificate{inside,unique,dead,count}:
      Permanent.compose_once(monster,damage,first,H.History.trace(requests,L.LiveCombat.world(first)),count,Permanent.safe(requests,L.LiveCombat.world(first),states,Once.Once.after(monster,damage),inside,valid,dead,permanent))

law Permanent.exactly_once:
  for +monster: M.Monsters.State
  for -damage: U32
  for -first: L.LiveCombat.Result
  for -run: H.History.Run
  for +certificate: Permanent.OnceTrace<monster,damage,first,run>
  {Dead.Dead.count(R.Roster.id(monster),B.Battle.concat(L.LiveCombat.notices(first),Permanent.notices(H.History.entries(run)))) == 1n : Nat}

def Permanent.exactly_once(monster,damage,first,run,certificate):
  match certificate:
    case Permanent.OnceTrace{suffix,count}: count

