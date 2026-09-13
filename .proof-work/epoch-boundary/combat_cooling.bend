# Positive cooldowns remain unavailable, including after partial tick decay.
import Base
import ./combat.bend as C
import ./players.bend as P
import ./targeting.bend as T
import ./playerids.bend as Id
import ./bindings.bend as Bind
import ./combat_repeat.bend as Repeat
import ./combat_rejected.bend as R
import ./combat_other.bend as Other
import ./combat_foreign.bend as Foreign
import ./combat_actor.bend as Actor
import ./payouts.bend as Pay
import ./live_combat.bend as L
import ./simulation.bend as S
import ./terrain.bend as Terrain
import ./admission.bend as J
import ./numeric.bend as N
import ./cooldown_actor.bend as Tracked
import ./cooldown_roster.bend as TC
import ./live_tick.bend as Tick
import ./seeded_world.bend as SW
import ./connections.bend as Conn
import ./sessions.bend as Sess
import ./worldstate.bend as WS

def Cooling.Positive(+kind: C.Combat.Kind,+player: P.Players.State) -> Data: {U32.is_gt(C.Combat.cooldown(kind,P.Players.vitals(player)),0) == True{} : Bool}

type Cooling.Held<-kind: C.Combat.Kind,-pid: U32,-players: List<&2,P.Players.State>> is Data:
  Cooling.Held{player: P.Players.State,inside: T.Targeting.In<player,players>,same: {P.Players.id(player) == pid : U32},positive: Cooling.Positive(kind,player)}

law Cooling.reject_taken:
  for +taken: P.Players.Take
  for +kind: C.Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  for +same: {P.Players.found(taken) == Some{player} : Maybe<&2,P.Players.State>}
  for +locked: Cooling.Positive(kind,player)
  {C.Combat.apply_taken(taken,kind,phase) == C.Combat.Result{P.Players.restore(taken),None{}} : C.Combat.Result}

def Cooling.reject_taken(taken,kind,phase,player,same,locked):
  match taken:
    case P.Players.Take{others,found}:
      %Equal.sym(Maybe<&2,P.Players.State>,found,Some{player},same) : {C.Combat.apply_taken(P.Players.Take{others,_},kind,phase) == C.Combat.Result{P.Players.restore(P.Players.Take{others,_}),None{}} : C.Combat.Result}
      %Equal.sym(C.Combat.Step,C.Combat.prepare(kind,phase,player),C.Combat.Step{player,False{}},C.Combat.cooling_rejected(kind,phase,player,locked)) : {C.Combat.finish(_,others) == C.Combat.Result{Con{player,others},None{}} : C.Combat.Result}
      {==}

law Cooling.held_rejected:
  for +players: List<&2,P.Players.State>
  for +kind: C.Combat.Kind
  for +pid: U32
  for +phase: U32
  for +held: Cooling.Held<kind,pid,players>
  for +unique: J.Admission.Unique<players>
  {C.Combat.run(players,pid,kind,phase) == C.Combat.Result{P.Players.restore(P.Players.take(players,pid)),None{}} : C.Combat.Result}

def Cooling.held_rejected(players,kind,pid,phase,held,unique):
  match held:
    case Cooling.Held{player,inside,same,locked}: Cooling.reject_taken(P.Players.take(players,pid),kind,phase,player,(%same : {P.Players.found(P.Players.take(players,_)) == Some{player} : Maybe<&2,P.Players.State>}; Repeat.Repeat.lookup_member(player,players,inside,Id.PlayerIds.from_admission(Id.PlayerIds.Player{},players,unique))),locked)

