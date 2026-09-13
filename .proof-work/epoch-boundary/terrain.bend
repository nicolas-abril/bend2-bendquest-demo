# Shared authoritative maps and tile-gated cardinal movement.
import Base
import ./zones.bend as Z
import ./game.bend as G
import ./players.bend as P
import ./monsters.bend as M
import ./simulation.bend as S
import ./navigation.bend as N
import ./numeric.bend as Num

def Terrain.Map() -> Data: List<&2,U32>
def Terrain.Maps() -> Data: List<&2,Terrain.Map>

# This is the actual server world, including the maps used for collision.
type Terrain.World is Data:
  Terrain.World{meta: S.Simulation.Meta,players: List<&2,P.Players.State>,monsters: List<&2,M.Monsters.State>,maps: Terrain.Maps}

def Terrain.share(map: List<&1,U32>) -> Terrain.Map:
  match map:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{head,Terrain.share(rest)}

def Terrain.linear(map: Terrain.Map) -> List<&1,U32>:
  match map:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{head,Terrain.linear(rest)}

law Terrain.share_roundtrip:
  for +map: Terrain.Map
  {Terrain.share(Terrain.linear(map)) == map : Terrain.Map}

def Terrain.share_roundtrip(map):
  match map:
    case Nil{}: {==}
    case Con{head,rest}:
      %Terrain.share_roundtrip(rest) : {Con{head,Terrain.share(Terrain.linear(rest))} == Con{head,_} : Terrain.Map}
      {==}

def Terrain.get(map: Terrain.Map,index: Nat,fallback: U32) -> U32:
  match map:
    case Nil{}: fallback
    case Con{head,rest}:
      match index:
        case Zero{}: head
        case Succ{next}: Terrain.get(rest,next,fallback)

def Terrain.zone(maps: Terrain.Maps,index: Nat) -> Terrain.Map:
  match maps:
    case Nil{}: Nil{}
    case Con{head,rest}:
      match index:
        case Zero{}: head
        case Succ{next}: Terrain.zone(rest,next)

def Terrain.map_of(maps: Terrain.Maps,zone: U32) -> Terrain.Map:
  Terrain.zone(maps,U32.to_nat(zone))

def Terrain.grid_ok(zone: U32,x: U32,y: U32) -> Bool:
  Bool.and(G.Bq.Nat.lt(U32.to_nat(zone),4n),Bool.and(G.Bq.Nat.lt(U32.to_nat(x),N.Navigation.width_nat),G.Bq.Nat.lt(U32.to_nat(y),N.Navigation.height_nat)))

def Terrain.offset(x: U32,y: U32) -> Nat:
  G.Bq.Nat.add(G.Bq.Nat.mul(U32.to_nat(y),N.Navigation.width_nat),U32.to_nat(x))

def Terrain.tile_gate(inside: Bool,maps: Terrain.Maps,zone: U32,x: U32,y: U32) -> U32:
  match inside:
    case False{}: 2
    case True{}: Terrain.get(Terrain.map_of(maps,zone),Terrain.offset(x,y),2)

def Terrain.tile_at(maps: Terrain.Maps,+zone: U32,+x: U32,+y: U32) -> U32:
  Terrain.tile_gate(Terrain.grid_ok(zone,x,y),maps,zone,x,y)

# Tree, water, rock, cave wall, crystal, and snow tree are solid.
def Terrain.walkable(+tile: U32) -> Bool:
  Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(U32.is_ne(tile,2),U32.is_ne(tile,3)),U32.is_ne(tile,5)),U32.is_ne(tile,7)),U32.is_ne(tile,8)),U32.is_ne(tile,11))

def Terrain.can_walk(maps: Terrain.Maps,+pos: P.Players.Pos) -> Bool:
  Terrain.walkable(Terrain.tile_at(maps,N.Navigation.zone(pos),N.Navigation.x(pos),N.Navigation.y(pos)))

type Terrain.On<-maps: Terrain.Maps,-pos: P.Players.Pos> is Data:
  Terrain.On{bounds: N.Navigation.Bounds<pos>,walkable: {Terrain.can_walk(maps,pos) == True{} : Bool}}

def Terrain.bounds(maps: Terrain.Maps,pos: P.Players.Pos,valid: Terrain.On<maps,pos>) -> N.Navigation.Bounds<pos>:
  match valid:
    case Terrain.On{bounds,walkable}: bounds

# Classify before constructing the direction, so native lowering does not
# need a Nat lookup table containing constructor-valued entries.
def Terrain.pick_direction(left: Bool,right: Bool,up: Bool) -> G.Bq.Dir:
  match left:
    case True{}: G.Bq.Dir.DL{}
    case False{}:
      match right:
        case True{}: G.Bq.Dir.DR{}
        case False{}:
          match up:
            case True{}: G.Bq.Dir.DU{}
            case False{}: G.Bq.Dir.DD{}

def Terrain.direction_nat(+direction: Nat) -> G.Bq.Dir:
  Terrain.pick_direction(G.Bq.Nat.lt(direction,1n),G.Bq.Nat.lt(direction,2n),G.Bq.Nat.lt(direction,3n))

