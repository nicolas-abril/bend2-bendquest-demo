# Safe list surgery over the server's shared monster lists.
import Base
import ./monsters.bend as M
import ./numeric.bend as N
import ./game.bend as G

def Roster.OK(monsters: List<&2, M.Monsters.State>) -> Data:
  match monsters:
    case Nil{}:
      Unit
    case Con{monster, rest}:
      Sigma<&2, &2, M.Monsters.OK(monster), (valid => Roster.OK(rest))>

def Roster.id(monster: M.Monsters.State) -> U32:
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      mid

type Roster.Take is Data:
  Roster.Take{others: List<&2, M.Monsters.State>, found: Maybe<&2, M.Monsters.State>}

def Roster.prepend(monster: M.Monsters.State, taken: Roster.Take) -> Roster.Take:
  match taken:
    case Roster.Take{others, found}:
      Roster.Take{Con{monster, others}, found}

def Roster.scan(tail: List<&2, M.Monsters.State>, head: M.Monsters.State, matches: Bool, +target: U32) -> Roster.Take:
  match tail:
    case Nil{}:
      match matches:
        case True{}:
          Roster.Take{Nil{}, Some{head}}
        case False{}:
          Roster.Take{Con{head, Nil{}}, None{}}
    case Con{next, rest}:
      match matches:
        case True{}:
          Roster.Take{Con{next, rest}, Some{head}}
        case False{}:
          +shared = next
          Roster.prepend(head, Roster.scan(rest, shared, U32.is_eq(Roster.id(shared), target), target))

def Roster.take(monsters: List<&2, M.Monsters.State>, +target: U32) -> Roster.Take:
  match monsters:
    case Nil{}:
      Roster.Take{Nil{}, None{}}
    case Con{head, rest}:
      +shared = head
      Roster.scan(rest, shared, U32.is_eq(Roster.id(shared), target), target)

def Roster.FoundOK(found: Maybe<&2, M.Monsters.State>) -> Data:
  match found:
    case None{}:
      Unit
    case Some{monster}:
      M.Monsters.OK(monster)

def Roster.others(taken: Roster.Take) -> List<&2, M.Monsters.State>:
  match taken:
    case Roster.Take{others, found}:
      others

def Roster.found(taken: Roster.Take) -> Maybe<&2, M.Monsters.State>:
  match taken:
    case Roster.Take{others, found}:
      found

type Roster.TakeOK<-taken: Roster.Take> is Data:
  Roster.ValidTake{others: Roster.OK(Roster.others(taken)), found: Roster.FoundOK(Roster.found(taken))}

law Roster.prepend_others:
  for +head: M.Monsters.State
  for +taken: Roster.Take
  {Roster.others(Roster.prepend(head, taken)) == Con{head, Roster.others(taken)} : List<&2, M.Monsters.State>}

def Roster.prepend_others(head, taken):
  match taken:
    case Roster.Take{others, found}:
      {==}

law Roster.prepend_found:
  for +head: M.Monsters.State
  for +taken: Roster.Take
  {Roster.found(Roster.prepend(head, taken)) == Roster.found(taken) : Maybe<&2, M.Monsters.State>}

def Roster.prepend_found(head, taken):
  match taken:
    case Roster.Take{others, found}:
      {==}

law Roster.prepend_ok:
  for +head: M.Monsters.State
  for +taken: Roster.Take
  for +head_ok: M.Monsters.OK(head)
  for +tail_ok: Roster.TakeOK<taken>
  Roster.TakeOK<Roster.prepend(head, taken)>

def Roster.prepend_ok(head, taken, head_ok, tail_ok):
  match tail_ok:
    case Roster.ValidTake{others_ok, found_ok}:
      Roster.ValidTake{
        (%Equal.sym(List<&2, M.Monsters.State>, Roster.others(Roster.prepend(head, taken)), Con{head, Roster.others(taken)}, Roster.prepend_others(head, taken)) : Roster.OK(_); Tuple{head_ok, others_ok}),
        (%Equal.sym(Maybe<&2, M.Monsters.State>, Roster.found(Roster.prepend(head, taken)), Roster.found(taken), Roster.prepend_found(head, taken)) : Roster.FoundOK(_); found_ok)}

