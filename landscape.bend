# Seeded terrain and the cleared corridors used by every generated world.
import Base
import ./terrain.bend as T
import ./game.bend as G
import ./navigation.bend as N
import ./players.bend as P
import ./zones.bend as Z
import ./locomotion.bend as L
import ./simulation.bend as S
import ./interactions.bend as I

def Landscape.pick(condition: Bool,yes: U32,no: U32) -> U32:
  match condition:
    case True{}: yes
    case False{}: no

def Landscape.hash(+a: U32,+b: U32) -> U32:
  +x = U32.xor(U32.xor(U32.mul(a,2654435761),U32.mul(b,40503)),U32.shrn(b,3n))
  +y = U32.mul(U32.xor(x,U32.shrn(x,15n)),2246822519)
  U32.xor(y,U32.shrn(y,13n))

def Landscape.meadow(edge: Bool,+r: U32,x: U32) -> U32:
  Landscape.pick(edge,2,Landscape.pick(U32.is_lt(r,10),2,Landscape.pick(Bool.and(Bool.and(U32.is_ge(r,10),U32.is_lt(r,14)),U32.is_gt(x,12)),3,Landscape.pick(Bool.and(U32.is_ge(r,14),U32.is_lt(r,22)),1,Landscape.pick(Bool.and(U32.is_ge(r,22),U32.is_lt(r,24)),5,0)))))

def Landscape.cave(edge: Bool,+r: U32) -> U32:
  Landscape.pick(edge,7,Landscape.pick(U32.is_lt(r,16),7,Landscape.pick(Bool.and(U32.is_ge(r,16),U32.is_lt(r,21)),8,6)))

def Landscape.snow(edge: Bool,+r: U32) -> U32:
  Landscape.pick(edge,11,Landscape.pick(U32.is_lt(r,11),11,Landscape.pick(Bool.and(U32.is_ge(r,11),U32.is_lt(r,19)),10,Landscape.pick(Bool.and(U32.is_ge(r,19),U32.is_lt(r,22)),5,9))))

def Landscape.rift(edge: Bool,r: U32) -> U32:
  Landscape.pick(edge,7,Landscape.pick(U32.is_lt(r,5),8,13))

def Landscape.random_value(+zone: U32,+seed: U32,+index: U32) -> U32:
  +x = U32.mod(index,30)
  +y = U32.div(index,30)
  +r = U32.mod(Landscape.hash(U32.xor(seed,U32.mul(zone,7919)),index),100)
  +edge = Bool.or(Bool.or(Bool.or(U32.is_eq(x,0),U32.is_eq(y,0)),U32.is_eq(x,29)),U32.is_eq(y,16))
  Landscape.pick(U32.is_eq(zone,0),Landscape.meadow(edge,r,x),Landscape.pick(U32.is_eq(zone,1),Landscape.cave(edge,r),Landscape.pick(U32.is_eq(zone,2),Landscape.snow(edge,r),Landscape.rift(edge,r))))

# Match the seed before doing word arithmetic. For an arbitrary seed the
# checker can retain this call instead of expanding the random expression.
def Landscape.random_tile(zone: U32,seed: U32,index: U32) -> U32:
  match seed:
    case U32{word}: Landscape.random_value(zone,U32{word},index)

def Landscape.leaf(inside: Bool,zone: U32,seed: U32,index: U32) -> T.Terrain.Map:
  match inside:
    case False{}: Nil{}
    case True{}: [Landscape.random_tile(zone,seed,index)]

def Landscape.raw(depth: Nat,+zone: U32,+seed: U32,+index: U32) -> T.Terrain.Map:
  match depth:
    case Zero{}: Landscape.leaf(U32.is_lt(index,510),zone,seed,index)
    case Succ{rest}:
      +next = rest
      left right = Landscape.raw(next,zone,seed,index) Landscape.raw(next,zone,seed,U32.add(index,U32.shln(1,next)))
      T.Terrain.concat(left,right)

def Landscape.floor(+zone: U32) -> U32:
  Landscape.pick(U32.is_eq(zone,0),4,Landscape.pick(U32.is_eq(zone,1),6,Landscape.pick(U32.is_eq(zone,2),9,13)))

def Landscape.portal(+zone: U32) -> U32:
  Landscape.pick(U32.is_eq(zone,2),14,Landscape.pick(U32.is_eq(zone,3),13,12))

def Landscape.set(map: T.Terrain.Map,index: Nat,tile: U32) -> T.Terrain.Map:
  match map:
    case Nil{}: Nil{}
    case Con{head,rest}:
      match index:
        case Zero{}: Con{tile,rest}
        case Succ{next}: Con{head,Landscape.set(rest,next,tile)}