def Terrain.direction_spec(direction: Nat) -> G.Bq.Dir:
  match direction:
    case Zero{}: G.Bq.Dir.DL{}
    case Succ{one}:
      match one:
        case Zero{}: G.Bq.Dir.DR{}
        case Succ{two}:
          match two:
            case Zero{}: G.Bq.Dir.DU{}
            case Succ{other}: G.Bq.Dir.DD{}

law Terrain.direction_exact:
  for +direction: Nat
  {Terrain.direction_nat(direction) == Terrain.direction_spec(direction) : G.Bq.Dir}

def Terrain.direction_exact(direction):
  match direction:
    case Zero{}: {==}
    case Succ{one}:
      match one:
        case Zero{}: {==}
        case Succ{two}:
          match two:
            case Zero{}: {==}
            case Succ{other}: {==}

def Terrain.direction(direction: U32) -> G.Bq.Dir:
  Terrain.direction_nat(U32.to_nat(direction))

def Terrain.next_x(pos: P.Players.Pos,dir: G.Bq.Dir) -> Nat:
  G.Bq.walk_x(N.Navigation.width_nat,U32.to_nat(N.Navigation.x(pos)),dir)

def Terrain.next_y(pos: P.Players.Pos,dir: G.Bq.Dir) -> Nat:
  G.Bq.walk_y(N.Navigation.height_nat,U32.to_nat(N.Navigation.y(pos)),dir)

def Terrain.propose_dir(pos: P.Players.Pos,+dir: G.Bq.Dir) -> P.Players.Pos:
  match pos:
    case P.Players.Pos{zone,x,y,heading,moving}:
      P.Players.Pos{zone,U32.from_nat(G.Bq.walk_x(N.Navigation.width_nat,U32.to_nat(x),dir)),U32.from_nat(G.Bq.walk_y(N.Navigation.height_nat,U32.to_nat(y),dir)),heading,moving}

def Terrain.propose(+pos: P.Players.Pos) -> P.Players.Pos:
  Terrain.propose_dir(pos,Terrain.direction(N.Navigation.direction(pos)))

def Terrain.choose(allowed: Bool,proposal: P.Players.Pos,original: P.Players.Pos) -> P.Players.Pos:
  match allowed:
    case False{}: original
    case True{}: proposal

def Terrain.move(maps: Terrain.Maps,+pos: P.Players.Pos) -> P.Players.Pos:
  +proposal = Terrain.propose(pos)
  Terrain.choose(Terrain.can_walk(maps,proposal),proposal,pos)

law Terrain.next_x_bound:
  for +pos: P.Players.Pos
  for +dir: G.Bq.Dir
  for +valid: N.Navigation.Bounds<pos>
  {G.Bq.Nat.lt(Terrain.next_x(pos,dir),N.Navigation.width_nat) == True{} : Bool}

def Terrain.next_x_bound(pos,dir,valid):
  match valid:
    case N.Navigation.Bounds{zone,x,y}:
      G.Bq.Bool.and_l(G.Bq.Nat.lt(Terrain.next_x(pos,dir),N.Navigation.width_nat),G.Bq.Nat.lt(Terrain.next_y(pos,dir),N.Navigation.height_nat),G.Bq.walk_bounds_go(N.Navigation.width_nat,N.Navigation.height_nat,U32.to_nat(N.Navigation.x(pos)),U32.to_nat(N.Navigation.y(pos)),dir,x,y))

law Terrain.next_y_bound:
  for +pos: P.Players.Pos
  for +dir: G.Bq.Dir
  for +valid: N.Navigation.Bounds<pos>
  {G.Bq.Nat.lt(Terrain.next_y(pos,dir),N.Navigation.height_nat) == True{} : Bool}

def Terrain.next_y_bound(pos,dir,valid):
  match valid:
    case N.Navigation.Bounds{zone,x,y}:
      G.Bq.Bool.and_r(G.Bq.Nat.lt(Terrain.next_x(pos,dir),N.Navigation.width_nat),G.Bq.Nat.lt(Terrain.next_y(pos,dir),N.Navigation.height_nat),G.Bq.walk_bounds_go(N.Navigation.width_nat,N.Navigation.height_nat,U32.to_nat(N.Navigation.x(pos)),U32.to_nat(N.Navigation.y(pos)),dir,x,y))

law Terrain.next_x_fits:
  for +pos: P.Players.Pos
  for +dir: G.Bq.Dir
  for +valid: N.Navigation.Bounds<pos>
  Num.Numeric.Fits<32n,Terrain.next_x(pos,dir)>

def Terrain.next_x_fits(pos,dir,valid):
  Num.Numeric.fits_downward(32n,Terrain.next_x(pos,dir),30n,Num.Numeric.u32_value_fits(30),G.Bq.le_step_down(Terrain.next_x(pos,dir),30n,Terrain.next_x_bound(pos,dir,valid)))

law Terrain.next_y_fits:
  for +pos: P.Players.Pos
  for +dir: G.Bq.Dir
  for +valid: N.Navigation.Bounds<pos>
  Num.Numeric.Fits<32n,Terrain.next_y(pos,dir)>

def Terrain.next_y_fits(pos,dir,valid):
  Num.Numeric.fits_downward(32n,Terrain.next_y(pos,dir),17n,Num.Numeric.u32_value_fits(17),G.Bq.le_step_down(Terrain.next_y(pos,dir),17n,Terrain.next_y_bound(pos,dir,valid)))

