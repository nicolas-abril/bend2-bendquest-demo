# Actual combat admission returns a roster member with the requested PID.
import Base
import ./target_plans.bend as TP
import ./spin_plans.bend as Spin
import ./combat_frame.bend as CF
import ./combat_targets.bend as Targets
import ./identity.bend as I
import ./combat.bend as C
import ./players.bend as P
import ./vitals.bend as V
import ./combat_actor.bend as A
import ./targeting.bend as T
import ./simulation.bend as S
import ./terrain.bend as Terrain
import ./live_combat.bend as L
import ./battle.bend as B
import ./monsters.bend as M
import ./roster.bend as R

law Admitted.stamp_pid:
  for +kind: C.Combat.Kind
  for +player: P.Players.State
  {P.Players.id(C.Combat.stamp(kind,player)) == P.Players.id(player) : U32}

def Admitted.stamp_pid(kind,player):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}: {==}

law Admitted.gate_pid:
  for +blocked: Bool
  for +kind: C.Combat.Kind
  for +player: P.Players.State
  {P.Players.id(C.Combat.player(C.Combat.gate(blocked,kind,player))) == P.Players.id(player) : U32}

def Admitted.gate_pid(blocked,kind,player):
  match blocked:
    case True{}: {==}
    case False{}: Admitted.stamp_pid(kind,player)

law Admitted.prepare_pid:
  for +kind: C.Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  {P.Players.id(C.Combat.player(C.Combat.prepare(kind,phase,player))) == P.Players.id(player) : U32}

def Admitted.prepare_pid(kind,phase,player): Admitted.gate_pid(C.Combat.blocked(kind,phase,player),kind,player)

# In the Some case both claims concern the exact returned actor, not an
# arbitrary same-ID record. No assumed uniqueness or world validity is needed.
def Admitted.Actor(found: Maybe<&2,P.Players.State>,+players: List<&2,P.Players.State>,+pid: U32) -> Data:
  match found:
    case None{}: Unit
    case Some{player}: Sigma<&2,&2,T.Targeting.In<player,players>,(inside => {P.Players.id(player) == pid : U32})>

def Admitted.OK(result: C.Combat.Result,+pid: U32) -> Data:
  match result:
    case C.Combat.Result{players,actor}: Admitted.Actor(actor,players,pid)

law Admitted.actor:
  for +accepted: Bool
  for +player: P.Players.State
  for +others: List<&2,P.Players.State>
  for +pid: U32
  for +same: {P.Players.id(player) == pid : U32}
  Admitted.Actor(C.Combat.actor(accepted,player),Con{player,others},pid)

def Admitted.actor(accepted,player,others,pid,same):
  match accepted:
    case False{}: Unit{}
    case True{}: Tuple{T.Targeting.Here{others,{==}},same}

law Admitted.finish:
  for +step: C.Combat.Step
  for +others: List<&2,P.Players.State>
  for +pid: U32
  for +same: {P.Players.id(C.Combat.player(step)) == pid : U32}
  Admitted.OK(C.Combat.finish(step,others),pid)

def Admitted.finish(step,others,pid,same):
  match step:
    case C.Combat.Step{player,accepted}: Admitted.actor(accepted,player,others,pid,same)

law Admitted.apply_taken:
  for +taken: P.Players.Take
  for +kind: C.Combat.Kind
  for +phase: U32
  for +pid: U32
  for +same: P.Players.FoundID(P.Players.found(taken),pid)
  Admitted.OK(C.Combat.apply_taken(taken,kind,phase),pid)

def Admitted.apply_taken(taken,kind,phase,pid,same):
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}: Unit{}
        case Some{player}: Admitted.finish(C.Combat.prepare(kind,phase,player),others,pid,Equal.trans(U32,P.Players.id(C.Combat.player(C.Combat.prepare(kind,phase,player))),P.Players.id(player),pid,Admitted.prepare_pid(kind,phase,player),same))

law Admitted.run:
  for +players: List<&2,P.Players.State>
  for +pid: U32
  for +kind: C.Combat.Kind
  for +phase: U32
  Admitted.OK(C.Combat.run(players,pid,kind,phase),pid)

def Admitted.run(players,pid,kind,phase): Admitted.apply_taken(P.Players.take(players,pid),kind,phase,pid,P.Players.take_id(players,pid))

def Admitted.Ready(ready: L.LiveCombat.Ready) -> Data:
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,result,pid,score}: Admitted.OK(result,pid)

law Admitted.live_prepare:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  Admitted.Ready(L.LiveCombat.prepare(world,kind,pid,score))

def Admitted.live_prepare(world,kind,pid,score):
  match world:
    case Terrain.Terrain.World{meta,players,monsters,maps}: Admitted.run(players,pid,kind,S.Simulation.phase(meta))

# Accepted actors persist in the actual final world. Rejected actions have
# no actor obligation; their exact no-effect law already lives in LiveCombat.
def Admitted.FinalActor(found: Maybe<&2,P.Players.State>,+world: Terrain.Terrain.World) -> Data:
  match found:
    case None{}: Unit
    case Some{player}: A.Actor.Member<player,S.Simulation.players(Terrain.Terrain.simulation(world))>

def Admitted.Finished(ready: L.LiveCombat.Ready,+result: L.LiveCombat.Result) -> Data:
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,actor}: Admitted.FinalActor(actor,L.LiveCombat.world(result))

