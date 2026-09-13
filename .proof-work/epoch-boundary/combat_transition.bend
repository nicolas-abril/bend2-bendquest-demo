# Exact tracked-player frames through any combat command, including zero cooldown.
import Base
import ./combat.bend as C
import ./players.bend as P
import ./targeting.bend as T
import ./playerids.bend as Id
import ./admission.bend as J
import ./combat_repeat.bend as Repeat
import ./combat_foreign.bend as Foreign
import ./combat_actor.bend as Actor
import ./combat_admitted.bend as Admit
import ./live_combat.bend as L
import ./simulation.bend as S
import ./terrain.bend as Terrain
import ./numeric.bend as N
import ./payouts.bend as Pay
import ./vitals.bend as V
import ./cooldown_roster.bend as TC
import ./cooldown_actor.bend as Tracked

# A command prepares this player exactly when its requested PID matches.
def Transition.choose(same: Bool,+kind: C.Combat.Kind,+phase: U32,+player: P.Players.State) -> P.Players.State:
  match same:
    case False{}: player
    case True{}: C.Combat.player(C.Combat.prepare(kind,phase,player))

def Transition.expected(+world: Terrain.Terrain.World,+kind: C.Combat.Kind,+pid: U32,+player: P.Players.State) -> P.Players.State: Transition.choose(U32.is_eq(P.Players.id(player),pid),kind,S.Simulation.phase(S.Simulation.meta(Terrain.Terrain.simulation(world))),player)

law Transition.taken:
  for +taken: P.Players.Take
  for +kind: C.Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  for +same: {P.Players.found(taken) == Some{player} : Maybe<&2,P.Players.State>}
  T.Targeting.In<C.Combat.player(C.Combat.prepare(kind,phase,player)),C.Combat.roster(C.Combat.apply_taken(taken,kind,phase))>

def Transition.taken(taken,kind,phase,player,same):
  match taken:
    case P.Players.Take{others,found}:
      %Equal.sym(Maybe<&2,P.Players.State>,found,Some{player},same) : T.Targeting.In<C.Combat.player(C.Combat.prepare(kind,phase,player)),C.Combat.roster(C.Combat.apply_taken(P.Players.Take{others,_},kind,phase))>
      T.Targeting.Here{others,C.Combat.finish_roster(C.Combat.prepare(kind,phase,player),others)}

law Transition.admission:
  for +players: List<&2,P.Players.State>
  for +kind: C.Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  for +inside: T.Targeting.In<player,players>
  for +unique: J.Admission.Unique<players>
  T.Targeting.In<C.Combat.player(C.Combat.prepare(kind,phase,player)),C.Combat.roster(C.Combat.run(players,P.Players.id(player),kind,phase))>

def Transition.admission(players,kind,phase,player,inside,unique): Transition.taken(P.Players.take(players,P.Players.id(player)),kind,phase,player,Repeat.Repeat.lookup_member(player,players,inside,Id.PlayerIds.from_admission(Id.PlayerIds.Player{},players,unique)))

law Transition.prepared:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +score: U32
  for +player: P.Players.State
  for +inside: T.Targeting.In<player,S.Simulation.players(Terrain.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(Terrain.Terrain.simulation(world))>
  Foreign.Foreign.Ready(L.LiveCombat.prepare(world,kind,P.Players.id(player),score),C.Combat.player(C.Combat.prepare(kind,S.Simulation.phase(S.Simulation.meta(Terrain.Terrain.simulation(world))),player)))

def Transition.prepared(world,kind,score,player,inside,unique):
  match world:
    case Terrain.Terrain.World{meta,players,monsters,maps}: Actor.Actor.Member{C.Combat.player(C.Combat.prepare(kind,S.Simulation.phase(meta),player)),Transition.admission(players,kind,S.Simulation.phase(meta),player,inside,unique),{==}}

law Transition.own:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +player: P.Players.State
  for +inside: T.Targeting.In<player,S.Simulation.players(Terrain.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(Terrain.Terrain.simulation(world))>
  Actor.Actor.Member<C.Combat.player(C.Combat.prepare(kind,S.Simulation.phase(S.Simulation.meta(Terrain.Terrain.simulation(world))),player)),S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.run(world,kind,P.Players.id(player),score,planner))))>

