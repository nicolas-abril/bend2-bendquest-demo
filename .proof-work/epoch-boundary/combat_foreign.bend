# Commands from a distinct PID preserve the tracked player's payout frame.
import Base
import ./combat.bend as C
import ./players.bend as P
import ./targeting.bend as T
import ./player_membership.bend as PM
import ./bindings.bend as Bind
import ./combat_actor.bend as Actor
import ./live_combat.bend as L
import ./battle.bend as B
import ./simulation.bend as S
import ./terrain.bend as Terrain
import ./combat_repeat.bend as Repeat
import ./combat_rejected.bend as R
import ./admission.bend as J

law Foreign.replace:
  for +player: P.Players.State
  for +head: P.Players.State
  for +rest: List<&2,P.Players.State>
  for +next: P.Players.State
  for +target: U32
  for +selected: {P.Players.id(head) == target : U32}
  for +different: {U32.is_eq(P.Players.id(player),target) == False{} : Bool}
  for +inside: T.Targeting.In<player,Con{head,rest}>
  T.Targeting.In<player,Con{next,rest}>

def Foreign.replace(player,head,rest,next,target,selected,different,inside):
  match inside:
    case T.Targeting.Here{tail,shape}: Empty.absurd(T.Targeting.In<player,Con{next,rest}>,PM.PlayerMembership.eq_ne(P.Players.id(player),target,Equal.trans(U32,P.Players.id(player),P.Players.id(head),target,Equal.cong(P.Players.State,U32,(p => P.Players.id(p)),player,head,Equal.sym(P.Players.State,head,player,PM.PlayerMembership.cons_head(head,player,rest,tail,shape))),selected),different))
    case T.Targeting.There{before,tail,shape,later}: T.Targeting.There{next,rest,{==},(%Equal.sym(List<&2,P.Players.State>,rest,tail,PM.PlayerMembership.cons_tail(head,before,rest,tail,shape)) : T.Targeting.In<player,_>; later)}

law Foreign.taken:
  for +taken: P.Players.Take
  for +target: U32
  for +kind: C.Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  for +selected: P.Players.FoundID(P.Players.found(taken),target)
  for +different: {U32.is_eq(P.Players.id(player),target) == False{} : Bool}
  for +inside: T.Targeting.In<player,P.Players.restore(taken)>
  T.Targeting.In<player,C.Combat.roster(C.Combat.apply_taken(taken,kind,phase))>

def Foreign.taken(taken,target,kind,phase,player,selected,different,inside):
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}: inside
        case Some{head}:
          %Equal.sym(List<&2,P.Players.State>,C.Combat.roster(C.Combat.finish(C.Combat.prepare(kind,phase,head),others)),Con{C.Combat.player(C.Combat.prepare(kind,phase,head)),others},C.Combat.finish_roster(C.Combat.prepare(kind,phase,head),others)) : T.Targeting.In<player,_>
          Foreign.replace(player,head,others,C.Combat.player(C.Combat.prepare(kind,phase,head)),target,selected,different,inside)

law Foreign.admission:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +kind: C.Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  for +different: {U32.is_eq(P.Players.id(player),target) == False{} : Bool}
  for +inside: T.Targeting.In<player,players>
  T.Targeting.In<player,C.Combat.roster(C.Combat.run(players,target,kind,phase))>

def Foreign.admission(players,target,kind,phase,player,different,inside): Foreign.taken(P.Players.take(players,target),target,kind,phase,player,P.Players.take_id(players,target),different,Bind.Bindings.perm_member(player,P.Players.restore(P.Players.take(players,target)),players,P.Players.take_restores(players,target),inside))

def Foreign.Ready(ready: L.LiveCombat.Ready,+player: P.Players.State) -> Data:
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}: Actor.Actor.Member<player,C.Combat.roster(admitted)>

law Foreign.prepared:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for +player: P.Players.State
  for +different: {U32.is_eq(P.Players.id(player),pid) == False{} : Bool}
  for +inside: T.Targeting.In<player,S.Simulation.players(Terrain.Terrain.simulation(world))>
  Foreign.Ready(L.LiveCombat.prepare(world,kind,pid,score),player)

def Foreign.prepared(world,kind,pid,score,player,different,inside):
  match world:
    case Terrain.Terrain.World{meta,players,monsters,maps}: Actor.Actor.Member{player,Foreign.admission(players,pid,kind,S.Simulation.phase(meta),player,different,inside),{==}}

