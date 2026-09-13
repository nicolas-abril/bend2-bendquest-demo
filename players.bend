# Complete player records and checked player-list state transitions.
import Base
import ./game.bend as G
import ./vitals.bend as V
import ./rewards.bend as R
import ./numeric.bend as N

type Players.Pos is Data:
  Players.Pos{zone: U32, x: U32, y: U32, dir: U32, moving: U32}

type Players.Style is Data:
  Players.Style{skin: U32, hairs: U32, hairc: U32, shirt: U32, hat: U32, cape: U32}

type Players.Quest is Data:
  Players.Quest{main: U32, cull: U32, side0: U32, side1: U32, side2: U32, claimed: U32}

type Players.Meta is Data:
  Players.Meta{score: U32, kills: U32, found: U32, name: List<&2, Char>}

type Players.State is Data:
  Players.State{pid: U32, cid: U32, hero: G.Bq.Hero, pos: Players.Pos, vitals: V.Vitals.State, style: Players.Style, quest: Players.Quest, meta: Players.Meta}

def Players.share_name(name: List<&1, Char>) -> List<&2, Char>:
  match name:
    case Nil{}:
      Nil{}
    case Con{head, rest}:
      Con{head, Players.share_name(rest)}

def Players.text_name(name: List<&2, Char>) -> List<&1, Char>:
  match name:
    case Nil{}:
      Nil{}
    case Con{head, rest}:
      Con{head, Players.text_name(rest)}

law Players.name_round_trip:
  for +name: List<&2, Char>
  {Players.share_name(Players.text_name(name)) == name : List<&2, Char>}

def Players.name_round_trip(name):
  match name:
    case Nil{}:
      {==}
    case Con{head, rest}:
      %Players.name_round_trip(rest) : {Con{head, Players.share_name(Players.text_name(rest))} == Con{head, _} : List<&2, Char>}
      {==}

def Players.hero(player: Players.State) -> G.Bq.Hero:
  match player:
    case Players.State{pid, cid, hero, pos, vitals, style, quest, meta}:
      hero

def Players.vitals(player: Players.State) -> V.Vitals.State:
  match player:
    case Players.State{pid, cid, hero, pos, vitals, style, quest, meta}:
      vitals

def Players.id(player: Players.State) -> U32:
  match player:
    case Players.State{pid, cid, hero, pos, vitals, style, quest, meta}:
      pid

def Players.maximum(player: Players.State) -> U32:
  R.Rewards.maximum(Players.hero(player), 4294967295)

type Players.OK<-player: Players.State> is Data:
  Players.OK{vitals: V.Vitals.OK<Players.vitals(player), Players.maximum(player)>, equipped: G.Bq.WellEquipped(Players.hero(player))}

def Players.All(players: List<&2, Players.State>) -> Data:
  match players:
    case Nil{}:
      Unit
    case Con{head, rest}:
      Sigma<&2, &2, Players.OK<head>, (valid => Players.All(rest))>

def Players.concat(left: List<&2, Players.State>, right: List<&2, Players.State>) -> List<&2, Players.State>:
  match left:
    case Nil{}:
      right
    case Con{head, rest}:
      Con{head, Players.concat(rest, right)}

law Players.concat_all:
  for +left: List<&2, Players.State>
  for +right: List<&2, Players.State>
  for +left_ok: Players.All(left)
  for +right_ok: Players.All(right)
  Players.All(Players.concat(left, right))

def Players.concat_all(left, right, left_ok, right_ok):
  match left:
    case Nil{}:
      right_ok
    case Con{head, rest}:
      match left_ok:
        case Tuple{head_ok, rest_ok}:
          Tuple{head_ok, Players.concat_all(rest, right, rest_ok, right_ok)}

def Players.Valid(player: Players.State) -> Data:
  Players.OK<player>

type Players.Take is Data:
  Players.Take{others: List<&2, Players.State>, found: Maybe<&2, Players.State>}

def Players.prepend(player: Players.State, taken: Players.Take) -> Players.Take:
  match taken:
    case Players.Take{others, found}:
      Players.Take{Con{player, others}, found}

def Players.scan(tail: List<&2, Players.State>, head: Players.State, matches: Bool, +target: U32) -> Players.Take:
  match tail:
    case Nil{}:
      match matches:
        case True{}:
          Players.Take{Nil{}, Some{head}}
        case False{}:
          Players.Take{Con{head, Nil{}}, None{}}
    case Con{next, rest}:
      match matches:
        case True{}:
          Players.Take{Con{next, rest}, Some{head}}
        case False{}:
          +shared = next
          Players.prepend(head, Players.scan(rest, shared, U32.is_eq(Players.id(shared), target), target))

def Players.take(players: List<&2, Players.State>, +target: U32) -> Players.Take:
  match players:
    case Nil{}:
      Players.Take{Nil{}, None{}}
    case Con{head, rest}:
      +shared = head
      Players.scan(rest, shared, U32.is_eq(Players.id(shared), target), target)

def Players.FoundOK(found: Maybe<&2, Players.State>) -> Data:
  match found:
    case None{}:
      Unit
    case Some{player}:
      Players.Valid(player)

def Players.others(taken: Players.Take) -> List<&2, Players.State>:
  match taken:
    case Players.Take{others, found}:
      others

def Players.found(taken: Players.Take) -> Maybe<&2, Players.State>:
  match taken:
    case Players.Take{others, found}:
      found

type Players.TakeOK<-taken: Players.Take> is Data:
  Players.ValidTake{others: Players.All(Players.others(taken)), found: Players.FoundOK(Players.found(taken))}

