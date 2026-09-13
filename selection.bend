# Connection selection, exact descriptor conservation, and WorldOK preservation.
import Base
import ./sessions.bend as S
import ./connections.bend as C
import ./players.bend as P
import ./playerids.bend as Ids
import ./allocation.bend as A
import ./numeric.bend as N
import ./game.bend as G
import ./simulation.bend as Sim

type Selection.Take is Data:
  Selection.Take{others: List<&2, S.Sessions.State>, found: Maybe<&2, S.Sessions.State>}

def Selection.prepend(player: S.Sessions.State, taken: Selection.Take) -> Selection.Take:
  match taken:
    case Selection.Take{others, found}:
      Selection.Take{Con{player, others}, found}

def Selection.scan(tail: List<&2, S.Sessions.State>, head: S.Sessions.State, matches: Bool, +target: U32) -> Selection.Take:
  match tail:
    case Nil{}:
      match matches:
        case True{}:
          Selection.Take{Nil{}, Some{head}}
        case False{}:
          Selection.Take{Con{head, Nil{}}, None{}}
    case Con{next, rest}:
      match matches:
        case True{}:
          Selection.Take{Con{next, rest}, Some{head}}
        case False{}:
          +shared = next
          Selection.prepend(head, Selection.scan(rest, shared, U32.is_eq(S.Sessions.cid(shared), target), target))

def Selection.take(players: List<&2, S.Sessions.State>, +target: U32) -> Selection.Take:
  match players:
    case Nil{}:
      Selection.Take{Nil{}, None{}}
    case Con{head, rest}:
      +shared = head
      Selection.scan(rest, shared, U32.is_eq(S.Sessions.cid(shared), target), target)


def Selection.others(taken: Selection.Take) -> List<&2, S.Sessions.State>:
  match taken:
    case Selection.Take{others, found}:
      others

def Selection.found(taken: Selection.Take) -> Maybe<&2, S.Sessions.State>:
  match taken:
    case Selection.Take{others, found}:
      found


law Selection.prepend_others:
  for +head: S.Sessions.State
  for +taken: Selection.Take
  {Selection.others(Selection.prepend(head, taken)) == Con{head, Selection.others(taken)} : List<&2, S.Sessions.State>}

def Selection.prepend_others(head, taken):
  match taken:
    case Selection.Take{others, found}:
      {==}

law Selection.prepend_found:
  for +head: S.Sessions.State
  for +taken: Selection.Take
  {Selection.found(Selection.prepend(head, taken)) == Selection.found(taken) : Maybe<&2, S.Sessions.State>}

def Selection.prepend_found(head, taken):
  match taken:
    case Selection.Take{others, found}:
      {==}


# Standard permutation evidence: identity, common head, adjacent swap,
# and transitivity. It relates complete connection descriptors, not just IDs.
type Selection.Perm<-left: List<&2, S.Sessions.State>, -right: List<&2, S.Sessions.State>> is Data:
  Selection.Same{equal: {left == right : List<&2, S.Sessions.State>}}
  Selection.Common{head: S.Sessions.State, left_tail: List<&2, S.Sessions.State>, right_tail: List<&2, S.Sessions.State>, left_shape: {left == Con{head, left_tail} : List<&2, S.Sessions.State>}, right_shape: {right == Con{head, right_tail} : List<&2, S.Sessions.State>}, tails: Selection.Perm<left_tail, right_tail>}
  Selection.Swap{first: S.Sessions.State, second: S.Sessions.State, rest: List<&2, S.Sessions.State>, left_shape: {left == Con{first, Con{second, rest}} : List<&2, S.Sessions.State>}, right_shape: {right == Con{second, Con{first, rest}} : List<&2, S.Sessions.State>}}
  Selection.Then{middle: List<&2, S.Sessions.State>, before: Selection.Perm<left, middle>, after: Selection.Perm<middle, right>}

def Selection.restore(taken: Selection.Take) -> List<&2, S.Sessions.State>:
  match taken:
    case Selection.Take{others, found}:
      match found:
        case None{}:
          others
        case Some{player}:
          Con{player, others}

law Selection.prepend_restores:
  for +head: S.Sessions.State
  for +taken: Selection.Take
  Selection.Perm<Selection.restore(Selection.prepend(head, taken)), Con{head, Selection.restore(taken)}>

def Selection.prepend_restores(head, taken):
  match taken:
    case Selection.Take{others, found}:
      match found:
        case None{}:
          Selection.Same{{==}}
        case Some{player}:
          Selection.Swap{player, head, others, {==}, {==}}

law Selection.scan_restores:
  for +tail: List<&2, S.Sessions.State>
  for +head: S.Sessions.State
  for +matches: Bool
  for +target: U32
  Selection.Perm<Selection.restore(Selection.scan(tail, head, matches, target)), Con{head, tail}>

