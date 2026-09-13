# Authoritative hero commands lifted to complete player records.
import Base
import ./game.bend as G
import ./health.bend as H
import ./rewards.bend as R
import ./vitals.bend as V
import ./players.bend as P

# These flags are derived from the operation, never supplied by the wire.
def Inventory.shop(op: G.Bq.HOp) -> Bool:
  match op:
    case G.Bq.HOp.Buy{k}: True{}
    case G.Bq.HOp.Equip{k}: False{}
    case G.Bq.HOp.Unequip{s}: False{}
    case G.Bq.HOp.Quaff{}: False{}
    case G.Bq.HOp.Alloc{s}: False{}
    case G.Bq.HOp.LevelUp{}: False{}

def Inventory.potion(op: G.Bq.HOp) -> Bool:
  match op:
    case G.Bq.HOp.Buy{k}: False{}
    case G.Bq.HOp.Equip{k}: False{}
    case G.Bq.HOp.Unequip{s}: False{}
    case G.Bq.HOp.Quaff{}: True{}
    case G.Bq.HOp.Alloc{s}: False{}
    case G.Bq.HOp.LevelUp{}: False{}

def Inventory.health(healing: Bool, +hp: U32, amount: U32, +maximum: U32) -> U32:
  match healing:
    case False{}: H.Health.clamp_word(hp, maximum)
    case True{}: H.Health.heal_word(hp, amount, maximum)

law Inventory.health_bound:
  for +healing: Bool
  for +hp: U32
  for +amount: U32
  for +maximum: U32
  {G.Bq.Nat.le(U32.to_nat(Inventory.health(healing, hp, amount, maximum)), U32.to_nat(maximum)) == True{} : Bool}

def Inventory.health_bound(healing, hp, amount, maximum):
  match healing:
    case False{}: H.Health.clamp_word_bounded(hp, maximum)
    case True{}: H.Health.heal_word_bounded(hp, amount, maximum)

law Inventory.health_positive:
  for +healing: Bool
  for +hp: U32
  for +amount: U32
  for +maximum: U32
  for +positive: {G.Bq.Nat.le(1n, U32.to_nat(hp)) == True{} : Bool}
  for +limit: {G.Bq.Nat.le(1n, U32.to_nat(maximum)) == True{} : Bool}
  {G.Bq.Nat.le(1n, U32.to_nat(Inventory.health(healing, hp, amount, maximum))) == True{} : Bool}

def Inventory.health_positive(healing, hp, amount, maximum, positive, limit):
  match healing:
    case False{}: H.Health.cap_nat_word_positive(U32.to_nat(hp), maximum, positive, limit)
    case True{}:
      %Equal.sym(Nat, U32.to_nat(H.Health.heal_word(hp, amount, maximum)), H.Health.heal(U32.to_nat(hp), U32.to_nat(amount), U32.to_nat(maximum)), H.Health.heal_word_exact(hp, amount, maximum)) : {G.Bq.Nat.le(1n, _) == True{} : Bool}
      %Equal.sym(Nat, H.Health.heal(U32.to_nat(hp), U32.to_nat(amount), U32.to_nat(maximum)), H.Health.spec_heal(U32.to_nat(hp), U32.to_nat(amount), U32.to_nat(maximum)), H.Health.heal_agrees(U32.to_nat(hp), U32.to_nat(amount), U32.to_nat(maximum))) : {G.Bq.Nat.le(1n, _) == True{} : Bool}
      H.Health.le_min(1n, G.Bq.Nat.add(U32.to_nat(hp), U32.to_nat(amount)), U32.to_nat(maximum), H.Health.le_trans(1n, U32.to_nat(hp), G.Bq.Nat.add(U32.to_nat(hp), U32.to_nat(amount)), positive, H.Health.le_add(U32.to_nat(hp), U32.to_nat(amount))), limit)

# Rebuild only the hero and health fields. Dead players are gated before this.
def Inventory.commit(player: P.Players.State, +hero: G.Bq.Hero, healing: Bool, amount: U32) -> P.Players.State:
  match player:
    case P.Players.State{pid, cid, old, pos, vitals, style, quest, meta}:
      match vitals:
        case V.Vitals.State{hp, xp, dead, respawn, attack, spin}:
          P.Players.State{pid, cid, hero, pos, V.Vitals.State{Inventory.health(healing, hp, amount, R.Rewards.maximum(hero, 4294967295)), xp, dead, respawn, attack, spin}, style, quest, meta}

law Inventory.commit_ok:
  for +player: P.Players.State
  for +hero: G.Bq.Hero
  for +healing: Bool
  for +amount: U32
  for +alive: {V.Vitals.dead(P.Players.vitals(player)) == 0 : U32}
  for +positive: {G.Bq.Nat.le(1n, U32.to_nat(V.Vitals.hp(P.Players.vitals(player)))) == True{} : Bool}
  for +equipped: G.Bq.WellEquipped(hero)
  P.Players.OK<Inventory.commit(player, hero, healing, amount)>

