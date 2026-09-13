# Exact full-record conservation for monsters other than the struck MID.
import Base
import ./monsters.bend as M
import ./roster.bend as R
import ./numeric.bend as N
import ./zones.bend as Z
import ./identity.bend as I
import ./combat_targets.bend as T
import ./target_plans.bend as TP
import ./battle.bend as B
import ./simulation.bend as S
import ./payouts.bend as P
import ./spin_plans.bend as Spin
import ./live_combat.bend as L

def CombatFrame.gate(matches: Bool,head: M.Monsters.State,tail: List<&2,M.Monsters.State>) -> List<&2,M.Monsters.State>:
  match matches:
    case True{}: tail
    case False{}: Con{head,tail}

# Dropping the struck ID lets us compare every other field and relative order.
def CombatFrame.erase(monsters: List<&2,M.Monsters.State>,+mid: U32) -> List<&2,M.Monsters.State>:
  match monsters:
    case Nil{}: Nil{}
    case Con{head,rest}:
      +head = head
      CombatFrame.gate(U32.is_eq(R.Roster.id(head),mid),head,CombatFrame.erase(rest,mid))

law CombatFrame.scan_erase:
  for +tail: List<&2,M.Monsters.State>
  for +head: M.Monsters.State
  for +matches: Bool
  for +mid: U32
  for +decision: {U32.is_eq(R.Roster.id(head),mid) == matches : Bool}
  {CombatFrame.erase(R.Roster.others(R.Roster.scan(tail,head,matches,mid)),mid) == CombatFrame.erase(Con{head,tail},mid) : List<&2,M.Monsters.State>}

def CombatFrame.scan_erase(tail,head,matches,mid,decision):
  match tail:
    case Nil{}:
      match matches:
        case True{}:
          %Equal.sym(Bool,U32.is_eq(R.Roster.id(head),mid),True{},decision) : {Nil{} == CombatFrame.gate(_,head,Nil{}) : List<&2,M.Monsters.State>}
          {==}
        case False{}: {==}
    case Con{next,rest}:
      match matches:
        case True{}:
          %Equal.sym(Bool,U32.is_eq(R.Roster.id(head),mid),True{},decision) : {CombatFrame.erase(Con{next,rest},mid) == CombatFrame.gate(_,head,CombatFrame.erase(Con{next,rest},mid)) : List<&2,M.Monsters.State>}
          {==}
        case False{}:
          %Equal.sym(List<&2,M.Monsters.State>,R.Roster.others(R.Roster.prepend(head,R.Roster.scan(rest,next,U32.is_eq(R.Roster.id(next),mid),mid))),Con{head,R.Roster.others(R.Roster.scan(rest,next,U32.is_eq(R.Roster.id(next),mid),mid))},R.Roster.prepend_others(head,R.Roster.scan(rest,next,U32.is_eq(R.Roster.id(next),mid),mid))) : {CombatFrame.erase(_,mid) == CombatFrame.erase(Con{head,Con{next,rest}},mid) : List<&2,M.Monsters.State>}
          %Equal.sym(Bool,U32.is_eq(R.Roster.id(head),mid),False{},decision) : {CombatFrame.gate(_,head,CombatFrame.erase(R.Roster.others(R.Roster.scan(rest,next,U32.is_eq(R.Roster.id(next),mid),mid)),mid)) == CombatFrame.gate(_,head,CombatFrame.erase(Con{next,rest},mid)) : List<&2,M.Monsters.State>}
          Equal.cong(List<&2,M.Monsters.State>,List<&2,M.Monsters.State>,(tail => Con{head,tail}),CombatFrame.erase(R.Roster.others(R.Roster.scan(rest,next,U32.is_eq(R.Roster.id(next),mid),mid)),mid),CombatFrame.erase(Con{next,rest},mid),CombatFrame.scan_erase(rest,next,U32.is_eq(R.Roster.id(next),mid),mid,{==}))

law CombatFrame.take_erase:
  for +monsters: List<&2,M.Monsters.State>
  for +mid: U32
  {CombatFrame.erase(R.Roster.others(R.Roster.take(monsters,mid)),mid) == CombatFrame.erase(monsters,mid) : List<&2,M.Monsters.State>}

