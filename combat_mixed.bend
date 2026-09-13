# Arbitrary finite combat streams preserve a previously stamped cooldown.
import Base
import ./combat.bend as C
import ./live_combat.bend as L
import ./terrain.bend as T
import ./simulation.bend as S
import ./players.bend as P
import ./admission.bend as J
import ./bindings.bend as Bind
import ./combat_repeat.bend as Repeat
import ./combat_rejected.bend as R
import ./combat_other.bend as Other
import ./combat_foreign.bend as Foreign
import ./combat_clock.bend as CC
import ./world_clock.bend as Clock
import ./numeric.bend as N

law Mixed.restored:
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +held: Repeat.Repeat.Held<kind,pid,S.Simulation.players(T.Terrain.simulation(world))>
  Repeat.Repeat.Held<kind,pid,S.Simulation.players(T.Terrain.simulation(L.LiveCombat.world(Repeat.Repeat.quiet(world,pid))))>

def Mixed.restored(world,kind,pid,held):
  match world:
    case T.Terrain.World{meta,players,monsters,maps}:
      match held:
        case Repeat.Repeat.Held{player,inside,same,locked}: Repeat.Repeat.Held{player,Bind.Bindings.perm_member(player,P.Players.restore(P.Players.take(players,pid)),players,P.Players.take_restores(players,pid),inside),same,locked}

law Mixed.own:
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +held: Repeat.Repeat.Held<kind,pid,S.Simulation.players(T.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(world))>
  Repeat.Repeat.Held<kind,pid,S.Simulation.players(T.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,planner))))>

def Mixed.own(world,kind,pid,score,planner,held,unique):
  %Equal.sym(L.LiveCombat.Result,L.LiveCombat.run(world,kind,pid,score,planner),Repeat.Repeat.quiet(world,pid),Repeat.Repeat.live_run_rejected(world,kind,pid,score,planner,held,unique)) : Repeat.Repeat.Held<kind,pid,S.Simulation.players(T.Terrain.simulation(L.LiveCombat.world(_)))>
  Mixed.restored(world,kind,pid,held)

law Mixed.same_kind:
  for +same_pid: Bool
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +tracked: U32
  for +comparison: {U32.is_eq(tracked,pid) == same_pid : Bool}
  for +held: Repeat.Repeat.Held<kind,tracked,S.Simulation.players(T.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(world))>
  Repeat.Repeat.Held<kind,tracked,S.Simulation.players(T.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,planner))))>

def Mixed.same_kind(same_pid,world,kind,pid,score,planner,tracked,comparison,held,unique):
  match same_pid:
    case False{}: Foreign.Foreign.live_held(world,kind,pid,score,planner,kind,tracked,comparison,held)
    case True{}:
      +plan = planner(L.LiveCombat.prepare(world,kind,pid,score))
      %N.Numeric.u32_eq_sound(tracked,pid,comparison) : Repeat.Repeat.Held<kind,tracked,S.Simulation.players(T.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.at(world,kind,_,score,plan))))>
      Mixed.own(world,kind,tracked,score,(unused => plan),held,unique)

law Mixed.live_held:
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +protected: C.Combat.Kind
  for +tracked: U32
  for +held: Repeat.Repeat.Held<protected,tracked,S.Simulation.players(T.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(world))>
  Repeat.Repeat.Held<protected,tracked,S.Simulation.players(T.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,planner))))>

def Mixed.live_held(world,kind,pid,score,planner,protected,tracked,held,unique):
  match kind:
    case C.Combat.Attack{}:
      match protected:
        case C.Combat.Attack{}: Mixed.same_kind(U32.is_eq(tracked,pid),world,C.Combat.Attack{},pid,score,planner,tracked,{==},held,unique)
        case C.Combat.Spin{}: Other.Other.live_held(world,C.Combat.Attack{},pid,score,planner,tracked,held)
    case C.Combat.Spin{}:
      match protected:
        case C.Combat.Attack{}: Other.Other.live_held(world,C.Combat.Spin{},pid,score,planner,tracked,held)
        case C.Combat.Spin{}: Mixed.same_kind(U32.is_eq(tracked,pid),world,C.Combat.Spin{},pid,score,planner,tracked,{==},held,unique)

def Mixed.If(same: Bool,+before: T.Terrain.World,+result: L.LiveCombat.Result) -> Data:
  match same:
    case False{}: Unit
    case True{}: R.Rejected.Inert<before,result>