def Inventory.commit_ok(player, hero, healing, amount, alive, positive, equipped):
  match player:
    case P.Players.State{pid, cid, old, pos, vitals, style, quest, meta}:
      match vitals:
        case V.Vitals.State{hp, xp, dead, respawn, attack, spin}:
          P.Players.OK{V.Vitals.OK{Inventory.health_bound(healing, hp, amount, R.Rewards.maximum(hero, 4294967295)), V.Vitals.Alive{alive, Inventory.health_positive(healing, hp, amount, R.Rewards.maximum(hero, 4294967295), positive, R.Rewards.maximum_positive(hero, 4294967295, {==}))}}, equipped}

# A failed kernel operation is an exact no-op, including the vital fields.
def Inventory.accept(accepted: Bool, +op: G.Bq.HOp, +player: P.Players.State, amount: U32) -> P.Players.State:
  match accepted:
    case False{}: player
    case True{}: Inventory.commit(player, G.Bq.hero_step(op, P.Players.hero(player)), Inventory.potion(op), amount)

def Inventory.live(allowed: Bool, +op: G.Bq.HOp, +player: P.Players.State, amount: U32) -> P.Players.State:
  match allowed:
    case False{}: player
    case True{}: Inventory.accept(G.Bq.hop_ok(op, P.Players.hero(player)), op, player, amount)

def Inventory.gate(dead: Bool, allowed: Bool, op: G.Bq.HOp, +player: P.Players.State, amount: U32) -> P.Players.State:
  match dead:
    case True{}: player
    case False{}: Inventory.live(allowed, op, player, amount)

def Inventory.step(+op: G.Bq.HOp, +player: P.Players.State, near_shop: Bool, amount: U32) -> P.Players.State:
  Inventory.gate(U32.is_eq(V.Vitals.dead(P.Players.vitals(player)), 1), Bool.or(Bool.not(Inventory.shop(op)), near_shop), op, player, amount)

law Inventory.accept_ok:
  for +accepted: Bool
  for +op: G.Bq.HOp
  for +player: P.Players.State
  for +amount: U32
  for +alive: {V.Vitals.dead(P.Players.vitals(player)) == 0 : U32}
  for +positive: {G.Bq.Nat.le(1n, U32.to_nat(V.Vitals.hp(P.Players.vitals(player)))) == True{} : Bool}
  for +valid: P.Players.OK<player>
  P.Players.OK<Inventory.accept(accepted, op, player, amount)>

def Inventory.accept_ok(accepted, op, player, amount, alive, positive, valid):
  match accepted:
    case False{}: valid
    case True{}:
      match valid:
        case P.Players.OK{vitals, equipped}:
          Inventory.commit_ok(player, G.Bq.hero_step(op, P.Players.hero(player)), Inventory.potion(op), amount, alive, positive, G.Bq.ops_respect_requirements(op, P.Players.hero(player), equipped))

law Inventory.live_ok:
  for +allowed: Bool
  for +op: G.Bq.HOp
  for +player: P.Players.State
  for +amount: U32
  for +alive: {V.Vitals.dead(P.Players.vitals(player)) == 0 : U32}
  for +positive: {G.Bq.Nat.le(1n, U32.to_nat(V.Vitals.hp(P.Players.vitals(player)))) == True{} : Bool}
  for +valid: P.Players.OK<player>
  P.Players.OK<Inventory.live(allowed, op, player, amount)>

def Inventory.live_ok(allowed, op, player, amount, alive, positive, valid):
  match allowed:
    case False{}: valid
    case True{}: Inventory.accept_ok(G.Bq.hop_ok(op, P.Players.hero(player)), op, player, amount, alive, positive, valid)

law Inventory.step_ok:
  for +op: G.Bq.HOp
  for +player: P.Players.State
  for +near_shop: Bool
  for +amount: U32
  for +valid: P.Players.OK<player>
  P.Players.OK<Inventory.step(op, player, near_shop, amount)>

def Inventory.step_ok(op, player, near_shop, amount, valid):
  match valid:
    case P.Players.OK{vitals, equipped}:
      match vitals:
        case V.Vitals.OK{bound, life}:
          match life:
            case V.Vitals.Dead{flag, zero}:
              %Equal.sym(U32, V.Vitals.dead(P.Players.vitals(player)), 1, flag) : P.Players.OK<Inventory.gate(U32.is_eq(_, 1), Bool.or(Bool.not(Inventory.shop(op)), near_shop), op, player, amount)>
              P.Players.OK{V.Vitals.OK{bound, V.Vitals.Dead{flag, zero}}, equipped}
            case V.Vitals.Alive{flag, positive}:
              %Equal.sym(U32, V.Vitals.dead(P.Players.vitals(player)), 0, flag) : P.Players.OK<Inventory.gate(U32.is_eq(_, 1), Bool.or(Bool.not(Inventory.shop(op)), near_shop), op, player, amount)>
              Inventory.live_ok(Bool.or(Bool.not(Inventory.shop(op)), near_shop), op, player, amount, flag, positive, P.Players.OK{V.Vitals.OK{bound, V.Vitals.Alive{flag, positive}}, equipped})