law Admitted.finish_accepted:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +maps: Terrain.Terrain.Maps
  for +players: List<&2,P.Players.State>
  for +actor: P.Players.State
  for +pid: U32
  for +score: U32
  for +plan: L.LiveCombat.Plan
  for +inside: T.Targeting.In<actor,players>
  A.Actor.Member<actor,S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.finish(L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,Some{actor}},pid,score},plan))))>

def Admitted.finish_accepted(meta,monsters,maps,players,actor,pid,score,plan,inside):
  match plan:
    case L.LiveCombat.Plan{inputs,visual}:
      %Equal.sym(S.Simulation.State,Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.pack(B.Battle.run(inputs,S.Simulation.State{meta,players,monsters},pid,score),maps,visual))),B.Battle.state(B.Battle.run(inputs,S.Simulation.State{meta,players,monsters},pid,score)),L.LiveCombat.pack_simulation(B.Battle.run(inputs,S.Simulation.State{meta,players,monsters},pid,score),maps,visual)) : A.Actor.Member<actor,S.Simulation.players(_)>
      A.Actor.battle_run(actor,inputs,S.Simulation.State{meta,players,monsters},pid,score,A.Actor.Member{actor,inside,{==}})

law Admitted.live_finish:
  for +ready: L.LiveCombat.Ready
  for +plan: L.LiveCombat.Plan
  for +valid: Admitted.Ready(ready)
  Admitted.Finished(ready,L.LiveCombat.finish(ready,plan))

def Admitted.live_finish(ready,plan,valid):
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}: Unit{}
            case Some{player}:
              match valid:
                case Tuple{inside,same}: Admitted.finish_accepted(meta,monsters,maps,players,player,pid,score,plan,inside)

law Admitted.live_run:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  Admitted.Finished(L.LiveCombat.prepare(world,kind,pid,score),L.LiveCombat.run(world,kind,pid,score,planner))

def Admitted.live_run(world,kind,pid,score,planner):
  +ready = L.LiveCombat.prepare(world,kind,pid,score)
  Admitted.live_finish(ready,planner(ready),Admitted.live_prepare(world,kind,pid,score))

# The intermediate state uses the command PID, exactly as Battle.run does.
# Admission's PID equality connects this to the current-attacker theorem.
def Admitted.Sequence(inputs: List<&2,B.Battle.Input>,+state: S.Simulation.State,+actor: P.Players.State,+pid: U32,+score: U32) -> Data:
  match inputs:
    case Nil{}: Unit
    case Con{head,rest}:
      +head = head
      Sigma<&2,&2,A.Actor.Strike<actor,state,TP.TargetPlans.id(head)>,(witness => Admitted.Sequence(rest,B.Battle.state(B.Battle.strike(head,state,pid,score)),actor,pid,score))>

law Admitted.actor_sequence:
  for +inputs: List<&2,B.Battle.Input>
  for +state: S.Simulation.State
  for +actor: P.Players.State
  for +score: U32
  for +execution: A.Actor.Execution(inputs,state,actor,score)
  Admitted.Sequence(inputs,state,actor,P.Players.id(actor),score)

def Admitted.actor_sequence(inputs,state,actor,score,execution):
  match inputs:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match execution:
        case Tuple{current,later}: Tuple{current,Admitted.actor_sequence(rest,B.Battle.state(B.Battle.strike(head,state,P.Players.id(actor),score)),actor,score,later)}

law Admitted.command_sequence:
  for +inputs: List<&2,B.Battle.Input>
  for +state: S.Simulation.State
  for +actor: P.Players.State
  for +pid: U32
  for +score: U32
  for +same: {P.Players.id(actor) == pid : U32}
  for +execution: A.Actor.Execution(inputs,state,actor,score)
  Admitted.Sequence(inputs,state,actor,pid,score)

def Admitted.command_sequence(inputs,state,actor,pid,score,same,execution):
  %same : Admitted.Sequence(inputs,state,actor,_,score)
  Admitted.actor_sequence(inputs,state,actor,score,execution)

law Admitted.spin_sequence:
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +monsters: List<&2,M.Monsters.State>
  for +actor: P.Players.State
  for +pid: U32
  for +score: U32
  for build: (@+selected: List<&2,M.Monsters.State> -> Spin.SpinPlans.Powers(selected))
  for +valid: Admitted.OK(C.Combat.Result{players,Some{actor}},pid)
  for +unique: I.Identity.Monsters(monsters)
  Admitted.Sequence(L.LiveCombat.inputs(Spin.SpinPlans.run(monsters,A.Actor.point(actor),build)),S.Simulation.State{meta,players,monsters},actor,pid,score)

def Admitted.spin_sequence(meta,players,monsters,actor,pid,score,build,valid,unique):
  match valid:
    case Tuple{inside,same}:
      +selected = Targets.Targets.filter(monsters,A.Actor.point(actor))
      +powers = build(selected)
      Admitted.command_sequence(Spin.SpinPlans.inputs(selected,powers),S.Simulation.State{meta,players,monsters},actor,pid,score,same,A.Actor.inputs_execution(Spin.SpinPlans.inputs(selected,powers),S.Simulation.State{meta,players,monsters},actor,score,A.Actor.Member{actor,inside,{==}},CF.CombatFrame.inputs_execution(selected,powers,S.Simulation.State{meta,players,monsters},P.Players.id(actor),score,A.Actor.point(actor),Targets.Targets.filter_sources(monsters,A.Actor.point(actor)),unique,Targets.Targets.filter_unique(monsters,A.Actor.point(actor),unique))))
