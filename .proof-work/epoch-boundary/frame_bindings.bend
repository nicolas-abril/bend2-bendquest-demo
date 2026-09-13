# Project established command frames to connection bindings.
import Base
import ./bindings.bend as Bind
import ./connections.bend as Conn
import ./sessions.bend as Sess
import ./inventory.bend as Inv
import ./interactions.bend as Inter
import ./combat.bend as C
import ./payouts.bend as Pay
import ./players.bend as P
import ./vitals.bend as V
import ./game.bend as G
import ./battle.bend as B
import ./roster.bend as R
import ./monsters.bend as M
import ./simulation.bend as S
import ./worldstate.bend as W
import ./playerids.bend as Id
import ./landscape.bend as L
import ./creation.bend as K
import ./disconnect.bend as D
import ./terrain.bend as T
import ./population.bend as Pop

def FrameBindings.inventory_header(frame: Inv.Inventory.Frame) -> Bind.Bindings.Header:
  match frame:
    case Inv.Inventory.Frame{pid,cid,pos,xp,dead,respawn,attack,spin,style,quest,meta}:
      match meta:
        case P.Players.Meta{score,kills,found,name}: Bind.Bindings.Header{pid,cid,name}

law FrameBindings.inventory_of:
  for +player: P.Players.State
  {FrameBindings.inventory_header(Inv.Inventory.frame(player)) == Bind.Bindings.header(player) : Bind.Bindings.Header}

def FrameBindings.inventory_of(player):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match vitals:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}:
          match quest:
            case P.Players.Quest{main,cull,side0,side1,side2,claimed}:
              match meta:
                case P.Players.Meta{score,kills,found,name}: {==}

def FrameBindings.inventory_headers(frames: List<&2,Inv.Inventory.Frame>) -> List<&2,Bind.Bindings.Header>:
  match frames:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{FrameBindings.inventory_header(head),FrameBindings.inventory_headers(rest)}

law FrameBindings.inventory_projection:
  for +players: List<&2,P.Players.State>
  {FrameBindings.inventory_headers(Inv.Inventory.frames(players)) == Bind.Bindings.headers(players) : List<&2,Bind.Bindings.Header>}

def FrameBindings.inventory_projection(players):
  match players:
    case Nil{}: {==}
    case Con{head,rest}:
      %FrameBindings.inventory_of(head) : {Con{FrameBindings.inventory_header(Inv.Inventory.frame(head)),FrameBindings.inventory_headers(Inv.Inventory.frames(rest))} == Con{_,Bind.Bindings.headers(rest)} : List<&2,Bind.Bindings.Header>}
      %FrameBindings.inventory_projection(rest) : {Con{FrameBindings.inventory_header(Inv.Inventory.frame(head)),FrameBindings.inventory_headers(Inv.Inventory.frames(rest))} == Con{FrameBindings.inventory_header(Inv.Inventory.frame(head)),_} : List<&2,Bind.Bindings.Header>}
      {==}

law FrameBindings.inventory_equal:
  for +left: List<&2,P.Players.State>
  for +right: List<&2,P.Players.State>
  for +same: {Inv.Inventory.frames(left) == Inv.Inventory.frames(right) : List<&2,Inv.Inventory.Frame>}
  {Bind.Bindings.headers(left) == Bind.Bindings.headers(right) : List<&2,Bind.Bindings.Header>}

def FrameBindings.inventory_equal(left,right,same):
  %FrameBindings.inventory_projection(left) : {_ == Bind.Bindings.headers(right) : List<&2,Bind.Bindings.Header>}
  %FrameBindings.inventory_projection(right) : {FrameBindings.inventory_headers(Inv.Inventory.frames(left)) == _ : List<&2,Bind.Bindings.Header>}
  %same : {FrameBindings.inventory_headers(Inv.Inventory.frames(left)) == FrameBindings.inventory_headers(_) : List<&2,Bind.Bindings.Header>}
  {==}

law FrameBindings.inventory_conserved:
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: Inv.Inventory.Conserved<before,after>
  Bind.Bindings.Conserved<before,after>

def FrameBindings.inventory_conserved(before,after,conserved):
  match conserved:
    case Inv.Inventory.Conserved{ordered,permutation,frames}: Bind.Bindings.Conserved{ordered,permutation,FrameBindings.inventory_equal(after,ordered,frames)}