law Inventory.dead_noop:
  for +op: G.Bq.HOp
  for +player: P.Players.State
  for +near_shop: Bool
  for +amount: U32
  for +dead: {V.Vitals.dead(P.Players.vitals(player)) == 1 : U32}
  {Inventory.step(op, player, near_shop, amount) == player : P.Players.State}

def Inventory.dead_noop(op, player, near_shop, amount, dead):
  %Equal.sym(U32, V.Vitals.dead(P.Players.vitals(player)), 1, dead) : {Inventory.gate(U32.is_eq(_, 1), Bool.or(Bool.not(Inventory.shop(op)), near_shop), op, player, amount) == player : P.Players.State}
  {==}

law Inventory.blocked_gate:
  for +dead: Bool
  for +op: G.Bq.HOp
  for +player: P.Players.State
  for +amount: U32
  {Inventory.gate(dead, False{}, op, player, amount) == player : P.Players.State}

def Inventory.blocked_gate(dead, op, player, amount):
  match dead:
    case True{}: {==}
    case False{}: {==}

law Inventory.buy_requires_shop:
  for +kind: Nat
  for +player: P.Players.State
  for +amount: U32
  {Inventory.step(G.Bq.HOp.Buy{kind}, player, False{}, amount) == player : P.Players.State}

def Inventory.buy_requires_shop(kind, player, amount):
  Inventory.blocked_gate(U32.is_eq(V.Vitals.dead(P.Players.vitals(player)), 1), G.Bq.HOp.Buy{kind}, player, amount)

law Inventory.rejected_gate:
  for +dead: Bool
  for +allowed: Bool
  for +op: G.Bq.HOp
  for +player: P.Players.State
  for +amount: U32
  for +rejected: {G.Bq.hop_ok(op, P.Players.hero(player)) == False{} : Bool}
  {Inventory.gate(dead, allowed, op, player, amount) == player : P.Players.State}

def Inventory.rejected_gate(dead, allowed, op, player, amount, rejected):
  match dead:
    case True{}: {==}
    case False{}:
      match allowed:
        case False{}: {==}
        case True{}:
          %Equal.sym(Bool, G.Bq.hop_ok(op, P.Players.hero(player)), False{}, rejected) : {Inventory.accept(_, op, player, amount) == player : P.Players.State}
          {==}

law Inventory.rejected_noop:
  for +op: G.Bq.HOp
  for +player: P.Players.State
  for +near_shop: Bool
  for +amount: U32
  for +rejected: {G.Bq.hop_ok(op, P.Players.hero(player)) == False{} : Bool}
  {Inventory.step(op, player, near_shop, amount) == player : P.Players.State}

def Inventory.rejected_noop(op, player, near_shop, amount, rejected):
  Inventory.rejected_gate(U32.is_eq(V.Vitals.dead(P.Players.vitals(player)), 1), Bool.or(Bool.not(Inventory.shop(op)), near_shop), op, player, amount, rejected)

law Inventory.quaff_accepted:
  for +player: P.Players.State
  for +near_shop: Bool
  for +amount: U32
  for +alive: {V.Vitals.dead(P.Players.vitals(player)) == 0 : U32}
  for +accepted: {G.Bq.hop_ok(G.Bq.HOp.Quaff{}, P.Players.hero(player)) == True{} : Bool}
  {Inventory.step(G.Bq.HOp.Quaff{}, player, near_shop, amount) == Inventory.commit(player, G.Bq.hero_step(G.Bq.HOp.Quaff{}, P.Players.hero(player)), True{}, amount) : P.Players.State}

def Inventory.quaff_accepted(player, near_shop, amount, alive, accepted):
  %Equal.sym(U32, V.Vitals.dead(P.Players.vitals(player)), 0, alive) : {Inventory.gate(U32.is_eq(_, 1), True{}, G.Bq.HOp.Quaff{}, player, amount) == Inventory.commit(player, G.Bq.hero_step(G.Bq.HOp.Quaff{}, P.Players.hero(player)), True{}, amount) : P.Players.State}
  %Equal.sym(Bool, G.Bq.hop_ok(G.Bq.HOp.Quaff{}, P.Players.hero(player)), True{}, accepted) : {Inventory.accept(_, G.Bq.HOp.Quaff{}, player, amount) == Inventory.commit(player, G.Bq.hero_step(G.Bq.HOp.Quaff{}, P.Players.hero(player)), True{}, amount) : P.Players.State}
  {==}

# Every other field is retained exactly, including cooldowns and identity.
type Inventory.Frame is Data:
  Inventory.Frame{pid: U32, cid: U32, pos: P.Players.Pos, xp: U32, dead: U32, respawn: U32, attack: U32, spin: U32, style: P.Players.Style, quest: P.Players.Quest, meta: P.Players.Meta}