law Terrain.propose_x_exact:
  for +pos: P.Players.Pos
  for +dir: G.Bq.Dir
  for +valid: N.Navigation.Bounds<pos>
  {U32.to_nat(N.Navigation.x(Terrain.propose_dir(pos,dir))) == Terrain.next_x(pos,dir) : Nat}

def Terrain.propose_x_exact(pos,dir,valid):
  match pos:
    case P.Players.Pos{zone,x,y,heading,moving}:
      Num.Numeric.u32_nat_roundtrip(Terrain.next_x(P.Players.Pos{zone,x,y,heading,moving},dir),Terrain.next_x_fits(P.Players.Pos{zone,x,y,heading,moving},dir,valid))

law Terrain.propose_y_exact:
  for +pos: P.Players.Pos
  for +dir: G.Bq.Dir
  for +valid: N.Navigation.Bounds<pos>
  {U32.to_nat(N.Navigation.y(Terrain.propose_dir(pos,dir))) == Terrain.next_y(pos,dir) : Nat}

def Terrain.propose_y_exact(pos,dir,valid):
  match pos:
    case P.Players.Pos{zone,x,y,heading,moving}:
      Num.Numeric.u32_nat_roundtrip(Terrain.next_y(P.Players.Pos{zone,x,y,heading,moving},dir),Terrain.next_y_fits(P.Players.Pos{zone,x,y,heading,moving},dir,valid))

law Terrain.propose_dir_bounds:
  for +pos: P.Players.Pos
  for +dir: G.Bq.Dir
  for +valid: N.Navigation.Bounds<pos>
  N.Navigation.Bounds<Terrain.propose_dir(pos,dir)>

def Terrain.propose_dir_bounds(pos,dir,valid):
  match pos:
    case P.Players.Pos{zone,x,y,heading,moving}:
      match valid:
        case N.Navigation.Bounds{zone_ok,x_ok,y_ok}:
          N.Navigation.Bounds{zone_ok,
            (%Equal.sym(Nat,U32.to_nat(U32.from_nat(Terrain.next_x(P.Players.Pos{zone,x,y,heading,moving},dir))),Terrain.next_x(P.Players.Pos{zone,x,y,heading,moving},dir),Terrain.propose_x_exact(P.Players.Pos{zone,x,y,heading,moving},dir,N.Navigation.Bounds{zone_ok,x_ok,y_ok})) : {G.Bq.Nat.lt(_,30n) == True{} : Bool}; Terrain.next_x_bound(P.Players.Pos{zone,x,y,heading,moving},dir,N.Navigation.Bounds{zone_ok,x_ok,y_ok})),
            (%Equal.sym(Nat,U32.to_nat(U32.from_nat(Terrain.next_y(P.Players.Pos{zone,x,y,heading,moving},dir))),Terrain.next_y(P.Players.Pos{zone,x,y,heading,moving},dir),Terrain.propose_y_exact(P.Players.Pos{zone,x,y,heading,moving},dir,N.Navigation.Bounds{zone_ok,x_ok,y_ok})) : {G.Bq.Nat.lt(_,17n) == True{} : Bool}; Terrain.next_y_bound(P.Players.Pos{zone,x,y,heading,moving},dir,N.Navigation.Bounds{zone_ok,x_ok,y_ok}))}

law Terrain.propose_bounds:
  for +pos: P.Players.Pos
  for +valid: N.Navigation.Bounds<pos>
  N.Navigation.Bounds<Terrain.propose(pos)>

def Terrain.propose_bounds(pos,valid): Terrain.propose_dir_bounds(pos,Terrain.direction(N.Navigation.direction(pos)),valid)

law Terrain.choose_bounds:
  for +allowed: Bool
  for +proposal: P.Players.Pos
  for +original: P.Players.Pos
  for +proposal_ok: N.Navigation.Bounds<proposal>
  for +original_ok: N.Navigation.Bounds<original>
  N.Navigation.Bounds<Terrain.choose(allowed,proposal,original)>

def Terrain.choose_bounds(allowed,proposal,original,proposal_ok,original_ok):
  match allowed:
    case False{}: original_ok
    case True{}: proposal_ok

law Terrain.move_bounds:
  for +maps: Terrain.Maps
  for +pos: P.Players.Pos
  for +valid: N.Navigation.Bounds<pos>
  N.Navigation.Bounds<Terrain.move(maps,pos)>

def Terrain.move_bounds(maps,pos,valid): Terrain.choose_bounds(Terrain.can_walk(maps,Terrain.propose(pos)),Terrain.propose(pos),pos,Terrain.propose_bounds(pos,valid),valid)

law Terrain.choose_on:
  for +allowed: Bool
  for +maps: Terrain.Maps
  for +proposal: P.Players.Pos
  for +original: P.Players.Pos
  for +proposal_ok: N.Navigation.Bounds<proposal>
  for +original_ok: Terrain.On<maps,original>
  for +decision: {Terrain.can_walk(maps,proposal) == allowed : Bool}
  Terrain.On<maps,Terrain.choose(allowed,proposal,original)>

def Terrain.choose_on(allowed,maps,proposal,original,proposal_ok,original_ok,decision):
  match allowed:
    case False{}: original_ok
    case True{}: Terrain.On{proposal_ok,decision}