def Selection.scan_restores(tail, head, matches, target):
  match tail:
    case Nil{}:
      match matches:
        case True{}:
          Selection.Same{{==}}
        case False{}:
          Selection.Same{{==}}
    case Con{next, rest}:
      match matches:
        case True{}:
          Selection.Same{{==}}
        case False{}:
          Selection.Then{Con{head, Selection.restore(Selection.scan(rest, next, U32.is_eq(S.Sessions.cid(next), target), target))}, Selection.prepend_restores(head, Selection.scan(rest, next, U32.is_eq(S.Sessions.cid(next), target), target)), Selection.Common{head, Selection.restore(Selection.scan(rest, next, U32.is_eq(S.Sessions.cid(next), target), target)), Con{next, rest}, {==}, {==}, Selection.scan_restores(rest, next, U32.is_eq(S.Sessions.cid(next), target), target)}}

law Selection.take_restores:
  for +players: List<&2, S.Sessions.State>
  for +target: U32
  Selection.Perm<Selection.restore(Selection.take(players, target)), players>

def Selection.take_restores(players, target):
  match players:
    case Nil{}:
      Selection.Same{{==}}
    case Con{head, rest}:
      Selection.scan_restores(rest, head, U32.is_eq(S.Sessions.cid(head), target), target)

def Selection.length(players: List<&2, S.Sessions.State>) -> Nat:
  match players:
    case Nil{}:
      0n
    case Con{head, rest}:
      Succ{Selection.length(rest)}

law Selection.perm_length:
  for -left: List<&2, S.Sessions.State>
  for -right: List<&2, S.Sessions.State>
  for +permutation: Selection.Perm<left, right>
  {Selection.length(left) == Selection.length(right) : Nat}

def Selection.perm_length(left, right, permutation):
  match permutation:
    case Selection.Same{equal}:
      Equal.cong(List<&2, S.Sessions.State>, Nat, (xs => Selection.length(xs)), left, right, equal)
    case Selection.Common{head, lt, rt, ls, rs, tails}:
      %Equal.sym(List<&2, S.Sessions.State>, left, Con{head, lt}, ls) : {Selection.length(_) == Selection.length(right) : Nat}
      %Equal.sym(List<&2, S.Sessions.State>, right, Con{head, rt}, rs) : {Selection.length(Con{head, lt}) == Selection.length(_) : Nat}
      %Selection.perm_length(lt, rt, tails) : {Succ{Selection.length(lt)} == Succ{_} : Nat}
      {==}
    case Selection.Swap{first, second, rest, ls, rs}:
      %Equal.sym(List<&2, S.Sessions.State>, left, Con{first, Con{second, rest}}, ls) : {Selection.length(_) == Selection.length(right) : Nat}
      %Equal.sym(List<&2, S.Sessions.State>, right, Con{second, Con{first, rest}}, rs) : {Selection.length(Con{first, Con{second, rest}}) == Selection.length(_) : Nat}
      {==}
    case Selection.Then{middle, before, after}:
      Equal.trans(Nat, Selection.length(left), Selection.length(middle), Selection.length(right), Selection.perm_length(left, middle, before), Selection.perm_length(middle, right, after))

law Selection.take_count:
  for +players: List<&2, S.Sessions.State>
  for +target: U32
  {Selection.length(Selection.restore(Selection.take(players, target))) == Selection.length(players) : Nat}

def Selection.take_count(players, target):
  Selection.perm_length(Selection.restore(Selection.take(players, target)), players, Selection.take_restores(players, target))


def Selection.FoundTarget(found: Maybe<&2, S.Sessions.State>, target: U32) -> Data:
  match found:
    case None{}:
      Unit
    case Some{player}:
      {U32.is_eq(S.Sessions.cid(player), target) == True{} : Bool}

law Selection.scan_target:
  for +tail: List<&2, S.Sessions.State>
  for +head: S.Sessions.State
  for +matches: Bool
  for +target: U32
  for +comparison: {matches == U32.is_eq(S.Sessions.cid(head), target) : Bool}
  Selection.FoundTarget(Selection.found(Selection.scan(tail, head, matches, target)), target)

def Selection.scan_target(tail, head, matches, target, comparison):
  match tail:
    case Nil{}:
      match matches:
        case True{}:
          Equal.sym(Bool, True{}, U32.is_eq(S.Sessions.cid(head), target), comparison)
        case False{}:
          Unit{}
    case Con{next, rest}:
      match matches:
        case True{}:
          Equal.sym(Bool, True{}, U32.is_eq(S.Sessions.cid(head), target), comparison)
        case False{}:
          %Equal.sym(Maybe<&2, S.Sessions.State>, Selection.found(Selection.prepend(head, Selection.scan(rest, next, U32.is_eq(S.Sessions.cid(next), target), target))), Selection.found(Selection.scan(rest, next, U32.is_eq(S.Sessions.cid(next), target), target)), Selection.prepend_found(head, Selection.scan(rest, next, U32.is_eq(S.Sessions.cid(next), target), target))) : Selection.FoundTarget(_, target)
          Selection.scan_target(rest, next, U32.is_eq(S.Sessions.cid(next), target), target, {==})

law Selection.take_target:
  for +players: List<&2, S.Sessions.State>
  for +target: U32
  Selection.FoundTarget(Selection.found(Selection.take(players, target)), target)

