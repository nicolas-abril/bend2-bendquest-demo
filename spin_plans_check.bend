import Base
import ./main.bend as Application
import ./world.bend as W
import ./spin_plans.bend as Spin
import ./combat_targets.bend as Targets
import ./target_plans.bend as TP
import ./live_combat.bend as Fight
import ./battle.bend as Battle
import ./combat.bend as Combat
import ./payouts.bend as Pay
import ./monsters.bend as M
import ./players.bend as P
import ./simulation.bend as S
import ./game.bend as G
import ./compat.bend as C
import ./live_combat_check.bend as Live
import ./combat_targets_check.bend as Selection
import ./combat_check.bend as CT
import ./inventory_check.bend as Inv
import ./players_check.bend as Test

def same_payout(a: Pay.Payout.Plan,b: Pay.Payout.Plan) -> Bool:
  match a:
    case Pay.Payout.Plan{kind,xp,gold,score,side_need,side_score,drop,find_score,bonus,cull_need,cull_score}:
      match b:
        case Pay.Payout.Plan{k,e,g,s,n,t,d,f,v,c,q}: Bool.and(U32.is_eq(kind,k),Bool.and(U32.is_eq(xp,e),Bool.and(U32.is_eq(gold,g),Bool.and(U32.is_eq(score,s),Bool.and(U32.is_eq(side_need,n),Bool.and(U32.is_eq(side_score,t),Bool.and(U32.is_eq(drop,d),Bool.and(U32.is_eq(find_score,f),Bool.and(U32.is_eq(bonus,v),Bool.and(U32.is_eq(cull_need,c),U32.is_eq(cull_score,q)))))))))))

def same_input(a: Battle.Battle.Input,b: Battle.Battle.Input) -> Bool:
  match a:
    case Battle.Battle.Input{mid,damage,payout}:
      match b:
        case Battle.Battle.Input{id,amount,plan}: Bool.and(U32.is_eq(mid,id),Bool.and(U32.is_eq(damage,amount),same_payout(payout,plan)))

def same_inputs(a: List<&2,Battle.Battle.Input>,b: List<&2,Battle.Battle.Input>) -> Bool:
  match a:
    case Nil{}:
      match b:
        case Nil{}: True{}
        case Con{head,rest}: False{}
    case Con{head,rest}:
      match b:
        case Nil{}: False{}
        case Con{other,later}: Bool.and(same_input(head,other),same_inputs(rest,later))

def spin_visual(actual: Fight.LiveCombat.Visual,point: Targets.Targets.Point) -> Bool:
  match actual:
    case Fight.LiveCombat.Quiet{}: False{}
    case Fight.LiveCombat.Attack{zone,x,y,dir,mid,crit}: False{}
    case Fight.LiveCombat.Spin{zone,x,y}:
      match point:
        case Targets.Targets.Point{z,a,b}: Bool.and(U32.is_eq(zone,z),Bool.and(U32.is_eq(x,a),U32.is_eq(y,b)))

def check_plan(label: String,actual: Fight.LiveCombat.Plan,point: Targets.Targets.Point,expected: List<&2,Battle.Battle.Input>) -> IO(Unit):
  match actual:
    case Fight.LiveCombat.Plan{inputs,visual}: Test.verdict(label,Bool.and(same_inputs(inputs,expected),spin_visual(visual,point)))

# Deliberately distinct values exercise every payload field and ordering.
def marked(monster: M.Monsters.State) -> TP.TargetPlans.Power:
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}: TP.TargetPlans.Power{mid,Pay.Payout.Plan{kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}}

def marked_powers(+selected: List<&2,M.Monsters.State>) -> Spin.SpinPlans.Powers(selected):
  match selected:
    case Nil{}: Unit{}
    case Con{head,rest}: Tuple{marked(head),marked_powers(rest)}

