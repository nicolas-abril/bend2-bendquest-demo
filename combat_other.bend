# An arbitrary completed combat command preserves the other-kind cooldown.
import Base
import ./combat.bend as C
import ./players.bend as P
import ./targeting.bend as T
import ./player_membership.bend as PM
import ./bindings.bend as Bind
import ./combat_actor.bend as Actor
import ./payouts.bend as Pay
import ./vitals.bend as V
import ./live_combat.bend as L
import ./battle.bend as B
import ./simulation.bend as S
import ./terrain.bend as Terrain
import ./combat_repeat.bend as Repeat
import ./combat_rejected.bend as R
import ./admission.bend as J

# kind always denotes the intervening command; the protected kind is other(kind).
type Other.Frame is Data:
  Other.Frame{pid: U32,cid: U32,cooldown: U32}

def Other.from_combat(frame: C.Combat.Frame,cooldown: U32) -> Other.Frame:
  match frame:
    case C.Combat.Frame{pid,cid,hero,pos,hp,xp,dead,respawn,style,quest,meta}: Other.Frame{pid,cid,cooldown}

def Other.frame(+kind: C.Combat.Kind,+player: P.Players.State) -> Other.Frame:
  Other.from_combat(C.Combat.frame(player),C.Combat.cooldown(C.Combat.other(kind),P.Players.vitals(player)))

law Other.prepare:
  for +kind: C.Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  {Other.frame(kind,C.Combat.player(C.Combat.prepare(kind,phase,player))) == Other.frame(kind,player) : Other.Frame}

def Other.prepare(kind,phase,player):
  %C.Combat.prepare_other(kind,phase,player) : {Other.frame(kind,C.Combat.player(C.Combat.prepare(kind,phase,player))) == Other.from_combat(C.Combat.frame(player),_) : Other.Frame}
  %C.Combat.prepare_frame(kind,phase,player) : {Other.frame(kind,C.Combat.player(C.Combat.prepare(kind,phase,player))) == Other.from_combat(_,C.Combat.cooldown(C.Combat.other(kind),P.Players.vitals(C.Combat.player(C.Combat.prepare(kind,phase,player))))) : Other.Frame}
  {==}

type Other.Member<-kind: C.Combat.Kind,-before: P.Players.State,-players: List<&2,P.Players.State>> is Data:
  Other.Member{after: P.Players.State,inside: T.Targeting.In<after,players>,same: {Other.frame(kind,after) == Other.frame(kind,before) : Other.Frame}}

law Other.replace:
  for +kind: C.Combat.Kind
  for +player: P.Players.State
  for +head: P.Players.State
  for +rest: List<&2,P.Players.State>
  for +next: P.Players.State
  for +same: {Other.frame(kind,next) == Other.frame(kind,head) : Other.Frame}
  for +inside: T.Targeting.In<player,Con{head,rest}>
  Other.Member<kind,player,Con{next,rest}>

def Other.replace(kind,player,head,rest,next,same,inside):
  match inside:
    case T.Targeting.Here{tail,shape}: Other.Member{next,T.Targeting.Here{rest,{==}},Equal.trans(Other.Frame,Other.frame(kind,next),Other.frame(kind,head),Other.frame(kind,player),same,Equal.cong(P.Players.State,Other.Frame,(p => Other.frame(kind,p)),head,player,PM.PlayerMembership.cons_head(head,player,rest,tail,shape)))}
    case T.Targeting.There{before,tail,shape,later}: Other.Member{player,T.Targeting.There{next,rest,{==},(%Equal.sym(List<&2,P.Players.State>,rest,tail,PM.PlayerMembership.cons_tail(head,before,rest,tail,shape)) : T.Targeting.In<player,_>; later)},{==}}

law Other.taken:
  for +taken: P.Players.Take
  for +kind: C.Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  for +inside: T.Targeting.In<player,P.Players.restore(taken)>
  Other.Member<kind,player,C.Combat.roster(C.Combat.apply_taken(taken,kind,phase))>