def Selection.take_target(players, target):
  match players:
    case Nil{}:
      Unit{}
    case Con{head, rest}:
      Selection.scan_target(rest, head, U32.is_eq(S.Sessions.cid(head), target), target, {==})

def Selection.FoundID(found: Maybe<&2, S.Sessions.State>, target: U32) -> Data:
  match found:
    case None{}:
      Unit
    case Some{player}:
      {S.Sessions.cid(player) == target : U32}

law Selection.found_id:
  for +found: Maybe<&2, S.Sessions.State>
  for +target: U32
  for +comparison: Selection.FoundTarget(found, target)
  Selection.FoundID(found, target)

def Selection.found_id(found, target, comparison):
  match found:
    case None{}:
      Unit{}
    case Some{player}:
      N.Numeric.u32_eq_sound(S.Sessions.cid(player), target, comparison)

law Selection.take_id:
  for +players: List<&2, S.Sessions.State>
  for +target: U32
  Selection.FoundID(Selection.found(Selection.take(players, target)), target)

def Selection.take_id(players, target):
  Selection.found_id(Selection.found(Selection.take(players, target)), target, Selection.take_target(players, target))

def Selection.has(found: Maybe<&2, S.Sessions.State>) -> Bool:
  match found:
    case None{}:
      False{}
    case Some{player}:
      True{}

def Selection.has_id(players: List<&2, S.Sessions.State>, +target: U32) -> Bool:
  match players:
    case Nil{}:
      False{}
    case Con{head, rest}:
      Bool.or(U32.is_eq(S.Sessions.cid(head), target), Selection.has_id(rest, target))

law Selection.scan_success:
  for +tail: List<&2, S.Sessions.State>
  for +head: S.Sessions.State
  for +matches: Bool
  for +target: U32
  for +present: {Bool.or(matches, Selection.has_id(tail, target)) == True{} : Bool}
  {Selection.has(Selection.found(Selection.scan(tail, head, matches, target))) == True{} : Bool}

def Selection.scan_success(tail, head, matches, target, present):
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
          %Equal.sym(Maybe<&2, S.Sessions.State>, Selection.found(Selection.prepend(head, Selection.scan(rest, next, U32.is_eq(S.Sessions.cid(next), target), target))), Selection.found(Selection.scan(rest, next, U32.is_eq(S.Sessions.cid(next), target), target)), Selection.prepend_found(head, Selection.scan(rest, next, U32.is_eq(S.Sessions.cid(next), target), target))) : {Selection.has(_) == True{} : Bool}
          Selection.scan_success(rest, next, U32.is_eq(S.Sessions.cid(next), target), target, present)

law Selection.take_success:
  for +players: List<&2, S.Sessions.State>
  for +target: U32
  for +present: {Selection.has_id(players, target) == True{} : Bool}
  {Selection.has(Selection.found(Selection.take(players, target))) == True{} : Bool}

def Selection.take_success(players, target, present):
  match players:
    case Nil{}:
      Empty.absurd({False{} == True{} : Bool}, G.Bq.Bool.false_ne_true(present))
    case Con{head, rest}:
      Selection.scan_success(rest, head, U32.is_eq(S.Sessions.cid(head), target), target, present)

law Selection.scan_hit:
  for +tail: List<&2, S.Sessions.State>
  for +head: S.Sessions.State
  for +target: U32
  {Selection.scan(tail, head, True{}, target) == Selection.Take{tail, Some{head}} : Selection.Take}

def Selection.scan_hit(tail, head, target):
  match tail:
    case Nil{}:
      {==}
    case Con{next, rest}:
      {==}

law Selection.take_head:
  for +head: S.Sessions.State
  for +tail: List<&2, S.Sessions.State>
  {Selection.take(Con{head, tail}, S.Sessions.cid(head)) == Selection.Take{tail, Some{head}} : Selection.Take}

def Selection.take_head(head, tail):
  %Equal.sym(Bool, U32.is_eq(S.Sessions.cid(head), S.Sessions.cid(head)), True{}, N.Numeric.u32_eq_refl(S.Sessions.cid(head))) : {Selection.scan(tail, head, _, S.Sessions.cid(head)) == Selection.Take{tail, Some{head}} : Selection.Take}
  Selection.scan_hit(tail, head, S.Sessions.cid(head))

law Selection.scan_missing:
  for +tail: List<&2, S.Sessions.State>
  for +head: S.Sessions.State
  for +matches: Bool
  for +target: U32
  for +absent: {Bool.or(matches, Selection.has_id(tail, target)) == False{} : Bool}
  {Selection.scan(tail, head, matches, target) == Selection.Take{Con{head, tail}, None{}} : Selection.Take}

