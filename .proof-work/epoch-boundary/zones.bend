# Valid zones and conservation through the server's four-zone AI update.
import Base
import ./monsters.bend as M
import ./roster.bend as R
import ./ai.bend as A
import ./vitals.bend as V

# An explicit finite-zone witness, with no assumption about arbitrary U32s.
type Zones.Valid<-zone: U32> is Data:
  Zones.Hollow{equal: {zone == 0 : U32}}
  Zones.Cavern{equal: {zone == 1 : U32}}
  Zones.Frost{equal: {zone == 2 : U32}}
  Zones.Rift{equal: {zone == 3 : U32}}

def Zones.All(monsters: List<&2, M.Monsters.State>) -> Data:
  match monsters:
    case Nil{}:
      Unit
    case Con{head, rest}:
      Sigma<&2, &2, Zones.Valid<R.Roster.zone_of(head)>, (valid => Zones.All(rest))>

def Zones.join(a: List<&2, M.Monsters.State>, b: List<&2, M.Monsters.State>, c: List<&2, M.Monsters.State>, d: List<&2, M.Monsters.State>) -> List<&2, M.Monsters.State>:
  R.Roster.concat(a, R.Roster.concat(b, R.Roster.concat(c, d)))

def Zones.partition(+monsters: List<&2, M.Monsters.State>) -> List<&2, M.Monsters.State>:
  Zones.join(R.Roster.zone(monsters, 0), R.Roster.zone(monsters, 1), R.Roster.zone(monsters, 2), R.Roster.zone(monsters, 3))

law Zones.prefix_perm:
  for +prefix: List<&2, M.Monsters.State>
  for +left: List<&2, M.Monsters.State>
  for +right: List<&2, M.Monsters.State>
  for +permutation: R.Roster.Perm<left, right>
  R.Roster.Perm<R.Roster.concat(prefix, left), R.Roster.concat(prefix, right)>

def Zones.prefix_perm(prefix, left, right, permutation):
  match prefix:
    case Nil{}:
      permutation
    case Con{head, rest}:
      R.Roster.Common{head, R.Roster.concat(rest, left), R.Roster.concat(rest, right), {==}, {==}, Zones.prefix_perm(rest, left, right, permutation)}

law Zones.pull_head:
  for +prefix: List<&2, M.Monsters.State>
  for +head: M.Monsters.State
  for +rest: List<&2, M.Monsters.State>
  R.Roster.Perm<R.Roster.concat(prefix, Con{head, rest}), Con{head, R.Roster.concat(prefix, rest)}>

def Zones.pull_head(prefix, head, rest):
  match prefix:
    case Nil{}:
      R.Roster.Same{{==}}
    case Con{first, tail}:
      R.Roster.Then{Con{first, Con{head, R.Roster.concat(tail, rest)}}, R.Roster.Common{first, R.Roster.concat(tail, Con{head, rest}), Con{head, R.Roster.concat(tail, rest)}, {==}, {==}, Zones.pull_head(tail, head, rest)}, R.Roster.Swap{first, head, R.Roster.concat(tail, rest), {==}, {==}}}

def Zones.insert(+zone: U32, +head: M.Monsters.State, a: List<&2, M.Monsters.State>, b: List<&2, M.Monsters.State>, c: List<&2, M.Monsters.State>, d: List<&2, M.Monsters.State>) -> List<&2, M.Monsters.State>:
  Zones.join(R.Roster.keep(U32.is_eq(zone, 0), head, a), R.Roster.keep(U32.is_eq(zone, 1), head, b), R.Roster.keep(U32.is_eq(zone, 2), head, c), R.Roster.keep(U32.is_eq(zone, 3), head, d))

law Zones.insert_perm:
  for +zone: U32
  for +head: M.Monsters.State
  for +a: List<&2, M.Monsters.State>
  for +b: List<&2, M.Monsters.State>
  for +c: List<&2, M.Monsters.State>
  for +d: List<&2, M.Monsters.State>
  for +valid: Zones.Valid<zone>
  R.Roster.Perm<Zones.insert(zone, head, a, b, c, d), Con{head, Zones.join(a, b, c, d)}>

def Zones.insert_perm(zone, head, a, b, c, d, valid):
  match valid:
    case Zones.Hollow{equal}:
      %Equal.sym(U32, zone, 0, equal) : R.Roster.Perm<Zones.insert(_, head, a, b, c, d), Con{head, Zones.join(a, b, c, d)}>
      R.Roster.Same{{==}}
    case Zones.Cavern{equal}:
      %Equal.sym(U32, zone, 1, equal) : R.Roster.Perm<Zones.insert(_, head, a, b, c, d), Con{head, Zones.join(a, b, c, d)}>
      Zones.pull_head(a, head, R.Roster.concat(b, R.Roster.concat(c, d)))
    case Zones.Frost{equal}:
      %Equal.sym(U32, zone, 2, equal) : R.Roster.Perm<Zones.insert(_, head, a, b, c, d), Con{head, Zones.join(a, b, c, d)}>
      R.Roster.Then{R.Roster.concat(a, Con{head, R.Roster.concat(b, R.Roster.concat(c, d))}), Zones.prefix_perm(a, R.Roster.concat(b, Con{head, R.Roster.concat(c, d)}), Con{head, R.Roster.concat(b, R.Roster.concat(c, d))}, Zones.pull_head(b, head, R.Roster.concat(c, d))), Zones.pull_head(a, head, R.Roster.concat(b, R.Roster.concat(c, d)))}
    case Zones.Rift{equal}:
      %Equal.sym(U32, zone, 3, equal) : R.Roster.Perm<Zones.insert(_, head, a, b, c, d), Con{head, Zones.join(a, b, c, d)}>
      R.Roster.Then{R.Roster.concat(a, R.Roster.concat(b, Con{head, R.Roster.concat(c, d)})), Zones.prefix_perm(a, R.Roster.concat(b, R.Roster.concat(c, Con{head, d})), R.Roster.concat(b, Con{head, R.Roster.concat(c, d)}), Zones.prefix_perm(b, R.Roster.concat(c, Con{head, d}), Con{head, R.Roster.concat(c, d)}, Zones.pull_head(c, head, d))), R.Roster.Then{R.Roster.concat(a, Con{head, R.Roster.concat(b, R.Roster.concat(c, d))}), Zones.prefix_perm(a, R.Roster.concat(b, Con{head, R.Roster.concat(c, d)}), Con{head, R.Roster.concat(b, R.Roster.concat(c, d))}, Zones.pull_head(b, head, R.Roster.concat(c, d))), Zones.pull_head(a, head, R.Roster.concat(b, R.Roster.concat(c, d)))}}