def Other.taken(taken,kind,phase,player,inside):
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}: Other.Member{player,inside,{==}}
        case Some{head}:
          %Equal.sym(List<&2,P.Players.State>,C.Combat.roster(C.Combat.finish(C.Combat.prepare(kind,phase,head),others)),Con{C.Combat.player(C.Combat.prepare(kind,phase,head)),others},C.Combat.finish_roster(C.Combat.prepare(kind,phase,head),others)) : Other.Member<kind,player,_>
          Other.replace(kind,player,head,others,C.Combat.player(C.Combat.prepare(kind,phase,head)),Other.prepare(kind,phase,head),inside)

law Other.admission:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +kind: C.Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  for +inside: T.Targeting.In<player,players>
  Other.Member<kind,player,C.Combat.roster(C.Combat.run(players,target,kind,phase))>

def Other.admission(players,target,kind,phase,player,inside): Other.taken(P.Players.take(players,target),kind,phase,player,Bind.Bindings.perm_member(player,P.Players.restore(P.Players.take(players,target)),players,P.Players.take_restores(players,target),inside))

def Other.from_payout(kind: C.Combat.Kind,frame: Pay.Payout.Frame) -> Other.Frame:
  match kind:
    case C.Combat.Attack{}:
      match frame:
        case Pay.Payout.Frame{pid,cid,pos,hp,dead,respawn,attack,spin,style,name}: Other.Frame{pid,cid,spin}
    case C.Combat.Spin{}:
      match frame:
        case Pay.Payout.Frame{pid,cid,pos,hp,dead,respawn,attack,spin,style,name}: Other.Frame{pid,cid,attack}

law Other.payout_of:
  for +kind: C.Combat.Kind
  for +player: P.Players.State
  {Other.from_payout(kind,Pay.Payout.frame(player)) == Other.frame(kind,player) : Other.Frame}

def Other.payout_of(kind,player):
  match kind:
    case C.Combat.Attack{}:
      match player:
        case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
          match vitals:
            case V.Vitals.State{hp,xp,dead,respawn,attack,spin}:
              match meta:
                case P.Players.Meta{score,kills,found,name}: {==}
    case C.Combat.Spin{}:
      match player:
        case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
          match vitals:
            case V.Vitals.State{hp,xp,dead,respawn,attack,spin}:
              match meta:
                case P.Players.Meta{score,kills,found,name}: {==}

law Other.payout_same:
  for +kind: C.Combat.Kind
  for +after: P.Players.State
  for +before: P.Players.State
  for +same: {Pay.Payout.frame(after) == Pay.Payout.frame(before) : Pay.Payout.Frame}
  {Other.frame(kind,after) == Other.frame(kind,before) : Other.Frame}

def Other.payout_same(kind,after,before,same):
  %Other.payout_of(kind,after) : {_ == Other.frame(kind,before) : Other.Frame}
  %Other.payout_of(kind,before) : {Other.from_payout(kind,Pay.Payout.frame(after)) == _ : Other.Frame}
  Equal.cong(Pay.Payout.Frame,Other.Frame,(frame => Other.from_payout(kind,frame)),Pay.Payout.frame(after),Pay.Payout.frame(before),same)

law Other.rewarded:
  for +kind: C.Combat.Kind
  for +before: P.Players.State
  for +current: P.Players.State
  for -players: List<&2,P.Players.State>
  for +same: {Other.frame(kind,current) == Other.frame(kind,before) : Other.Frame}
  for +member: Actor.Actor.Member<current,players>
  Other.Member<kind,before,players>

def Other.rewarded(kind,before,current,players,same,member):
  match member:
    case Actor.Actor.Member{after,inside,frame}: Other.Member{after,inside,Equal.trans(Other.Frame,Other.frame(kind,after),Other.frame(kind,current),Other.frame(kind,before),Other.payout_same(kind,after,current,frame),same)}