def marked_case(label: String,monsters: List<&2,M.Monsters.State>,+point: Targets.Targets.Point,expected: List<&2,Battle.Battle.Input>) -> IO(Unit):
  check_plan(label,Spin.SpinPlans.run(monsters,point,marked_powers),point,expected)

@unsafe
def payload_case(label: String,+monsters: List<&2,M.Monsters.State>,point: Targets.Targets.Point,+hero: G.Bq.Hero,+meta: S.Simulation.Meta) -> IO(Unit):
  match point:
    case Targets.Targets.Point{zone,x,y}:
      +zone = zone
      +x = x
      +y = y
      check_plan(label,Spin.SpinPlans.run(monsters,Targets.Targets.Point{zone,x,y},W.Bq.spin_powers(monsters,hero,meta)),Targets.Targets.Point{zone,x,y},W.Bq.battle_spin_inputs(Selection.Previous.mids_in_reach(monsters,zone,x,y),monsters,hero,meta))

def creature(mid: U32,kind: U32,rare: U32,zone: U32,x: U32,y: U32,hp: U32,dead: U32) -> M.Monsters.State:
  M.Monsters.State{mid,kind,rare,zone,x,y,hp,123,55,7,dead,29}

def strong() -> G.Bq.Hero: G.Bq.Hero.Hero{Nil{},Fail{Unit{}},Fail{Unit{}},Fail{Unit{}},Fail{Unit{}},999n,40n,100n,200n,300n,0n}

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- marked_case("spin plan exact empty",[],Targets.Targets.Point{0,6,4},[])
    Unit <- marked_case("spin plan exact one",[creature(7,2,1,0,6,4,100,0)],Targets.Targets.Point{0,6,4},[Battle.Battle.Input{7,7,Pay.Payout.Plan{2,1,0,6,4,100,123,55,7,0,29}}])
    Unit <- marked_case("spin plan exact ordered",[creature(19,2,1,0,6,4,100,0),creature(7,2,1,0,6,4,100,0),creature(11,2,1,0,6,4,100,0)],Targets.Targets.Point{0,6,4},[Battle.Battle.Input{19,19,Pay.Payout.Plan{2,1,0,6,4,100,123,55,7,0,29}},Battle.Battle.Input{7,7,Pay.Payout.Plan{2,1,0,6,4,100,123,55,7,0,29}},Battle.Battle.Input{11,11,Pay.Payout.Plan{2,1,0,6,4,100,123,55,7,0,29}}])
    Unit <- marked_case("spin plan exact different payloads",[creature(7,0,0,0,6,4,4,0),creature(8,9,1,0,7,4,90,0)],Targets.Targets.Point{0,6,4},[Battle.Battle.Input{7,7,Pay.Payout.Plan{0,0,0,6,4,4,123,55,7,0,29}},Battle.Battle.Input{8,8,Pay.Payout.Plan{9,1,0,7,4,90,123,55,7,0,29}}])
    Unit <- marked_case("spin plan exact mixed rejection",[creature(3,2,1,1,6,4,100,0),creature(19,2,1,0,6,4,100,0),creature(4,2,1,0,6,4,100,1),creature(7,2,1,0,6,4,100,0),creature(5,2,1,0,9,4,100,0)],Targets.Targets.Point{0,6,4},[Battle.Battle.Input{19,19,Pay.Payout.Plan{2,1,0,6,4,100,123,55,7,0,29}},Battle.Battle.Input{7,7,Pay.Payout.Plan{2,1,0,6,4,100,123,55,7,0,29}}])
    Unit <- marked_case("spin plan exact all rejected",[creature(3,2,1,1,6,4,100,0),creature(4,2,1,0,6,4,100,1),creature(5,2,1,0,9,4,100,0)],Targets.Targets.Point{0,6,4},[])
    Unit <- marked_case("spin plan exact duplicate IDs",[creature(7,0,1,0,6,4,100,0),creature(7,9,1,0,6,4,100,0)],Targets.Targets.Point{0,6,4},[Battle.Battle.Input{7,7,Pay.Payout.Plan{0,1,0,6,4,100,123,55,7,0,29}},Battle.Battle.Input{7,7,Pay.Payout.Plan{9,1,0,6,4,100,123,55,7,0,29}}])
    Unit <- marked_case("spin plan exact zero selected",[creature(0,2,1,0,6,4,100,0),creature(7,2,1,0,6,4,100,0)],Targets.Targets.Point{0,6,4},[Battle.Battle.Input{0,0,Pay.Payout.Plan{2,1,0,6,4,100,123,55,7,0,29}},Battle.Battle.Input{7,7,Pay.Payout.Plan{2,1,0,6,4,100,123,55,7,0,29}}])
    Unit <- marked_case("spin plan exact MAX selected",[creature(4294967295,2,1,0,6,4,100,0),creature(7,2,1,0,6,4,100,0)],Targets.Targets.Point{0,6,4},[Battle.Battle.Input{4294967295,4294967295,Pay.Payout.Plan{2,1,0,6,4,100,123,55,7,0,29}},Battle.Battle.Input{7,7,Pay.Payout.Plan{2,1,0,6,4,100,123,55,7,0,29}}])
    Unit <- marked_case("spin plan exact diagonal boundary",[creature(7,2,1,0,5,3,100,0),creature(8,2,1,0,7,5,100,0)],Targets.Targets.Point{0,6,4},[Battle.Battle.Input{7,7,Pay.Payout.Plan{2,1,0,5,3,100,123,55,7,0,29}},Battle.Battle.Input{8,8,Pay.Payout.Plan{2,1,0,7,5,100,123,55,7,0,29}}])
    Unit <- marked_case("spin plan exact zero distant",[creature(0,2,1,0,20,4,100,0),creature(8,2,1,0,6,4,100,0)],Targets.Targets.Point{0,6,4},[Battle.Battle.Input{8,8,Pay.Payout.Plan{2,1,0,6,4,100,123,55,7,0,29}}])
    Unit <- marked_case("spin plan exact retained unusual fields",[creature(7,4294967295,4294967295,0,6,4,4294967295,0)],Targets.Targets.Point{0,6,4},[Battle.Battle.Input{7,7,Pay.Payout.Plan{4294967295,4294967295,0,6,4,4294967295,123,55,7,0,29}}])
    Unit <- payload_case("spin plan actual catalog kind 0",[creature(7,0,0,0,6,4,100,0),creature(8,0,1,0,7,4,100,0)],Targets.Targets.Point{0,6,4},G.Bq.fresh_hero,CT.fixture_meta(1))
    Unit <- payload_case("spin plan actual catalog kind 1",[creature(7,1,0,0,6,4,100,0),creature(8,1,1,0,7,4,100,0)],Targets.Targets.Point{0,6,4},G.Bq.fresh_hero,CT.fixture_meta(1))
    Unit <- payload_case("spin plan actual catalog kind 2",[creature(7,2,0,0,6,4,100,0),creature(8,2,1,0,7,4,100,0)],Targets.Targets.Point{0,6,4},G.Bq.fresh_hero,CT.fixture_meta(1))
    Unit <- payload_case("spin plan actual catalog kind 3",[creature(7,3,0,0,6,4,100,0),creature(8,3,1,0,7,4,100,0)],Targets.Targets.Point{0,6,4},G.Bq.fresh_hero,CT.fixture_meta(1))
    Unit <- payload_case("spin plan actual catalog kind 4",[creature(7,4,0,0,6,4,100,0),creature(8,4,1,0,7,4,100,0)],Targets.Targets.Point{0,6,4},G.Bq.fresh_hero,CT.fixture_meta(1))
    Unit <- payload_case("spin plan actual catalog kind 5",[creature(7,5,0,0,6,4,100,0),creature(8,5,1,0,7,4,100,0)],Targets.Targets.Point{0,6,4},G.Bq.fresh_hero,CT.fixture_meta(1))
    Unit <- payload_case("spin plan actual catalog kind 6",[creature(7,6,0,0,6,4,100,0),creature(8,6,1,0,7,4,100,0)],Targets.Targets.Point{0,6,4},G.Bq.fresh_hero,CT.fixture_meta(1))
    Unit <- payload_case("spin plan actual catalog kind 7",[creature(7,7,0,0,6,4,100,0),creature(8,7,1,0,7,4,100,0)],Targets.Targets.Point{0,6,4},G.Bq.fresh_hero,CT.fixture_meta(1))
    Unit <- payload_case("spin plan actual catalog kind 8",[creature(7,8,0,0,6,4,100,0),creature(8,8,1,0,7,4,100,0)],Targets.Targets.Point{0,6,4},G.Bq.fresh_hero,CT.fixture_meta(1))
    Unit <- payload_case("spin plan actual catalog kind 9",[creature(7,9,0,0,6,4,100,0),creature(8,9,1,0,7,4,100,0)],Targets.Targets.Point{0,6,4},G.Bq.fresh_hero,CT.fixture_meta(1))
    Unit <- payload_case("spin plan actual hero fresh",[creature(9,9,1,0,6,4,100,0),creature(7,0,1,0,6,4,1,0),creature(11,6,0,0,7,4,1,0),creature(5,2,1,0,8,4,100,0)],Targets.Targets.Point{0,6,4},G.Bq.fresh_hero,CT.fixture_meta(1))
    Unit <- payload_case("spin plan actual hero weapon",[creature(9,9,1,0,6,4,100,0),creature(7,0,1,0,6,4,1,0),creature(11,6,0,0,7,4,1,0),creature(5,2,1,0,8,4,100,0)],Targets.Targets.Point{0,6,4},P.Players.hero(Inv.armed),CT.fixture_meta(1))
    Unit <- payload_case("spin plan actual hero charm",[creature(9,9,1,0,6,4,100,0),creature(7,0,1,0,6,4,1,0),creature(11,6,0,0,7,4,1,0),creature(5,2,1,0,8,4,100,0)],Targets.Targets.Point{0,6,4},P.Players.hero(Inv.amulet),CT.fixture_meta(1))
    Unit <- payload_case("spin plan actual hero strong",[creature(9,9,1,0,6,4,100,0),creature(7,0,1,0,6,4,1,0),creature(11,6,0,0,7,4,1,0),creature(5,2,1,0,8,4,100,0)],Targets.Targets.Point{0,6,4},strong,CT.fixture_meta(1))
    Unit <- payload_case("spin plan actual metadata zero",[creature(9,9,1,0,6,4,100,0),creature(7,0,1,0,6,4,1,0),creature(11,6,0,0,7,4,1,0),creature(5,2,1,0,8,4,100,0)],Targets.Targets.Point{0,6,4},strong,S.Simulation.Meta{1,0,0,0,0,0,0,0,1,400})
    Unit <- payload_case("spin plan actual metadata MAX tick",[creature(9,9,1,0,6,4,100,0),creature(7,0,1,0,6,4,1,0),creature(11,6,0,0,7,4,1,0),creature(5,2,1,0,8,4,100,0)],Targets.Targets.Point{0,6,4},strong,S.Simulation.Meta{1,7,41,4294967295,100,200,0,19,51,450})
    Unit <- payload_case("spin plan actual metadata elapsed wrap",[creature(9,9,1,0,6,4,100,0),creature(7,0,1,0,6,4,1,0),creature(11,6,0,0,7,4,1,0),creature(5,2,1,0,8,4,100,0)],Targets.Targets.Point{0,6,4},strong,S.Simulation.Meta{1,7,41,17,4294967295,0,7,19,51,450})
    Unit <- payload_case("spin plan actual metadata full words",[creature(9,9,1,0,6,4,100,0),creature(7,0,1,0,6,4,1,0),creature(11,6,0,0,7,4,1,0),creature(5,2,1,0,8,4,100,0)],Targets.Targets.Point{0,6,4},strong,S.Simulation.Meta{4294967295,4294967295,4294967295,4294967295,4294967295,4294967295,4294967295,4294967295,4294967295,4294967295})
    Unit <- payload_case("spin plan actual roster empty",[],Targets.Targets.Point{0,6,4},G.Bq.fresh_hero,CT.fixture_meta(1))
    Unit <- payload_case("spin plan actual roster mixed rejection",[creature(3,2,1,1,6,4,100,0),creature(19,2,1,0,6,4,100,0),creature(4,2,1,0,6,4,100,1),creature(7,2,1,0,6,4,100,0),creature(5,2,1,0,9,4,100,0)],Targets.Targets.Point{0,6,4},G.Bq.fresh_hero,CT.fixture_meta(1))
    Unit <- payload_case("spin plan actual roster duplicate ID first lookup",[creature(7,0,1,0,6,4,100,0),creature(7,9,1,0,6,4,100,0)],Targets.Targets.Point{0,6,4},G.Bq.fresh_hero,CT.fixture_meta(1))
    Unit <- payload_case("spin plan actual roster zero ID",[creature(0,6,1,0,6,4,100,0),creature(7,9,1,0,6,4,100,0)],Targets.Targets.Point{0,6,4},G.Bq.fresh_hero,CT.fixture_meta(1))
    Unit <- payload_case("spin plan actual roster reverse order",[creature(5,2,1,0,8,4,100,0),creature(11,6,0,0,7,4,1,0),creature(7,0,1,0,6,4,1,0),creature(9,9,1,0,6,4,100,0)],Targets.Targets.Point{0,6,4},G.Bq.fresh_hero,CT.fixture_meta(1))
    Unit <- payload_case("spin plan actual roster unknown monster kind",[creature(7,4294967295,1,0,6,4,100,0)],Targets.Targets.Point{0,6,4},G.Bq.fresh_hero,CT.fixture_meta(1))
    Unit <- Live.checked("spin plan live two lethal",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0),CT.fixture_player(3,0,0,0)],[creature(7,0,0,0,6,4,1,0),creature(8,1,0,0,6,4,1,0)],1),2)
    Unit <- Live.checked("spin plan live boss then warden",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0),CT.fixture_player(3,0,0,0)],[creature(7,9,0,0,6,4,1,0),creature(8,6,0,0,6,4,1,0)],1),2)
    Unit <- Live.checked("spin plan live warden then boss",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0),CT.fixture_player(3,0,0,0)],[creature(7,6,0,0,6,4,1,0),creature(8,9,0,0,6,4,1,0)],1),2)
    Unit <- Live.checked("spin plan live all bosses",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0),CT.fixture_player(3,0,0,0)],[creature(7,6,0,0,6,4,1,0),creature(8,7,0,0,6,4,1,0),creature(9,8,0,0,6,4,1,0),creature(10,9,0,0,6,4,1,0)],1),2)
    Unit <- Live.checked("spin plan live mixed survivors",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0),CT.fixture_player(3,0,0,0)],[creature(9,9,1,0,6,4,100,0),creature(7,0,0,0,6,4,1,0),creature(8,6,0,0,6,4,1,0)],1),2)
    Unit <- Live.checked("spin plan live rare lethal",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0),CT.fixture_player(3,0,0,0)],[creature(7,2,1,0,6,4,1,0),creature(8,4,1,0,6,4,1,0)],1),2)
    Unit <- Live.checked("spin plan live zero then boss",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0),CT.fixture_player(3,0,0,0)],[creature(0,0,0,0,6,4,1,0),creature(8,9,0,0,6,4,1,0)],1),2)
    Unit <- Live.checked("spin plan live no eligible",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0),CT.fixture_player(3,0,0,0)],[creature(3,2,1,1,6,4,100,0),creature(4,2,1,0,6,4,100,1),creature(5,2,1,0,9,4,100,0)],1),2)
    Unit <- Live.twice("spin plan sequence spin twice",Combat.Combat.Spin{},Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0),CT.fixture_player(3,0,0,0)],[creature(9,9,1,0,6,4,100,0),creature(7,0,1,0,6,4,1,0),creature(11,6,0,0,7,4,1,0),creature(5,2,1,0,8,4,100,0)],1),2,2)
    Unit <- Live.twice("spin plan sequence spin then attack",Combat.Combat.Spin{},Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0),CT.fixture_player(3,0,0,0)],[creature(9,9,1,0,6,4,100,0),creature(7,0,1,0,6,4,1,0),creature(11,6,0,0,7,4,1,0),creature(5,2,1,0,8,4,100,0)],1),2,2)
    Unit <- Live.twice("spin plan sequence attack then spin",Combat.Combat.Attack{},Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0),CT.fixture_player(3,0,0,0)],[creature(9,9,1,0,6,4,100,0),creature(7,0,1,0,6,4,1,0),creature(11,6,0,0,7,4,1,0),creature(5,2,1,0,8,4,100,0)],1),2,2)
    Unit <- Live.twice("spin plan sequence competing players",Combat.Combat.Spin{},Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0),CT.fixture_player(3,0,0,0)],[creature(9,9,1,0,6,4,100,0),creature(7,0,1,0,6,4,1,0),creature(11,6,0,0,7,4,1,0),creature(5,2,1,0,8,4,100,0)],1),2,3)
    return Unit{}