def Landscape.row(count: Nat,map: T.Terrain.Map,index: Nat,+tile: U32) -> T.Terrain.Map:
  match count:
    case Zero{}: map
    case Succ{rest}:
      +next = index
      Landscape.row(rest,Landscape.set(map,next,tile),Succ{next},tile)

def Landscape.column(count: Nat,map: T.Terrain.Map,index: Nat,+tile: U32) -> T.Terrain.Map:
  match count:
    case Zero{}: map
    case Succ{rest}:
      +next = index
      Landscape.column(rest,Landscape.set(map,next,tile),G.Bq.Nat.add(next,30n),tile)

def Landscape.box(height: Nat,map: T.Terrain.Map,index: Nat,+width: Nat,+tile: U32) -> T.Terrain.Map:
  match height:
    case Zero{}: map
    case Succ{rest}:
      +next = index
      Landscape.box(rest,Landscape.row(width,map,next,tile),G.Bq.Nat.add(next,30n),width,tile)

def Landscape.back(is_meadow: Bool,map: T.Terrain.Map) -> T.Terrain.Map:
  match is_meadow:
    case True{}: map
    case False{}: Landscape.set(map,241n,12)

def Landscape.rift_room(is_rift: Bool,map: T.Terrain.Map) -> T.Terrain.Map:
  match is_rift:
    case False{}: map
    case True{}: Landscape.box(11n,map,100n,12n,13)

def Landscape.village(is_meadow: Bool,is_rift: Bool,map: T.Terrain.Map) -> T.Terrain.Map:
  match is_meadow:
    case True{}: Landscape.set(Landscape.box(4n,map,93n,9n,0),129n,15)
    case False{}: Landscape.rift_room(is_rift,map)

def Landscape.layout(+zone: U32,map: T.Terrain.Map) -> T.Terrain.Map:
  +floor = Landscape.floor(zone)
  +corridor = Landscape.row(28n,map,241n,floor)
  +crossing = Landscape.column(12n,corridor,112n,floor)
  +boss_room = Landscape.box(7n,crossing,169n,7n,floor)
  +spawn_room = Landscape.box(5n,boss_room,182n,4n,floor)
  +forward = Landscape.set(spawn_room,268n,Landscape.portal(zone))
  +back = Landscape.back(U32.is_eq(zone,0),forward)
  Landscape.village(U32.is_eq(zone,0),U32.is_eq(zone,3),back)

def Landscape.zone(+zone: U32,seed: U32) -> T.Terrain.Map:
  Landscape.layout(zone,Landscape.raw(9n,zone,seed,0))

def Landscape.maps_value(+seed: U32) -> T.Terrain.Maps:
  z0 z1 z2 z3 = Landscape.zone(0,seed) Landscape.zone(1,seed) Landscape.zone(2,seed) Landscape.zone(3,seed)
  [z0,z1,z2,z3]

# Keep generated maps symbolic in dependent type indices until their seed is
# available; native execution still builds the same four parallel zone maps.
def Landscape.maps(seed: U32) -> T.Terrain.Maps:
  match seed:
    case U32{word}: Landscape.maps_value(U32{word})

law Landscape.raw_length:
  for +zone: U32
  for +seed: U32
  {T.Terrain.length(Landscape.raw(9n,zone,seed,0)) == 510n : Nat}

def Landscape.raw_length(zone,seed): {==}

law Landscape.spawn_tile:
  for +seed: U32
  {T.Terrain.tile_at(Landscape.maps(seed),0,4,8) == 4 : U32}

def Landscape.spawn_tile(seed):
  match seed:
    case U32{word}: {==}

law Landscape.forward_arrival_meadow:
  for +seed: U32
  {T.Terrain.tile_at(Landscape.maps(seed),0,2,8) == 4 : U32}

def Landscape.forward_arrival_meadow(seed):
  match seed:
    case U32{word}: {==}

law Landscape.backward_arrival_rift:
  for +seed: U32
  {T.Terrain.tile_at(Landscape.maps(seed),3,27,8) == 13 : U32}

def Landscape.backward_arrival_rift(seed):
  match seed:
    case U32{word}: {==}

def Landscape.spawn_x() -> U32: 4
def Landscape.spawn_y() -> U32: 8

law Landscape.spawn_on:
  for +seed: U32
  L.Locomotion.Spawn(Landscape.maps(seed),Landscape.spawn_x,Landscape.spawn_y)

def Landscape.spawn_on(seed):
  match seed:
    case U32{word}: T.Terrain.On{N.Navigation.Bounds{Z.Zones.Hollow{{==}},{==},{==}},{==}}

law Landscape.set_length:
  for +map: T.Terrain.Map
  for +index: Nat
  for +tile: U32
  {T.Terrain.length(Landscape.set(map,index,tile)) == T.Terrain.length(map) : Nat}