law Terrain.move_on:
  for +maps: Terrain.Maps
  for +pos: P.Players.Pos
  for +valid: Terrain.On<maps,pos>
  Terrain.On<maps,Terrain.move(maps,pos)>

def Terrain.move_on(maps,pos,valid):
  Terrain.choose_on(Terrain.can_walk(maps,Terrain.propose(pos)),maps,Terrain.propose(pos),pos,Terrain.propose_bounds(pos,Terrain.bounds(maps,pos,valid)),valid,{==})

law Terrain.linear_roundtrip:
  for map: List<&1,U32>
  {Terrain.linear(Terrain.share(map)) == map : List<&1,U32>}

def Terrain.linear_roundtrip(map):
  match map:
    case Nil{}: {==}
    case Con{head,rest}:
      %Terrain.linear_roundtrip(rest) : {Con{head,Terrain.linear(Terrain.share(rest))} == Con{head,_} : List<&1,U32>}
      {==}

# Cardinal movement changes at most one coordinate by at most one tile.
type Terrain.Cardinal<-before: P.Players.Pos,-after: P.Players.Pos> is Data:
  Terrain.Horizontal{zone: {N.Navigation.zone(before) == N.Navigation.zone(after) : U32},y: {N.Navigation.y(before) == N.Navigation.y(after) : U32},x: {G.Bq.near(U32.to_nat(N.Navigation.x(before)),U32.to_nat(N.Navigation.x(after))) == True{} : Bool}}
  Terrain.Vertical{zone: {N.Navigation.zone(before) == N.Navigation.zone(after) : U32},x: {N.Navigation.x(before) == N.Navigation.x(after) : U32},y: {G.Bq.near(U32.to_nat(N.Navigation.y(before)),U32.to_nat(N.Navigation.y(after))) == True{} : Bool}}

law Terrain.propose_near_x:
  for +pos: P.Players.Pos
  for +dir: G.Bq.Dir
  for +valid: N.Navigation.Bounds<pos>
  {G.Bq.near(U32.to_nat(N.Navigation.x(pos)),U32.to_nat(N.Navigation.x(Terrain.propose_dir(pos,dir)))) == True{} : Bool}

def Terrain.propose_near_x(pos,dir,valid):
  %Equal.sym(Nat,U32.to_nat(N.Navigation.x(Terrain.propose_dir(pos,dir))),Terrain.next_x(pos,dir),Terrain.propose_x_exact(pos,dir,valid)) : {G.Bq.near(U32.to_nat(N.Navigation.x(pos)),_) == True{} : Bool}
  G.Bq.Bool.and_l(G.Bq.near(U32.to_nat(N.Navigation.x(pos)),Terrain.next_x(pos,dir)),G.Bq.near(U32.to_nat(N.Navigation.y(pos)),Terrain.next_y(pos,dir)),G.Bq.walk_is_adjacent(30n,17n,U32.to_nat(N.Navigation.x(pos)),U32.to_nat(N.Navigation.y(pos)),dir))

law Terrain.propose_near_y:
  for +pos: P.Players.Pos
  for +dir: G.Bq.Dir
  for +valid: N.Navigation.Bounds<pos>
  {G.Bq.near(U32.to_nat(N.Navigation.y(pos)),U32.to_nat(N.Navigation.y(Terrain.propose_dir(pos,dir)))) == True{} : Bool}

def Terrain.propose_near_y(pos,dir,valid):
  %Equal.sym(Nat,U32.to_nat(N.Navigation.y(Terrain.propose_dir(pos,dir))),Terrain.next_y(pos,dir),Terrain.propose_y_exact(pos,dir,valid)) : {G.Bq.near(U32.to_nat(N.Navigation.y(pos)),_) == True{} : Bool}
  G.Bq.Bool.and_r(G.Bq.near(U32.to_nat(N.Navigation.x(pos)),Terrain.next_x(pos,dir)),G.Bq.near(U32.to_nat(N.Navigation.y(pos)),Terrain.next_y(pos,dir)),G.Bq.walk_is_adjacent(30n,17n,U32.to_nat(N.Navigation.x(pos)),U32.to_nat(N.Navigation.y(pos)),dir))

law Terrain.propose_dir_cardinal:
  for +pos: P.Players.Pos
  for +dir: G.Bq.Dir
  for +valid: N.Navigation.Bounds<pos>
  Terrain.Cardinal<pos,Terrain.propose_dir(pos,dir)>

def Terrain.propose_dir_cardinal(pos,dir,valid):
  match pos:
    case P.Players.Pos{zone,x,y,heading,moving}:
      match dir:
        case G.Bq.Dir.DL{}:
          Terrain.Horizontal{{==},Equal.sym(U32,U32.from_nat(U32.to_nat(y)),y,Num.Numeric.u32_roundtrip(y)),Terrain.propose_near_x(P.Players.Pos{zone,x,y,heading,moving},G.Bq.Dir.DL{},valid)}
        case G.Bq.Dir.DR{}:
          Terrain.Horizontal{{==},Equal.sym(U32,U32.from_nat(U32.to_nat(y)),y,Num.Numeric.u32_roundtrip(y)),Terrain.propose_near_x(P.Players.Pos{zone,x,y,heading,moving},G.Bq.Dir.DR{},valid)}
        case G.Bq.Dir.DU{}:
          Terrain.Vertical{{==},Equal.sym(U32,U32.from_nat(U32.to_nat(x)),x,Num.Numeric.u32_roundtrip(x)),Terrain.propose_near_y(P.Players.Pos{zone,x,y,heading,moving},G.Bq.Dir.DU{},valid)}
        case G.Bq.Dir.DD{}:
          Terrain.Vertical{{==},Equal.sym(U32,U32.from_nat(U32.to_nat(x)),x,Num.Numeric.u32_roundtrip(x)),Terrain.propose_near_y(P.Players.Pos{zone,x,y,heading,moving},G.Bq.Dir.DD{},valid)}

