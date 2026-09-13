# A dead full monster record persists through later strikes without respawn.
import Base
import ./monsters.bend as M
import ./vitals.bend as V
import ./roster.bend as R
import ./combat_targets.bend as Member
import ./combat_frame.bend as Frame
import ./identity.bend as I
import ./numeric.bend as N
import ./battle.bend as B
import ./simulation.bend as S
import ./players.bend as P
import ./payouts.bend as Pay
import ./target_plans.bend as TP

law Dead.quiet_result:
  for +monster: M.Monsters.State
  for +others: List<&2,M.Monsters.State>
  {R.Roster.strike_result(M.Monsters.Hit{monster,False{},0},others) == R.Roster.Strike{Con{monster,others},None{},0} : R.Roster.Strike}

def Dead.quiet_result(monster,others):
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}: {==}

law Dead.taken:
  for +taken: R.Roster.Take
  for +monster: M.Monsters.State
  for +damage: U32
  for +found: {R.Roster.found(taken) == Some{monster} : Maybe<&2,M.Monsters.State>}
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  {R.Roster.strike_taken(taken,damage) == R.Roster.Strike{Con{monster,R.Roster.others(taken)},None{},0} : R.Roster.Strike}

def Dead.taken(taken,monster,damage,found,dead):
  match taken:
    case R.Roster.Take{others,selected}:
      %Equal.sym(Maybe<&2,M.Monsters.State>,selected,Some{monster},found) : {R.Roster.strike_taken(R.Roster.Take{others,_},damage) == R.Roster.Strike{Con{monster,others},None{},0} : R.Roster.Strike}
      %Equal.sym(M.Monsters.Hit,M.Monsters.hit(monster,damage,R.Roster.respawn_time(M.Monsters.kind(monster))),M.Monsters.Hit{monster,False{},0},M.Monsters.dead_hit_noop(monster,damage,R.Roster.respawn_time(M.Monsters.kind(monster)),dead)) : {R.Roster.strike_result(_,others) == R.Roster.Strike{Con{monster,others},None{},0} : R.Roster.Strike}
      Dead.quiet_result(monster,others)

law Dead.roster:
  for +monsters: List<&2,M.Monsters.State>
  for +monster: M.Monsters.State
  for +damage: U32
  for +inside: Member.Targets.In<monster,monsters>
  for +unique: I.Identity.Monsters(monsters)
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  {R.Roster.strike(monsters,R.Roster.id(monster),damage) == R.Roster.Strike{Con{monster,R.Roster.others(R.Roster.take(monsters,R.Roster.id(monster)))},None{},0} : R.Roster.Strike}

def Dead.roster(monsters,monster,damage,inside,unique,dead): Dead.taken(R.Roster.take(monsters,R.Roster.id(monster)),monster,damage,Member.Targets.lookup_member(monster,monsters,inside,unique),dead)

law Dead.own:
  for +monster: M.Monsters.State
  for +state: S.Simulation.State
  for +damage: U32
  for +payout: Pay.Payout.Plan
  for +pid: U32
  for +score: U32
  for +inside: Member.Targets.In<monster,S.Simulation.monsters(state)>
  for +unique: I.Identity.Monsters(S.Simulation.monsters(state))
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  {B.Battle.strike(B.Battle.Input{R.Roster.id(monster),damage,payout},state,pid,score) == B.Battle.Result{S.Simulation.State{S.Simulation.meta(state),S.Simulation.players(state),Con{monster,R.Roster.others(R.Roster.take(S.Simulation.monsters(state),R.Roster.id(monster)))}},Nil{}} : B.Battle.Result}

def Dead.own(monster,state,damage,payout,pid,score,inside,unique,dead):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      %Equal.sym(R.Roster.Strike,R.Roster.strike(monsters,R.Roster.id(monster),damage),R.Roster.Strike{Con{monster,R.Roster.others(R.Roster.take(monsters,R.Roster.id(monster)))},None{},0},Dead.roster(monsters,monster,damage,inside,unique,dead)) : {B.Battle.finish_hit(meta,players,_,pid,payout,score) == B.Battle.Result{S.Simulation.State{meta,players,Con{monster,R.Roster.others(R.Roster.take(monsters,R.Roster.id(monster)))}},Nil{}} : B.Battle.Result}
      {==}