def Mixed.Guard(kind: C.Combat.Kind,protected: C.Combat.Kind,pid: U32,tracked: U32,before: T.Terrain.World,result: L.LiveCombat.Result) -> Data:
  match kind:
    case C.Combat.Attack{}:
      match protected:
        case C.Combat.Attack{}: Mixed.If(U32.is_eq(tracked,pid),before,result)
        case C.Combat.Spin{}: Unit
    case C.Combat.Spin{}:
      match protected:
        case C.Combat.Attack{}: Unit
        case C.Combat.Spin{}: Mixed.If(U32.is_eq(tracked,pid),before,result)

law Mixed.same_inert:
  for +same_pid: Bool
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +tracked: U32
  for +comparison: {U32.is_eq(tracked,pid) == same_pid : Bool}
  for +held: Repeat.Repeat.Held<kind,tracked,S.Simulation.players(T.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(world))>
  Mixed.If(same_pid,world,L.LiveCombat.run(world,kind,pid,score,planner))

def Mixed.same_inert(same_pid,world,kind,pid,score,planner,tracked,comparison,held,unique):
  match same_pid:
    case False{}: Unit{}
    case True{}:
      +plan = planner(L.LiveCombat.prepare(world,kind,pid,score))
      %N.Numeric.u32_eq_sound(tracked,pid,comparison) : R.Rejected.Inert<world,L.LiveCombat.at(world,kind,_,score,plan)>
      %Equal.sym(L.LiveCombat.Result,L.LiveCombat.at(world,kind,tracked,score,plan),Repeat.Repeat.quiet(world,tracked),Repeat.Repeat.live_rejected(world,kind,tracked,score,plan,held,unique)) : R.Rejected.Inert<world,_>
      R.Rejected.quiet_inert(world,tracked)

law Mixed.guarded:
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +protected: C.Combat.Kind
  for +tracked: U32
  for +held: Repeat.Repeat.Held<protected,tracked,S.Simulation.players(T.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(world))>
  Mixed.Guard(kind,protected,pid,tracked,world,L.LiveCombat.run(world,kind,pid,score,planner))

def Mixed.guarded(world,kind,pid,score,planner,protected,tracked,held,unique):
  match kind:
    case C.Combat.Attack{}:
      match protected:
        case C.Combat.Attack{}: Mixed.same_inert(U32.is_eq(tracked,pid),world,C.Combat.Attack{},pid,score,planner,tracked,{==},held,unique)
        case C.Combat.Spin{}: Unit{}
    case C.Combat.Spin{}:
      match protected:
        case C.Combat.Attack{}: Unit{}
        case C.Combat.Spin{}: Mixed.same_inert(U32.is_eq(tracked,pid),world,C.Combat.Spin{},pid,score,planner,tracked,{==},held,unique)

law Mixed.clock_held:
  for +world: T.Terrain.World
  for +now: U32
  for +kind: C.Combat.Kind
  for +pid: U32
  for +held: Repeat.Repeat.Held<kind,pid,S.Simulation.players(T.Terrain.simulation(world))>
  Repeat.Repeat.Held<kind,pid,S.Simulation.players(T.Terrain.simulation(Clock.WorldClock.set(world,now)))>

def Mixed.clock_held(world,now,kind,pid,held):
  %Equal.sym(List<&2,P.Players.State>,S.Simulation.players(T.Terrain.simulation(Clock.WorldClock.set(world,now))),S.Simulation.players(T.Terrain.simulation(world)),CC.CombatClock.players(world,now)) : Repeat.Repeat.Held<kind,pid,_>
  held

# Timestamps are clock updates only; gameplay ticks are not in this stream.
type Mixed.Request is Type:
  Mixed.Request{now: U32,kind: C.Combat.Kind,pid: U32,score: U32,planner: L.LiveCombat.Ready -> L.LiveCombat.Plan}

type Mixed.Entry is Data:
  Mixed.Entry{before: T.Terrain.World,kind: C.Combat.Kind,pid: U32,result: L.LiveCombat.Result}

type Mixed.Run is Data:
  Mixed.Run{world: T.Terrain.World,entries: List<&2,Mixed.Entry>}

def Mixed.world(run: Mixed.Run) -> T.Terrain.World:
  match run:
    case Mixed.Run{world,entries}: world

def Mixed.entries(run: Mixed.Run) -> List<&2,Mixed.Entry>:
  match run:
    case Mixed.Run{world,entries}: entries

def Mixed.prepend(entry: Mixed.Entry,+run: Mixed.Run) -> Mixed.Run: Mixed.Run{Mixed.world(run),Con{entry,Mixed.entries(run)}}

