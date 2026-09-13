# Monster IDs are distinct independently of mutable monster fields and zones.
import Base
import ./numeric.bend as N
import ./monsters.bend as M
import ./roster.bend as R
import ./zones.bend as Z
import ./population.bend as Pop
import ./placement.bend as Place
import ./navigation.bend as Nav
import ./terrain.bend as T
import ./landscape.bend as L
import ./ai.bend as A
import ./planning.bend as Plan
import ./locomotion.bend as Walk
import ./simulation.bend as S
import ./players.bend as P
import ./battle.bend as B
import ./combat.bend as K

def Identity.mid(key: Z.Zones.Key) -> U32:
  match key:
    case Z.Zones.Key{mid,zone}: mid

def Identity.Absent(+id: U32,keys: List<&2,Z.Zones.Key>) -> Data:
  match keys:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,{U32.is_eq(id,Identity.mid(head)) == False{} : Bool},(different => Identity.Absent(id,rest))>

def Identity.Unique(keys: List<&2,Z.Zones.Key>) -> Data:
  match keys:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,Identity.Absent(Identity.mid(head),rest),(absent => Identity.Unique(rest))>

def Identity.Monsters(monsters: List<&2,M.Monsters.State>) -> Data:
  Identity.Unique(Z.Zones.keys(monsters))

law Identity.neq_case:
  for +a: U32
  for +b: U32
  for +same: Bool
  for +decision: {U32.is_eq(b,a) == same : Bool}
  for +different: {U32.is_eq(a,b) == False{} : Bool}
  {same == False{} : Bool}

def Identity.neq_case(a,b,same,decision,different):
  match same:
    case False{}: {==}
    case True{}:
      +equal = N.Numeric.u32_eq_sound(b,a,decision)
      +bad = {(%equal : {U32.is_eq(a,_) == False{} : Bool}; different) : {U32.is_eq(a,a) == False{} : Bool}}
      +impossible = N.Numeric.true_ne_false((%N.Numeric.u32_eq_refl(a) : {_ == False{} : Bool}; bad))
      Empty.absurd({True{} == False{} : Bool},impossible)

law Identity.neq_sym:
  for +a: U32
  for +b: U32
  for +different: {U32.is_eq(a,b) == False{} : Bool}
  {U32.is_eq(b,a) == False{} : Bool}

def Identity.neq_sym(a,b,different): Identity.neq_case(a,b,U32.is_eq(b,a),{==},different)

law Identity.absent_swap:
  for +id: U32
  for +first: Z.Zones.Key
  for +second: Z.Zones.Key
  for +rest: List<&2,Z.Zones.Key>
  for +valid: Identity.Absent(id,Con{first,Con{second,rest}})
  Identity.Absent(id,Con{second,Con{first,rest}})

def Identity.absent_swap(id,first,second,rest,valid):
  match valid:
    case Tuple{a,later}:
      match later:
        case Tuple{b,tail}: Tuple{b,Tuple{a,tail}}

law Identity.unique_swap:
  for +first: Z.Zones.Key
  for +second: Z.Zones.Key
  for +rest: List<&2,Z.Zones.Key>
  for +valid: Identity.Unique(Con{first,Con{second,rest}})
  Identity.Unique(Con{second,Con{first,rest}})

def Identity.unique_swap(first,second,rest,valid):
  match valid:
    case Tuple{first_absent,later}:
      match first_absent:
        case Tuple{different,first_rest}:
          match later:
            case Tuple{second_rest,tail}: Tuple{Tuple{Identity.neq_sym(Identity.mid(first),Identity.mid(second),different),second_rest},Tuple{first_rest,tail}}

def Identity.absent_head(id: U32,head: Z.Zones.Key,rest: List<&2,Z.Zones.Key>,valid: Identity.Absent(id,Con{head,rest})) -> {U32.is_eq(id,Identity.mid(head)) == False{} : Bool}:
  match valid:
    case Tuple{different,tail}: different

def Identity.absent_tail(id: U32,head: Z.Zones.Key,rest: List<&2,Z.Zones.Key>,valid: Identity.Absent(id,Con{head,rest})) -> Identity.Absent(id,rest):
  match valid:
    case Tuple{different,tail}: tail

def Identity.unique_head(head: Z.Zones.Key,rest: List<&2,Z.Zones.Key>,valid: Identity.Unique(Con{head,rest})) -> Identity.Absent(Identity.mid(head),rest):
  match valid:
    case Tuple{absent,tail}: absent

