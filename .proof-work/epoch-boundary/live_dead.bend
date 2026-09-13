# Dead-monster reward exclusion through actual admitted/planned commands.
import Base
import ./dead_rewards.bend as Dead
import ./reward_once.bend as Once
import ./live_combat.bend as L
import ./combat.bend as C
import ./battle.bend as B
import ./simulation.bend as S
import ./terrain.bend as T
import ./players.bend as P
import ./monsters.bend as M
import ./vitals.bend as V
import ./roster.bend as R
import ./combat_targets.bend as Member
import ./identity.bend as I
import ./world_clock.bend as Clock

# These fields refer to the actual result world and actual notices.
type LiveDead.Safe<-monster: M.Monsters.State,-result: L.LiveCombat.Result> is Data:
  LiveDead.Safe{inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(L.LiveCombat.world(result)))>,unique: I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(L.LiveCombat.world(result)))),clear: Dead.Dead.Clear(R.Roster.id(monster),L.LiveCombat.notices(result))}

law LiveDead.execute_safe:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +admitted: C.Combat.Result
  for +inputs: List<&2,B.Battle.Input>
  for +pid: U32
  for +score: U32
  for +monster: M.Monsters.State
  for +inside: Member.Targets.In<monster,monsters>
  for +unique: I.Identity.Monsters(monsters)
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  Dead.Dead.Safe<monster,B.Battle.execute(meta,monsters,admitted,inputs,pid,score)>

def LiveDead.execute_safe(meta,monsters,admitted,inputs,pid,score,monster,inside,unique,dead):
  match admitted:
    case C.Combat.Result{players,actor}:
      match actor:
        case None{}: Dead.Dead.Safe{inside,unique,Unit{}}
        case Some{player}: Dead.Dead.Safe{Dead.Dead.run_member(inputs,monster,S.Simulation.State{meta,players,monsters},pid,score,inside,unique,dead),I.Identity.battle_run_unique(inputs,S.Simulation.State{meta,players,monsters},pid,score,unique),Dead.Dead.run_clear(inputs,monster,S.Simulation.State{meta,players,monsters},pid,score,inside,unique,dead)}

law LiveDead.finish_safe:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +maps: T.Terrain.Maps
  for +admitted: C.Combat.Result
  for +pid: U32
  for +score: U32
  for +plan: L.LiveCombat.Plan
  for +monster: M.Monsters.State
  for +safe: Dead.Dead.Safe<monster,B.Battle.execute(meta,monsters,admitted,L.LiveCombat.inputs(plan),pid,score)>
  LiveDead.Safe<monster,L.LiveCombat.finish(L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score},plan)>

def LiveDead.finish_safe(meta,monsters,maps,admitted,pid,score,plan,monster,safe):
  match safe:
    case Dead.Dead.Safe{inside,unique,clear}:
      +result = L.LiveCombat.finish(L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score},plan)
      +battle = B.Battle.execute(meta,monsters,admitted,L.LiveCombat.inputs(plan),pid,score)
      +simulation = L.LiveCombat.finish_simulation(meta,monsters,maps,admitted,pid,score,plan)
      +notices = L.LiveCombat.finish_notices(meta,monsters,maps,admitted,pid,score,plan)
      LiveDead.Safe{(%Equal.sym(S.Simulation.State,T.Terrain.simulation(L.LiveCombat.world(result)),B.Battle.state(battle),simulation) : Member.Targets.In<monster,S.Simulation.monsters(_)>; inside),(%Equal.sym(S.Simulation.State,T.Terrain.simulation(L.LiveCombat.world(result)),B.Battle.state(battle),simulation) : I.Identity.Monsters(S.Simulation.monsters(_)); unique),(%Equal.sym(List<&2,B.Battle.Notice>,L.LiveCombat.notices(result),B.Battle.notices(battle),notices) : Dead.Dead.Clear(R.Roster.id(monster),_); clear)}

def LiveDead.monsters(ready: L.LiveCombat.Ready) -> List<&2,M.Monsters.State>:
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}: monsters

