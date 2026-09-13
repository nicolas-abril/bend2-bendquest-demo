import Base
import ./terrain.bend as Terrain
import ./players.bend as P
import ./game.bend as G
import ./world.bend as W
import ./compat.bend as C
import ./players_check.bend as T
import ./interactions_check.bend as IT
import ./simulation_check.bend as ST
import ./combat_check.bend as CT

def filled(count: Nat,+tile: U32) -> Terrain.Terrain.Map:
  match count:
    case Zero{}: Nil{}
    case Succ{rest}: Con{tile,filled(rest,tile)}

def indices(count: Nat,+start: U32) -> Terrain.Terrain.Map:
  match count:
    case Zero{}: Nil{}
    case Succ{rest}: Con{start,indices(rest,U32.add(start,1))}

def open_maps() -> Terrain.Terrain.Maps:
  +map = filled(510n,0)
  [map,map,map,map]

def indexed_maps() -> Terrain.Terrain.Maps: [indices(510n,0)]
def blocked_outside() -> Terrain.Terrain.Maps: [Terrain.Terrain.concat(filled(134n,0),Con{2,filled(375n,0)})]

def blocked_right() -> Terrain.Terrain.Maps: [Terrain.Terrain.concat(filled(127n,0),Con{2,filled(382n,0)})]
def fixture_pos(zone: U32,x: U32,y: U32,dir: U32,moving: U32) -> P.Players.Pos: P.Players.Pos{zone,x,y,dir,moving}

def check_word(label: String,actual: U32,expected: U32) -> IO(Unit): T.verdict(label,U32.is_eq(actual,expected))
def check_pos(label: String,actual: P.Players.Pos,expected: P.Players.Pos) -> IO(Unit): T.verdict(label,T.same_pos(actual,expected))

def tiles_match(tiles: List<&2,U32>,+expected: Bool) -> Bool:
  match tiles:
    case Nil{}: True{}
    case Con{head,rest}: Bool.and(Bool.not(Bool.xor(Terrain.Terrain.walkable(head),expected)),tiles_match(rest,expected))

def check_xy(label: String,actual: C.Bq.Pair.Pair(U32,(x => U32)),x: U32,y: U32) -> IO(Unit):
  match actual:
    case Tuple{ax,ay}: T.verdict(label,Bool.and(U32.is_eq(ax,x),U32.is_eq(ay,y)))

def shared_world() -> Terrain.Terrain.World:
  Terrain.Terrain.World{CT.fixture_meta(1),[CT.fixture_player(2,0,0,0)],CT.fixture_mobs,open_maps}

