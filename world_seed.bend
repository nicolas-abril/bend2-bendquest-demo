# Stored seed preservation by complete gameplay operations.
import Base
import ./restart_metadata.bend as Meta
import ./admission.bend as J
import ./references.bend as Ref
import ./locomotion.bend as Walk
import ./planning.bend as Plan
import ./ai_refs.bend as AI
import ./worldstate.bend as W
import ./simulation.bend as S
import ./channel_restart.bend as CR
import ./battle.bend as B
import ./combat.bend as Combat
import ./players.bend as P
import ./monsters.bend as M
import ./roster.bend as R
import ./payouts.bend as Pay
import ./playerids.bend as Id
import ./terrain.bend as T

def WorldSeed.of(state: S.Simulation.State) -> U32: CR.ChannelRestart.seed(S.Simulation.meta(state))

law WorldSeed.end_meta:
  for +ended: Bool
  for +meta: S.Simulation.Meta
  for +kind: U32
  {CR.ChannelRestart.seed(B.Battle.end_meta(ended,meta,kind)) == CR.ChannelRestart.seed(meta) : U32}

def WorldSeed.end_meta(ended,meta,kind):
  match ended:
    case False{}:
      match meta:
        case S.Simulation.Meta{phase,world,seed,tick,started,now,sigils,fame,next_player,next_monster}: {==}
    case True{}:
      match meta:
        case S.Simulation.Meta{phase,world,seed,tick,started,now,sigils,fame,next_player,next_monster}: {==}

law WorldSeed.reward_meta:
  for +meta: S.Simulation.Meta
  for +kind: U32
  {CR.ChannelRestart.seed(B.Battle.reward_meta(meta,kind)) == CR.ChannelRestart.seed(meta) : U32}

def WorldSeed.reward_meta(meta,kind): WorldSeed.end_meta(U32.is_eq(kind,9),meta,kind)

law WorldSeed.paid:
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +monsters: List<&2,M.Monsters.State>
  for +kill: R.Roster.Kill
  for +paid: Maybe<&2,Pay.Payout.Kill>
  {WorldSeed.of(B.Battle.state(B.Battle.paid(meta,players,monsters,kill,paid))) == CR.ChannelRestart.seed(meta) : U32}

def WorldSeed.paid(meta,players,monsters,kill,paid):
  match paid:
    case None{}: {==}
    case Some{award}: WorldSeed.reward_meta(meta,B.Battle.kind(kill))

law WorldSeed.finish_reward:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +kill: R.Roster.Kill
  for +paid: Pay.Payout.Result
  {WorldSeed.of(B.Battle.state(B.Battle.finish_reward(meta,monsters,kill,paid))) == CR.ChannelRestart.seed(meta) : U32}

def WorldSeed.finish_reward(meta,monsters,kill,paid):
  match paid:
    case Pay.Payout.Result{players,award}: WorldSeed.paid(meta,players,monsters,kill,award)

law WorldSeed.reward:
  for +state: S.Simulation.State
  for +pid: U32
  for +kill: R.Roster.Kill
  for +plan: Pay.Payout.Plan
  for +score: U32
  {WorldSeed.of(B.Battle.state(B.Battle.reward(state,pid,kill,plan,score))) == WorldSeed.of(state) : U32}

def WorldSeed.reward(state,pid,kill,plan,score):
  match state:
    case S.Simulation.State{meta,players,monsters}: WorldSeed.finish_reward(meta,monsters,kill,Pay.Payout.run(players,pid,B.Battle.bind_kind(plan,B.Battle.kind(kill)),score))

law WorldSeed.after:
  for +kill: Maybe<&2,R.Roster.Kill>
  for +state: S.Simulation.State
  for +pid: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  {WorldSeed.of(B.Battle.state(B.Battle.after(kill,state,pid,plan,score))) == WorldSeed.of(state) : U32}

def WorldSeed.after(kill,state,pid,plan,score):
  match kill:
    case None{}: {==}
    case Some{info}: WorldSeed.reward(state,pid,info,plan,score)

law WorldSeed.finish_hit:
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +hit: R.Roster.Strike
  for +pid: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  {WorldSeed.of(B.Battle.state(B.Battle.finish_hit(meta,players,hit,pid,plan,score))) == CR.ChannelRestart.seed(meta) : U32}

def WorldSeed.finish_hit(meta,players,hit,pid,plan,score):
  match hit:
    case R.Roster.Strike{monsters,kill,dealt}: WorldSeed.after(kill,S.Simulation.State{meta,players,monsters},pid,plan,score)

law WorldSeed.strike:
  for +input: B.Battle.Input
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  {WorldSeed.of(B.Battle.state(B.Battle.strike(input,state,pid,score))) == WorldSeed.of(state) : U32}

def WorldSeed.strike(input,state,pid,score):
  match input:
    case B.Battle.Input{mid,damage,plan}:
      match state:
        case S.Simulation.State{meta,players,monsters}: WorldSeed.finish_hit(meta,players,R.Roster.strike(monsters,mid,damage),pid,plan,score)