law LiveDead.ready_safe:
  for +ready: L.LiveCombat.Ready
  for +plan: L.LiveCombat.Plan
  for +monster: M.Monsters.State
  for +inside: Member.Targets.In<monster,LiveDead.monsters(ready)>
  for +unique: I.Identity.Monsters(LiveDead.monsters(ready))
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  LiveDead.Safe<monster,L.LiveCombat.finish(ready,plan)>

def LiveDead.ready_safe(ready,plan,monster,inside,unique,dead):
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}: LiveDead.finish_safe(meta,monsters,maps,admitted,pid,score,plan,monster,LiveDead.execute_safe(meta,monsters,admitted,L.LiveCombat.inputs(plan),pid,score,monster,inside,unique,dead))

law LiveDead.live:
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +monster: M.Monsters.State
  for +inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>
  for +unique: I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(world)))
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  LiveDead.Safe<monster,L.LiveCombat.run(world,kind,pid,score,planner)>

def LiveDead.live(world,kind,pid,score,planner,monster,inside,unique,dead):
  match world:
    case T.Terrain.World{meta,players,monsters,maps}:
      +ready = L.LiveCombat.prepare(T.Terrain.World{meta,players,monsters,maps},kind,pid,score)
      LiveDead.ready_safe(ready,planner(ready),monster,inside,unique,dead)

law LiveDead.at_safe:
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for +plan: L.LiveCombat.Plan
  for +monster: M.Monsters.State
  for +inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>
  for +unique: I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(world)))
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  LiveDead.Safe<monster,L.LiveCombat.at(world,kind,pid,score,plan)>

def LiveDead.at_safe(world,kind,pid,score,plan,monster,inside,unique,dead):
  match world:
    case T.Terrain.World{meta,players,monsters,maps}: LiveDead.ready_safe(L.LiveCombat.prepare(T.Terrain.World{meta,players,monsters,maps},kind,pid,score),plan,monster,inside,unique,dead)

law LiveDead.timed_safe:
  for +world: T.Terrain.World
  for +now: U32
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for +plan: L.LiveCombat.Plan
  for +monster: M.Monsters.State
  for +inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>
  for +unique: I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(world)))
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  LiveDead.Safe<monster,L.LiveCombat.at(Clock.WorldClock.set(world,now),kind,pid,score,plan)>

def LiveDead.timed_safe(world,now,kind,pid,score,plan,monster,inside,unique,dead):
  match world:
    case T.Terrain.World{meta,players,monsters,maps}: LiveDead.at_safe(Clock.WorldClock.set(T.Terrain.World{meta,players,monsters,maps},now),kind,pid,score,plan,monster,inside,unique,dead)

law LiveDead.eliminate:
  for -Result: Data
  for +monster: M.Monsters.State
  for -result: L.LiveCombat.Result
  for +safe: LiveDead.Safe<monster,result>
  for use: (@+inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(L.LiveCombat.world(result)))> -> @+unique: I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(L.LiveCombat.world(result)))) -> @+clear: Dead.Dead.Clear(R.Roster.id(monster),L.LiveCombat.notices(result)) -> Result)
  Result

def LiveDead.eliminate(Result,monster,result,safe,use):
  match safe:
    case LiveDead.Safe{inside,unique,clear}: use(inside,unique,clear)

# The request and callback are affine; the exact actual result is retained.
type LiveDead.Request is Type:
  LiveDead.Request{now: U32,kind: C.Combat.Kind,pid: U32,score: U32,planner: L.LiveCombat.Ready -> L.LiveCombat.Plan}

type LiveDead.Run is Data:
  LiveDead.Run{world: T.Terrain.World,results: List<&2,L.LiveCombat.Result>}

def LiveDead.world(run: LiveDead.Run) -> T.Terrain.World:
  match run:
    case LiveDead.Run{world,results}: world

def LiveDead.results(run: LiveDead.Run) -> List<&2,L.LiveCombat.Result>:
  match run:
    case LiveDead.Run{world,results}: results

