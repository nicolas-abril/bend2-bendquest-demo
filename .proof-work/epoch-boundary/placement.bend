# Seeded spawn selection used by initial monsters and later respawns.
import Base
import ./game.bend as G
import ./numeric.bend as Num
import ./remainders.bend as R
import ./terrain.bend as T
import ./navigation.bend as N
import ./players.bend as P
import ./zones.bend as Z
import ./landscape.bend as L
import ./habitat.bend as H
import ./monsters.bend as M

# A certificate for a consecutive part of the generated portal corridor.
def Placement.Row(+maps: T.Terrain.Maps,+zone: U32,+first: Nat,count: Nat) -> Data:
  match count:
    case Zero{}: Unit
    case Succ{rest}: Sigma<&2,&2,T.Terrain.On<maps,P.Players.Pos{zone,U32.from_nat(first),8,0,0}>,(valid => Placement.Row(maps,zone,Succ{first},rest))>

law Placement.row_get:
  for +index: Nat
  for +count: Nat
  for +first: Nat
  for +maps: T.Terrain.Maps
  for +zone: U32
  for +row: Placement.Row(maps,zone,first,count)
  for +inside: {G.Bq.Nat.lt(index,count) == True{} : Bool}
  T.Terrain.On<maps,P.Players.Pos{zone,U32.from_nat(G.Bq.Nat.add(first,index)),8,0,0}>

def Placement.row_get(index,count,first,maps,zone,row,inside):
  match index:
    case Zero{}:
      match count:
        case Zero{}: Empty.absurd(T.Terrain.On<maps,P.Players.Pos{zone,U32.from_nat(G.Bq.Nat.add(first,0n)),8,0,0}>,G.Bq.Bool.false_ne_true(inside))
        case Succ{rest}:
          match row:
            case Tuple{head,tail}:
              %Equal.sym(Nat,G.Bq.Nat.add(first,0n),first,G.Bq.Nat.add_zero(first)) : T.Terrain.On<maps,P.Players.Pos{zone,U32.from_nat(_),8,0,0}>
              head
    case Succ{next}:
      match count:
        case Zero{}: Empty.absurd(T.Terrain.On<maps,P.Players.Pos{zone,U32.from_nat(G.Bq.Nat.add(first,Succ{next})),8,0,0}>,G.Bq.Bool.false_ne_true(inside))
        case Succ{rest}:
          match row:
            case Tuple{head,tail}:
              %Equal.sym(Nat,G.Bq.Nat.add(first,Succ{next}),Succ{G.Bq.Nat.add(first,next)},G.Bq.Nat.add_succ(first,next)) : T.Terrain.On<maps,P.Players.Pos{zone,U32.from_nat(_),8,0,0}>
              Placement.row_get(next,rest,Succ{first},maps,zone,tail,inside)

def Placement.max14(+x: U32) -> U32:
  L.Landscape.pick(U32.is_ge(x,14),x,14)

def Placement.random_x(+hash: U32) -> U32: U32.add(2,U32.mod(hash,26))
def Placement.random_y(hash: U32) -> U32: U32.add(2,U32.mod(U32.shrn(hash,8n),13))

def Placement.candidate(zone: U32,+hash: U32) -> P.Players.Pos:
  P.Players.Pos{zone,Placement.random_x(hash),Placement.random_y(hash),0,0}

def Placement.fallback(zone: U32,hash: U32) -> P.Players.Pos:
  P.Players.Pos{zone,Placement.max14(Placement.random_x(hash)),8,0,0}

def Placement.select(allowed: Bool,point: P.Players.Pos,fallback: P.Players.Pos) -> P.Players.Pos:
  match allowed:
    case True{}: point
    case False{}: fallback

def Placement.from_hash(+maps: T.Terrain.Maps,+zone: U32,+hash: U32) -> P.Players.Pos:
  +point = Placement.candidate(zone,hash)
  Placement.select(Bool.and(T.Terrain.can_walk(maps,point),Bool.not(T.Terrain.in_village(point))),point,Placement.fallback(zone,hash))

def Placement.spot(maps: T.Terrain.Maps,+zone: U32,salt: U32) -> P.Players.Pos:
  Placement.from_hash(maps,zone,L.Landscape.hash(salt,U32.mul(zone,131)))

law Placement.row_0:
  for +seed: U32
  Placement.Row(L.Landscape.maps(seed),0,14n,14n)

def Placement.row_0(seed):
  match seed:
    case U32{word}: Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Hollow{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Hollow{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Hollow{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Hollow{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Hollow{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Hollow{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Hollow{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Hollow{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Hollow{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Hollow{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Hollow{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Hollow{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Hollow{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Hollow{{==}},{==},{==}},{==}},Unit{}}}}}}}}}}}}}}}