#| PASS spin plan exact empty
#| PASS spin plan exact one
#| PASS spin plan exact ordered
#| PASS spin plan exact different payloads
#| PASS spin plan exact mixed rejection
#| PASS spin plan exact all rejected
#| PASS spin plan exact duplicate IDs
#| PASS spin plan exact zero selected
#| PASS spin plan exact MAX selected
#| PASS spin plan exact diagonal boundary
#| PASS spin plan exact zero distant
#| PASS spin plan exact retained unusual fields
#| PASS spin plan actual catalog kind 0
#| PASS spin plan actual catalog kind 1
#| PASS spin plan actual catalog kind 2
#| PASS spin plan actual catalog kind 3
#| PASS spin plan actual catalog kind 4
#| PASS spin plan actual catalog kind 5
#| PASS spin plan actual catalog kind 6
#| PASS spin plan actual catalog kind 7
#| PASS spin plan actual catalog kind 8
#| PASS spin plan actual catalog kind 9
#| PASS spin plan actual hero fresh
#| PASS spin plan actual hero weapon
#| PASS spin plan actual hero charm
#| PASS spin plan actual hero strong
#| PASS spin plan actual metadata zero
#| PASS spin plan actual metadata MAX tick
#| PASS spin plan actual metadata elapsed wrap
#| PASS spin plan actual metadata full words
#| PASS spin plan actual roster empty
#| PASS spin plan actual roster mixed rejection
#| PASS spin plan actual roster duplicate ID first lookup
#| PASS spin plan actual roster zero ID
#| PASS spin plan actual roster reverse order
#| PASS spin plan actual roster unknown monster kind
#| PASS spin plan live two lethal
#| PASS spin plan live boss then warden
#| PASS spin plan live warden then boss
#| PASS spin plan live all bosses
#| PASS spin plan live mixed survivors
#| PASS spin plan live rare lethal
#| PASS spin plan live zero then boss
#| PASS spin plan live no eligible
#| PASS spin plan sequence spin twice
#| PASS spin plan sequence spin then attack
#| PASS spin plan sequence attack then spin
#| PASS spin plan sequence competing players