def LiveDead.list_notices(results: List<&2,L.LiveCombat.Result>) -> List<&2,B.Battle.Notice>:
  match results:
    case Nil{}: Nil{}
    case Con{head,rest}: B.Battle.concat(L.LiveCombat.notices(head),LiveDead.list_notices(rest))

def LiveDead.notices(run: LiveDead.Run) -> List<&2,B.Battle.Notice>: LiveDead.list_notices(LiveDead.results(run))

def LiveDead.prepend(first: L.LiveCombat.Result,+tail: LiveDead.Run) -> LiveDead.Run:
  LiveDead.Run{LiveDead.world(tail),Con{first,LiveDead.results(tail)}}

def LiveDead.trace(requests: List<&1,LiveDead.Request>,world: T.Terrain.World) -> LiveDead.Run:
  match requests:
    case Nil{}: LiveDead.Run{world,Nil{}}
    case Con{head,rest}:
      match head:
        case LiveDead.Request{now,kind,pid,score,planner}:
          +first = L.LiveCombat.run(Clock.WorldClock.set(world,now),kind,pid,score,planner)
          LiveDead.prepend(first,LiveDead.trace(rest,L.LiveCombat.world(first)))

# Retain the actual run as Data so proving an affine trace never reruns planners.
type LiveDead.TraceSafe<-monster: M.Monsters.State,-run: LiveDead.Run> is Data:
  LiveDead.TraceSafe{actual: LiveDead.Run,same: {actual == run : LiveDead.Run},inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(LiveDead.world(actual)))>,unique: I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(LiveDead.world(actual)))),clear: Dead.Dead.Clear(R.Roster.id(monster),LiveDead.notices(actual))}

law LiveDead.add:
  for +monster: M.Monsters.State
  for +first: L.LiveCombat.Result
  for -tail: LiveDead.Run
  for +clear: Dead.Dead.Clear(R.Roster.id(monster),L.LiveCombat.notices(first))
  for +safe: LiveDead.TraceSafe<monster,tail>
  LiveDead.TraceSafe<monster,LiveDead.prepend(first,tail)>

def LiveDead.add(monster,first,tail,clear,safe):
  match safe:
    case LiveDead.TraceSafe{actual,same,inside,unique,later}:
      %same : LiveDead.TraceSafe<monster,LiveDead.prepend(first,_)>
      LiveDead.TraceSafe{LiveDead.prepend(first,actual),{==},inside,unique,Dead.Dead.concat_clear(L.LiveCombat.notices(first),LiveDead.notices(actual),R.Roster.id(monster),clear,later)}

law LiveDead.safe:
  for requests: List<&1,LiveDead.Request>
  for +world: T.Terrain.World
  for +monster: M.Monsters.State
  for +inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>
  for +unique: I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(world)))
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  LiveDead.TraceSafe<monster,LiveDead.trace(requests,world)>

def LiveDead.safe(requests,world,monster,inside,unique,dead):
  match requests:
    case Nil{}: LiveDead.TraceSafe{LiveDead.Run{world,Nil{}},{==},inside,unique,Unit{}}
    case Con{head,rest}:
      match head:
        case LiveDead.Request{now,kind,pid,score,planner}:
          +now = now
          +kind = kind
          +pid = pid
          +score = score
          +plan = planner(L.LiveCombat.prepare(Clock.WorldClock.set(world,now),kind,pid,score))
          +first = L.LiveCombat.at(Clock.WorldClock.set(world,now),kind,pid,score,plan)
          LiveDead.eliminate(LiveDead.TraceSafe<monster,LiveDead.prepend(first,LiveDead.trace(rest,L.LiveCombat.world(first)))>,monster,first,LiveDead.timed_safe(world,now,kind,pid,score,plan,monster,inside,unique,dead),(present => (next_unique => (clear => LiveDead.add(monster,first,LiveDead.trace(rest,L.LiveCombat.world(first)),clear,LiveDead.safe(rest,L.LiveCombat.world(first),monster,present,next_unique,dead))))))