law Placement.row_1:
  for +seed: U32
  Placement.Row(L.Landscape.maps(seed),1,14n,14n)

def Placement.row_1(seed):
  match seed:
    case U32{word}: Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Cavern{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Cavern{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Cavern{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Cavern{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Cavern{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Cavern{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Cavern{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Cavern{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Cavern{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Cavern{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Cavern{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Cavern{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Cavern{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Cavern{{==}},{==},{==}},{==}},Unit{}}}}}}}}}}}}}}}

law Placement.row_2:
  for +seed: U32
  Placement.Row(L.Landscape.maps(seed),2,14n,14n)

def Placement.row_2(seed):
  match seed:
    case U32{word}: Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Frost{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Frost{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Frost{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Frost{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Frost{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Frost{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Frost{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Frost{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Frost{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Frost{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Frost{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Frost{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Frost{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Frost{{==}},{==},{==}},{==}},Unit{}}}}}}}}}}}}}}}

law Placement.row_3:
  for +seed: U32
  Placement.Row(L.Landscape.maps(seed),3,14n,14n)

def Placement.row_3(seed):
  match seed:
    case U32{word}: Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Rift{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Rift{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Rift{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Rift{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Rift{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Rift{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Rift{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Rift{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Rift{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Rift{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Rift{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Rift{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Rift{{==}},{==},{==}},{==}},Tuple{T.Terrain.On{N.Navigation.Bounds{Z.Zones.Rift{{==}},{==},{==}},{==}},Unit{}}}}}}}}}}}}}}}

law Placement.row:
  for +seed: U32
  for +zone: U32
  for +valid: Z.Zones.Valid<zone>
  Placement.Row(L.Landscape.maps(seed),zone,14n,14n)

def Placement.row(seed,zone,valid):
  match valid:
    case Z.Zones.Hollow{equal}:
      %Equal.sym(U32,zone,0,equal) : Placement.Row(L.Landscape.maps(seed),_,14n,14n)
      Placement.row_0(seed)
    case Z.Zones.Cavern{equal}:
      %Equal.sym(U32,zone,1,equal) : Placement.Row(L.Landscape.maps(seed),_,14n,14n)
      Placement.row_1(seed)
    case Z.Zones.Frost{equal}:
      %Equal.sym(U32,zone,2,equal) : Placement.Row(L.Landscape.maps(seed),_,14n,14n)
      Placement.row_2(seed)
    case Z.Zones.Rift{equal}:
      %Equal.sym(U32,zone,3,equal) : Placement.Row(L.Landscape.maps(seed),_,14n,14n)
      Placement.row_3(seed)

law Placement.fallback_nat:
  for +n: Nat
  for +maps: T.Terrain.Maps
  for +zone: U32
  for +row: Placement.Row(maps,zone,14n,14n)
  for +bound: {G.Bq.Nat.lt(n,26n) == True{} : Bool}
  T.Terrain.On<maps,P.Players.Pos{zone,Placement.max14(U32.add(2,U32.from_nat(n))),8,0,0}>

def Placement.fallback_nat(n,maps,zone,row,bound):
  match n:
    case 0n: Placement.row_get(0n,14n,14n,maps,zone,row,{==})
    case 1n: Placement.row_get(0n,14n,14n,maps,zone,row,{==})
    case 2n: Placement.row_get(0n,14n,14n,maps,zone,row,{==})
    case 3n: Placement.row_get(0n,14n,14n,maps,zone,row,{==})
    case 4n: Placement.row_get(0n,14n,14n,maps,zone,row,{==})
    case 5n: Placement.row_get(0n,14n,14n,maps,zone,row,{==})
    case 6n: Placement.row_get(0n,14n,14n,maps,zone,row,{==})
    case 7n: Placement.row_get(0n,14n,14n,maps,zone,row,{==})
    case 8n: Placement.row_get(0n,14n,14n,maps,zone,row,{==})
    case 9n: Placement.row_get(0n,14n,14n,maps,zone,row,{==})
    case 10n: Placement.row_get(0n,14n,14n,maps,zone,row,{==})
    case 11n: Placement.row_get(0n,14n,14n,maps,zone,row,{==})
    case 12n: Placement.row_get(0n,14n,14n,maps,zone,row,{==})
    case 13n: Placement.row_get(1n,14n,14n,maps,zone,row,{==})
    case 14n: Placement.row_get(2n,14n,14n,maps,zone,row,{==})
    case 15n: Placement.row_get(3n,14n,14n,maps,zone,row,{==})
    case 16n: Placement.row_get(4n,14n,14n,maps,zone,row,{==})
    case 17n: Placement.row_get(5n,14n,14n,maps,zone,row,{==})
    case 18n: Placement.row_get(6n,14n,14n,maps,zone,row,{==})
    case 19n: Placement.row_get(7n,14n,14n,maps,zone,row,{==})
    case 20n: Placement.row_get(8n,14n,14n,maps,zone,row,{==})
    case 21n: Placement.row_get(9n,14n,14n,maps,zone,row,{==})
    case 22n: Placement.row_get(10n,14n,14n,maps,zone,row,{==})
    case 23n: Placement.row_get(11n,14n,14n,maps,zone,row,{==})
    case 24n: Placement.row_get(12n,14n,14n,maps,zone,row,{==})
    case 25n: Placement.row_get(13n,14n,14n,maps,zone,row,{==})
    case 26n+rest:
      Empty.absurd(T.Terrain.On<maps,P.Players.Pos{zone,Placement.max14(U32.add(2,U32.from_nat(26n+rest))),8,0,0}>,G.Bq.Bool.false_ne_true(bound))

