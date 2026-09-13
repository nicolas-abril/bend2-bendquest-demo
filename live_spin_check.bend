import Base
import ./main.bend as Application
import ./world.bend as W
import ./live_spin.bend as LS
import ./live_combat.bend as Fight
import ./combat.bend as Combat
import ./players.bend as P
import ./vitals.bend as V
import ./monsters.bend as M
import ./roster.bend as R
import ./simulation.bend as S
import ./terrain.bend as Terrain
import ./spin_plans.bend as Spin
import ./combat_targets.bend as Targets
import ./target_plans.bend as TP
import ./payouts.bend as Pay
import ./battle.bend as Battle
import ./spin_plans_check.bend as Old
import ./combat_check.bend as CT
import ./players_check.bend as Test

@unsafe
def Previous.plan_spin(ready: Fight.LiveCombat.Ready) -> Fight.LiveCombat.Plan:
  match ready:
    case Fight.LiveCombat.Ready{wm,mobs,maps,result,pid,score}:
      match result:
        case Combat.Combat.Result{players,attacker}:
          match attacker:
            case None{}: Fight.LiveCombat.Plan{Nil{},Fight.LiveCombat.Quiet{}}
            case Some{player}:
              match player:
                case P.Players.State{actor_id,cid,hero,pos,vitals,style,quest,meta}:
                  match pos:
                    case P.Players.Pos{zone,x,y,dir,moving}:
                      +wm = wm
                      +mobs = mobs
                      +hero = hero
                      +zone = zone
                      +x = x
                      +y = y
                      Spin.SpinPlans.run(mobs,Targets.Targets.Point{zone,x,y},W.Bq.spin_powers(mobs,hero,wm))


def snapshot_power(monsters: List<&2,M.Monsters.State>,+player: P.Players.State,meta: S.Simulation.Meta,monster: M.Monsters.State) -> TP.TargetPlans.Power:
  match meta:
    case S.Simulation.Meta{phase,world,seed,tick,started,now,sigils,fame,next_player,next_monster}:
      TP.TargetPlans.Power{P.Players.id(player),Pay.Payout.Plan{P.Players.id(player),seed,tick,now,phase,U32.from_nat(R.Roster.length(monsters)),R.Roster.id(monster),V.Vitals.hp(P.Players.vitals(player)),Combat.Combat.cooldown(Combat.Combat.Spin{},P.Players.vitals(player)),Combat.Combat.cooldown(Combat.Combat.Attack{},P.Players.vitals(player)),world}}

def snapshot_powers(+monsters: List<&2,M.Monsters.State>,+player: P.Players.State,+meta: S.Simulation.Meta,+selected: List<&2,M.Monsters.State>) -> Spin.SpinPlans.Powers(selected):
  match selected:
    case Nil{}: Unit{}
    case Con{head,rest}: Tuple{snapshot_power(monsters,player,meta,head),snapshot_powers(monsters,player,meta,rest)}

def empty_quiet(plan: Fight.LiveCombat.Plan) -> Bool:
  match plan:
    case Fight.LiveCombat.Plan{inputs,visual}:
      match inputs:
        case Nil{}:
          match visual:
            case Fight.LiveCombat.Quiet{}: True{}
            case Fight.LiveCombat.Spin{zone,x,y}: False{}
            case Fight.LiveCombat.Attack{zone,x,y,dir,mid,crit}: False{}
        case Con{head,rest}: False{}

def same_visual(a: Fight.LiveCombat.Visual,b: Fight.LiveCombat.Visual) -> Bool:
  match a:
    case Fight.LiveCombat.Quiet{}: empty_quiet(Fight.LiveCombat.Plan{Nil{},b})
    case Fight.LiveCombat.Spin{zone,x,y}: Old.spin_visual(b,Targets.Targets.Point{zone,x,y})
    case Fight.LiveCombat.Attack{zone,x,y,dir,mid,crit}: False{}

def same_plan(a: Fight.LiveCombat.Plan,b: Fight.LiveCombat.Plan) -> Bool:
  match a:
    case Fight.LiveCombat.Plan{xs,av}:
      match b:
        case Fight.LiveCombat.Plan{ys,bv}: Bool.and(Old.same_inputs(xs,ys),same_visual(av,bv))