def Identity.unique_tail(head: Z.Zones.Key,rest: List<&2,Z.Zones.Key>,valid: Identity.Unique(Con{head,rest})) -> Identity.Unique(rest):
  match valid:
    case Tuple{absent,tail}: tail

law Identity.perm_absent:
  for -left: List<&2,M.Monsters.State>
  for -right: List<&2,M.Monsters.State>
  for +permutation: R.Roster.Perm<left,right>
  for +id: U32
  for +valid: Identity.Absent(id,Z.Zones.keys(right))
  Identity.Absent(id,Z.Zones.keys(left))

def Identity.perm_absent(left,right,permutation,id,valid):
  match permutation:
    case R.Roster.Same{equal}:
      %Equal.sym(List<&2,M.Monsters.State>,left,right,equal) : Identity.Absent(id,Z.Zones.keys(_))
      valid
    case R.Roster.Common{head,lt,rt,ls,rs,tails}:
      +given = {(%rs : Identity.Absent(id,Z.Zones.keys(_)); valid) : Identity.Absent(id,Z.Zones.keys(Con{head,rt}))}
      %Equal.sym(List<&2,M.Monsters.State>,left,Con{head,lt},ls) : Identity.Absent(id,Z.Zones.keys(_))
      Tuple{Identity.absent_head(id,Z.Zones.key(head),Z.Zones.keys(rt),given),Identity.perm_absent(lt,rt,tails,id,Identity.absent_tail(id,Z.Zones.key(head),Z.Zones.keys(rt),given))}
    case R.Roster.Swap{first,second,rest,ls,rs}:
      %Equal.sym(List<&2,M.Monsters.State>,left,Con{first,Con{second,rest}},ls) : Identity.Absent(id,Z.Zones.keys(_))
      Identity.absent_swap(id,Z.Zones.key(second),Z.Zones.key(first),Z.Zones.keys(rest),(%rs : Identity.Absent(id,Z.Zones.keys(_)); valid))
    case R.Roster.Then{middle,before,after}:
      Identity.perm_absent(left,middle,before,id,Identity.perm_absent(middle,right,after,id,valid))

law Identity.perm_unique:
  for -left: List<&2,M.Monsters.State>
  for -right: List<&2,M.Monsters.State>
  for +permutation: R.Roster.Perm<left,right>
  for +valid: Identity.Monsters(right)
  Identity.Monsters(left)

def Identity.perm_unique(left,right,permutation,valid):
  match permutation:
    case R.Roster.Same{equal}:
      %Equal.sym(List<&2,M.Monsters.State>,left,right,equal) : Identity.Monsters(_)
      valid
    case R.Roster.Common{head,lt,rt,ls,rs,tails}:
      +given = {(%rs : Identity.Monsters(_); valid) : Identity.Monsters(Con{head,rt})}
      %Equal.sym(List<&2,M.Monsters.State>,left,Con{head,lt},ls) : Identity.Monsters(_)
      Tuple{Identity.perm_absent(lt,rt,tails,Identity.mid(Z.Zones.key(head)),Identity.unique_head(Z.Zones.key(head),Z.Zones.keys(rt),given)),Identity.perm_unique(lt,rt,tails,Identity.unique_tail(Z.Zones.key(head),Z.Zones.keys(rt),given))}
    case R.Roster.Swap{first,second,rest,ls,rs}:
      %Equal.sym(List<&2,M.Monsters.State>,left,Con{first,Con{second,rest}},ls) : Identity.Monsters(_)
      Identity.unique_swap(Z.Zones.key(second),Z.Zones.key(first),Z.Zones.keys(rest),(%rs : Identity.Monsters(_); valid))
    case R.Roster.Then{middle,before,after}:
      Identity.perm_unique(left,middle,before,Identity.perm_unique(middle,right,after,valid))

law Identity.conserved_unique:
  for +before: List<&2,M.Monsters.State>
  for +after: List<&2,M.Monsters.State>
  for +conserved: Z.Zones.Conserved<before,after>
  for +valid: Identity.Monsters(before)
  Identity.Monsters(after)

def Identity.conserved_unique(before,after,conserved,valid):
  match conserved:
    case Z.Zones.Conserved{ordered,permutation,keys}:
      %Equal.sym(List<&2,Z.Zones.Key>,Z.Zones.keys(after),Z.Zones.keys(ordered),keys) : Identity.Unique(_)
      Identity.perm_unique(ordered,before,permutation,valid)