law Zones.partition_perm:
  for +monsters: List<&2, M.Monsters.State>
  for +valid: Zones.All(monsters)
  R.Roster.Perm<Zones.partition(monsters), monsters>

def Zones.partition_perm(monsters, valid):
  match monsters:
    case Nil{}:
      R.Roster.Same{{==}}
    case Con{head, rest}:
      match valid:
        case Tuple{head_ok, rest_ok}:
          R.Roster.Then{Con{head, Zones.partition(rest)}, Zones.insert_perm(R.Roster.zone_of(head), head, R.Roster.zone(rest, 0), R.Roster.zone(rest, 1), R.Roster.zone(rest, 2), R.Roster.zone(rest, 3), head_ok), R.Roster.Common{head, Zones.partition(rest), rest, {==}, {==}, Zones.partition_perm(rest, rest_ok)}}

law Zones.partition_count:
  for +monsters: List<&2, M.Monsters.State>
  for +valid: Zones.All(monsters)
  {R.Roster.length(Zones.partition(monsters)) == R.Roster.length(monsters) : Nat}

def Zones.partition_count(monsters, valid):
  R.Roster.perm_length(Zones.partition(monsters), monsters, Zones.partition_perm(monsters, valid))

law Zones.concat_length:
  for +left: List<&2, M.Monsters.State>
  for +right: List<&2, M.Monsters.State>
  {R.Roster.length(R.Roster.concat(left, right)) == Nat.add(R.Roster.length(left), R.Roster.length(right)) : Nat}

def Zones.concat_length(left, right):
  match left:
    case Nil{}:
      {==}
    case Con{head, rest}:
      %Zones.concat_length(rest, right) : {Succ{R.Roster.length(R.Roster.concat(rest, right))} == Succ{_} : Nat}
      {==}

law Zones.merge_count:
  for +left: A.AI.Result
  for +right: A.AI.Result
  for +before_left: List<&2, M.Monsters.State>
  for +before_right: List<&2, M.Monsters.State>
  for +left_count: {R.Roster.length(A.AI.monsters(left)) == R.Roster.length(before_left) : Nat}
  for +right_count: {R.Roster.length(A.AI.monsters(right)) == R.Roster.length(before_right) : Nat}
  {R.Roster.length(A.AI.monsters(A.AI.merge(left, right))) == R.Roster.length(R.Roster.concat(before_left, before_right)) : Nat}

def Zones.merge_count(left, right, before_left, before_right, left_count, right_count):
  match left:
    case A.AI.Result{lm, lh}:
      match right:
        case A.AI.Result{rm, rh}:
          %Equal.sym(Nat, R.Roster.length(R.Roster.concat(before_left, before_right)), Nat.add(R.Roster.length(before_left), R.Roster.length(before_right)), Zones.concat_length(before_left, before_right)) : {R.Roster.length(R.Roster.concat(lm, rm)) == _ : Nat}
          %Equal.sym(Nat, R.Roster.length(R.Roster.concat(lm, rm)), Nat.add(R.Roster.length(lm), R.Roster.length(rm)), Zones.concat_length(lm, rm)) : {_ == Nat.add(R.Roster.length(before_left), R.Roster.length(before_right)) : Nat}
          %left_count : {Nat.add(R.Roster.length(lm), R.Roster.length(rm)) == Nat.add(_, R.Roster.length(before_right)) : Nat}
          %right_count : {Nat.add(R.Roster.length(lm), R.Roster.length(rm)) == Nat.add(R.Roster.length(lm), _) : Nat}
          {==}

law Zones.run_zones_count:
  for +monsters: List<&2, M.Monsters.State>
  for +p0: List<&2, A.AI.Plan>
  for +p1: List<&2, A.AI.Plan>
  for +p2: List<&2, A.AI.Plan>
  for +p3: List<&2, A.AI.Plan>
  for +valid: Zones.All(monsters)
  {R.Roster.length(A.AI.monsters(A.AI.run_zones(monsters, p0, p1, p2, p3))) == R.Roster.length(monsters) : Nat}

