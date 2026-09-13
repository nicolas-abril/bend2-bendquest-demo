import Base
import ./main.bend as Application
import ./world.bend as W
import ./live_attack.bend as LA
import ./live_combat.bend as Fight
import ./combat.bend as Combat
import ./players.bend as P
import ./vitals.bend as V
import ./monsters.bend as M
import ./roster.bend as R
import ./simulation.bend as S
import ./terrain.bend as Terrain
import ./combat_targets.bend as Targets
import ./target_plans.bend as TP
import ./payouts.bend as Pay
import ./battle.bend as Battle
import ./compat.bend as C
import ./spin_plans_check.bend as Old
import ./combat_check.bend as CT
import ./players_check.bend as Test

@unsafe
def Previous.plan_attack(ready: Fight.LiveCombat.Ready) -> Fight.LiveCombat.Plan:
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
                      +crit = C.Bq.bit(U32.is_lt(U32.mod(W.Bq.hash2(W.Bq.wm_tick(wm),U32.add(U32.mul(pid,7),3)),100),W.Bq.hero_crit(hero)))
                      TP.TargetPlans.attack(Targets.Targets.first(mobs,Targets.Targets.Point{zone,x,y}),Targets.Targets.Point{zone,x,y},dir,crit,W.Bq.attack_power(mobs,hero,wm,crit))


def snapshot_power(monsters: List<&2,M.Monsters.State>,+player: P.Players.State,meta: S.Simulation.Meta,pid: U32,crit: U32,monster: M.Monsters.State) -> TP.TargetPlans.Power:
  match meta:
    case S.Simulation.Meta{phase,world,seed,tick,started,now,sigils,fame,next_player,next_monster}:
      TP.TargetPlans.Power{pid,Pay.Payout.Plan{P.Players.id(player),seed,tick,now,phase,U32.from_nat(R.Roster.length(monsters)),R.Roster.id(monster),V.Vitals.hp(P.Players.vitals(player)),Combat.Combat.cooldown(Combat.Combat.Spin{},P.Players.vitals(player)),Combat.Combat.cooldown(Combat.Combat.Attack{},P.Players.vitals(player)),crit}}

def snapshot_tuning(+monsters: List<&2,M.Monsters.State>,+player: P.Players.State,+meta: S.Simulation.Meta,+pid: U32) -> LA.LiveAttack.Tuning:
  +crit = U32.mod(pid,2)
  LA.LiveAttack.Tuning{crit,snapshot_power(monsters,player,meta,pid,crit)}

def same_visual(a: Fight.LiveCombat.Visual,b: Fight.LiveCombat.Visual) -> Bool:
  match a:
    case Fight.LiveCombat.Quiet{}:
      match b:
        case Fight.LiveCombat.Quiet{}: True{}
        case Fight.LiveCombat.Spin{zone,x,y}: False{}
        case Fight.LiveCombat.Attack{zone,x,y,dir,mid,crit}: False{}
    case Fight.LiveCombat.Spin{zone,x,y}: False{}
    case Fight.LiveCombat.Attack{zone,x,y,dir,mid,crit}:
      match b:
        case Fight.LiveCombat.Quiet{}: False{}
        case Fight.LiveCombat.Spin{z,a,b}: False{}
        case Fight.LiveCombat.Attack{z,a,b,d,m,c}: Bool.and(U32.is_eq(zone,z),Bool.and(U32.is_eq(x,a),Bool.and(U32.is_eq(y,b),Bool.and(U32.is_eq(dir,d),Bool.and(U32.is_eq(mid,m),U32.is_eq(crit,c))))))

def same_plan(a: Fight.LiveCombat.Plan,b: Fight.LiveCombat.Plan) -> Bool:
  match a:
    case Fight.LiveCombat.Plan{xs,av}:
      match b:
        case Fight.LiveCombat.Plan{ys,bv}: Bool.and(Old.same_inputs(xs,ys),same_visual(av,bv))

def snapshot_case(label: String,world: Terrain.Terrain.World,pid: U32,expected: Fight.LiveCombat.Plan) -> IO(Unit): Test.verdict(label,same_plan(LA.LiveAttack.plan(Fight.LiveCombat.prepare(world,Combat.Combat.Attack{},pid,60),snapshot_tuning),expected))

def quiet_case(label: String,world: Terrain.Terrain.World,pid: U32) -> IO(Unit): snapshot_case(label,world,pid,Fight.LiveCombat.Plan{Nil{},Fight.LiveCombat.Quiet{}})