law Players.prepend_others:
  for +head: Players.State
  for +taken: Players.Take
  {Players.others(Players.prepend(head, taken)) == Con{head, Players.others(taken)} : List<&2, Players.State>}

def Players.prepend_others(head, taken):
  match taken:
    case Players.Take{others, found}:
      {==}

law Players.prepend_found:
  for +head: Players.State
  for +taken: Players.Take
  {Players.found(Players.prepend(head, taken)) == Players.found(taken) : Maybe<&2, Players.State>}

def Players.prepend_found(head, taken):
  match taken:
    case Players.Take{others, found}:
      {==}

law Players.prepend_ok:
  for +head: Players.State
  for +taken: Players.Take
  for +head_ok: Players.Valid(head)
  for +tail_ok: Players.TakeOK<taken>
  Players.TakeOK<Players.prepend(head, taken)>

def Players.prepend_ok(head, taken, head_ok, tail_ok):
  match tail_ok:
    case Players.ValidTake{others_ok, found_ok}:
      Players.ValidTake{
        (%Equal.sym(List<&2, Players.State>, Players.others(Players.prepend(head, taken)), Con{head, Players.others(taken)}, Players.prepend_others(head, taken)) : Players.All(_); Tuple{head_ok, others_ok}),
        (%Equal.sym(Maybe<&2, Players.State>, Players.found(Players.prepend(head, taken)), Players.found(taken), Players.prepend_found(head, taken)) : Players.FoundOK(_); found_ok)}

law Players.scan_ok:
  for +tail: List<&2, Players.State>
  for +head: Players.State
  for +matches: Bool
  for +target: U32
  for +tail_ok: Players.All(tail)
  for +head_ok: Players.Valid(head)
  Players.TakeOK<Players.scan(tail, head, matches, target)>

def Players.scan_ok(tail, head, matches, target, tail_ok, head_ok):
  match tail:
    case Nil{}:
      match matches:
        case True{}:
          Players.ValidTake{Unit{}, head_ok}
        case False{}:
          Players.ValidTake{Tuple{head_ok, Unit{}}, Unit{}}
    case Con{next, rest}:
      match matches:
        case True{}:
          Players.ValidTake{tail_ok, head_ok}
        case False{}:
          match tail_ok:
            case Tuple{next_ok, rest_ok}:
              +shared = next
              Players.prepend_ok(head, Players.scan(rest, shared, U32.is_eq(Players.id(shared), target), target), head_ok, Players.scan_ok(rest, shared, U32.is_eq(Players.id(shared), target), target, rest_ok, next_ok))

law Players.take_ok:
  for +players: List<&2, Players.State>
  for +target: U32
  for +valid: Players.All(players)
  Players.TakeOK<Players.take(players, target)>

def Players.take_ok(players, target, valid):
  match players:
    case Nil{}:
      Players.ValidTake{Unit{}, Unit{}}
    case Con{head, rest}:
      match valid:
        case Tuple{head_ok, rest_ok}:
          +shared = head
          Players.scan_ok(rest, shared, U32.is_eq(Players.id(shared), target), target, rest_ok, head_ok)


# Standard permutation evidence: identity, common head, adjacent swap,
# and transitivity. It relates complete player records, not just IDs.
type Players.Perm<-left: List<&2, Players.State>, -right: List<&2, Players.State>> is Data:
  Players.Same{equal: {left == right : List<&2, Players.State>}}
  Players.Common{head: Players.State, left_tail: List<&2, Players.State>, right_tail: List<&2, Players.State>, left_shape: {left == Con{head, left_tail} : List<&2, Players.State>}, right_shape: {right == Con{head, right_tail} : List<&2, Players.State>}, tails: Players.Perm<left_tail, right_tail>}
  Players.Swap{first: Players.State, second: Players.State, rest: List<&2, Players.State>, left_shape: {left == Con{first, Con{second, rest}} : List<&2, Players.State>}, right_shape: {right == Con{second, Con{first, rest}} : List<&2, Players.State>}}
  Players.Then{middle: List<&2, Players.State>, before: Players.Perm<left, middle>, after: Players.Perm<middle, right>}

def Players.restore(taken: Players.Take) -> List<&2, Players.State>:
  match taken:
    case Players.Take{others, found}:
      match found:
        case None{}:
          others
        case Some{player}:
          Con{player, others}

law Players.prepend_restores:
  for +head: Players.State
  for +taken: Players.Take
  Players.Perm<Players.restore(Players.prepend(head, taken)), Con{head, Players.restore(taken)}>

def Players.prepend_restores(head, taken):
  match taken:
    case Players.Take{others, found}:
      match found:
        case None{}:
          Players.Same{{==}}
        case Some{player}:
          Players.Swap{player, head, others, {==}, {==}}

law Players.scan_restores:
  for +tail: List<&2, Players.State>
  for +head: Players.State
  for +matches: Bool
  for +target: U32
  Players.Perm<Players.restore(Players.scan(tail, head, matches, target)), Con{head, tail}>

def Players.scan_restores(tail, head, matches, target):
  match tail:
    case Nil{}:
      match matches:
        case True{}:
          Players.Same{{==}}
        case False{}:
          Players.Same{{==}}
    case Con{next, rest}:
      match matches:
        case True{}:
          Players.Same{{==}}
        case False{}:
          Players.Then{Con{head, Players.restore(Players.scan(rest, next, U32.is_eq(Players.id(next), target), target))}, Players.prepend_restores(head, Players.scan(rest, next, U32.is_eq(Players.id(next), target), target)), Players.Common{head, Players.restore(Players.scan(rest, next, U32.is_eq(Players.id(next), target), target)), Con{next, rest}, {==}, {==}, Players.scan_restores(rest, next, U32.is_eq(Players.id(next), target), target)}}