def Landscape.set_length(map,index,tile):
  match map:
    case Nil{}: {==}
    case Con{head,rest}:
      match index:
        case Zero{}: {==}
        case Succ{next}:
          %Landscape.set_length(rest,next,tile) : {Succ{T.Terrain.length(Landscape.set(rest,next,tile))} == Succ{_} : Nat}
          {==}

law Landscape.row_length:
  for +count: Nat
  for +map: T.Terrain.Map
  for +index: Nat
  for +tile: U32
  {T.Terrain.length(Landscape.row(count,map,index,tile)) == T.Terrain.length(map) : Nat}

def Landscape.row_length(count,map,index,tile):
  match count:
    case Zero{}: {==}
    case Succ{rest}:
      Equal.trans(Nat,T.Terrain.length(Landscape.row(rest,Landscape.set(map,index,tile),Succ{index},tile)),T.Terrain.length(Landscape.set(map,index,tile)),T.Terrain.length(map),Landscape.row_length(rest,Landscape.set(map,index,tile),Succ{index},tile),Landscape.set_length(map,index,tile))

law Landscape.column_length:
  for +count: Nat
  for +map: T.Terrain.Map
  for +index: Nat
  for +tile: U32
  {T.Terrain.length(Landscape.column(count,map,index,tile)) == T.Terrain.length(map) : Nat}

def Landscape.column_length(count,map,index,tile):
  match count:
    case Zero{}: {==}
    case Succ{rest}:
      Equal.trans(Nat,T.Terrain.length(Landscape.column(rest,Landscape.set(map,index,tile),G.Bq.Nat.add(index,30n),tile)),T.Terrain.length(Landscape.set(map,index,tile)),T.Terrain.length(map),Landscape.column_length(rest,Landscape.set(map,index,tile),G.Bq.Nat.add(index,30n),tile),Landscape.set_length(map,index,tile))

law Landscape.box_length:
  for +height: Nat
  for +map: T.Terrain.Map
  for +index: Nat
  for +width: Nat
  for +tile: U32
  {T.Terrain.length(Landscape.box(height,map,index,width,tile)) == T.Terrain.length(map) : Nat}

def Landscape.box_length(height,map,index,width,tile):
  match height:
    case Zero{}: {==}
    case Succ{rest}:
      Equal.trans(Nat,T.Terrain.length(Landscape.box(rest,Landscape.row(width,map,index,tile),G.Bq.Nat.add(index,30n),width,tile)),T.Terrain.length(Landscape.row(width,map,index,tile)),T.Terrain.length(map),Landscape.box_length(rest,Landscape.row(width,map,index,tile),G.Bq.Nat.add(index,30n),width,tile),Landscape.row_length(width,map,index,tile))

law Landscape.back_length:
  for +meadow: Bool
  for +map: T.Terrain.Map
  {T.Terrain.length(Landscape.back(meadow,map)) == T.Terrain.length(map) : Nat}

def Landscape.back_length(meadow,map):
  match meadow:
    case True{}: {==}
    case False{}: Landscape.set_length(map,241n,12)

law Landscape.rift_room_length:
  for +rift: Bool
  for +map: T.Terrain.Map
  {T.Terrain.length(Landscape.rift_room(rift,map)) == T.Terrain.length(map) : Nat}

def Landscape.rift_room_length(rift,map):
  match rift:
    case False{}: {==}
    case True{}: Landscape.box_length(11n,map,100n,12n,13)

law Landscape.village_length:
  for +meadow: Bool
  for +rift: Bool
  for +map: T.Terrain.Map
  {T.Terrain.length(Landscape.village(meadow,rift,map)) == T.Terrain.length(map) : Nat}

def Landscape.village_length(meadow,rift,map):
  match meadow:
    case False{}: Landscape.rift_room_length(rift,map)
    case True{}:
      Equal.trans(Nat,T.Terrain.length(Landscape.set(Landscape.box(4n,map,93n,9n,0),129n,15)),T.Terrain.length(Landscape.box(4n,map,93n,9n,0)),T.Terrain.length(map),Landscape.set_length(Landscape.box(4n,map,93n,9n,0),129n,15),Landscape.box_length(4n,map,93n,9n,0))

law Landscape.layout_length:
  for +zone: U32
  for +map: T.Terrain.Map
  {T.Terrain.length(Landscape.layout(zone,map)) == T.Terrain.length(map) : Nat}

