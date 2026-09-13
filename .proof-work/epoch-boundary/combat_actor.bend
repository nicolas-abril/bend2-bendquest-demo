# Player identity, position and vital-state preservation through sequential hits.
import Base
import ./players.bend as P
import ./payouts.bend as Pay
import ./targeting.bend as T
import ./player_membership.bend as PM
import ./bindings.bend as Bind
import ./numeric.bend as N
import ./battle.bend as B
import ./simulation.bend as S
import ./roster.bend as R
import ./monsters.bend as M
import ./combat_frame.bend as CF
import ./combat_targets.bend as Targets
import ./spin_plans.bend as Spin
import ./live_combat.bend as L
import ./identity.bend as I
import ./vitals.bend as V
import ./target_plans.bend as TP
import ./game.bend as G

type Actor.Aligned<-left: List<&2,P.Players.State>,-right: List<&2,P.Players.State>> is Data:
  Actor.Empty{ls: {left == Nil{} : List<&2,P.Players.State>},rs: {right == Nil{} : List<&2,P.Players.State>}}
  Actor.Pair{a: P.Players.State,b: P.Players.State,xs: List<&2,P.Players.State>,ys: List<&2,P.Players.State>,ls: {left == Con{a,xs} : List<&2,P.Players.State>},rs: {right == Con{b,ys} : List<&2,P.Players.State>},same: {Pay.Payout.frame(a) == Pay.Payout.frame(b) : Pay.Payout.Frame},tails: Actor.Aligned<xs,ys>}

def Actor.first(headers: List<&2,Pay.Payout.Frame>,fallback: Pay.Payout.Frame) -> Pay.Payout.Frame:
  match headers:
    case Nil{}: fallback
    case Con{head,rest}: head

def Actor.rest(headers: List<&2,Pay.Payout.Frame>) -> List<&2,Pay.Payout.Frame>:
  match headers:
    case Nil{}: Nil{}
    case Con{head,rest}: rest

def Actor.nonempty(headers: List<&2,Pay.Payout.Frame>) -> Bool:
  match headers:
    case Nil{}: False{}
    case Con{head,rest}: True{}

law Actor.nil_cons:
  for +head: Pay.Payout.Frame
  for +rest: List<&2,Pay.Payout.Frame>
  for +same: {Nil{} == Con{head,rest} : List<&2,Pay.Payout.Frame>}
  Empty

def Actor.nil_cons(head,rest,same): N.Numeric.true_ne_false((%same : {Actor.nonempty(_) == False{} : Bool}; {==}))

law Actor.heads_equal:
  for +a: Pay.Payout.Frame
  for +b: Pay.Payout.Frame
  for +xs: List<&2,Pay.Payout.Frame>
  for +ys: List<&2,Pay.Payout.Frame>
  for +same: {Con{a,xs} == Con{b,ys} : List<&2,Pay.Payout.Frame>}
  {a == b : Pay.Payout.Frame}

def Actor.heads_equal(a,b,xs,ys,same):
  %same : {a == Actor.first(_,a) : Pay.Payout.Frame}
  {==}

law Actor.tails_equal:
  for +a: Pay.Payout.Frame
  for +b: Pay.Payout.Frame
  for +xs: List<&2,Pay.Payout.Frame>
  for +ys: List<&2,Pay.Payout.Frame>
  for +same: {Con{a,xs} == Con{b,ys} : List<&2,Pay.Payout.Frame>}
  {xs == ys : List<&2,Pay.Payout.Frame>}

def Actor.tails_equal(a,b,xs,ys,same):
  %same : {xs == Actor.rest(_) : List<&2,Pay.Payout.Frame>}
  {==}

law Actor.align:
  for +left: List<&2,P.Players.State>
  for +right: List<&2,P.Players.State>
  for +same: {Pay.Payout.frames(left) == Pay.Payout.frames(right) : List<&2,Pay.Payout.Frame>}
  Actor.Aligned<left,right>