law FrameBindings.inventory_run:
  for +states: List<&2,Sess.Sessions.State>
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +op: G.Bq.HOp
  for +near_shop: Bool
  for +amount: U32
  for +valid: Conn.Connections.OK<players,states>
  Conn.Connections.OK<Inv.Inventory.roster(Inv.Inventory.run(players,target,op,near_shop,amount)),states>

def FrameBindings.inventory_run(states,players,target,op,near_shop,amount,valid): Bind.Bindings.conserved_ok(states,players,Inv.Inventory.roster(Inv.Inventory.run(players,target,op,near_shop,amount)),FrameBindings.inventory_conserved(players,Inv.Inventory.roster(Inv.Inventory.run(players,target,op,near_shop,amount)),Inv.Inventory.run_conserves(players,target,op,near_shop,amount)),valid)

def FrameBindings.interaction_header(frame: Inter.Interaction.Frame) -> Bind.Bindings.Header:
  match frame:
    case Inter.Interaction.Frame{pid,cid,hero,vitals,style,cull,side0,side1,side2,claimed,kills,found,name}: Bind.Bindings.Header{pid,cid,name}

law FrameBindings.interaction_of:
  for +player: P.Players.State
  {FrameBindings.interaction_header(Inter.Interaction.frame(player)) == Bind.Bindings.header(player) : Bind.Bindings.Header}

def FrameBindings.interaction_of(player):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match vitals:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}:
          match quest:
            case P.Players.Quest{main,cull,side0,side1,side2,claimed}:
              match meta:
                case P.Players.Meta{score,kills,found,name}: {==}

def FrameBindings.interaction_headers(frames: List<&2,Inter.Interaction.Frame>) -> List<&2,Bind.Bindings.Header>:
  match frames:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{FrameBindings.interaction_header(head),FrameBindings.interaction_headers(rest)}

law FrameBindings.interaction_projection:
  for +players: List<&2,P.Players.State>
  {FrameBindings.interaction_headers(Inter.Interaction.frames(players)) == Bind.Bindings.headers(players) : List<&2,Bind.Bindings.Header>}

def FrameBindings.interaction_projection(players):
  match players:
    case Nil{}: {==}
    case Con{head,rest}:
      %FrameBindings.interaction_of(head) : {Con{FrameBindings.interaction_header(Inter.Interaction.frame(head)),FrameBindings.interaction_headers(Inter.Interaction.frames(rest))} == Con{_,Bind.Bindings.headers(rest)} : List<&2,Bind.Bindings.Header>}
      %FrameBindings.interaction_projection(rest) : {Con{FrameBindings.interaction_header(Inter.Interaction.frame(head)),FrameBindings.interaction_headers(Inter.Interaction.frames(rest))} == Con{FrameBindings.interaction_header(Inter.Interaction.frame(head)),_} : List<&2,Bind.Bindings.Header>}
      {==}

law FrameBindings.interaction_equal:
  for +left: List<&2,P.Players.State>
  for +right: List<&2,P.Players.State>
  for +same: {Inter.Interaction.frames(left) == Inter.Interaction.frames(right) : List<&2,Inter.Interaction.Frame>}
  {Bind.Bindings.headers(left) == Bind.Bindings.headers(right) : List<&2,Bind.Bindings.Header>}

def FrameBindings.interaction_equal(left,right,same):
  %FrameBindings.interaction_projection(left) : {_ == Bind.Bindings.headers(right) : List<&2,Bind.Bindings.Header>}
  %FrameBindings.interaction_projection(right) : {FrameBindings.interaction_headers(Inter.Interaction.frames(left)) == _ : List<&2,Bind.Bindings.Header>}
  %same : {FrameBindings.interaction_headers(Inter.Interaction.frames(left)) == FrameBindings.interaction_headers(_) : List<&2,Bind.Bindings.Header>}
  {==}

law FrameBindings.interaction_conserved:
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: Inter.Interaction.Conserved<before,after>
  Bind.Bindings.Conserved<before,after>

def FrameBindings.interaction_conserved(before,after,conserved):
  match conserved:
    case Inter.Interaction.Conserved{ordered,permutation,frames}: Bind.Bindings.Conserved{ordered,permutation,FrameBindings.interaction_equal(after,ordered,frames)}