law Players.take_restores:
  for +players: List<&2, Players.State>
  for +target: U32
  Players.Perm<Players.restore(Players.take(players, target)), players>

def Players.take_restores(players, target):
  match players:
    case Nil{}:
      Players.Same{{==}}
    case Con{head, rest}:
      Players.scan_restores(rest, head, U32.is_eq(Players.id(head), target), target)

def Players.length(players: List<&2, Players.State>) -> Nat:
  match players:
    case Nil{}:
      0n
    case Con{head, rest}:
      Succ{Players.length(rest)}

law Players.perm_length:
  for -left: List<&2, Players.State>
  for -right: List<&2, Players.State>
  for +permutation: Players.Perm<left, right>
  {Players.length(left) == Players.length(right) : Nat}

def Players.perm_length(left, right, permutation):
  match permutation:
    case Players.Same{equal}:
      Equal.cong(List<&2, Players.State>, Nat, (xs => Players.length(xs)), left, right, equal)
    case Players.Common{head, lt, rt, ls, rs, tails}:
      %Equal.sym(List<&2, Players.State>, left, Con{head, lt}, ls) : {Players.length(_) == Players.length(right) : Nat}
      %Equal.sym(List<&2, Players.State>, right, Con{head, rt}, rs) : {Players.length(Con{head, lt}) == Players.length(_) : Nat}
      %Players.perm_length(lt, rt, tails) : {Succ{Players.length(lt)} == Succ{_} : Nat}
      {==}
    case Players.Swap{first, second, rest, ls, rs}:
      %Equal.sym(List<&2, Players.State>, left, Con{first, Con{second, rest}}, ls) : {Players.length(_) == Players.length(right) : Nat}
      %Equal.sym(List<&2, Players.State>, right, Con{second, Con{first, rest}}, rs) : {Players.length(Con{first, Con{second, rest}}) == Players.length(_) : Nat}
      {==}
    case Players.Then{middle, before, after}:
      Equal.trans(Nat, Players.length(left), Players.length(middle), Players.length(right), Players.perm_length(left, middle, before), Players.perm_length(middle, right, after))

law Players.take_count:
  for +players: List<&2, Players.State>
  for +target: U32
  {Players.length(Players.restore(Players.take(players, target))) == Players.length(players) : Nat}

def Players.take_count(players, target):
  Players.perm_length(Players.restore(Players.take(players, target)), players, Players.take_restores(players, target))


def Players.FoundTarget(found: Maybe<&2, Players.State>, target: U32) -> Data:
  match found:
    case None{}:
      Unit
    case Some{player}:
      {U32.is_eq(Players.id(player), target) == True{} : Bool}

law Players.scan_target:
  for +tail: List<&2, Players.State>
  for +head: Players.State
  for +matches: Bool
  for +target: U32
  for +comparison: {matches == U32.is_eq(Players.id(head), target) : Bool}
  Players.FoundTarget(Players.found(Players.scan(tail, head, matches, target)), target)

def Players.scan_target(tail, head, matches, target, comparison):
  match tail:
    case Nil{}:
      match matches:
        case True{}:
          Equal.sym(Bool, True{}, U32.is_eq(Players.id(head), target), comparison)
        case False{}:
          Unit{}
    case Con{next, rest}:
      match matches:
        case True{}:
          Equal.sym(Bool, True{}, U32.is_eq(Players.id(head), target), comparison)
        case False{}:
          %Equal.sym(Maybe<&2, Players.State>, Players.found(Players.prepend(head, Players.scan(rest, next, U32.is_eq(Players.id(next), target), target))), Players.found(Players.scan(rest, next, U32.is_eq(Players.id(next), target), target)), Players.prepend_found(head, Players.scan(rest, next, U32.is_eq(Players.id(next), target), target))) : Players.FoundTarget(_, target)
          Players.scan_target(rest, next, U32.is_eq(Players.id(next), target), target, {==})

law Players.take_target:
  for +players: List<&2, Players.State>
  for +target: U32
  Players.FoundTarget(Players.found(Players.take(players, target)), target)

def Players.take_target(players, target):
  match players:
    case Nil{}:
      Unit{}
    case Con{head, rest}:
      Players.scan_target(rest, head, U32.is_eq(Players.id(head), target), target, {==})

def Players.FoundID(found: Maybe<&2, Players.State>, target: U32) -> Data:
  match found:
    case None{}:
      Unit
    case Some{player}:
      {Players.id(player) == target : U32}

law Players.found_id:
  for +found: Maybe<&2, Players.State>
  for +target: U32
  for +comparison: Players.FoundTarget(found, target)
  Players.FoundID(found, target)

def Players.found_id(found, target, comparison):
  match found:
    case None{}:
      Unit{}
    case Some{player}:
      N.Numeric.u32_eq_sound(Players.id(player), target, comparison)

law Players.take_id:
  for +players: List<&2, Players.State>
  for +target: U32
  Players.FoundID(Players.found(Players.take(players, target)), target)

def Players.take_id(players, target):
  Players.found_id(Players.found(Players.take(players, target)), target, Players.take_target(players, target))

def Players.has(found: Maybe<&2, Players.State>) -> Bool:
  match found:
    case None{}:
      False{}
    case Some{player}:
      True{}

def Players.has_id(players: List<&2, Players.State>, +target: U32) -> Bool:
  match players:
    case Nil{}:
      False{}
    case Con{head, rest}:
      Bool.or(U32.is_eq(Players.id(head), target), Players.has_id(rest, target))