law Dead.own_member:
  for +monster: M.Monsters.State
  for +state: S.Simulation.State
  for +damage: U32
  for +payout: Pay.Payout.Plan
  for +pid: U32
  for +score: U32
  for +inside: Member.Targets.In<monster,S.Simulation.monsters(state)>
  for +unique: I.Identity.Monsters(S.Simulation.monsters(state))
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  Member.Targets.In<monster,S.Simulation.monsters(B.Battle.state(B.Battle.strike(B.Battle.Input{R.Roster.id(monster),damage,payout},state,pid,score)))>

def Dead.own_member(monster,state,damage,payout,pid,score,inside,unique,dead):
  %Equal.sym(B.Battle.Result,B.Battle.strike(B.Battle.Input{R.Roster.id(monster),damage,payout},state,pid,score),B.Battle.Result{S.Simulation.State{S.Simulation.meta(state),S.Simulation.players(state),Con{monster,R.Roster.others(R.Roster.take(S.Simulation.monsters(state),R.Roster.id(monster)))}},Nil{}},Dead.own(monster,state,damage,payout,pid,score,inside,unique,dead)) : Member.Targets.In<monster,S.Simulation.monsters(B.Battle.state(_))>
  Member.Targets.Here{R.Roster.others(R.Roster.take(S.Simulation.monsters(state),R.Roster.id(monster))),{==}}

law Dead.preserve_member:
  for +monster: M.Monsters.State
  for +before: List<&2,M.Monsters.State>
  for +after: List<&2,M.Monsters.State>
  for +mid: U32
  for +inside: Member.Targets.In<monster,before>
  for +different: {U32.is_eq(R.Roster.id(monster),mid) == False{} : Bool}
  for +frame: {Frame.CombatFrame.erase(after,mid) == Frame.CombatFrame.erase(before,mid) : List<&2,M.Monsters.State>}
  Member.Targets.In<monster,after>

def Dead.preserve_member(monster,before,after,mid,inside,different,frame):
  Frame.CombatFrame.in_members(monster,Frame.CombatFrame.erase(after,mid),after,(%Equal.sym(List<&2,M.Monsters.State>,Frame.CombatFrame.erase(after,mid),Frame.CombatFrame.erase(before,mid),frame) : Member.Targets.In<monster,_>; Frame.CombatFrame.erase_contains(monster,before,mid,inside,different)),Frame.CombatFrame.erase_members(after,mid))

law Dead.branch_member:
  for +same: Bool
  for +monster: M.Monsters.State
  for +state: S.Simulation.State
  for +mid: U32
  for +damage: U32
  for +payout: Pay.Payout.Plan
  for +pid: U32
  for +score: U32
  for +inside: Member.Targets.In<monster,S.Simulation.monsters(state)>
  for +unique: I.Identity.Monsters(S.Simulation.monsters(state))
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  for +decision: {U32.is_eq(R.Roster.id(monster),mid) == same : Bool}
  Member.Targets.In<monster,S.Simulation.monsters(B.Battle.state(B.Battle.strike(B.Battle.Input{mid,damage,payout},state,pid,score)))>

def Dead.branch_member(same,monster,state,mid,damage,payout,pid,score,inside,unique,dead,decision):
  match same:
    case True{}:
      %N.Numeric.u32_eq_sound(R.Roster.id(monster),mid,decision) : Member.Targets.In<monster,S.Simulation.monsters(B.Battle.state(B.Battle.strike(B.Battle.Input{_,damage,payout},state,pid,score)))>
      Dead.own_member(monster,state,damage,payout,pid,score,inside,unique,dead)
    case False{}: Dead.preserve_member(monster,S.Simulation.monsters(state),S.Simulation.monsters(B.Battle.state(B.Battle.strike(B.Battle.Input{mid,damage,payout},state,pid,score))),mid,inside,decision,Frame.CombatFrame.battle_erase(mid,damage,payout,state,pid,score))

law Dead.step_member:
  for +monster: M.Monsters.State
  for +input: B.Battle.Input
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +inside: Member.Targets.In<monster,S.Simulation.monsters(state)>
  for +unique: I.Identity.Monsters(S.Simulation.monsters(state))
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  Member.Targets.In<monster,S.Simulation.monsters(B.Battle.state(B.Battle.strike(input,state,pid,score)))>