def Mixed.trace(requests: List<&1,Mixed.Request>,+world: T.Terrain.World) -> Mixed.Run:
  match requests:
    case Nil{}: Mixed.Run{world,Nil{}}
    case Con{head,rest}:
      match head:
        case Mixed.Request{now,kind,pid,score,planner}:
          +kind = kind
          +pid = pid
          +before = Clock.WorldClock.set(world,now)
          +result = L.LiveCombat.run(before,kind,pid,score,planner)
          Mixed.prepend(Mixed.Entry{before,kind,pid,result},Mixed.trace(rest,L.LiveCombat.world(result)))

def Mixed.EntryOK(entry: Mixed.Entry,+protected: C.Combat.Kind,+tracked: U32) -> Data:
  match entry:
    case Mixed.Entry{before,kind,pid,result}:
      +result = result
      +before = before
      +kind = kind
      +pid = pid
      Sigma<&2,&2,Repeat.Repeat.Held<protected,tracked,S.Simulation.players(T.Terrain.simulation(L.LiveCombat.world(result)))>,(held => Sigma<&2,&2,J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(L.LiveCombat.world(result)))>,(unique => Mixed.Guard(kind,protected,pid,tracked,before,result))>)>

def Mixed.All(entries: List<&2,Mixed.Entry>,+protected: C.Combat.Kind,+tracked: U32) -> Data:
  match entries:
    case Nil{}: Unit
    case Con{head,rest}:
      +rest = rest
      Sigma<&2,&2,Mixed.EntryOK(head,protected,tracked),(proof => Mixed.All(rest,protected,tracked))>

# The actual final world is retained as data, allowing affine callers to compose
# a subsequent command without evaluating the request callbacks a second time.
type Mixed.OK<-run: Mixed.Run,-protected: C.Combat.Kind,-tracked: U32> is Data:
  Mixed.OK{world: T.Terrain.World,same: {world == Mixed.world(run) : T.Terrain.World},held: Repeat.Repeat.Held<protected,tracked,S.Simulation.players(T.Terrain.simulation(world))>,unique: J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(world))>,all: Mixed.All(Mixed.entries(run),protected,tracked)}

law Mixed.add:
  for +entry: Mixed.Entry
  for -run: Mixed.Run
  for +protected: C.Combat.Kind
  for +tracked: U32
  for +entry_ok: Mixed.EntryOK(entry,protected,tracked)
  for +tail_ok: Mixed.OK<run,protected,tracked>
  Mixed.OK<Mixed.prepend(entry,run),protected,tracked>

def Mixed.add(entry,run,protected,tracked,entry_ok,tail_ok):
  match tail_ok:
    case Mixed.OK{world,same,held,unique,all}: Mixed.OK{world,same,held,unique,Tuple{entry_ok,all}}

law Mixed.safe:
  for requests: List<&1,Mixed.Request>
  for +world: T.Terrain.World
  for +protected: C.Combat.Kind
  for +tracked: U32
  for +held: Repeat.Repeat.Held<protected,tracked,S.Simulation.players(T.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(world))>
  Mixed.OK<Mixed.trace(requests,world),protected,tracked>

def Mixed.safe(requests,world,protected,tracked,held,unique):
  match requests:
    case Nil{}: Mixed.OK{world,{==},held,unique,Unit{}}
    case Con{head,rest}:
      match head:
        case Mixed.Request{now,kind,pid,score,planner}:
          +now = now
          +kind = kind
          +pid = pid
          +score = score
          +before = Clock.WorldClock.set(world,now)
          +before_held = Mixed.clock_held(world,now,protected,tracked,held)
          +before_unique = CC.CombatClock.unique(world,now,unique)
          +plan = planner(L.LiveCombat.prepare(before,kind,pid,score))
          +result = L.LiveCombat.at(before,kind,pid,score,plan)
          +after_held = Mixed.live_held(before,kind,pid,score,(unused => plan),protected,tracked,before_held,before_unique)
          +after_unique = Repeat.Repeat.at_unique(before,kind,pid,score,plan,before_unique)
          Mixed.add(Mixed.Entry{before,kind,pid,result},Mixed.trace(rest,L.LiveCombat.world(result)),protected,tracked,Tuple{after_held,Tuple{after_unique,Mixed.guarded(before,kind,pid,score,(unused => plan),protected,tracked,before_held,before_unique)}},Mixed.safe(rest,L.LiveCombat.world(result),protected,tracked,after_held,after_unique))