law Players.scan_success:
  for +tail: List<&2, Players.State>
  for +head: Players.State
  for +matches: Bool
  for +target: U32
  for +present: {Bool.or(matches, Players.has_id(tail, target)) == True{} : Bool}
  {Players.has(Players.found(Players.scan(tail, head, matches, target))) == True{} : Bool}

def Players.scan_success(tail, head, matches, target, present):
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
          %Equal.sym(Maybe<&2, Players.State>, Players.found(Players.prepend(head, Players.scan(rest, next, U32.is_eq(Players.id(next), target), target))), Players.found(Players.scan(rest, next, U32.is_eq(Players.id(next), target), target)), Players.prepend_found(head, Players.scan(rest, next, U32.is_eq(Players.id(next), target), target))) : {Players.has(_) == True{} : Bool}
          Players.scan_success(rest, next, U32.is_eq(Players.id(next), target), target, present)

law Players.take_success:
  for +players: List<&2, Players.State>
  for +target: U32
  for +present: {Players.has_id(players, target) == True{} : Bool}
  {Players.has(Players.found(Players.take(players, target))) == True{} : Bool}

def Players.take_success(players, target, present):
  match players:
    case Nil{}:
      Empty.absurd({False{} == True{} : Bool}, G.Bq.Bool.false_ne_true(present))
    case Con{head, rest}:
      Players.scan_success(rest, head, U32.is_eq(Players.id(head), target), target, present)

law Players.scan_hit:
  for +tail: List<&2, Players.State>
  for +head: Players.State
  for +target: U32
  {Players.scan(tail, head, True{}, target) == Players.Take{tail, Some{head}} : Players.Take}

def Players.scan_hit(tail, head, target):
  match tail:
    case Nil{}:
      {==}
    case Con{next, rest}:
      {==}

law Players.take_head:
  for +head: Players.State
  for +tail: List<&2, Players.State>
  {Players.take(Con{head, tail}, Players.id(head)) == Players.Take{tail, Some{head}} : Players.Take}

def Players.take_head(head, tail):
  %Equal.sym(Bool, U32.is_eq(Players.id(head), Players.id(head)), True{}, N.Numeric.u32_eq_refl(Players.id(head))) : {Players.scan(tail, head, _, Players.id(head)) == Players.Take{tail, Some{head}} : Players.Take}
  Players.scan_hit(tail, head, Players.id(head))

law Players.scan_missing:
  for +tail: List<&2, Players.State>
  for +head: Players.State
  for +matches: Bool
  for +target: U32
  for +absent: {Bool.or(matches, Players.has_id(tail, target)) == False{} : Bool}
  {Players.scan(tail, head, matches, target) == Players.Take{Con{head, tail}, None{}} : Players.Take}

def Players.scan_missing(tail, head, matches, target, absent):
  match tail:
    case Nil{}:
      match matches:
        case True{}:
          Empty.absurd({Players.Take{Nil{}, Some{head}} == Players.Take{Con{head, Nil{}}, None{}} : Players.Take}, N.Numeric.true_ne_false(absent))
        case False{}:
          {==}
    case Con{next, rest}:
      match matches:
        case True{}:
          Empty.absurd({Players.Take{Con{next, rest}, Some{head}} == Players.Take{Con{head, Con{next, rest}}, None{}} : Players.Take}, N.Numeric.true_ne_false(absent))
        case False{}:
          %Equal.sym(Players.Take, Players.scan(rest, next, U32.is_eq(Players.id(next), target), target), Players.Take{Con{next, rest}, None{}}, Players.scan_missing(rest, next, U32.is_eq(Players.id(next), target), target, absent)) : {Players.prepend(head, _) == Players.Take{Con{head, Con{next, rest}}, None{}} : Players.Take}
          {==}

law Players.take_missing:
  for +players: List<&2, Players.State>
  for +target: U32
  for +absent: {Players.has_id(players, target) == False{} : Bool}
  {Players.take(players, target) == Players.Take{players, None{}} : Players.Take}

def Players.take_missing(players, target, absent):
  match players:
    case Nil{}:
      {==}
    case Con{head, rest}:
      Players.scan_missing(rest, head, U32.is_eq(Players.id(head), target), target, absent)

def Players.defense_of(slot: G.Bq.Maybe(Nat)) -> U32:
  match slot:
    case Fail{unit}:
      0
    case Done{kind}:
      U32.from_nat(G.Bq.idf(kind))

def Players.defense(hero: G.Bq.Hero) -> U32:
  match hero:
    case G.Bq.Hero.Hero{inv, weapon, armor, helm, charm, gold, level, strength, agility, vitality, points}:
      U32.add(U32.add(Players.defense_of(armor), Players.defense_of(helm)), Players.defense_of(charm))

def Players.mob_hit(attack: U32, +hero: G.Bq.Hero) -> U32:
  match hero:
    case G.Bq.Hero.Hero{inv, weapon, armor, helm, charm, gold, level, strength, agility, vitality, points}:
      U32.from_nat(G.Bq.mob_damage(U32.to_nat(attack), U32.to_nat(Players.defense(G.Bq.Hero.Hero{inv, weapon, armor, helm, charm, gold, level, strength, agility, vitality, points})), G.Bq.max_hp(level, vitality)))

type Players.Event is Data:
  Players.Died{pid: U32, cid: U32, name: List<&2, Char>}
  Players.Revived{pid: U32, cid: U32}

type Players.Step is Data:
  Players.Step{player: Players.State, event: Maybe<&2, Players.Event>}

def Players.player(step: Players.Step) -> Players.State:
  match step:
    case Players.Step{player, event}:
      player