law FrameBindings.interaction_run:
  for +states: List<&2,Sess.Sessions.State>
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +command: Inter.Interaction.Command
  for +valid: Conn.Connections.OK<players,states>
  Conn.Connections.OK<Inter.Interaction.roster(Inter.Interaction.run(players,target,command)),states>

def FrameBindings.interaction_run(states,players,target,command,valid): Bind.Bindings.conserved_ok(states,players,Inter.Interaction.roster(Inter.Interaction.run(players,target,command)),FrameBindings.interaction_conserved(players,Inter.Interaction.roster(Inter.Interaction.run(players,target,command)),Inter.Interaction.run_conserves(players,target,command)),valid)

def FrameBindings.combat_header(frame: C.Combat.Frame) -> Bind.Bindings.Header:
  match frame:
    case C.Combat.Frame{pid,cid,hero,pos,hp,xp,dead,respawn,style,quest,meta}:
      match meta:
        case P.Players.Meta{score,kills,found,name}: Bind.Bindings.Header{pid,cid,name}

law FrameBindings.combat_of:
  for +player: P.Players.State
  {FrameBindings.combat_header(C.Combat.frame(player)) == Bind.Bindings.header(player) : Bind.Bindings.Header}

def FrameBindings.combat_of(player):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match vitals:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}:
          match quest:
            case P.Players.Quest{main,cull,side0,side1,side2,claimed}:
              match meta:
                case P.Players.Meta{score,kills,found,name}: {==}

def FrameBindings.combat_headers(frames: List<&2,C.Combat.Frame>) -> List<&2,Bind.Bindings.Header>:
  match frames:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{FrameBindings.combat_header(head),FrameBindings.combat_headers(rest)}

law FrameBindings.combat_projection:
  for +players: List<&2,P.Players.State>
  {FrameBindings.combat_headers(C.Combat.frames(players)) == Bind.Bindings.headers(players) : List<&2,Bind.Bindings.Header>}

def FrameBindings.combat_projection(players):
  match players:
    case Nil{}: {==}
    case Con{head,rest}:
      %FrameBindings.combat_of(head) : {Con{FrameBindings.combat_header(C.Combat.frame(head)),FrameBindings.combat_headers(C.Combat.frames(rest))} == Con{_,Bind.Bindings.headers(rest)} : List<&2,Bind.Bindings.Header>}
      %FrameBindings.combat_projection(rest) : {Con{FrameBindings.combat_header(C.Combat.frame(head)),FrameBindings.combat_headers(C.Combat.frames(rest))} == Con{FrameBindings.combat_header(C.Combat.frame(head)),_} : List<&2,Bind.Bindings.Header>}
      {==}

law FrameBindings.combat_equal:
  for +left: List<&2,P.Players.State>
  for +right: List<&2,P.Players.State>
  for +same: {C.Combat.frames(left) == C.Combat.frames(right) : List<&2,C.Combat.Frame>}
  {Bind.Bindings.headers(left) == Bind.Bindings.headers(right) : List<&2,Bind.Bindings.Header>}

def FrameBindings.combat_equal(left,right,same):
  %FrameBindings.combat_projection(left) : {_ == Bind.Bindings.headers(right) : List<&2,Bind.Bindings.Header>}
  %FrameBindings.combat_projection(right) : {FrameBindings.combat_headers(C.Combat.frames(left)) == _ : List<&2,Bind.Bindings.Header>}
  %same : {FrameBindings.combat_headers(C.Combat.frames(left)) == FrameBindings.combat_headers(_) : List<&2,Bind.Bindings.Header>}
  {==}

law FrameBindings.combat_conserved:
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: C.Combat.Conserved<before,after>
  Bind.Bindings.Conserved<before,after>

def FrameBindings.combat_conserved(before,after,conserved):
  match conserved:
    case C.Combat.Conserved{ordered,permutation,frames}: Bind.Bindings.Conserved{ordered,permutation,FrameBindings.combat_equal(after,ordered,frames)}

law FrameBindings.combat_run:
  for +states: List<&2,Sess.Sessions.State>
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +kind: C.Combat.Kind
  for +phase: U32
  for +valid: Conn.Connections.OK<players,states>
  Conn.Connections.OK<C.Combat.roster(C.Combat.run(players,target,kind,phase)),states>