law Roster.scan_ok:
  for +tail: List<&2, M.Monsters.State>
  for +head: M.Monsters.State
  for +matches: Bool
  for +target: U32
  for +tail_ok: Roster.OK(tail)
  for +head_ok: M.Monsters.OK(head)
  Roster.TakeOK<Roster.scan(tail, head, matches, target)>

def Roster.scan_ok(tail, head, matches, target, tail_ok, head_ok):
  match tail:
    case Nil{}:
      match matches:
        case True{}:
          Roster.ValidTake{Unit{}, head_ok}
        case False{}:
          Roster.ValidTake{Tuple{head_ok, Unit{}}, Unit{}}
    case Con{next, rest}:
      match matches:
        case True{}:
          Roster.ValidTake{tail_ok, head_ok}
        case False{}:
          match tail_ok:
            case Tuple{next_ok, rest_ok}:
              +shared = next
              Roster.prepend_ok(head, Roster.scan(rest, shared, U32.is_eq(Roster.id(shared), target), target), head_ok, Roster.scan_ok(rest, shared, U32.is_eq(Roster.id(shared), target), target, rest_ok, next_ok))

law Roster.take_ok:
  for +monsters: List<&2, M.Monsters.State>
  for +target: U32
  for +valid: Roster.OK(monsters)
  Roster.TakeOK<Roster.take(monsters, target)>

def Roster.take_ok(monsters, target, valid):
  match monsters:
    case Nil{}:
      Roster.ValidTake{Unit{}, Unit{}}
    case Con{head, rest}:
      match valid:
        case Tuple{head_ok, rest_ok}:
          +shared = head
          Roster.scan_ok(rest, shared, U32.is_eq(Roster.id(shared), target), target, rest_ok, head_ok)

def Roster.concat(left: List<&2, M.Monsters.State>, right: List<&2, M.Monsters.State>) -> List<&2, M.Monsters.State>:
  match left:
    case Nil{}:
      right
    case Con{head, rest}:
      Con{head, Roster.concat(rest, right)}

law Roster.concat_ok:
  for +left: List<&2, M.Monsters.State>
  for +right: List<&2, M.Monsters.State>
  for +left_ok: Roster.OK(left)
  for +right_ok: Roster.OK(right)
  Roster.OK(Roster.concat(left, right))

def Roster.concat_ok(left, right, left_ok, right_ok):
  match left:
    case Nil{}:
      right_ok
    case Con{head, rest}:
      match left_ok:
        case Tuple{head_ok, rest_ok}:
          Tuple{head_ok, Roster.concat_ok(rest, right, rest_ok, right_ok)}

type Roster.Kill is Data:
  Roster.Kill{kind: U32, rare: U32, zone: U32, mid: U32}

type Roster.Strike is Data:
  Roster.Strike{monsters: List<&2, M.Monsters.State>, kill: Maybe<&2, Roster.Kill>, dealt: U32}

def Roster.struck(strike: Roster.Strike) -> List<&2, M.Monsters.State>:
  match strike:
    case Roster.Strike{monsters, kill, dealt}:
      monsters

def Roster.respawn_time(kind: U32) -> U32:
  M.Monsters.choose(U32.is_ge(kind, 6), 4294967295, 80)

def Roster.strike_result(+hit: M.Monsters.Hit, others: List<&2, M.Monsters.State>) -> Roster.Strike:
  match hit:
    case M.Monsters.Hit{monster, killed, dealt}:
      match monster:
        case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
          match killed:
            case False{}:
              Roster.Strike{Con{M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}, others}, None{}, dealt}
            case True{}:
              Roster.Strike{Con{M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}, others}, Some{Roster.Kill{kind, rare, zone, mid}}, dealt}

def Roster.strike_taken(+taken: Roster.Take, damage: U32) -> Roster.Strike:
  match taken:
    case Roster.Take{others, found}:
      match found:
        case None{}:
          Roster.Strike{others, None{}, 0}
        case Some{monster}:
          Roster.strike_result(M.Monsters.hit(monster, damage, Roster.respawn_time(M.Monsters.kind(monster))), others)

