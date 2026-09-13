# One real lethal reward followed by arbitrary later strike commands.
import Base
import ./dead_rewards.bend as Dead
import ./combat_lethal.bend as Lethal
import ./monsters.bend as M
import ./vitals.bend as V
import ./roster.bend as R
import ./combat_targets.bend as Targets
import ./combat_frame.bend as Frame
import ./identity.bend as I
import ./numeric.bend as N
import ./battle.bend as B
import ./payouts.bend as Pay
import ./simulation.bend as S
import ./players.bend as P

law Once.only_count:
  for +notices: List<&2,B.Battle.Notice>
  for +mid: U32
  for +only: Dead.Dead.Only(mid,notices)
  {Dead.Dead.count(mid,notices) == B.Battle.notice_count(notices) : Nat}

def Once.only_count(notices,mid,only):
  match notices:
    case Nil{}: {==}
    case Con{head,rest}:
      match only:
        case Tuple{same,later}:
          %Equal.sym(U32,Dead.Dead.notice_id(head),mid,same) : {Dead.Dead.count_gate(U32.is_eq(mid,_),Dead.Dead.count(mid,rest)) == Succ{B.Battle.notice_count(rest)} : Nat}
          %Equal.sym(Bool,U32.is_eq(mid,mid),True{},N.Numeric.u32_eq_refl(mid)) : {Dead.Dead.count_gate(_,Dead.Dead.count(mid,rest)) == Succ{B.Battle.notice_count(rest)} : Nat}
          Equal.cong(Nat,Nat,(count => Succ{count}),Dead.Dead.count(mid,rest),B.Battle.notice_count(rest),Once.only_count(rest,mid,later))

law Once.gate_add:
  for +same: Bool
  for +left: Nat
  for +right: Nat
  {Dead.Dead.count_gate(same,Nat.add(left,right)) == Nat.add(Dead.Dead.count_gate(same,left),right) : Nat}

def Once.gate_add(same,left,right):
  match same:
    case True{}: {==}
    case False{}: {==}

law Once.concat_count:
  for +left: List<&2,B.Battle.Notice>
  for +right: List<&2,B.Battle.Notice>
  for +mid: U32
  {Dead.Dead.count(mid,B.Battle.concat(left,right)) == Nat.add(Dead.Dead.count(mid,left),Dead.Dead.count(mid,right)) : Nat}

def Once.concat_count(left,right,mid):
  match left:
    case Nil{}: {==}
    case Con{head,rest}:
      %Equal.sym(Nat,Dead.Dead.count(mid,B.Battle.concat(rest,right)),Nat.add(Dead.Dead.count(mid,rest),Dead.Dead.count(mid,right)),Once.concat_count(rest,right,mid)) : {Dead.Dead.count_gate(U32.is_eq(mid,Dead.Dead.notice_id(head)),_) == Nat.add(Dead.Dead.count_gate(U32.is_eq(mid,Dead.Dead.notice_id(head)),Dead.Dead.count(mid,rest)),Dead.Dead.count(mid,right)) : Nat}
      Once.gate_add(U32.is_eq(mid,Dead.Dead.notice_id(head)),Dead.Dead.count(mid,rest),Dead.Dead.count(mid,right))

def Once.after(+monster: M.Monsters.State,damage: U32) -> M.Monsters.State:
  M.Monsters.result(M.Monsters.hit(monster,damage,R.Roster.respawn_time(M.Monsters.kind(monster))))

law Once.after_id:
  for +monster: M.Monsters.State
  for +damage: U32
  {R.Roster.id(Once.after(monster,damage)) == R.Roster.id(monster) : U32}

def Once.after_id(monster,damage): Frame.CombatFrame.hit_id(monster,damage,R.Roster.respawn_time(M.Monsters.kind(monster)))