law Cooling.live_rejected:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for +plan: L.LiveCombat.Plan
  for +held: Cooling.Held<kind,pid,S.Simulation.players(Terrain.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(Terrain.Terrain.simulation(world))>
  {L.LiveCombat.at(world,kind,pid,score,plan) == Repeat.Repeat.quiet(world,pid) : L.LiveCombat.Result}

def Cooling.live_rejected(world,kind,pid,score,plan,held,unique):
  match world:
    case Terrain.Terrain.World{meta,players,monsters,maps}:
      %Equal.sym(C.Combat.Result,C.Combat.run(players,pid,kind,S.Simulation.phase(meta)),C.Combat.Result{P.Players.restore(P.Players.take(players,pid)),None{}},Cooling.held_rejected(players,kind,pid,S.Simulation.phase(meta),held,unique)) : {L.LiveCombat.finish(L.LiveCombat.Ready{meta,monsters,maps,_,pid,score},plan) == Repeat.Repeat.quiet(Terrain.Terrain.World{meta,players,monsters,maps},pid) : L.LiveCombat.Result}
      L.LiveCombat.finish_rejected(meta,P.Players.restore(P.Players.take(players,pid)),monsters,maps,pid,score,plan)

law Cooling.live_run_rejected:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +held: Cooling.Held<kind,pid,S.Simulation.players(Terrain.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(Terrain.Terrain.simulation(world))>
  {L.LiveCombat.run(world,kind,pid,score,planner) == Repeat.Repeat.quiet(world,pid) : L.LiveCombat.Result}

def Cooling.live_run_rejected(world,kind,pid,score,planner,held,unique): Cooling.live_rejected(world,kind,pid,score,planner(L.LiveCombat.prepare(world,kind,pid,score)),held,unique)

law Cooling.inert:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +held: Cooling.Held<kind,pid,S.Simulation.players(Terrain.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(Terrain.Terrain.simulation(world))>
  R.Rejected.Inert<world,L.LiveCombat.run(world,kind,pid,score,planner)>

def Cooling.inert(world,kind,pid,score,planner,held,unique):
  %Equal.sym(L.LiveCombat.Result,L.LiveCombat.run(world,kind,pid,score,planner),Repeat.Repeat.quiet(world,pid),Cooling.live_run_rejected(world,kind,pid,score,planner,held,unique)) : R.Rejected.Inert<world,_>
  R.Rejected.quiet_inert(world,pid)

law Cooling.frame_positive:
  for +kind: C.Combat.Kind
  for +before: P.Players.State
  for +after: P.Players.State
  for +same: {Pay.Payout.frame(after) == Pay.Payout.frame(before) : Pay.Payout.Frame}
  for +positive: Cooling.Positive(kind,before)
  Cooling.Positive(kind,after)

def Cooling.frame_positive(kind,before,after,same,positive):
  %Repeat.Repeat.frame_cooldown_of(kind,after) : {U32.is_gt(_,0) == True{} : Bool}
  %Equal.sym(Pay.Payout.Frame,Pay.Payout.frame(after),Pay.Payout.frame(before),same) : {U32.is_gt(Repeat.Repeat.frame_cooldown(kind,_),0) == True{} : Bool}
  %Equal.sym(U32,Repeat.Repeat.frame_cooldown(kind,Pay.Payout.frame(before)),C.Combat.cooldown(kind,P.Players.vitals(before)),Repeat.Repeat.frame_cooldown_of(kind,before)) : {U32.is_gt(_,0) == True{} : Bool}
  positive

law Cooling.member_held:
  for +kind: C.Combat.Kind
  for +pid: U32
  for +before: P.Players.State
  for -players: List<&2,P.Players.State>
  for +member: Actor.Actor.Member<before,players>
  for +same: {P.Players.id(before) == pid : U32}
  for +positive: Cooling.Positive(kind,before)
  Cooling.Held<kind,pid,players>

def Cooling.member_held(kind,pid,before,players,member,same,positive):
  match member:
    case Actor.Actor.Member{after,inside,equal}: Cooling.Held{after,inside,Equal.trans(U32,P.Players.id(after),P.Players.id(before),pid,Actor.Actor.same_pid(after,before,equal),same),Cooling.frame_positive(kind,before,after,equal,positive)}

law Cooling.foreign:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +protected: C.Combat.Kind
  for +tracked: U32
  for +different: {U32.is_eq(tracked,pid) == False{} : Bool}
  for +held: Cooling.Held<protected,tracked,S.Simulation.players(Terrain.Terrain.simulation(world))>
  Cooling.Held<protected,tracked,S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,planner))))>

def Cooling.foreign(world,kind,pid,score,planner,protected,tracked,different,held):
  match held:
    case Cooling.Held{player,inside,same,positive}: Cooling.member_held(protected,tracked,player,S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,planner)))),Foreign.Foreign.live(world,kind,pid,score,planner,player,(%Equal.sym(U32,P.Players.id(player),tracked,same) : {U32.is_eq(_,pid) == False{} : Bool}; different),inside),same,positive)