law Terrain.propose_cardinal:
  for +pos: P.Players.Pos
  for +valid: N.Navigation.Bounds<pos>
  Terrain.Cardinal<pos,Terrain.propose(pos)>

def Terrain.propose_cardinal(pos,valid): Terrain.propose_dir_cardinal(pos,Terrain.direction(N.Navigation.direction(pos)),valid)

law Terrain.self_cardinal:
  for +pos: P.Players.Pos
  Terrain.Cardinal<pos,pos>

def Terrain.self_cardinal(pos): Terrain.Horizontal{{==},{==},G.Bq.near_self(U32.to_nat(N.Navigation.x(pos)))}

law Terrain.choose_cardinal:
  for +allowed: Bool
  for +proposal: P.Players.Pos
  for +original: P.Players.Pos
  for +adjacent: Terrain.Cardinal<original,proposal>
  Terrain.Cardinal<original,Terrain.choose(allowed,proposal,original)>

def Terrain.choose_cardinal(allowed,proposal,original,adjacent):
  match allowed:
    case False{}: Terrain.self_cardinal(original)
    case True{}: adjacent

law Terrain.move_cardinal:
  for +maps: Terrain.Maps
  for +pos: P.Players.Pos
  for +valid: N.Navigation.Bounds<pos>
  Terrain.Cardinal<pos,Terrain.move(maps,pos)>

def Terrain.move_cardinal(maps,pos,valid):
  Terrain.choose_cardinal(Terrain.can_walk(maps,Terrain.propose(pos)),Terrain.propose(pos),pos,Terrain.propose_cardinal(pos,valid))

law Terrain.move_rejected:
  for +maps: Terrain.Maps
  for +pos: P.Players.Pos
  for +blocked: {Terrain.can_walk(maps,Terrain.propose(pos)) == False{} : Bool}
  {Terrain.move(maps,pos) == pos : P.Players.Pos}

def Terrain.move_rejected(maps,pos,blocked):
  %Equal.sym(Bool,Terrain.can_walk(maps,Terrain.propose(pos)),False{},blocked) : {Terrain.choose(_,Terrain.propose(pos),pos) == pos : P.Players.Pos}
  {==}

law Terrain.move_accepted:
  for +maps: Terrain.Maps
  for +pos: P.Players.Pos
  for +walkable: {Terrain.can_walk(maps,Terrain.propose(pos)) == True{} : Bool}
  {Terrain.move(maps,pos) == Terrain.propose(pos) : P.Players.Pos}

def Terrain.move_accepted(maps,pos,walkable):
  %Equal.sym(Bool,Terrain.can_walk(maps,Terrain.propose(pos)),True{},walkable) : {Terrain.choose(_,Terrain.propose(pos),pos) == Terrain.propose(pos) : P.Players.Pos}
  {==}

def Terrain.moving(pos: P.Players.Pos) -> U32:
  match pos:
    case P.Players.Pos{zone,x,y,heading,moving}: moving

def Terrain.active(moving: Bool,maps: Terrain.Maps,+pos: P.Players.Pos) -> P.Players.Pos:
  match moving:
    case False{}: pos
    case True{}: Terrain.move(maps,pos)

def Terrain.walk_if(maps: Terrain.Maps,+pos: P.Players.Pos) -> P.Players.Pos:
  Terrain.active(U32.is_ne(Terrain.moving(pos),0),maps,pos)

law Terrain.active_on:
  for +moving: Bool
  for +maps: Terrain.Maps
  for +pos: P.Players.Pos
  for +valid: Terrain.On<maps,pos>
  Terrain.On<maps,Terrain.active(moving,maps,pos)>

def Terrain.active_on(moving,maps,pos,valid):
  match moving:
    case False{}: valid
    case True{}: Terrain.move_on(maps,pos,valid)

law Terrain.walk_if_on:
  for +maps: Terrain.Maps
  for +pos: P.Players.Pos
  for +valid: Terrain.On<maps,pos>
  Terrain.On<maps,Terrain.walk_if(maps,pos)>

def Terrain.walk_if_on(maps,pos,valid): Terrain.active_on(U32.is_ne(Terrain.moving(pos),0),maps,pos,valid)

law Terrain.active_bounds:
  for +moving: Bool
  for +maps: Terrain.Maps
  for +pos: P.Players.Pos
  for +valid: N.Navigation.Bounds<pos>
  N.Navigation.Bounds<Terrain.active(moving,maps,pos)>

def Terrain.active_bounds(moving,maps,pos,valid):
  match moving:
    case False{}: valid
    case True{}: Terrain.move_bounds(maps,pos,valid)