def FrameBindings.combat_run(states,players,target,kind,phase,valid): Bind.Bindings.conserved_ok(states,players,C.Combat.roster(C.Combat.run(players,target,kind,phase)),FrameBindings.combat_conserved(players,C.Combat.roster(C.Combat.run(players,target,kind,phase)),C.Combat.run_conserves(players,target,kind,phase)),valid)

def FrameBindings.payout_header(frame: Pay.Payout.Frame) -> Bind.Bindings.Header:
  match frame:
    case Pay.Payout.Frame{pid,cid,pos,hp,dead,respawn,attack,spin,style,name}: Bind.Bindings.Header{pid,cid,name}

law FrameBindings.payout_of:
  for +player: P.Players.State
  {FrameBindings.payout_header(Pay.Payout.frame(player)) == Bind.Bindings.header(player) : Bind.Bindings.Header}

def FrameBindings.payout_of(player):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match vitals:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}:
          match quest:
            case P.Players.Quest{main,cull,side0,side1,side2,claimed}:
              match meta:
                case P.Players.Meta{score,kills,found,name}: {==}

def FrameBindings.payout_headers(frames: List<&2,Pay.Payout.Frame>) -> List<&2,Bind.Bindings.Header>:
  match frames:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{FrameBindings.payout_header(head),FrameBindings.payout_headers(rest)}

law FrameBindings.payout_projection:
  for +players: List<&2,P.Players.State>
  {FrameBindings.payout_headers(Pay.Payout.frames(players)) == Bind.Bindings.headers(players) : List<&2,Bind.Bindings.Header>}

def FrameBindings.payout_projection(players):
  match players:
    case Nil{}: {==}
    case Con{head,rest}:
      %FrameBindings.payout_of(head) : {Con{FrameBindings.payout_header(Pay.Payout.frame(head)),FrameBindings.payout_headers(Pay.Payout.frames(rest))} == Con{_,Bind.Bindings.headers(rest)} : List<&2,Bind.Bindings.Header>}
      %FrameBindings.payout_projection(rest) : {Con{FrameBindings.payout_header(Pay.Payout.frame(head)),FrameBindings.payout_headers(Pay.Payout.frames(rest))} == Con{FrameBindings.payout_header(Pay.Payout.frame(head)),_} : List<&2,Bind.Bindings.Header>}
      {==}

law FrameBindings.payout_equal:
  for +left: List<&2,P.Players.State>
  for +right: List<&2,P.Players.State>
  for +same: {Pay.Payout.frames(left) == Pay.Payout.frames(right) : List<&2,Pay.Payout.Frame>}
  {Bind.Bindings.headers(left) == Bind.Bindings.headers(right) : List<&2,Bind.Bindings.Header>}

def FrameBindings.payout_equal(left,right,same):
  %FrameBindings.payout_projection(left) : {_ == Bind.Bindings.headers(right) : List<&2,Bind.Bindings.Header>}
  %FrameBindings.payout_projection(right) : {FrameBindings.payout_headers(Pay.Payout.frames(left)) == _ : List<&2,Bind.Bindings.Header>}
  %same : {FrameBindings.payout_headers(Pay.Payout.frames(left)) == FrameBindings.payout_headers(_) : List<&2,Bind.Bindings.Header>}
  {==}

law FrameBindings.payout_conserved:
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: Pay.Payout.Conserved<before,after>
  Bind.Bindings.Conserved<before,after>

def FrameBindings.payout_conserved(before,after,conserved):
  match conserved:
    case Pay.Payout.Conserved{ordered,permutation,frames}: Bind.Bindings.Conserved{ordered,permutation,FrameBindings.payout_equal(after,ordered,frames)}

law FrameBindings.payout_run:
  for +states: List<&2,Sess.Sessions.State>
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +valid: Conn.Connections.OK<players,states>
  Conn.Connections.OK<Pay.Payout.roster(Pay.Payout.run(players,target,plan,score)),states>

def FrameBindings.payout_run(states,players,target,plan,score,valid): Bind.Bindings.conserved_ok(states,players,Pay.Payout.roster(Pay.Payout.run(players,target,plan,score)),FrameBindings.payout_conserved(players,Pay.Payout.roster(Pay.Payout.run(players,target,plan,score)),Pay.Payout.run_conserves(players,target,plan,score)),valid)