@unsafe
def oracle_ready(label: String,+ready: Fight.LiveCombat.Ready) -> IO(Unit): Test.verdict(label,same_plan(W.Bq.plan_attack(ready),Previous.plan_attack(ready)))

@unsafe
def oracle_case(label: String,world: Terrain.Terrain.World,pid: U32) -> IO(Unit): oracle_ready(label,Fight.LiveCombat.prepare(world,Combat.Combat.Attack{},pid,60))

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- snapshot_case("live attack forwards complete snapshots",CT.fixture_world([CT.fixture_player(2,0,0,7)],[Old.creature(9,2,0,1,6,4,100,0),Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0)],1),2,Fight.LiveCombat.Plan{[Battle.Battle.Input{7,2,Pay.Payout.Plan{2,41,17,200,1,3,7,35,7,4,0}}],Fight.LiveCombat.Attack{0,6,4,3,7,0}})
    Unit <- snapshot_case("live attack selects later player",CT.fixture_world([CT.fixture_player(3,0,0,99),CT.fixture_player(2,0,0,7)],[Old.creature(9,2,0,1,6,4,100,0),Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0)],1),2,Fight.LiveCombat.Plan{[Battle.Battle.Input{7,2,Pay.Payout.Plan{2,41,17,200,1,3,7,35,7,4,0}}],Fight.LiveCombat.Attack{0,6,4,3,7,0}})
    Unit <- snapshot_case("live attack selects first duplicate PID",CT.fixture_world([CT.fixture_player(2,0,0,7),CT.fixture_player(2,0,0,99)],[Old.creature(9,2,0,1,6,4,100,0),Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0)],1),2,Fight.LiveCombat.Plan{[Battle.Battle.Input{7,2,Pay.Payout.Plan{2,41,17,200,1,3,7,35,7,4,0}}],Fight.LiveCombat.Attack{0,6,4,3,7,0}})
    Unit <- snapshot_case("live attack preserves MAX spin cooldown",CT.fixture_world([CT.fixture_player(2,0,0,4294967295)],[Old.creature(9,2,0,1,6,4,100,0),Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0)],1),2,Fight.LiveCombat.Plan{[Battle.Battle.Input{7,2,Pay.Payout.Plan{2,41,17,200,1,3,7,35,4294967295,4,0}}],Fight.LiveCombat.Attack{0,6,4,3,7,0}})
    Unit <- snapshot_case("live attack forwards critical word",CT.fixture_world([CT.fixture_player(3,0,0,7)],[Old.creature(9,2,0,1,6,4,100,0),Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0)],1),3,Fight.LiveCombat.Plan{[Battle.Battle.Input{7,3,Pay.Payout.Plan{3,41,17,200,1,3,7,35,7,4,1}}],Fight.LiveCombat.Attack{0,6,4,3,7,1}})
    Unit <- snapshot_case("live attack zero actor ID",CT.fixture_world([CT.fixture_player(0,0,0,7)],[Old.creature(9,2,0,1,6,4,100,0),Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0)],1),0,Fight.LiveCombat.Plan{[Battle.Battle.Input{7,0,Pay.Payout.Plan{0,41,17,200,1,3,7,35,7,4,0}}],Fight.LiveCombat.Attack{0,6,4,3,7,0}})
    Unit <- snapshot_case("live attack MAX actor ID",CT.fixture_world([CT.fixture_player(4294967295,0,0,7)],[Old.creature(9,2,0,1,6,4,100,0),Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0)],1),4294967295,Fight.LiveCombat.Plan{[Battle.Battle.Input{7,4294967295,Pay.Payout.Plan{4294967295,41,17,200,1,3,7,35,7,4,1}}],Fight.LiveCombat.Attack{0,6,4,3,7,1}})
    Unit <- snapshot_case("live attack forwards boundary metadata",Terrain.Terrain.World{S.Simulation.Meta{1,4294967295,0,4294967295,100,0,0,19,51,450},[CT.fixture_player(2,0,0,7)],[Old.creature(9,2,0,1,6,4,100,0),Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0)],[]},2,Fight.LiveCombat.Plan{[Battle.Battle.Input{7,2,Pay.Payout.Plan{2,0,4294967295,0,1,3,7,35,7,4,0}}],Fight.LiveCombat.Attack{0,6,4,3,7,0}})
    Unit <- quiet_case("live attack missing actor",CT.fixture_world([CT.fixture_player(2,0,0,7)],[Old.creature(9,2,0,1,6,4,100,0),Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0)],1),99)
    Unit <- quiet_case("live attack empty players",CT.fixture_world([],[Old.creature(9,2,0,1,6,4,100,0),Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0)],1),2)
    Unit <- quiet_case("live attack dead actor",CT.fixture_world([CT.fixture_player(2,1,0,0)],[Old.creature(9,2,0,1,6,4,100,0),Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0)],1),2)
    Unit <- quiet_case("live attack cooling actor",CT.fixture_world([CT.fixture_player(2,0,1,0)],[Old.creature(9,2,0,1,6,4,100,0),Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0)],1),2)
    Unit <- quiet_case("live attack ended phase",CT.fixture_world([CT.fixture_player(2,0,0,0)],[Old.creature(9,2,0,1,6,4,100,0),Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0)],2),2)
    Unit <- quiet_case("live attack distant MID zero is a miss",CT.fixture_world([CT.fixture_player(2,0,0,0)],[Old.creature(0,0,0,0,20,4,100,0)],1),2)
    Unit <- quiet_case("live attack empty targets are quiet",CT.fixture_world([CT.fixture_player(2,0,0,0)],[],1),2)
    Unit <- snapshot_case("live attack selects eligible MID zero",CT.fixture_world([CT.fixture_player(2,0,0,7)],[Old.creature(0,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0)],1),2,Fight.LiveCombat.Plan{[Battle.Battle.Input{0,2,Pay.Payout.Plan{2,41,17,200,1,2,0,35,7,4,0}}],Fight.LiveCombat.Attack{0,6,4,3,0,0}})
    Unit <- oracle_case("live attack previous planner snapshots",CT.fixture_world([CT.fixture_player(2,0,0,7)],[Old.creature(9,2,0,1,6,4,100,0),Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0)],1),2)
    Unit <- oracle_case("live attack previous planner different critical roll",CT.fixture_world([CT.fixture_player(3,0,0,7)],[Old.creature(9,2,0,1,6,4,100,0),Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0)],1),3)
    Unit <- oracle_case("live attack previous planner empty targets",CT.fixture_world([CT.fixture_player(2,0,0,0)],[],1),2)
    Unit <- oracle_case("live attack previous planner rejected",CT.fixture_world([CT.fixture_player(2,0,0,7)],[Old.creature(9,2,0,1,6,4,100,0),Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0)],1),99)
    Unit <- oracle_case("live attack previous planner duplicate monster IDs",CT.fixture_world([CT.fixture_player(2,0,0,0)],[Old.creature(7,0,0,0,6,4,100,0),Old.creature(7,9,1,0,7,4,100,0)],1),2)
    Unit <- oracle_case("live attack previous planner distant MID zero",CT.fixture_world([CT.fixture_player(2,0,0,0)],[Old.creature(0,0,0,0,20,4,100,0)],1),2)
    Unit <- oracle_case("live attack previous planner boundary metadata",Terrain.Terrain.World{S.Simulation.Meta{1,4294967295,0,4294967295,100,0,0,19,51,450},[CT.fixture_player(2,0,0,7)],[Old.creature(9,2,0,1,6,4,100,0),Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0)],[]},2)
    Unit <- oracle_ready("live attack previous planner command PID",Fight.LiveCombat.Ready{CT.fixture_meta(1),[Old.creature(9,2,0,1,6,4,100,0),Old.creature(7,0,0,0,6,4,100,0),Old.creature(8,9,1,0,7,4,100,0)],[],Combat.Combat.Result{[CT.fixture_player(2,0,4,7)],Some{CT.fixture_player(2,0,4,7)}},99,60})
    return Unit{}

#| PASS live attack forwards complete snapshots
#| PASS live attack selects later player
#| PASS live attack selects first duplicate PID
#| PASS live attack preserves MAX spin cooldown
#| PASS live attack forwards critical word
#| PASS live attack zero actor ID
#| PASS live attack MAX actor ID
#| PASS live attack forwards boundary metadata
#| PASS live attack missing actor
#| PASS live attack empty players
#| PASS live attack dead actor
#| PASS live attack cooling actor
#| PASS live attack ended phase
#| PASS live attack distant MID zero is a miss
#| PASS live attack empty targets are quiet
#| PASS live attack selects eligible MID zero
#| PASS live attack previous planner snapshots
#| PASS live attack previous planner different critical roll
#| PASS live attack previous planner empty targets
#| PASS live attack previous planner rejected
#| PASS live attack previous planner duplicate monster IDs
#| PASS live attack previous planner distant MID zero
#| PASS live attack previous planner boundary metadata
#| PASS live attack previous planner command PID