law WorldSeed.run:
  for +inputs: List<&2,B.Battle.Input>
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  {WorldSeed.of(B.Battle.state(B.Battle.run(inputs,state,pid,score))) == WorldSeed.of(state) : U32}

def WorldSeed.run(inputs,state,pid,score):
  match inputs:
    case Nil{}: {==}
    case Con{head,rest}: Equal.trans(U32,WorldSeed.of(B.Battle.state(B.Battle.run(rest,B.Battle.state(B.Battle.strike(head,state,pid,score)),pid,score))),WorldSeed.of(B.Battle.state(B.Battle.strike(head,state,pid,score))),WorldSeed.of(state),WorldSeed.run(rest,B.Battle.state(B.Battle.strike(head,state,pid,score)),pid,score),WorldSeed.strike(head,state,pid,score))

law WorldSeed.execute:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +admitted: Combat.Combat.Result
  for +inputs: List<&2,B.Battle.Input>
  for +pid: U32
  for +score: U32
  {WorldSeed.of(B.Battle.state(B.Battle.execute(meta,monsters,admitted,inputs,pid,score))) == CR.ChannelRestart.seed(meta) : U32}

def WorldSeed.execute(meta,monsters,admitted,inputs,pid,score):
  match admitted:
    case Combat.Combat.Result{players,attacker}:
      match attacker:
        case None{}: {==}
        case Some{actor}: WorldSeed.run(inputs,S.Simulation.State{meta,players,monsters},pid,score)

law WorldSeed.command:
  for +kind: Combat.Combat.Kind
  for +state: S.Simulation.State
  for +inputs: List<&2,B.Battle.Input>
  for +pid: U32
  for +score: U32
  {WorldSeed.of(B.Battle.state(B.Battle.command(kind,state,inputs,pid,score))) == WorldSeed.of(state) : U32}

def WorldSeed.command(kind,state,inputs,pid,score):
  match state:
    case S.Simulation.State{meta,players,monsters}: WorldSeed.execute(meta,monsters,Combat.Combat.run(players,pid,kind,S.Simulation.phase(meta)),inputs,pid,score)

law WorldSeed.advance:
  for +meta: S.Simulation.Meta
  {CR.ChannelRestart.seed(S.Simulation.advance(meta)) == CR.ChannelRestart.seed(meta) : U32}

def WorldSeed.advance(meta):
  match meta:
    case S.Simulation.Meta{phase,world,seed,tick,started,now,sigils,fame,next_player,next_monster}: {==}

law WorldSeed.begin_meta:
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  {S.Simulation.prepared_meta(Walk.Locomotion.begin(state,maps,rules)) == S.Simulation.meta(state) : S.Simulation.Meta}

def WorldSeed.begin_meta(state,maps,rules): S.Simulation.begin_gate_meta(U32.is_eq(S.Simulation.phase(S.Simulation.meta(state)),1),state,Walk.Locomotion.tick_plans(U32.is_eq(S.Simulation.phase(S.Simulation.meta(state)),1),S.Simulation.players(state),maps),rules)

law WorldSeed.finish:
  for +prepared: S.Simulation.Prepared
  for +actions: Walk.Locomotion.Actions
  for +rules: S.Simulation.Rules
  {WorldSeed.of(S.Simulation.state(Walk.Locomotion.finish(prepared,actions,rules))) == CR.ChannelRestart.seed(S.Simulation.prepared_meta(prepared)) : U32}

def WorldSeed.finish(prepared,actions,rules):
  match actions:
    case Walk.Locomotion.Actions{p0,p1,p2,p3}:
      %Equal.sym(S.Simulation.Meta,S.Simulation.meta(S.Simulation.state(S.Simulation.finish(prepared,p0,p1,p2,p3,rules))),S.Simulation.advance(S.Simulation.prepared_meta(prepared)),S.Simulation.finish_meta(prepared,p0,p1,p2,p3,rules)) : {CR.ChannelRestart.seed(_) == CR.ChannelRestart.seed(S.Simulation.prepared_meta(prepared)) : U32}
      WorldSeed.advance(S.Simulation.prepared_meta(prepared))

law WorldSeed.planning_finish:
  for +prepared: S.Simulation.Prepared
  for +maps: T.Terrain.Maps
  for +c0: List<&2,Plan.Planning.Context>
  for +c1: List<&2,Plan.Planning.Context>
  for +c2: List<&2,Plan.Planning.Context>
  for +c3: List<&2,Plan.Planning.Context>
  for +rules: S.Simulation.Rules
  {WorldSeed.of(S.Simulation.state(Plan.Planning.finish(prepared,maps,c0,c1,c2,c3,rules))) == CR.ChannelRestart.seed(S.Simulation.prepared_meta(prepared)) : U32}