law Placement.fallback_on:
  for +seed: U32
  for +zone: U32
  for +hash: U32
  for +valid: Z.Zones.Valid<zone>
  T.Terrain.On<L.Landscape.maps(seed),Placement.fallback(zone,hash)>

def Placement.fallback_on(seed,zone,hash,valid):
  %Num.Numeric.u32_roundtrip(U32.mod(hash,26)) : T.Terrain.On<L.Landscape.maps(seed),P.Players.Pos{zone,Placement.max14(U32.add(2,_)),8,0,0}>
  Placement.fallback_nat(U32.to_nat(U32.mod(hash,26)),L.Landscape.maps(seed),zone,Placement.row(seed,zone,valid),R.Remainders.mod_26(hash))

law Placement.x_nat:
  for +n: Nat
  for +bound: {G.Bq.Nat.lt(n,26n) == True{} : Bool}
  {G.Bq.Nat.lt(U32.to_nat(U32.add(2,U32.from_nat(n))),30n) == True{} : Bool}

def Placement.x_nat(n,bound):
  match n:
    case 0n: {==}
    case 1n: {==}
    case 2n: {==}
    case 3n: {==}
    case 4n: {==}
    case 5n: {==}
    case 6n: {==}
    case 7n: {==}
    case 8n: {==}
    case 9n: {==}
    case 10n: {==}
    case 11n: {==}
    case 12n: {==}
    case 13n: {==}
    case 14n: {==}
    case 15n: {==}
    case 16n: {==}
    case 17n: {==}
    case 18n: {==}
    case 19n: {==}
    case 20n: {==}
    case 21n: {==}
    case 22n: {==}
    case 23n: {==}
    case 24n: {==}
    case 25n: {==}
    case 26n+rest:
      Empty.absurd({G.Bq.Nat.lt(U32.to_nat(U32.add(2,U32.from_nat(26n+rest))),30n) == True{} : Bool},G.Bq.Bool.false_ne_true(bound))

law Placement.x_bound:
  for +hash: U32
  {G.Bq.Nat.lt(U32.to_nat(Placement.random_x(hash)),30n) == True{} : Bool}

def Placement.x_bound(hash):
  %Num.Numeric.u32_roundtrip(U32.mod(hash,26)) : {G.Bq.Nat.lt(U32.to_nat(U32.add(2,_)),30n) == True{} : Bool}
  Placement.x_nat(U32.to_nat(U32.mod(hash,26)),R.Remainders.mod_26(hash))

law Placement.y_nat:
  for +n: Nat
  for +bound: {G.Bq.Nat.lt(n,13n) == True{} : Bool}
  {G.Bq.Nat.lt(U32.to_nat(U32.add(2,U32.from_nat(n))),17n) == True{} : Bool}

def Placement.y_nat(n,bound):
  match n:
    case 0n: {==}
    case 1n: {==}
    case 2n: {==}
    case 3n: {==}
    case 4n: {==}
    case 5n: {==}
    case 6n: {==}
    case 7n: {==}
    case 8n: {==}
    case 9n: {==}
    case 10n: {==}
    case 11n: {==}
    case 12n: {==}
    case 13n+rest:
      Empty.absurd({G.Bq.Nat.lt(U32.to_nat(U32.add(2,U32.from_nat(13n+rest))),17n) == True{} : Bool},G.Bq.Bool.false_ne_true(bound))

law Placement.y_bound:
  for +hash: U32
  {G.Bq.Nat.lt(U32.to_nat(Placement.random_y(hash)),17n) == True{} : Bool}