law Identity.conserved_absent:
  for +before: List<&2,M.Monsters.State>
  for +after: List<&2,M.Monsters.State>
  for +conserved: Z.Zones.Conserved<before,after>
  for +id: U32
  for +valid: Identity.Absent(id,Z.Zones.keys(before))
  Identity.Absent(id,Z.Zones.keys(after))

def Identity.conserved_absent(before,after,conserved,id,valid):
  match conserved:
    case Z.Zones.Conserved{ordered,permutation,keys}:
      %Equal.sym(List<&2,Z.Zones.Key>,Z.Zones.keys(after),Z.Zones.keys(ordered),keys) : Identity.Absent(id,_)
      Identity.perm_absent(ordered,before,permutation,id,valid)

law Identity.duplicate_rejected:
  for +first: Z.Zones.Key
  for +second: Z.Zones.Key
  for +rest: List<&2,Z.Zones.Key>
  for +same: {Identity.mid(first) == Identity.mid(second) : U32}
  for +valid: Identity.Unique(Con{first,Con{second,rest}})
  Empty

def Identity.duplicate_rejected(first,second,rest,same,valid):
  +different = Identity.absent_head(Identity.mid(first),second,rest,Identity.unique_head(first,Con{second,rest},valid))
  +bad = {(%Equal.sym(U32,Identity.mid(first),Identity.mid(second),same) : {U32.is_eq(Identity.mid(first),_) == False{} : Bool}; different) : {U32.is_eq(Identity.mid(first),Identity.mid(first)) == False{} : Bool}}
  N.Numeric.true_ne_false((%N.Numeric.u32_eq_refl(Identity.mid(first)) : {_ == False{} : Bool}; bad))

law Identity.strike_unique:
  for +monsters: List<&2,M.Monsters.State>
  for +target: U32
  for +damage: U32
  for +valid: Identity.Monsters(monsters)
  Identity.Monsters(R.Roster.struck(R.Roster.strike(monsters,target,damage)))

def Identity.strike_unique(monsters,target,damage,valid):
  Identity.conserved_unique(monsters,R.Roster.struck(R.Roster.strike(monsters,target,damage)),Z.Zones.strike_conserves(monsters,target,damage),valid)

law Identity.run_zones_unique:
  for +monsters: List<&2,M.Monsters.State>
  for +p0: List<&2,A.AI.Plan>
  for +p1: List<&2,A.AI.Plan>
  for +p2: List<&2,A.AI.Plan>
  for +p3: List<&2,A.AI.Plan>
  for +zones: Z.Zones.All(monsters)
  for +valid: Identity.Monsters(monsters)
  Identity.Monsters(A.AI.monsters(A.AI.run_zones(monsters,p0,p1,p2,p3)))

def Identity.run_zones_unique(monsters,p0,p1,p2,p3,zones,valid):
  Identity.conserved_unique(monsters,A.AI.monsters(A.AI.run_zones(monsters,p0,p1,p2,p3)),Z.Zones.run_zones_conserves(monsters,p0,p1,p2,p3,zones),valid)

law Identity.at_key:
  for +mid: U32
  for +kind: U32
  for +rare: U32
  for +pos: P.Players.Pos
  for +maximum: U32
  {Z.Zones.key(Pop.Population.at(mid,kind,rare,pos,maximum)) == Z.Zones.Key{mid,Nav.Navigation.zone(pos)} : Z.Zones.Key}

def Identity.at_key(mid,kind,rare,pos,maximum):
  match pos:
    case P.Players.Pos{zone,x,y,dir,moving}: Z.Zones.spawn_key(mid,kind,rare,zone,x,y,maximum)

law Identity.monster_key:
  for +maps: T.Terrain.Maps
  for +mid: U32
  for +zone: U32
  for +salt: U32
  for +rare: U32
  {Z.Zones.key(Pop.Population.monster(maps,mid,zone,salt,rare)) == Z.Zones.Key{mid,zone} : Z.Zones.Key}