law FrameBindings.reward:
  for +states: List<&2,Sess.Sessions.State>
  for +state: S.Simulation.State
  for +pid: U32
  for +kill: R.Roster.Kill
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +valid: Conn.Connections.OK<S.Simulation.players(state),states>
  Conn.Connections.OK<S.Simulation.players(B.Battle.state(B.Battle.reward(state,pid,kill,plan,score))),states>

def FrameBindings.reward(states,state,pid,kill,plan,score,valid):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      +bound = B.Battle.bind_kind(plan,B.Battle.kind(kill))
      +paid = Pay.Payout.run(players,pid,bound,score)
      %Equal.sym(List<&2,P.Players.State>,S.Simulation.players(B.Battle.state(B.Battle.finish_reward(meta,monsters,kill,paid))),Pay.Payout.roster(paid),B.Battle.finish_reward_players(meta,monsters,kill,paid)) : Conn.Connections.OK<_,states>
      FrameBindings.payout_run(states,players,pid,bound,score,valid)

law FrameBindings.after:
  for +states: List<&2,Sess.Sessions.State>
  for +kill: Maybe<&2,R.Roster.Kill>
  for +state: S.Simulation.State
  for +pid: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +valid: Conn.Connections.OK<S.Simulation.players(state),states>
  Conn.Connections.OK<S.Simulation.players(B.Battle.state(B.Battle.after(kill,state,pid,plan,score))),states>

def FrameBindings.after(states,kill,state,pid,plan,score,valid):
  match kill:
    case None{}: valid
    case Some{info}: FrameBindings.reward(states,state,pid,info,plan,score,valid)

law FrameBindings.finish_hit:
  for +states: List<&2,Sess.Sessions.State>
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +hit: R.Roster.Strike
  for +pid: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +valid: Conn.Connections.OK<players,states>
  Conn.Connections.OK<S.Simulation.players(B.Battle.state(B.Battle.finish_hit(meta,players,hit,pid,plan,score))),states>

def FrameBindings.finish_hit(states,meta,players,hit,pid,plan,score,valid):
  match hit:
    case R.Roster.Strike{monsters,kill,dealt}: FrameBindings.after(states,kill,S.Simulation.State{meta,players,monsters},pid,plan,score,valid)

law FrameBindings.battle_strike:
  for +states: List<&2,Sess.Sessions.State>
  for +input: B.Battle.Input
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +valid: Conn.Connections.OK<S.Simulation.players(state),states>
  Conn.Connections.OK<S.Simulation.players(B.Battle.state(B.Battle.strike(input,state,pid,score))),states>

def FrameBindings.battle_strike(states,input,state,pid,score,valid):
  match input:
    case B.Battle.Input{mid,damage,plan}:
      match state:
        case S.Simulation.State{meta,players,monsters}: FrameBindings.finish_hit(states,meta,players,R.Roster.strike(monsters,mid,damage),pid,plan,score,valid)

law FrameBindings.battle_run:
  for +states: List<&2,Sess.Sessions.State>
  for +inputs: List<&2,B.Battle.Input>
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +valid: Conn.Connections.OK<S.Simulation.players(state),states>
  Conn.Connections.OK<S.Simulation.players(B.Battle.state(B.Battle.run(inputs,state,pid,score))),states>

def FrameBindings.battle_run(states,inputs,state,pid,score,valid):
  match inputs:
    case Nil{}: valid
    case Con{head,rest}: FrameBindings.battle_run(states,rest,B.Battle.state(B.Battle.strike(head,state,pid,score)),pid,score,FrameBindings.battle_strike(states,head,state,pid,score,valid))

law FrameBindings.execute:
  for +states: List<&2,Sess.Sessions.State>
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +admitted: C.Combat.Result
  for +inputs: List<&2,B.Battle.Input>
  for +pid: U32
  for +score: U32
  for +valid: Conn.Connections.OK<C.Combat.roster(admitted),states>
  Conn.Connections.OK<S.Simulation.players(B.Battle.state(B.Battle.execute(meta,monsters,admitted,inputs,pid,score))),states>