law Other.battle:
  for +kind: C.Combat.Kind
  for +before: P.Players.State
  for +inputs: List<&2,B.Battle.Input>
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +member: Other.Member<kind,before,S.Simulation.players(state)>
  Other.Member<kind,before,S.Simulation.players(B.Battle.state(B.Battle.run(inputs,state,pid,score)))>

def Other.battle(kind,before,inputs,state,pid,score,member):
  match member:
    case Other.Member{current,inside,same}: Other.rewarded(kind,before,current,S.Simulation.players(B.Battle.state(B.Battle.run(inputs,state,pid,score))),same,Actor.Actor.battle_run(current,inputs,state,pid,score,Actor.Actor.Member{current,inside,{==}}))

def Other.Ready(ready: L.LiveCombat.Ready,+kind: C.Combat.Kind,+player: P.Players.State) -> Data:
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}: Other.Member<kind,player,C.Combat.roster(admitted)>

law Other.prepared:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for +player: P.Players.State
  for +inside: T.Targeting.In<player,S.Simulation.players(Terrain.Terrain.simulation(world))>
  Other.Ready(L.LiveCombat.prepare(world,kind,pid,score),kind,player)

def Other.prepared(world,kind,pid,score,player,inside):
  match world:
    case Terrain.Terrain.World{meta,players,monsters,maps}: Other.admission(players,pid,kind,S.Simulation.phase(meta),player,inside)

law Other.finished:
  for +ready: L.LiveCombat.Ready
  for +kind: C.Combat.Kind
  for +player: P.Players.State
  for +plan: L.LiveCombat.Plan
  for +member: Other.Ready(ready,kind,player)
  Other.Member<kind,player,S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.finish(ready,plan))))>

def Other.finished(ready,kind,player,plan,member):
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}: member
            case Some{attacker}:
              match plan:
                case L.LiveCombat.Plan{inputs,visual}:
                  %Equal.sym(S.Simulation.State,Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.pack(B.Battle.run(inputs,S.Simulation.State{meta,players,monsters},pid,score),maps,visual))),B.Battle.state(B.Battle.run(inputs,S.Simulation.State{meta,players,monsters},pid,score)),L.LiveCombat.pack_simulation(B.Battle.run(inputs,S.Simulation.State{meta,players,monsters},pid,score),maps,visual)) : Other.Member<kind,player,S.Simulation.players(_)>
                  Other.battle(kind,player,inputs,S.Simulation.State{meta,players,monsters},pid,score,member)

# Any acting PID, any actual affine planner, either admission branch.
law Other.live:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +player: P.Players.State
  for +inside: T.Targeting.In<player,S.Simulation.players(Terrain.Terrain.simulation(world))>
  Other.Member<kind,player,S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,planner))))>

def Other.live(world,kind,pid,score,planner,player,inside):
  +ready = L.LiveCombat.prepare(world,kind,pid,score)
  Other.finished(ready,kind,player,planner(ready),Other.prepared(world,kind,pid,score,player,inside))

def Other.pid(frame: Other.Frame) -> U32:
  match frame:
    case Other.Frame{pid,cid,cooldown}: pid

def Other.cooldown(frame: Other.Frame) -> U32:
  match frame:
    case Other.Frame{pid,cid,cooldown}: cooldown

law Other.pid_of:
  for +kind: C.Combat.Kind
  for +player: P.Players.State
  {Other.pid(Other.frame(kind,player)) == P.Players.id(player) : U32}

def Other.pid_of(kind,player):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match vitals:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: {==}

law Other.cooldown_of:
  for +kind: C.Combat.Kind
  for +player: P.Players.State
  {Other.cooldown(Other.frame(kind,player)) == C.Combat.cooldown(C.Combat.other(kind),P.Players.vitals(player)) : U32}