law Cooling.other_member:
  for +kind: C.Combat.Kind
  for +pid: U32
  for +before: P.Players.State
  for -players: List<&2,P.Players.State>
  for +member: Other.Other.Member<kind,before,players>
  for +same: {P.Players.id(before) == pid : U32}
  for +positive: Cooling.Positive(C.Combat.other(kind),before)
  Cooling.Held<C.Combat.other(kind),pid,players>

def Cooling.other_member(kind,pid,before,players,member,same,positive):
  match member:
    case Other.Other.Member{after,inside,equal}:
      +pid_same = Equal.trans(U32,P.Players.id(after),P.Players.id(before),pid,(%Other.Other.pid_of(kind,after) : {_ == P.Players.id(before) : U32}; %Other.Other.pid_of(kind,before) : {Other.Other.pid(Other.Other.frame(kind,after)) == _ : U32}; Equal.cong(Other.Other.Frame,U32,(frame => Other.Other.pid(frame)),Other.Other.frame(kind,after),Other.Other.frame(kind,before),equal)),same)
      Cooling.Held{after,inside,pid_same,(%Other.Other.cooldown_of(kind,after) : {U32.is_gt(_,0) == True{} : Bool}; %Equal.sym(Other.Other.Frame,Other.Other.frame(kind,after),Other.Other.frame(kind,before),equal) : {U32.is_gt(Other.Other.cooldown(_),0) == True{} : Bool}; %Equal.sym(U32,Other.Other.cooldown(Other.Other.frame(kind,before)),C.Combat.cooldown(C.Combat.other(kind),P.Players.vitals(before)),Other.Other.cooldown_of(kind,before)) : {U32.is_gt(_,0) == True{} : Bool}; positive)}

law Cooling.other:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +tracked: U32
  for +held: Cooling.Held<C.Combat.other(kind),tracked,S.Simulation.players(Terrain.Terrain.simulation(world))>
  Cooling.Held<C.Combat.other(kind),tracked,S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,planner))))>

def Cooling.other(world,kind,pid,score,planner,tracked,held):
  match held:
    case Cooling.Held{player,inside,same,positive}: Cooling.other_member(kind,tracked,player,S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,planner)))),Other.Other.live(world,kind,pid,score,planner,player,inside),same,positive)

law Cooling.restored:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +held: Cooling.Held<kind,pid,S.Simulation.players(Terrain.Terrain.simulation(world))>
  Cooling.Held<kind,pid,S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(Repeat.Repeat.quiet(world,pid))))>

def Cooling.restored(world,kind,pid,held):
  match world:
    case Terrain.Terrain.World{meta,players,monsters,maps}:
      match held:
        case Cooling.Held{player,inside,same,locked}: Cooling.Held{player,Bind.Bindings.perm_member(player,P.Players.restore(P.Players.take(players,pid)),players,P.Players.take_restores(players,pid),inside),same,locked}

law Cooling.own:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +held: Cooling.Held<kind,pid,S.Simulation.players(Terrain.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(Terrain.Terrain.simulation(world))>
  Cooling.Held<kind,pid,S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,planner))))>

def Cooling.own(world,kind,pid,score,planner,held,unique):
  %Equal.sym(L.LiveCombat.Result,L.LiveCombat.run(world,kind,pid,score,planner),Repeat.Repeat.quiet(world,pid),Cooling.live_run_rejected(world,kind,pid,score,planner,held,unique)) : Cooling.Held<kind,pid,S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(_)))>
  Cooling.restored(world,kind,pid,held)

law Cooling.same_kind:
  for +same_pid: Bool
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +tracked: U32
  for +comparison: {U32.is_eq(tracked,pid) == same_pid : Bool}
  for +held: Cooling.Held<kind,tracked,S.Simulation.players(Terrain.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(Terrain.Terrain.simulation(world))>
  Cooling.Held<kind,tracked,S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,planner))))>

def Cooling.same_kind(same_pid,world,kind,pid,score,planner,tracked,comparison,held,unique):
  match same_pid:
    case False{}: Cooling.foreign(world,kind,pid,score,planner,kind,tracked,comparison,held)
    case True{}:
      +plan = planner(L.LiveCombat.prepare(world,kind,pid,score))
      %N.Numeric.u32_eq_sound(tracked,pid,comparison) : Cooling.Held<kind,tracked,S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.at(world,kind,_,score,plan))))>
      Cooling.own(world,kind,tracked,score,(unused => plan),held,unique)

