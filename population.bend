# The actual monster catalog, generation, and initial world construction.
import Base
import ./ai.bend as A
import ./placement.bend as Place
import ./terrain.bend as T
import ./landscape.bend as L
import ./players.bend as P
import ./navigation.bend as N
import ./monsters.bend as M
import ./habitat.bend as H
import ./roster.bend as R
import ./zones.bend as Z
import ./simulation.bend as S

def Population.cap() -> U32: 9
def Population.rare_pct() -> U32: 4
def Population.boss_x() -> U32: 22
def Population.boss_y() -> U32: 8
def Population.maw_x() -> U32: 15
def Population.maw_y() -> U32: 7

def Population.maximum(+kind: U32) -> U32:
  L.Landscape.pick(U32.is_eq(kind,0),18,L.Landscape.pick(U32.is_eq(kind,1),28,L.Landscape.pick(U32.is_eq(kind,2),55,L.Landscape.pick(U32.is_eq(kind,3),90,L.Landscape.pick(U32.is_eq(kind,4),130,L.Landscape.pick(U32.is_eq(kind,5),170,L.Landscape.pick(U32.is_eq(kind,6),450,L.Landscape.pick(U32.is_eq(kind,7),950,L.Landscape.pick(U32.is_eq(kind,8),1700,6500)))))))))

def Population.kind(+zone: U32,salt: U32) -> U32:
  U32.add(L.Landscape.pick(U32.is_eq(zone,0),0,L.Landscape.pick(U32.is_eq(zone,1),2,4)),U32.mod(salt,2))

def Population.at(mid: U32,kind: U32,rare: U32,pos: P.Players.Pos,maximum: U32) -> M.Monsters.State:
  match pos:
    case P.Players.Pos{zone,x,y,dir,moving}: M.Monsters.spawn(mid,kind,rare,zone,x,y,maximum)

def Population.monster(+maps: T.Terrain.Maps,+mid: U32,+zone: U32,+salt: U32,+rare: U32) -> M.Monsters.State:
  +kind = Population.kind(zone,salt)
  Population.at(mid,kind,rare,Place.Placement.spot(maps,zone,U32.add(U32.mul(salt,977),mid)),U32.mul(Population.maximum(kind),U32.add(1,U32.mul(7,rare))))

def Population.boss_pos(+zone: U32) -> P.Players.Pos:
  P.Players.Pos{zone,L.Landscape.pick(U32.is_eq(zone,3),Population.maw_x,Population.boss_x),L.Landscape.pick(U32.is_eq(zone,3),Population.maw_y,Population.boss_y),0,0}

def Population.boss(mid: U32,+zone: U32) -> M.Monsters.State:
  Population.at(mid,U32.add(6,zone),0,Population.boss_pos(zone),Population.maximum(U32.add(6,zone)))

def Population.populate_value(+count: Nat,+maps: T.Terrain.Maps,+zone: U32,+base: U32) -> List<&2,M.Monsters.State>:
  match count:
    case Zero{}: Nil{}
    case Succ{rest}:
      +n = U32.from_nat(rest)
      +mid = U32.add(U32.add(base,1),n)
      +rare = L.Landscape.pick(U32.is_lt(U32.mod(L.Landscape.hash(mid,U32.add(zone,31)),100),Population.rare_pct),1,0)
      Con{Population.monster(maps,mid,zone,L.Landscape.hash(U32.add(U32.add(U32.mul(zone,100),1),n),555),rare),Population.populate_value(rest,maps,zone,base)}
def Population.populate(+count: Nat,maps: T.Terrain.Maps,+zone: U32,+base: U32) -> List<&2,M.Monsters.State>:
  match maps:
    case Nil{}: Population.populate_value(count,Nil{},zone,base)
    case Con{head,tail}: Population.populate_value(count,Con{head,tail},zone,base)

law Population.populate_refines:
  for +count: Nat
  for +maps: T.Terrain.Maps
  for +zone: U32
  for +base: U32
  {Population.populate(count,maps,zone,base) == Population.populate_value(count,maps,zone,base) : List<&2,M.Monsters.State>}

def Population.populate_refines(count,maps,zone,base):
  match maps:
    case Nil{}: {==}
    case Con{head,tail}: {==}


def Population.bosses() -> List<&2,M.Monsters.State>:
  [Population.boss(1,0),Population.boss(2,1),Population.boss(3,2),Population.boss(4,3)]