law Terrain.walk_if_bounds:
  for +maps: Terrain.Maps
  for +pos: P.Players.Pos
  for +valid: N.Navigation.Bounds<pos>
  N.Navigation.Bounds<Terrain.walk_if(maps,pos)>

def Terrain.walk_if_bounds(maps,pos,valid): Terrain.active_bounds(U32.is_ne(Terrain.moving(pos),0),maps,pos,valid)

law Terrain.active_cardinal:
  for +moving: Bool
  for +maps: Terrain.Maps
  for +pos: P.Players.Pos
  for +valid: N.Navigation.Bounds<pos>
  Terrain.Cardinal<pos,Terrain.active(moving,maps,pos)>

def Terrain.active_cardinal(moving,maps,pos,valid):
  match moving:
    case False{}: Terrain.self_cardinal(pos)
    case True{}: Terrain.move_cardinal(maps,pos,valid)

law Terrain.walk_if_cardinal:
  for +maps: Terrain.Maps
  for +pos: P.Players.Pos
  for +valid: N.Navigation.Bounds<pos>
  Terrain.Cardinal<pos,Terrain.walk_if(maps,pos)>

def Terrain.walk_if_cardinal(maps,pos,valid): Terrain.active_cardinal(U32.is_ne(Terrain.moving(pos),0),maps,pos,valid)

def Terrain.in_village(+pos: P.Players.Pos) -> Bool:
  Bool.and(Bool.and(Bool.and(Bool.and(U32.is_eq(N.Navigation.zone(pos),0),U32.is_ge(N.Navigation.x(pos),2)),U32.is_le(N.Navigation.x(pos),12)),U32.is_ge(N.Navigation.y(pos),3)),U32.is_le(N.Navigation.y(pos),9))

def Terrain.mob_move(maps: Terrain.Maps,+pos: P.Players.Pos) -> P.Players.Pos:
  +proposal = Terrain.move(maps,pos)
  Terrain.choose(Bool.not(Terrain.in_village(proposal)),proposal,pos)

law Terrain.select_on:
  for +allowed: Bool
  for +maps: Terrain.Maps
  for +proposal: P.Players.Pos
  for +original: P.Players.Pos
  for +proposal_ok: Terrain.On<maps,proposal>
  for +original_ok: Terrain.On<maps,original>
  Terrain.On<maps,Terrain.choose(allowed,proposal,original)>

def Terrain.select_on(allowed,maps,proposal,original,proposal_ok,original_ok):
  match allowed:
    case False{}: original_ok
    case True{}: proposal_ok

law Terrain.mob_move_on:
  for +maps: Terrain.Maps
  for +pos: P.Players.Pos
  for +valid: Terrain.On<maps,pos>
  Terrain.On<maps,Terrain.mob_move(maps,pos)>

def Terrain.mob_move_on(maps,pos,valid):
  Terrain.select_on(Bool.not(Terrain.in_village(Terrain.move(maps,pos))),maps,Terrain.move(maps,pos),pos,Terrain.move_on(maps,pos,valid),valid)

law Terrain.mob_move_bounds:
  for +maps: Terrain.Maps
  for +pos: P.Players.Pos
  for +valid: N.Navigation.Bounds<pos>
  N.Navigation.Bounds<Terrain.mob_move(maps,pos)>

def Terrain.mob_move_bounds(maps,pos,valid):
  Terrain.choose_bounds(Bool.not(Terrain.in_village(Terrain.move(maps,pos))),Terrain.move(maps,pos),pos,Terrain.move_bounds(maps,pos,valid),valid)

law Terrain.mob_move_cardinal:
  for +maps: Terrain.Maps
  for +pos: P.Players.Pos
  for +valid: N.Navigation.Bounds<pos>
  Terrain.Cardinal<pos,Terrain.mob_move(maps,pos)>

def Terrain.mob_move_cardinal(maps,pos,valid):
  Terrain.choose_cardinal(Bool.not(Terrain.in_village(Terrain.move(maps,pos))),Terrain.move(maps,pos),pos,Terrain.move_cardinal(maps,pos,valid))

def Terrain.simulation(world: Terrain.World) -> S.Simulation.State:
  match world:
    case Terrain.World{meta,players,monsters,maps}: S.Simulation.State{meta,players,monsters}

def Terrain.maps(world: Terrain.World) -> Terrain.Maps:
  match world:
    case Terrain.World{meta,players,monsters,maps}: maps

def Terrain.world(maps: Terrain.Maps,state: S.Simulation.State) -> Terrain.World:
  match state:
    case S.Simulation.State{meta,players,monsters}: Terrain.World{meta,players,monsters,maps}

law Terrain.world_roundtrip:
  for +world: Terrain.World
  {Terrain.world(Terrain.maps(world),Terrain.simulation(world)) == world : Terrain.World}

def Terrain.world_roundtrip(world):
  match world:
    case Terrain.World{meta,players,monsters,maps}: {==}

law Terrain.world_simulation:
  for +maps: Terrain.Maps
  for +state: S.Simulation.State
  {Terrain.simulation(Terrain.world(maps,state)) == state : S.Simulation.State}

def Terrain.world_simulation(maps,state):
  match state:
    case S.Simulation.State{meta,players,monsters}: {==}

law Terrain.world_maps:
  for +maps: Terrain.Maps
  for +state: S.Simulation.State
  {Terrain.maps(Terrain.world(maps,state)) == maps : Terrain.Maps}