law Cooling.live_held:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +protected: C.Combat.Kind
  for +tracked: U32
  for +held: Cooling.Held<protected,tracked,S.Simulation.players(Terrain.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(Terrain.Terrain.simulation(world))>
  Cooling.Held<protected,tracked,S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,planner))))>

def Cooling.live_held(world,kind,pid,score,planner,protected,tracked,held,unique):
  match kind:
    case C.Combat.Attack{}:
      match protected:
        case C.Combat.Attack{}: Cooling.same_kind(U32.is_eq(tracked,pid),world,C.Combat.Attack{},pid,score,planner,tracked,{==},held,unique)
        case C.Combat.Spin{}: Cooling.other(world,C.Combat.Attack{},pid,score,planner,tracked,held)
    case C.Combat.Spin{}:
      match protected:
        case C.Combat.Attack{}: Cooling.other(world,C.Combat.Spin{},pid,score,planner,tracked,held)
        case C.Combat.Spin{}: Cooling.same_kind(U32.is_eq(tracked,pid),world,C.Combat.Spin{},pid,score,planner,tracked,{==},held,unique)

law Cooling.after_command:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for first: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +protected: C.Combat.Kind
  for +tracked: U32
  for +retry_score: U32
  for retry: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +held: Cooling.Held<protected,tracked,S.Simulation.players(Terrain.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(Terrain.Terrain.simulation(world))>
  R.Rejected.Inert<L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,first)),L.LiveCombat.run(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,first)),protected,tracked,retry_score,retry)>

def Cooling.after_command(world,kind,pid,score,first,protected,tracked,retry_score,retry,held,unique):
  +plan = first(L.LiveCombat.prepare(world,kind,pid,score))
  +after = L.LiveCombat.world(L.LiveCombat.at(world,kind,pid,score,plan))
  Cooling.inert(after,protected,tracked,retry_score,retry,Cooling.live_held(world,kind,pid,score,(unused => plan),protected,tracked,held,unique),Repeat.Repeat.at_unique(world,kind,pid,score,plan,unique))

def Cooling.counter(kind: C.Combat.Kind,frame: TC.TickCooldown.Frame) -> U32:
  match kind:
    case C.Combat.Attack{}:
      match frame:
        case TC.TickCooldown.Frame{pid,cid,attack,spin}: attack
    case C.Combat.Spin{}:
      match frame:
        case TC.TickCooldown.Frame{pid,cid,attack,spin}: spin

law Cooling.counter_of:
  for +kind: C.Combat.Kind
  for +player: P.Players.State
  {Cooling.counter(kind,TC.TickCooldown.frame(player)) == C.Combat.cooldown(kind,P.Players.vitals(player)) : U32}

def Cooling.counter_of(kind,player):
  match kind:
    case C.Combat.Attack{}:
      match player:
        case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}: {==}
    case C.Combat.Spin{}:
      match player:
        case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}: {==}

def Cooling.next(+world: Terrain.Terrain.World,+kind: C.Combat.Kind,+player: P.Players.State) -> U32: Cooling.counter(kind,Tracked.Tracked.next(world,player))

# The premise is the computed next counter, not an assumed final roster/player.
law Cooling.observed:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +before: P.Players.State
  for -players: List<&2,P.Players.State>
  for +observed: Tracked.Tracked.Observed<Tracked.Tracked.next(world,before),players>
  for +positive: {U32.is_gt(Cooling.next(world,kind,before),0) == True{} : Bool}
  Cooling.Held<kind,P.Players.id(before),players>

def Cooling.observed(world,kind,before,players,observed,positive):
  match observed:
    case Tracked.Tracked.Observed{after,inside,same}:
      +running = U32.is_eq(S.Simulation.phase(S.Simulation.meta(Terrain.Terrain.simulation(world))),1)
      +pid_same = {(%Tracked.Tracked.next_pid(False{},after) : {_ == P.Players.id(before) : U32}; %Tracked.Tracked.next_pid(running,before) : {Tracked.Tracked.pid(TC.TickCooldown.frame(after)) == _ : U32}; Equal.cong(TC.TickCooldown.Frame,U32,(frame => Tracked.Tracked.pid(frame)),TC.TickCooldown.frame(after),Tracked.Tracked.next(world,before),same)) : {P.Players.id(after) == P.Players.id(before) : U32}}
      Cooling.Held{after,inside,pid_same,(%Cooling.counter_of(kind,after) : {U32.is_gt(_,0) == True{} : Bool}; %Equal.sym(TC.TickCooldown.Frame,TC.TickCooldown.frame(after),Tracked.Tracked.next(world,before),same) : {U32.is_gt(Cooling.counter(kind,_),0) == True{} : Bool}; positive)}