def Identity.monster_key(maps,mid,zone,salt,rare):
  +kind = Pop.Population.kind(zone,salt)
  +spot = Place.Placement.spot(maps,zone,U32.add(U32.mul(salt,977),mid))
  %Place.Placement.spot_zone(maps,zone,U32.add(U32.mul(salt,977),mid)) : {Z.Zones.key(Pop.Population.monster(maps,mid,zone,salt,rare)) == Z.Zones.Key{mid,_} : Z.Zones.Key}
  Identity.at_key(mid,kind,rare,spot,U32.mul(Pop.Population.maximum(kind),U32.add(1,U32.mul(7,rare))))

law Identity.boss_key:
  for +mid: U32
  for +zone: U32
  {Z.Zones.key(Pop.Population.boss(mid,zone)) == Z.Zones.Key{mid,zone} : Z.Zones.Key}

def Identity.boss_key(mid,zone): Identity.at_key(mid,U32.add(6,zone),0,Pop.Population.boss_pos(zone),Pop.Population.maximum(U32.add(6,zone)))

def Identity.population_keys(+count: Nat,+zone: U32,+base: U32) -> List<&2,Z.Zones.Key>:
  match count:
    case Zero{}: Nil{}
    case Succ{rest}: Con{Z.Zones.Key{U32.add(U32.add(base,1),U32.from_nat(rest)),zone},Identity.population_keys(rest,zone,base)}

law Identity.cons_equal:
  for +head: Z.Zones.Key
  for +tail: List<&2,Z.Zones.Key>
  for +desired: Z.Zones.Key
  for +rest: List<&2,Z.Zones.Key>
  for +heq: {head == desired : Z.Zones.Key}
  for +teq: {tail == rest : List<&2,Z.Zones.Key>}
  {Con{head,tail} == Con{desired,rest} : List<&2,Z.Zones.Key>}

def Identity.cons_equal(head,tail,desired,rest,heq,teq):
  %heq : {Con{head,tail} == Con{_,rest} : List<&2,Z.Zones.Key>}
  %teq : {Con{head,tail} == Con{head,_} : List<&2,Z.Zones.Key>}
  {==}

law Identity.populate_value_keys:
  for +count: Nat
  for +maps: T.Terrain.Maps
  for +zone: U32
  for +base: U32
  {Z.Zones.keys(Pop.Population.populate_value(count,maps,zone,base)) == Identity.population_keys(count,zone,base) : List<&2,Z.Zones.Key>}

def Identity.populate_value_keys(count,maps,zone,base):
  match count:
    case Zero{}: {==}
    case Succ{rest}:
      +n = U32.from_nat(rest)
      +mid = U32.add(U32.add(base,1),n)
      +rare = L.Landscape.pick(U32.is_lt(U32.mod(L.Landscape.hash(mid,U32.add(zone,31)),100),Pop.Population.rare_pct),1,0)
      +salt = L.Landscape.hash(U32.add(U32.add(U32.mul(zone,100),1),n),555)
      Identity.cons_equal(Z.Zones.key(Pop.Population.monster(maps,mid,zone,salt,rare)),Z.Zones.keys(Pop.Population.populate_value(rest,maps,zone,base)),Z.Zones.Key{mid,zone},Identity.population_keys(rest,zone,base),Identity.monster_key(maps,mid,zone,salt,rare),Identity.populate_value_keys(rest,maps,zone,base))

law Identity.populate_keys:
  for +count: Nat
  for +maps: T.Terrain.Maps
  for +zone: U32
  for +base: U32
  {Z.Zones.keys(Pop.Population.populate(count,maps,zone,base)) == Identity.population_keys(count,zone,base) : List<&2,Z.Zones.Key>}

def Identity.populate_keys(count,maps,zone,base):
  %Equal.sym(List<&2,M.Monsters.State>,Pop.Population.populate(count,maps,zone,base),Pop.Population.populate_value(count,maps,zone,base),Pop.Population.populate_refines(count,maps,zone,base)) : {Z.Zones.keys(_) == Identity.population_keys(count,zone,base) : List<&2,Z.Zones.Key>}
  Identity.populate_value_keys(count,maps,zone,base)

def Identity.boss_keys() -> List<&2,Z.Zones.Key>:
  [Z.Zones.Key{1,0},Z.Zones.Key{2,1},Z.Zones.Key{3,2},Z.Zones.Key{4,3}]

law Identity.bosses_keys:
  {Z.Zones.keys(Pop.Population.bosses) == Identity.boss_keys : List<&2,Z.Zones.Key>}

def Identity.bosses_keys(): {==}