law Foreign.finished:
  for +ready: L.LiveCombat.Ready
  for +player: P.Players.State
  for +plan: L.LiveCombat.Plan
  for +member: Foreign.Ready(ready,player)
  Actor.Actor.Member<player,S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.finish(ready,plan))))>

def Foreign.finished(ready,player,plan,member):
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}: member
            case Some{attacker}:
              match plan:
                case L.LiveCombat.Plan{inputs,visual}:
                  %Equal.sym(S.Simulation.State,Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.pack(B.Battle.run(inputs,S.Simulation.State{meta,players,monsters},pid,score),maps,visual))),B.Battle.state(B.Battle.run(inputs,S.Simulation.State{meta,players,monsters},pid,score)),L.LiveCombat.pack_simulation(B.Battle.run(inputs,S.Simulation.State{meta,players,monsters},pid,score),maps,visual)) : Actor.Actor.Member<player,S.Simulation.players(_)>
                  Actor.Actor.battle_run(player,inputs,S.Simulation.State{meta,players,monsters},pid,score,member)

law Foreign.live:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +player: P.Players.State
  for +different: {U32.is_eq(P.Players.id(player),pid) == False{} : Bool}
  for +inside: T.Targeting.In<player,S.Simulation.players(Terrain.Terrain.simulation(world))>
  Actor.Actor.Member<player,S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,planner))))>

def Foreign.live(world,kind,pid,score,planner,player,different,inside):
  +ready = L.LiveCombat.prepare(world,kind,pid,score)
  Foreign.finished(ready,player,planner(ready),Foreign.prepared(world,kind,pid,score,player,different,inside))

law Foreign.member_held:
  for +kind: C.Combat.Kind
  for +pid: U32
  for +before: P.Players.State
  for -players: List<&2,P.Players.State>
  for +member: Actor.Actor.Member<before,players>
  for +same: {P.Players.id(before) == pid : U32}
  for +locked: Repeat.Repeat.Locked(kind,before)
  Repeat.Repeat.Held<kind,pid,players>

def Foreign.member_held(kind,pid,before,players,member,same,locked):
  match member:
    case Actor.Actor.Member{after,inside,equal}: Repeat.Repeat.Held{after,inside,Equal.trans(U32,P.Players.id(after),P.Players.id(before),pid,Actor.Actor.same_pid(after,before,equal),same),Repeat.Repeat.frame_locked(kind,before,after,equal,locked)}

# The protected kind and intervening kind are independent; both counters persist.
law Foreign.live_held:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +protected: C.Combat.Kind
  for +tracked: U32
  for +different: {U32.is_eq(tracked,pid) == False{} : Bool}
  for +held: Repeat.Repeat.Held<protected,tracked,S.Simulation.players(Terrain.Terrain.simulation(world))>
  Repeat.Repeat.Held<protected,tracked,S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,planner))))>

def Foreign.live_held(world,kind,pid,score,planner,protected,tracked,different,held):
  match held:
    case Repeat.Repeat.Held{player,inside,same,locked}: Foreign.member_held(protected,tracked,player,S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,planner)))),Foreign.live(world,kind,pid,score,planner,player,(%Equal.sym(U32,P.Players.id(player),tracked,same) : {U32.is_eq(_,pid) == False{} : Bool}; different),inside),same,locked)

law Foreign.retry:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for first: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +protected: C.Combat.Kind
  for +tracked: U32
  for +retry_score: U32
  for retry: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +different: {U32.is_eq(tracked,pid) == False{} : Bool}
  for +held: Repeat.Repeat.Held<protected,tracked,S.Simulation.players(Terrain.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(Terrain.Terrain.simulation(world))>
  R.Rejected.Inert<L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,first)),L.LiveCombat.run(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,first)),protected,tracked,retry_score,retry)>

def Foreign.retry(world,kind,pid,score,first,protected,tracked,retry_score,retry,different,held,unique):
  +plan = first(L.LiveCombat.prepare(world,kind,pid,score))
  +after = L.LiveCombat.world(L.LiveCombat.at(world,kind,pid,score,plan))
  %Equal.sym(L.LiveCombat.Result,L.LiveCombat.run(after,protected,tracked,retry_score,retry),Repeat.Repeat.quiet(after,tracked),Repeat.Repeat.live_run_rejected(after,protected,tracked,retry_score,retry,Foreign.live_held(world,kind,pid,score,(unused => plan),protected,tracked,different,held),Repeat.Repeat.at_unique(world,kind,pid,score,plan,unique))) : R.Rejected.Inert<after,_>
  R.Rejected.quiet_inert(after,tracked)
