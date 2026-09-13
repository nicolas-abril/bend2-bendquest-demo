# Ordered spin inputs: one payload for every selected complete monster record.
import Base
import ./combat_targets.bend as T
import ./target_plans.bend as P
import ./live_combat.bend as L
import ./battle.bend as B
import ./monsters.bend as M
import ./roster.bend as R
import ./identity.bend as I

# The builder must return exactly one Power per selected record. A plain
# unindexed list could silently omit hits when zipped with the target list.
def SpinPlans.Powers(selected: List<&2,M.Monsters.State>) -> Data:
  match selected:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,P.TargetPlans.Power,(power => SpinPlans.Powers(rest))>

def SpinPlans.input(monster: M.Monsters.State,power: P.TargetPlans.Power) -> B.Battle.Input:
  match power:
    case P.TargetPlans.Power{damage,payout}: B.Battle.Input{R.Roster.id(monster),damage,payout}

def SpinPlans.inputs(selected: List<&2,M.Monsters.State>,powers: SpinPlans.Powers(selected)) -> List<&2,B.Battle.Input>:
  match selected:
    case Nil{}: Nil{}
    case Con{head,rest}:
      match powers:
        case Tuple{power,later}: Con{SpinPlans.input(head,power),SpinPlans.inputs(rest,later)}

def SpinPlans.power_list(selected: List<&2,M.Monsters.State>,powers: SpinPlans.Powers(selected)) -> List<&2,P.TargetPlans.Power>:
  match selected:
    case Nil{}: Nil{}
    case Con{head,rest}:
      match powers:
        case Tuple{power,later}: Con{power,SpinPlans.power_list(rest,later)}

def SpinPlans.ids(inputs: List<&2,B.Battle.Input>) -> List<&1,U32>:
  match inputs:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{P.TargetPlans.id(head),SpinPlans.ids(rest)}

def SpinPlans.payloads(inputs: List<&2,B.Battle.Input>) -> List<&2,P.TargetPlans.Power>:
  match inputs:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{P.TargetPlans.power(head),SpinPlans.payloads(rest)}

def SpinPlans.count(inputs: List<&2,B.Battle.Input>) -> Nat:
  match inputs:
    case Nil{}: Zero{}
    case Con{head,rest}: Succ{SpinPlans.count(rest)}

def SpinPlans.effect(point: T.Targets.Point) -> L.LiveCombat.Visual:
  match point:
    case T.Targets.Point{zone,x,y}: L.LiveCombat.Spin{zone,x,y}

def SpinPlans.visual(plan: L.LiveCombat.Plan) -> L.LiveCombat.Visual:
  match plan:
    case L.LiveCombat.Plan{inputs,visual}: visual

def SpinPlans.ready(selected: List<&2,M.Monsters.State>,point: T.Targets.Point,powers: SpinPlans.Powers(selected)) -> L.LiveCombat.Plan:
  L.LiveCombat.Plan{SpinPlans.inputs(selected,powers),SpinPlans.effect(point)}

# An ordinary affine callback runs once on the entire selected list.
def SpinPlans.run(monsters: List<&2,M.Monsters.State>,+point: T.Targets.Point,build: (@+selected: List<&2,M.Monsters.State> -> SpinPlans.Powers(selected))) -> L.LiveCombat.Plan:
  +selected = T.Targets.filter(monsters,point)
  SpinPlans.ready(selected,point,build(selected))

law SpinPlans.input_id:
  for +monster: M.Monsters.State
  for +power: P.TargetPlans.Power
  {P.TargetPlans.id(SpinPlans.input(monster,power)) == R.Roster.id(monster) : U32}

def SpinPlans.input_id(monster,power):
  match power:
    case P.TargetPlans.Power{damage,payout}: {==}

law SpinPlans.input_power:
  for +monster: M.Monsters.State
  for +power: P.TargetPlans.Power
  {P.TargetPlans.power(SpinPlans.input(monster,power)) == power : P.TargetPlans.Power}

def SpinPlans.input_power(monster,power):
  match power:
    case P.TargetPlans.Power{damage,payout}: {==}

law SpinPlans.inputs_ids:
  for +selected: List<&2,M.Monsters.State>
  for +powers: SpinPlans.Powers(selected)
  {SpinPlans.ids(SpinPlans.inputs(selected,powers)) == T.Targets.ids(selected) : List<&1,U32>}