def Zones.run_zones_count(monsters, p0, p1, p2, p3, valid):
  Equal.trans(Nat, R.Roster.length(A.AI.monsters(A.AI.run_zones(monsters, p0, p1, p2, p3))), R.Roster.length(Zones.partition(monsters)), R.Roster.length(monsters), Zones.merge_count(A.AI.run(R.Roster.zone(monsters, 0), p0), A.AI.merge(A.AI.run(R.Roster.zone(monsters, 1), p1), A.AI.merge(A.AI.run(R.Roster.zone(monsters, 2), p2), A.AI.run(R.Roster.zone(monsters, 3), p3))), R.Roster.zone(monsters, 0), R.Roster.concat(R.Roster.zone(monsters, 1), R.Roster.concat(R.Roster.zone(monsters, 2), R.Roster.zone(monsters, 3))), A.AI.run_count(R.Roster.zone(monsters, 0), p0), Zones.merge_count(A.AI.run(R.Roster.zone(monsters, 1), p1), A.AI.merge(A.AI.run(R.Roster.zone(monsters, 2), p2), A.AI.run(R.Roster.zone(monsters, 3), p3)), R.Roster.zone(monsters, 1), R.Roster.concat(R.Roster.zone(monsters, 2), R.Roster.zone(monsters, 3)), A.AI.run_count(R.Roster.zone(monsters, 1), p1), Zones.merge_count(A.AI.run(R.Roster.zone(monsters, 2), p2), A.AI.run(R.Roster.zone(monsters, 3), p3), R.Roster.zone(monsters, 2), R.Roster.zone(monsters, 3), A.AI.run_count(R.Roster.zone(monsters, 2), p2), A.AI.run_count(R.Roster.zone(monsters, 3), p3)))), Zones.partition_count(monsters, valid))

# Stable identity and zone; movement, health, target, and cooldown are mutable.
type Zones.Key is Data:
  Zones.Key{mid: U32, zone: U32}

def Zones.key(monster: M.Monsters.State) -> Zones.Key:
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      Zones.Key{mid, zone}

law Zones.spawn_positive_key:
  for +value: Nat
  for +mid: U32
  for +kind: U32
  for +rare: U32
  for +zone: U32
  for +x: U32
  for +y: U32
  for +maximum: U32
  {Zones.key(M.Monsters.spawn_positive(value, mid, kind, rare, zone, x, y, maximum)) == Zones.Key{mid, zone} : Zones.Key}

def Zones.spawn_positive_key(value, mid, kind, rare, zone, x, y, maximum):
  match value:
    case Zero{}:
      {==}
    case Succ{rest}:
      {==}

law Zones.spawn_key:
  for +mid: U32
  for +kind: U32
  for +rare: U32
  for +zone: U32
  for +x: U32
  for +y: U32
  for +maximum: U32
  {Zones.key(M.Monsters.spawn(mid, kind, rare, zone, x, y, maximum)) == Zones.Key{mid, zone} : Zones.Key}

def Zones.spawn_key(mid, kind, rare, zone, x, y, maximum):
  Zones.spawn_positive_key(U32.to_nat(maximum), mid, kind, rare, zone, x, y, maximum)

law Zones.aim_key:
  for +monster: M.Monsters.State
  for +nx: U32
  for +ny: U32
  for +target: U32
  for +attack: U32
  {Zones.key(M.Monsters.aim(monster, nx, ny, target, attack)) == Zones.key(monster) : Zones.Key}

def Zones.aim_key(monster, nx, ny, target, attack):
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      {==}

law Zones.wait_key:
  for +monster: M.Monsters.State
  {Zones.key(M.Monsters.wait(monster)) == Zones.key(monster) : Zones.Key}

def Zones.wait_key(monster):
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      {==}

law Zones.with_vitals_key:
  for +monster: M.Monsters.State
  for +vitals: V.Vitals.State
  {Zones.key(M.Monsters.with_vitals(monster, vitals)) == Zones.key(monster) : Zones.Key}

def Zones.with_vitals_key(monster, vitals):
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      match vitals:
        case V.Vitals.State{hp2, xp2, dead2, respawn2, attack2, spin2}:
          {==}

law Zones.upkeep_key:
  for +monster: M.Monsters.State
  for +amount: U32
  {Zones.key(M.Monsters.active(monster, amount)) == Zones.key(monster) : Zones.Key}

def Zones.upkeep_key(monster, amount):
  Zones.with_vitals_key(monster, V.Vitals.live_tick(M.Monsters.vitals(monster), amount, M.Monsters.maximum(monster)))

law Zones.ready_tick_key:
  for +ready: Bool
  for +monster: M.Monsters.State
  {Zones.key(M.Monsters.tick_state(M.Monsters.ready_tick(ready, monster))) == Zones.key(monster) : Zones.Key}

def Zones.ready_tick_key(ready, monster):
  match ready:
    case True{}:
      {==}
    case False{}:
      Zones.wait_key(monster)

law Zones.dead_tick_key:
  for +permanent: Bool
  for +ready: Bool
  for +monster: M.Monsters.State
  {Zones.key(M.Monsters.tick_state(M.Monsters.dead_tick(permanent, ready, monster))) == Zones.key(monster) : Zones.Key}

def Zones.dead_tick_key(permanent, ready, monster):
  match permanent:
    case True{}:
      {==}
    case False{}:
      Zones.ready_tick_key(ready, monster)

law Zones.tick_gate_key:
  for +is_dead: Bool
  for +permanent: Bool
  for +ready: Bool
  for +monster: M.Monsters.State
  for +amount: U32
  {Zones.key(M.Monsters.tick_state(M.Monsters.tick_gate(is_dead, permanent, ready, monster, amount))) == Zones.key(monster) : Zones.Key}

def Zones.tick_gate_key(is_dead, permanent, ready, monster, amount):
  match is_dead:
    case True{}:
      Zones.dead_tick_key(permanent, ready, monster)
    case False{}:
      Zones.upkeep_key(monster, amount)

law Zones.tick_key:
  for +monster: M.Monsters.State
  {Zones.key(M.Monsters.tick_state(M.Monsters.tick(monster))) == Zones.key(monster) : Zones.Key}

def Zones.tick_key(monster):
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      Zones.tick_gate_key(U32.is_eq(dead, 1), U32.is_eq(respawn, 4294967295), U32.is_le(respawn, 1), M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}, M.Monsters.choose(U32.is_eq(kind, 9), 30, 0))

law Zones.attack_key:
  for +ready: Bool
  for +monster: M.Monsters.State
  for +target: U32
  for +damage: U32
  {Zones.key(A.AI.monster(A.AI.attack(ready, monster, target, damage))) == Zones.key(monster) : Zones.Key}