law LiveDead.zero:
  for +monster: M.Monsters.State
  for -run: LiveDead.Run
  for +safe: LiveDead.TraceSafe<monster,run>
  {Dead.Dead.count(R.Roster.id(monster),LiveDead.notices(run)) == 0n : Nat}

def LiveDead.zero(monster,run,safe):
  match safe:
    case LiveDead.TraceSafe{actual,same,inside,unique,clear}:
      %same : {Dead.Dead.count(R.Roster.id(monster),LiveDead.notices(_)) == 0n : Nat}
      Dead.Dead.clear_zero(LiveDead.notices(actual),R.Roster.id(monster),clear)

law LiveDead.final_lookup:
  for +monster: M.Monsters.State
  for -run: LiveDead.Run
  for +safe: LiveDead.TraceSafe<monster,run>
  {R.Roster.found(R.Roster.take(S.Simulation.monsters(T.Terrain.simulation(LiveDead.world(run))),R.Roster.id(monster))) == Some{monster} : Maybe<&2,M.Monsters.State>}

def LiveDead.final_lookup(monster,run,safe):
  match safe:
    case LiveDead.TraceSafe{actual,same,inside,unique,clear}:
      %same : {R.Roster.found(R.Roster.take(S.Simulation.monsters(T.Terrain.simulation(LiveDead.world(_))),R.Roster.id(monster))) == Some{monster} : Maybe<&2,M.Monsters.State>}
      Member.Targets.lookup_member(monster,S.Simulation.monsters(T.Terrain.simulation(LiveDead.world(actual))),inside,unique)

def LiveDead.request_count(requests: List<&1,LiveDead.Request>) -> Nat:
  match requests:
    case Nil{}: 0n
    case Con{head,rest}: Succ{LiveDead.request_count(rest)}

def LiveDead.result_count(results: List<&2,L.LiveCombat.Result>) -> Nat:
  match results:
    case Nil{}: 0n
    case Con{head,rest}: Succ{LiveDead.result_count(rest)}

law LiveDead.length:
  for requests: List<&1,LiveDead.Request>
  for +world: T.Terrain.World
  {LiveDead.result_count(LiveDead.results(LiveDead.trace(requests,world))) == LiveDead.request_count(requests) : Nat}

def LiveDead.length(requests,world):
  match requests:
    case Nil{}: {==}
    case Con{head,rest}:
      match head:
        case LiveDead.Request{now,kind,pid,score,planner}:
          +after = L.LiveCombat.world(L.LiveCombat.run(Clock.WorldClock.set(world,now),kind,pid,score,planner))
          %LiveDead.length(rest,after) : {Succ{LiveDead.result_count(LiveDead.results(LiveDead.trace(rest,after)))} == Succ{_} : Nat}
          {==}

law LiveDead.from_state:
  for requests: List<&1,LiveDead.Request>
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +monster: M.Monsters.State
  for +inside: Member.Targets.In<monster,S.Simulation.monsters(state)>
  for +unique: I.Identity.Monsters(S.Simulation.monsters(state))
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  LiveDead.TraceSafe<monster,LiveDead.trace(requests,T.Terrain.world(maps,state))>

def LiveDead.from_state(requests,state,maps,monster,inside,unique,dead):
  match state:
    case S.Simulation.State{meta,players,monsters}: LiveDead.safe(requests,T.Terrain.world(maps,S.Simulation.State{meta,players,monsters}),monster,inside,unique,dead)

law LiveDead.one_plus_zero:
  for +first: List<&2,B.Battle.Notice>
  for +second: List<&2,B.Battle.Notice>
  for +mid: U32
  for +one: {Dead.Dead.count(mid,first) == 1n : Nat}
  for +zero: {Dead.Dead.count(mid,second) == 0n : Nat}
  {Dead.Dead.count(mid,B.Battle.concat(first,second)) == 1n : Nat}