def Selection.scan_missing(tail, head, matches, target, absent):
  match tail:
    case Nil{}:
      match matches:
        case True{}:
          Empty.absurd({Selection.Take{Nil{}, Some{head}} == Selection.Take{Con{head, Nil{}}, None{}} : Selection.Take}, N.Numeric.true_ne_false(absent))
        case False{}:
          {==}
    case Con{next, rest}:
      match matches:
        case True{}:
          Empty.absurd({Selection.Take{Con{next, rest}, Some{head}} == Selection.Take{Con{head, Con{next, rest}}, None{}} : Selection.Take}, N.Numeric.true_ne_false(absent))
        case False{}:
          %Equal.sym(Selection.Take, Selection.scan(rest, next, U32.is_eq(S.Sessions.cid(next), target), target), Selection.Take{Con{next, rest}, None{}}, Selection.scan_missing(rest, next, U32.is_eq(S.Sessions.cid(next), target), target, absent)) : {Selection.prepend(head, _) == Selection.Take{Con{head, Con{next, rest}}, None{}} : Selection.Take}
          {==}

law Selection.take_missing:
  for +players: List<&2, S.Sessions.State>
  for +target: U32
  for +absent: {Selection.has_id(players, target) == False{} : Bool}
  {Selection.take(players, target) == Selection.Take{players, None{}} : Selection.Take}

def Selection.take_missing(players, target, absent):
  match players:
    case Nil{}:
      {==}
    case Con{head, rest}:
      Selection.scan_missing(rest, head, U32.is_eq(S.Sessions.cid(head), target), target, absent)


# Permutations transport every actual membership witness.
law Selection.head_member:
  for +session: S.Sessions.State
  for +head: S.Sessions.State
  for +rest: List<&2,S.Sessions.State>
  for +equal: {head == session : S.Sessions.State}
  C.Connections.In<session,Con{head,rest}>

def Selection.head_member(session,head,rest,equal):
  %equal : C.Connections.In<_,Con{head,rest}>
  C.Connections.Here{rest,{==}}

law Selection.swap_later:
  for +session: S.Sessions.State
  for +first: S.Sessions.State
  for +second: S.Sessions.State
  for +rest: List<&2,S.Sessions.State>
  for +inside: C.Connections.In<session,Con{first,rest}>
  C.Connections.In<session,Con{first,Con{second,rest}}>

def Selection.swap_later(session,first,second,rest,inside):
  match inside:
    case C.Connections.Here{tail,shape}: Selection.head_member(session,first,Con{second,rest},C.Connections.cons_head(first,session,rest,tail,shape))
    case C.Connections.There{head,tail,shape,later}:
      C.Connections.There{first,Con{second,rest},{==},C.Connections.There{second,rest,{==},(%Equal.sym(List<&2,S.Sessions.State>,rest,tail,C.Connections.cons_tail(first,head,rest,tail,shape)) : C.Connections.In<session,_>; later)}}

law Selection.swap_member:
  for +session: S.Sessions.State
  for +first: S.Sessions.State
  for +second: S.Sessions.State
  for +rest: List<&2,S.Sessions.State>
  for +inside: C.Connections.In<session,Con{second,Con{first,rest}}>
  C.Connections.In<session,Con{first,Con{second,rest}}>

def Selection.swap_member(session,first,second,rest,inside):
  match inside:
    case C.Connections.Here{tail,shape}: C.Connections.There{first,Con{second,rest},{==},Selection.head_member(session,second,rest,C.Connections.cons_head(second,session,Con{first,rest},tail,shape))}
    case C.Connections.There{head,tail,shape,later}: Selection.swap_later(session,first,second,rest,(%Equal.sym(List<&2,S.Sessions.State>,Con{first,rest},tail,C.Connections.cons_tail(second,head,Con{first,rest},tail,shape)) : C.Connections.In<session,_>; later))

law Selection.perm_member:
  for +session: S.Sessions.State
  for -left: List<&2,S.Sessions.State>
  for -right: List<&2,S.Sessions.State>
  for +permutation: Selection.Perm<left,right>
  for +inside: C.Connections.In<session,right>
  C.Connections.In<session,left>

def Selection.perm_member(session,left,right,permutation,inside):
  match permutation:
    case Selection.Same{equal}:
      %Equal.sym(List<&2,S.Sessions.State>,left,right,equal) : C.Connections.In<session,_>
      inside
    case Selection.Common{head,lt,rt,ls,rs,tails}:
      match inside:
        case C.Connections.Here{rest,shape}:
          %Equal.sym(List<&2,S.Sessions.State>,left,Con{head,lt},ls) : C.Connections.In<session,_>
          Selection.head_member(session,head,lt,C.Connections.cons_head(head,session,rt,rest,Equal.trans(List<&2,S.Sessions.State>,Con{head,rt},right,Con{session,rest},Equal.sym(List<&2,S.Sessions.State>,right,Con{head,rt},rs),shape)))
        case C.Connections.There{before,rest,shape,later}:
          %Equal.sym(List<&2,S.Sessions.State>,left,Con{head,lt},ls) : C.Connections.In<session,_>
          C.Connections.There{head,lt,{==},Selection.perm_member(session,lt,rt,tails,(%Equal.sym(List<&2,S.Sessions.State>,rt,rest,C.Connections.cons_tail(head,before,rt,rest,Equal.trans(List<&2,S.Sessions.State>,Con{head,rt},right,Con{before,rest},Equal.sym(List<&2,S.Sessions.State>,right,Con{head,rt},rs),shape))) : C.Connections.In<session,_>; later))}
    case Selection.Swap{first,second,rest,ls,rs}:
      %Equal.sym(List<&2,S.Sessions.State>,left,Con{first,Con{second,rest}},ls) : C.Connections.In<session,_>
      Selection.swap_member(session,first,second,rest,(%rs : C.Connections.In<session,_>; inside))
    case Selection.Then{middle,before,after}: Selection.perm_member(session,left,middle,before,Selection.perm_member(session,middle,right,after,inside))

