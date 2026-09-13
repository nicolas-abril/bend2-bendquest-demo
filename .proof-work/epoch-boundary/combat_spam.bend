# Finite same-kind/PID command streams, with actual affine planners and clocks.
import Base
import ./combat.bend as C
import ./live_combat.bend as L
import ./terrain.bend as T
import ./simulation.bend as S
import ./admission.bend as J
import ./combat_repeat.bend as Repeat
import ./combat_rejected.bend as R
import ./combat_clock.bend as CC
import ./world_clock.bend as Clock

# Each callback is consumed once and sees its own actual prepared world.
type Spam.Request is Type:
  Spam.Request{now: U32,score: U32,planner: L.LiveCombat.Ready -> L.LiveCombat.Plan}

type Spam.Entry is Data:
  Spam.Entry{before: T.Terrain.World,result: L.LiveCombat.Result}

def Spam.trace(requests: List<&1,Spam.Request>,+world: T.Terrain.World,+kind: C.Combat.Kind,+pid: U32) -> List<&2,Spam.Entry>:
  match requests:
    case Nil{}: Nil{}
    case Con{head,rest}:
      match head:
        case Spam.Request{now,score,planner}:
          +before = Clock.WorldClock.set(world,now)
          +result = L.LiveCombat.run(before,kind,pid,score,planner)
          Con{Spam.Entry{before,result},Spam.trace(rest,L.LiveCombat.world(result),kind,pid)}

def Spam.Inert(entry: Spam.Entry) -> Data:
  match entry:
    case Spam.Entry{before,result}: R.Rejected.Inert<before,result>

def Spam.All(entries: List<&2,Spam.Entry>) -> Data:
  match entries:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,Spam.Inert(head),(proof => Spam.All(rest))>

def Spam.AfterFirst(entries: List<&2,Spam.Entry>) -> Data:
  match entries:
    case Nil{}: Unit
    case Con{head,rest}: Spam.All(rest)

# A trace suffix starts after a real completed command, not an assumed lock.
law Spam.tail:
  for requests: List<&1,Spam.Request>
  for +before: T.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for +plan: L.LiveCombat.Plan
  for +unique: J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(before))>
  Spam.All(Spam.trace(requests,L.LiveCombat.world(L.LiveCombat.at(before,kind,pid,score,plan)),kind,pid))

def Spam.tail(requests,before,kind,pid,score,plan,unique):
  match requests:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match head:
        case Spam.Request{now,next_score,planner}:
          +now = now
          +next_score = next_score
          +after = L.LiveCombat.world(L.LiveCombat.at(before,kind,pid,score,plan))
          +timed = Clock.WorldClock.set(after,now)
          +next = planner(L.LiveCombat.prepare(timed,kind,pid,next_score))
          Tuple{CC.CombatClock.live_twice(before,kind,pid,score,now,next_score,(unused => plan),(unused => next),unique),Spam.tail(rest,timed,kind,pid,next_score,next,CC.CombatClock.unique(after,now,Repeat.Repeat.at_unique(before,kind,pid,score,plan,unique)))}

# Every entry after the first is inert, including rejected-first streams.
law Spam.safe:
  for requests: List<&1,Spam.Request>
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +unique: J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(world))>
  Spam.AfterFirst(Spam.trace(requests,world,kind,pid))

def Spam.safe(requests,world,kind,pid,unique):
  match requests:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match head:
        case Spam.Request{now,score,planner}:
          +now = now
          +score = score
          +before = Clock.WorldClock.set(world,now)
          +plan = planner(L.LiveCombat.prepare(before,kind,pid,score))
          Spam.tail(rest,before,kind,pid,score,plan,CC.CombatClock.unique(world,now,unique))

# Cardinality and exact step equations tie the audit to every input request.
def Spam.requests(requests: List<&1,Spam.Request>) -> Nat:
  match requests:
    case Nil{}: Zero{}
    case Con{head,rest}: Succ{Spam.requests(rest)}

def Spam.entries(entries: List<&2,Spam.Entry>) -> Nat:
  match entries:
    case Nil{}: Zero{}
    case Con{head,rest}: Succ{Spam.entries(rest)}

law Spam.length:
  for requests: List<&1,Spam.Request>
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  {Spam.entries(Spam.trace(requests,world,kind,pid)) == Spam.requests(requests) : Nat}

def Spam.length(requests,world,kind,pid):
  match requests:
    case Nil{}: {==}
    case Con{head,rest}:
      match head:
        case Spam.Request{now,score,planner}:
          +result = L.LiveCombat.run(Clock.WorldClock.set(world,now),kind,pid,score,planner)
          %Spam.length(rest,L.LiveCombat.world(result),kind,pid) : {Succ{Spam.entries(Spam.trace(rest,L.LiveCombat.world(result),kind,pid))} == Succ{_} : Nat}
          {==}

law Spam.nil:
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  {Spam.trace(Nil{},world,kind,pid) == Nil{} : List<&2,Spam.Entry>}

def Spam.nil(world,kind,pid): {==}

law Spam.cons:
  for +now: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for rest: List<&1,Spam.Request>
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  {Spam.trace(Con{Spam.Request{now,score,planner},rest},world,kind,pid) == Con{Spam.Entry{Clock.WorldClock.set(world,now),L.LiveCombat.run(Clock.WorldClock.set(world,now),kind,pid,score,planner)},Spam.trace(rest,L.LiveCombat.world(L.LiveCombat.run(Clock.WorldClock.set(world,now),kind,pid,score,planner)),kind,pid)} : List<&2,Spam.Entry>}

def Spam.cons(now,score,planner,rest,world,kind,pid): {==}