def Zones.attack_key(ready, monster, target, damage):
  match ready:
    case False{}:
      {==}
    case True{}:
      match monster:
        case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
          {==}

law Zones.plan_key:
  for +monster: M.Monsters.State
  for +plan: A.AI.Plan
  {Zones.key(A.AI.monster(A.AI.active(monster, plan))) == Zones.key(monster) : Zones.Key}

def Zones.plan_key(monster, plan):
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      match plan:
        case A.AI.Rest{}:
          {==}
        case A.AI.Move{nx, ny, next_target}:
          {==}
        case A.AI.Attack{next_target, damage}:
          Zones.attack_key(U32.is_eq(attack, 0), M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}, next_target, damage)
        case A.AI.Spawn{new_kind, new_rare, nx, ny, new_maximum}:
          {==}

law Zones.rebirth_key:
  for +monster: M.Monsters.State
  for +plan: A.AI.Plan
  {Zones.key(A.AI.monster(A.AI.rebirth(monster, plan))) == Zones.key(monster) : Zones.Key}

def Zones.rebirth_key(monster, plan):
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      match plan:
        case A.AI.Rest{}:
          {==}
        case A.AI.Move{nx, ny, next_target}:
          {==}
        case A.AI.Attack{next_target, damage}:
          {==}
        case A.AI.Spawn{new_kind, new_rare, nx, ny, new_maximum}:
          Zones.spawn_key(mid, new_kind, new_rare, zone, nx, ny, new_maximum)

law Zones.commit_key:
  for +tick: M.Monsters.Tick
  for +plan: A.AI.Plan
  {Zones.key(A.AI.monster(A.AI.commit(tick, plan))) == Zones.key(M.Monsters.tick_state(tick)) : Zones.Key}

def Zones.commit_key(tick, plan):
  match tick:
    case M.Monsters.Tick{monster, phase}:
      match phase:
        case M.Monsters.Active{}:
          Zones.plan_key(monster, plan)
        case M.Monsters.Dormant{}:
          {==}
        case M.Monsters.Rebirth{}:
          Zones.rebirth_key(monster, plan)

law Zones.step_key:
  for +monster: M.Monsters.State
  for +plan: A.AI.Plan
  {Zones.key(A.AI.monster(A.AI.step(monster, plan))) == Zones.key(monster) : Zones.Key}

def Zones.step_key(monster, plan):
  Equal.trans(Zones.Key, Zones.key(A.AI.monster(A.AI.step(monster, plan))), Zones.key(M.Monsters.tick_state(M.Monsters.tick(monster))), Zones.key(monster), Zones.commit_key(M.Monsters.tick(monster), plan), Zones.tick_key(monster))

def Zones.keys(monsters: List<&2, M.Monsters.State>) -> List<&2, Zones.Key>:
  match monsters:
    case Nil{}:
      Nil{}
    case Con{head, rest}:
      Con{Zones.key(head), Zones.keys(rest)}

def Zones.concat_keys(left: List<&2, Zones.Key>, right: List<&2, Zones.Key>) -> List<&2, Zones.Key>:
  match left:
    case Nil{}:
      right
    case Con{head, rest}:
      Con{head, Zones.concat_keys(rest, right)}

law Zones.keys_concat:
  for +left: List<&2, M.Monsters.State>
  for +right: List<&2, M.Monsters.State>
  {Zones.keys(R.Roster.concat(left, right)) == Zones.concat_keys(Zones.keys(left), Zones.keys(right)) : List<&2, Zones.Key>}

def Zones.keys_concat(left, right):
  match left:
    case Nil{}:
      {==}
    case Con{head, rest}:
      %Zones.keys_concat(rest, right) : {Con{Zones.key(head), Zones.keys(R.Roster.concat(rest, right))} == Con{Zones.key(head), _} : List<&2, Zones.Key>}
      {==}

law Zones.prepend_keys:
  for +step: A.AI.Step
  for +result: A.AI.Result
  {Zones.keys(A.AI.monsters(A.AI.prepend(step, result))) == Con{Zones.key(A.AI.monster(step)), Zones.keys(A.AI.monsters(result))} : List<&2, Zones.Key>}

def Zones.prepend_keys(step, result):
  match step:
    case A.AI.Step{monster, hit}:
      match result:
        case A.AI.Result{monsters, hits}:
          {==}

law Zones.run_keys:
  for +monsters: List<&2, M.Monsters.State>
  for +plans: List<&2, A.AI.Plan>
  {Zones.keys(A.AI.monsters(A.AI.run(monsters, plans))) == Zones.keys(monsters) : List<&2, Zones.Key>}