def Other.cooldown_of(kind,player):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match vitals:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: {==}

law Other.member_held:
  for +kind: C.Combat.Kind
  for +pid: U32
  for +before: P.Players.State
  for -players: List<&2,P.Players.State>
  for +member: Other.Member<kind,before,players>
  for +same: {P.Players.id(before) == pid : U32}
  for +locked: Repeat.Repeat.Locked(C.Combat.other(kind),before)
  Repeat.Repeat.Held<C.Combat.other(kind),pid,players>

def Other.member_held(kind,pid,before,players,member,same,locked):
  match member:
    case Other.Member{after,inside,equal}:
      +pid_same = Equal.trans(U32,P.Players.id(after),P.Players.id(before),pid,(%Other.pid_of(kind,after) : {_ == P.Players.id(before) : U32}; %Other.pid_of(kind,before) : {Other.pid(Other.frame(kind,after)) == _ : U32}; Equal.cong(Other.Frame,U32,(frame => Other.pid(frame)),Other.frame(kind,after),Other.frame(kind,before),equal)),same)
      +cooldown_same = {(%Other.cooldown_of(kind,after) : {_ == C.Combat.cooldown(C.Combat.other(kind),P.Players.vitals(before)) : U32}; %Other.cooldown_of(kind,before) : {Other.cooldown(Other.frame(kind,after)) == _ : U32}; Equal.cong(Other.Frame,U32,(frame => Other.cooldown(frame)),Other.frame(kind,after),Other.frame(kind,before),equal)) : {C.Combat.cooldown(C.Combat.other(kind),P.Players.vitals(after)) == C.Combat.cooldown(C.Combat.other(kind),P.Players.vitals(before)) : U32}}
      Repeat.Repeat.Held{after,inside,pid_same,Equal.trans(U32,C.Combat.cooldown(C.Combat.other(kind),P.Players.vitals(after)),C.Combat.cooldown(C.Combat.other(kind),P.Players.vitals(before)),C.Combat.delay(C.Combat.other(kind)),cooldown_same,locked)}

law Other.live_held:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +tracked: U32
  for +held: Repeat.Repeat.Held<C.Combat.other(kind),tracked,S.Simulation.players(Terrain.Terrain.simulation(world))>
  Repeat.Repeat.Held<C.Combat.other(kind),tracked,S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,planner))))>

def Other.live_held(world,kind,pid,score,planner,tracked,held):
  match held:
    case Repeat.Repeat.Held{player,inside,same,locked}: Other.member_held(kind,tracked,player,S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,planner)))),Other.live(world,kind,pid,score,planner,player,inside),same,locked)

law Other.retry:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for first: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +tracked: U32
  for +retry_score: U32
  for retry: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +held: Repeat.Repeat.Held<C.Combat.other(kind),tracked,S.Simulation.players(Terrain.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(Terrain.Terrain.simulation(world))>
  R.Rejected.Inert<L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,first)),L.LiveCombat.run(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,first)),C.Combat.other(kind),tracked,retry_score,retry)>

def Other.retry(world,kind,pid,score,first,tracked,retry_score,retry,held,unique):
  +plan = first(L.LiveCombat.prepare(world,kind,pid,score))
  +after = L.LiveCombat.world(L.LiveCombat.at(world,kind,pid,score,plan))
  %Equal.sym(L.LiveCombat.Result,L.LiveCombat.run(after,C.Combat.other(kind),tracked,retry_score,retry),Repeat.Repeat.quiet(after,tracked),Repeat.Repeat.live_run_rejected(after,C.Combat.other(kind),tracked,retry_score,retry,Other.live_held(world,kind,pid,score,(unused => plan),tracked,held),Repeat.Repeat.at_unique(world,kind,pid,score,plan,unique))) : R.Rejected.Inert<after,_>
  R.Rejected.quiet_inert(after,tracked)