def Roster.strike(monsters: List<&2, M.Monsters.State>, target: U32, damage: U32) -> Roster.Strike:
  Roster.strike_taken(Roster.take(monsters, target), damage)

law Roster.strike_result_ok:
  for +hit: M.Monsters.Hit
  for +others: List<&2, M.Monsters.State>
  for +hit_ok: M.Monsters.OK(M.Monsters.result(hit))
  for +others_ok: Roster.OK(others)
  Roster.OK(Roster.struck(Roster.strike_result(hit, others)))

def Roster.strike_result_ok(hit, others, hit_ok, others_ok):
  match hit:
    case M.Monsters.Hit{monster, killed, dealt}:
      match monster:
        case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
          match killed:
            case False{}:
              Tuple{hit_ok, others_ok}
            case True{}:
              Tuple{hit_ok, others_ok}

law Roster.strike_taken_ok:
  for +taken: Roster.Take
  for +damage: U32
  for +valid: Roster.TakeOK<taken>
  Roster.OK(Roster.struck(Roster.strike_taken(taken, damage)))

def Roster.strike_taken_ok(taken, damage, valid):
  match taken:
    case Roster.Take{others, found}:
      match found:
        case None{}:
          match valid:
            case Roster.ValidTake{others_ok, found_ok}:
              others_ok
        case Some{monster}:
          match valid:
            case Roster.ValidTake{others_ok, found_ok}:
              Roster.strike_result_ok(M.Monsters.hit(monster, damage, Roster.respawn_time(M.Monsters.kind(monster))), others, M.Monsters.hit_ok(monster, damage, Roster.respawn_time(M.Monsters.kind(monster)), found_ok), others_ok)

law Roster.strike_ok:
  for +monsters: List<&2, M.Monsters.State>
  for +target: U32
  for +damage: U32
  for +valid: Roster.OK(monsters)
  Roster.OK(Roster.struck(Roster.strike(monsters, target, damage)))

def Roster.strike_ok(monsters, target, damage, valid):
  Roster.strike_taken_ok(Roster.take(monsters, target), damage, Roster.take_ok(monsters, target, valid))

# Standard permutation evidence: identity, common head, adjacent swap,
# and transitivity. It relates complete monster records, not just IDs.
type Roster.Perm<-left: List<&2, M.Monsters.State>, -right: List<&2, M.Monsters.State>> is Data:
  Roster.Same{equal: {left == right : List<&2, M.Monsters.State>}}
  Roster.Common{head: M.Monsters.State, left_tail: List<&2, M.Monsters.State>, right_tail: List<&2, M.Monsters.State>, left_shape: {left == Con{head, left_tail} : List<&2, M.Monsters.State>}, right_shape: {right == Con{head, right_tail} : List<&2, M.Monsters.State>}, tails: Roster.Perm<left_tail, right_tail>}
  Roster.Swap{first: M.Monsters.State, second: M.Monsters.State, rest: List<&2, M.Monsters.State>, left_shape: {left == Con{first, Con{second, rest}} : List<&2, M.Monsters.State>}, right_shape: {right == Con{second, Con{first, rest}} : List<&2, M.Monsters.State>}}
  Roster.Then{middle: List<&2, M.Monsters.State>, before: Roster.Perm<left, middle>, after: Roster.Perm<middle, right>}

def Roster.restore(taken: Roster.Take) -> List<&2, M.Monsters.State>:
  match taken:
    case Roster.Take{others, found}:
      match found:
        case None{}:
          others
        case Some{monster}:
          Con{monster, others}

law Roster.prepend_restores:
  for +head: M.Monsters.State
  for +taken: Roster.Take
  Roster.Perm<Roster.restore(Roster.prepend(head, taken)), Con{head, Roster.restore(taken)}>

def Roster.prepend_restores(head, taken):
  match taken:
    case Roster.Take{others, found}:
      match found:
        case None{}:
          Roster.Same{{==}}
        case Some{monster}:
          Roster.Swap{monster, head, others, {==}, {==}}

