import Base
import ./main.bend as Application
import ./world.bend as W
import ./combat_targets.bend as T
import ./target_plans.bend as TP
import ./combat.bend as Combat
import ./live_combat.bend as Fight
import ./live_combat_check.bend as Live
import ./terrain.bend as Terrain
import ./players.bend as P
import ./monsters.bend as M
import ./roster.bend as R
import ./compat.bend as C
import ./support.bend as Support
import ./players_check.bend as Test
import ./combat_check.bend as CT
import ./ai_check.bend as MT

law Previous.chdist:
  (@+ax_0: U32 -> (@+ay_1: U32 -> (@+bx_2: U32 -> (@+by_3: U32 -> U32))))

law Previous.mids_in_reach:
  (@+ms_0: List<&2, W.Bq.Mob> -> (@+z_1: U32 -> (@+x_2: U32 -> (@+y_3: U32 -> List<&1, U32>))))

law Previous.mob_in_reach:
  (@+ms_0: List<&2, W.Bq.Mob> -> (@+z_1: U32 -> (@+x_2: U32 -> (@+y_3: U32 -> U32))))

@unsafe
def Previous.chdist():
  (ax_0 => (ay_1 => (bx_2 => (by_3 => (+dx_4 = (Support.Bq.U32.max(ax_0, bx_2) - Support.Bq.U32.min(ax_0, bx_2) : U32); (+dy_5 = (Support.Bq.U32.max(ay_1, by_3) - Support.Bq.U32.min(ay_1, by_3) : U32); Support.Bq.U32.max(dx_4, dy_5)))))))

@unsafe
def Previous.mids_in_reach():
  \{Nil: (z_0 => (x_1 => (y_2 => Nil{}))); \{Con: \{M.Monsters.State: (mid_0 => (kind_1 => (rare_2 => (zone_3 => (mx_4 => (my_5 => (hp_6 => (mhp_7 => (tgt_8 => (atkcd_9 => (dead_10 => (resp_11 => (rest_12 => (z_13 => (x_14 => (y_15 => (+apply_130 = {(rest_0 => (z_1 => (x_2 => (y_3 => (mid_4 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => Previous.mids_in_reach(rest_0, z_1, x_2, y_3)), (_613_5 => Con{mid_4, Previous.mids_in_reach(rest_0, z_1, x_2, y_3)}), 0))))))) : (@+rest_0: List<&2, W.Bq.Mob> -> (@+z_1: U32 -> (@+x_2: U32 -> (@+y_3: U32 -> (@+mid_4: U32 -> (@+___5: U32 -> List<&1, U32>))))))}; apply_130(rest_12, z_13, x_14, y_15, mid_0, C.Bq.word_and(C.Bq.word_and(C.Bq.bit(U32.is_eq(zone_3, z_13)), C.Bq.bit(U32.is_eq(dead_10, 0))), C.Bq.bit(U32.is_le(Previous.chdist(mx_4, my_5, x_14, y_15), 1))))))))))))))))))))); \{}}; \{}}}

@unsafe
def Previous.mob_in_reach():
  \{Nil: (z_0 => (x_1 => (y_2 => 0))); \{Con: \{M.Monsters.State: (mid_0 => (kind_1 => (rare_2 => (zone_3 => (mx_4 => (my_5 => (hp_6 => (mhp_7 => (tgt_8 => (atkcd_9 => (dead_10 => (resp_11 => (rest_12 => (z_13 => (x_14 => (y_15 => (+apply_311 = {(rest_0 => (z_1 => (x_2 => (y_3 => (mid_4 => (word => C.Bq.word_case(U32, word, 0, (unit => Previous.mob_in_reach(rest_0, z_1, x_2, y_3)), (_593_5 => mid_4), 0))))))) : (@+rest_0: List<&2, W.Bq.Mob> -> (@+z_1: U32 -> (@+x_2: U32 -> (@+y_3: U32 -> (@+mid_4: U32 -> (@+___5: U32 -> U32))))))}; apply_311(rest_12, z_13, x_14, y_15, mid_0, C.Bq.word_and(C.Bq.word_and(C.Bq.bit(U32.is_eq(zone_3, z_13)), C.Bq.bit(U32.is_eq(dead_10, 0))), C.Bq.bit(U32.is_le(Previous.chdist(mx_4, my_5, x_14, y_15), 1))))))))))))))))))))); \{}}; \{}}}