def Players.event(step: Players.Step) -> Maybe<&2, Players.Event>:
  match step:
    case Players.Step{player, event}:
      event

def Players.halt(pos: Players.Pos) -> Players.Pos:
  match pos:
    case Players.Pos{zone, x, y, dir, moving}:
      Players.Pos{zone, x, y, dir, 0}

def Players.death(player: Players.State) -> Players.Event:
  match player:
    case Players.State{pid, cid, hero, pos, vitals, style, quest, meta}:
      match meta:
        case Players.Meta{score, kills, found, name}:
          Players.Died{pid, cid, name}

def Players.finish_hit(+player: Players.State, hit: V.Vitals.Hit) -> Players.Step:
  match player:
    case Players.State{pid, cid, hero, pos, old, style, quest, meta}:
      match hit:
        case V.Vitals.Hit{vitals, fell}:
          match fell:
            case False{}:
              Players.Step{Players.State{pid, cid, hero, pos, vitals, style, quest, meta}, None{}}
            case True{}:
              Players.Step{Players.State{pid, cid, hero, Players.halt(pos), vitals, style, quest, meta}, Some{Players.death(Players.State{pid, cid, hero, pos, old, style, quest, meta})}}

def Players.hurt(+player: Players.State, attack: U32, timer: U32) -> Players.Step:
  Players.finish_hit(player, V.Vitals.hit(Players.vitals(player), Players.mob_hit(attack, Players.hero(player)), timer))

law Players.finish_hit_ok:
  for +player: Players.State
  for +hit: V.Vitals.Hit
  for +vitals_ok: V.Vitals.OK<V.Vitals.hit_state(hit), Players.maximum(player)>
  for +equipped: G.Bq.WellEquipped(Players.hero(player))
  Players.OK<Players.player(Players.finish_hit(player, hit))>

def Players.finish_hit_ok(player, hit, vitals_ok, equipped):
  match player:
    case Players.State{pid, cid, hero, pos, old, style, quest, meta}:
      match hit:
        case V.Vitals.Hit{vitals, fell}:
          match fell:
            case False{}:
              Players.OK{vitals_ok, equipped}
            case True{}:
              Players.OK{vitals_ok, equipped}

law Players.hurt_ok:
  for +player: Players.State
  for +attack: U32
  for +timer: U32
  for +valid: Players.OK<player>
  Players.OK<Players.player(Players.hurt(player, attack, timer))>

def Players.hurt_ok(player, attack, timer, valid):
  match valid:
    case Players.OK{vitals_ok, equipped}:
      Players.finish_hit_ok(player, V.Vitals.hit(Players.vitals(player), Players.mob_hit(attack, Players.hero(player)), timer), V.Vitals.hit_ok(Players.vitals(player), Players.mob_hit(attack, Players.hero(player)), timer, Players.maximum(player), vitals_ok), equipped)

type Players.Attack is Data:
  Players.Attack{pid: U32, attack: U32}

type Players.Result is Data:
  Players.Result{players: List<&2, Players.State>, events: List<&2, Players.Event>}

def Players.roster(result: Players.Result) -> List<&2, Players.State>:
  match result:
    case Players.Result{players, events}:
      players

def Players.events(result: Players.Result) -> List<&2, Players.Event>:
  match result:
    case Players.Result{players, events}:
      events

def Players.add_event(event: Maybe<&2, Players.Event>, events: List<&2, Players.Event>) -> List<&2, Players.Event>:
  match event:
    case None{}:
      events
    case Some{head}:
      Con{head, events}

def Players.prepend_step(step: Players.Step, result: Players.Result) -> Players.Result:
  match step:
    case Players.Step{player, event}:
      match result:
        case Players.Result{players, events}:
          Players.Result{Con{player, players}, Players.add_event(event, events)}

def Players.concat_events(left: List<&2, Players.Event>, right: List<&2, Players.Event>) -> List<&2, Players.Event>:
  match left:
    case Nil{}:
      right
    case Con{head, rest}:
      Con{head, Players.concat_events(rest, right)}

def Players.before(first: Players.Result, later: Players.Result) -> Players.Result:
  match first:
    case Players.Result{old_players, earlier}:
      match later:
        case Players.Result{players, events}:
          Players.Result{players, Players.concat_events(earlier, events)}

def Players.hit_taken(taken: Players.Take, attack: U32, timer: U32) -> Players.Result:
  match taken:
    case Players.Take{others, found}:
      match found:
        case None{}:
          Players.Result{others, Nil{}}
        case Some{player}:
          Players.prepend_step(Players.hurt(player, attack, timer), Players.Result{others, Nil{}})

def Players.strike(players: List<&2, Players.State>, pid: U32, attack: U32, timer: U32) -> Players.Result:
  Players.hit_taken(Players.take(players, pid), attack, timer)

# Hit order is authoritative; each hit sees the preceding hit's result.
def Players.apply_hits(hits: List<&2, Players.Attack>, players: List<&2, Players.State>, +timer: U32) -> Players.Result:
  match hits:
    case Nil{}:
      Players.Result{players, Nil{}}
    case Con{hit, rest}:
      match hit:
        case Players.Attack{pid, attack}:
          +current = Players.strike(players, pid, attack, timer)
          Players.before(current, Players.apply_hits(rest, Players.roster(current), timer))

law Players.prepend_step_all:
  for +step: Players.Step
  for +result: Players.Result
  for +head_ok: Players.OK<Players.player(step)>
  for +rest_ok: Players.All(Players.roster(result))
  Players.All(Players.roster(Players.prepend_step(step, result)))