def FrameBindings.execute(states,meta,monsters,admitted,inputs,pid,score,valid):
  match admitted:
    case C.Combat.Result{players,attacker}:
      match attacker:
        case None{}: valid
        case Some{actor}: FrameBindings.battle_run(states,inputs,S.Simulation.State{meta,players,monsters},pid,score,valid)

law FrameBindings.command:
  for +states: List<&2,Sess.Sessions.State>
  for +kind: C.Combat.Kind
  for +state: S.Simulation.State
  for +inputs: List<&2,B.Battle.Input>
  for +pid: U32
  for +score: U32
  for +valid: Conn.Connections.OK<S.Simulation.players(state),states>
  Conn.Connections.OK<S.Simulation.players(B.Battle.state(B.Battle.command(kind,state,inputs,pid,score))),states>

def FrameBindings.command(states,kind,state,inputs,pid,score,valid):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      FrameBindings.execute(states,meta,monsters,C.Combat.run(players,pid,kind,S.Simulation.phase(meta)),inputs,pid,score,FrameBindings.combat_run(states,players,pid,kind,S.Simulation.phase(meta),valid))


law FrameBindings.inventory_world:
  for +seed: U32
  for +world: S.Simulation.State
  for +states: List<&2,Sess.Sessions.State>
  for +target: U32
  for +op: G.Bq.HOp
  for +near_shop: Bool
  for +amount: U32
  for +valid: Conn.Connections.WorldOK<seed,world,states>
  Conn.Connections.WorldOK<seed,Id.PlayerIds.run_change(Id.PlayerIds.Inventory{target,op,near_shop,amount},world,L.Landscape.maps(seed)),states>

def FrameBindings.inventory_world(seed,world,states,target,op,near_shop,amount,valid):
  match world:
    case S.Simulation.State{meta,players,monsters}:
      match valid:
        case Conn.Connections.WorldOK{world_ok,connections}: Conn.Connections.WorldOK{W.WorldState.inventory(seed,S.Simulation.State{meta,players,monsters},target,op,near_shop,amount,world_ok),FrameBindings.inventory_run(states,players,target,op,near_shop,amount,connections)}

law FrameBindings.interaction_world:
  for +seed: U32
  for +world: S.Simulation.State
  for +states: List<&2,Sess.Sessions.State>
  for +target: U32
  for +command: Inter.Interaction.Command
  for +valid: Conn.Connections.WorldOK<seed,world,states>
  Conn.Connections.WorldOK<seed,Id.PlayerIds.run_change(Id.PlayerIds.Interact{target,command},world,L.Landscape.maps(seed)),states>

def FrameBindings.interaction_world(seed,world,states,target,command,valid):
  match world:
    case S.Simulation.State{meta,players,monsters}:
      match valid:
        case Conn.Connections.WorldOK{world_ok,connections}: Conn.Connections.WorldOK{W.WorldState.interact(seed,S.Simulation.State{meta,players,monsters},target,command,world_ok),FrameBindings.interaction_run(states,players,target,command,connections)}

law FrameBindings.fight_world:
  for +kind: C.Combat.Kind
  for +seed: U32
  for +world: S.Simulation.State
  for +states: List<&2,Sess.Sessions.State>
  for +inputs: List<&2,B.Battle.Input>
  for +pid: U32
  for +score: U32
  for +valid: Conn.Connections.WorldOK<seed,world,states>
  Conn.Connections.WorldOK<seed,B.Battle.state(B.Battle.command(kind,world,inputs,pid,score)),states>

def FrameBindings.fight_world(kind,seed,world,states,inputs,pid,score,valid):
  match valid:
    case Conn.Connections.WorldOK{world_ok,connections}: Conn.Connections.WorldOK{W.WorldState.fight(kind,seed,world,inputs,pid,score,world_ok),FrameBindings.command(states,kind,world,inputs,pid,score,connections)}

# Ordinary game commands keep connections, unlike the joint lifecycle operations.
# Authentication/command ownership and tick scheduling are separate obligations.
type FrameBindings.Command is Data:
  FrameBindings.Inventory{target: U32,op: G.Bq.HOp,near_shop: Bool,amount: U32}
  FrameBindings.Interact{target: U32,command: Inter.Interaction.Command}
  FrameBindings.Fight{kind: C.Combat.Kind,inputs: List<&2,B.Battle.Input>,pid: U32,score: U32}