def same_ids(a: List<&1,U32>,b: List<&1,U32>) -> Bool:
  match a:
    case Nil{}:
      match b:
        case Nil{}: True{}
        case Con{head,rest}: False{}
    case Con{head,rest}:
      match b:
        case Nil{}: False{}
        case Con{other,later}: Bool.and(U32.is_eq(head,other),same_ids(rest,later))

def same_found(a: Maybe<&2,M.Monsters.State>,b: Maybe<&2,M.Monsters.State>) -> Bool:
  match a:
    case None{}:
      match b:
        case None{}: True{}
        case Some{monster}: False{}
    case Some{monster}:
      match b:
        case None{}: False{}
        case Some{other}: MT.same_monster(monster,other)

@unsafe
def distance_case(label: String,+ax: U32,+ay: U32,+bx: U32,+by: U32,+expected: U32) -> IO(Unit):
  Test.verdict(label,Bool.and(U32.is_eq(T.Targets.distance(ax,ay,bx,by),expected),Bool.and(U32.is_eq(W.Bq.chdist(ax,ay,bx,by),expected),U32.is_eq(Previous.chdist(ax,ay,bx,by),expected))))

@unsafe
def selection_case(label: String,+monsters: List<&2,M.Monsters.State>,point: T.Targets.Point,+expected: List<&2,M.Monsters.State>) -> IO(Unit):
  match point:
    case T.Targets.Point{zone,x,y}:
      +zone = zone
      +x = x
      +y = y
      Test.verdict(label,Bool.and(MT.same_list(T.Targets.filter(monsters,T.Targets.Point{zone,x,y}),expected),Bool.and(same_found(T.Targets.first(monsters,T.Targets.Point{zone,x,y}),T.Targets.head(expected)),Bool.and(same_ids(W.Bq.mids_in_reach(monsters,zone,x,y),T.Targets.ids(expected)),Bool.and(same_ids(Previous.mids_in_reach(monsters,zone,x,y),T.Targets.ids(expected)),Bool.and(U32.is_eq(W.Bq.mob_in_reach(monsters,zone,x,y),T.Targets.found_id(T.Targets.head(expected))),U32.is_eq(Previous.mob_in_reach(monsters,zone,x,y),T.Targets.found_id(T.Targets.head(expected)))))))))

def creature(mid: U32,zone: U32,x: U32,y: U32,dead: U32) -> M.Monsters.State:
  M.Monsters.State{mid,2,1,zone,x,y,100,123,55,7,dead,29}

@unsafe
def miss_case(label: String,+monsters: List<&2,M.Monsters.State>) -> IO(Unit):
  Test.verdict(label,Live.Output.same_result(W.Bq.cmd_atk(CT.fixture_world([CT.fixture_player(2,0,0,0)],monsters,1),2),Tuple{CT.fixture_world([CT.fixture_player(2,0,4,0)],monsters,1),Nil{}}))