law Selection.perm_absent:
  for -left: List<&2,S.Sessions.State>
  for -right: List<&2,S.Sessions.State>
  for +permutation: Selection.Perm<left,right>
  for +id: U32
  for +valid: A.Allocation.Absent(id,C.Connections.cids(right))
  A.Allocation.Absent(id,C.Connections.cids(left))

def Selection.perm_absent(left,right,permutation,id,valid):
  match permutation:
    case Selection.Same{equal}:
      %Equal.sym(List<&2,S.Sessions.State>,left,right,equal) : A.Allocation.Absent(id,C.Connections.cids(_))
      valid
    case Selection.Common{head,lt,rt,ls,rs,tails}:
      +given = {(%rs : A.Allocation.Absent(id,C.Connections.cids(_)); valid) : A.Allocation.Absent(id,C.Connections.cids(Con{head,rt}))}
      %Equal.sym(List<&2,S.Sessions.State>,left,Con{head,lt},ls) : A.Allocation.Absent(id,C.Connections.cids(_))
      Tuple{Ids.PlayerIds.absent_head(id,S.Sessions.cid(head),C.Connections.cids(rt),given),Selection.perm_absent(lt,rt,tails,id,Ids.PlayerIds.absent_tail(id,S.Sessions.cid(head),C.Connections.cids(rt),given))}
    case Selection.Swap{first,second,rest,ls,rs}:
      %Equal.sym(List<&2,S.Sessions.State>,left,Con{first,Con{second,rest}},ls) : A.Allocation.Absent(id,C.Connections.cids(_))
      Ids.PlayerIds.absent_swap(id,S.Sessions.cid(second),S.Sessions.cid(first),C.Connections.cids(rest),(%rs : A.Allocation.Absent(id,C.Connections.cids(_)); valid))
    case Selection.Then{middle,before,after}:
      Selection.perm_absent(left,middle,before,id,Selection.perm_absent(middle,right,after,id,valid))

law Selection.perm_unique:
  for -left: List<&2,S.Sessions.State>
  for -right: List<&2,S.Sessions.State>
  for +permutation: Selection.Perm<left,right>
  for +valid: A.Allocation.Unique(C.Connections.cids(right))
  A.Allocation.Unique(C.Connections.cids(left))

def Selection.perm_unique(left,right,permutation,valid):
  match permutation:
    case Selection.Same{equal}:
      %Equal.sym(List<&2,S.Sessions.State>,left,right,equal) : A.Allocation.Unique(C.Connections.cids(_))
      valid
    case Selection.Common{head,lt,rt,ls,rs,tails}:
      +given = {(%rs : A.Allocation.Unique(C.Connections.cids(_)); valid) : A.Allocation.Unique(C.Connections.cids(Con{head,rt}))}
      %Equal.sym(List<&2,S.Sessions.State>,left,Con{head,lt},ls) : A.Allocation.Unique(C.Connections.cids(_))
      Tuple{Selection.perm_absent(lt,rt,tails,S.Sessions.cid(head),Ids.PlayerIds.unique_head(S.Sessions.cid(head),C.Connections.cids(rt),given)),Selection.perm_unique(lt,rt,tails,Ids.PlayerIds.unique_tail(S.Sessions.cid(head),C.Connections.cids(rt),given))}
    case Selection.Swap{first,second,rest,ls,rs}:
      %Equal.sym(List<&2,S.Sessions.State>,left,Con{first,Con{second,rest}},ls) : A.Allocation.Unique(C.Connections.cids(_))
      Ids.PlayerIds.unique_swap(S.Sessions.cid(second),S.Sessions.cid(first),C.Connections.cids(rest),(%rs : A.Allocation.Unique(C.Connections.cids(_)); valid))
    case Selection.Then{middle,before,after}:
      Selection.perm_unique(left,middle,before,Selection.perm_unique(middle,right,after,valid))


def Selection.all_head(head: S.Sessions.State,rest: List<&2,S.Sessions.State>,valid: C.Connections.All(Con{head,rest})) -> S.Sessions.OK<head>:
  match valid:
    case Tuple{first,later}: first

def Selection.all_tail(head: S.Sessions.State,rest: List<&2,S.Sessions.State>,valid: C.Connections.All(Con{head,rest})) -> C.Connections.All(rest):
  match valid:
    case Tuple{first,later}: later

