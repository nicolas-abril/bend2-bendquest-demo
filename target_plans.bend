# Bind an attack's target ID to the selected complete monster record.
import Base
import ./combat_targets.bend as T
import ./live_combat.bend as L
import ./battle.bend as B
import ./payouts.bend as P
import ./monsters.bend as M
import ./roster.bend as R
import ./identity.bend as I

type TargetPlans.Power is Data:
  TargetPlans.Power{damage: U32,payout: P.Payout.Plan}

def TargetPlans.power(input: B.Battle.Input) -> TargetPlans.Power:
  match input:
    case B.Battle.Input{mid,damage,payout}: TargetPlans.Power{damage,payout}

def TargetPlans.id(input: B.Battle.Input) -> U32:
  match input:
    case B.Battle.Input{mid,damage,payout}: mid

def TargetPlans.ready(+monster: M.Monsters.State,point: T.Targets.Point,dir: U32,crit: U32,power: TargetPlans.Power) -> L.LiveCombat.Plan:
  match point:
    case T.Targets.Point{zone,x,y}:
      match power:
        case TargetPlans.Power{damage,payout}: L.LiveCombat.Plan{[B.Battle.Input{R.Roster.id(monster),damage,payout}],L.LiveCombat.Attack{zone,x,y,dir,R.Roster.id(monster),crit}}

def TargetPlans.attack(found: Maybe<&2,M.Monsters.State>,point: T.Targets.Point,dir: U32,crit: U32,build: M.Monsters.State -> TargetPlans.Power) -> L.LiveCombat.Plan:
  match found:
    case None{}: L.LiveCombat.Plan{Nil{},L.LiveCombat.Quiet{}}
    case Some{monster}:
      +monster = monster
      TargetPlans.ready(monster,point,dir,crit,build(monster))

def TargetPlans.InputSources(+monsters: List<&2,M.Monsters.State>,+point: T.Targets.Point,inputs: List<&2,B.Battle.Input>) -> Data:
  match inputs:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,T.Targets.IDSource<monsters,point,TargetPlans.id(head)>,(source => TargetPlans.InputSources(monsters,point,rest))>

law TargetPlans.attack_none:
  for +point: T.Targets.Point
  for +dir: U32
  for +crit: U32
  for build: M.Monsters.State -> TargetPlans.Power
  {TargetPlans.attack(None{},point,dir,crit,build) == L.LiveCombat.Plan{Nil{},L.LiveCombat.Quiet{}} : L.LiveCombat.Plan}

def TargetPlans.attack_none(point,dir,crit,build): {==}

law TargetPlans.attack_some:
  for +monster: M.Monsters.State
  for +point: T.Targets.Point
  for +dir: U32
  for +crit: U32
  for build: M.Monsters.State -> TargetPlans.Power
  {TargetPlans.attack(Some{monster},point,dir,crit,build) == TargetPlans.ready(monster,point,dir,crit,build(monster)) : L.LiveCombat.Plan}

def TargetPlans.attack_some(monster,point,dir,crit,build): {==}

law TargetPlans.ready_sources:
  for +monster: M.Monsters.State
  for +point: T.Targets.Point
  for +dir: U32
  for +crit: U32
  for +power: TargetPlans.Power
  for +monsters: List<&2,M.Monsters.State>
  for +source: T.Targets.IDSource<monsters,point,R.Roster.id(monster)>
  TargetPlans.InputSources(monsters,point,L.LiveCombat.inputs(TargetPlans.ready(monster,point,dir,crit,power)))

def TargetPlans.ready_sources(monster,point,dir,crit,power,monsters,source):
  match point:
    case T.Targets.Point{zone,x,y}:
      match power:
        case TargetPlans.Power{damage,payout}: Tuple{source,Unit{}}

law TargetPlans.attack_sources:
  for +found: Maybe<&2,M.Monsters.State>
  for +point: T.Targets.Point
  for +dir: U32
  for +crit: U32
  for +monsters: List<&2,M.Monsters.State>
  for build: M.Monsters.State -> TargetPlans.Power
  for +source: T.Targets.FirstLookup(monsters,point,found)
  TargetPlans.InputSources(monsters,point,L.LiveCombat.inputs(TargetPlans.attack(found,point,dir,crit,build)))

def TargetPlans.attack_sources(found,point,dir,crit,monsters,build,source):
  match found:
    case None{}: Unit{}
    case Some{monster}: TargetPlans.ready_sources(monster,point,dir,crit,build(monster),monsters,source)

law TargetPlans.first_attack_sources:
  for +monsters: List<&2,M.Monsters.State>
  for +point: T.Targets.Point
  for +dir: U32
  for +crit: U32
  for build: M.Monsters.State -> TargetPlans.Power
  for +unique: I.Identity.Monsters(monsters)
  TargetPlans.InputSources(monsters,point,L.LiveCombat.inputs(TargetPlans.attack(T.Targets.first(monsters,point),point,dir,crit,build)))

def TargetPlans.first_attack_sources(monsters,point,dir,crit,build,unique): TargetPlans.attack_sources(T.Targets.first(monsters,point),point,dir,crit,monsters,build,T.Targets.first_lookup(monsters,point,unique))

law TargetPlans.power_exact:
  for +mid: U32
  for +damage: U32
  for +payout: P.Payout.Plan
  {TargetPlans.power(B.Battle.Input{mid,damage,payout}) == TargetPlans.Power{damage,payout} : TargetPlans.Power}

def TargetPlans.power_exact(mid,damage,payout): {==}

law TargetPlans.ready_exact:
  for +monster: M.Monsters.State
  for +zone: U32
  for +x: U32
  for +y: U32
  for +dir: U32
  for +crit: U32
  for +damage: U32
  for +payout: P.Payout.Plan
  {TargetPlans.ready(monster,T.Targets.Point{zone,x,y},dir,crit,TargetPlans.Power{damage,payout}) == L.LiveCombat.Plan{[B.Battle.Input{R.Roster.id(monster),damage,payout}],L.LiveCombat.Attack{zone,x,y,dir,R.Roster.id(monster),crit}} : L.LiveCombat.Plan}

def TargetPlans.ready_exact(monster,zone,x,y,dir,crit,damage,payout): {==}