def Zones.run_keys(monsters, plans):
  match monsters:
    case Nil{}:
      {==}
    case Con{head, rest}:
      match plans:
        case Nil{}:
          %Equal.sym(List<&2, Zones.Key>, Zones.keys(A.AI.monsters(A.AI.prepend(A.AI.step(head, A.AI.Rest{}), A.AI.run(rest, Nil{})))), Con{Zones.key(A.AI.monster(A.AI.step(head, A.AI.Rest{}))), Zones.keys(A.AI.monsters(A.AI.run(rest, Nil{})))}, Zones.prepend_keys(A.AI.step(head, A.AI.Rest{}), A.AI.run(rest, Nil{}))) : {_ == Con{Zones.key(head), Zones.keys(rest)} : List<&2, Zones.Key>}
          %Equal.sym(Zones.Key, Zones.key(A.AI.monster(A.AI.step(head, A.AI.Rest{}))), Zones.key(head), Zones.step_key(head, A.AI.Rest{})) : {Con{_, Zones.keys(A.AI.monsters(A.AI.run(rest, Nil{})))} == Con{Zones.key(head), Zones.keys(rest)} : List<&2, Zones.Key>}
          %Zones.run_keys(rest, Nil{}) : {Con{Zones.key(head), Zones.keys(A.AI.monsters(A.AI.run(rest, Nil{})))} == Con{Zones.key(head), _} : List<&2, Zones.Key>}
          {==}
        case Con{plan, later}:
          %Equal.sym(List<&2, Zones.Key>, Zones.keys(A.AI.monsters(A.AI.prepend(A.AI.step(head, plan), A.AI.run(rest, later)))), Con{Zones.key(A.AI.monster(A.AI.step(head, plan))), Zones.keys(A.AI.monsters(A.AI.run(rest, later)))}, Zones.prepend_keys(A.AI.step(head, plan), A.AI.run(rest, later))) : {_ == Con{Zones.key(head), Zones.keys(rest)} : List<&2, Zones.Key>}
          %Equal.sym(Zones.Key, Zones.key(A.AI.monster(A.AI.step(head, plan))), Zones.key(head), Zones.step_key(head, plan)) : {Con{_, Zones.keys(A.AI.monsters(A.AI.run(rest, later)))} == Con{Zones.key(head), Zones.keys(rest)} : List<&2, Zones.Key>}
          %Zones.run_keys(rest, later) : {Con{Zones.key(head), Zones.keys(A.AI.monsters(A.AI.run(rest, later)))} == Con{Zones.key(head), _} : List<&2, Zones.Key>}
          {==}

law Zones.merge_keys:
  for +left: A.AI.Result
  for +right: A.AI.Result
  for +before_left: List<&2, M.Monsters.State>
  for +before_right: List<&2, M.Monsters.State>
  for +left_keys: {Zones.keys(A.AI.monsters(left)) == Zones.keys(before_left) : List<&2, Zones.Key>}
  for +right_keys: {Zones.keys(A.AI.monsters(right)) == Zones.keys(before_right) : List<&2, Zones.Key>}
  {Zones.keys(A.AI.monsters(A.AI.merge(left, right))) == Zones.keys(R.Roster.concat(before_left, before_right)) : List<&2, Zones.Key>}

def Zones.merge_keys(left, right, before_left, before_right, left_keys, right_keys):
  match left:
    case A.AI.Result{lm, lh}:
      match right:
        case A.AI.Result{rm, rh}:
          %Equal.sym(List<&2, Zones.Key>, Zones.keys(R.Roster.concat(before_left, before_right)), Zones.concat_keys(Zones.keys(before_left), Zones.keys(before_right)), Zones.keys_concat(before_left, before_right)) : {Zones.keys(R.Roster.concat(lm, rm)) == _ : List<&2, Zones.Key>}
          %Equal.sym(List<&2, Zones.Key>, Zones.keys(R.Roster.concat(lm, rm)), Zones.concat_keys(Zones.keys(lm), Zones.keys(rm)), Zones.keys_concat(lm, rm)) : {_ == Zones.concat_keys(Zones.keys(before_left), Zones.keys(before_right)) : List<&2, Zones.Key>}
          %left_keys : {Zones.concat_keys(Zones.keys(lm), Zones.keys(rm)) == Zones.concat_keys(_, Zones.keys(before_right)) : List<&2, Zones.Key>}
          %right_keys : {Zones.concat_keys(Zones.keys(lm), Zones.keys(rm)) == Zones.concat_keys(Zones.keys(lm), _) : List<&2, Zones.Key>}
          {==}

law Zones.run_zones_keys:
  for +monsters: List<&2, M.Monsters.State>
  for +p0: List<&2, A.AI.Plan>
  for +p1: List<&2, A.AI.Plan>
  for +p2: List<&2, A.AI.Plan>
  for +p3: List<&2, A.AI.Plan>
  {Zones.keys(A.AI.monsters(A.AI.run_zones(monsters, p0, p1, p2, p3))) == Zones.keys(Zones.partition(monsters)) : List<&2, Zones.Key>}

def Zones.run_zones_keys(monsters, p0, p1, p2, p3):
  Zones.merge_keys(A.AI.run(R.Roster.zone(monsters, 0), p0), A.AI.merge(A.AI.run(R.Roster.zone(monsters, 1), p1), A.AI.merge(A.AI.run(R.Roster.zone(monsters, 2), p2), A.AI.run(R.Roster.zone(monsters, 3), p3))), R.Roster.zone(monsters, 0), R.Roster.concat(R.Roster.zone(monsters, 1), R.Roster.concat(R.Roster.zone(monsters, 2), R.Roster.zone(monsters, 3))), Zones.run_keys(R.Roster.zone(monsters, 0), p0), Zones.merge_keys(A.AI.run(R.Roster.zone(monsters, 1), p1), A.AI.merge(A.AI.run(R.Roster.zone(monsters, 2), p2), A.AI.run(R.Roster.zone(monsters, 3), p3)), R.Roster.zone(monsters, 1), R.Roster.concat(R.Roster.zone(monsters, 2), R.Roster.zone(monsters, 3)), Zones.run_keys(R.Roster.zone(monsters, 1), p1), Zones.merge_keys(A.AI.run(R.Roster.zone(monsters, 2), p2), A.AI.run(R.Roster.zone(monsters, 3), p3), R.Roster.zone(monsters, 2), R.Roster.zone(monsters, 3), Zones.run_keys(R.Roster.zone(monsters, 2), p2), Zones.run_keys(R.Roster.zone(monsters, 3), p3))))

# A full-record permutation followed by pointwise preservation of ID and zone.
# This does not assert that mutable fields such as health remain unchanged.
type Zones.Conserved<-before: List<&2, M.Monsters.State>, -after: List<&2, M.Monsters.State>> is Data:
  Zones.Conserved{ordered: List<&2, M.Monsters.State>, permutation: R.Roster.Perm<ordered, before>, keys: {Zones.keys(after) == Zones.keys(ordered) : List<&2, Zones.Key>}}