def Terrain.world_maps(maps,state):
  match state:
    case S.Simulation.State{meta,players,monsters}: {==}

law Terrain.zone_inside:
  for +zone: U32
  for +valid: Z.Zones.Valid<zone>
  {G.Bq.Nat.lt(U32.to_nat(zone),4n) == True{} : Bool}

def Terrain.zone_inside(zone,valid):
  match valid:
    case Z.Zones.Hollow{equal}:
      %Equal.sym(U32,zone,0,equal) : {G.Bq.Nat.lt(U32.to_nat(_),4n) == True{} : Bool}
      {==}
    case Z.Zones.Cavern{equal}:
      %Equal.sym(U32,zone,1,equal) : {G.Bq.Nat.lt(U32.to_nat(_),4n) == True{} : Bool}
      {==}
    case Z.Zones.Frost{equal}:
      %Equal.sym(U32,zone,2,equal) : {G.Bq.Nat.lt(U32.to_nat(_),4n) == True{} : Bool}
      {==}
    case Z.Zones.Rift{equal}:
      %Equal.sym(U32,zone,3,equal) : {G.Bq.Nat.lt(U32.to_nat(_),4n) == True{} : Bool}
      {==}

law Terrain.and_true:
  for +a: Bool
  for +b: Bool
  for +left: {a == True{} : Bool}
  for +right: {b == True{} : Bool}
  {Bool.and(a,b) == True{} : Bool}

def Terrain.and_true(a,b,left,right):
  %Equal.sym(Bool,a,True{},left) : {Bool.and(_,b) == True{} : Bool}
  %Equal.sym(Bool,b,True{},right) : {Bool.and(True{},_) == True{} : Bool}
  {==}

law Terrain.grid_valid:
  for +pos: P.Players.Pos
  for +valid: N.Navigation.Bounds<pos>
  {Terrain.grid_ok(N.Navigation.zone(pos),N.Navigation.x(pos),N.Navigation.y(pos)) == True{} : Bool}

def Terrain.grid_valid(pos,valid):
  match valid:
    case N.Navigation.Bounds{zone,x,y}:
      Terrain.and_true(G.Bq.Nat.lt(U32.to_nat(N.Navigation.zone(pos)),4n),Bool.and(G.Bq.Nat.lt(U32.to_nat(N.Navigation.x(pos)),30n),G.Bq.Nat.lt(U32.to_nat(N.Navigation.y(pos)),17n)),Terrain.zone_inside(N.Navigation.zone(pos),zone),Terrain.and_true(G.Bq.Nat.lt(U32.to_nat(N.Navigation.x(pos)),30n),G.Bq.Nat.lt(U32.to_nat(N.Navigation.y(pos)),17n),x,y))

law Terrain.tile_in_bounds:
  for +maps: Terrain.Maps
  for +pos: P.Players.Pos
  for +valid: N.Navigation.Bounds<pos>
  {Terrain.tile_at(maps,N.Navigation.zone(pos),N.Navigation.x(pos),N.Navigation.y(pos)) == Terrain.get(Terrain.map_of(maps,N.Navigation.zone(pos)),Terrain.offset(N.Navigation.x(pos),N.Navigation.y(pos)),2) : U32}

def Terrain.tile_in_bounds(maps,pos,valid):
  %Equal.sym(Bool,Terrain.grid_ok(N.Navigation.zone(pos),N.Navigation.x(pos),N.Navigation.y(pos)),True{},Terrain.grid_valid(pos,valid)) : {Terrain.tile_gate(_,maps,N.Navigation.zone(pos),N.Navigation.x(pos),N.Navigation.y(pos)) == Terrain.get(Terrain.map_of(maps,N.Navigation.zone(pos)),Terrain.offset(N.Navigation.x(pos),N.Navigation.y(pos)),2) : U32}
  {==}

law Terrain.tile_outside:
  for +maps: Terrain.Maps
  for +zone: U32
  for +x: U32
  for +y: U32
  for +outside: {Terrain.grid_ok(zone,x,y) == False{} : Bool}
  {Terrain.tile_at(maps,zone,x,y) == 2 : U32}

def Terrain.tile_outside(maps,zone,x,y,outside):
  %Equal.sym(Bool,Terrain.grid_ok(zone,x,y),False{},outside) : {Terrain.tile_gate(_,maps,zone,x,y) == 2 : U32}
  {==}

def Terrain.length(map: Terrain.Map) -> Nat:
  match map:
    case Nil{}: Zero{}
    case Con{head,rest}: Succ{Terrain.length(rest)}

def Terrain.concat(left: Terrain.Map,right: Terrain.Map) -> Terrain.Map:
  match left:
    case Nil{}: right
    case Con{head,rest}: Con{head,Terrain.concat(rest,right)}

law Terrain.get_at:
  for +prefix: Terrain.Map
  for +value: U32
  for +suffix: Terrain.Map
  for +fallback: U32
  {Terrain.get(Terrain.concat(prefix,Con{value,suffix}),Terrain.length(prefix),fallback) == value : U32}

def Terrain.get_at(prefix,value,suffix,fallback):
  match prefix:
    case Nil{}: {==}
    case Con{head,rest}: Terrain.get_at(rest,value,suffix,fallback)