law Identity.concat_keys:
  for +left: List<&2,M.Monsters.State>
  for +right: List<&2,M.Monsters.State>
  for +lk: List<&2,Z.Zones.Key>
  for +rk: List<&2,Z.Zones.Key>
  for +leq: {Z.Zones.keys(left) == lk : List<&2,Z.Zones.Key>}
  for +req: {Z.Zones.keys(right) == rk : List<&2,Z.Zones.Key>}
  {Z.Zones.keys(R.Roster.concat(left,right)) == Z.Zones.concat_keys(lk,rk) : List<&2,Z.Zones.Key>}

def Identity.concat_keys(left,right,lk,rk,leq,req):
  %leq : {Z.Zones.keys(R.Roster.concat(left,right)) == Z.Zones.concat_keys(_,rk) : List<&2,Z.Zones.Key>}
  %req : {Z.Zones.keys(R.Roster.concat(left,right)) == Z.Zones.concat_keys(Z.Zones.keys(left),_) : List<&2,Z.Zones.Key>}
  Z.Zones.keys_concat(left,right)

def Identity.initial_keys() -> List<&2,Z.Zones.Key>:
  Z.Zones.concat_keys(Identity.boss_keys,Z.Zones.concat_keys(Identity.population_keys(9n,0,100),Z.Zones.concat_keys(Identity.population_keys(9n,1,200),Identity.population_keys(9n,2,300))))

law Identity.initial_exact:
  for +maps: T.Terrain.Maps
  {Z.Zones.keys(Pop.Population.initial(maps)) == Identity.initial_keys : List<&2,Z.Zones.Key>}

def Identity.initial_exact(maps):
  +a = Pop.Population.populate(9n,maps,0,100)
  +b = Pop.Population.populate(9n,maps,1,200)
  +c = Pop.Population.populate(9n,maps,2,300)
  +ak = Identity.population_keys(9n,0,100)
  +bk = Identity.population_keys(9n,1,200)
  +ck = Identity.population_keys(9n,2,300)
  Identity.concat_keys(Pop.Population.bosses,R.Roster.concat(a,R.Roster.concat(b,c)),Identity.boss_keys,Z.Zones.concat_keys(ak,Z.Zones.concat_keys(bk,ck)),Identity.bosses_keys,Identity.concat_keys(a,R.Roster.concat(b,c),ak,Z.Zones.concat_keys(bk,ck),Identity.populate_keys(9n,maps,0,100),Identity.concat_keys(b,c,bk,ck,Identity.populate_keys(9n,maps,1,200),Identity.populate_keys(9n,maps,2,300))))


# A concrete witness for all 31 fixed IDs; initial_exact transports it to
# the actual generated records for every map, hence for every seed.
law Identity.initial_distinct:
  Identity.Unique(Identity.initial_keys)