def Landscape.layout_length(zone,map):
  +floor = Landscape.floor(zone)
  +corridor = Landscape.row(28n,map,241n,floor)
  +crossing = Landscape.column(12n,corridor,112n,floor)
  +boss_room = Landscape.box(7n,crossing,169n,7n,floor)
  +spawn_room = Landscape.box(5n,boss_room,182n,4n,floor)
  +forward = Landscape.set(spawn_room,268n,Landscape.portal(zone))
  +back = Landscape.back(U32.is_eq(zone,0),forward)
  Equal.trans(Nat,T.Terrain.length(Landscape.layout(zone,map)),T.Terrain.length(back),T.Terrain.length(map),Landscape.village_length(U32.is_eq(zone,0),U32.is_eq(zone,3),back),
    Equal.trans(Nat,T.Terrain.length(back),T.Terrain.length(forward),T.Terrain.length(map),Landscape.back_length(U32.is_eq(zone,0),forward),
      Equal.trans(Nat,T.Terrain.length(forward),T.Terrain.length(spawn_room),T.Terrain.length(map),Landscape.set_length(spawn_room,268n,Landscape.portal(zone)),
        Equal.trans(Nat,T.Terrain.length(spawn_room),T.Terrain.length(boss_room),T.Terrain.length(map),Landscape.box_length(5n,boss_room,182n,4n,floor),
          Equal.trans(Nat,T.Terrain.length(boss_room),T.Terrain.length(crossing),T.Terrain.length(map),Landscape.box_length(7n,crossing,169n,7n,floor),
            Equal.trans(Nat,T.Terrain.length(crossing),T.Terrain.length(corridor),T.Terrain.length(map),Landscape.column_length(12n,corridor,112n,floor),Landscape.row_length(28n,map,241n,floor)))))))

law Landscape.zone_length:
  for +zone: U32
  for +seed: U32
  {T.Terrain.length(Landscape.zone(zone,seed)) == 510n : Nat}

def Landscape.zone_length(zone,seed):
  Equal.trans(Nat,T.Terrain.length(Landscape.zone(zone,seed)),T.Terrain.length(Landscape.raw(9n,zone,seed,0)),510n,Landscape.layout_length(zone,Landscape.raw(9n,zone,seed,0)),Landscape.raw_length(zone,seed))

def Landscape.arrival(zone: U32,forward: Bool,heading: U32) -> P.Players.Pos:
  match forward:
    case True{}: P.Players.Pos{zone,2,8,heading,0}
    case False{}: P.Players.Pos{zone,27,8,heading,0}

law Landscape.forward_0_on:
  for +seed: U32
  for +heading: U32
  T.Terrain.On<Landscape.maps(seed),P.Players.Pos{0,2,8,heading,0}>

def Landscape.forward_0_on(seed,heading):
  match seed:
    case U32{word}: T.Terrain.On{N.Navigation.Bounds{Z.Zones.Hollow{{==}},{==},{==}},{==}}

law Landscape.backward_0_on:
  for +seed: U32
  for +heading: U32
  T.Terrain.On<Landscape.maps(seed),P.Players.Pos{0,27,8,heading,0}>

def Landscape.backward_0_on(seed,heading):
  match seed:
    case U32{word}: T.Terrain.On{N.Navigation.Bounds{Z.Zones.Hollow{{==}},{==},{==}},{==}}

law Landscape.forward_1_on:
  for +seed: U32
  for +heading: U32
  T.Terrain.On<Landscape.maps(seed),P.Players.Pos{1,2,8,heading,0}>

def Landscape.forward_1_on(seed,heading):
  match seed:
    case U32{word}: T.Terrain.On{N.Navigation.Bounds{Z.Zones.Cavern{{==}},{==},{==}},{==}}

law Landscape.backward_1_on:
  for +seed: U32
  for +heading: U32
  T.Terrain.On<Landscape.maps(seed),P.Players.Pos{1,27,8,heading,0}>

def Landscape.backward_1_on(seed,heading):
  match seed:
    case U32{word}: T.Terrain.On{N.Navigation.Bounds{Z.Zones.Cavern{{==}},{==},{==}},{==}}

law Landscape.forward_2_on:
  for +seed: U32
  for +heading: U32
  T.Terrain.On<Landscape.maps(seed),P.Players.Pos{2,2,8,heading,0}>

def Landscape.forward_2_on(seed,heading):
  match seed:
    case U32{word}: T.Terrain.On{N.Navigation.Bounds{Z.Zones.Frost{{==}},{==},{==}},{==}}

law Landscape.backward_2_on:
  for +seed: U32
  for +heading: U32
  T.Terrain.On<Landscape.maps(seed),P.Players.Pos{2,27,8,heading,0}>

def Landscape.backward_2_on(seed,heading):
  match seed:
    case U32{word}: T.Terrain.On{N.Navigation.Bounds{Z.Zones.Frost{{==}},{==},{==}},{==}}

law Landscape.forward_3_on:
  for +seed: U32
  for +heading: U32
  T.Terrain.On<Landscape.maps(seed),P.Players.Pos{3,2,8,heading,0}>