def Population.initial(+maps: T.Terrain.Maps) -> List<&2,M.Monsters.State>:
  R.Roster.concat(Population.bosses,R.Roster.concat(Population.populate(U32.to_nat(Population.cap),maps,0,100),R.Roster.concat(Population.populate(U32.to_nat(Population.cap),maps,1,200),Population.populate(U32.to_nat(Population.cap),maps,2,300))))

def Population.fresh(world: U32,+seed: U32,+now: U32) -> T.Terrain.World:
  +maps = L.Landscape.maps(seed)
  T.Terrain.World{S.Simulation.Meta{1,world,seed,0,now,now,0,0,1,400},Nil{},Population.initial(maps),maps}

law Population.at_ok:
  for +mid: U32
  for +kind: U32
  for +rare: U32
  for +pos: P.Players.Pos
  for +maximum: U32
  M.Monsters.OK(Population.at(mid,kind,rare,pos,maximum))

def Population.at_ok(mid,kind,rare,pos,maximum):
  match pos:
    case P.Players.Pos{zone,x,y,dir,moving}: M.Monsters.spawn_ok(mid,kind,rare,zone,x,y,maximum)

law Population.at_on:
  for +maps: T.Terrain.Maps
  for +mid: U32
  for +kind: U32
  for +rare: U32
  for +pos: P.Players.Pos
  for +maximum: U32
  for +valid: T.Terrain.On<maps,pos>
  H.Habitat.On(maps,Population.at(mid,kind,rare,pos,maximum))

def Population.at_on(maps,mid,kind,rare,pos,maximum,valid):
  match pos:
    case P.Players.Pos{zone,x,y,dir,moving}: H.Habitat.spawn_on(maps,mid,kind,rare,zone,x,y,maximum,L.Landscape.control_on(maps,P.Players.Pos{zone,x,y,dir,moving},0,0,valid))

law Population.monster_ok:
  for +maps: T.Terrain.Maps
  for +mid: U32
  for +zone: U32
  for +salt: U32
  for +rare: U32
  M.Monsters.OK(Population.monster(maps,mid,zone,salt,rare))

def Population.monster_ok(maps,mid,zone,salt,rare):
  +kind = Population.kind(zone,salt)
  Population.at_ok(mid,kind,rare,Place.Placement.spot(maps,zone,U32.add(U32.mul(salt,977),mid)),U32.mul(Population.maximum(kind),U32.add(1,U32.mul(7,rare))))

law Population.monster_on:
  for +seed: U32
  for +mid: U32
  for +zone: U32
  for +salt: U32
  for +rare: U32
  for +valid: Z.Zones.Valid<zone>
  H.Habitat.On(L.Landscape.maps(seed),Population.monster(L.Landscape.maps(seed),mid,zone,salt,rare))

def Population.monster_on(seed,mid,zone,salt,rare,valid):
  +maps = L.Landscape.maps(seed)
  +kind = Population.kind(zone,salt)
  Population.at_on(maps,mid,kind,rare,Place.Placement.spot(maps,zone,U32.add(U32.mul(salt,977),mid)),U32.mul(Population.maximum(kind),U32.add(1,U32.mul(7,rare))),Place.Placement.spot_on(seed,zone,U32.add(U32.mul(salt,977),mid),valid))

law Population.boss_ok:
  for +mid: U32
  for +zone: U32
  M.Monsters.OK(Population.boss(mid,zone))

def Population.boss_ok(mid,zone):
  Population.at_ok(mid,U32.add(6,zone),0,Population.boss_pos(zone),Population.maximum(U32.add(6,zone)))

law Population.maw_on:
  for +seed: U32
  T.Terrain.On<L.Landscape.maps(seed),Population.boss_pos(3)>

def Population.maw_on(seed):
  match seed:
    case U32{word}: T.Terrain.On{N.Navigation.Bounds{Z.Zones.Rift{{==}},{==},{==}},{==}}

law Population.boss_pos_on:
  for +seed: U32
  for +zone: U32
  for +valid: Z.Zones.Valid<zone>
  T.Terrain.On<L.Landscape.maps(seed),Population.boss_pos(zone)>