def CombatFrame.take_erase(monsters,mid):
  match monsters:
    case Nil{}: {==}
    case Con{head,rest}: CombatFrame.scan_erase(rest,head,U32.is_eq(R.Roster.id(head),mid),mid,{==})

law CombatFrame.hit_id:
  for +monster: M.Monsters.State
  for +damage: U32
  for +timer: U32
  {R.Roster.id(M.Monsters.result(M.Monsters.hit(monster,damage,timer))) == R.Roster.id(monster) : U32}

def CombatFrame.hit_id(monster,damage,timer):
  %T.Targets.key_id(M.Monsters.result(M.Monsters.hit(monster,damage,timer))) : {_ == R.Roster.id(monster) : U32}
  %T.Targets.key_id(monster) : {I.Identity.mid(Z.Zones.key(M.Monsters.result(M.Monsters.hit(monster,damage,timer)))) == _ : U32}
  Equal.cong(Z.Zones.Key,U32,(key => I.Identity.mid(key)),Z.Zones.key(M.Monsters.result(M.Monsters.hit(monster,damage,timer))),Z.Zones.key(monster),Z.Zones.hit_key(monster,damage,timer))

law CombatFrame.strike_result_list:
  for +hit: M.Monsters.Hit
  for +others: List<&2,M.Monsters.State>
  {R.Roster.struck(R.Roster.strike_result(hit,others)) == Con{M.Monsters.result(hit),others} : List<&2,M.Monsters.State>}

def CombatFrame.strike_result_list(hit,others):
  match hit:
    case M.Monsters.Hit{monster,killed,dealt}:
      match monster:
        case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}:
          match killed:
            case False{}: {==}
            case True{}: {==}

law CombatFrame.erase_same:
  for +head: M.Monsters.State
  for +tail: List<&2,M.Monsters.State>
  for +mid: U32
  for +same: {R.Roster.id(head) == mid : U32}
  {CombatFrame.erase(Con{head,tail},mid) == CombatFrame.erase(tail,mid) : List<&2,M.Monsters.State>}

def CombatFrame.erase_same(head,tail,mid,same):
  %Equal.sym(Bool,U32.is_eq(R.Roster.id(head),mid),True{},(%Equal.sym(U32,R.Roster.id(head),mid,same) : {U32.is_eq(_,mid) == True{} : Bool}; N.Numeric.u32_eq_refl(mid))) : {CombatFrame.gate(_,head,CombatFrame.erase(tail,mid)) == CombatFrame.erase(tail,mid) : List<&2,M.Monsters.State>}
  {==}

law CombatFrame.strike_taken_erase:
  for +taken: R.Roster.Take
  for +mid: U32
  for +damage: U32
  for +found: R.Roster.FoundID(R.Roster.found(taken),mid)
  {CombatFrame.erase(R.Roster.struck(R.Roster.strike_taken(taken,damage)),mid) == CombatFrame.erase(R.Roster.others(taken),mid) : List<&2,M.Monsters.State>}

def CombatFrame.strike_taken_erase(taken,mid,damage,found):
  match taken:
    case R.Roster.Take{others,selected}:
      match selected:
        case None{}: {==}
        case Some{monster}:
          %Equal.sym(List<&2,M.Monsters.State>,R.Roster.struck(R.Roster.strike_result(M.Monsters.hit(monster,damage,R.Roster.respawn_time(M.Monsters.kind(monster))),others)),Con{M.Monsters.result(M.Monsters.hit(monster,damage,R.Roster.respawn_time(M.Monsters.kind(monster)))),others},CombatFrame.strike_result_list(M.Monsters.hit(monster,damage,R.Roster.respawn_time(M.Monsters.kind(monster))),others)) : {CombatFrame.erase(_,mid) == CombatFrame.erase(others,mid) : List<&2,M.Monsters.State>}
          CombatFrame.erase_same(M.Monsters.result(M.Monsters.hit(monster,damage,R.Roster.respawn_time(M.Monsters.kind(monster)))),others,mid,Equal.trans(U32,R.Roster.id(M.Monsters.result(M.Monsters.hit(monster,damage,R.Roster.respawn_time(M.Monsters.kind(monster))))),R.Roster.id(monster),mid,CombatFrame.hit_id(monster,damage,R.Roster.respawn_time(M.Monsters.kind(monster))),found))