def Dead.step_member(monster,input,state,pid,score,inside,unique,dead):
  match input:
    case B.Battle.Input{mid,damage,payout}: Dead.branch_member(U32.is_eq(R.Roster.id(monster),mid),monster,state,mid,damage,payout,pid,score,inside,unique,dead,{==})

law Dead.run_member:
  for +inputs: List<&2,B.Battle.Input>
  for +monster: M.Monsters.State
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +inside: Member.Targets.In<monster,S.Simulation.monsters(state)>
  for +unique: I.Identity.Monsters(S.Simulation.monsters(state))
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  Member.Targets.In<monster,S.Simulation.monsters(B.Battle.state(B.Battle.run(inputs,state,pid,score)))>

def Dead.run_member(inputs,monster,state,pid,score,inside,unique,dead):
  match inputs:
    case Nil{}: inside
    case Con{head,rest}: Dead.run_member(rest,monster,B.Battle.state(B.Battle.strike(head,state,pid,score)),pid,score,Dead.step_member(monster,head,state,pid,score,inside,unique,dead),I.Identity.battle_strike_unique(head,state,pid,score,unique),dead)

def Dead.kill_id(kill: R.Roster.Kill) -> U32:
  match kill:
    case R.Roster.Kill{kind,rare,zone,mid}: mid

def Dead.KillTarget(kill: Maybe<&2,R.Roster.Kill>,+target: U32) -> Data:
  match kill:
    case None{}: Unit
    case Some{info}: {Dead.kill_id(info) == target : U32}

law Dead.result_target:
  for +hit: M.Monsters.Hit
  for +others: List<&2,M.Monsters.State>
  for +target: U32
  for +same: {R.Roster.id(M.Monsters.result(hit)) == target : U32}
  Dead.KillTarget(B.Battle.kill(R.Roster.strike_result(hit,others)),target)

def Dead.result_target(hit,others,target,same):
  match hit:
    case M.Monsters.Hit{monster,killed,dealt}:
      match monster:
        case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,focus,attack,dead,respawn}:
          match killed:
            case False{}: Unit{}
            case True{}: same

law Dead.taken_target:
  for +taken: R.Roster.Take
  for +damage: U32
  for +target: U32
  for +same: R.Roster.FoundID(R.Roster.found(taken),target)
  Dead.KillTarget(B.Battle.kill(R.Roster.strike_taken(taken,damage)),target)

def Dead.taken_target(taken,damage,target,same):
  match taken:
    case R.Roster.Take{others,found}:
      match found:
        case None{}: Unit{}
        case Some{monster}: Dead.result_target(M.Monsters.hit(monster,damage,R.Roster.respawn_time(M.Monsters.kind(monster))),others,target,Equal.trans(U32,R.Roster.id(M.Monsters.result(M.Monsters.hit(monster,damage,R.Roster.respawn_time(M.Monsters.kind(monster))))),R.Roster.id(monster),target,Frame.CombatFrame.hit_id(monster,damage,R.Roster.respawn_time(M.Monsters.kind(monster))),same))

law Dead.roster_target:
  for +monsters: List<&2,M.Monsters.State>
  for +target: U32
  for +damage: U32
  Dead.KillTarget(B.Battle.kill(R.Roster.strike(monsters,target,damage)),target)

def Dead.roster_target(monsters,target,damage): Dead.taken_target(R.Roster.take(monsters,target),damage,target,R.Roster.take_id(monsters,target))

def Dead.notice_id(notice: B.Battle.Notice) -> U32:
  match notice:
    case B.Battle.Notice{kill,award,elapsed,ended,players}: Dead.kill_id(kill)

def Dead.Only(+target: U32,notices: List<&2,B.Battle.Notice>) -> Data:
  match notices:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,{Dead.notice_id(head) == target : U32},(same => Dead.Only(target,rest))>

law Dead.reward_result_target:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +kill: R.Roster.Kill
  for +result: Pay.Payout.Result
  Dead.Only(Dead.kill_id(kill),B.Battle.notices(B.Battle.finish_reward(meta,monsters,kill,result)))

def Dead.reward_result_target(meta,monsters,kill,result):
  match result:
    case Pay.Payout.Result{players,paid}:
      match paid:
        case None{}: Unit{}
        case Some{award}: Tuple{{==},Unit{}}

law Dead.reward_target:
  for +state: S.Simulation.State
  for +pid: U32
  for +kill: R.Roster.Kill
  for +plan: Pay.Payout.Plan
  for +score: U32
  Dead.Only(Dead.kill_id(kill),B.Battle.notices(B.Battle.reward(state,pid,kill,plan,score)))