law Selection.all_swap:
  for +first: S.Sessions.State
  for +second: S.Sessions.State
  for +rest: List<&2,S.Sessions.State>
  for +valid: C.Connections.All(Con{first,Con{second,rest}})
  C.Connections.All(Con{second,Con{first,rest}})

def Selection.all_swap(first,second,rest,valid):
  match valid:
    case Tuple{a,later}:
      match later:
        case Tuple{b,tail}: Tuple{b,Tuple{a,tail}}

law Selection.perm_all:
  for -left: List<&2,S.Sessions.State>
  for -right: List<&2,S.Sessions.State>
  for +permutation: Selection.Perm<left,right>
  for +valid: C.Connections.All(right)
  C.Connections.All(left)

def Selection.perm_all(left,right,permutation,valid):
  match permutation:
    case Selection.Same{equal}:
      %Equal.sym(List<&2,S.Sessions.State>,left,right,equal) : C.Connections.All(_)
      valid
    case Selection.Common{head,lt,rt,ls,rs,tails}:
      +given = {(%rs : C.Connections.All(_); valid) : C.Connections.All(Con{head,rt})}
      %Equal.sym(List<&2,S.Sessions.State>,left,Con{head,lt},ls) : C.Connections.All(_)
      Tuple{Selection.all_head(head,rt,given),Selection.perm_all(lt,rt,tails,Selection.all_tail(head,rt,given))}
    case Selection.Swap{first,second,rest,ls,rs}:
      %Equal.sym(List<&2,S.Sessions.State>,left,Con{first,Con{second,rest}},ls) : C.Connections.All(_)
      Selection.all_swap(second,first,rest,(%rs : C.Connections.All(_); valid))
    case Selection.Then{middle,before,after}: Selection.perm_all(left,middle,before,Selection.perm_all(middle,right,after,valid))

def Selection.links_head(players: List<&2,P.Players.State>,head: S.Sessions.State,rest: List<&2,S.Sessions.State>,valid: C.Connections.Links(players,Con{head,rest})) -> C.Connections.Link<players,head>:
  match valid:
    case Tuple{first,later}: first

def Selection.links_tail(players: List<&2,P.Players.State>,head: S.Sessions.State,rest: List<&2,S.Sessions.State>,valid: C.Connections.Links(players,Con{head,rest})) -> C.Connections.Links(players,rest):
  match valid:
    case Tuple{first,later}: later

law Selection.links_swap:
  for +players: List<&2,P.Players.State>
  for +first: S.Sessions.State
  for +second: S.Sessions.State
  for +rest: List<&2,S.Sessions.State>
  for +valid: C.Connections.Links(players,Con{first,Con{second,rest}})
  C.Connections.Links(players,Con{second,Con{first,rest}})

def Selection.links_swap(players,first,second,rest,valid):
  match valid:
    case Tuple{a,later}:
      match later:
        case Tuple{b,tail}: Tuple{b,Tuple{a,tail}}

law Selection.perm_links:
  for +players: List<&2,P.Players.State>
  for -left: List<&2,S.Sessions.State>
  for -right: List<&2,S.Sessions.State>
  for +permutation: Selection.Perm<left,right>
  for +valid: C.Connections.Links(players,right)
  C.Connections.Links(players,left)

def Selection.perm_links(players,left,right,permutation,valid):
  match permutation:
    case Selection.Same{equal}:
      %Equal.sym(List<&2,S.Sessions.State>,left,right,equal) : C.Connections.Links(players,_)
      valid
    case Selection.Common{head,lt,rt,ls,rs,tails}:
      +given = {(%rs : C.Connections.Links(players,_); valid) : C.Connections.Links(players,Con{head,rt})}
      %Equal.sym(List<&2,S.Sessions.State>,left,Con{head,lt},ls) : C.Connections.Links(players,_)
      Tuple{Selection.links_head(players,head,rt,given),Selection.perm_links(players,lt,rt,tails,Selection.links_tail(players,head,rt,given))}
    case Selection.Swap{first,second,rest,ls,rs}:
      %Equal.sym(List<&2,S.Sessions.State>,left,Con{first,Con{second,rest}},ls) : C.Connections.Links(players,_)
      Selection.links_swap(players,second,first,rest,(%rs : C.Connections.Links(players,_); valid))
    case Selection.Then{middle,before,after}: Selection.perm_links(players,left,middle,before,Selection.perm_links(players,middle,right,after,valid))

law Selection.perm_present:
  for +player: P.Players.State
  for +left: List<&2,S.Sessions.State>
  for +right: List<&2,S.Sessions.State>
  for +permutation: Selection.Perm<left,right>
  for +present: C.Connections.Present<player,right>
  C.Connections.Present<player,left>

def Selection.perm_present(player,left,right,permutation,present):
  match present:
    case C.Connections.Present{session,inside,positive,cid,pid,name}: C.Connections.Present{session,Selection.perm_member(session,left,right,permutation,inside),positive,cid,pid,name}