def SpinPlans.inputs_ids(selected,powers):
  match selected:
    case Nil{}: {==}
    case Con{head,rest}:
      match powers:
        case Tuple{power,later}:
          %Equal.sym(U32,P.TargetPlans.id(SpinPlans.input(head,power)),R.Roster.id(head),SpinPlans.input_id(head,power)) : {Con{_,SpinPlans.ids(SpinPlans.inputs(rest,later))} == Con{R.Roster.id(head),T.Targets.ids(rest)} : List<&1,U32>}
          Equal.cong(List<&1,U32>,List<&1,U32>,(ids => Con{R.Roster.id(head),ids}),SpinPlans.ids(SpinPlans.inputs(rest,later)),T.Targets.ids(rest),SpinPlans.inputs_ids(rest,later))

law SpinPlans.inputs_powers:
  for +selected: List<&2,M.Monsters.State>
  for +powers: SpinPlans.Powers(selected)
  {SpinPlans.payloads(SpinPlans.inputs(selected,powers)) == SpinPlans.power_list(selected,powers) : List<&2,P.TargetPlans.Power>}

def SpinPlans.inputs_powers(selected,powers):
  match selected:
    case Nil{}: {==}
    case Con{head,rest}:
      match powers:
        case Tuple{power,later}:
          %Equal.sym(P.TargetPlans.Power,P.TargetPlans.power(SpinPlans.input(head,power)),power,SpinPlans.input_power(head,power)) : {Con{_,SpinPlans.payloads(SpinPlans.inputs(rest,later))} == Con{power,SpinPlans.power_list(rest,later)} : List<&2,P.TargetPlans.Power>}
          Equal.cong(List<&2,P.TargetPlans.Power>,List<&2,P.TargetPlans.Power>,(tail => Con{power,tail}),SpinPlans.payloads(SpinPlans.inputs(rest,later)),SpinPlans.power_list(rest,later),SpinPlans.inputs_powers(rest,later))

law SpinPlans.inputs_count:
  for +selected: List<&2,M.Monsters.State>
  for +powers: SpinPlans.Powers(selected)
  {SpinPlans.count(SpinPlans.inputs(selected,powers)) == R.Roster.length(selected) : Nat}

def SpinPlans.inputs_count(selected,powers):
  match selected:
    case Nil{}: {==}
    case Con{head,rest}:
      match powers:
        case Tuple{power,later}: Equal.cong(Nat,Nat,(n => Succ{n}),SpinPlans.count(SpinPlans.inputs(rest,later)),R.Roster.length(rest),SpinPlans.inputs_count(rest,later))

law SpinPlans.ids_sources:
  for +inputs: List<&2,B.Battle.Input>
  for +monsters: List<&2,M.Monsters.State>
  for +point: T.Targets.Point
  for +sources: T.Targets.IDSources(monsters,point,SpinPlans.ids(inputs))
  P.TargetPlans.InputSources(monsters,point,inputs)

def SpinPlans.ids_sources(inputs,monsters,point,sources):
  match inputs:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match sources:
        case Tuple{source,later}: Tuple{source,SpinPlans.ids_sources(rest,monsters,point,later)}

law SpinPlans.inputs_sources:
  for +selected: List<&2,M.Monsters.State>
  for +powers: SpinPlans.Powers(selected)
  for +monsters: List<&2,M.Monsters.State>
  for +point: T.Targets.Point
  for +sources: T.Targets.Sources(monsters,point,selected)
  for +unique: I.Identity.Monsters(monsters)
  P.TargetPlans.InputSources(monsters,point,SpinPlans.inputs(selected,powers))

def SpinPlans.inputs_sources(selected,powers,monsters,point,sources,unique):
  SpinPlans.ids_sources(SpinPlans.inputs(selected,powers),monsters,point,(%Equal.sym(List<&1,U32>,SpinPlans.ids(SpinPlans.inputs(selected,powers)),T.Targets.ids(selected),SpinPlans.inputs_ids(selected,powers)) : T.Targets.IDSources(monsters,point,_); T.Targets.ids_sources(selected,monsters,point,sources,unique)))

law SpinPlans.ready_inputs:
  for +selected: List<&2,M.Monsters.State>
  for +point: T.Targets.Point
  for +powers: SpinPlans.Powers(selected)
  {L.LiveCombat.inputs(SpinPlans.ready(selected,point,powers)) == SpinPlans.inputs(selected,powers) : List<&2,B.Battle.Input>}