law Roster.scan_restores:
  for +tail: List<&2, M.Monsters.State>
  for +head: M.Monsters.State
  for +matches: Bool
  for +target: U32
  Roster.Perm<Roster.restore(Roster.scan(tail, head, matches, target)), Con{head, tail}>

def Roster.scan_restores(tail, head, matches, target):
  match tail:
    case Nil{}:
      match matches:
        case True{}:
          Roster.Same{{==}}
        case False{}:
          Roster.Same{{==}}
    case Con{next, rest}:
      match matches:
        case True{}:
          Roster.Same{{==}}
        case False{}:
          Roster.Then{Con{head, Roster.restore(Roster.scan(rest, next, U32.is_eq(Roster.id(next), target), target))}, Roster.prepend_restores(head, Roster.scan(rest, next, U32.is_eq(Roster.id(next), target), target)), Roster.Common{head, Roster.restore(Roster.scan(rest, next, U32.is_eq(Roster.id(next), target), target)), Con{next, rest}, {==}, {==}, Roster.scan_restores(rest, next, U32.is_eq(Roster.id(next), target), target)}}

law Roster.take_restores:
  for +monsters: List<&2, M.Monsters.State>
  for +target: U32
  Roster.Perm<Roster.restore(Roster.take(monsters, target)), monsters>

def Roster.take_restores(monsters, target):
  match monsters:
    case Nil{}:
      Roster.Same{{==}}
    case Con{head, rest}:
      Roster.scan_restores(rest, head, U32.is_eq(Roster.id(head), target), target)

def Roster.length(monsters: List<&2, M.Monsters.State>) -> Nat:
  match monsters:
    case Nil{}:
      0n
    case Con{head, rest}:
      Succ{Roster.length(rest)}

law Roster.perm_length:
  for -left: List<&2, M.Monsters.State>
  for -right: List<&2, M.Monsters.State>
  for +permutation: Roster.Perm<left, right>
  {Roster.length(left) == Roster.length(right) : Nat}

def Roster.perm_length(left, right, permutation):
  match permutation:
    case Roster.Same{equal}:
      Equal.cong(List<&2, M.Monsters.State>, Nat, (xs => Roster.length(xs)), left, right, equal)
    case Roster.Common{head, lt, rt, ls, rs, tails}:
      %Equal.sym(List<&2, M.Monsters.State>, left, Con{head, lt}, ls) : {Roster.length(_) == Roster.length(right) : Nat}
      %Equal.sym(List<&2, M.Monsters.State>, right, Con{head, rt}, rs) : {Roster.length(Con{head, lt}) == Roster.length(_) : Nat}
      %Roster.perm_length(lt, rt, tails) : {Succ{Roster.length(lt)} == Succ{_} : Nat}
      {==}
    case Roster.Swap{first, second, rest, ls, rs}:
      %Equal.sym(List<&2, M.Monsters.State>, left, Con{first, Con{second, rest}}, ls) : {Roster.length(_) == Roster.length(right) : Nat}
      %Equal.sym(List<&2, M.Monsters.State>, right, Con{second, Con{first, rest}}, rs) : {Roster.length(Con{first, Con{second, rest}}) == Roster.length(_) : Nat}
      {==}
    case Roster.Then{middle, before, after}:
      Equal.trans(Nat, Roster.length(left), Roster.length(middle), Roster.length(right), Roster.perm_length(left, middle, before), Roster.perm_length(middle, right, after))

law Roster.take_count:
  for +monsters: List<&2, M.Monsters.State>
  for +target: U32
  {Roster.length(Roster.restore(Roster.take(monsters, target))) == Roster.length(monsters) : Nat}

def Roster.take_count(monsters, target):
  Roster.perm_length(Roster.restore(Roster.take(monsters, target)), monsters, Roster.take_restores(monsters, target))

law Roster.strike_result_count:
  for +hit: M.Monsters.Hit
  for +others: List<&2, M.Monsters.State>
  {Roster.length(Roster.struck(Roster.strike_result(hit, others))) == Succ{Roster.length(others)} : Nat}