def Population.boss_pos_on(seed,zone,valid):
  match valid:
    case Z.Zones.Hollow{equal}:
      %Equal.sym(U32,zone,0,equal) : T.Terrain.On<L.Landscape.maps(seed),Population.boss_pos(_)>
      Place.Placement.row_get(8n,14n,14n,L.Landscape.maps(seed),0,Place.Placement.row_0(seed),{==})
    case Z.Zones.Cavern{equal}:
      %Equal.sym(U32,zone,1,equal) : T.Terrain.On<L.Landscape.maps(seed),Population.boss_pos(_)>
      Place.Placement.row_get(8n,14n,14n,L.Landscape.maps(seed),1,Place.Placement.row_1(seed),{==})
    case Z.Zones.Frost{equal}:
      %Equal.sym(U32,zone,2,equal) : T.Terrain.On<L.Landscape.maps(seed),Population.boss_pos(_)>
      Place.Placement.row_get(8n,14n,14n,L.Landscape.maps(seed),2,Place.Placement.row_2(seed),{==})
    case Z.Zones.Rift{equal}:
      %Equal.sym(U32,zone,3,equal) : T.Terrain.On<L.Landscape.maps(seed),Population.boss_pos(_)>
      Population.maw_on(seed)

law Population.boss_on:
  for +seed: U32
  for +mid: U32
  for +zone: U32
  for +valid: Z.Zones.Valid<zone>
  H.Habitat.On(L.Landscape.maps(seed),Population.boss(mid,zone))

def Population.boss_on(seed,mid,zone,valid):
  Population.at_on(L.Landscape.maps(seed),mid,U32.add(6,zone),0,Population.boss_pos(zone),Population.maximum(U32.add(6,zone)),Population.boss_pos_on(seed,zone,valid))

law Population.populate_value_ok:
  for +count: Nat
  for +maps: T.Terrain.Maps
  for +zone: U32
  for +base: U32
  R.Roster.OK(Population.populate_value(count,maps,zone,base))

def Population.populate_value_ok(count,maps,zone,base):
  match count:
    case Zero{}: Unit{}
    case Succ{rest}:
      +n = U32.from_nat(rest)
      +mid = U32.add(U32.add(base,1),n)
      +rare = L.Landscape.pick(U32.is_lt(U32.mod(L.Landscape.hash(mid,U32.add(zone,31)),100),Population.rare_pct),1,0)
      Tuple{Population.monster_ok(maps,mid,zone,L.Landscape.hash(U32.add(U32.add(U32.mul(zone,100),1),n),555),rare),Population.populate_value_ok(rest,maps,zone,base)}

law Population.populate_value_on:
  for +count: Nat
  for +seed: U32
  for +zone: U32
  for +base: U32
  for +valid: Z.Zones.Valid<zone>
  H.Habitat.All(L.Landscape.maps(seed),Population.populate_value(count,L.Landscape.maps(seed),zone,base))

def Population.populate_value_on(count,seed,zone,base,valid):
  match count:
    case Zero{}: Unit{}
    case Succ{rest}:
      +n = U32.from_nat(rest)
      +mid = U32.add(U32.add(base,1),n)
      +rare = L.Landscape.pick(U32.is_lt(U32.mod(L.Landscape.hash(mid,U32.add(zone,31)),100),Population.rare_pct),1,0)
      Tuple{Population.monster_on(seed,mid,zone,L.Landscape.hash(U32.add(U32.add(U32.mul(zone,100),1),n),555),rare,valid),Population.populate_value_on(rest,seed,zone,base,valid)}

law Population.populate_ok:
  for +count: Nat
  for +maps: T.Terrain.Maps
  for +zone: U32
  for +base: U32
  R.Roster.OK(Population.populate(count,maps,zone,base))

def Population.populate_ok(count,maps,zone,base):
  %Equal.sym(List<&2,M.Monsters.State>,Population.populate(count,maps,zone,base),Population.populate_value(count,maps,zone,base),Population.populate_refines(count,maps,zone,base)) : R.Roster.OK(_)
  Population.populate_value_ok(count,maps,zone,base)

law Population.populate_on:
  for +count: Nat
  for +seed: U32
  for +zone: U32
  for +base: U32
  for +valid: Z.Zones.Valid<zone>
  H.Habitat.All(L.Landscape.maps(seed),Population.populate(count,L.Landscape.maps(seed),zone,base))

def Population.populate_on(count,seed,zone,base,valid):
  +maps = L.Landscape.maps(seed)
  %Equal.sym(List<&2,M.Monsters.State>,Population.populate(count,maps,zone,base),Population.populate_value(count,maps,zone,base),Population.populate_refines(count,maps,zone,base)) : H.Habitat.All(maps,_)
  Population.populate_value_on(count,seed,zone,base,valid)

law Population.bosses_ok:
  R.Roster.OK(Population.bosses)

def Population.bosses_ok():
  Tuple{Population.boss_ok(1,0),Tuple{Population.boss_ok(2,1),Tuple{Population.boss_ok(3,2),Tuple{Population.boss_ok(4,3),Unit{}}}}}