def LiveDead.one_plus_zero(first,second,mid,one,zero):
  %Equal.sym(Nat,Dead.Dead.count(mid,B.Battle.concat(first,second)),Nat.add(Dead.Dead.count(mid,first),Dead.Dead.count(mid,second)),Once.Once.concat_count(first,second,mid)) : {_ == 1n : Nat}
  %Equal.sym(Nat,Dead.Dead.count(mid,first),1n,one) : {Nat.add(_,Dead.Dead.count(mid,second)) == 1n : Nat}
  %Equal.sym(Nat,Dead.Dead.count(mid,second),0n,zero) : {Succ{_} == 1n : Nat}
  {==}

# The prefix has already established one real reward. This keeps its notices
# and the whole actual live suffix, whose callbacks remain affine.
type LiveDead.OnceTrace<-monster: M.Monsters.State,-damage: U32,-first: B.Battle.Result,-run: LiveDead.Run> is Data:
  LiveDead.OnceTrace{suffix: LiveDead.TraceSafe<Once.Once.after(monster,damage),run>,count: {Dead.Dead.count(R.Roster.id(monster),B.Battle.concat(B.Battle.notices(first),LiveDead.notices(run))) == 1n : Nat}}

law LiveDead.compose_once:
  for +monster: M.Monsters.State
  for +damage: U32
  for +first: B.Battle.Result
  for -run: LiveDead.Run
  for +one: {Dead.Dead.count(R.Roster.id(monster),B.Battle.notices(first)) == 1n : Nat}
  for +safe: LiveDead.TraceSafe<Once.Once.after(monster,damage),run>
  LiveDead.OnceTrace<monster,damage,first,run>

def LiveDead.compose_once(monster,damage,first,run,one,safe):
  match safe:
    case LiveDead.TraceSafe{actual,same,inside,unique,clear}:
      +zero = {(%Once.Once.after_id(monster,damage) : {Dead.Dead.count(_,LiveDead.notices(actual)) == 0n : Nat}; Dead.Dead.clear_zero(LiveDead.notices(actual),R.Roster.id(Once.Once.after(monster,damage)),clear)) : {Dead.Dead.count(R.Roster.id(monster),LiveDead.notices(actual)) == 0n : Nat}}
      LiveDead.OnceTrace{LiveDead.TraceSafe{actual,same,inside,unique,clear},(%same : {Dead.Dead.count(R.Roster.id(monster),B.Battle.concat(B.Battle.notices(first),LiveDead.notices(_))) == 1n : Nat}; LiveDead.one_plus_zero(B.Battle.notices(first),LiveDead.notices(actual),R.Roster.id(monster),one,zero))}

law LiveDead.after_once:
  for requests: List<&1,LiveDead.Request>
  for +monster: M.Monsters.State
  for +damage: U32
  for +first: B.Battle.Result
  for +maps: T.Terrain.Maps
  for +certificate: Once.Once.Certificate<monster,damage,first>
  LiveDead.OnceTrace<monster,damage,first,LiveDead.trace(requests,T.Terrain.world(maps,B.Battle.state(first)))>

def LiveDead.after_once(requests,monster,damage,first,maps,certificate):
  match certificate:
    case Once.Once.Certificate{inside,unique,dead,count}:
      LiveDead.compose_once(monster,damage,first,LiveDead.trace(requests,T.Terrain.world(maps,B.Battle.state(first))),count,LiveDead.from_state(requests,B.Battle.state(first),maps,Once.Once.after(monster,damage),inside,unique,dead))

law LiveDead.exactly_once:
  for +monster: M.Monsters.State
  for -damage: U32
  for -first: B.Battle.Result
  for -run: LiveDead.Run
  for +certificate: LiveDead.OnceTrace<monster,damage,first,run>
  {Dead.Dead.count(R.Roster.id(monster),B.Battle.concat(B.Battle.notices(first),LiveDead.notices(run))) == 1n : Nat}

def LiveDead.exactly_once(monster,damage,first,run,certificate):
  match certificate:
    case LiveDead.OnceTrace{suffix,count}: count