def Roster.strike_result_count(hit, others):
  match hit:
    case M.Monsters.Hit{monster, killed, dealt}:
      match monster:
        case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
          match killed:
            case False{}:
              {==}
            case True{}:
              {==}

law Roster.strike_taken_count:
  for +taken: Roster.Take
  for +damage: U32
  {Roster.length(Roster.struck(Roster.strike_taken(taken, damage))) == Roster.length(Roster.restore(taken)) : Nat}

def Roster.strike_taken_count(taken, damage):
  match taken:
    case Roster.Take{others, found}:
      match found:
        case None{}:
          {==}
        case Some{monster}:
          Roster.strike_result_count(M.Monsters.hit(monster, damage, Roster.respawn_time(M.Monsters.kind(monster))), others)

law Roster.strike_count:
  for +monsters: List<&2, M.Monsters.State>
  for +target: U32
  for +damage: U32
  {Roster.length(Roster.struck(Roster.strike(monsters, target, damage))) == Roster.length(monsters) : Nat}

def Roster.strike_count(monsters, target, damage):
  Equal.trans(Nat, Roster.length(Roster.struck(Roster.strike(monsters, target, damage))), Roster.length(Roster.restore(Roster.take(monsters, target))), Roster.length(monsters), Roster.strike_taken_count(Roster.take(monsters, target), damage), Roster.take_count(monsters, target))

def Roster.FoundTarget(found: Maybe<&2, M.Monsters.State>, target: U32) -> Data:
  match found:
    case None{}:
      Unit
    case Some{monster}:
      {U32.is_eq(Roster.id(monster), target) == True{} : Bool}

law Roster.scan_target:
  for +tail: List<&2, M.Monsters.State>
  for +head: M.Monsters.State
  for +matches: Bool
  for +target: U32
  for +comparison: {matches == U32.is_eq(Roster.id(head), target) : Bool}
  Roster.FoundTarget(Roster.found(Roster.scan(tail, head, matches, target)), target)

def Roster.scan_target(tail, head, matches, target, comparison):
  match tail:
    case Nil{}:
      match matches:
        case True{}:
          Equal.sym(Bool, True{}, U32.is_eq(Roster.id(head), target), comparison)
        case False{}:
          Unit{}
    case Con{next, rest}:
      match matches:
        case True{}:
          Equal.sym(Bool, True{}, U32.is_eq(Roster.id(head), target), comparison)
        case False{}:
          %Equal.sym(Maybe<&2, M.Monsters.State>, Roster.found(Roster.prepend(head, Roster.scan(rest, next, U32.is_eq(Roster.id(next), target), target))), Roster.found(Roster.scan(rest, next, U32.is_eq(Roster.id(next), target), target)), Roster.prepend_found(head, Roster.scan(rest, next, U32.is_eq(Roster.id(next), target), target))) : Roster.FoundTarget(_, target)
          Roster.scan_target(rest, next, U32.is_eq(Roster.id(next), target), target, {==})

law Roster.take_target:
  for +monsters: List<&2, M.Monsters.State>
  for +target: U32
  Roster.FoundTarget(Roster.found(Roster.take(monsters, target)), target)

def Roster.take_target(monsters, target):
  match monsters:
    case Nil{}:
      Unit{}
    case Con{head, rest}:
      Roster.scan_target(rest, head, U32.is_eq(Roster.id(head), target), target, {==})

def Roster.FoundID(found: Maybe<&2, M.Monsters.State>, target: U32) -> Data:
  match found:
    case None{}:
      Unit
    case Some{monster}:
      {Roster.id(monster) == target : U32}

law Roster.found_id:
  for +found: Maybe<&2, M.Monsters.State>
  for +target: U32
  for +comparison: Roster.FoundTarget(found, target)
  Roster.FoundID(found, target)

def Roster.found_id(found, target, comparison):
  match found:
    case None{}:
      Unit{}
    case Some{monster}:
      N.Numeric.u32_eq_sound(Roster.id(monster), target, comparison)