def snapshot_case(label: String,world: Terrain.Terrain.World,pid: U32,point: Targets.Targets.Point,expected: List<&2,Battle.Battle.Input>) -> IO(Unit): Old.check_plan(label,LS.LiveSpin.plan(Fight.LiveCombat.prepare(world,Combat.Combat.Spin{},pid,60),snapshot_powers),point,expected)

def rejected_case(label: String,world: Terrain.Terrain.World,pid: U32) -> IO(Unit): Test.verdict(label,empty_quiet(LS.LiveSpin.plan(Fight.LiveCombat.prepare(world,Combat.Combat.Spin{},pid,60),snapshot_powers)))

@unsafe
def oracle_case(label: String,world: Terrain.Terrain.World,pid: U32) -> IO(Unit):
  +ready = Fight.LiveCombat.prepare(world,Combat.Combat.Spin{},pid,60)
  Test.verdict(label,same_plan(W.Bq.plan_spin(ready),Previous.plan_spin(ready)))

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- snapshot_case("live spin forwards complete snapshots",CT.fixture_world([CT.fixture_player(2,0,7,0)],[Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0),Old.creature(9,2,0,1,6,4,100,0)],1),2,Targets.Targets.Point{0,6,4},[Battle.Battle.Input{7,2,Pay.Payout.Plan{2,41,17,200,1,3,7,35,25,7,7}},Battle.Battle.Input{8,2,Pay.Payout.Plan{2,41,17,200,1,3,8,35,25,7,7}}])
    Unit <- snapshot_case("live spin selects second player",CT.fixture_world([CT.fixture_player(3,0,99,0),CT.fixture_player(2,0,7,0)],[Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0),Old.creature(9,2,0,1,6,4,100,0)],1),2,Targets.Targets.Point{0,6,4},[Battle.Battle.Input{7,2,Pay.Payout.Plan{2,41,17,200,1,3,7,35,25,7,7}},Battle.Battle.Input{8,2,Pay.Payout.Plan{2,41,17,200,1,3,8,35,25,7,7}}])
    Unit <- snapshot_case("live spin selects first duplicate PID",CT.fixture_world([CT.fixture_player(2,0,7,0),CT.fixture_player(2,0,99,0)],[Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0),Old.creature(9,2,0,1,6,4,100,0)],1),2,Targets.Targets.Point{0,6,4},[Battle.Battle.Input{7,2,Pay.Payout.Plan{2,41,17,200,1,3,7,35,25,7,7}},Battle.Battle.Input{8,2,Pay.Payout.Plan{2,41,17,200,1,3,8,35,25,7,7}}])
    Unit <- snapshot_case("live spin preserves attack cooldown",CT.fixture_world([CT.fixture_player(2,0,4294967295,0)],[Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0),Old.creature(9,2,0,1,6,4,100,0)],1),2,Targets.Targets.Point{0,6,4},[Battle.Battle.Input{7,2,Pay.Payout.Plan{2,41,17,200,1,3,7,35,25,4294967295,7}},Battle.Battle.Input{8,2,Pay.Payout.Plan{2,41,17,200,1,3,8,35,25,4294967295,7}}])
    Unit <- snapshot_case("live spin empty targets animate",CT.fixture_world([CT.fixture_player(2,0,7,0)],[],1),2,Targets.Targets.Point{0,6,4},[])
    Unit <- snapshot_case("live spin zero actor ID",CT.fixture_world([CT.fixture_player(0,0,7,0)],[Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0),Old.creature(9,2,0,1,6,4,100,0)],1),0,Targets.Targets.Point{0,6,4},[Battle.Battle.Input{7,0,Pay.Payout.Plan{0,41,17,200,1,3,7,35,25,7,7}},Battle.Battle.Input{8,0,Pay.Payout.Plan{0,41,17,200,1,3,8,35,25,7,7}}])
    Unit <- snapshot_case("live spin MAX actor ID",CT.fixture_world([CT.fixture_player(4294967295,0,7,0)],[Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0),Old.creature(9,2,0,1,6,4,100,0)],1),4294967295,Targets.Targets.Point{0,6,4},[Battle.Battle.Input{7,4294967295,Pay.Payout.Plan{4294967295,41,17,200,1,3,7,35,25,7,7}},Battle.Battle.Input{8,4294967295,Pay.Payout.Plan{4294967295,41,17,200,1,3,8,35,25,7,7}}])
    Unit <- snapshot_case("live spin forwards boundary metadata",Terrain.Terrain.World{S.Simulation.Meta{1,4294967295,0,4294967295,100,0,0,19,51,450},[CT.fixture_player(2,0,7,0)],[Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0),Old.creature(9,2,0,1,6,4,100,0)],[]},2,Targets.Targets.Point{0,6,4},[Battle.Battle.Input{7,2,Pay.Payout.Plan{2,0,4294967295,0,1,3,7,35,25,7,4294967295}},Battle.Battle.Input{8,2,Pay.Payout.Plan{2,0,4294967295,0,1,3,8,35,25,7,4294967295}}])
    Unit <- rejected_case("live spin missing actor",CT.fixture_world([CT.fixture_player(2,0,7,0)],[Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0),Old.creature(9,2,0,1,6,4,100,0)],1),99)
    Unit <- rejected_case("live spin empty players",CT.fixture_world([],[Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0),Old.creature(9,2,0,1,6,4,100,0)],1),2)
    Unit <- rejected_case("live spin dead actor",CT.fixture_world([CT.fixture_player(2,1,0,0)],[Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0),Old.creature(9,2,0,1,6,4,100,0)],1),2)
    Unit <- rejected_case("live spin cooling actor",CT.fixture_world([CT.fixture_player(2,0,0,1)],[Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0),Old.creature(9,2,0,1,6,4,100,0)],1),2)
    Unit <- rejected_case("live spin ended phase",CT.fixture_world([CT.fixture_player(2,0,0,0)],[Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0),Old.creature(9,2,0,1,6,4,100,0)],2),2)
    Unit <- rejected_case("live spin zero phase",CT.fixture_world([CT.fixture_player(2,0,0,0)],[Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0),Old.creature(9,2,0,1,6,4,100,0)],0),2)
    Unit <- oracle_case("live spin previous planner snapshots",CT.fixture_world([CT.fixture_player(2,0,7,0)],[Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0),Old.creature(9,2,0,1,6,4,100,0)],1),2)
    Unit <- oracle_case("live spin previous planner second actor",CT.fixture_world([CT.fixture_player(3,0,0,0),CT.fixture_player(2,0,0,0)],[Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0),Old.creature(9,2,0,1,6,4,100,0)],1),2)
    Unit <- oracle_case("live spin previous planner missing actor",CT.fixture_world([CT.fixture_player(2,0,7,0)],[Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0),Old.creature(9,2,0,1,6,4,100,0)],1),99)
    Unit <- oracle_case("live spin previous planner empty targets",CT.fixture_world([CT.fixture_player(2,0,0,0)],[],1),2)
    Unit <- oracle_case("live spin previous planner duplicate IDs",CT.fixture_world([CT.fixture_player(2,0,0,0)],[Old.creature(7,0,0,0,6,4,100,0),Old.creature(7,9,1,0,7,4,100,0)],1),2)
    Unit <- oracle_case("live spin previous planner boundaries",Terrain.Terrain.World{S.Simulation.Meta{1,4294967295,0,4294967295,100,0,0,19,51,450},[CT.fixture_player(2,0,7,0)],[Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0),Old.creature(9,2,0,1,6,4,100,0)],[]},2)
    return Unit{}

#| PASS live spin forwards complete snapshots
#| PASS live spin selects second player
#| PASS live spin selects first duplicate PID
#| PASS live spin preserves attack cooldown
#| PASS live spin empty targets animate
#| PASS live spin zero actor ID
#| PASS live spin MAX actor ID
#| PASS live spin forwards boundary metadata
#| PASS live spin missing actor
#| PASS live spin empty players
#| PASS live spin dead actor
#| PASS live spin cooling actor
#| PASS live spin ended phase
#| PASS live spin zero phase
#| PASS live spin previous planner snapshots
#| PASS live spin previous planner second actor
#| PASS live spin previous planner missing actor
#| PASS live spin previous planner empty targets
#| PASS live spin previous planner duplicate IDs
#| PASS live spin previous planner boundaries