def Placement.y_bound(hash):
  %Num.Numeric.u32_roundtrip(U32.mod(U32.shrn(hash,8n),13)) : {G.Bq.Nat.lt(U32.to_nat(U32.add(2,_)),17n) == True{} : Bool}
  Placement.y_nat(U32.to_nat(U32.mod(U32.shrn(hash,8n),13)),R.Remainders.mod_13(U32.shrn(hash,8n)))

law Placement.candidate_bounds:
  for +zone: U32
  for +hash: U32
  for +valid: Z.Zones.Valid<zone>
  N.Navigation.Bounds<Placement.candidate(zone,hash)>

def Placement.candidate_bounds(zone,hash,valid):
  N.Navigation.Bounds{valid,Placement.x_bound(hash),Placement.y_bound(hash)}

law Placement.and_left:
  for +a: Bool
  for +b: Bool
  for +both: {Bool.and(a,b) == True{} : Bool}
  {a == True{} : Bool}

def Placement.and_left(a,b,both):
  match a:
    case True{}: {==}
    case False{}: both

law Placement.select_on:
  for +allowed: Bool
  for +maps: T.Terrain.Maps
  for +point: P.Players.Pos
  for +fallback: P.Players.Pos
  for +bounds: N.Navigation.Bounds<point>
  for +back: T.Terrain.On<maps,fallback>
  for +decision: {Bool.and(T.Terrain.can_walk(maps,point),Bool.not(T.Terrain.in_village(point))) == allowed : Bool}
  T.Terrain.On<maps,Placement.select(allowed,point,fallback)>

def Placement.select_on(allowed,maps,point,fallback,bounds,back,decision):
  match allowed:
    case False{}: back
    case True{}: T.Terrain.On{bounds,Placement.and_left(T.Terrain.can_walk(maps,point),Bool.not(T.Terrain.in_village(point)),decision)}

law Placement.from_hash_on:
  for +seed: U32
  for +zone: U32
  for +hash: U32
  for +valid: Z.Zones.Valid<zone>
  T.Terrain.On<L.Landscape.maps(seed),Placement.from_hash(L.Landscape.maps(seed),zone,hash)>

def Placement.from_hash_on(seed,zone,hash,valid):
  +maps = L.Landscape.maps(seed)
  +point = Placement.candidate(zone,hash)
  Placement.select_on(Bool.and(T.Terrain.can_walk(maps,point),Bool.not(T.Terrain.in_village(point))),maps,point,Placement.fallback(zone,hash),Placement.candidate_bounds(zone,hash,valid),Placement.fallback_on(seed,zone,hash,valid),{==})

law Placement.spot_on:
  for +seed: U32
  for +zone: U32
  for +salt: U32
  for +valid: Z.Zones.Valid<zone>
  T.Terrain.On<L.Landscape.maps(seed),Placement.spot(L.Landscape.maps(seed),zone,salt)>

def Placement.spot_on(seed,zone,salt,valid):
  Placement.from_hash_on(seed,zone,L.Landscape.hash(salt,U32.mul(zone,131)),valid)

law Placement.select_zone:
  for +allowed: Bool
  for +point: P.Players.Pos
  for +fallback: P.Players.Pos
  for +zone: U32
  for +point_zone: {N.Navigation.zone(point) == zone : U32}
  for +back_zone: {N.Navigation.zone(fallback) == zone : U32}
  {N.Navigation.zone(Placement.select(allowed,point,fallback)) == zone : U32}

def Placement.select_zone(allowed,point,fallback,zone,point_zone,back_zone):
  match allowed:
    case True{}: point_zone
    case False{}: back_zone

law Placement.from_hash_zone:
  for +maps: T.Terrain.Maps
  for +zone: U32
  for +hash: U32
  {N.Navigation.zone(Placement.from_hash(maps,zone,hash)) == zone : U32}

def Placement.from_hash_zone(maps,zone,hash):
  +point = Placement.candidate(zone,hash)
  Placement.select_zone(Bool.and(T.Terrain.can_walk(maps,point),Bool.not(T.Terrain.in_village(point))),point,Placement.fallback(zone,hash),zone,{==},{==})

law Placement.spot_zone:
  for +maps: T.Terrain.Maps
  for +zone: U32
  for +salt: U32
  {N.Navigation.zone(Placement.spot(maps,zone,salt)) == zone : U32}

def Placement.spot_zone(maps,zone,salt):
  Placement.from_hash_zone(maps,zone,L.Landscape.hash(salt,U32.mul(zone,131)))

def Placement.xy(pos: P.Players.Pos) -> U32 & U32:
  match pos:
    case P.Players.Pos{zone,x,y,dir,moving}: Tuple{x,y}