def Actor.align(left,right,same):
  match left:
    case Nil{}:
      match right:
        case Nil{}: Actor.Empty{{==},{==}}
        case Con{head,rest}: Empty.absurd(Actor.Aligned<Nil{},Con{head,rest}>,Actor.nil_cons(Pay.Payout.frame(head),Pay.Payout.frames(rest),same))
    case Con{a,xs}:
      match right:
        case Nil{}: Empty.absurd(Actor.Aligned<Con{a,xs},Nil{}>,Actor.nil_cons(Pay.Payout.frame(a),Pay.Payout.frames(xs),Equal.sym(List<&2,Pay.Payout.Frame>,Con{Pay.Payout.frame(a),Pay.Payout.frames(xs)},Nil{},same)))
        case Con{b,ys}: Actor.Pair{a,b,xs,ys,{==},{==},Actor.heads_equal(Pay.Payout.frame(a),Pay.Payout.frame(b),Pay.Payout.frames(xs),Pay.Payout.frames(ys),same),Actor.align(xs,ys,Actor.tails_equal(Pay.Payout.frame(a),Pay.Payout.frame(b),Pay.Payout.frames(xs),Pay.Payout.frames(ys),same))}

type Actor.Member<-before: P.Players.State,-players: List<&2,P.Players.State>> is Data:
  Actor.Member{after: P.Players.State,inside: T.Targeting.In<after,players>,same: {Pay.Payout.frame(after) == Pay.Payout.frame(before) : Pay.Payout.Frame}}

law Actor.weaken_member:
  for +head: P.Players.State
  for +rest: List<&2,P.Players.State>
  for +player: P.Players.State
  for +member: Actor.Member<player,rest>
  Actor.Member<player,Con{head,rest}>

def Actor.weaken_member(head,rest,player,member):
  match member:
    case Actor.Member{after,inside,same}: Actor.Member{after,T.Targeting.There{head,rest,{==},inside},same}

law Actor.aligned_member:
  for +player: P.Players.State
  for -left: List<&2,P.Players.State>
  for -right: List<&2,P.Players.State>
  for +aligned: Actor.Aligned<left,right>
  for +inside: T.Targeting.In<player,right>
  Actor.Member<player,left>

def Actor.aligned_member(player,left,right,aligned,inside):
  match aligned:
    case Actor.Empty{ls,rs}: Empty.absurd(Actor.Member<player,left>,Bind.Bindings.nil_member(player,(%rs : T.Targeting.In<player,_>; inside)))
    case Actor.Pair{a,b,xs,ys,ls,rs,same,tails}:
      match inside:
        case T.Targeting.Here{rest,shape}:
          Actor.Member{a,T.Targeting.Here{xs,ls},Equal.trans(Pay.Payout.Frame,Pay.Payout.frame(a),Pay.Payout.frame(b),Pay.Payout.frame(player),same,Equal.cong(P.Players.State,Pay.Payout.Frame,(p => Pay.Payout.frame(p)),b,player,PM.PlayerMembership.cons_head(b,player,ys,rest,Equal.trans(List<&2,P.Players.State>,Con{b,ys},right,Con{player,rest},Equal.sym(List<&2,P.Players.State>,right,Con{b,ys},rs),shape))))}
        case T.Targeting.There{head,rest,shape,later}:
          %Equal.sym(List<&2,P.Players.State>,left,Con{a,xs},ls) : Actor.Member<player,_>
          Actor.weaken_member(a,xs,player,Actor.aligned_member(player,xs,ys,tails,(%Equal.sym(List<&2,P.Players.State>,ys,rest,PM.PlayerMembership.cons_tail(b,head,ys,rest,Equal.trans(List<&2,P.Players.State>,Con{b,ys},right,Con{head,rest},Equal.sym(List<&2,P.Players.State>,right,Con{b,ys},rs),shape))) : T.Targeting.In<player,_>; later)))