def Transition.own(world,kind,score,planner,player,inside,unique):
  +ready = L.LiveCombat.prepare(world,kind,P.Players.id(player),score)
  Foreign.Foreign.finished(ready,C.Combat.player(C.Combat.prepare(kind,S.Simulation.phase(S.Simulation.meta(Terrain.Terrain.simulation(world))),player)),planner(ready),Transition.prepared(world,kind,score,player,inside,unique))

law Transition.branch:
  for +same_pid: Bool
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +player: P.Players.State
  for +comparison: {U32.is_eq(P.Players.id(player),pid) == same_pid : Bool}
  for +inside: T.Targeting.In<player,S.Simulation.players(Terrain.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(Terrain.Terrain.simulation(world))>
  Actor.Actor.Member<Transition.choose(same_pid,kind,S.Simulation.phase(S.Simulation.meta(Terrain.Terrain.simulation(world))),player),S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,planner))))>

def Transition.branch(same_pid,world,kind,pid,score,planner,player,comparison,inside,unique):
  match same_pid:
    case False{}: Foreign.Foreign.live(world,kind,pid,score,planner,player,comparison,inside)
    case True{}:
      +plan = planner(L.LiveCombat.prepare(world,kind,pid,score))
      %N.Numeric.u32_eq_sound(P.Players.id(player),pid,comparison) : Actor.Actor.Member<C.Combat.player(C.Combat.prepare(kind,S.Simulation.phase(S.Simulation.meta(Terrain.Terrain.simulation(world))),player)),S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.at(world,kind,_,score,plan))))>
      Transition.own(world,kind,score,(unused => plan),player,inside,unique)

# No positivity, readiness, active-phase, or survival assumption.
law Transition.live:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +player: P.Players.State
  for +inside: T.Targeting.In<player,S.Simulation.players(Terrain.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(Terrain.Terrain.simulation(world))>
  Actor.Actor.Member<Transition.expected(world,kind,pid,player),S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,planner))))>

def Transition.live(world,kind,pid,score,planner,player,inside,unique): Transition.branch(U32.is_eq(P.Players.id(player),pid),world,kind,pid,score,planner,player,{==},inside,unique)

def Transition.from_payout(frame: Pay.Payout.Frame) -> TC.TickCooldown.Frame:
  match frame:
    case Pay.Payout.Frame{pid,cid,pos,hp,dead,respawn,attack,spin,style,name}: TC.TickCooldown.Frame{pid,cid,attack,spin}

law Transition.payout_of:
  for +player: P.Players.State
  {Transition.from_payout(Pay.Payout.frame(player)) == TC.TickCooldown.frame(player) : TC.TickCooldown.Frame}

def Transition.payout_of(player):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match vitals:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}:
          match meta:
            case P.Players.Meta{score,kills,found,name}: {==}

law Transition.observed:
  for +player: P.Players.State
  for -players: List<&2,P.Players.State>
  for +member: Actor.Actor.Member<player,players>
  Tracked.Tracked.Observed<TC.TickCooldown.frame(player),players>

def Transition.observed(player,players,member):
  match member:
    case Actor.Actor.Member{after,inside,same}: Tracked.Tracked.Observed{after,inside,(%Transition.payout_of(after) : {_ == TC.TickCooldown.frame(player) : TC.TickCooldown.Frame}; %Transition.payout_of(player) : {Transition.from_payout(Pay.Payout.frame(after)) == _ : TC.TickCooldown.Frame}; Equal.cong(Pay.Payout.Frame,TC.TickCooldown.Frame,(frame => Transition.from_payout(frame)),Pay.Payout.frame(after),Pay.Payout.frame(player),same))}

law Transition.live_frame:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +player: P.Players.State
  for +inside: T.Targeting.In<player,S.Simulation.players(Terrain.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(Terrain.Terrain.simulation(world))>
  Tracked.Tracked.Observed<TC.TickCooldown.frame(Transition.expected(world,kind,pid,player)),S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,planner))))>

def Transition.live_frame(world,kind,pid,score,planner,player,inside,unique): Transition.observed(Transition.expected(world,kind,pid,player),S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,planner)))),Transition.live(world,kind,pid,score,planner,player,inside,unique))

law Transition.choose_pid:
  for +same: Bool
  for +kind: C.Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  {P.Players.id(Transition.choose(same,kind,phase,player)) == P.Players.id(player) : U32}

def Transition.choose_pid(same,kind,phase,player):
  match same:
    case False{}: {==}
    case True{}: Admit.Admitted.prepare_pid(kind,phase,player)

law Transition.expected_pid:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +player: P.Players.State
  {P.Players.id(Transition.expected(world,kind,pid,player)) == P.Players.id(player) : U32}