@unsafe
def prior_zero_bug() -> IO(Unit):
  Test.verdict("target ID zero miss exposes prior unintended damage",Bool.not(Live.Output.same_result(Live.Previous.cmd_atk(CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(0,0,20,10,0)],1),2),Tuple{CT.fixture_world([CT.fixture_player(2,0,4,0)],[creature(0,0,20,10,0)],1),Nil{}})))

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- distance_case("target distance origin",0,0,0,0,0)
    Unit <- distance_case("target distance same MAX",4294967295,4294967295,4294967295,4294967295,0)
    Unit <- distance_case("target distance east",6,4,7,4,1)
    Unit <- distance_case("target distance west",6,4,5,4,1)
    Unit <- distance_case("target distance north",6,4,6,3,1)
    Unit <- distance_case("target distance south",6,4,6,5,1)
    Unit <- distance_case("target distance diagonal",6,4,7,5,1)
    Unit <- distance_case("target distance two cells",6,4,8,4,2)
    Unit <- distance_case("target distance asymmetric axes",10,1,3,5,7)
    Unit <- distance_case("target distance reverse axes",3,5,10,1,7)
    Unit <- distance_case("target distance MAX delta",0,0,4294967295,0,4294967295)
    Unit <- distance_case("target distance reverse MAX delta",4294967295,0,0,0,4294967295)
    Unit <- distance_case("target distance MAX adjacent",4294967295,4294967295,4294967294,4294967295,1)
    Unit <- distance_case("target distance MAX diagonal",4294967294,4294967294,4294967295,4294967295,1)
    Unit <- selection_case("target selection empty",[],T.Targets.Point{0,6,4},[])
    Unit <- selection_case("target selection same cell",[creature(7,0,6,4,0)],T.Targets.Point{0,6,4},[creature(7,0,6,4,0)])
    Unit <- selection_case("target selection east",[creature(7,0,7,4,0)],T.Targets.Point{0,6,4},[creature(7,0,7,4,0)])
    Unit <- selection_case("target selection west",[creature(7,0,5,4,0)],T.Targets.Point{0,6,4},[creature(7,0,5,4,0)])
    Unit <- selection_case("target selection north",[creature(7,0,6,3,0)],T.Targets.Point{0,6,4},[creature(7,0,6,3,0)])
    Unit <- selection_case("target selection south",[creature(7,0,6,5,0)],T.Targets.Point{0,6,4},[creature(7,0,6,5,0)])
    Unit <- selection_case("target selection diagonal",[creature(7,0,7,5,0)],T.Targets.Point{0,6,4},[creature(7,0,7,5,0)])
    Unit <- selection_case("target selection outside east",[creature(7,0,8,4,0)],T.Targets.Point{0,6,4},[])
    Unit <- selection_case("target selection outside west",[creature(7,0,4,4,0)],T.Targets.Point{0,6,4},[])
    Unit <- selection_case("target selection outside north",[creature(7,0,6,2,0)],T.Targets.Point{0,6,4},[])
    Unit <- selection_case("target selection outside south",[creature(7,0,6,6,0)],T.Targets.Point{0,6,4},[])
    Unit <- selection_case("target selection wrong zone",[creature(7,1,6,4,0)],T.Targets.Point{0,6,4},[])
    Unit <- selection_case("target selection dead",[creature(7,0,6,4,1)],T.Targets.Point{0,6,4},[])
    Unit <- selection_case("target selection unknown dead word",[creature(7,0,6,4,4294967295)],T.Targets.Point{0,6,4},[])
    Unit <- selection_case("target selection MAX coordinate",[creature(7,0,4294967295,4,0)],T.Targets.Point{0,6,4},[])
    Unit <- selection_case("target selection source order",[creature(9,0,6,4,0),creature(7,0,6,4,0),creature(8,0,6,4,0)],T.Targets.Point{0,6,4},[creature(9,0,6,4,0),creature(7,0,6,4,0),creature(8,0,6,4,0)])
    Unit <- selection_case("target selection mixed rejection",[creature(3,1,6,4,0),creature(9,0,6,4,0),creature(4,0,6,4,1),creature(7,0,6,4,0),creature(5,0,9,4,0)],T.Targets.Point{0,6,4},[creature(9,0,6,4,0),creature(7,0,6,4,0)])
    Unit <- selection_case("target selection all rejected",[creature(7,1,6,4,0),creature(8,0,6,4,1),creature(9,0,10,4,0)],T.Targets.Point{0,6,4},[])
    Unit <- selection_case("target selection duplicate records",[creature(7,0,6,4,0),creature(7,0,6,4,0)],T.Targets.Point{0,6,4},[creature(7,0,6,4,0),creature(7,0,6,4,0)])
    Unit <- selection_case("target selection duplicate IDs retain full records",[creature(7,0,5,4,0),creature(7,0,7,4,0)],T.Targets.Point{0,6,4},[creature(7,0,5,4,0),creature(7,0,7,4,0)])
    Unit <- selection_case("target selection zero ID present",[creature(0,0,6,4,0)],T.Targets.Point{0,6,4},[creature(0,0,6,4,0)])
    Unit <- selection_case("target selection zero ID absent",[creature(0,0,20,4,0)],T.Targets.Point{0,6,4},[])
    Unit <- selection_case("target selection zero ID then real target",[creature(0,0,20,4,0),creature(9,0,6,4,0)],T.Targets.Point{0,6,4},[creature(9,0,6,4,0)])
    Unit <- selection_case("target selection MAX ID",[creature(4294967295,0,6,4,0)],T.Targets.Point{0,6,4},[creature(4294967295,0,6,4,0)])
    Unit <- selection_case("target selection zero boundary",[creature(7,0,0,0,0),creature(8,0,1,1,0),creature(9,0,4294967295,0,0)],T.Targets.Point{0,0,0},[creature(7,0,0,0,0),creature(8,0,1,1,0)])
    Unit <- selection_case("target selection MAX boundary",[creature(7,0,4294967295,4294967295,0),creature(8,0,4294967294,4294967294,0),creature(9,0,0,0,0)],T.Targets.Point{0,4294967295,4294967295},[creature(7,0,4294967295,4294967295,0),creature(8,0,4294967294,4294967294,0)])
    Unit <- selection_case("target selection arbitrary same zone",[creature(7,4294967295,6,4,0)],T.Targets.Point{4294967295,6,4},[creature(7,4294967295,6,4,0)])
    Unit <- miss_case("target attack miss empty",[])
    Unit <- miss_case("target attack miss distant ordinary",[creature(7,0,20,4,0)])
    Unit <- miss_case("target attack miss distant zero ID",[creature(0,0,20,4,0)])
    Unit <- miss_case("target attack miss wrong zone zero ID",[creature(0,1,6,4,0)])
    Unit <- miss_case("target attack miss dead zero ID",[creature(0,0,6,4,1)])
    Unit <- miss_case("target attack miss mixed rejected zero ID",[creature(0,0,20,4,0),creature(7,1,6,4,0),creature(8,0,6,4,1)])
    Unit <- prior_zero_bug()
    Unit <- Live.checked("target live attack zero selected",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(0,0,6,4,0)],1),2)
    Unit <- Live.checked("target live attack zero distant then eligible",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(0,0,20,4,0),creature(7,0,6,4,0)],1),2)
    Unit <- Live.checked("target live attack multiple eligible",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(9,0,6,4,0),creature(7,0,6,4,0),creature(8,0,6,4,0)],1),2)
    Unit <- Live.checked("target live attack mixed",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(3,1,6,4,0),creature(9,0,6,4,0),creature(4,0,6,4,1),creature(7,0,6,4,0)],1),2)
    Unit <- Live.checked("target live spin zero selected",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(0,0,6,4,0)],1),2)
    Unit <- Live.checked("target live spin zero distant then eligible",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(0,0,20,4,0),creature(7,0,6,4,0)],1),2)
    Unit <- Live.checked("target live spin multiple eligible",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(9,0,6,4,0),creature(7,0,6,4,0),creature(8,0,6,4,0)],1),2)
    Unit <- Live.checked("target live spin mixed",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(3,1,6,4,0),creature(9,0,6,4,0),creature(4,0,6,4,1),creature(7,0,6,4,0)],1),2)
    return Unit{}