law Actor.chain:
  for +original: P.Players.State
  for +current: P.Players.State
  for +players: List<&2,P.Players.State>
  for +same: {Pay.Payout.frame(current) == Pay.Payout.frame(original) : Pay.Payout.Frame}
  for +member: Actor.Member<current,players>
  Actor.Member<original,players>

def Actor.chain(original,current,players,same,member):
  match member:
    case Actor.Member{after,inside,equal}: Actor.Member{after,inside,Equal.trans(Pay.Payout.Frame,Pay.Payout.frame(after),Pay.Payout.frame(current),Pay.Payout.frame(original),equal,same)}

law Actor.conserved_member:
  for +player: P.Players.State
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: Pay.Payout.Conserved<before,after>
  for +member: Actor.Member<player,before>
  Actor.Member<player,after>

def Actor.conserved_member(player,before,after,conserved,member):
  match conserved:
    case Pay.Payout.Conserved{ordered,permutation,frames}:
      match member:
        case Actor.Member{current,inside,same}:
          Actor.chain(player,current,after,same,Actor.aligned_member(current,after,ordered,Actor.align(after,ordered,frames),Bind.Bindings.perm_member(current,ordered,before,permutation,inside)))

law Actor.payout_run:
  for +player: P.Players.State
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +valid: Actor.Member<player,players>
  Actor.Member<player,Pay.Payout.roster(Pay.Payout.run(players,target,plan,score))>

def Actor.payout_run(player,players,target,plan,score,valid): Actor.conserved_member(player,players,Pay.Payout.roster(Pay.Payout.run(players,target,plan,score)),Pay.Payout.run_conserves(players,target,plan,score),valid)

law Actor.reward:
  for +player: P.Players.State
  for +state: S.Simulation.State
  for +pid: U32
  for +kill: R.Roster.Kill
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +valid: Actor.Member<player,S.Simulation.players(state)>
  Actor.Member<player,S.Simulation.players(B.Battle.state(B.Battle.reward(state,pid,kill,plan,score)))>

def Actor.reward(player,state,pid,kill,plan,score,valid):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      +bound = B.Battle.bind_kind(plan,B.Battle.kind(kill))
      +paid = Pay.Payout.run(players,pid,bound,score)
      %Equal.sym(List<&2,P.Players.State>,S.Simulation.players(B.Battle.state(B.Battle.finish_reward(meta,monsters,kill,paid))),Pay.Payout.roster(paid),B.Battle.finish_reward_players(meta,monsters,kill,paid)) : Actor.Member<player,_>
      Actor.payout_run(player,players,pid,bound,score,valid)

law Actor.after:
  for +player: P.Players.State
  for +kill: Maybe<&2,R.Roster.Kill>
  for +state: S.Simulation.State
  for +pid: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +valid: Actor.Member<player,S.Simulation.players(state)>
  Actor.Member<player,S.Simulation.players(B.Battle.state(B.Battle.after(kill,state,pid,plan,score)))>

def Actor.after(player,kill,state,pid,plan,score,valid):
  match kill:
    case None{}: valid
    case Some{info}: Actor.reward(player,state,pid,info,plan,score,valid)

law Actor.finish_hit:
  for +player: P.Players.State
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +hit: R.Roster.Strike
  for +pid: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +valid: Actor.Member<player,players>
  Actor.Member<player,S.Simulation.players(B.Battle.state(B.Battle.finish_hit(meta,players,hit,pid,plan,score)))>

def Actor.finish_hit(player,meta,players,hit,pid,plan,score,valid):
  match hit:
    case R.Roster.Strike{monsters,kill,dealt}: Actor.after(player,kill,S.Simulation.State{meta,players,monsters},pid,plan,score,valid)

law Actor.battle_strike:
  for +player: P.Players.State
  for +input: B.Battle.Input
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +valid: Actor.Member<player,S.Simulation.players(state)>
  Actor.Member<player,S.Simulation.players(B.Battle.state(B.Battle.strike(input,state,pid,score)))>