law Roster.take_id:
  for +monsters: List<&2, M.Monsters.State>
  for +target: U32
  Roster.FoundID(Roster.found(Roster.take(monsters, target)), target)

def Roster.take_id(monsters, target):
  Roster.found_id(Roster.found(Roster.take(monsters, target)), target, Roster.take_target(monsters, target))

def Roster.has(found: Maybe<&2, M.Monsters.State>) -> Bool:
  match found:
    case None{}:
      False{}
    case Some{monster}:
      True{}

def Roster.has_id(monsters: List<&2, M.Monsters.State>, +target: U32) -> Bool:
  match monsters:
    case Nil{}:
      False{}
    case Con{head, rest}:
      Bool.or(U32.is_eq(Roster.id(head), target), Roster.has_id(rest, target))

law Roster.scan_success:
  for +tail: List<&2, M.Monsters.State>
  for +head: M.Monsters.State
  for +matches: Bool
  for +target: U32
  for +present: {Bool.or(matches, Roster.has_id(tail, target)) == True{} : Bool}
  {Roster.has(Roster.found(Roster.scan(tail, head, matches, target))) == True{} : Bool}

def Roster.scan_success(tail, head, matches, target, present):
  match tail:
    case Nil{}:
      match matches:
        case True{}:
          {==}
        case False{}:
          Empty.absurd({False{} == True{} : Bool}, G.Bq.Bool.false_ne_true(present))
    case Con{next, rest}:
      match matches:
        case True{}:
          {==}
        case False{}:
          %Equal.sym(Maybe<&2, M.Monsters.State>, Roster.found(Roster.prepend(head, Roster.scan(rest, next, U32.is_eq(Roster.id(next), target), target))), Roster.found(Roster.scan(rest, next, U32.is_eq(Roster.id(next), target), target)), Roster.prepend_found(head, Roster.scan(rest, next, U32.is_eq(Roster.id(next), target), target))) : {Roster.has(_) == True{} : Bool}
          Roster.scan_success(rest, next, U32.is_eq(Roster.id(next), target), target, present)

law Roster.take_success:
  for +monsters: List<&2, M.Monsters.State>
  for +target: U32
  for +present: {Roster.has_id(monsters, target) == True{} : Bool}
  {Roster.has(Roster.found(Roster.take(monsters, target))) == True{} : Bool}

def Roster.take_success(monsters, target, present):
  match monsters:
    case Nil{}:
      Empty.absurd({False{} == True{} : Bool}, G.Bq.Bool.false_ne_true(present))
    case Con{head, rest}:
      Roster.scan_success(rest, head, U32.is_eq(Roster.id(head), target), target, present)

law Roster.scan_hit:
  for +tail: List<&2, M.Monsters.State>
  for +head: M.Monsters.State
  for +target: U32
  {Roster.scan(tail, head, True{}, target) == Roster.Take{tail, Some{head}} : Roster.Take}

def Roster.scan_hit(tail, head, target):
  match tail:
    case Nil{}:
      {==}
    case Con{next, rest}:
      {==}

law Roster.take_head:
  for +head: M.Monsters.State
  for +tail: List<&2, M.Monsters.State>
  {Roster.take(Con{head, tail}, Roster.id(head)) == Roster.Take{tail, Some{head}} : Roster.Take}

def Roster.take_head(head, tail):
  %Equal.sym(Bool, U32.is_eq(Roster.id(head), Roster.id(head)), True{}, N.Numeric.u32_eq_refl(Roster.id(head))) : {Roster.scan(tail, head, _, Roster.id(head)) == Roster.Take{tail, Some{head}} : Roster.Take}
  Roster.scan_hit(tail, head, Roster.id(head))

law Roster.scan_missing:
  for +tail: List<&2, M.Monsters.State>
  for +head: M.Monsters.State
  for +matches: Bool
  for +target: U32
  for +absent: {Bool.or(matches, Roster.has_id(tail, target)) == False{} : Bool}
  {Roster.scan(tail, head, matches, target) == Roster.Take{Con{head, tail}, None{}} : Roster.Take}