law Zones.run_zones_conserves:
  for +monsters: List<&2, M.Monsters.State>
  for +p0: List<&2, A.AI.Plan>
  for +p1: List<&2, A.AI.Plan>
  for +p2: List<&2, A.AI.Plan>
  for +p3: List<&2, A.AI.Plan>
  for +valid: Zones.All(monsters)
  Zones.Conserved<monsters, A.AI.monsters(A.AI.run_zones(monsters, p0, p1, p2, p3))>

def Zones.run_zones_conserves(monsters, p0, p1, p2, p3, valid):
  Zones.Conserved{Zones.partition(monsters), Zones.partition_perm(monsters, valid), Zones.run_zones_keys(monsters, p0, p1, p2, p3)}

def Zones.key_zone(key: Zones.Key) -> U32:
  match key:
    case Zones.Key{mid, zone}:
      zone

law Zones.key_zone_of:
  for +monster: M.Monsters.State
  {Zones.key_zone(Zones.key(monster)) == R.Roster.zone_of(monster) : U32}

def Zones.key_zone_of(monster):
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      {==}

law Zones.step_zone:
  for +monster: M.Monsters.State
  for +plan: A.AI.Plan
  {R.Roster.zone_of(A.AI.monster(A.AI.step(monster, plan))) == R.Roster.zone_of(monster) : U32}

def Zones.step_zone(monster, plan):
  %Zones.key_zone_of(A.AI.monster(A.AI.step(monster, plan))) : {_ == R.Roster.zone_of(monster) : U32}
  %Zones.key_zone_of(monster) : {Zones.key_zone(Zones.key(A.AI.monster(A.AI.step(monster, plan)))) == _ : U32}
  %Zones.step_key(monster, plan) : {Zones.key_zone(Zones.key(A.AI.monster(A.AI.step(monster, plan)))) == Zones.key_zone(_) : U32}
  {==}

law Zones.step_valid:
  for +monster: M.Monsters.State
  for +plan: A.AI.Plan
  for +valid: Zones.Valid<R.Roster.zone_of(monster)>
  Zones.Valid<R.Roster.zone_of(A.AI.monster(A.AI.step(monster, plan)))>

def Zones.step_valid(monster, plan, valid):
  %Equal.sym(U32, R.Roster.zone_of(A.AI.monster(A.AI.step(monster, plan))), R.Roster.zone_of(monster), Zones.step_zone(monster, plan)) : Zones.Valid<_>
  valid

law Zones.keep_all:
  for +keep: Bool
  for +head: M.Monsters.State
  for +tail: List<&2, M.Monsters.State>
  for +head_ok: Zones.Valid<R.Roster.zone_of(head)>
  for +tail_ok: Zones.All(tail)
  Zones.All(R.Roster.keep(keep, head, tail))

def Zones.keep_all(keep, head, tail, head_ok, tail_ok):
  match keep:
    case True{}:
      Tuple{head_ok, tail_ok}
    case False{}:
      tail_ok

law Zones.zone_all:
  for +monsters: List<&2, M.Monsters.State>
  for +zone: U32
  for +valid: Zones.All(monsters)
  Zones.All(R.Roster.zone(monsters, zone))

def Zones.zone_all(monsters, zone, valid):
  match monsters:
    case Nil{}:
      Unit{}
    case Con{head, rest}:
      match valid:
        case Tuple{head_ok, rest_ok}:
          Zones.keep_all(U32.is_eq(R.Roster.zone_of(head), zone), head, R.Roster.zone(rest, zone), head_ok, Zones.zone_all(rest, zone, rest_ok))

law Zones.concat_all:
  for +left: List<&2, M.Monsters.State>
  for +right: List<&2, M.Monsters.State>
  for +left_ok: Zones.All(left)
  for +right_ok: Zones.All(right)
  Zones.All(R.Roster.concat(left, right))

def Zones.concat_all(left, right, left_ok, right_ok):
  match left:
    case Nil{}:
      right_ok
    case Con{head, rest}:
      match left_ok:
        case Tuple{head_ok, rest_ok}:
          Tuple{head_ok, Zones.concat_all(rest, right, rest_ok, right_ok)}

law Zones.prepend_all:
  for +step: A.AI.Step
  for +result: A.AI.Result
  for +head_ok: Zones.Valid<R.Roster.zone_of(A.AI.monster(step))>
  for +rest_ok: Zones.All(A.AI.monsters(result))
  Zones.All(A.AI.monsters(A.AI.prepend(step, result)))

def Zones.prepend_all(step, result, head_ok, rest_ok):
  match step:
    case A.AI.Step{monster, hit}:
      match result:
        case A.AI.Result{monsters, hits}:
          Tuple{head_ok, rest_ok}

law Zones.run_all:
  for +monsters: List<&2, M.Monsters.State>
  for +plans: List<&2, A.AI.Plan>
  for +valid: Zones.All(monsters)
  Zones.All(A.AI.monsters(A.AI.run(monsters, plans)))

def Zones.run_all(monsters, plans, valid):
  match monsters:
    case Nil{}:
      Unit{}
    case Con{head, rest}:
      match plans:
        case Nil{}:
          match valid:
            case Tuple{head_ok, rest_ok}:
              Zones.prepend_all(A.AI.step(head, A.AI.Rest{}), A.AI.run(rest, Nil{}), Zones.step_valid(head, A.AI.Rest{}, head_ok), Zones.run_all(rest, Nil{}, rest_ok))
        case Con{plan, later}:
          match valid:
            case Tuple{head_ok, rest_ok}:
              Zones.prepend_all(A.AI.step(head, plan), A.AI.run(rest, later), Zones.step_valid(head, plan, head_ok), Zones.run_all(rest, later, rest_ok))