law Terrain.get_missing:
  for +map: Terrain.Map
  for +extra: Nat
  for +fallback: U32
  {Terrain.get(map,G.Bq.Nat.add(Terrain.length(map),extra),fallback) == fallback : U32}

def Terrain.get_missing(map,extra,fallback):
  match map:
    case Nil{}: {==}
    case Con{head,rest}: Terrain.get_missing(rest,extra,fallback)

def Terrain.zone_count(maps: Terrain.Maps) -> Nat:
  match maps:
    case Nil{}: Zero{}
    case Con{head,rest}: Succ{Terrain.zone_count(rest)}

def Terrain.concat_zones(left: Terrain.Maps,right: Terrain.Maps) -> Terrain.Maps:
  match left:
    case Nil{}: right
    case Con{head,rest}: Con{head,Terrain.concat_zones(rest,right)}

law Terrain.zone_at:
  for +prefix: Terrain.Maps
  for +map: Terrain.Map
  for +suffix: Terrain.Maps
  {Terrain.zone(Terrain.concat_zones(prefix,Con{map,suffix}),Terrain.zone_count(prefix)) == map : Terrain.Map}

def Terrain.zone_at(prefix,map,suffix):
  match prefix:
    case Nil{}: {==}
    case Con{head,rest}: Terrain.zone_at(rest,map,suffix)

law Terrain.zone_missing:
  for +maps: Terrain.Maps
  for +extra: Nat
  {Terrain.zone(maps,G.Bq.Nat.add(Terrain.zone_count(maps),extra)) == Nil{} : Terrain.Map}

def Terrain.zone_missing(maps,extra):
  match maps:
    case Nil{}: {==}
    case Con{head,rest}: Terrain.zone_missing(rest,extra)

type Terrain.Controls is Data:
  Terrain.Controls{zone: U32,heading: U32,moving: U32}

def Terrain.controls(pos: P.Players.Pos) -> Terrain.Controls:
  match pos:
    case P.Players.Pos{zone,x,y,heading,moving}: Terrain.Controls{zone,heading,moving}

law Terrain.propose_dir_controls:
  for +pos: P.Players.Pos
  for +dir: G.Bq.Dir
  {Terrain.controls(Terrain.propose_dir(pos,dir)) == Terrain.controls(pos) : Terrain.Controls}

def Terrain.propose_dir_controls(pos,dir):
  match pos:
    case P.Players.Pos{zone,x,y,heading,moving}: {==}

law Terrain.choose_controls:
  for +allowed: Bool
  for +proposal: P.Players.Pos
  for +original: P.Players.Pos
  for +same: {Terrain.controls(proposal) == Terrain.controls(original) : Terrain.Controls}
  {Terrain.controls(Terrain.choose(allowed,proposal,original)) == Terrain.controls(original) : Terrain.Controls}

def Terrain.choose_controls(allowed,proposal,original,same):
  match allowed:
    case False{}: {==}
    case True{}: same

law Terrain.move_controls:
  for +maps: Terrain.Maps
  for +pos: P.Players.Pos
  {Terrain.controls(Terrain.move(maps,pos)) == Terrain.controls(pos) : Terrain.Controls}

def Terrain.move_controls(maps,pos):
  Terrain.choose_controls(Terrain.can_walk(maps,Terrain.propose(pos)),Terrain.propose(pos),pos,Terrain.propose_dir_controls(pos,Terrain.direction(N.Navigation.direction(pos))))

law Terrain.active_controls:
  for +moving: Bool
  for +maps: Terrain.Maps
  for +pos: P.Players.Pos
  {Terrain.controls(Terrain.active(moving,maps,pos)) == Terrain.controls(pos) : Terrain.Controls}

def Terrain.active_controls(moving,maps,pos):
  match moving:
    case False{}: {==}
    case True{}: Terrain.move_controls(maps,pos)

law Terrain.walk_if_controls:
  for +maps: Terrain.Maps
  for +pos: P.Players.Pos
  {Terrain.controls(Terrain.walk_if(maps,pos)) == Terrain.controls(pos) : Terrain.Controls}

def Terrain.walk_if_controls(maps,pos): Terrain.active_controls(U32.is_ne(Terrain.moving(pos),0),maps,pos)

law Terrain.mob_move_controls:
  for +maps: Terrain.Maps
  for +pos: P.Players.Pos
  {Terrain.controls(Terrain.mob_move(maps,pos)) == Terrain.controls(pos) : Terrain.Controls}

def Terrain.mob_move_controls(maps,pos):
  Terrain.choose_controls(Bool.not(Terrain.in_village(Terrain.move(maps,pos))),Terrain.move(maps,pos),pos,Terrain.move_controls(maps,pos))

law Terrain.outside_solid:
  for +maps: Terrain.Maps
  for +zone: U32
  for +x: U32
  for +y: U32
  for +outside: {Terrain.grid_ok(zone,x,y) == False{} : Bool}
  {Terrain.walkable(Terrain.tile_at(maps,zone,x,y)) == False{} : Bool}

def Terrain.outside_solid(maps,zone,x,y,outside):
  %Equal.sym(U32,Terrain.tile_at(maps,zone,x,y),2,Terrain.tile_outside(maps,zone,x,y,outside)) : {Terrain.walkable(_) == False{} : Bool}
  {==}