law Selection.perm_covers:
  for +players: List<&2,P.Players.State>
  for +left: List<&2,S.Sessions.State>
  for +right: List<&2,S.Sessions.State>
  for +permutation: Selection.Perm<left,right>
  for +covers: C.Connections.Covers(right,players)
  C.Connections.Covers(left,players)

def Selection.perm_covers(players,left,right,permutation,covers):
  match players:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match covers:
        case Tuple{first,later}: Tuple{Selection.perm_present(head,left,right,permutation,first),Selection.perm_covers(rest,left,right,permutation,later)}

law Selection.perm_ok:
  for +players: List<&2,P.Players.State>
  for +left: List<&2,S.Sessions.State>
  for +right: List<&2,S.Sessions.State>
  for +permutation: Selection.Perm<left,right>
  for +valid: C.Connections.OK<players,right>
  C.Connections.OK<players,left>

def Selection.perm_ok(players,left,right,permutation,valid):
  match valid:
    case C.Connections.OK{sessions,unique,links,covers}: C.Connections.OK{Selection.perm_all(left,right,permutation,sessions),Selection.perm_unique(left,right,permutation,unique),Selection.perm_links(players,left,right,permutation,links),Selection.perm_covers(players,left,right,permutation,covers)}

law Selection.take_ok:
  for +players: List<&2,P.Players.State>
  for +states: List<&2,S.Sessions.State>
  for +cid: U32
  for +valid: C.Connections.OK<players,states>
  C.Connections.OK<players,Selection.restore(Selection.take(states,cid))>

def Selection.take_ok(players,states,cid,valid): Selection.perm_ok(players,Selection.restore(Selection.take(states,cid)),states,Selection.take_restores(states,cid),valid)

law Selection.take_world:
  for +seed: U32
  for +world: Sim.Simulation.State
  for +states: List<&2,S.Sessions.State>
  for +cid: U32
  for +valid: C.Connections.WorldOK<seed,world,states>
  C.Connections.WorldOK<seed,world,Selection.restore(Selection.take(states,cid))>

def Selection.take_world(seed,world,states,cid,valid):
  match valid:
    case C.Connections.WorldOK{world_ok,connections}: C.Connections.WorldOK{world_ok,Selection.take_ok(Sim.Simulation.players(world),states,cid,connections)}

# HELLO after selection by an arbitrary CID, including the absent-CID no-op.
def Selection.hello_taken(taken: Selection.Take,name: List<&2,Char>) -> List<&2,S.Sessions.State>:
  match taken:
    case Selection.Take{others,found}:
      match found:
        case None{}: others
        case Some{head}:
          +others = others
          Con{S.Sessions.state(S.Sessions.hello(head,name,others)),others}

def Selection.hello(states: List<&2,S.Sessions.State>,cid: U32,name: List<&2,Char>) -> List<&2,S.Sessions.State>: Selection.hello_taken(Selection.take(states,cid),name)

law Selection.hello_taken_ok:
  for +taken: Selection.Take
  for +players: List<&2,P.Players.State>
  for +name: List<&2,Char>
  for +valid: C.Connections.OK<players,Selection.restore(taken)>
  C.Connections.OK<players,Selection.hello_taken(taken,name)>

def Selection.hello_taken_ok(taken,players,name,valid):
  match taken:
    case Selection.Take{others,found}:
      match found:
        case None{}: valid
        case Some{head}: C.Connections.hello_ok(players,head,others,name,valid)

law Selection.hello_ok:
  for +players: List<&2,P.Players.State>
  for +states: List<&2,S.Sessions.State>
  for +cid: U32
  for +name: List<&2,Char>
  for +valid: C.Connections.OK<players,states>
  C.Connections.OK<players,Selection.hello(states,cid,name)>

def Selection.hello_ok(players,states,cid,name,valid): Selection.hello_taken_ok(Selection.take(states,cid),players,name,Selection.take_ok(players,states,cid,valid))

law Selection.hello_world:
  for +seed: U32
  for +world: Sim.Simulation.State
  for +states: List<&2,S.Sessions.State>
  for +cid: U32
  for +name: List<&2,Char>
  for +valid: C.Connections.WorldOK<seed,world,states>
  C.Connections.WorldOK<seed,world,Selection.hello(states,cid,name)>

def Selection.hello_world(seed,world,states,cid,name,valid):
  match valid:
    case C.Connections.WorldOK{world_ok,connections}: C.Connections.WorldOK{world_ok,Selection.hello_ok(Sim.Simulation.players(world),states,cid,name,connections)}

law Selection.perm_sym:
  for -left: List<&2,S.Sessions.State>
  for -right: List<&2,S.Sessions.State>
  for +permutation: Selection.Perm<left,right>
  Selection.Perm<right,left>

def Selection.perm_sym(left,right,permutation):
  match permutation:
    case Selection.Same{equal}: Selection.Same{Equal.sym(List<&2,S.Sessions.State>,left,right,equal)}
    case Selection.Common{head,lt,rt,ls,rs,tails}: Selection.Common{head,rt,lt,rs,ls,Selection.perm_sym(lt,rt,tails)}
    case Selection.Swap{first,second,rest,ls,rs}: Selection.Swap{second,first,rest,rs,ls}
    case Selection.Then{middle,before,after}: Selection.Then{middle,Selection.perm_sym(middle,right,after),Selection.perm_sym(left,middle,before)}