def Transition.expected_pid(world,kind,pid,player): Transition.choose_pid(U32.is_eq(P.Players.id(player),pid),kind,S.Simulation.phase(S.Simulation.meta(Terrain.Terrain.simulation(world))),player)

# An explicit counter rule: unchanged unless this player is admitted; then only
# the requested attack counter receives its fixed delay. IDs remain paired.
def Transition.stamp(kind: C.Combat.Kind,frame: TC.TickCooldown.Frame) -> TC.TickCooldown.Frame:
  match kind:
    case C.Combat.Attack{}:
      match frame:
        case TC.TickCooldown.Frame{pid,cid,attack,spin}: TC.TickCooldown.Frame{pid,cid,4,spin}
    case C.Combat.Spin{}:
      match frame:
        case TC.TickCooldown.Frame{pid,cid,attack,spin}: TC.TickCooldown.Frame{pid,cid,attack,25}

def Transition.gate(blocked: Bool,kind: C.Combat.Kind,frame: TC.TickCooldown.Frame) -> TC.TickCooldown.Frame:
  match blocked:
    case True{}: frame
    case False{}: Transition.stamp(kind,frame)

def Transition.compute(same: Bool,blocked: Bool,kind: C.Combat.Kind,frame: TC.TickCooldown.Frame) -> TC.TickCooldown.Frame:
  match same:
    case False{}: frame
    case True{}: Transition.gate(blocked,kind,frame)

law Transition.stamp_frame:
  for +kind: C.Combat.Kind
  for +player: P.Players.State
  {TC.TickCooldown.frame(C.Combat.stamp(kind,player)) == Transition.stamp(kind,TC.TickCooldown.frame(player)) : TC.TickCooldown.Frame}

def Transition.stamp_frame(kind,player):
  match kind:
    case C.Combat.Attack{}:
      match player:
        case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
          match vitals:
            case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: {==}
    case C.Combat.Spin{}:
      match player:
        case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
          match vitals:
            case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: {==}

law Transition.gate_frame:
  for +blocked: Bool
  for +kind: C.Combat.Kind
  for +player: P.Players.State
  {TC.TickCooldown.frame(C.Combat.player(C.Combat.gate(blocked,kind,player))) == Transition.gate(blocked,kind,TC.TickCooldown.frame(player)) : TC.TickCooldown.Frame}

def Transition.gate_frame(blocked,kind,player):
  match blocked:
    case True{}: {==}
    case False{}: Transition.stamp_frame(kind,player)

law Transition.choose_frame:
  for +same: Bool
  for +kind: C.Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  {TC.TickCooldown.frame(Transition.choose(same,kind,phase,player)) == Transition.compute(same,C.Combat.blocked(kind,phase,player),kind,TC.TickCooldown.frame(player)) : TC.TickCooldown.Frame}

def Transition.choose_frame(same,kind,phase,player):
  match same:
    case False{}: {==}
    case True{}: Transition.gate_frame(C.Combat.blocked(kind,phase,player),kind,player)

def Transition.next(+world: Terrain.Terrain.World,+kind: C.Combat.Kind,+pid: U32,+player: P.Players.State) -> TC.TickCooldown.Frame: Transition.compute(U32.is_eq(P.Players.id(player),pid),C.Combat.blocked(kind,S.Simulation.phase(S.Simulation.meta(Terrain.Terrain.simulation(world))),player),kind,TC.TickCooldown.frame(player))

law Transition.formula:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +player: P.Players.State
  {TC.TickCooldown.frame(Transition.expected(world,kind,pid,player)) == Transition.next(world,kind,pid,player) : TC.TickCooldown.Frame}

def Transition.formula(world,kind,pid,player): Transition.choose_frame(U32.is_eq(P.Players.id(player),pid),kind,S.Simulation.phase(S.Simulation.meta(Terrain.Terrain.simulation(world))),player)

law Transition.live_computed:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +player: P.Players.State
  for +inside: T.Targeting.In<player,S.Simulation.players(Terrain.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(Terrain.Terrain.simulation(world))>
  Tracked.Tracked.Observed<Transition.next(world,kind,pid,player),S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,planner))))>

def Transition.live_computed(world,kind,pid,score,planner,player,inside,unique):
  %Transition.formula(world,kind,pid,player) : Tracked.Tracked.Observed<_,S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,planner))))>
  Transition.live_frame(world,kind,pid,score,planner,player,inside,unique)