law Cooling.tick:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +player: P.Players.State
  for +timer: U32
  for +inside: T.Targeting.In<player,S.Simulation.players(Terrain.Terrain.simulation(world))>
  for +positive: {U32.is_gt(Cooling.next(world,kind,player),0) == True{} : Bool}
  Cooling.Held<kind,P.Players.id(player),S.Simulation.players(Terrain.Terrain.simulation(Tick.LiveTick.world(Tick.LiveTick.run(world,timer))))>

def Cooling.tick(world,kind,player,timer,inside,positive): Cooling.observed(world,kind,player,S.Simulation.players(Terrain.Terrain.simulation(Tick.LiveTick.world(Tick.LiveTick.run(world,timer)))),Tracked.Tracked.live(world,player,timer,inside),positive)

def Cooling.unique(-world: Terrain.Terrain.World,-states: List<&2,Sess.Sessions.State>,valid: SW.SeededWorld.OK<world,states>) -> J.Admission.Unique<S.Simulation.players(Terrain.Terrain.simulation(world))>:
  match valid:
    case SW.SeededWorld.OK{world_ok,maps}:
      match world_ok:
        case Conn.Connections.WorldOK{world_valid,connections}:
          match world_valid:
            case WS.WorldState.OK{health,positions,monsters,players,nonzero,references}: players

law Cooling.tick_inert:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +player: P.Players.State
  for +timer: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +states: List<&2,Sess.Sessions.State>
  for +valid: SW.SeededWorld.OK<world,states>
  for +inside: T.Targeting.In<player,S.Simulation.players(Terrain.Terrain.simulation(world))>
  for +positive: {U32.is_gt(Cooling.next(world,kind,player),0) == True{} : Bool}
  R.Rejected.Inert<Tick.LiveTick.world(Tick.LiveTick.run(world,timer)),L.LiveCombat.run(Tick.LiveTick.world(Tick.LiveTick.run(world,timer)),kind,P.Players.id(player),score,planner)>

def Cooling.tick_inert(world,kind,player,timer,score,planner,states,valid,inside,positive):
  +after = Tick.LiveTick.world(Tick.LiveTick.run(world,timer))
  Cooling.inert(after,kind,P.Players.id(player),score,planner,Cooling.tick(world,kind,player,timer,inside,positive),Cooling.unique(after,states,Tick.LiveTick.seeded(world,timer,states,valid)))

law Cooling.tick_command:
  for +world: Terrain.Terrain.World
  for +protected: C.Combat.Kind
  for +player: P.Players.State
  for +timer: U32
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for first: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +retry_score: U32
  for retry: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +states: List<&2,Sess.Sessions.State>
  for +valid: SW.SeededWorld.OK<world,states>
  for +inside: T.Targeting.In<player,S.Simulation.players(Terrain.Terrain.simulation(world))>
  for +positive: {U32.is_gt(Cooling.next(world,protected,player),0) == True{} : Bool}
  R.Rejected.Inert<L.LiveCombat.world(L.LiveCombat.run(Tick.LiveTick.world(Tick.LiveTick.run(world,timer)),kind,pid,score,first)),L.LiveCombat.run(L.LiveCombat.world(L.LiveCombat.run(Tick.LiveTick.world(Tick.LiveTick.run(world,timer)),kind,pid,score,first)),protected,P.Players.id(player),retry_score,retry)>

def Cooling.tick_command(world,protected,player,timer,kind,pid,score,first,retry_score,retry,states,valid,inside,positive):
  +after = Tick.LiveTick.world(Tick.LiveTick.run(world,timer))
  Cooling.after_command(after,kind,pid,score,first,protected,P.Players.id(player),retry_score,retry,Cooling.tick(world,protected,player,timer,inside,positive),Cooling.unique(after,states,Tick.LiveTick.seeded(world,timer,states,valid)))