def Inventory.frame(player: P.Players.State) -> Inventory.Frame:
  match player:
    case P.Players.State{pid, cid, hero, pos, vitals, style, quest, meta}:
      match vitals:
        case V.Vitals.State{hp, xp, dead, respawn, attack, spin}:
          Inventory.Frame{pid, cid, pos, xp, dead, respawn, attack, spin, style, quest, meta}

law Inventory.commit_frame:
  for +player: P.Players.State
  for +hero: G.Bq.Hero
  for +healing: Bool
  for +amount: U32
  {Inventory.frame(Inventory.commit(player, hero, healing, amount)) == Inventory.frame(player) : Inventory.Frame}

def Inventory.commit_frame(player, hero, healing, amount):
  match player:
    case P.Players.State{pid, cid, old, pos, vitals, style, quest, meta}:
      match vitals:
        case V.Vitals.State{hp, xp, dead, respawn, attack, spin}:
          {==}

law Inventory.accept_frame:
  for +accepted: Bool
  for +op: G.Bq.HOp
  for +player: P.Players.State
  for +amount: U32
  {Inventory.frame(Inventory.accept(accepted, op, player, amount)) == Inventory.frame(player) : Inventory.Frame}

def Inventory.accept_frame(accepted, op, player, amount):
  match accepted:
    case False{}: {==}
    case True{}: Inventory.commit_frame(player, G.Bq.hero_step(op, P.Players.hero(player)), Inventory.potion(op), amount)

law Inventory.live_frame:
  for +allowed: Bool
  for +op: G.Bq.HOp
  for +player: P.Players.State
  for +amount: U32
  {Inventory.frame(Inventory.live(allowed, op, player, amount)) == Inventory.frame(player) : Inventory.Frame}

def Inventory.live_frame(allowed, op, player, amount):
  match allowed:
    case False{}: {==}
    case True{}: Inventory.accept_frame(G.Bq.hop_ok(op, P.Players.hero(player)), op, player, amount)

law Inventory.gate_frame:
  for +dead: Bool
  for +allowed: Bool
  for +op: G.Bq.HOp
  for +player: P.Players.State
  for +amount: U32
  {Inventory.frame(Inventory.gate(dead, allowed, op, player, amount)) == Inventory.frame(player) : Inventory.Frame}

def Inventory.gate_frame(dead, allowed, op, player, amount):
  match dead:
    case True{}: {==}
    case False{}: Inventory.live_frame(allowed, op, player, amount)

law Inventory.step_frame:
  for +op: G.Bq.HOp
  for +player: P.Players.State
  for +near_shop: Bool
  for +amount: U32
  {Inventory.frame(Inventory.step(op, player, near_shop, amount)) == Inventory.frame(player) : Inventory.Frame}

def Inventory.step_frame(op, player, near_shop, amount):
  Inventory.gate_frame(U32.is_eq(V.Vitals.dead(P.Players.vitals(player)), 1), Bool.or(Bool.not(Inventory.shop(op)), near_shop), op, player, amount)

type Inventory.Notice is Data:
  Inventory.Quiet{}
  Inventory.TooFar{}
  Inventory.NoGold{}

def Inventory.buy_notice(near_shop: Bool, accepted: Bool) -> Inventory.Notice:
  match near_shop:
    case False{}: Inventory.TooFar{}
    case True{}:
      match accepted:
        case False{}: Inventory.NoGold{}
        case True{}: Inventory.Quiet{}

def Inventory.notice_gate(dead: Bool, buying: Bool, near_shop: Bool, accepted: Bool) -> Inventory.Notice:
  match dead:
    case True{}: Inventory.Quiet{}
    case False{}:
      match buying:
        case False{}: Inventory.Quiet{}
        case True{}: Inventory.buy_notice(near_shop, accepted)

def Inventory.notice(+op: G.Bq.HOp, +player: P.Players.State, near_shop: Bool) -> Inventory.Notice:
  Inventory.notice_gate(U32.is_eq(V.Vitals.dead(P.Players.vitals(player)), 1), Inventory.shop(op), near_shop, G.Bq.hop_ok(op, P.Players.hero(player)))

type Inventory.Reply is Data:
  Inventory.Reply{cid: U32, notice: Inventory.Notice}

def Inventory.cid(player: P.Players.State) -> U32:
  match player:
    case P.Players.State{pid, cid, hero, pos, vitals, style, quest, meta}: cid

type Inventory.Result is Data:
  Inventory.Result{players: List<&2, P.Players.State>, reply: Maybe<&2, Inventory.Reply>}

def Inventory.roster(result: Inventory.Result) -> List<&2, P.Players.State>:
  match result:
    case Inventory.Result{players, reply}: players

def Inventory.apply_taken(taken: P.Players.Take, +op: G.Bq.HOp, +near_shop: Bool, amount: U32) -> Inventory.Result:
  match taken:
    case P.Players.Take{others, found}:
      match found:
        case None{}: Inventory.Result{others, None{}}
        case Some{player}:
          +shared = player
          Inventory.Result{Con{Inventory.step(op, shared, near_shop, amount), others}, Some{Inventory.Reply{Inventory.cid(shared), Inventory.notice(op, shared, near_shop)}}}