def Selection.FoundInside(+states: List<&2,S.Sessions.State>,found: Maybe<&2,S.Sessions.State>) -> Data:
  match found:
    case None{}: Unit
    case Some{session}: C.Connections.In<session,states>

law Selection.found_restored:
  for +taken: Selection.Take
  Selection.FoundInside(Selection.restore(taken),Selection.found(taken))

def Selection.found_restored(taken):
  match taken:
    case Selection.Take{others,found}:
      match found:
        case None{}: Unit{}
        case Some{session}: C.Connections.Here{others,{==}}

law Selection.found_permutation:
  for +found: Maybe<&2,S.Sessions.State>
  for +left: List<&2,S.Sessions.State>
  for +right: List<&2,S.Sessions.State>
  for +permutation: Selection.Perm<left,right>
  for +inside: Selection.FoundInside(right,found)
  Selection.FoundInside(left,found)

def Selection.found_permutation(found,left,right,permutation,inside):
  match found:
    case None{}: Unit{}
    case Some{session}: Selection.perm_member(session,left,right,permutation,inside)

law Selection.take_inside:
  for +states: List<&2,S.Sessions.State>
  for +cid: U32
  Selection.FoundInside(states,Selection.found(Selection.take(states,cid)))

def Selection.take_inside(states,cid): Selection.found_permutation(Selection.found(Selection.take(states,cid)),states,Selection.restore(Selection.take(states,cid)),Selection.perm_sym(Selection.restore(Selection.take(states,cid)),states,Selection.take_restores(states,cid)),Selection.found_restored(Selection.take(states,cid)))

def Selection.Separated(+others: List<&2,S.Sessions.State>,found: Maybe<&2,S.Sessions.State>) -> Data:
  match found:
    case None{}: Unit
    case Some{session}: A.Allocation.Absent(S.Sessions.cid(session),C.Connections.cids(others))

law Selection.separated:
  for +taken: Selection.Take
  for +valid: A.Allocation.Unique(C.Connections.cids(Selection.restore(taken)))
  Selection.Separated(Selection.others(taken),Selection.found(taken))

def Selection.separated(taken,valid):
  match taken:
    case Selection.Take{others,found}:
      match found:
        case None{}: Unit{}
        case Some{session}:
          match valid:
            case Tuple{absent,later}: absent

law Selection.take_separated:
  for +states: List<&2,S.Sessions.State>
  for +cid: U32
  for +valid: A.Allocation.Unique(C.Connections.cids(states))
  Selection.Separated(Selection.others(Selection.take(states,cid)),Selection.found(Selection.take(states,cid)))

def Selection.take_separated(states,cid,valid): Selection.separated(Selection.take(states,cid),Selection.perm_unique(Selection.restore(Selection.take(states,cid)),states,Selection.take_restores(states,cid),valid))

# Composition of the proved connection-only operations. World-changing
# CREATE/disconnect/commands are deliberately separate outstanding obligations.
type Selection.Input is Data:
  Selection.Join{hint: U32}
  Selection.Hello{cid: U32,name: List<&2,Char>}

def Selection.step(input: Selection.Input,+states: List<&2,S.Sessions.State>) -> List<&2,S.Sessions.State>:
  match input:
    case Selection.Join{hint}: C.Connections.admit(A.Allocation.find(C.Connections.cids(states),hint),states)
    case Selection.Hello{cid,name}: Selection.hello(states,cid,name)

def Selection.trace(inputs: List<&2,Selection.Input>,states: List<&2,S.Sessions.State>) -> List<&2,S.Sessions.State>:
  match inputs:
    case Nil{}: states
    case Con{head,rest}: Selection.trace(rest,Selection.step(head,states))

law Selection.step_world:
  for +input: Selection.Input
  for +seed: U32
  for +world: Sim.Simulation.State
  for +states: List<&2,S.Sessions.State>
  for +valid: C.Connections.WorldOK<seed,world,states>
  C.Connections.WorldOK<seed,world,Selection.step(input,states)>

def Selection.step_world(input,seed,world,states,valid):
  match input:
    case Selection.Join{hint}: C.Connections.join_world(seed,world,states,hint,valid)
    case Selection.Hello{cid,name}: Selection.hello_world(seed,world,states,cid,name,valid)

law Selection.trace_world:
  for +inputs: List<&2,Selection.Input>
  for +seed: U32
  for +world: Sim.Simulation.State
  for +states: List<&2,S.Sessions.State>
  for +valid: C.Connections.WorldOK<seed,world,states>
  C.Connections.WorldOK<seed,world,Selection.trace(inputs,states)>

def Selection.trace_world(inputs,seed,world,states,valid):
  match inputs:
    case Nil{}: valid
    case Con{head,rest}: Selection.trace_world(rest,seed,world,Selection.step(head,states),Selection.step_world(head,seed,world,states,valid))