def FrameBindings.change(command: FrameBindings.Command) -> Id.PlayerIds.Change:
  match command:
    case FrameBindings.Inventory{target,op,near_shop,amount}: Id.PlayerIds.Inventory{target,op,near_shop,amount}
    case FrameBindings.Interact{target,command}: Id.PlayerIds.Interact{target,command}
    case FrameBindings.Fight{kind,inputs,pid,score}: Id.PlayerIds.Fight{kind,inputs,pid,score}

def FrameBindings.run(command: FrameBindings.Command,seed: U32,result: K.Creation.Result) -> K.Creation.Result:
  match result:
    case K.Creation.Result{world,states}: K.Creation.Result{Id.PlayerIds.run_change(FrameBindings.change(command),world,L.Landscape.maps(seed)),states}

law FrameBindings.run_ok:
  for +command: FrameBindings.Command
  for +seed: U32
  for +result: K.Creation.Result
  for +valid: K.Creation.OK(seed,result)
  K.Creation.OK(seed,FrameBindings.run(command,seed,result))

def FrameBindings.run_ok(command,seed,result,valid):
  match command:
    case FrameBindings.Inventory{target,op,near_shop,amount}:
      match result:
        case K.Creation.Result{world,states}: FrameBindings.inventory_world(seed,world,states,target,op,near_shop,amount,valid)
    case FrameBindings.Interact{target,command}:
      match result:
        case K.Creation.Result{world,states}: FrameBindings.interaction_world(seed,world,states,target,command,valid)
    case FrameBindings.Fight{kind,inputs,pid,score}:
      match result:
        case K.Creation.Result{world,states}: FrameBindings.fight_world(kind,seed,world,states,inputs,pid,score,valid)

type FrameBindings.Input is Data:
  FrameBindings.Lifecycle{input: D.Disconnect.Input}
  FrameBindings.Action{command: FrameBindings.Command}

def FrameBindings.step(input: FrameBindings.Input,seed: U32,result: K.Creation.Result) -> K.Creation.Result:
  match input:
    case FrameBindings.Lifecycle{input}: D.Disconnect.step(input,result)
    case FrameBindings.Action{command}: FrameBindings.run(command,seed,result)

def FrameBindings.trace(inputs: List<&2,FrameBindings.Input>,+seed: U32,result: K.Creation.Result) -> K.Creation.Result:
  match inputs:
    case Nil{}: result
    case Con{head,rest}: FrameBindings.trace(rest,seed,FrameBindings.step(head,seed,result))

law FrameBindings.step_ok:
  for +input: FrameBindings.Input
  for +seed: U32
  for +result: K.Creation.Result
  for +valid: K.Creation.OK(seed,result)
  K.Creation.OK(seed,FrameBindings.step(input,seed,result))

def FrameBindings.step_ok(input,seed,result,valid):
  match input:
    case FrameBindings.Lifecycle{input}: D.Disconnect.step_ok(input,seed,result,valid)
    case FrameBindings.Action{command}: FrameBindings.run_ok(command,seed,result,valid)

law FrameBindings.trace_ok:
  for +inputs: List<&2,FrameBindings.Input>
  for +seed: U32
  for +result: K.Creation.Result
  for +valid: K.Creation.OK(seed,result)
  K.Creation.OK(seed,FrameBindings.trace(inputs,seed,result))

def FrameBindings.trace_ok(inputs,seed,result,valid):
  match inputs:
    case Nil{}: valid
    case Con{head,rest}: FrameBindings.trace_ok(rest,seed,FrameBindings.step(head,seed,result),FrameBindings.step_ok(head,seed,result,valid))

law FrameBindings.fresh_trace:
  for +inputs: List<&2,FrameBindings.Input>
  for +world: U32
  for +seed: U32
  for +now: U32
  K.Creation.OK(seed,FrameBindings.trace(inputs,seed,K.Creation.Result{T.Terrain.simulation(Pop.Population.fresh(world,seed,now)),Nil{}}))

def FrameBindings.fresh_trace(inputs,world,seed,now): FrameBindings.trace_ok(inputs,seed,K.Creation.Result{T.Terrain.simulation(Pop.Population.fresh(world,seed,now)),Nil{}},Conn.Connections.fresh_world(world,seed,now))