law CombatFrame.strike_erase:
  for +monsters: List<&2,M.Monsters.State>
  for +mid: U32
  for +damage: U32
  {CombatFrame.erase(R.Roster.struck(R.Roster.strike(monsters,mid,damage)),mid) == CombatFrame.erase(monsters,mid) : List<&2,M.Monsters.State>}

def CombatFrame.strike_erase(monsters,mid,damage):
  Equal.trans(List<&2,M.Monsters.State>,CombatFrame.erase(R.Roster.struck(R.Roster.strike(monsters,mid,damage)),mid),CombatFrame.erase(R.Roster.others(R.Roster.take(monsters,mid)),mid),CombatFrame.erase(monsters,mid),CombatFrame.strike_taken_erase(R.Roster.take(monsters,mid),mid,damage,R.Roster.take_id(monsters,mid)),CombatFrame.take_erase(monsters,mid))

law CombatFrame.battle_erase:
  for +mid: U32
  for +damage: U32
  for +plan: P.Payout.Plan
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  {CombatFrame.erase(S.Simulation.monsters(B.Battle.state(B.Battle.strike(B.Battle.Input{mid,damage,plan},state,pid,score))),mid) == CombatFrame.erase(S.Simulation.monsters(state),mid) : List<&2,M.Monsters.State>}

def CombatFrame.battle_erase(mid,damage,plan,state,pid,score):
  %Equal.sym(List<&2,M.Monsters.State>,S.Simulation.monsters(B.Battle.state(B.Battle.strike(B.Battle.Input{mid,damage,plan},state,pid,score))),R.Roster.struck(R.Roster.strike(S.Simulation.monsters(state),mid,damage)),B.Battle.strike_monsters(mid,damage,plan,state,pid,score)) : {CombatFrame.erase(_,mid) == CombatFrame.erase(S.Simulation.monsters(state),mid) : List<&2,M.Monsters.State>}
  CombatFrame.strike_erase(S.Simulation.monsters(state),mid,damage)

def CombatFrame.Members(+original: List<&2,M.Monsters.State>,selected: List<&2,M.Monsters.State>) -> Data:
  match selected:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,T.Targets.In<head,original>,(inside => CombatFrame.Members(original,rest))>

law CombatFrame.weaken_members:
  for +selected: List<&2,M.Monsters.State>
  for +head: M.Monsters.State
  for +original: List<&2,M.Monsters.State>
  for +members: CombatFrame.Members(original,selected)
  CombatFrame.Members(Con{head,original},selected)

def CombatFrame.weaken_members(selected,head,original,members):
  match selected:
    case Nil{}: Unit{}
    case Con{monster,rest}:
      match members:
        case Tuple{inside,later}: Tuple{T.Targets.There{head,original,{==},inside},CombatFrame.weaken_members(rest,head,original,later)}

law CombatFrame.gate_members:
  for +matches: Bool
  for +head: M.Monsters.State
  for +tail: List<&2,M.Monsters.State>
  for +selected: List<&2,M.Monsters.State>
  for +members: CombatFrame.Members(Con{head,tail},selected)
  CombatFrame.Members(Con{head,tail},CombatFrame.gate(matches,head,selected))

def CombatFrame.gate_members(matches,head,tail,selected,members):
  match matches:
    case True{}: members
    case False{}: Tuple{T.Targets.Here{tail,{==}},members}

law CombatFrame.erase_members:
  for +monsters: List<&2,M.Monsters.State>
  for +mid: U32
  CombatFrame.Members(monsters,CombatFrame.erase(monsters,mid))

def CombatFrame.erase_members(monsters,mid):
  match monsters:
    case Nil{}: Unit{}
    case Con{head,rest}: CombatFrame.gate_members(U32.is_eq(R.Roster.id(head),mid),head,rest,CombatFrame.erase(rest,mid),CombatFrame.weaken_members(CombatFrame.erase(rest,mid),head,rest,CombatFrame.erase_members(rest,mid)))

def CombatFrame.members_head(-head: M.Monsters.State,-tail: List<&2,M.Monsters.State>,-original: List<&2,M.Monsters.State>,members: CombatFrame.Members(original,Con{head,tail})) -> T.Targets.In<head,original>:
  match members:
    case Tuple{inside,later}: inside