law Population.bosses_on:
  for +seed: U32
  H.Habitat.All(L.Landscape.maps(seed),Population.bosses)

def Population.bosses_on(seed):
  Tuple{Population.boss_on(seed,1,0,Z.Zones.Hollow{{==}}),Tuple{Population.boss_on(seed,2,1,Z.Zones.Cavern{{==}}),Tuple{Population.boss_on(seed,3,2,Z.Zones.Frost{{==}}),Tuple{Population.boss_on(seed,4,3,Z.Zones.Rift{{==}}),Unit{}}}}}

law Population.initial_ok:
  for +maps: T.Terrain.Maps
  R.Roster.OK(Population.initial(maps))

def Population.initial_ok(maps):
  +a = Population.populate(U32.to_nat(Population.cap),maps,0,100)
  +b = Population.populate(U32.to_nat(Population.cap),maps,1,200)
  +c = Population.populate(U32.to_nat(Population.cap),maps,2,300)
  R.Roster.concat_ok(Population.bosses,R.Roster.concat(a,R.Roster.concat(b,c)),Population.bosses_ok,R.Roster.concat_ok(a,R.Roster.concat(b,c),Population.populate_ok(U32.to_nat(Population.cap),maps,0,100),R.Roster.concat_ok(b,c,Population.populate_ok(U32.to_nat(Population.cap),maps,1,200),Population.populate_ok(U32.to_nat(Population.cap),maps,2,300))))

law Population.initial_on:
  for +seed: U32
  H.Habitat.All(L.Landscape.maps(seed),Population.initial(L.Landscape.maps(seed)))

def Population.initial_on(seed):
  +maps = L.Landscape.maps(seed)
  +a = Population.populate(U32.to_nat(Population.cap),maps,0,100)
  +b = Population.populate(U32.to_nat(Population.cap),maps,1,200)
  +c = Population.populate(U32.to_nat(Population.cap),maps,2,300)
  H.Habitat.concat_on(maps,Population.bosses,R.Roster.concat(a,R.Roster.concat(b,c)),Population.bosses_on(seed),H.Habitat.concat_on(maps,a,R.Roster.concat(b,c),Population.populate_on(U32.to_nat(Population.cap),seed,0,100,Z.Zones.Hollow{{==}}),H.Habitat.concat_on(maps,b,c,Population.populate_on(U32.to_nat(Population.cap),seed,1,200,Z.Zones.Cavern{{==}}),Population.populate_on(U32.to_nat(Population.cap),seed,2,300,Z.Zones.Frost{{==}}))))

law Population.valid_zone:
  for +maps: T.Terrain.Maps
  for +monster: M.Monsters.State
  for +valid: H.Habitat.On(maps,monster)
  Z.Zones.Valid<R.Roster.zone_of(monster)>

def Population.valid_zone(maps,monster,valid):
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}:
      match valid:
        case T.Terrain.On{bounds,walkable}:
          match bounds:
            case N.Navigation.Bounds{zone_ok,x_ok,y_ok}: zone_ok

law Population.valid_zones:
  for +maps: T.Terrain.Maps
  for +monsters: List<&2,M.Monsters.State>
  for +valid: H.Habitat.All(maps,monsters)
  Z.Zones.All(monsters)

def Population.valid_zones(maps,monsters,valid):
  match monsters:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match valid:
        case Tuple{head_ok,rest_ok}: Tuple{Population.valid_zone(maps,head,head_ok),Population.valid_zones(maps,rest,rest_ok)}

law Population.fresh_ok:
  for +world: U32
  for +seed: U32
  for +now: U32
  S.Simulation.OK<T.Terrain.simulation(Population.fresh(world,seed,now))>

def Population.fresh_ok(world,seed,now):
  S.Simulation.OK{Unit{},Population.initial_ok(L.Landscape.maps(seed)),Population.valid_zones(L.Landscape.maps(seed),Population.initial(L.Landscape.maps(seed)),Population.initial_on(seed))}

law Population.fresh_on:
  for +world: U32
  for +seed: U32
  for +now: U32
  H.Habitat.All(T.Terrain.maps(Population.fresh(world,seed,now)),S.Simulation.monsters(T.Terrain.simulation(Population.fresh(world,seed,now))))

def Population.fresh_on(world,seed,now): Population.initial_on(seed)

law Population.positive_zone:
  for +value: Nat
  for +mid: U32
  for +kind: U32
  for +rare: U32
  for +zone: U32
  for +x: U32
  for +y: U32
  for +maximum: U32
  {R.Roster.zone_of(M.Monsters.spawn_positive(value,mid,kind,rare,zone,x,y,maximum)) == zone : U32}