def Inventory.run(players: List<&2, P.Players.State>, target: U32, op: G.Bq.HOp, near_shop: Bool, amount: U32) -> Inventory.Result:
  Inventory.apply_taken(P.Players.take(players, target), op, near_shop, amount)

law Inventory.apply_taken_ok:
  for +taken: P.Players.Take
  for +op: G.Bq.HOp
  for +near_shop: Bool
  for +amount: U32
  for +valid: P.Players.TakeOK<taken>
  P.Players.All(Inventory.roster(Inventory.apply_taken(taken, op, near_shop, amount)))

def Inventory.apply_taken_ok(taken, op, near_shop, amount, valid):
  match taken:
    case P.Players.Take{others, found}:
      match found:
        case None{}:
          match valid:
            case P.Players.ValidTake{others_ok, found_ok}: others_ok
        case Some{player}:
          match valid:
            case P.Players.ValidTake{others_ok, found_ok}:
              Tuple{Inventory.step_ok(op, player, near_shop, amount, found_ok), others_ok}

law Inventory.run_ok:
  for +players: List<&2, P.Players.State>
  for +target: U32
  for +op: G.Bq.HOp
  for +near_shop: Bool
  for +amount: U32
  for +valid: P.Players.All(players)
  P.Players.All(Inventory.roster(Inventory.run(players, target, op, near_shop, amount)))

def Inventory.run_ok(players, target, op, near_shop, amount, valid):
  Inventory.apply_taken_ok(P.Players.take(players, target), op, near_shop, amount, P.Players.take_ok(players, target, valid))

law Inventory.apply_taken_count:
  for +taken: P.Players.Take
  for +op: G.Bq.HOp
  for +near_shop: Bool
  for +amount: U32
  {P.Players.length(Inventory.roster(Inventory.apply_taken(taken, op, near_shop, amount))) == P.Players.length(P.Players.restore(taken)) : Nat}

def Inventory.apply_taken_count(taken, op, near_shop, amount):
  match taken:
    case P.Players.Take{others, found}:
      match found:
        case None{}: {==}
        case Some{player}: {==}

law Inventory.run_count:
  for +players: List<&2, P.Players.State>
  for +target: U32
  for +op: G.Bq.HOp
  for +near_shop: Bool
  for +amount: U32
  {P.Players.length(Inventory.roster(Inventory.run(players, target, op, near_shop, amount))) == P.Players.length(players) : Nat}

def Inventory.run_count(players, target, op, near_shop, amount):
  Equal.trans(Nat, P.Players.length(Inventory.roster(Inventory.run(players, target, op, near_shop, amount))), P.Players.length(P.Players.restore(P.Players.take(players, target))), P.Players.length(players), Inventory.apply_taken_count(P.Players.take(players, target), op, near_shop, amount), P.Players.take_count(players, target))

type Inventory.Command is Data:
  Inventory.Command{target: U32, op: G.Bq.HOp, near_shop: Bool}

def Inventory.trace(commands: List<&2, Inventory.Command>, players: List<&2, P.Players.State>, +amount: U32) -> List<&2, P.Players.State>:
  match commands:
    case Nil{}: players
    case Con{head, rest}:
      match head:
        case Inventory.Command{target, op, near_shop}:
          Inventory.trace(rest, Inventory.roster(Inventory.run(players, target, op, near_shop, amount)), amount)

law Inventory.trace_ok:
  for +commands: List<&2, Inventory.Command>
  for +players: List<&2, P.Players.State>
  for +amount: U32
  for +valid: P.Players.All(players)
  P.Players.All(Inventory.trace(commands, players, amount))

def Inventory.trace_ok(commands, players, amount, valid):
  match commands:
    case Nil{}: valid
    case Con{head, rest}:
      match head:
        case Inventory.Command{target, op, near_shop}:
          Inventory.trace_ok(rest, Inventory.roster(Inventory.run(players, target, op, near_shop, amount)), amount, Inventory.run_ok(players, target, op, near_shop, amount, valid))

def Inventory.frames(players: List<&2, P.Players.State>) -> List<&2, Inventory.Frame>:
  match players:
    case Nil{}: Nil{}
    case Con{head, rest}: Con{Inventory.frame(head), Inventory.frames(rest)}

law Inventory.apply_taken_frames:
  for +taken: P.Players.Take
  for +op: G.Bq.HOp
  for +near_shop: Bool
  for +amount: U32
  {Inventory.frames(Inventory.roster(Inventory.apply_taken(taken, op, near_shop, amount))) == Inventory.frames(P.Players.restore(taken)) : List<&2, Inventory.Frame>}