def Identity.initial_distinct(): Tuple{Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}},Tuple{Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}},Tuple{Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}}}}}}}}}}}}}}}}}}}}}}}}}}},Tuple{Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}}}}}}}}}}}}}}}}}}}}}}}}}},Tuple{Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}}}}}}}}}}}}}}}}}}}}}}}}},Tuple{Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}}}}}}}}}}}}}}}}}}}}}}}},Tuple{Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}}}}}}}}}}}}}}}}}}}}}}},Tuple{Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}}}}}}}}}}}}}}}}}}}}}},Tuple{Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}}}}}}}}}}}}}}}}}}}}},Tuple{Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}}}}}}}}}}}}}}}}}}}},Tuple{Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}}}}}}}}}}}}}}}}}}},Tuple{Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}}}}}}}}}}}}}}}}}},Tuple{Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}}}}}}}}}}}}}}}}},Tuple{Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}}}}}}}}}}}}}}}},Tuple{Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}}}}}}}}}}}}}}},Tuple{Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}}}}}}}}}}}}}},Tuple{Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}}}}}}}}}}}}},Tuple{Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}}}}}}}}}}}},Tuple{Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}}}}}}}}}}},Tuple{Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}}}}}}}}}},Tuple{Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}}}}}}}}},Tuple{Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}}}}}}}},Tuple{Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}}}}}}},Tuple{Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}}}}}},Tuple{Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}}}}},Tuple{Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}}}},Tuple{Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}}},Tuple{Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}},Tuple{Tuple{{==},Tuple{{==},Unit{}}},Tuple{Tuple{{==},Unit{}},Tuple{Unit{},Unit{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

law Identity.initial_unique:
  for +maps: T.Terrain.Maps
  Identity.Monsters(Pop.Population.initial(maps))

def Identity.initial_unique(maps):
  %Equal.sym(List<&2,Z.Zones.Key>,Z.Zones.keys(Pop.Population.initial(maps)),Identity.initial_keys,Identity.initial_exact(maps)) : Identity.Unique(_)
  Identity.initial_distinct

law Identity.fresh_unique:
  for +world: U32
  for +seed: U32
  for +now: U32
  Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(Pop.Population.fresh(world,seed,now))))

def Identity.fresh_unique(world,seed,now): Identity.initial_unique(L.Landscape.maps(seed))

def Identity.ok_zones(state: S.Simulation.State,valid: S.Simulation.OK<state>) -> Z.Zones.All(S.Simulation.monsters(state)):
  match valid:
    case S.Simulation.OK{players,monsters,zones}: zones

law Identity.finish_unique:
  for +prepared: S.Simulation.Prepared
  for +p0: List<&2,A.AI.Plan>
  for +p1: List<&2,A.AI.Plan>
  for +p2: List<&2,A.AI.Plan>
  for +p3: List<&2,A.AI.Plan>
  for +rules: S.Simulation.Rules
  for +zones: Z.Zones.All(S.Simulation.prepared_monsters(prepared))
  for +valid: Identity.Monsters(S.Simulation.prepared_monsters(prepared))
  Identity.Monsters(S.Simulation.monsters(S.Simulation.state(S.Simulation.finish(prepared,p0,p1,p2,p3,rules))))

def Identity.finish_unique(prepared,p0,p1,p2,p3,rules,zones,valid):
  match prepared:
    case S.Simulation.Prepared{meta,monsters,upkeep,running}:
      match running:
        case False{}: valid
        case True{}:
          match rules:
            case S.Simulation.Rules{spawn_x,spawn_y,timer}: Identity.run_zones_unique(monsters,p0,p1,p2,p3,zones,valid)

law Identity.tick_unique:
  for +state: S.Simulation.State
  for +plan: S.Simulation.Plan
  for +rules: S.Simulation.Rules
  for +zones: Z.Zones.All(S.Simulation.monsters(state))
  for +valid: Identity.Monsters(S.Simulation.monsters(state))
  Identity.Monsters(S.Simulation.monsters(S.Simulation.state(S.Simulation.tick(state,plan,rules))))

def Identity.tick_unique(state,plan,rules,zones,valid):
  match plan:
    case S.Simulation.Plan{players,p0,p1,p2,p3}:
      +prepared = S.Simulation.begin(state,players,rules)
      +same = Equal.sym(List<&2,M.Monsters.State>,S.Simulation.prepared_monsters(prepared),S.Simulation.monsters(state),S.Simulation.begin_monsters(state,players,rules))
      Identity.finish_unique(prepared,p0,p1,p2,p3,rules,(%same : Z.Zones.All(_); zones),(%same : Identity.Monsters(_); valid))

law Identity.actions_unique:
  for +prepared: S.Simulation.Prepared
  for +actions: Walk.Locomotion.Actions
  for +rules: S.Simulation.Rules
  for +zones: Z.Zones.All(S.Simulation.prepared_monsters(prepared))
  for +valid: Identity.Monsters(S.Simulation.prepared_monsters(prepared))
  Identity.Monsters(S.Simulation.monsters(S.Simulation.state(Walk.Locomotion.finish(prepared,actions,rules))))

def Identity.actions_unique(prepared,actions,rules,zones,valid):
  match actions:
    case Walk.Locomotion.Actions{p0,p1,p2,p3}: Identity.finish_unique(prepared,p0,p1,p2,p3,rules,zones,valid)

law Identity.planning_finish_unique:
  for +prepared: S.Simulation.Prepared
  for +maps: T.Terrain.Maps
  for +c0: List<&2,Plan.Planning.Context>
  for +c1: List<&2,Plan.Planning.Context>
  for +c2: List<&2,Plan.Planning.Context>
  for +c3: List<&2,Plan.Planning.Context>
  for +rules: S.Simulation.Rules
  for +zones: Z.Zones.All(S.Simulation.prepared_monsters(prepared))
  for +valid: Identity.Monsters(S.Simulation.prepared_monsters(prepared))
  Identity.Monsters(S.Simulation.monsters(S.Simulation.state(Plan.Planning.finish(prepared,maps,c0,c1,c2,c3,rules))))

def Identity.planning_finish_unique(prepared,maps,c0,c1,c2,c3,rules,zones,valid):
  +actions = Plan.Planning.actions(S.Simulation.prepared_monsters(prepared),c0,c1,c2,c3,maps,S.Simulation.clock(S.Simulation.prepared_meta(prepared)))
  %Equal.sym(S.Simulation.Result,Plan.Planning.finish(prepared,maps,c0,c1,c2,c3,rules),Walk.Locomotion.finish(prepared,actions,rules),Plan.Planning.finish_refines(prepared,maps,c0,c1,c2,c3,rules)) : Identity.Monsters(S.Simulation.monsters(S.Simulation.state(_)))
  Identity.actions_unique(prepared,actions,rules,zones,valid)

law Identity.planning_tick_unique:
  for +state: S.Simulation.State
  for +input: Plan.Planning.Input
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  for +zones: Z.Zones.All(S.Simulation.monsters(state))
  for +valid: Identity.Monsters(S.Simulation.monsters(state))
  Identity.Monsters(S.Simulation.monsters(S.Simulation.state(Plan.Planning.tick(state,input,maps,rules))))

def Identity.planning_tick_unique(state,input,maps,rules,zones,valid):
  match input:
    case Plan.Planning.Input{c0,c1,c2,c3}:
      +prepared = Walk.Locomotion.begin(state,maps,rules)
      +same = Equal.sym(List<&2,M.Monsters.State>,S.Simulation.prepared_monsters(prepared),S.Simulation.monsters(state),Plan.Planning.begin_monsters(state,maps,rules))
      Identity.planning_finish_unique(prepared,maps,c0,c1,c2,c3,rules,(%same : Z.Zones.All(_); zones),(%same : Identity.Monsters(_); valid))

law Identity.planning_trace_unique:
  for +inputs: List<&2,Plan.Planning.Input>
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  for +ok: S.Simulation.OK<state>
  for +valid: Identity.Monsters(S.Simulation.monsters(state))
  Identity.Monsters(S.Simulation.monsters(Plan.Planning.trace(inputs,state,maps,rules)))

def Identity.planning_trace_unique(inputs,state,maps,rules,ok,valid):
  match inputs:
    case Nil{}: valid
    case Con{head,rest}: Identity.planning_trace_unique(rest,S.Simulation.state(Plan.Planning.tick(state,head,maps,rules)),maps,rules,Plan.Planning.tick_ok(state,head,maps,rules,ok),Identity.planning_tick_unique(state,head,maps,rules,Identity.ok_zones(state,ok),valid))

law Identity.battle_strike_unique:
  for +input: B.Battle.Input
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +valid: Identity.Monsters(S.Simulation.monsters(state))
  Identity.Monsters(S.Simulation.monsters(B.Battle.state(B.Battle.strike(input,state,pid,score))))

def Identity.battle_strike_unique(input,state,pid,score,valid):
  match input:
    case B.Battle.Input{mid,damage,plan}:
      %Equal.sym(List<&2,M.Monsters.State>,S.Simulation.monsters(B.Battle.state(B.Battle.strike(B.Battle.Input{mid,damage,plan},state,pid,score))),R.Roster.struck(R.Roster.strike(S.Simulation.monsters(state),mid,damage)),B.Battle.strike_monsters(mid,damage,plan,state,pid,score)) : Identity.Monsters(_)
      Identity.strike_unique(S.Simulation.monsters(state),mid,damage,valid)

law Identity.battle_run_unique:
  for +inputs: List<&2,B.Battle.Input>
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +valid: Identity.Monsters(S.Simulation.monsters(state))
  Identity.Monsters(S.Simulation.monsters(B.Battle.state(B.Battle.run(inputs,state,pid,score))))

def Identity.battle_run_unique(inputs,state,pid,score,valid):
  match inputs:
    case Nil{}: valid
    case Con{head,rest}: Identity.battle_run_unique(rest,B.Battle.state(B.Battle.strike(head,state,pid,score)),pid,score,Identity.battle_strike_unique(head,state,pid,score,valid))

law Identity.execute_unique:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +admitted: K.Combat.Result
  for +inputs: List<&2,B.Battle.Input>
  for +pid: U32
  for +score: U32
  for +valid: Identity.Monsters(monsters)
  Identity.Monsters(S.Simulation.monsters(B.Battle.state(B.Battle.execute(meta,monsters,admitted,inputs,pid,score))))

def Identity.execute_unique(meta,monsters,admitted,inputs,pid,score,valid):
  match admitted:
    case K.Combat.Result{players,attacker}:
      match attacker:
        case None{}: valid
        case Some{actor}: Identity.battle_run_unique(inputs,S.Simulation.State{meta,players,monsters},pid,score,valid)

law Identity.command_unique:
  for +kind: K.Combat.Kind
  for +state: S.Simulation.State
  for +inputs: List<&2,B.Battle.Input>
  for +pid: U32
  for +score: U32
  for +valid: Identity.Monsters(S.Simulation.monsters(state))
  Identity.Monsters(S.Simulation.monsters(B.Battle.state(B.Battle.command(kind,state,inputs,pid,score))))

def Identity.command_unique(kind,state,inputs,pid,score,valid):
  match state:
    case S.Simulation.State{meta,players,monsters}: Identity.execute_unique(meta,monsters,K.Combat.run(players,pid,kind,S.Simulation.phase(meta)),inputs,pid,score,valid)

law Identity.transition_unique:
  for +transition: B.Battle.Transition
  for +state: S.Simulation.State
  for +ok: S.Simulation.OK<state>
  for +valid: Identity.Monsters(S.Simulation.monsters(state))
  Identity.Monsters(S.Simulation.monsters(B.Battle.transition(transition,state)))

def Identity.transition_unique(transition,state,ok,valid):
  match transition:
    case B.Battle.Fighting{kind,inputs,pid,score}: Identity.command_unique(kind,state,inputs,pid,score,valid)
    case B.Battle.Ticking{plan,rules}: Identity.tick_unique(state,plan,rules,Identity.ok_zones(state,ok),valid)

law Identity.trace_unique:
  for +transitions: List<&2,B.Battle.Transition>
  for +state: S.Simulation.State
  for +ok: S.Simulation.OK<state>
  for +valid: Identity.Monsters(S.Simulation.monsters(state))
  Identity.Monsters(S.Simulation.monsters(B.Battle.trace(transitions,state)))

def Identity.trace_unique(transitions,state,ok,valid):
  match transitions:
    case Nil{}: valid
    case Con{head,rest}: Identity.trace_unique(rest,B.Battle.transition(head,state),B.Battle.transition_ok(head,state,ok),Identity.transition_unique(head,state,ok,valid))


law Identity.initial_nonzero_keys:
  Identity.Absent(0,Identity.initial_keys)

def Identity.initial_nonzero_keys(): Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Tuple{{==},Unit{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

law Identity.initial_nonzero:
  for +maps: T.Terrain.Maps
  Identity.Absent(0,Z.Zones.keys(Pop.Population.initial(maps)))

def Identity.initial_nonzero(maps):
  %Equal.sym(List<&2,Z.Zones.Key>,Z.Zones.keys(Pop.Population.initial(maps)),Identity.initial_keys,Identity.initial_exact(maps)) : Identity.Absent(0,_)
  Identity.initial_nonzero_keys

law Identity.fresh_planning_trace_unique:
  for +inputs: List<&2,Plan.Planning.Input>
  for +world: U32
  for +seed: U32
  for +now: U32
  for +timer: U32
  Identity.Monsters(S.Simulation.monsters(Plan.Planning.trace(inputs,T.Terrain.simulation(Pop.Population.fresh(world,seed,now)),L.Landscape.maps(seed),Plan.Planning.rules(timer))))

def Identity.fresh_planning_trace_unique(inputs,world,seed,now,timer):
  Identity.planning_trace_unique(inputs,T.Terrain.simulation(Pop.Population.fresh(world,seed,now)),L.Landscape.maps(seed),Plan.Planning.rules(timer),Pop.Population.fresh_ok(world,seed,now),Identity.fresh_unique(world,seed,now))

law Identity.fresh_battle_trace_unique:
  for +transitions: List<&2,B.Battle.Transition>
  for +world: U32
  for +seed: U32
  for +now: U32
  Identity.Monsters(S.Simulation.monsters(B.Battle.trace(transitions,T.Terrain.simulation(Pop.Population.fresh(world,seed,now)))))

def Identity.fresh_battle_trace_unique(transitions,world,seed,now):
  Identity.trace_unique(transitions,T.Terrain.simulation(Pop.Population.fresh(world,seed,now)),Pop.Population.fresh_ok(world,seed,now),Identity.fresh_unique(world,seed,now))