#| PASS target distance origin
#| PASS target distance same MAX
#| PASS target distance east
#| PASS target distance west
#| PASS target distance north
#| PASS target distance south
#| PASS target distance diagonal
#| PASS target distance two cells
#| PASS target distance asymmetric axes
#| PASS target distance reverse axes
#| PASS target distance MAX delta
#| PASS target distance reverse MAX delta
#| PASS target distance MAX adjacent
#| PASS target distance MAX diagonal
#| PASS target selection empty
#| PASS target selection same cell
#| PASS target selection east
#| PASS target selection west
#| PASS target selection north
#| PASS target selection south
#| PASS target selection diagonal
#| PASS target selection outside east
#| PASS target selection outside west
#| PASS target selection outside north
#| PASS target selection outside south
#| PASS target selection wrong zone
#| PASS target selection dead
#| PASS target selection unknown dead word
#| PASS target selection MAX coordinate
#| PASS target selection source order
#| PASS target selection mixed rejection
#| PASS target selection all rejected
#| PASS target selection duplicate records
#| PASS target selection duplicate IDs retain full records
#| PASS target selection zero ID present
#| PASS target selection zero ID absent
#| PASS target selection zero ID then real target
#| PASS target selection MAX ID
#| PASS target selection zero boundary
#| PASS target selection MAX boundary
#| PASS target selection arbitrary same zone
#| PASS target attack miss empty
#| PASS target attack miss distant ordinary
#| PASS target attack miss distant zero ID
#| PASS target attack miss wrong zone zero ID
#| PASS target attack miss dead zero ID
#| PASS target attack miss mixed rejected zero ID
#| PASS target ID zero miss exposes prior unintended damage
#| PASS target live attack zero selected
#| PASS target live attack zero distant then eligible
#| PASS target live attack multiple eligible
#| PASS target live attack mixed
#| PASS target live spin zero selected
#| PASS target live spin zero distant then eligible
#| PASS target live spin multiple eligible
#| PASS target live spin mixed
