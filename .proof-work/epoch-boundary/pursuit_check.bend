import Base
import ./pursuit.bend as Q
import ./terrain.bend as T
import ./terrain_check.bend as TT
import ./landscape.bend as L
import ./players.bend as P
import ./monsters.bend as M
import ./ai.bend as A
import ./world.bend as W
import ./players_check.bend as Test

def origin() -> P.Players.Pos: P.Players.Pos{0,13,4,0,0}
def right_wall() -> T.Terrain.Maps: [L.Landscape.set(TT.filled(510n,0),134n,2)]
def down_wall() -> T.Terrain.Maps: [L.Landscape.set(TT.filled(510n,0),163n,2)]
def both_walls() -> T.Terrain.Maps: [L.Landscape.set(L.Landscape.set(TT.filled(510n,0),134n,2),163n,2)]
def monster(attack: U32) -> M.Monsters.State: M.Monsters.State{7,0,0,0,13,4,20,20,99,attack,0,0}

def same_plan(a: A.AI.Plan,b: A.AI.Plan) -> Bool:
  match a:
    case A.AI.Rest{}:
      match b:
        case A.AI.Rest{}: True{}
        case A.AI.Move{x,y,t}: False{}
        case A.AI.Attack{t,d}: False{}
        case A.AI.Spawn{k,r,x,y,m}: False{}
    case A.AI.Move{x,y,t}:
      match b:
        case A.AI.Rest{}: False{}
        case A.AI.Move{bx,by,bt}: Bool.and(U32.is_eq(x,bx),Bool.and(U32.is_eq(y,by),U32.is_eq(t,bt)))
        case A.AI.Attack{t,d}: False{}
        case A.AI.Spawn{k,r,x,y,m}: False{}
    case A.AI.Attack{t,d}:
      match b:
        case A.AI.Rest{}: False{}
        case A.AI.Move{x,y,t}: False{}
        case A.AI.Attack{bt,bd}: Bool.and(U32.is_eq(t,bt),U32.is_eq(d,bd))
        case A.AI.Spawn{k,r,x,y,m}: False{}
    case A.AI.Spawn{k,r,x,y,m}:
      match b:
        case A.AI.Rest{}: False{}
        case A.AI.Move{x,y,t}: False{}
        case A.AI.Attack{t,d}: False{}
        case A.AI.Spawn{bk,br,bx,by,bm}: Bool.and(U32.is_eq(k,bk),Bool.and(U32.is_eq(r,br),Bool.and(U32.is_eq(x,bx),Bool.and(U32.is_eq(y,by),U32.is_eq(m,bm)))))

def check_pos(label: String,actual: P.Players.Pos,x: U32,y: U32) -> IO(Unit):
  Test.verdict(label,Test.same_pos(actual,P.Players.Pos{0,x,y,0,0}))

def check_plan(label: String,actual: A.AI.Plan,expected: A.AI.Plan) -> IO(Unit):
  Test.verdict(label,same_plan(actual,expected))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- check_pos("horizontal chase wins equal-axis tie",Q.Pursuit.toward(TT.open_maps,origin,15,6),14,4)
    Unit <- check_pos("vertical chase wins larger distance",Q.Pursuit.toward(TT.open_maps,origin,14,7),13,5)
    Unit <- check_pos("blocked horizontal chase tries vertical",Q.Pursuit.toward(right_wall,origin,15,6),13,5)
    Unit <- check_pos("blocked vertical chase tries horizontal",Q.Pursuit.toward(down_wall,origin,14,7),14,4)
    Unit <- check_pos("both blocked chase axes retain position",Q.Pursuit.toward(both_walls,origin,15,6),13,4)
    Unit <- check_pos("same target position retains position",Q.Pursuit.toward(TT.open_maps,origin,13,4),13,4)
    Unit <- check_pos("horizontal wall with no vertical distance retains position",Q.Pursuit.toward(right_wall,origin,15,4),13,4)
    Unit <- check_pos("chase cannot enter village",Q.Pursuit.toward(TT.open_maps,origin,11,4),13,4)
    Unit <- check_pos("huge target coordinates still move one tile",Q.Pursuit.toward(TT.open_maps,origin,4294967295,2147483648),14,4)
    Unit <- check_plan("inactive wander clears target",Q.Pursuit.wander(False{},TT.open_maps,origin,1),A.AI.Move{13,4,0})
    Unit <- check_plan("active wander commits cardinal move",Q.Pursuit.wander(True{},TT.open_maps,origin,1),A.AI.Move{14,4,0})
    Unit <- check_plan("ready adjacent plan carries target and damage",Q.Pursuit.plan(TT.open_maps,monster(0),Q.Pursuit.Target{3,14,5,True{}},0,9),A.AI.Attack{3,9})
    Unit <- check_plan("cooling adjacent plan retains position and target",Q.Pursuit.plan(TT.open_maps,monster(1),Q.Pursuit.Target{3,14,5,True{}},0,9),A.AI.Move{13,4,3})
    Unit <- check_plan("chase runs on scheduled tick",Q.Pursuit.plan(TT.open_maps,monster(0),Q.Pursuit.Target{3,19,4,True{}},1,9),A.AI.Move{14,4,3})
    Unit <- check_plan("chase waits on alternate tick",Q.Pursuit.plan(TT.open_maps,monster(0),Q.Pursuit.Target{3,19,4,True{}},0,9),A.AI.Move{13,4,3})
    Unit <- check_plan("missing target clears previous target",Q.Pursuit.plan(TT.open_maps,monster(0),Q.Pursuit.Target{99,19,4,False{}},0,9),A.AI.Move{13,4,0})
    Unit <- check_plan("wrapped tick preserves chase schedule",Q.Pursuit.plan(TT.open_maps,monster(0),Q.Pursuit.Target{3,19,4,True{}},4294967295,9),A.AI.Move{14,4,3})
    Unit <- check_plan("server AI uses checked active chase",W.Bq.ai_plan(monster(0),[Tuple{3,Tuple{16,4}}],TT.open_maps,1),A.AI.Move{14,4,3})
    Unit <- check_plan("server AI uses checked adjacent attack",W.Bq.ai_plan(monster(0),[Tuple{3,Tuple{14,4}}],TT.open_maps,0),A.AI.Attack{3,4})
    return Unit{}

#| PASS horizontal chase wins equal-axis tie
#| PASS vertical chase wins larger distance
#| PASS blocked horizontal chase tries vertical
#| PASS blocked vertical chase tries horizontal
#| PASS both blocked chase axes retain position
#| PASS same target position retains position
#| PASS horizontal wall with no vertical distance retains position
#| PASS chase cannot enter village
#| PASS huge target coordinates still move one tile
#| PASS inactive wander clears target
#| PASS active wander commits cardinal move
#| PASS ready adjacent plan carries target and damage
#| PASS cooling adjacent plan retains position and target
#| PASS chase runs on scheduled tick
#| PASS chase waits on alternate tick
#| PASS missing target clears previous target
#| PASS wrapped tick preserves chase schedule
#| PASS server AI uses checked active chase
#| PASS server AI uses checked adjacent attack