def Dead.reward_target(state,pid,kill,plan,score):
  match state:
    case S.Simulation.State{meta,players,monsters}: Dead.reward_result_target(meta,monsters,kill,Pay.Payout.run(players,pid,B.Battle.bind_kind(plan,B.Battle.kind(kill)),score))

law Dead.after_target:
  for +kill: Maybe<&2,R.Roster.Kill>
  for +state: S.Simulation.State
  for +pid: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +target: U32
  for +same: Dead.KillTarget(kill,target)
  Dead.Only(target,B.Battle.notices(B.Battle.after(kill,state,pid,plan,score)))

def Dead.after_target(kill,state,pid,plan,score,target,same):
  match kill:
    case None{}: Unit{}
    case Some{info}:
      %same : Dead.Only(_,B.Battle.notices(B.Battle.reward(state,pid,info,plan,score)))
      Dead.reward_target(state,pid,info,plan,score)

law Dead.hit_target:
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +hit: R.Roster.Strike
  for +pid: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +target: U32
  for +same: Dead.KillTarget(B.Battle.kill(hit),target)
  Dead.Only(target,B.Battle.notices(B.Battle.finish_hit(meta,players,hit,pid,plan,score)))

def Dead.hit_target(meta,players,hit,pid,plan,score,target,same):
  match hit:
    case R.Roster.Strike{monsters,kill,dealt}: Dead.after_target(kill,S.Simulation.State{meta,players,monsters},pid,plan,score,target,same)

law Dead.battle_target:
  for +input: B.Battle.Input
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  Dead.Only(TP.TargetPlans.id(input),B.Battle.notices(B.Battle.strike(input,state,pid,score)))

def Dead.battle_target(input,state,pid,score):
  match input:
    case B.Battle.Input{mid,damage,plan}:
      match state:
        case S.Simulation.State{meta,players,monsters}: Dead.hit_target(meta,players,R.Roster.strike(monsters,mid,damage),pid,plan,score,mid,Dead.roster_target(monsters,mid,damage))

def Dead.Clear(+mid: U32,notices: List<&2,B.Battle.Notice>) -> Data:
  match notices:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,{U32.is_eq(mid,Dead.notice_id(head)) == False{} : Bool},(different => Dead.Clear(mid,rest))>

law Dead.only_clear:
  for +notices: List<&2,B.Battle.Notice>
  for +target: U32
  for +mid: U32
  for +only: Dead.Only(target,notices)
  for +different: {U32.is_eq(mid,target) == False{} : Bool}
  Dead.Clear(mid,notices)

def Dead.only_clear(notices,target,mid,only,different):
  match notices:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match only:
        case Tuple{same,later}: Tuple{(%Equal.sym(U32,Dead.notice_id(head),target,same) : {U32.is_eq(mid,_) == False{} : Bool}; different),Dead.only_clear(rest,target,mid,later,different)}

law Dead.branch_clear:
  for +same: Bool
  for +monster: M.Monsters.State
  for +state: S.Simulation.State
  for +mid: U32
  for +damage: U32
  for +payout: Pay.Payout.Plan
  for +pid: U32
  for +score: U32
  for +inside: Member.Targets.In<monster,S.Simulation.monsters(state)>
  for +unique: I.Identity.Monsters(S.Simulation.monsters(state))
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  for +decision: {U32.is_eq(R.Roster.id(monster),mid) == same : Bool}
  Dead.Clear(R.Roster.id(monster),B.Battle.notices(B.Battle.strike(B.Battle.Input{mid,damage,payout},state,pid,score)))

def Dead.branch_clear(same,monster,state,mid,damage,payout,pid,score,inside,unique,dead,decision):
  match same:
    case True{}:
      %N.Numeric.u32_eq_sound(R.Roster.id(monster),mid,decision) : Dead.Clear(R.Roster.id(monster),B.Battle.notices(B.Battle.strike(B.Battle.Input{_,damage,payout},state,pid,score)))
      %Equal.sym(B.Battle.Result,B.Battle.strike(B.Battle.Input{R.Roster.id(monster),damage,payout},state,pid,score),B.Battle.Result{S.Simulation.State{S.Simulation.meta(state),S.Simulation.players(state),Con{monster,R.Roster.others(R.Roster.take(S.Simulation.monsters(state),R.Roster.id(monster)))}},Nil{}},Dead.own(monster,state,damage,payout,pid,score,inside,unique,dead)) : Dead.Clear(R.Roster.id(monster),B.Battle.notices(_))
      Unit{}
    case False{}: Dead.only_clear(B.Battle.notices(B.Battle.strike(B.Battle.Input{mid,damage,payout},state,pid,score)),mid,R.Roster.id(monster),Dead.battle_target(B.Battle.Input{mid,damage,payout},state,pid,score),decision)