def Inventory.apply_taken_frames(taken, op, near_shop, amount):
  match taken:
    case P.Players.Take{others, found}:
      match found:
        case None{}: {==}
        case Some{player}:
          %Inventory.step_frame(op, player, near_shop, amount) : {Con{Inventory.frame(Inventory.step(op, player, near_shop, amount)), Inventory.frames(others)} == Con{_, Inventory.frames(others)} : List<&2, Inventory.Frame>}
          {==}

type Inventory.Conserved<-before: List<&2, P.Players.State>, -after: List<&2, P.Players.State>> is Data:
  Inventory.Conserved{ordered: List<&2, P.Players.State>, permutation: P.Players.Perm<ordered, before>, frames: {Inventory.frames(after) == Inventory.frames(ordered) : List<&2, Inventory.Frame>}}

law Inventory.run_conserves:
  for +players: List<&2, P.Players.State>
  for +target: U32
  for +op: G.Bq.HOp
  for +near_shop: Bool
  for +amount: U32
  Inventory.Conserved<players, Inventory.roster(Inventory.run(players, target, op, near_shop, amount))>

def Inventory.run_conserves(players, target, op, near_shop, amount):
  Inventory.Conserved{P.Players.restore(P.Players.take(players, target)), P.Players.take_restores(players, target), Inventory.apply_taken_frames(P.Players.take(players, target), op, near_shop, amount)}

law Inventory.run_missing:
  for +players: List<&2, P.Players.State>
  for +target: U32
  for +op: G.Bq.HOp
  for +near_shop: Bool
  for +amount: U32
  for +missing: {P.Players.has_id(players, target) == False{} : Bool}
  {Inventory.run(players, target, op, near_shop, amount) == Inventory.Result{players, None{}} : Inventory.Result}

def Inventory.run_missing(players, target, op, near_shop, amount, missing):
  %Equal.sym(P.Players.Take, P.Players.take(players, target), P.Players.Take{players, None{}}, P.Players.take_missing(players, target, missing)) : {Inventory.apply_taken(_, op, near_shop, amount) == Inventory.Result{players, None{}} : Inventory.Result}
  {==}

law Inventory.commit_hero:
  for +player: P.Players.State
  for +hero: G.Bq.Hero
  for +healing: Bool
  for +amount: U32
  {P.Players.hero(Inventory.commit(player, hero, healing, amount)) == hero : G.Bq.Hero}

def Inventory.commit_hero(player, hero, healing, amount):
  match player:
    case P.Players.State{pid, cid, old, pos, vitals, style, quest, meta}:
      match vitals:
        case V.Vitals.State{hp, xp, dead, respawn, attack, spin}: {==}

law Inventory.accept_hero:
  for +accepted: Bool
  for +op: G.Bq.HOp
  for +player: P.Players.State
  for +amount: U32
  for +decision: {G.Bq.hop_ok(op, P.Players.hero(player)) == accepted : Bool}
  {P.Players.hero(Inventory.accept(accepted, op, player, amount)) == G.Bq.hero_step(op, P.Players.hero(player)) : G.Bq.Hero}

def Inventory.accept_hero(accepted, op, player, amount, decision):
  match accepted:
    case False{}: Equal.sym(G.Bq.Hero, G.Bq.hero_step(op, P.Players.hero(player)), P.Players.hero(player), G.Bq.rejected_op_is_noop(op, P.Players.hero(player), decision))
    case True{}: Inventory.commit_hero(player, G.Bq.hero_step(op, P.Players.hero(player)), Inventory.potion(op), amount)

law Inventory.step_hero:
  for +op: G.Bq.HOp
  for +player: P.Players.State
  for +near_shop: Bool
  for +amount: U32
  for +alive: {V.Vitals.dead(P.Players.vitals(player)) == 0 : U32}
  for +allowed: {Bool.or(Bool.not(Inventory.shop(op)), near_shop) == True{} : Bool}
  {P.Players.hero(Inventory.step(op, player, near_shop, amount)) == G.Bq.hero_step(op, P.Players.hero(player)) : G.Bq.Hero}

def Inventory.step_hero(op, player, near_shop, amount, alive, allowed):
  %Equal.sym(U32, V.Vitals.dead(P.Players.vitals(player)), 0, alive) : {P.Players.hero(Inventory.gate(U32.is_eq(_, 1), Bool.or(Bool.not(Inventory.shop(op)), near_shop), op, player, amount)) == G.Bq.hero_step(op, P.Players.hero(player)) : G.Bq.Hero}
  %Equal.sym(Bool, Bool.or(Bool.not(Inventory.shop(op)), near_shop), True{}, allowed) : {P.Players.hero(Inventory.live(_, op, player, amount)) == G.Bq.hero_step(op, P.Players.hero(player)) : G.Bq.Hero}
  Inventory.accept_hero(G.Bq.hop_ok(op, P.Players.hero(player)), op, player, amount, {==})

law Inventory.step_stat_budget:
  for +op: G.Bq.HOp
  for +player: P.Players.State
  for +near_shop: Bool
  for +amount: U32
  for +alive: {V.Vitals.dead(P.Players.vitals(player)) == 0 : U32}
  for +allowed: {Bool.or(Bool.not(Inventory.shop(op)), near_shop) == True{} : Bool}
  {G.Bq.stat_total(P.Players.hero(Inventory.step(op, player, near_shop, amount))) == G.Bq.stat_expect(op, P.Players.hero(player)) : Nat}