law Once.after_dead:
  for +monster: M.Monsters.State
  for +damage: U32
  for +point: Targets.Targets.Point
  for +eligible: {Targets.Targets.eligible(monster,point) == True{} : Bool}
  for +enough: Lethal.Lethal.Enough(monster,damage)
  {V.Vitals.dead(M.Monsters.vitals(Once.after(monster,damage))) == 1 : U32}

def Once.after_dead(monster,damage,point,eligible,enough):
  M.Monsters.hit_killed_dead(monster,damage,R.Roster.respawn_time(M.Monsters.kind(monster)),M.Monsters.lethal_hit_reports_kill(monster,damage,R.Roster.respawn_time(M.Monsters.kind(monster)),(%Lethal.Lethal.dead_field(monster) : {_ == 0 : U32}; Targets.Targets.eligible_alive(monster,point,eligible)),enough))

law Once.taken_member:
  for +taken: R.Roster.Take
  for +monster: M.Monsters.State
  for +damage: U32
  for +found: {R.Roster.found(taken) == Some{monster} : Maybe<&2,M.Monsters.State>}
  Targets.Targets.In<Once.after(monster,damage),R.Roster.struck(R.Roster.strike_taken(taken,damage))>

def Once.taken_member(taken,monster,damage,found):
  match taken:
    case R.Roster.Take{others,selected}:
      %Equal.sym(Maybe<&2,M.Monsters.State>,selected,Some{monster},found) : Targets.Targets.In<Once.after(monster,damage),R.Roster.struck(R.Roster.strike_taken(R.Roster.Take{others,_},damage))>
      %Equal.sym(List<&2,M.Monsters.State>,R.Roster.struck(R.Roster.strike_result(M.Monsters.hit(monster,damage,R.Roster.respawn_time(M.Monsters.kind(monster))),others)),Con{Once.after(monster,damage),others},Frame.CombatFrame.strike_result_list(M.Monsters.hit(monster,damage,R.Roster.respawn_time(M.Monsters.kind(monster))),others)) : Targets.Targets.In<Once.after(monster,damage),_>
      Targets.Targets.Here{others,{==}}

def Once.first(+monster: M.Monsters.State,damage: U32,payout: Pay.Payout.Plan,state: S.Simulation.State,pid: U32,score: U32) -> B.Battle.Result:
  B.Battle.strike(B.Battle.Input{R.Roster.id(monster),damage,payout},state,pid,score)

law Once.first_member:
  for +monster: M.Monsters.State
  for +damage: U32
  for +payout: Pay.Payout.Plan
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +inside: Targets.Targets.In<monster,S.Simulation.monsters(state)>
  for +unique: I.Identity.Monsters(S.Simulation.monsters(state))
  Targets.Targets.In<Once.after(monster,damage),S.Simulation.monsters(B.Battle.state(Once.first(monster,damage,payout,state,pid,score)))>

def Once.first_member(monster,damage,payout,state,pid,score,inside,unique):
  %Equal.sym(List<&2,M.Monsters.State>,S.Simulation.monsters(B.Battle.state(Once.first(monster,damage,payout,state,pid,score))),R.Roster.struck(R.Roster.strike(S.Simulation.monsters(state),R.Roster.id(monster),damage)),B.Battle.strike_monsters(R.Roster.id(monster),damage,payout,state,pid,score)) : Targets.Targets.In<Once.after(monster,damage),_>
  Once.taken_member(R.Roster.take(S.Simulation.monsters(state),R.Roster.id(monster)),monster,damage,Targets.Targets.lookup_member(monster,S.Simulation.monsters(state),inside,unique))

law Once.first_count:
  for +monster: M.Monsters.State
  for +damage: U32
  for +payout: Pay.Payout.Plan
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +point: Targets.Targets.Point
  for +source: Targets.Targets.Source<S.Simulation.monsters(state),point,monster>
  for +unique: I.Identity.Monsters(S.Simulation.monsters(state))
  for +enough: Lethal.Lethal.Enough(monster,damage)
  for +present: {P.Players.has_id(S.Simulation.players(state),pid) == True{} : Bool}
  {Dead.Dead.count(R.Roster.id(monster),B.Battle.notices(Once.first(monster,damage,payout,state,pid,score))) == 1n : Nat}