law Dead.step_clear:
  for +monster: M.Monsters.State
  for +input: B.Battle.Input
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +inside: Member.Targets.In<monster,S.Simulation.monsters(state)>
  for +unique: I.Identity.Monsters(S.Simulation.monsters(state))
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  Dead.Clear(R.Roster.id(monster),B.Battle.notices(B.Battle.strike(input,state,pid,score)))

def Dead.step_clear(monster,input,state,pid,score,inside,unique,dead):
  match input:
    case B.Battle.Input{mid,damage,payout}: Dead.branch_clear(U32.is_eq(R.Roster.id(monster),mid),monster,state,mid,damage,payout,pid,score,inside,unique,dead,{==})

law Dead.concat_clear:
  for +left: List<&2,B.Battle.Notice>
  for +right: List<&2,B.Battle.Notice>
  for +mid: U32
  for +first: Dead.Clear(mid,left)
  for +second: Dead.Clear(mid,right)
  Dead.Clear(mid,B.Battle.concat(left,right))

def Dead.concat_clear(left,right,mid,first,second):
  match left:
    case Nil{}: second
    case Con{head,rest}:
      match first:
        case Tuple{different,later}: Tuple{different,Dead.concat_clear(rest,right,mid,later,second)}

law Dead.run_clear:
  for +inputs: List<&2,B.Battle.Input>
  for +monster: M.Monsters.State
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +inside: Member.Targets.In<monster,S.Simulation.monsters(state)>
  for +unique: I.Identity.Monsters(S.Simulation.monsters(state))
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  Dead.Clear(R.Roster.id(monster),B.Battle.notices(B.Battle.run(inputs,state,pid,score)))

def Dead.run_clear(inputs,monster,state,pid,score,inside,unique,dead):
  match inputs:
    case Nil{}: Unit{}
    case Con{head,rest}: Dead.concat_clear(B.Battle.notices(B.Battle.strike(head,state,pid,score)),B.Battle.notices(B.Battle.run(rest,B.Battle.state(B.Battle.strike(head,state,pid,score)),pid,score)),R.Roster.id(monster),Dead.step_clear(monster,head,state,pid,score,inside,unique,dead),Dead.run_clear(rest,monster,B.Battle.state(B.Battle.strike(head,state,pid,score)),pid,score,Dead.step_member(monster,head,state,pid,score,inside,unique,dead),I.Identity.battle_strike_unique(head,state,pid,score,unique),dead))

# Each strike may have a different acting player, score and payout plan.
# No tick/respawn occurs in this interval; later batches cover that boundary.
type Dead.Command is Data:
  Dead.Command{input: B.Battle.Input,pid: U32,score: U32}

def Dead.apply(command: Dead.Command,state: S.Simulation.State) -> B.Battle.Result:
  match command:
    case Dead.Command{input,pid,score}: B.Battle.strike(input,state,pid,score)

def Dead.trace(commands: List<&2,Dead.Command>,state: S.Simulation.State) -> B.Battle.Result:
  match commands:
    case Nil{}: B.Battle.Result{state,Nil{}}
    case Con{head,rest}:
      +first = Dead.apply(head,state)
      B.Battle.before(first,Dead.trace(rest,B.Battle.state(first)))

type Dead.Safe<-monster: M.Monsters.State,-result: B.Battle.Result> is Data:
  Dead.Safe{inside: Member.Targets.In<monster,S.Simulation.monsters(B.Battle.state(result))>,unique: I.Identity.Monsters(S.Simulation.monsters(B.Battle.state(result))),clear: Dead.Clear(R.Roster.id(monster),B.Battle.notices(result))}

law Dead.step:
  for +command: Dead.Command
  for +monster: M.Monsters.State
  for +state: S.Simulation.State
  for +inside: Member.Targets.In<monster,S.Simulation.monsters(state)>
  for +unique: I.Identity.Monsters(S.Simulation.monsters(state))
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  Dead.Safe<monster,Dead.apply(command,state)>