def Inventory.step_stat_budget(op, player, near_shop, amount, alive, allowed):
  %Equal.sym(G.Bq.Hero, P.Players.hero(Inventory.step(op, player, near_shop, amount)), G.Bq.hero_step(op, P.Players.hero(player)), Inventory.step_hero(op, player, near_shop, amount, alive, allowed)) : {G.Bq.stat_total(_) == G.Bq.stat_expect(op, P.Players.hero(player)) : Nat}
  G.Bq.ops_respect_stat_budget(op, P.Players.hero(player))

law Inventory.equip_census:
  for +kind: Nat
  for +player: P.Players.State
  for +amount: U32
  for +alive: {V.Vitals.dead(P.Players.vitals(player)) == 0 : U32}
  {G.Bq.census(P.Players.hero(Inventory.step(G.Bq.HOp.Equip{kind}, player, True{}, amount))) == G.Bq.census(P.Players.hero(player)) : G.Bq.Bag}

def Inventory.equip_census(kind, player, amount, alive):
  %Equal.sym(G.Bq.Hero, P.Players.hero(Inventory.step(G.Bq.HOp.Equip{kind}, player, True{}, amount)), G.Bq.hero_step(G.Bq.HOp.Equip{kind}, P.Players.hero(player)), Inventory.step_hero(G.Bq.HOp.Equip{kind}, player, True{}, amount, alive, {==})) : {G.Bq.census(_) == G.Bq.census(P.Players.hero(player)) : G.Bq.Bag}
  G.Bq.equip_preserves_census(kind, P.Players.hero(player))

law Inventory.unequip_census:
  for +slot: G.Bq.ISlot
  for +player: P.Players.State
  for +amount: U32
  for +alive: {V.Vitals.dead(P.Players.vitals(player)) == 0 : U32}
  {G.Bq.census(P.Players.hero(Inventory.step(G.Bq.HOp.Unequip{slot}, player, True{}, amount))) == G.Bq.census(P.Players.hero(player)) : G.Bq.Bag}

def Inventory.unequip_census(slot, player, amount, alive):
  %Equal.sym(G.Bq.Hero, P.Players.hero(Inventory.step(G.Bq.HOp.Unequip{slot}, player, True{}, amount)), G.Bq.hero_step(G.Bq.HOp.Unequip{slot}, P.Players.hero(player)), Inventory.step_hero(G.Bq.HOp.Unequip{slot}, player, True{}, amount, alive, {==})) : {G.Bq.census(_) == G.Bq.census(P.Players.hero(player)) : G.Bq.Bag}
  G.Bq.unequip_preserves_census(slot, P.Players.hero(player))

law Inventory.buy_mints_one:
  for +kind: Nat
  for +player: P.Players.State
  for +amount: U32
  for +alive: {V.Vitals.dead(P.Players.vitals(player)) == 0 : U32}
  for +accepted: {G.Bq.buy_ok(kind, P.Players.hero(player)) == True{} : Bool}
  {G.Bq.census(P.Players.hero(Inventory.step(G.Bq.HOp.Buy{kind}, player, True{}, amount))) == G.Bq.Bag.add(G.Bq.one(kind), G.Bq.census(P.Players.hero(player))) : G.Bq.Bag}

def Inventory.buy_mints_one(kind, player, amount, alive, accepted):
  %Equal.sym(G.Bq.Hero, P.Players.hero(Inventory.step(G.Bq.HOp.Buy{kind}, player, True{}, amount)), G.Bq.hero_step(G.Bq.HOp.Buy{kind}, P.Players.hero(player)), Inventory.step_hero(G.Bq.HOp.Buy{kind}, player, True{}, amount, alive, {==})) : {G.Bq.census(_) == G.Bq.Bag.add(G.Bq.one(kind), G.Bq.census(P.Players.hero(player))) : G.Bq.Bag}
  G.Bq.buy_mints_exactly_one(kind, P.Players.hero(player), accepted)

law Inventory.buy_exact_gold:
  for +kind: Nat
  for +player: P.Players.State
  for +amount: U32
  for +alive: {V.Vitals.dead(P.Players.vitals(player)) == 0 : U32}
  for +accepted: {G.Bq.buy_ok(kind, P.Players.hero(player)) == True{} : Bool}
  {G.Bq.Nat.add(G.Bq.iprice(kind), G.Bq.hero_gold(P.Players.hero(Inventory.step(G.Bq.HOp.Buy{kind}, player, True{}, amount)))) == G.Bq.hero_gold(P.Players.hero(player)) : Nat}