def CombatFrame.members_tail(-head: M.Monsters.State,-tail: List<&2,M.Monsters.State>,-original: List<&2,M.Monsters.State>,members: CombatFrame.Members(original,Con{head,tail})) -> CombatFrame.Members(original,tail):
  match members:
    case Tuple{inside,later}: later

law CombatFrame.in_members:
  for +monster: M.Monsters.State
  for -selected: List<&2,M.Monsters.State>
  for +original: List<&2,M.Monsters.State>
  for +inside: T.Targets.In<monster,selected>
  for +members: CombatFrame.Members(original,selected)
  T.Targets.In<monster,original>

def CombatFrame.in_members(monster,selected,original,inside,members):
  match inside:
    case T.Targets.Here{rest,shape}: CombatFrame.members_head(monster,rest,original,(%shape : CombatFrame.Members(original,_); members))
    case T.Targets.There{head,rest,shape,earlier}: CombatFrame.in_members(monster,rest,original,earlier,CombatFrame.members_tail(head,rest,original,(%shape : CombatFrame.Members(original,_); members)))

law CombatFrame.gate_contains:
  for +matches: Bool
  for +head: M.Monsters.State
  for +tail: List<&2,M.Monsters.State>
  for +monster: M.Monsters.State
  for +inside: T.Targets.In<monster,tail>
  T.Targets.In<monster,CombatFrame.gate(matches,head,tail)>

def CombatFrame.gate_contains(matches,head,tail,monster,inside):
  match matches:
    case True{}: inside
    case False{}: T.Targets.There{head,tail,{==},inside}

law CombatFrame.erase_contains:
  for +monster: M.Monsters.State
  for -monsters: List<&2,M.Monsters.State>
  for +mid: U32
  for +inside: T.Targets.In<monster,monsters>
  for +different: {U32.is_eq(R.Roster.id(monster),mid) == False{} : Bool}
  T.Targets.In<monster,CombatFrame.erase(monsters,mid)>

def CombatFrame.erase_contains(monster,monsters,mid,inside,different):
  match inside:
    case T.Targets.Here{rest,shape}:
      %Equal.sym(List<&2,M.Monsters.State>,monsters,Con{monster,rest},shape) : T.Targets.In<monster,CombatFrame.erase(_,mid)>
      %Equal.sym(Bool,U32.is_eq(R.Roster.id(monster),mid),False{},different) : T.Targets.In<monster,CombatFrame.gate(_,monster,CombatFrame.erase(rest,mid))>
      T.Targets.Here{CombatFrame.erase(rest,mid),{==}}
    case T.Targets.There{head,rest,shape,earlier}:
      %Equal.sym(List<&2,M.Monsters.State>,monsters,Con{head,rest},shape) : T.Targets.In<monster,CombatFrame.erase(_,mid)>
      CombatFrame.gate_contains(U32.is_eq(R.Roster.id(head),mid),head,CombatFrame.erase(rest,mid),monster,CombatFrame.erase_contains(monster,rest,mid,earlier,different))

law CombatFrame.preserve_source:
  for +monster: M.Monsters.State
  for +before: List<&2,M.Monsters.State>
  for +after: List<&2,M.Monsters.State>
  for +mid: U32
  for +point: T.Targets.Point
  for +source: T.Targets.Source<before,point,monster>
  for +different: {U32.is_eq(R.Roster.id(monster),mid) == False{} : Bool}
  for +frame: {CombatFrame.erase(after,mid) == CombatFrame.erase(before,mid) : List<&2,M.Monsters.State>}
  T.Targets.Source<after,point,monster>

def CombatFrame.preserve_source(monster,before,after,mid,point,source,different,frame):
  match source:
    case T.Targets.Source{inside,eligible}:
      T.Targets.Source{CombatFrame.in_members(monster,CombatFrame.erase(after,mid),after,(%Equal.sym(List<&2,M.Monsters.State>,CombatFrame.erase(after,mid),CombatFrame.erase(before,mid),frame) : T.Targets.In<monster,_>; CombatFrame.erase_contains(monster,before,mid,inside,different)),CombatFrame.erase_members(after,mid)),eligible}