def Landscape.forward_3_on(seed,heading):
  match seed:
    case U32{word}: T.Terrain.On{N.Navigation.Bounds{Z.Zones.Rift{{==}},{==},{==}},{==}}

law Landscape.backward_3_on:
  for +seed: U32
  for +heading: U32
  T.Terrain.On<Landscape.maps(seed),P.Players.Pos{3,27,8,heading,0}>

def Landscape.backward_3_on(seed,heading):
  match seed:
    case U32{word}: T.Terrain.On{N.Navigation.Bounds{Z.Zones.Rift{{==}},{==},{==}},{==}}

law Landscape.control_on:
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  for +heading: U32
  for +moving: U32
  for +valid: T.Terrain.On<maps,pos>
  T.Terrain.On<maps,N.Navigation.control(pos,heading,moving)>

def Landscape.control_on(maps,pos,heading,moving,valid):
  match pos:
    case P.Players.Pos{zone,x,y,old_dir,old_moving}:
      match valid:
        case T.Terrain.On{bounds,walkable}:
          match bounds:
            case N.Navigation.Bounds{z_ok,x_ok,y_ok}: T.Terrain.On{N.Navigation.Bounds{z_ok,x_ok,y_ok},walkable}

type Landscape.Anchors<-maps: T.Terrain.Maps> is Data:
  Landscape.Anchors{f0: T.Terrain.On<maps,P.Players.Pos{0,2,8,0,0}>,b0: T.Terrain.On<maps,P.Players.Pos{0,27,8,0,0}>,f1: T.Terrain.On<maps,P.Players.Pos{1,2,8,0,0}>,b1: T.Terrain.On<maps,P.Players.Pos{1,27,8,0,0}>,f2: T.Terrain.On<maps,P.Players.Pos{2,2,8,0,0}>,b2: T.Terrain.On<maps,P.Players.Pos{2,27,8,0,0}>,f3: T.Terrain.On<maps,P.Players.Pos{3,2,8,0,0}>,b3: T.Terrain.On<maps,P.Players.Pos{3,27,8,0,0}>}

law Landscape.anchors:
  for +seed: U32
  Landscape.Anchors<Landscape.maps(seed)>

def Landscape.anchors(seed):
  Landscape.Anchors{Landscape.forward_0_on(seed,0),Landscape.backward_0_on(seed,0),Landscape.forward_1_on(seed,0),Landscape.backward_1_on(seed,0),Landscape.forward_2_on(seed,0),Landscape.backward_2_on(seed,0),Landscape.forward_3_on(seed,0),Landscape.backward_3_on(seed,0)}

law Landscape.anchored_arrival:
  for +maps: T.Terrain.Maps
  for +anchors: Landscape.Anchors<maps>
  for +zone: U32
  for +forward: Bool
  for +heading: U32
  for +valid: Z.Zones.Valid<zone>
  T.Terrain.On<maps,Landscape.arrival(zone,forward,heading)>

def Landscape.anchored_arrival(maps,anchors,zone,forward,heading,valid):
  match anchors:
    case Landscape.Anchors{f0,b0,f1,b1,f2,b2,f3,b3}:
      match forward:
        case True{}:
          match valid:
            case Z.Zones.Hollow{equal}:
              %Equal.sym(U32,zone,0,equal) : T.Terrain.On<maps,P.Players.Pos{_,2,8,heading,0}>
              Landscape.control_on(maps,P.Players.Pos{0,2,8,0,0},heading,0,f0)
            case Z.Zones.Cavern{equal}:
              %Equal.sym(U32,zone,1,equal) : T.Terrain.On<maps,P.Players.Pos{_,2,8,heading,0}>
              Landscape.control_on(maps,P.Players.Pos{1,2,8,0,0},heading,0,f1)
            case Z.Zones.Frost{equal}:
              %Equal.sym(U32,zone,2,equal) : T.Terrain.On<maps,P.Players.Pos{_,2,8,heading,0}>
              Landscape.control_on(maps,P.Players.Pos{2,2,8,0,0},heading,0,f2)
            case Z.Zones.Rift{equal}:
              %Equal.sym(U32,zone,3,equal) : T.Terrain.On<maps,P.Players.Pos{_,2,8,heading,0}>
              Landscape.control_on(maps,P.Players.Pos{3,2,8,0,0},heading,0,f3)
        case False{}:
          match valid:
            case Z.Zones.Hollow{equal}:
              %Equal.sym(U32,zone,0,equal) : T.Terrain.On<maps,P.Players.Pos{_,27,8,heading,0}>
              Landscape.control_on(maps,P.Players.Pos{0,27,8,0,0},heading,0,b0)
            case Z.Zones.Cavern{equal}:
              %Equal.sym(U32,zone,1,equal) : T.Terrain.On<maps,P.Players.Pos{_,27,8,heading,0}>
              Landscape.control_on(maps,P.Players.Pos{1,27,8,0,0},heading,0,b1)
            case Z.Zones.Frost{equal}:
              %Equal.sym(U32,zone,2,equal) : T.Terrain.On<maps,P.Players.Pos{_,27,8,heading,0}>
              Landscape.control_on(maps,P.Players.Pos{2,27,8,0,0},heading,0,b2)
            case Z.Zones.Rift{equal}:
              %Equal.sym(U32,zone,3,equal) : T.Terrain.On<maps,P.Players.Pos{_,27,8,heading,0}>
              Landscape.control_on(maps,P.Players.Pos{3,27,8,0,0},heading,0,b3)