def Dead.step(command,monster,state,inside,unique,dead):
  match command:
    case Dead.Command{input,pid,score}: Dead.Safe{Dead.step_member(monster,input,state,pid,score,inside,unique,dead),I.Identity.battle_strike_unique(input,state,pid,score,unique),Dead.step_clear(monster,input,state,pid,score,inside,unique,dead)}

law Dead.join:
  for +monster: M.Monsters.State
  for +first: B.Battle.Result
  for +second: B.Battle.Result
  for +clear: Dead.Clear(R.Roster.id(monster),B.Battle.notices(first))
  for +safe: Dead.Safe<monster,second>
  Dead.Safe<monster,B.Battle.before(first,second)>

def Dead.join(monster,first,second,clear,safe):
  match safe:
    case Dead.Safe{inside,unique,later}: Dead.Safe{inside,unique,Dead.concat_clear(B.Battle.notices(first),B.Battle.notices(second),R.Roster.id(monster),clear,later)}

law Dead.trace_safe:
  for +commands: List<&2,Dead.Command>
  for +monster: M.Monsters.State
  for +state: S.Simulation.State
  for +inside: Member.Targets.In<monster,S.Simulation.monsters(state)>
  for +unique: I.Identity.Monsters(S.Simulation.monsters(state))
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  Dead.Safe<monster,Dead.trace(commands,state)>

def Dead.trace_safe(commands,monster,state,inside,unique,dead):
  match commands:
    case Nil{}: Dead.Safe{inside,unique,Unit{}}
    case Con{head,rest}:
      match head:
        case Dead.Command{input,pid,score}:
          Dead.join(monster,B.Battle.strike(input,state,pid,score),Dead.trace(rest,B.Battle.state(B.Battle.strike(input,state,pid,score))),Dead.step_clear(monster,input,state,pid,score,inside,unique,dead),Dead.trace_safe(rest,monster,B.Battle.state(B.Battle.strike(input,state,pid,score)),Dead.step_member(monster,input,state,pid,score,inside,unique,dead),I.Identity.battle_strike_unique(input,state,pid,score,unique),dead))

def Dead.count_gate(same: Bool,count: Nat) -> Nat:
  match same:
    case True{}: Succ{count}
    case False{}: count

def Dead.count(+mid: U32,notices: List<&2,B.Battle.Notice>) -> Nat:
  match notices:
    case Nil{}: 0n
    case Con{head,rest}: Dead.count_gate(U32.is_eq(mid,Dead.notice_id(head)),Dead.count(mid,rest))

law Dead.clear_zero:
  for +notices: List<&2,B.Battle.Notice>
  for +mid: U32
  for +clear: Dead.Clear(mid,notices)
  {Dead.count(mid,notices) == 0n : Nat}

def Dead.clear_zero(notices,mid,clear):
  match notices:
    case Nil{}: {==}
    case Con{head,rest}:
      match clear:
        case Tuple{different,later}:
          %Equal.sym(Bool,U32.is_eq(mid,Dead.notice_id(head)),False{},different) : {Dead.count_gate(_,Dead.count(mid,rest)) == 0n : Nat}
          Dead.clear_zero(rest,mid,later)

law Dead.safe_zero:
  for +monster: M.Monsters.State
  for +result: B.Battle.Result
  for +safe: Dead.Safe<monster,result>
  {Dead.count(R.Roster.id(monster),B.Battle.notices(result)) == 0n : Nat}

def Dead.safe_zero(monster,result,safe):
  match safe:
    case Dead.Safe{inside,unique,clear}: Dead.clear_zero(B.Battle.notices(result),R.Roster.id(monster),clear)

law Dead.final_lookup:
  for +monster: M.Monsters.State
  for +result: B.Battle.Result
  for +safe: Dead.Safe<monster,result>
  {R.Roster.found(R.Roster.take(S.Simulation.monsters(B.Battle.state(result)),R.Roster.id(monster))) == Some{monster} : Maybe<&2,M.Monsters.State>}

def Dead.final_lookup(monster,result,safe):
  match safe:
    case Dead.Safe{inside,unique,clear}: Member.Targets.lookup_member(monster,S.Simulation.monsters(B.Battle.state(result)),inside,unique)