def Players.prepend_step_all(step, result, head_ok, rest_ok):
  match step:
    case Players.Step{player, event}:
      match result:
        case Players.Result{players, events}:
          Tuple{head_ok, rest_ok}

law Players.before_all:
  for +first: Players.Result
  for +later: Players.Result
  for +valid: Players.All(Players.roster(later))
  Players.All(Players.roster(Players.before(first, later)))

def Players.before_all(first, later, valid):
  match first:
    case Players.Result{old_players, earlier}:
      match later:
        case Players.Result{players, events}:
          valid

law Players.hit_taken_all:
  for +taken: Players.Take
  for +attack: U32
  for +timer: U32
  for +valid: Players.TakeOK<taken>
  Players.All(Players.roster(Players.hit_taken(taken, attack, timer)))

def Players.hit_taken_all(taken, attack, timer, valid):
  match taken:
    case Players.Take{others, found}:
      match found:
        case None{}:
          match valid:
            case Players.ValidTake{others_ok, found_ok}:
              others_ok
        case Some{player}:
          match valid:
            case Players.ValidTake{others_ok, found_ok}:
              Players.prepend_step_all(Players.hurt(player, attack, timer), Players.Result{others, Nil{}}, Players.hurt_ok(player, attack, timer, found_ok), others_ok)

law Players.strike_all:
  for +players: List<&2, Players.State>
  for +pid: U32
  for +attack: U32
  for +timer: U32
  for +valid: Players.All(players)
  Players.All(Players.roster(Players.strike(players, pid, attack, timer)))

def Players.strike_all(players, pid, attack, timer, valid):
  Players.hit_taken_all(Players.take(players, pid), attack, timer, Players.take_ok(players, pid, valid))

law Players.apply_hits_all:
  for +hits: List<&2, Players.Attack>
  for +players: List<&2, Players.State>
  for +timer: U32
  for +valid: Players.All(players)
  Players.All(Players.roster(Players.apply_hits(hits, players, timer)))

def Players.apply_hits_all(hits, players, timer, valid):
  match hits:
    case Nil{}:
      valid
    case Con{hit, rest}:
      match hit:
        case Players.Attack{pid, attack}:
          Players.before_all(Players.strike(players, pid, attack, timer), Players.apply_hits(rest, Players.roster(Players.strike(players, pid, attack, timer)), timer), Players.apply_hits_all(rest, Players.roster(Players.strike(players, pid, attack, timer)), timer, Players.strike_all(players, pid, attack, timer, valid)))

law Players.finish_idle:
  for +player: Players.State
  {Players.finish_hit(player, V.Vitals.Hit{Players.vitals(player), False{}}) == Players.Step{player, None{}} : Players.Step}

def Players.finish_idle(player):
  match player:
    case Players.State{pid, cid, hero, pos, vitals, style, quest, meta}:
      {==}

law Players.dead_hurt_noop:
  for +player: Players.State
  for +attack: U32
  for +timer: U32
  for +dead: {V.Vitals.dead(Players.vitals(player)) == 1 : U32}
  {Players.hurt(player, attack, timer) == Players.Step{player, None{}} : Players.Step}

def Players.dead_hurt_noop(player, attack, timer, dead):
  %Equal.sym(V.Vitals.Hit, V.Vitals.hit(Players.vitals(player), Players.mob_hit(attack, Players.hero(player)), timer), V.Vitals.Hit{Players.vitals(player), False{}}, V.Vitals.dead_hit_noop(Players.vitals(player), Players.mob_hit(attack, Players.hero(player)), timer, dead)) : {Players.finish_hit(player, _) == Players.Step{player, None{}} : Players.Step}
  Players.finish_idle(player)

# Movement planning can propose coordinates; the commit owns lifecycle/zone.
type Players.Plan is Data:
  Players.Walk{x: U32, y: U32}

def Players.stay(player: Players.State) -> Players.Plan:
  match player:
    case Players.State{pid, cid, hero, pos, vitals, style, quest, meta}:
      match pos:
        case Players.Pos{zone, x, y, dir, moving}:
          Players.Walk{x, y}

def Players.walk_pos(pos: Players.Pos, plan: Players.Plan, walk: Bool) -> Players.Pos:
  match pos:
    case Players.Pos{zone, x, y, dir, moving}:
      match plan:
        case Players.Walk{nx, ny}:
          match walk:
            case False{}:
              Players.Pos{zone, x, y, dir, moving}
            case True{}:
              Players.Pos{zone, nx, ny, dir, moving}

def Players.regen_gate(ready: Bool) -> U32:
  match ready:
    case False{}:
      0
    case True{}:
      2

def Players.regen(tick: U32, hp: U32, maximum: U32) -> U32:
  Players.regen_gate(Bool.and(U32.is_eq((tick .&. 7 : U32), 0), U32.is_lt(hp, maximum)))

def Players.finish_upkeep(+player: Players.State, plan: Players.Plan, result: V.Vitals.Upkeep, spawn_x: U32, spawn_y: U32) -> Players.Step:
  match player:
    case Players.State{pid, cid, hero, pos, old, style, quest, meta}:
      match result:
        case V.Vitals.Upkeep{vitals, revived, walk}:
          match revived:
            case False{}:
              Players.Step{Players.State{pid, cid, hero, Players.walk_pos(pos, plan, walk), vitals, style, quest, meta}, None{}}
            case True{}:
              Players.Step{Players.State{pid, cid, hero, Players.Pos{0, spawn_x, spawn_y, 1, 0}, vitals, style, quest, meta}, Some{Players.Revived{pid, cid}}}