law Landscape.arrival_on:
  for +seed: U32
  for +zone: U32
  for +forward: Bool
  for +heading: U32
  for +valid: Z.Zones.Valid<zone>
  T.Terrain.On<Landscape.maps(seed),Landscape.arrival(zone,forward,heading)>

def Landscape.arrival_on(seed,zone,forward,heading,valid):
  Landscape.anchored_arrival(Landscape.maps(seed),Landscape.anchors(seed),zone,forward,heading,valid)

law Landscape.player_spawn_on:
  for +seed: U32
  for +pid: U32
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  L.Locomotion.On(Landscape.maps(seed),P.Players.spawn(pid,cid,style,name,Landscape.spawn_x,Landscape.spawn_y))

def Landscape.player_spawn_on(seed,pid,cid,style,name):
  L.Locomotion.spawn_on(Landscape.maps(seed),pid,cid,style,name,Landscape.spawn_x,Landscape.spawn_y,Landscape.spawn_on(seed))

law Landscape.tick_on:
  for +seed: U32
  for +state: S.Simulation.State
  for +actions: L.Locomotion.Actions
  for +timer: U32
  for +valid: L.Locomotion.All(Landscape.maps(seed),S.Simulation.players(state))
  L.Locomotion.All(Landscape.maps(seed),S.Simulation.players(S.Simulation.state(L.Locomotion.tick(state,Landscape.maps(seed),actions,S.Simulation.Rules{Landscape.spawn_x,Landscape.spawn_y,timer}))))

def Landscape.tick_on(seed,state,actions,timer,valid):
  L.Locomotion.tick_on(state,Landscape.maps(seed),actions,S.Simulation.Rules{Landscape.spawn_x,Landscape.spawn_y,timer},valid,Landscape.spawn_on(seed))

law Landscape.trace_on:
  for +actions: List<&2,L.Locomotion.Actions>
  for +seed: U32
  for +state: S.Simulation.State
  for +timer: U32
  for +valid: L.Locomotion.All(Landscape.maps(seed),S.Simulation.players(state))
  L.Locomotion.All(Landscape.maps(seed),S.Simulation.players(L.Locomotion.trace(actions,state,Landscape.maps(seed),S.Simulation.Rules{Landscape.spawn_x,Landscape.spawn_y,timer})))

def Landscape.trace_on(actions,seed,state,timer,valid):
  L.Locomotion.trace_on(actions,state,Landscape.maps(seed),S.Simulation.Rules{Landscape.spawn_x,Landscape.spawn_y,timer},valid,Landscape.spawn_on(seed))

law Landscape.land_on:
  for +route: N.Navigation.Route
  for +pos: P.Players.Pos
  for +seed: U32
  for +valid: T.Terrain.On<Landscape.maps(seed),pos>
  for +route_valid: N.Navigation.RouteValid(N.Navigation.zone(pos),route)
  T.Terrain.On<Landscape.maps(seed),N.Navigation.land(route,pos,N.Navigation.rules)>

def Landscape.land_on(route,pos,seed,valid,route_valid):
  match route:
    case N.Navigation.Stay{}: valid
    case N.Navigation.Sealed{}: valid
    case N.Navigation.Travel{zone,forward}:
      match forward:
        case True{}:
          match pos:
            case P.Players.Pos{old,x,y,dir,moving}: Landscape.arrival_on(seed,zone,True{},dir,route_valid)
        case False{}:
          match pos:
            case P.Players.Pos{old,x,y,dir,moving}: Landscape.arrival_on(seed,zone,False{},dir,route_valid)

law Landscape.propose_on:
  for +pos: P.Players.Pos
  for +sigils: U32
  for +seed: U32
  for +valid: T.Terrain.On<Landscape.maps(seed),pos>
  T.Terrain.On<Landscape.maps(seed),N.Navigation.land(N.Navigation.route_for(pos,sigils,N.Navigation.rules),pos,N.Navigation.rules)>