law CombatFrame.battle_source:
  for +monster: M.Monsters.State
  for +input: B.Battle.Input
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +point: T.Targets.Point
  for +source: T.Targets.Source<S.Simulation.monsters(state),point,monster>
  for +different: {U32.is_eq(R.Roster.id(monster),TP.TargetPlans.id(input)) == False{} : Bool}
  T.Targets.Source<S.Simulation.monsters(B.Battle.state(B.Battle.strike(input,state,pid,score))),point,monster>

def CombatFrame.battle_source(monster,input,state,pid,score,point,source,different):
  match input:
    case B.Battle.Input{mid,damage,plan}: CombatFrame.preserve_source(monster,S.Simulation.monsters(state),S.Simulation.monsters(B.Battle.state(B.Battle.strike(B.Battle.Input{mid,damage,plan},state,pid,score))),mid,point,source,different,CombatFrame.battle_erase(mid,damage,plan,state,pid,score))

def CombatFrame.Different(+monster: M.Monsters.State,inputs: List<&2,B.Battle.Input>) -> Data:
  match inputs:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,{U32.is_eq(R.Roster.id(monster),TP.TargetPlans.id(head)) == False{} : Bool},(different => CombatFrame.Different(monster,rest))>

law CombatFrame.run_source:
  for +inputs: List<&2,B.Battle.Input>
  for +monster: M.Monsters.State
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +point: T.Targets.Point
  for +source: T.Targets.Source<S.Simulation.monsters(state),point,monster>
  for +different: CombatFrame.Different(monster,inputs)
  T.Targets.Source<S.Simulation.monsters(B.Battle.state(B.Battle.run(inputs,state,pid,score))),point,monster>

def CombatFrame.run_source(inputs,monster,state,pid,score,point,source,different):
  match inputs:
    case Nil{}: source
    case Con{head,rest}:
      match different:
        case Tuple{excluded,later}: CombatFrame.run_source(rest,monster,B.Battle.state(B.Battle.strike(head,state,pid,score)),pid,score,point,CombatFrame.battle_source(monster,head,state,pid,score,point,source,excluded),later)

law CombatFrame.source_lookup:
  for +monster: M.Monsters.State
  for +monsters: List<&2,M.Monsters.State>
  for +point: T.Targets.Point
  for +source: T.Targets.Source<monsters,point,monster>
  for +unique: I.Identity.Monsters(monsters)
  {R.Roster.found(R.Roster.take(monsters,R.Roster.id(monster))) == Some{monster} : Maybe<&2,M.Monsters.State>}

def CombatFrame.source_lookup(monster,monsters,point,source,unique):
  match source:
    case T.Targets.Source{inside,eligible}: T.Targets.lookup_member(monster,monsters,inside,unique)

law CombatFrame.run_lookup:
  for +inputs: List<&2,B.Battle.Input>
  for +monster: M.Monsters.State
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +point: T.Targets.Point
  for +source: T.Targets.Source<S.Simulation.monsters(state),point,monster>
  for +different: CombatFrame.Different(monster,inputs)
  for +unique: I.Identity.Monsters(S.Simulation.monsters(state))
  {R.Roster.found(R.Roster.take(S.Simulation.monsters(B.Battle.state(B.Battle.run(inputs,state,pid,score))),R.Roster.id(monster))) == Some{monster} : Maybe<&2,M.Monsters.State>}

def CombatFrame.run_lookup(inputs,monster,state,pid,score,point,source,different,unique): CombatFrame.source_lookup(monster,S.Simulation.monsters(B.Battle.state(B.Battle.run(inputs,state,pid,score))),point,CombatFrame.run_source(inputs,monster,state,pid,score,point,source,different),I.Identity.battle_run_unique(inputs,state,pid,score,unique))

law CombatFrame.survivor_sources:
  for +selected: List<&2,M.Monsters.State>
  for +input: B.Battle.Input
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +point: T.Targets.Point
  for +sources: T.Targets.Sources(S.Simulation.monsters(state),point,selected)
  for +absent: I.Identity.Absent(TP.TargetPlans.id(input),Z.Zones.keys(selected))
  T.Targets.Sources(S.Simulation.monsters(B.Battle.state(B.Battle.strike(input,state,pid,score))),point,selected)