def Players.upkeep(+player: Players.State, plan: Players.Plan, tick: U32, spawn_x: U32, spawn_y: U32) -> Players.Step:
  Players.finish_upkeep(player, plan, V.Vitals.upkeep_hero(Players.vitals(player), Players.regen(tick, V.Vitals.hp(Players.vitals(player)), Players.maximum(player)), Players.hero(player), 4294967295), spawn_x, spawn_y)

law Players.finish_upkeep_ok:
  for +player: Players.State
  for +plan: Players.Plan
  for +result: V.Vitals.Upkeep
  for +spawn_x: U32
  for +spawn_y: U32
  for +vitals_ok: V.Vitals.OK<V.Vitals.upkeep_state(result), Players.maximum(player)>
  for +equipped: G.Bq.WellEquipped(Players.hero(player))
  Players.OK<Players.player(Players.finish_upkeep(player, plan, result, spawn_x, spawn_y))>

def Players.finish_upkeep_ok(player, plan, result, spawn_x, spawn_y, vitals_ok, equipped):
  match player:
    case Players.State{pid, cid, hero, pos, old, style, quest, meta}:
      match result:
        case V.Vitals.Upkeep{vitals, revived, walk}:
          match revived:
            case False{}:
              Players.OK{vitals_ok, equipped}
            case True{}:
              Players.OK{vitals_ok, equipped}

law Players.upkeep_ok:
  for +player: Players.State
  for +plan: Players.Plan
  for +tick: U32
  for +spawn_x: U32
  for +spawn_y: U32
  for +valid: Players.OK<player>
  Players.OK<Players.player(Players.upkeep(player, plan, tick, spawn_x, spawn_y))>

def Players.upkeep_ok(player, plan, tick, spawn_x, spawn_y, valid):
  match valid:
    case Players.OK{vitals_ok, equipped}:
      Players.finish_upkeep_ok(player, plan, V.Vitals.upkeep_hero(Players.vitals(player), Players.regen(tick, V.Vitals.hp(Players.vitals(player)), Players.maximum(player)), Players.hero(player), 4294967295), spawn_x, spawn_y, V.Vitals.upkeep_hero_ok(Players.vitals(player), Players.regen(tick, V.Vitals.hp(Players.vitals(player)), Players.maximum(player)), Players.hero(player), 4294967295, vitals_ok, {==}), equipped)

def Players.upkeep_all(players: List<&2, Players.State>, plans: List<&2, Players.Plan>, +tick: U32, +spawn_x: U32, +spawn_y: U32) -> Players.Result:
  match players:
    case Nil{}:
      Players.Result{Nil{}, Nil{}}
    case Con{head, rest}:
      match plans:
        case Nil{}:
          +shared = head
          Players.prepend_step(Players.upkeep(shared, Players.stay(shared), tick, spawn_x, spawn_y), Players.upkeep_all(rest, Nil{}, tick, spawn_x, spawn_y))
        case Con{plan, later}:
          Players.prepend_step(Players.upkeep(head, plan, tick, spawn_x, spawn_y), Players.upkeep_all(rest, later, tick, spawn_x, spawn_y))

law Players.upkeep_all_ok:
  for +players: List<&2, Players.State>
  for +plans: List<&2, Players.Plan>
  for +tick: U32
  for +spawn_x: U32
  for +spawn_y: U32
  for +valid: Players.All(players)
  Players.All(Players.roster(Players.upkeep_all(players, plans, tick, spawn_x, spawn_y)))

def Players.upkeep_all_ok(players, plans, tick, spawn_x, spawn_y, valid):
  match players:
    case Nil{}:
      Unit{}
    case Con{head, rest}:
      match plans:
        case Nil{}:
          match valid:
            case Tuple{head_ok, rest_ok}:
              Players.prepend_step_all(Players.upkeep(head, Players.stay(head), tick, spawn_x, spawn_y), Players.upkeep_all(rest, Nil{}, tick, spawn_x, spawn_y), Players.upkeep_ok(head, Players.stay(head), tick, spawn_x, spawn_y, head_ok), Players.upkeep_all_ok(rest, Nil{}, tick, spawn_x, spawn_y, rest_ok))
        case Con{plan, later}:
          match valid:
            case Tuple{head_ok, rest_ok}:
              Players.prepend_step_all(Players.upkeep(head, plan, tick, spawn_x, spawn_y), Players.upkeep_all(rest, later, tick, spawn_x, spawn_y), Players.upkeep_ok(head, plan, tick, spawn_x, spawn_y, head_ok), Players.upkeep_all_ok(rest, later, tick, spawn_x, spawn_y, rest_ok))

def Players.spawn(pid: U32, cid: U32, style: Players.Style, name: List<&2, Char>, spawn_x: U32, spawn_y: U32) -> Players.State:
  +hero = G.Bq.fresh_hero
  Players.State{pid, cid, hero, Players.Pos{0, spawn_x, spawn_y, 1, 0}, V.Vitals.spawn(R.Rewards.maximum(hero, 4294967295)), style, Players.Quest{0, 0, 0, 0, 0, 0}, Players.Meta{0, 0, 0, name}}

law Players.spawn_ok:
  for +pid: U32
  for +cid: U32
  for +style: Players.Style
  for +name: List<&2, Char>
  for +spawn_x: U32
  for +spawn_y: U32
  Players.OK<Players.spawn(pid, cid, style, name, spawn_x, spawn_y)>

def Players.spawn_ok(pid, cid, style, name, spawn_x, spawn_y):
  Players.OK{V.Vitals.spawn_hero_ok(G.Bq.fresh_hero, 4294967295, {==}), Tuple{Unit{}, Tuple{Unit{}, Tuple{Unit{}, Unit{}}}}}