def Landscape.propose_on(pos,sigils,seed,valid):
  match valid:
    case T.Terrain.On{bounds,walkable}:
      match bounds:
        case N.Navigation.Bounds{zone_ok,x_ok,y_ok}:
          Landscape.land_on(N.Navigation.route_for(pos,sigils,N.Navigation.rules),pos,seed,T.Terrain.On{N.Navigation.Bounds{zone_ok,x_ok,y_ok},walkable},N.Navigation.route_valid(N.Navigation.zone(pos),N.Navigation.at(pos,N.Navigation.forward_x(N.Navigation.rules),N.Navigation.forward_y(N.Navigation.rules)),N.Navigation.at(pos,N.Navigation.back_x(N.Navigation.rules),N.Navigation.back_y(N.Navigation.rules)),sigils,zone_ok))


# The actual MOVE, HALT, TALK and ENTER handlers preserve generated terrain.
law Landscape.set_pos_on:
  for +seed: U32
  for +player: P.Players.State
  for +pos: P.Players.Pos
  for +valid: T.Terrain.On<Landscape.maps(seed),pos>
  T.Terrain.On<Landscape.maps(seed),N.Navigation.pos(I.Interaction.set_pos(player,pos))>

def Landscape.set_pos_on(seed,player,pos,valid):
  %Equal.sym(P.Players.Pos,N.Navigation.pos(I.Interaction.set_pos(player,pos)),pos,I.Interaction.set_pos_position(player,pos)) : T.Terrain.On<Landscape.maps(seed),_>
  valid

law Landscape.begin_on:
  for +seed: U32
  for +player: P.Players.State
  for +valid: T.Terrain.On<Landscape.maps(seed),N.Navigation.pos(player)>
  T.Terrain.On<Landscape.maps(seed),N.Navigation.pos(I.Interaction.begin(player))>

def Landscape.begin_on(seed,player,valid):
  %Equal.sym(P.Players.Pos,N.Navigation.pos(I.Interaction.begin(player)),N.Navigation.pos(player),I.Interaction.begin_position(player)) : T.Terrain.On<Landscape.maps(seed),_>
  valid

law Landscape.move_on:
  for +seed: U32
  for +player: P.Players.State
  for +direction: U32
  for +valid: T.Terrain.On<Landscape.maps(seed),N.Navigation.pos(player)>
  T.Terrain.On<Landscape.maps(seed),N.Navigation.pos(I.Interaction.move(player,direction))>

def Landscape.move_on(seed,player,direction,valid):
  Landscape.set_pos_on(seed,player,N.Navigation.control(N.Navigation.pos(player),U32.and(direction,3),1),Landscape.control_on(Landscape.maps(seed),N.Navigation.pos(player),U32.and(direction,3),1,valid))

law Landscape.halt_on:
  for +seed: U32
  for +player: P.Players.State
  for +valid: T.Terrain.On<Landscape.maps(seed),N.Navigation.pos(player)>
  T.Terrain.On<Landscape.maps(seed),N.Navigation.pos(I.Interaction.halt(player))>

def Landscape.halt_on(seed,player,valid):
  Landscape.set_pos_on(seed,player,N.Navigation.control(N.Navigation.pos(player),N.Navigation.direction(N.Navigation.pos(player)),0),Landscape.control_on(Landscape.maps(seed),N.Navigation.pos(player),N.Navigation.direction(N.Navigation.pos(player)),0,valid))

law Landscape.elder_gate_on:
  for +seed: U32
  for +start: Bool
  for +player: P.Players.State
  for +valid: T.Terrain.On<Landscape.maps(seed),N.Navigation.pos(player)>
  T.Terrain.On<Landscape.maps(seed),N.Navigation.pos(I.Interaction.player(I.Interaction.elder_gate(start,player)))>

def Landscape.elder_gate_on(seed,start,player,valid):
  match start:
    case True{}: Landscape.begin_on(seed,player,valid)
    case False{}: valid

law Landscape.elder_on:
  for +seed: U32
  for +player: P.Players.State
  for +valid: T.Terrain.On<Landscape.maps(seed),N.Navigation.pos(player)>
  T.Terrain.On<Landscape.maps(seed),N.Navigation.pos(I.Interaction.player(I.Interaction.elder(player)))>

def Landscape.elder_on(seed,player,valid):
  Landscape.elder_gate_on(seed,U32.is_eq(I.Interaction.main(player),0),player,valid)

law Landscape.shop_gate_on:
  for +seed: U32
  for +near: Bool
  for +player: P.Players.State
  for +valid: T.Terrain.On<Landscape.maps(seed),N.Navigation.pos(player)>
  T.Terrain.On<Landscape.maps(seed),N.Navigation.pos(I.Interaction.player(I.Interaction.shop_gate(near,player)))>

def Landscape.shop_gate_on(seed,near,player,valid):
  match near:
    case True{}: valid
    case False{}: valid