def SpinPlans.ready_inputs(selected,point,powers): {==}

law SpinPlans.ready_visual:
  for +selected: List<&2,M.Monsters.State>
  for +point: T.Targets.Point
  for +powers: SpinPlans.Powers(selected)
  {SpinPlans.visual(SpinPlans.ready(selected,point,powers)) == SpinPlans.effect(point) : L.LiveCombat.Visual}

def SpinPlans.ready_visual(selected,point,powers): {==}

law SpinPlans.run_ids:
  for +monsters: List<&2,M.Monsters.State>
  for +point: T.Targets.Point
  for build: (@+selected: List<&2,M.Monsters.State> -> SpinPlans.Powers(selected))
  {SpinPlans.ids(L.LiveCombat.inputs(SpinPlans.run(monsters,point,build))) == T.Targets.all_ids(monsters,point) : List<&1,U32>}

def SpinPlans.run_ids(monsters,point,build):
  +selected = T.Targets.filter(monsters,point)
  SpinPlans.inputs_ids(selected,build(selected))

law SpinPlans.run_count:
  for +monsters: List<&2,M.Monsters.State>
  for +point: T.Targets.Point
  for build: (@+selected: List<&2,M.Monsters.State> -> SpinPlans.Powers(selected))
  {SpinPlans.count(L.LiveCombat.inputs(SpinPlans.run(monsters,point,build))) == R.Roster.length(T.Targets.filter(monsters,point)) : Nat}

def SpinPlans.run_count(monsters,point,build):
  +selected = T.Targets.filter(monsters,point)
  SpinPlans.inputs_count(selected,build(selected))

law SpinPlans.run_sources:
  for +monsters: List<&2,M.Monsters.State>
  for +point: T.Targets.Point
  for build: (@+selected: List<&2,M.Monsters.State> -> SpinPlans.Powers(selected))
  for +unique: I.Identity.Monsters(monsters)
  P.TargetPlans.InputSources(monsters,point,L.LiveCombat.inputs(SpinPlans.run(monsters,point,build)))

def SpinPlans.run_sources(monsters,point,build,unique):
  +selected = T.Targets.filter(monsters,point)
  SpinPlans.inputs_sources(selected,build(selected),monsters,point,T.Targets.filter_sources(monsters,point),unique)

law SpinPlans.run_visual:
  for +monsters: List<&2,M.Monsters.State>
  for +point: T.Targets.Point
  for build: (@+selected: List<&2,M.Monsters.State> -> SpinPlans.Powers(selected))
  {SpinPlans.visual(SpinPlans.run(monsters,point,build)) == SpinPlans.effect(point) : L.LiveCombat.Visual}

def SpinPlans.run_visual(monsters,point,build):
  +selected = T.Targets.filter(monsters,point)
  SpinPlans.ready_visual(selected,point,build(selected))

law SpinPlans.run_powers:
  for +monsters: List<&2,M.Monsters.State>
  for +point: T.Targets.Point
  for build: (@+selected: List<&2,M.Monsters.State> -> SpinPlans.Powers(selected))
  {SpinPlans.payloads(L.LiveCombat.inputs(SpinPlans.run(monsters,point,build))) == SpinPlans.power_list(T.Targets.filter(monsters,point),build(T.Targets.filter(monsters,point))) : List<&2,P.TargetPlans.Power>}

def SpinPlans.run_powers(monsters,point,build):
  +selected = T.Targets.filter(monsters,point)
  SpinPlans.inputs_powers(selected,build(selected))

law SpinPlans.run_empty:
  for +monsters: List<&2,M.Monsters.State>
  for +point: T.Targets.Point
  for build: (@+selected: List<&2,M.Monsters.State> -> SpinPlans.Powers(selected))
  for +empty: {T.Targets.filter(monsters,point) == Nil{} : List<&2,M.Monsters.State>}
  {SpinPlans.run(monsters,point,build) == L.LiveCombat.Plan{Nil{},SpinPlans.effect(point)} : L.LiveCombat.Plan}

def SpinPlans.run_empty(monsters,point,build,empty):
  %Equal.sym(List<&2,M.Monsters.State>,T.Targets.filter(monsters,point),Nil{},empty) : {SpinPlans.ready(_,point,build(_)) == L.LiveCombat.Plan{Nil{},SpinPlans.effect(point)} : L.LiveCombat.Plan}
  {==}