law Zones.merge_all:
  for +left: A.AI.Result
  for +right: A.AI.Result
  for +left_ok: Zones.All(A.AI.monsters(left))
  for +right_ok: Zones.All(A.AI.monsters(right))
  Zones.All(A.AI.monsters(A.AI.merge(left, right)))

def Zones.merge_all(left, right, left_ok, right_ok):
  match left:
    case A.AI.Result{lm, lh}:
      match right:
        case A.AI.Result{rm, rh}:
          Zones.concat_all(lm, rm, left_ok, right_ok)

law Zones.run_zones_all:
  for +monsters: List<&2, M.Monsters.State>
  for +p0: List<&2, A.AI.Plan>
  for +p1: List<&2, A.AI.Plan>
  for +p2: List<&2, A.AI.Plan>
  for +p3: List<&2, A.AI.Plan>
  for +valid: Zones.All(monsters)
  Zones.All(A.AI.monsters(A.AI.run_zones(monsters, p0, p1, p2, p3)))

def Zones.run_zones_all(monsters, p0, p1, p2, p3, valid):
  Zones.merge_all(A.AI.run(R.Roster.zone(monsters, 0), p0), A.AI.merge(A.AI.run(R.Roster.zone(monsters, 1), p1), A.AI.merge(A.AI.run(R.Roster.zone(monsters, 2), p2), A.AI.run(R.Roster.zone(monsters, 3), p3))), Zones.run_all(R.Roster.zone(monsters, 0), p0, Zones.zone_all(monsters, 0, valid)), Zones.merge_all(A.AI.run(R.Roster.zone(monsters, 1), p1), A.AI.merge(A.AI.run(R.Roster.zone(monsters, 2), p2), A.AI.run(R.Roster.zone(monsters, 3), p3)), Zones.run_all(R.Roster.zone(monsters, 1), p1, Zones.zone_all(monsters, 1, valid)), Zones.merge_all(A.AI.run(R.Roster.zone(monsters, 2), p2), A.AI.run(R.Roster.zone(monsters, 3), p3), Zones.run_all(R.Roster.zone(monsters, 2), p2, Zones.zone_all(monsters, 2, valid)), Zones.run_all(R.Roster.zone(monsters, 3), p3, Zones.zone_all(monsters, 3, valid)))))


law Zones.finish_key:
  for +monster: M.Monsters.State
  for +hit: V.Vitals.Hit
  for +damage: U32
  {Zones.key(M.Monsters.result(M.Monsters.finish(monster, hit, damage))) == Zones.key(monster) : Zones.Key}

def Zones.finish_key(monster, hit, damage):
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      match hit:
        case V.Vitals.Hit{next, fell}:
          match next:
            case V.Vitals.State{hp2, xp2, dead2, respawn2, attack2, spin2}:
              {==}

law Zones.hit_gate_key:
  for +is_dead: Bool
  for +monster: M.Monsters.State
  for +damage: U32
  for +timer: U32
  {Zones.key(M.Monsters.result(M.Monsters.hit_gate(is_dead, monster, damage, timer))) == Zones.key(monster) : Zones.Key}

def Zones.hit_gate_key(is_dead, monster, damage, timer):
  match is_dead:
    case True{}:
      {==}
    case False{}:
      Zones.finish_key(monster, V.Vitals.hit_gate(False{}, M.Monsters.vitals(monster), damage, timer), damage)

law Zones.hit_key:
  for +monster: M.Monsters.State
  for +damage: U32
  for +timer: U32
  {Zones.key(M.Monsters.result(M.Monsters.hit(monster, damage, timer))) == Zones.key(monster) : Zones.Key}

def Zones.hit_key(monster, damage, timer):
  Zones.hit_gate_key(U32.is_eq(V.Vitals.dead(M.Monsters.vitals(monster)), 1), monster, damage, timer)

law Zones.strike_result_keys:
  for +hit: M.Monsters.Hit
  for +others: List<&2, M.Monsters.State>
  {Zones.keys(R.Roster.struck(R.Roster.strike_result(hit, others))) == Con{Zones.key(M.Monsters.result(hit)), Zones.keys(others)} : List<&2, Zones.Key>}

def Zones.strike_result_keys(hit, others):
  match hit:
    case M.Monsters.Hit{monster, killed, dealt}:
      match monster:
        case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
          match killed:
            case False{}:
              {==}
            case True{}:
              {==}

law Zones.strike_taken_keys:
  for +taken: R.Roster.Take
  for +damage: U32
  {Zones.keys(R.Roster.struck(R.Roster.strike_taken(taken, damage))) == Zones.keys(R.Roster.restore(taken)) : List<&2, Zones.Key>}

def Zones.strike_taken_keys(taken, damage):
  match taken:
    case R.Roster.Take{others, found}:
      match found:
        case None{}:
          {==}
        case Some{monster}:
          %Equal.sym(List<&2, Zones.Key>, Zones.keys(R.Roster.struck(R.Roster.strike_result(M.Monsters.hit(monster, damage, R.Roster.respawn_time(M.Monsters.kind(monster))), others))), Con{Zones.key(M.Monsters.result(M.Monsters.hit(monster, damage, R.Roster.respawn_time(M.Monsters.kind(monster))))), Zones.keys(others)}, Zones.strike_result_keys(M.Monsters.hit(monster, damage, R.Roster.respawn_time(M.Monsters.kind(monster))), others)) : {_ == Con{Zones.key(monster), Zones.keys(others)} : List<&2, Zones.Key>}
          %Zones.hit_key(monster, damage, R.Roster.respawn_time(M.Monsters.kind(monster))) : {Con{Zones.key(M.Monsters.result(M.Monsters.hit(monster, damage, R.Roster.respawn_time(M.Monsters.kind(monster))))), Zones.keys(others)} == Con{_, Zones.keys(others)} : List<&2, Zones.Key>}
          {==}