def Actor.battle_strike(player,input,state,pid,score,valid):
  match input:
    case B.Battle.Input{mid,damage,plan}:
      match state:
        case S.Simulation.State{meta,players,monsters}: Actor.finish_hit(player,meta,players,R.Roster.strike(monsters,mid,damage),pid,plan,score,valid)

law Actor.battle_run:
  for +player: P.Players.State
  for +inputs: List<&2,B.Battle.Input>
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +valid: Actor.Member<player,S.Simulation.players(state)>
  Actor.Member<player,S.Simulation.players(B.Battle.state(B.Battle.run(inputs,state,pid,score)))>

def Actor.battle_run(player,inputs,state,pid,score,valid):
  match inputs:
    case Nil{}: valid
    case Con{head,rest}: Actor.battle_run(player,rest,B.Battle.state(B.Battle.strike(head,state,pid,score)),pid,score,Actor.battle_strike(player,head,state,pid,score,valid))

def Actor.frame_pid(frame: Pay.Payout.Frame) -> U32:
  match frame:
    case Pay.Payout.Frame{pid,cid,pos,hp,dead,respawn,attack,spin,style,name}: pid

def Actor.frame_point(frame: Pay.Payout.Frame) -> Targets.Targets.Point:
  match frame:
    case Pay.Payout.Frame{pid,cid,pos,hp,dead,respawn,attack,spin,style,name}:
      match pos:
        case P.Players.Pos{zone,x,y,dir,moving}: Targets.Targets.Point{zone,x,y}

def Actor.point(player: P.Players.State) -> Targets.Targets.Point: Actor.frame_point(Pay.Payout.frame(player))

law Actor.point_of:
  for +pid: U32
  for +cid: U32
  for +hero: G.Bq.Hero
  for +zone: U32
  for +x: U32
  for +y: U32
  for +dir: U32
  for +moving: U32
  for +vitals: V.Vitals.State
  for +style: P.Players.Style
  for +quest: P.Players.Quest
  for +meta: P.Players.Meta
  {Actor.point(P.Players.State{pid,cid,hero,P.Players.Pos{zone,x,y,dir,moving},vitals,style,quest,meta}) == Targets.Targets.Point{zone,x,y} : Targets.Targets.Point}

def Actor.point_of(pid,cid,hero,zone,x,y,dir,moving,vitals,style,quest,meta):
  match vitals:
    case V.Vitals.State{hp,xp,dead,respawn,attack,spin}:
      match meta:
        case P.Players.Meta{score,kills,found,name}: {==}

law Actor.frame_pid_of:
  for +player: P.Players.State
  {Actor.frame_pid(Pay.Payout.frame(player)) == P.Players.id(player) : U32}

def Actor.frame_pid_of(player):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match vitals:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}:
          match meta:
            case P.Players.Meta{score,kills,found,name}: {==}

law Actor.same_pid:
  for +left: P.Players.State
  for +right: P.Players.State
  for +same: {Pay.Payout.frame(left) == Pay.Payout.frame(right) : Pay.Payout.Frame}
  {P.Players.id(left) == P.Players.id(right) : U32}

def Actor.same_pid(left,right,same):
  %Actor.frame_pid_of(left) : {_ == P.Players.id(right) : U32}
  %Actor.frame_pid_of(right) : {Actor.frame_pid(Pay.Payout.frame(left)) == _ : U32}
  %same : {Actor.frame_pid(Pay.Payout.frame(left)) == Actor.frame_pid(_) : U32}
  {==}

law Actor.same_point:
  for +left: P.Players.State
  for +right: P.Players.State
  for +same: {Pay.Payout.frame(left) == Pay.Payout.frame(right) : Pay.Payout.Frame}
  {Actor.point(left) == Actor.point(right) : Targets.Targets.Point}

def Actor.same_point(left,right,same): Equal.cong(Pay.Payout.Frame,Targets.Targets.Point,(frame => Actor.frame_point(frame)),Pay.Payout.frame(left),Pay.Payout.frame(right),same)