def Inventory.buy_exact_gold(kind, player, amount, alive, accepted):
  %Equal.sym(G.Bq.Hero, P.Players.hero(Inventory.step(G.Bq.HOp.Buy{kind}, player, True{}, amount)), G.Bq.hero_step(G.Bq.HOp.Buy{kind}, P.Players.hero(player)), Inventory.step_hero(G.Bq.HOp.Buy{kind}, player, True{}, amount, alive, {==})) : {G.Bq.Nat.add(G.Bq.iprice(kind), G.Bq.hero_gold(_)) == G.Bq.hero_gold(P.Players.hero(player)) : Nat}
  G.Bq.buy_burns_exact_gold(kind, P.Players.hero(player), accepted)

law Inventory.quaff_consumes_one:
  for +player: P.Players.State
  for +amount: U32
  for +alive: {V.Vitals.dead(P.Players.vitals(player)) == 0 : U32}
  for +accepted: {G.Bq.quaff_ok(P.Players.hero(player)) == True{} : Bool}
  {G.Bq.Bag.add(G.Bq.one(G.Bq.POTION), G.Bq.census(P.Players.hero(Inventory.step(G.Bq.HOp.Quaff{}, player, True{}, amount)))) == G.Bq.census(P.Players.hero(player)) : G.Bq.Bag}

def Inventory.quaff_consumes_one(player, amount, alive, accepted):
  %Equal.sym(G.Bq.Hero, P.Players.hero(Inventory.step(G.Bq.HOp.Quaff{}, player, True{}, amount)), G.Bq.hero_step(G.Bq.HOp.Quaff{}, P.Players.hero(player)), Inventory.step_hero(G.Bq.HOp.Quaff{}, player, True{}, amount, alive, {==})) : {G.Bq.Bag.add(G.Bq.one(G.Bq.POTION), G.Bq.census(_)) == G.Bq.census(P.Players.hero(player)) : G.Bq.Bag}
  G.Bq.quaff_burns_one_potion(P.Players.hero(player), accepted)

law Inventory.commit_hp:
  for +player: P.Players.State
  for +hero: G.Bq.Hero
  for +healing: Bool
  for +amount: U32
  {V.Vitals.hp(P.Players.vitals(Inventory.commit(player, hero, healing, amount))) == Inventory.health(healing, V.Vitals.hp(P.Players.vitals(player)), amount, R.Rewards.maximum(hero, 4294967295)) : U32}

def Inventory.commit_hp(player, hero, healing, amount):
  match player:
    case P.Players.State{pid, cid, old, pos, vitals, style, quest, meta}:
      match vitals:
        case V.Vitals.State{hp, xp, dead, respawn, attack, spin}: {==}

law Inventory.quaff_heals:
  for +player: P.Players.State
  for +near_shop: Bool
  for +amount: U32
  for +alive: {V.Vitals.dead(P.Players.vitals(player)) == 0 : U32}
  for +accepted: {G.Bq.hop_ok(G.Bq.HOp.Quaff{}, P.Players.hero(player)) == True{} : Bool}
  {V.Vitals.hp(P.Players.vitals(Inventory.step(G.Bq.HOp.Quaff{}, player, near_shop, amount))) == H.Health.heal_word(V.Vitals.hp(P.Players.vitals(player)), amount, R.Rewards.maximum(G.Bq.hero_step(G.Bq.HOp.Quaff{}, P.Players.hero(player)), 4294967295)) : U32}

def Inventory.quaff_heals(player, near_shop, amount, alive, accepted):
  %Equal.sym(P.Players.State, Inventory.step(G.Bq.HOp.Quaff{}, player, near_shop, amount), Inventory.commit(player, G.Bq.hero_step(G.Bq.HOp.Quaff{}, P.Players.hero(player)), True{}, amount), Inventory.quaff_accepted(player, near_shop, amount, alive, accepted)) : {V.Vitals.hp(P.Players.vitals(_)) == H.Health.heal_word(V.Vitals.hp(P.Players.vitals(player)), amount, R.Rewards.maximum(G.Bq.hero_step(G.Bq.HOp.Quaff{}, P.Players.hero(player)), 4294967295)) : U32}
  Inventory.commit_hp(player, G.Bq.hero_step(G.Bq.HOp.Quaff{}, P.Players.hero(player)), True{}, amount)

law Inventory.trace_count:
  for +commands: List<&2, Inventory.Command>
  for +players: List<&2, P.Players.State>
  for +amount: U32
  {P.Players.length(Inventory.trace(commands, players, amount)) == P.Players.length(players) : Nat}

def Inventory.trace_count(commands, players, amount):
  match commands:
    case Nil{}: {==}
    case Con{head, rest}:
      match head:
        case Inventory.Command{target, op, near_shop}:
          Equal.trans(Nat, P.Players.length(Inventory.trace(rest, Inventory.roster(Inventory.run(players, target, op, near_shop, amount)), amount)), P.Players.length(Inventory.roster(Inventory.run(players, target, op, near_shop, amount))), P.Players.length(players), Inventory.trace_count(rest, Inventory.roster(Inventory.run(players, target, op, near_shop, amount)), amount), Inventory.run_count(players, target, op, near_shop, amount))