def Population.positive_zone(value,mid,kind,rare,zone,x,y,maximum):
  match value:
    case Zero{}: {==}
    case Succ{rest}: {==}

law Population.spawn_zone:
  for +mid: U32
  for +kind: U32
  for +rare: U32
  for +zone: U32
  for +x: U32
  for +y: U32
  for +maximum: U32
  {R.Roster.zone_of(M.Monsters.spawn(mid,kind,rare,zone,x,y,maximum)) == zone : U32}

def Population.spawn_zone(mid,kind,rare,zone,x,y,maximum):
  Population.positive_zone(U32.to_nat(maximum),mid,kind,rare,zone,x,y,maximum)

law Population.at_zone:
  for +mid: U32
  for +kind: U32
  for +rare: U32
  for +pos: P.Players.Pos
  for +maximum: U32
  {R.Roster.zone_of(Population.at(mid,kind,rare,pos,maximum)) == N.Navigation.zone(pos) : U32}

def Population.at_zone(mid,kind,rare,pos,maximum):
  match pos:
    case P.Players.Pos{zone,x,y,dir,moving}: Population.spawn_zone(mid,kind,rare,zone,x,y,maximum)

law Population.monster_zone:
  for +maps: T.Terrain.Maps
  for +mid: U32
  for +zone: U32
  for +salt: U32
  for +rare: U32
  {R.Roster.zone_of(Population.monster(maps,mid,zone,salt,rare)) == zone : U32}

def Population.monster_zone(maps,mid,zone,salt,rare):
  +kind = Population.kind(zone,salt)
  +spot = Place.Placement.spot(maps,zone,U32.add(U32.mul(salt,977),mid))
  Equal.trans(U32,R.Roster.zone_of(Population.monster(maps,mid,zone,salt,rare)),N.Navigation.zone(spot),zone,Population.at_zone(mid,kind,rare,spot,U32.mul(Population.maximum(kind),U32.add(1,U32.mul(7,rare)))),Place.Placement.spot_zone(maps,zone,U32.add(U32.mul(salt,977),mid)))

def Population.spawn_plan(monster: M.Monsters.State) -> A.AI.Plan:
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}: A.AI.Spawn{kind,rare,x,y,maximum}

def Population.rebirth(+maps: T.Terrain.Maps,monster: M.Monsters.State,+tick: U32) -> A.AI.Plan:
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}:
      +id = mid
      +rare = L.Landscape.pick(U32.is_lt(U32.mod(L.Landscape.hash(tick,U32.add(U32.mul(id,3),1)),100),Population.rare_pct),1,0)
      Population.spawn_plan(Population.monster(maps,id,zone,L.Landscape.hash(tick,id),rare))

law Population.spawn_plan_on:
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  for +monster: M.Monsters.State
  for +valid: H.Habitat.On(maps,monster)
  for +zone: {R.Roster.zone_of(monster) == N.Navigation.zone(pos) : U32}
  H.Habitat.PlanOn(maps,pos,Population.spawn_plan(monster))

def Population.spawn_plan_on(maps,pos,monster,valid,zone):
  match monster:
    case M.Monsters.State{mid,kind,rare,z,x,y,hp,maximum,target,attack,dead,respawn}:
      %zone : T.Terrain.On<maps,P.Players.Pos{_,x,y,0,0}>
      valid

law Population.rebirth_on:
  for +seed: U32
  for +monster: M.Monsters.State
  for +tick: U32
  for +valid: H.Habitat.On(L.Landscape.maps(seed),monster)
  H.Habitat.PlanOn(L.Landscape.maps(seed),H.Habitat.pos(monster),Population.rebirth(L.Landscape.maps(seed),monster,tick))

def Population.rebirth_on(seed,monster,tick,valid):
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}:
      +maps = L.Landscape.maps(seed)
      +original = {M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn} : M.Monsters.State}
      +next_rare = L.Landscape.pick(U32.is_lt(U32.mod(L.Landscape.hash(tick,U32.add(U32.mul(mid,3),1)),100),Population.rare_pct),1,0)
      +salt = L.Landscape.hash(tick,mid)
      Population.spawn_plan_on(maps,H.Habitat.pos(original),Population.monster(maps,mid,zone,salt,next_rare),Population.monster_on(seed,mid,zone,salt,next_rare,Population.valid_zone(maps,original,valid)),Population.monster_zone(maps,mid,zone,salt,next_rare))