# A hit has an actual current player record, its unchanged identity/frame,
# and an eligible monster lookup relative to that current player's position.
type Actor.Strike<-original: P.Players.State,-state: S.Simulation.State,-mid: U32> is Data:
  Actor.Strike{current: P.Players.State,inside: T.Targeting.In<current,S.Simulation.players(state)>,same: {Pay.Payout.frame(current) == Pay.Payout.frame(original) : Pay.Payout.Frame},pid: {P.Players.id(current) == P.Players.id(original) : U32},source: Targets.Targets.IDSource<S.Simulation.monsters(state),Actor.point(current),mid>}

law Actor.strike_witness:
  for +original: P.Players.State
  for +state: S.Simulation.State
  for +mid: U32
  for +member: Actor.Member<original,S.Simulation.players(state)>
  for +source: Targets.Targets.IDSource<S.Simulation.monsters(state),Actor.point(original),mid>
  Actor.Strike<original,state,mid>

def Actor.strike_witness(original,state,mid,member,source):
  match member:
    case Actor.Member{current,inside,same}: Actor.Strike{current,inside,same,Actor.same_pid(current,original,same),(%Equal.sym(Targets.Targets.Point,Actor.point(current),Actor.point(original),Actor.same_point(current,original,same)) : Targets.Targets.IDSource<S.Simulation.monsters(state),_,mid>; source)}

def Actor.Execution(inputs: List<&2,B.Battle.Input>,+state: S.Simulation.State,+original: P.Players.State,+score: U32) -> Data:
  match inputs:
    case Nil{}: Unit
    case Con{head,rest}:
      +head = head
      Sigma<&2,&2,Actor.Strike<original,state,TP.TargetPlans.id(head)>,(witness => Actor.Execution(rest,B.Battle.state(B.Battle.strike(head,state,P.Players.id(original),score)),original,score))>

law Actor.inputs_execution:
  for +inputs: List<&2,B.Battle.Input>
  for +state: S.Simulation.State
  for +original: P.Players.State
  for +score: U32
  for +member: Actor.Member<original,S.Simulation.players(state)>
  for +sources: CF.CombatFrame.Execution(inputs,state,Actor.point(original),P.Players.id(original),score)
  Actor.Execution(inputs,state,original,score)

def Actor.inputs_execution(inputs,state,original,score,member,sources):
  match inputs:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match sources:
        case Tuple{source,later}: Tuple{Actor.strike_witness(original,state,TP.TargetPlans.id(head),member,source),Actor.inputs_execution(rest,B.Battle.state(B.Battle.strike(head,state,P.Players.id(original),score)),original,score,Actor.battle_strike(original,head,state,P.Players.id(original),score,member),later)}

law Actor.spin_execution:
  for +state: S.Simulation.State
  for +original: P.Players.State
  for +score: U32
  for build: (@+selected: List<&2,M.Monsters.State> -> Spin.SpinPlans.Powers(selected))
  for +member: Actor.Member<original,S.Simulation.players(state)>
  for +unique: I.Identity.Monsters(S.Simulation.monsters(state))
  Actor.Execution(L.LiveCombat.inputs(Spin.SpinPlans.run(S.Simulation.monsters(state),Actor.point(original),build)),state,original,score)

def Actor.spin_execution(state,original,score,build,member,unique):
  +selected = Targets.Targets.filter(S.Simulation.monsters(state),Actor.point(original))
  +powers = build(selected)
  Actor.inputs_execution(Spin.SpinPlans.inputs(selected,powers),state,original,score,member,CF.CombatFrame.inputs_execution(selected,powers,state,P.Players.id(original),score,Actor.point(original),Targets.Targets.filter_sources(S.Simulation.monsters(state),Actor.point(original)),unique,Targets.Targets.filter_unique(S.Simulation.monsters(state),Actor.point(original),unique)))