law Landscape.talk_gate_on:
  for +seed: U32
  for +elder: Bool
  for +shop: Bool
  for +player: P.Players.State
  for +valid: T.Terrain.On<Landscape.maps(seed),N.Navigation.pos(player)>
  T.Terrain.On<Landscape.maps(seed),N.Navigation.pos(I.Interaction.player(I.Interaction.talk_gate(elder,shop,player)))>

def Landscape.talk_gate_on(seed,elder,shop,player,valid):
  match elder:
    case True{}: Landscape.elder_on(seed,player,valid)
    case False{}: Landscape.shop_gate_on(seed,shop,player,valid)

law Landscape.talk_on:
  for +seed: U32
  for +player: P.Players.State
  for +npc: U32
  for +valid: T.Terrain.On<Landscape.maps(seed),N.Navigation.pos(player)>
  T.Terrain.On<Landscape.maps(seed),N.Navigation.pos(I.Interaction.player(I.Interaction.talk(player,npc)))>

def Landscape.talk_on(seed,player,npc,valid):
  Landscape.talk_gate_on(seed,Bool.and(U32.is_eq(npc,0),I.Interaction.near(N.Navigation.pos(player),I.Interaction.elder_x,I.Interaction.elder_y)),Bool.and(U32.is_eq(npc,1),I.Interaction.near(N.Navigation.pos(player),I.Interaction.shop_x,I.Interaction.shop_y)),player,valid)

law Landscape.enter_on:
  for +seed: U32
  for +player: P.Players.State
  for +sigils: U32
  for +valid: T.Terrain.On<Landscape.maps(seed),N.Navigation.pos(player)>
  T.Terrain.On<Landscape.maps(seed),N.Navigation.pos(I.Interaction.player(I.Interaction.enter(player,sigils)))>

def Landscape.enter_on(seed,player,sigils,valid):
  Landscape.set_pos_on(seed,player,N.Navigation.land(N.Navigation.route_for(N.Navigation.pos(player),sigils,N.Navigation.rules),N.Navigation.pos(player),N.Navigation.rules),Landscape.propose_on(N.Navigation.pos(player),sigils,seed,valid))

law Landscape.step_on:
  for +seed: U32
  for +command: I.Interaction.Command
  for +player: P.Players.State
  for +valid: T.Terrain.On<Landscape.maps(seed),N.Navigation.pos(player)>
  T.Terrain.On<Landscape.maps(seed),N.Navigation.pos(I.Interaction.player(I.Interaction.step(command,player)))>

def Landscape.step_on(seed,command,player,valid):
  match command:
    case I.Interaction.Move{direction}: Landscape.move_on(seed,player,direction,valid)
    case I.Interaction.Halt{}: Landscape.halt_on(seed,player,valid)
    case I.Interaction.Talk{npc}: Landscape.talk_on(seed,player,npc,valid)
    case I.Interaction.Enter{sigils}: Landscape.enter_on(seed,player,sigils,valid)

law Landscape.apply_taken_on:
  for +seed: U32
  for +taken: P.Players.Take
  for +command: I.Interaction.Command
  for +valid: L.Locomotion.All(Landscape.maps(seed),P.Players.restore(taken))
  L.Locomotion.All(Landscape.maps(seed),I.Interaction.roster(I.Interaction.apply_taken(taken,command)))

def Landscape.apply_taken_on(seed,taken,command,valid):
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}: valid
        case Some{player}:
          match valid:
            case Tuple{player_ok,others_ok}: Tuple{Landscape.step_on(seed,command,player,player_ok),others_ok}

law Landscape.run_on:
  for +seed: U32
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +command: I.Interaction.Command
  for +valid: L.Locomotion.All(Landscape.maps(seed),players)
  L.Locomotion.All(Landscape.maps(seed),I.Interaction.roster(I.Interaction.run(players,target,command)))

def Landscape.run_on(seed,players,target,command,valid):
  Landscape.apply_taken_on(seed,P.Players.take(players,target),command,L.Locomotion.take_on(Landscape.maps(seed),players,target,valid))

law Landscape.commands_on:
  for +seed: U32
  for +inputs: List<&2,I.Interaction.Input>
  for +players: List<&2,P.Players.State>
  for +valid: L.Locomotion.All(Landscape.maps(seed),players)
  L.Locomotion.All(Landscape.maps(seed),I.Interaction.trace(inputs,players))

def Landscape.commands_on(seed,inputs,players,valid):
  match inputs:
    case Nil{}: valid
    case Con{head,rest}:
      match head:
        case I.Interaction.Input{target,command}: Landscape.commands_on(seed,rest,I.Interaction.roster(I.Interaction.run(players,target,command)),Landscape.run_on(seed,players,target,command,valid))