def Once.first_count(monster,damage,payout,state,pid,score,point,source,unique,enough,present):
  Equal.trans(Nat,Dead.Dead.count(R.Roster.id(monster),B.Battle.notices(Once.first(monster,damage,payout,state,pid,score))),B.Battle.notice_count(B.Battle.notices(Once.first(monster,damage,payout,state,pid,score))),1n,Once.only_count(B.Battle.notices(Once.first(monster,damage,payout,state,pid,score)),R.Roster.id(monster),Dead.Dead.battle_target(B.Battle.Input{R.Roster.id(monster),damage,payout},state,pid,score)),Lethal.Lethal.reward(state,point,monster,damage,payout,pid,score,source,unique,enough,present))

law Once.tail_safe:
  for +commands: List<&2,Dead.Dead.Command>
  for +monster: M.Monsters.State
  for +damage: U32
  for +payout: Pay.Payout.Plan
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +point: Targets.Targets.Point
  for +source: Targets.Targets.Source<S.Simulation.monsters(state),point,monster>
  for +unique: I.Identity.Monsters(S.Simulation.monsters(state))
  for +enough: Lethal.Lethal.Enough(monster,damage)
  Dead.Dead.Safe<Once.after(monster,damage),Dead.Dead.trace(commands,B.Battle.state(Once.first(monster,damage,payout,state,pid,score)))>

def Once.tail_safe(commands,monster,damage,payout,state,pid,score,point,source,unique,enough):
  match source:
    case Targets.Targets.Source{inside,eligible}:
      Dead.Dead.trace_safe(commands,Once.after(monster,damage),B.Battle.state(Once.first(monster,damage,payout,state,pid,score)),Once.first_member(monster,damage,payout,state,pid,score,inside,unique),I.Identity.battle_strike_unique(B.Battle.Input{R.Roster.id(monster),damage,payout},state,pid,score,unique),Once.after_dead(monster,damage,point,eligible,enough))

def Once.run(commands: List<&2,Dead.Dead.Command>,monster: M.Monsters.State,damage: U32,payout: Pay.Payout.Plan,state: S.Simulation.State,pid: U32,score: U32) -> B.Battle.Result:
  +first = Once.first(monster,damage,payout,state,pid,score)
  B.Battle.before(first,Dead.Dead.trace(commands,B.Battle.state(first)))

type Once.Certificate<-monster: M.Monsters.State,-damage: U32,-result: B.Battle.Result> is Data:
  Once.Certificate{inside: Targets.Targets.In<Once.after(monster,damage),S.Simulation.monsters(B.Battle.state(result))>,unique: I.Identity.Monsters(S.Simulation.monsters(B.Battle.state(result))),dead: {V.Vitals.dead(M.Monsters.vitals(Once.after(monster,damage))) == 1 : U32},count: {Dead.Dead.count(R.Roster.id(monster),B.Battle.notices(result)) == 1n : Nat}}

law Once.assemble:
  for +monster: M.Monsters.State
  for +damage: U32
  for +first: B.Battle.Result
  for +second: B.Battle.Result
  for +one: {Dead.Dead.count(R.Roster.id(monster),B.Battle.notices(first)) == 1n : Nat}
  for +dead: {V.Vitals.dead(M.Monsters.vitals(Once.after(monster,damage))) == 1 : U32}
  for +safe: Dead.Dead.Safe<Once.after(monster,damage),second>
  Once.Certificate<monster,damage,B.Battle.before(first,second)>

