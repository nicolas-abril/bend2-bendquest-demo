# Clock changes between combat commands cannot release a same-kind cooldown.
import Base
import ./world_clock.bend as Clock
import ./simulation.bend as S
import ./terrain.bend as T
import ./players.bend as P
import ./combat.bend as C
import ./live_combat.bend as L
import ./combat_repeat.bend as Repeat
import ./combat_rejected.bend as R
import ./combat_admitted.bend as Admit
import ./admission.bend as J

law CombatClock.phase:
  for +meta: S.Simulation.Meta
  for +now: U32
  {S.Simulation.phase(Clock.WorldClock.meta(meta,now)) == S.Simulation.phase(meta) : U32}

def CombatClock.phase(meta,now):
  match meta:
    case S.Simulation.Meta{phase,world,seed,tick,started,old_now,sigils,fame,next_player,next_monster}: {==}

law CombatClock.players:
  for +world: T.Terrain.World
  for +now: U32
  {S.Simulation.players(T.Terrain.simulation(Clock.WorldClock.set(world,now))) == S.Simulation.players(T.Terrain.simulation(world)) : List<&2,P.Players.State>}

def CombatClock.players(world,now):
  match world:
    case T.Terrain.World{meta,players,monsters,maps}: {==}

law CombatClock.unique:
  for +world: T.Terrain.World
  for +now: U32
  for +unique: J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(world))>
  J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(Clock.WorldClock.set(world,now)))>

def CombatClock.unique(world,now,unique):
  %Equal.sym(List<&2,P.Players.State>,S.Simulation.players(T.Terrain.simulation(Clock.WorldClock.set(world,now))),S.Simulation.players(T.Terrain.simulation(world)),CombatClock.players(world,now)) : J.Admission.Unique<_>
  unique

law CombatClock.held:
  for +ready: L.LiveCombat.Ready
  for +kind: C.Combat.Kind
  for +world: T.Terrain.World
  for +now: U32
  for +held: Repeat.Repeat.WhenAccepted(ready,kind,world)
  Repeat.Repeat.WhenAccepted(ready,kind,Clock.WorldClock.set(world,now))

def CombatClock.held(ready,kind,world,now,held):
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}: Unit{}
            case Some{player}:
              %Equal.sym(List<&2,P.Players.State>,S.Simulation.players(T.Terrain.simulation(Clock.WorldClock.set(world,now))),S.Simulation.players(T.Terrain.simulation(world)),CombatClock.players(world,now)) : Repeat.Repeat.Held<kind,pid,_>
              held

law CombatClock.replay:
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +kind: C.Combat.Kind
  for +pid: U32
  for +now: U32
  for +replay: {C.Combat.run(players,pid,kind,S.Simulation.phase(meta)) == C.Combat.Result{players,None{}} : C.Combat.Result}
  {C.Combat.run(players,pid,kind,S.Simulation.phase(Clock.WorldClock.meta(meta,now))) == C.Combat.Result{players,None{}} : C.Combat.Result}

def CombatClock.replay(meta,players,kind,pid,now,replay):
  %Equal.sym(U32,S.Simulation.phase(Clock.WorldClock.meta(meta,now)),S.Simulation.phase(meta),CombatClock.phase(meta,now)) : {C.Combat.run(players,pid,kind,_) == C.Combat.Result{players,None{}} : C.Combat.Result}
  replay

law CombatClock.combine:
  for +ready: L.LiveCombat.Ready
  for +kind: C.Combat.Kind
  for +first: L.LiveCombat.Plan
  for +now: U32
  for +score: U32
  for +second: L.LiveCombat.Plan
  for +replay: R.Rejected.Replay(ready,kind)
  for +accepted: Repeat.Repeat.Outcome(ready,Clock.WorldClock.set(L.LiveCombat.world(L.LiveCombat.finish(ready,first)),now),L.LiveCombat.at(Clock.WorldClock.set(L.LiveCombat.world(L.LiveCombat.finish(ready,first)),now),kind,Repeat.Repeat.pid(ready),score,second))
  R.Rejected.Inert<Clock.WorldClock.set(L.LiveCombat.world(L.LiveCombat.finish(ready,first)),now),L.LiveCombat.at(Clock.WorldClock.set(L.LiveCombat.world(L.LiveCombat.finish(ready,first)),now),kind,Repeat.Repeat.pid(ready),score,second)>

def CombatClock.combine(ready,kind,first,now,score,second,replay,accepted):
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,first_score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}:
              +world = Clock.WorldClock.set(T.Terrain.World{meta,players,monsters,maps},now)
              %Equal.sym(L.LiveCombat.Result,L.LiveCombat.at(world,kind,pid,score,second),L.LiveCombat.Result{world,Nil{},L.LiveCombat.Quiet{}},R.Rejected.at_same(world,kind,pid,score,second,CombatClock.replay(meta,players,kind,pid,now,replay))) : R.Rejected.Inert<world,_>
              R.Rejected.same_inert(world)
            case Some{player}:
              +ready = {L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,Some{player}},pid,first_score} : L.LiveCombat.Ready}
              +world = Clock.WorldClock.set(L.LiveCombat.world(L.LiveCombat.finish(ready,first)),now)
              %Equal.sym(L.LiveCombat.Result,L.LiveCombat.at(world,kind,pid,score,second),Repeat.Repeat.quiet(world,pid),accepted) : R.Rejected.Inert<world,_>
              R.Rejected.quiet_inert(world,pid)

# Arbitrary timestamp, scores and state-dependent affine planners. No first-
# admission premise; Inert is relative to the world with the new clock value.
law CombatClock.live_twice:
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +first_score: U32
  for +now: U32
  for +second_score: U32
  for first: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for second: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +unique: J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(world))>
  R.Rejected.Inert<Clock.WorldClock.set(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,first_score,first)),now),L.LiveCombat.run(Clock.WorldClock.set(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,first_score,first)),now),kind,pid,second_score,second)>

def CombatClock.live_twice(world,kind,pid,first_score,now,second_score,first,second,unique):
  +ready = L.LiveCombat.prepare(world,kind,pid,first_score)
  +plan = first(ready)
  +after = L.LiveCombat.world(L.LiveCombat.finish(ready,plan))
  +timed = Clock.WorldClock.set(after,now)
  +next = second(L.LiveCombat.prepare(timed,kind,pid,second_score))
  %Repeat.Repeat.ready_pid(world,kind,pid,first_score) : R.Rejected.Inert<timed,L.LiveCombat.at(timed,kind,_,second_score,next)>
  CombatClock.combine(ready,kind,plan,now,second_score,next,R.Rejected.prepared_replay(world,kind,pid,first_score),Repeat.Repeat.repeat_after(ready,kind,timed,second_score,(unused => next),CombatClock.held(ready,kind,after,now,Repeat.Repeat.finish_held(ready,kind,plan,Admit.Admitted.live_prepare(world,kind,pid,first_score),Repeat.Repeat.prepare_cooled(world,kind,pid,first_score))),CombatClock.unique(after,now,Repeat.Repeat.at_unique(world,kind,pid,first_score,plan,unique))))