law Zones.strike_conserves:
  for +monsters: List<&2, M.Monsters.State>
  for +target: U32
  for +damage: U32
  Zones.Conserved<monsters, R.Roster.struck(R.Roster.strike(monsters, target, damage))>

def Zones.strike_conserves(monsters, target, damage):
  Zones.Conserved{R.Roster.restore(R.Roster.take(monsters, target)), R.Roster.take_restores(monsters, target), Zones.strike_taken_keys(R.Roster.take(monsters, target), damage)}

def Zones.all_head(head: M.Monsters.State, rest: List<&2, M.Monsters.State>, valid: Zones.All(Con{head, rest})) -> Zones.Valid<R.Roster.zone_of(head)>:
  match valid:
    case Tuple{head_ok, rest_ok}:
      head_ok

def Zones.all_tail(head: M.Monsters.State, rest: List<&2, M.Monsters.State>, valid: Zones.All(Con{head, rest})) -> Zones.All(rest):
  match valid:
    case Tuple{head_ok, rest_ok}:
      rest_ok

law Zones.swap_all:
  for +first: M.Monsters.State
  for +second: M.Monsters.State
  for +rest: List<&2, M.Monsters.State>
  for +valid: Zones.All(Con{first, Con{second, rest}})
  Zones.All(Con{second, Con{first, rest}})

def Zones.swap_all(first, second, rest, valid):
  match valid:
    case Tuple{first_ok, later_ok}:
      match later_ok:
        case Tuple{second_ok, rest_ok}:
          Tuple{second_ok, Tuple{first_ok, rest_ok}}

law Zones.perm_all_back:
  for -left: List<&2, M.Monsters.State>
  for -right: List<&2, M.Monsters.State>
  for +permutation: R.Roster.Perm<left, right>
  for +valid: Zones.All(right)
  Zones.All(left)

def Zones.perm_all_back(left, right, permutation, valid):
  match permutation:
    case R.Roster.Same{equal}:
      %Equal.sym(List<&2, M.Monsters.State>, left, right, equal) : Zones.All(_)
      valid
    case R.Roster.Common{head, lt, rt, ls, rs, tails}:
      %Equal.sym(List<&2, M.Monsters.State>, left, Con{head, lt}, ls) : Zones.All(_)
      Tuple{Zones.all_head(head, rt, (%rs : Zones.All(_); valid)), Zones.perm_all_back(lt, rt, tails, Zones.all_tail(head, rt, (%rs : Zones.All(_); valid)))}
    case R.Roster.Swap{first, second, rest, ls, rs}:
      %Equal.sym(List<&2, M.Monsters.State>, left, Con{first, Con{second, rest}}, ls) : Zones.All(_)
      Zones.swap_all(second, first, rest, (%rs : Zones.All(_); valid))
    case R.Roster.Then{middle, before, after}:
      Zones.perm_all_back(left, middle, before, Zones.perm_all_back(middle, right, after, valid))

def Zones.KeysAll(keys: List<&2, Zones.Key>) -> Data:
  match keys:
    case Nil{}:
      Unit
    case Con{head, rest}:
      Sigma<&2, &2, Zones.Valid<Zones.key_zone(head)>, (valid => Zones.KeysAll(rest))>

law Zones.all_keys:
  for +monsters: List<&2, M.Monsters.State>
  for +valid: Zones.All(monsters)
  Zones.KeysAll(Zones.keys(monsters))

def Zones.all_keys(monsters, valid):
  match monsters:
    case Nil{}:
      Unit{}
    case Con{head, rest}:
      match valid:
        case Tuple{head_ok, rest_ok}:
          Tuple{(%Equal.sym(U32, Zones.key_zone(Zones.key(head)), R.Roster.zone_of(head), Zones.key_zone_of(head)) : Zones.Valid<_>; head_ok), Zones.all_keys(rest, rest_ok)}

law Zones.keys_all:
  for +monsters: List<&2, M.Monsters.State>
  for +valid: Zones.KeysAll(Zones.keys(monsters))
  Zones.All(monsters)

def Zones.keys_all(monsters, valid):
  match monsters:
    case Nil{}:
      Unit{}
    case Con{head, rest}:
      match valid:
        case Tuple{head_ok, rest_ok}:
          Tuple{(%Zones.key_zone_of(head) : Zones.Valid<_>; head_ok), Zones.keys_all(rest, rest_ok)}

law Zones.conserved_all:
  for +before: List<&2, M.Monsters.State>
  for +after: List<&2, M.Monsters.State>
  for +conserved: Zones.Conserved<before, after>
  for +valid: Zones.All(before)
  Zones.All(after)

def Zones.conserved_all(before, after, conserved, valid):
  match conserved:
    case Zones.Conserved{ordered, permutation, keys}:
      Zones.keys_all(after, (%Equal.sym(List<&2, Zones.Key>, Zones.keys(after), Zones.keys(ordered), keys) : Zones.KeysAll(_); Zones.all_keys(ordered, Zones.perm_all_back(ordered, before, permutation, valid))))

law Zones.strike_all:
  for +monsters: List<&2, M.Monsters.State>
  for +target: U32
  for +damage: U32
  for +valid: Zones.All(monsters)
  Zones.All(R.Roster.struck(R.Roster.strike(monsters, target, damage)))

def Zones.strike_all(monsters, target, damage, valid):
  Zones.conserved_all(monsters, R.Roster.struck(R.Roster.strike(monsters, target, damage)), Zones.strike_conserves(monsters, target, damage), valid)