def CombatFrame.survivor_sources(selected,input,state,pid,score,point,sources,absent):
  match selected:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match sources:
        case Tuple{source,later}:
          match absent:
            case Tuple{different,remaining}: Tuple{CombatFrame.battle_source(head,input,state,pid,score,point,source,I.Identity.neq_sym(TP.TargetPlans.id(input),R.Roster.id(head),(%T.Targets.key_id(head) : {U32.is_eq(TP.TargetPlans.id(input),_) == False{} : Bool}; different))),CombatFrame.survivor_sources(rest,input,state,pid,score,point,later,remaining)}

# Each witness refers to the actual world immediately before its own strike.
# The origin point is fixed for this admitted action; player-position framing
# is a separate obligation when relating it to each intermediate player state.
def CombatFrame.Execution(inputs: List<&2,B.Battle.Input>,+state: S.Simulation.State,+point: T.Targets.Point,+pid: U32,+score: U32) -> Data:
  match inputs:
    case Nil{}: Unit
    case Con{head,rest}:
      +head = head
      Sigma<&2,&2,T.Targets.IDSource<S.Simulation.monsters(state),point,TP.TargetPlans.id(head)>,(source => CombatFrame.Execution(rest,B.Battle.state(B.Battle.strike(head,state,pid,score)),point,pid,score))>

law CombatFrame.inputs_execution:
  for +selected: List<&2,M.Monsters.State>
  for +powers: Spin.SpinPlans.Powers(selected)
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +point: T.Targets.Point
  for +sources: T.Targets.Sources(S.Simulation.monsters(state),point,selected)
  for +unique: I.Identity.Monsters(S.Simulation.monsters(state))
  for +selected_unique: I.Identity.Monsters(selected)
  CombatFrame.Execution(Spin.SpinPlans.inputs(selected,powers),state,point,pid,score)

def CombatFrame.inputs_execution(selected,powers,state,pid,score,point,sources,unique,selected_unique):
  match selected:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match powers:
        case Tuple{power,later_powers}:
          match sources:
            case Tuple{source,later_sources}:
              match selected_unique:
                case Tuple{absent,remaining_unique}:
                  +input = Spin.SpinPlans.input(head,power)
                  +other_ids = {(%Equal.sym(U32,TP.TargetPlans.id(input),R.Roster.id(head),Spin.SpinPlans.input_id(head,power)) : I.Identity.Absent(_,Z.Zones.keys(rest)); (%T.Targets.key_id(head) : I.Identity.Absent(_,Z.Zones.keys(rest)); absent)) : I.Identity.Absent(TP.TargetPlans.id(input),Z.Zones.keys(rest))}
                  Tuple{(%Equal.sym(U32,TP.TargetPlans.id(input),R.Roster.id(head),Spin.SpinPlans.input_id(head,power)) : T.Targets.IDSource<S.Simulation.monsters(state),point,_>; T.Targets.found_lookup(Some{head},S.Simulation.monsters(state),point,source,unique)),CombatFrame.inputs_execution(rest,later_powers,B.Battle.state(B.Battle.strike(input,state,pid,score)),pid,score,point,CombatFrame.survivor_sources(rest,input,state,pid,score,point,later_sources,other_ids),I.Identity.battle_strike_unique(input,state,pid,score,unique),remaining_unique)}

law CombatFrame.spin_execution:
  for +state: S.Simulation.State
  for +point: T.Targets.Point
  for +pid: U32
  for +score: U32
  for build: (@+selected: List<&2,M.Monsters.State> -> Spin.SpinPlans.Powers(selected))
  for +unique: I.Identity.Monsters(S.Simulation.monsters(state))
  CombatFrame.Execution(L.LiveCombat.inputs(Spin.SpinPlans.run(S.Simulation.monsters(state),point,build)),state,point,pid,score)

def CombatFrame.spin_execution(state,point,pid,score,build,unique):
  +selected = T.Targets.filter(S.Simulation.monsters(state),point)
  CombatFrame.inputs_execution(selected,build(selected),state,pid,score,point,T.Targets.filter_sources(S.Simulation.monsters(state),point),unique,T.Targets.filter_unique(S.Simulation.monsters(state),point,unique))