def Roster.scan_missing(tail, head, matches, target, absent):
  match tail:
    case Nil{}:
      match matches:
        case True{}:
          Empty.absurd({Roster.Take{Nil{}, Some{head}} == Roster.Take{Con{head, Nil{}}, None{}} : Roster.Take}, N.Numeric.true_ne_false(absent))
        case False{}:
          {==}
    case Con{next, rest}:
      match matches:
        case True{}:
          Empty.absurd({Roster.Take{Con{next, rest}, Some{head}} == Roster.Take{Con{head, Con{next, rest}}, None{}} : Roster.Take}, N.Numeric.true_ne_false(absent))
        case False{}:
          %Equal.sym(Roster.Take, Roster.scan(rest, next, U32.is_eq(Roster.id(next), target), target), Roster.Take{Con{next, rest}, None{}}, Roster.scan_missing(rest, next, U32.is_eq(Roster.id(next), target), target, absent)) : {Roster.prepend(head, _) == Roster.Take{Con{head, Con{next, rest}}, None{}} : Roster.Take}
          {==}

law Roster.take_missing:
  for +monsters: List<&2, M.Monsters.State>
  for +target: U32
  for +absent: {Roster.has_id(monsters, target) == False{} : Bool}
  {Roster.take(monsters, target) == Roster.Take{monsters, None{}} : Roster.Take}

def Roster.take_missing(monsters, target, absent):
  match monsters:
    case Nil{}:
      {==}
    case Con{head, rest}:
      Roster.scan_missing(rest, head, U32.is_eq(Roster.id(head), target), target, absent)

law Roster.strike_missing:
  for +monsters: List<&2, M.Monsters.State>
  for +target: U32
  for +damage: U32
  for +absent: {Roster.has_id(monsters, target) == False{} : Bool}
  {Roster.strike(monsters, target, damage) == Roster.Strike{monsters, None{}, 0} : Roster.Strike}

def Roster.strike_missing(monsters, target, damage, absent):
  %Equal.sym(Roster.Take, Roster.take(monsters, target), Roster.Take{monsters, None{}}, Roster.take_missing(monsters, target, absent)) : {Roster.strike_taken(_, damage) == Roster.Strike{monsters, None{}, 0} : Roster.Strike}
  {==}

def Roster.zone_of(monster: M.Monsters.State) -> U32:
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      zone

def Roster.keep(keep: Bool, head: M.Monsters.State, tail: List<&2, M.Monsters.State>) -> List<&2, M.Monsters.State>:
  match keep:
    case True{}:
      Con{head, tail}
    case False{}:
      tail

def Roster.zone(+monsters: List<&2, M.Monsters.State>, +zone: U32) -> List<&2, M.Monsters.State>:
  match monsters:
    case Nil{}:
      Nil{}
    case Con{head, rest}:
      Roster.keep(U32.is_eq(Roster.zone_of(head), zone), head, Roster.zone(rest, zone))

law Roster.keep_ok:
  for +keep: Bool
  for +head: M.Monsters.State
  for +tail: List<&2, M.Monsters.State>
  for +head_ok: M.Monsters.OK(head)
  for +tail_ok: Roster.OK(tail)
  Roster.OK(Roster.keep(keep, head, tail))

def Roster.keep_ok(keep, head, tail, head_ok, tail_ok):
  match keep:
    case True{}:
      Tuple{head_ok, tail_ok}
    case False{}:
      tail_ok

law Roster.zone_ok:
  for +monsters: List<&2, M.Monsters.State>
  for +zone: U32
  for +valid: Roster.OK(monsters)
  Roster.OK(Roster.zone(monsters, zone))

def Roster.zone_ok(monsters, zone, valid):
  match monsters:
    case Nil{}:
      Unit{}
    case Con{head, rest}:
      match valid:
        case Tuple{head_ok, rest_ok}:
          Roster.keep_ok(U32.is_eq(Roster.zone_of(head), zone), head, Roster.zone(rest, zone), head_ok, Roster.zone_ok(rest, zone, rest_ok))