def check_world(label: String,+world: Terrain.Terrain.World) -> IO(Unit):
  T.verdict(label,Bool.and(ST.same_state(Terrain.Terrain.simulation(world),Terrain.Terrain.simulation(shared_world)),IT.same_maps(Terrain.Terrain.maps(world),open_maps)))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- check_word("map lookup first cell",Terrain.Terrain.tile_at(indexed_maps,0,0,0),0)
    Unit <- check_word("map lookup last column",Terrain.Terrain.tile_at(indexed_maps,0,29,0),29)
    Unit <- check_word("map lookup next row",Terrain.Terrain.tile_at(indexed_maps,0,0,1),30)
    Unit <- check_word("map lookup last grid cell",Terrain.Terrain.tile_at(indexed_maps,0,29,16),509)
    Unit <- check_word("x outside grid cannot alias next row",Terrain.Terrain.tile_at(indexed_maps,0,30,0),2)
    Unit <- check_word("y outside grid is solid",Terrain.Terrain.tile_at(open_maps,0,0,17),2)
    Unit <- check_word("maximum x cannot wrap into a valid row",Terrain.Terrain.tile_at(open_maps,0,4294967295,1),2)
    Unit <- check_word("large y cannot wrap its row offset",Terrain.Terrain.tile_at(open_maps,0,0,2147483648),2)
    Unit <- check_word("invalid zone cannot read a fifth map",Terrain.Terrain.tile_at([filled(510n,0),filled(510n,0),filled(510n,0),filled(510n,0),filled(510n,0)],4,0,0),2)
    Unit <- check_word("maximum zone is solid",Terrain.Terrain.tile_at(open_maps,4294967295,0,0),2)
    Unit <- check_word("missing map is solid",Terrain.Terrain.tile_at([],0,0,0),2)
    Unit <- check_word("missing cell is solid",Terrain.Terrain.tile_at([[0]],0,1,0),2)
    Unit <- T.verdict("all six solid tile classes reject walking",tiles_match([2,3,5,7,8,11],False{}))
    Unit <- T.verdict("all other game tile classes allow walking",tiles_match([0,1,4,6,9,10,12,13,14,15],True{}))
    Unit <- T.verdict("shared map conversion retains all cells",IT.same_words(Terrain.Terrain.share(Terrain.Terrain.linear(indices(510n,0))),indices(510n,0)))
    Unit <- check_pos("left move changes only x",Terrain.Terrain.move(open_maps,fixture_pos(0,6,4,0,7)),fixture_pos(0,5,4,0,7))
    Unit <- check_pos("right move changes only x",Terrain.Terrain.move(open_maps,fixture_pos(0,6,4,1,7)),fixture_pos(0,7,4,1,7))
    Unit <- check_pos("up move changes only y",Terrain.Terrain.move(open_maps,fixture_pos(0,6,4,2,7)),fixture_pos(0,6,3,2,7))
    Unit <- check_pos("down move changes only y",Terrain.Terrain.move(open_maps,fixture_pos(0,6,4,3,7)),fixture_pos(0,6,5,3,7))
    Unit <- check_pos("legacy unknown direction still selects down",Terrain.Terrain.move(open_maps,fixture_pos(0,6,4,4294967295,7)),fixture_pos(0,6,5,4294967295,7))
    Unit <- check_pos("left boundary does not underflow",Terrain.Terrain.move(open_maps,fixture_pos(0,0,4,0,1)),fixture_pos(0,0,4,0,1))
    Unit <- check_pos("right boundary does not overflow",Terrain.Terrain.move(open_maps,fixture_pos(0,29,4,1,1)),fixture_pos(0,29,4,1,1))
    Unit <- check_pos("top boundary does not underflow",Terrain.Terrain.move(open_maps,fixture_pos(0,6,0,2,1)),fixture_pos(0,6,0,2,1))
    Unit <- check_pos("bottom boundary does not overflow",Terrain.Terrain.move(open_maps,fixture_pos(0,6,16,3,1)),fixture_pos(0,6,16,3,1))
    Unit <- check_pos("solid destination preserves complete position",Terrain.Terrain.move(blocked_right,fixture_pos(0,6,4,1,7)),fixture_pos(0,6,4,1,7))
    Unit <- check_pos("halted player does not walk",Terrain.Terrain.walk_if(open_maps,fixture_pos(0,6,4,1,0)),fixture_pos(0,6,4,1,0))
    Unit <- check_pos("nonzero moving flag walks",Terrain.Terrain.walk_if(open_maps,fixture_pos(0,6,4,1,4294967295)),fixture_pos(0,7,4,1,4294967295))
    Unit <- check_pos("monster cannot enter village boundary",Terrain.Terrain.mob_move(open_maps,fixture_pos(0,13,4,0,1)),fixture_pos(0,13,4,0,1))
    Unit <- check_pos("monster can approach outside village",Terrain.Terrain.mob_move(open_maps,fixture_pos(0,14,4,0,1)),fixture_pos(0,13,4,0,1))
    Unit <- check_pos("village restriction is local to Hollow",Terrain.Terrain.mob_move(open_maps,fixture_pos(1,13,4,0,1)),fixture_pos(1,12,4,0,1))
    Unit <- check_pos("monster collision still rejects solid tile",Terrain.Terrain.mob_move(blocked_outside,fixture_pos(0,13,4,1,1)),fixture_pos(0,13,4,1,1))
    Unit <- check_xy("server player movement uses checked map",W.Bq.move_plr_xy(open_maps,0,6,4,1),7,4)
    Unit <- check_xy("server player collision uses checked map",W.Bq.move_plr_xy(blocked_right,0,6,4,1),6,4)
    Unit <- check_xy("server monster movement honors village",W.Bq.mob_move_xy(open_maps,0,13,4,0),13,4)
    Unit <- check_xy("server halted movement preserves coordinates",W.Bq.walk_if(open_maps,0,6,4,1,0),6,4)
    Unit <- check_word("server tile lookup rejects row alias",W.Bq.tile_at(indexed_maps,0,30,0),2)
    Unit <- check_world("world reconstruction retains maps and full simulation",Terrain.Terrain.world(Terrain.Terrain.maps(shared_world),Terrain.Terrain.simulation(shared_world)))
    return Unit{}

#| PASS map lookup first cell
#| PASS map lookup last column
#| PASS map lookup next row
#| PASS map lookup last grid cell
#| PASS x outside grid cannot alias next row
#| PASS y outside grid is solid
#| PASS maximum x cannot wrap into a valid row
#| PASS large y cannot wrap its row offset
#| PASS invalid zone cannot read a fifth map
#| PASS maximum zone is solid
#| PASS missing map is solid
#| PASS missing cell is solid
#| PASS all six solid tile classes reject walking
#| PASS all other game tile classes allow walking
#| PASS shared map conversion retains all cells
#| PASS left move changes only x
#| PASS right move changes only x
#| PASS up move changes only y
#| PASS down move changes only y
#| PASS legacy unknown direction still selects down
#| PASS left boundary does not underflow
#| PASS right boundary does not overflow
#| PASS top boundary does not underflow
#| PASS bottom boundary does not overflow
#| PASS solid destination preserves complete position
#| PASS halted player does not walk
#| PASS nonzero moving flag walks
#| PASS monster cannot enter village boundary
#| PASS monster can approach outside village
#| PASS village restriction is local to Hollow
#| PASS monster collision still rejects solid tile
#| PASS server player movement uses checked map
#| PASS server player collision uses checked map
#| PASS server monster movement honors village
#| PASS server halted movement preserves coordinates
#| PASS server tile lookup rejects row alias
#| PASS world reconstruction retains maps and full simulation