law Mixed.retry_from:
  for -run: Mixed.Run
  for +protected: C.Combat.Kind
  for +tracked: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +valid: Mixed.OK<run,protected,tracked>
  R.Rejected.Inert<Mixed.world(run),L.LiveCombat.run(Mixed.world(run),protected,tracked,score,planner)>

def Mixed.retry_from(run,protected,tracked,score,planner,valid):
  match valid:
    case Mixed.OK{world,same,held,unique,all}:
      %same : R.Rejected.Inert<_,L.LiveCombat.run(_,protected,tracked,score,planner)>
      +plan = planner(L.LiveCombat.prepare(world,protected,tracked,score))
      %Equal.sym(L.LiveCombat.Result,L.LiveCombat.at(world,protected,tracked,score,plan),Repeat.Repeat.quiet(world,tracked),Repeat.Repeat.live_rejected(world,protected,tracked,score,plan,held,unique)) : R.Rejected.Inert<world,_>
      R.Rejected.quiet_inert(world,tracked)

law Mixed.retry:
  for requests: List<&1,Mixed.Request>
  for +world: T.Terrain.World
  for +protected: C.Combat.Kind
  for +tracked: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +held: Repeat.Repeat.Held<protected,tracked,S.Simulation.players(T.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(world))>
  R.Rejected.Inert<Mixed.world(Mixed.trace(requests,world)),L.LiveCombat.run(Mixed.world(Mixed.trace(requests,world)),protected,tracked,score,planner)>

def Mixed.retry(requests,world,protected,tracked,score,planner,held,unique): Mixed.retry_from(Mixed.trace(requests,world),protected,tracked,score,planner,Mixed.safe(requests,world,protected,tracked,held,unique))

def Mixed.requests(requests: List<&1,Mixed.Request>) -> Nat:
  match requests:
    case Nil{}: Zero{}
    case Con{head,rest}: Succ{Mixed.requests(rest)}

def Mixed.count(entries: List<&2,Mixed.Entry>) -> Nat:
  match entries:
    case Nil{}: Zero{}
    case Con{head,rest}: Succ{Mixed.count(rest)}

law Mixed.length:
  for requests: List<&1,Mixed.Request>
  for +world: T.Terrain.World
  {Mixed.count(Mixed.entries(Mixed.trace(requests,world))) == Mixed.requests(requests) : Nat}

def Mixed.length(requests,world):
  match requests:
    case Nil{}: {==}
    case Con{head,rest}:
      match head:
        case Mixed.Request{now,kind,pid,score,planner}:
          +result = L.LiveCombat.run(Clock.WorldClock.set(world,now),kind,pid,score,planner)
          %Mixed.length(rest,L.LiveCombat.world(result)) : {Succ{Mixed.count(Mixed.entries(Mixed.trace(rest,L.LiveCombat.world(result))))} == Succ{_} : Nat}
          {==}

# A real accepted first command supplies the lock for the entire mixed suffix.
def Mixed.WhenAccepted(ready: L.LiveCombat.Ready,+run: Mixed.Run,+kind: C.Combat.Kind) -> Data:
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}: Unit
            case Some{player}: Mixed.OK<run,kind,pid>

law Mixed.accepted_tail:
  for +ready: L.LiveCombat.Ready
  for requests: List<&1,Mixed.Request>
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +held: Repeat.Repeat.WhenAccepted(ready,kind,world)
  for +unique: J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(world))>
  Mixed.WhenAccepted(ready,Mixed.trace(requests,world),kind)

def Mixed.accepted_tail(ready,requests,world,kind,held,unique):
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}: Unit{}
            case Some{player}: Mixed.safe(requests,world,kind,pid,held,unique)

law Mixed.after_first:
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for requests: List<&1,Mixed.Request>
  for +unique: J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(world))>
  Mixed.WhenAccepted(L.LiveCombat.prepare(world,kind,pid,score),Mixed.trace(requests,L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,planner))),kind)

def Mixed.after_first(world,kind,pid,score,planner,requests,unique):
  +ready = L.LiveCombat.prepare(world,kind,pid,score)
  +plan = planner(ready)
  Mixed.accepted_tail(ready,requests,L.LiveCombat.world(L.LiveCombat.at(world,kind,pid,score,plan)),kind,Repeat.Repeat.run_held(world,kind,pid,score,(unused => plan)),Repeat.Repeat.at_unique(world,kind,pid,score,plan,unique))