law Players.prepend_step_count:
  for +step: Players.Step
  for +result: Players.Result
  {Players.length(Players.roster(Players.prepend_step(step, result))) == Succ{Players.length(Players.roster(result))} : Nat}

def Players.prepend_step_count(step, result):
  match step:
    case Players.Step{player, event}:
      match result:
        case Players.Result{players, events}:
          {==}

law Players.before_roster:
  for +first: Players.Result
  for +later: Players.Result
  {Players.roster(Players.before(first, later)) == Players.roster(later) : List<&2, Players.State>}

def Players.before_roster(first, later):
  match first:
    case Players.Result{old_players, earlier}:
      match later:
        case Players.Result{players, events}:
          {==}

law Players.hit_taken_count:
  for +taken: Players.Take
  for +attack: U32
  for +timer: U32
  {Players.length(Players.roster(Players.hit_taken(taken, attack, timer))) == Players.length(Players.restore(taken)) : Nat}

def Players.hit_taken_count(taken, attack, timer):
  match taken:
    case Players.Take{others, found}:
      match found:
        case None{}:
          {==}
        case Some{player}:
          Players.prepend_step_count(Players.hurt(player, attack, timer), Players.Result{others, Nil{}})

law Players.strike_count:
  for +players: List<&2, Players.State>
  for +pid: U32
  for +attack: U32
  for +timer: U32
  {Players.length(Players.roster(Players.strike(players, pid, attack, timer))) == Players.length(players) : Nat}

def Players.strike_count(players, pid, attack, timer):
  Equal.trans(Nat, Players.length(Players.roster(Players.strike(players, pid, attack, timer))), Players.length(Players.restore(Players.take(players, pid))), Players.length(players), Players.hit_taken_count(Players.take(players, pid), attack, timer), Players.take_count(players, pid))

law Players.apply_hits_count:
  for +hits: List<&2, Players.Attack>
  for +players: List<&2, Players.State>
  for +timer: U32
  {Players.length(Players.roster(Players.apply_hits(hits, players, timer))) == Players.length(players) : Nat}

def Players.apply_hits_count(hits, players, timer):
  match hits:
    case Nil{}:
      {==}
    case Con{hit, rest}:
      match hit:
        case Players.Attack{pid, attack}:
          %Equal.sym(List<&2, Players.State>, Players.roster(Players.before(Players.strike(players, pid, attack, timer), Players.apply_hits(rest, Players.roster(Players.strike(players, pid, attack, timer)), timer))), Players.roster(Players.apply_hits(rest, Players.roster(Players.strike(players, pid, attack, timer)), timer)), Players.before_roster(Players.strike(players, pid, attack, timer), Players.apply_hits(rest, Players.roster(Players.strike(players, pid, attack, timer)), timer))) : {Players.length(_) == Players.length(players) : Nat}
          Equal.trans(Nat, Players.length(Players.roster(Players.apply_hits(rest, Players.roster(Players.strike(players, pid, attack, timer)), timer))), Players.length(Players.roster(Players.strike(players, pid, attack, timer))), Players.length(players), Players.apply_hits_count(rest, Players.roster(Players.strike(players, pid, attack, timer)), timer), Players.strike_count(players, pid, attack, timer))

law Players.upkeep_count:
  for +players: List<&2, Players.State>
  for +plans: List<&2, Players.Plan>
  for +tick: U32
  for +spawn_x: U32
  for +spawn_y: U32
  {Players.length(Players.roster(Players.upkeep_all(players, plans, tick, spawn_x, spawn_y))) == Players.length(players) : Nat}

def Players.upkeep_count(players, plans, tick, spawn_x, spawn_y):
  match players:
    case Nil{}:
      {==}
    case Con{head, rest}:
      match plans:
        case Nil{}:
          %Equal.sym(Nat, Players.length(Players.roster(Players.prepend_step(Players.upkeep(head, Players.stay(head), tick, spawn_x, spawn_y), Players.upkeep_all(rest, Nil{}, tick, spawn_x, spawn_y)))), Succ{Players.length(Players.roster(Players.upkeep_all(rest, Nil{}, tick, spawn_x, spawn_y)))}, Players.prepend_step_count(Players.upkeep(head, Players.stay(head), tick, spawn_x, spawn_y), Players.upkeep_all(rest, Nil{}, tick, spawn_x, spawn_y))) : {_ == Succ{Players.length(rest)} : Nat}
          %Players.upkeep_count(rest, Nil{}, tick, spawn_x, spawn_y) : {Succ{Players.length(Players.roster(Players.upkeep_all(rest, Nil{}, tick, spawn_x, spawn_y)))} == Succ{_} : Nat}
          {==}
        case Con{plan, later}:
          %Equal.sym(Nat, Players.length(Players.roster(Players.prepend_step(Players.upkeep(head, plan, tick, spawn_x, spawn_y), Players.upkeep_all(rest, later, tick, spawn_x, spawn_y)))), Succ{Players.length(Players.roster(Players.upkeep_all(rest, later, tick, spawn_x, spawn_y)))}, Players.prepend_step_count(Players.upkeep(head, plan, tick, spawn_x, spawn_y), Players.upkeep_all(rest, later, tick, spawn_x, spawn_y))) : {_ == Succ{Players.length(rest)} : Nat}
          %Players.upkeep_count(rest, later, tick, spawn_x, spawn_y) : {Succ{Players.length(Players.roster(Players.upkeep_all(rest, later, tick, spawn_x, spawn_y)))} == Succ{_} : Nat}
          {==}