def WorldSeed.planning_finish(prepared,maps,c0,c1,c2,c3,rules):
  +actions = Plan.Planning.actions(S.Simulation.prepared_monsters(prepared),c0,c1,c2,c3,maps,S.Simulation.clock(S.Simulation.prepared_meta(prepared)))
  %Equal.sym(S.Simulation.Result,Plan.Planning.finish(prepared,maps,c0,c1,c2,c3,rules),Walk.Locomotion.finish(prepared,actions,rules),Plan.Planning.finish_refines(prepared,maps,c0,c1,c2,c3,rules)) : {WorldSeed.of(S.Simulation.state(_)) == CR.ChannelRestart.seed(S.Simulation.prepared_meta(prepared)) : U32}
  WorldSeed.finish(prepared,actions,rules)

law WorldSeed.planning_tick:
  for +state: S.Simulation.State
  for +input: Plan.Planning.Input
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  {WorldSeed.of(S.Simulation.state(Plan.Planning.tick(state,input,maps,rules))) == WorldSeed.of(state) : U32}

def WorldSeed.planning_tick(state,input,maps,rules):
  match input:
    case Plan.Planning.Input{c0,c1,c2,c3}:
      %WorldSeed.begin_meta(state,maps,rules) : {WorldSeed.of(S.Simulation.state(Plan.Planning.finish(Walk.Locomotion.begin(state,maps,rules),maps,c0,c1,c2,c3,rules))) == CR.ChannelRestart.seed(_) : U32}
      WorldSeed.planning_finish(Walk.Locomotion.begin(state,maps,rules),maps,c0,c1,c2,c3,rules)

law WorldSeed.tick:
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +d0: List<&2,U32>
  for +d1: List<&2,U32>
  for +d2: List<&2,U32>
  for +d3: List<&2,U32>
  for +rules: S.Simulation.Rules
  {WorldSeed.of(S.Simulation.state(AI.AIRefs.tick(state,maps,d0,d1,d2,d3,rules))) == WorldSeed.of(state) : U32}

def WorldSeed.tick(state,maps,d0,d1,d2,d3,rules):
  +input = W.WorldState.input(Walk.Locomotion.begin(state,maps,rules),d0,d1,d2,d3)
  %Equal.sym(S.Simulation.Result,AI.AIRefs.tick(state,maps,d0,d1,d2,d3,rules),Plan.Planning.tick(state,input,maps,rules),W.WorldState.tick_refines(state,maps,d0,d1,d2,d3,rules)) : {WorldSeed.of(S.Simulation.state(_)) == WorldSeed.of(state) : U32}
  WorldSeed.planning_tick(state,input,maps,rules)

law WorldSeed.run_tick:
  for +damages: AI.AIRefs.Damages
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  {WorldSeed.of(AI.AIRefs.run_tick(damages,state,maps,rules)) == WorldSeed.of(state) : U32}

def WorldSeed.run_tick(damages,state,maps,rules):
  match damages:
    case AI.AIRefs.Damages{d0,d1,d2,d3}: WorldSeed.tick(state,maps,d0,d1,d2,d3,rules)

law WorldSeed.admission:
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  {WorldSeed.of(J.Admission.state(J.Admission.add(state,cid,style,name))) == WorldSeed.of(state) : U32}

def WorldSeed.admission(state,cid,style,name):
  +meta = S.Simulation.meta(J.Admission.state(J.Admission.add(state,cid,style,name)))
  %Meta.RestartMetadata.frame_seed(meta) : {_ == WorldSeed.of(state) : U32}
  %Meta.RestartMetadata.frame_seed(S.Simulation.meta(state)) : {CR.ChannelRestart.seed(Meta.RestartMetadata.frame(meta)) == _ : U32}
  %Meta.RestartMetadata.add(state,cid,style,name) : {CR.ChannelRestart.seed(Meta.RestartMetadata.frame(meta)) == CR.ChannelRestart.seed(_) : U32}
  {==}

law WorldSeed.remove:
  for +state: S.Simulation.State
  for +pid: U32
  {WorldSeed.of(Ref.References.remove_state(state,pid)) == WorldSeed.of(state) : U32}

def WorldSeed.remove(state,pid): Equal.cong(S.Simulation.Meta,U32,(meta => CR.ChannelRestart.seed(meta)),S.Simulation.meta(Ref.References.remove_state(state,pid)),S.Simulation.meta(state),Ref.References.remove_meta(state,pid))

law WorldSeed.change:
  for +command: Id.PlayerIds.Change
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  {WorldSeed.of(Id.PlayerIds.run_change(command,state,maps)) == WorldSeed.of(state) : U32}

def WorldSeed.change(command,state,maps):
  match command:
    case Id.PlayerIds.Create{cid,style,name}: WorldSeed.admission(state,cid,style,name)
    case Id.PlayerIds.Remove{target}: WorldSeed.remove(state,target)
    case Id.PlayerIds.Tick{input,rules}: WorldSeed.planning_tick(state,input,maps,rules)
    case Id.PlayerIds.Inventory{target,op,near_shop,amount}:
      match state:
        case S.Simulation.State{meta,players,monsters}: {==}
    case Id.PlayerIds.Interact{target,input}:
      match state:
        case S.Simulation.State{meta,players,monsters}: {==}
    case Id.PlayerIds.Fight{kind,inputs,pid,score}: WorldSeed.command(kind,state,inputs,pid,score)