def Once.assemble(monster,damage,first,second,one,dead,safe):
  match safe:
    case Dead.Dead.Safe{inside,unique,clear}:
      +zero = {(%Once.after_id(monster,damage) : {Dead.Dead.count(_,B.Battle.notices(second)) == 0n : Nat}; Dead.Dead.clear_zero(B.Battle.notices(second),R.Roster.id(Once.after(monster,damage)),clear)) : {Dead.Dead.count(R.Roster.id(monster),B.Battle.notices(second)) == 0n : Nat}}
      Once.Certificate{inside,unique,dead,(%Equal.sym(Nat,Dead.Dead.count(R.Roster.id(monster),B.Battle.concat(B.Battle.notices(first),B.Battle.notices(second))),Nat.add(Dead.Dead.count(R.Roster.id(monster),B.Battle.notices(first)),Dead.Dead.count(R.Roster.id(monster),B.Battle.notices(second))),Once.concat_count(B.Battle.notices(first),B.Battle.notices(second),R.Roster.id(monster))) : {_ == 1n : Nat}; (%Equal.sym(Nat,Dead.Dead.count(R.Roster.id(monster),B.Battle.notices(first)),1n,one) : {Nat.add(_,Dead.Dead.count(R.Roster.id(monster),B.Battle.notices(second))) == 1n : Nat}; (%Equal.sym(Nat,Dead.Dead.count(R.Roster.id(monster),B.Battle.notices(second)),0n,zero) : {Succ{_} == 1n : Nat}; {==}))) }

law Once.prove:
  for +commands: List<&2,Dead.Dead.Command>
  for +monster: M.Monsters.State
  for +damage: U32
  for +payout: Pay.Payout.Plan
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +point: Targets.Targets.Point
  for +source: Targets.Targets.Source<S.Simulation.monsters(state),point,monster>
  for +unique: I.Identity.Monsters(S.Simulation.monsters(state))
  for +enough: Lethal.Lethal.Enough(monster,damage)
  for +present: {P.Players.has_id(S.Simulation.players(state),pid) == True{} : Bool}
  Once.Certificate<monster,damage,Once.run(commands,monster,damage,payout,state,pid,score)>

def Once.prove(commands,monster,damage,payout,state,pid,score,point,source,unique,enough,present):
  match source:
    case Targets.Targets.Source{inside,eligible}:
      Once.assemble(monster,damage,Once.first(monster,damage,payout,state,pid,score),Dead.Dead.trace(commands,B.Battle.state(Once.first(monster,damage,payout,state,pid,score))),Once.first_count(monster,damage,payout,state,pid,score,point,Targets.Targets.Source{inside,eligible},unique,enough,present),Once.after_dead(monster,damage,point,eligible,enough),Once.tail_safe(commands,monster,damage,payout,state,pid,score,point,Targets.Targets.Source{inside,eligible},unique,enough))

law Once.final_lookup:
  for +monster: M.Monsters.State
  for +damage: U32
  for +result: B.Battle.Result
  for +certificate: Once.Certificate<monster,damage,result>
  {R.Roster.found(R.Roster.take(S.Simulation.monsters(B.Battle.state(result)),R.Roster.id(monster))) == Some{Once.after(monster,damage)} : Maybe<&2,M.Monsters.State>}

def Once.final_lookup(monster,damage,result,certificate):
  match certificate:
    case Once.Certificate{inside,unique,dead,count}:
      %Once.after_id(monster,damage) : {R.Roster.found(R.Roster.take(S.Simulation.monsters(B.Battle.state(result)),_)) == Some{Once.after(monster,damage)} : Maybe<&2,M.Monsters.State>}
      Targets.Targets.lookup_member(Once.after(monster,damage),S.Simulation.monsters(B.Battle.state(result)),inside,unique)

law Once.count:
  for +monster: M.Monsters.State
  for +damage: U32
  for +result: B.Battle.Result
  for +certificate: Once.Certificate<monster,damage,result>
  {Dead.Dead.count(R.Roster.id(monster),B.Battle.notices(result)) == 1n : Nat}

def Once.count(monster,damage,result,certificate):
  match certificate:
    case Once.Certificate{inside,unique,dead,count}: count
