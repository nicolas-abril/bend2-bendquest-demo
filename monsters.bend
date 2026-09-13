# Monster state used by the server, with checked damage/death transitions.
import Base
import ./game.bend as G
import ./health.bend as H
import ./vitals.bend as V

type Monsters.State is Data:
  Monsters.State{mid: U32, kind: U32, rare: U32, zone: U32, x: U32, y: U32, hp: U32, maximum: U32, target: U32, attack: U32, dead: U32, respawn: U32}

def Monsters.vitals(monster: Monsters.State) -> V.Vitals.State:
  match monster:
    case Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      V.Vitals.State{hp, 0, dead, respawn, attack, 0}

def Monsters.maximum(monster: Monsters.State) -> U32:
  match monster:
    case Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      maximum

def Monsters.OK(+monster: Monsters.State) -> Data:
  V.Vitals.OK<Monsters.vitals(monster), Monsters.maximum(monster)>

type Monsters.Hit is Data:
  Monsters.Hit{monster: Monsters.State, killed: Bool, dealt: U32}

def Monsters.result(hit: Monsters.Hit) -> Monsters.State:
  match hit:
    case Monsters.Hit{monster, killed, dealt}:
      monster

def Monsters.choose(flag: Bool, yes: U32, no: U32) -> U32:
  match flag:
    case True{}:
      yes
    case False{}:
      no

def Monsters.finish(monster: Monsters.State, +hit: V.Vitals.Hit, damage: U32) -> Monsters.Hit:
  match monster:
    case Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      match hit:
        case V.Vitals.Hit{next, fell}:
          match next:
            case V.Vitals.State{hp2, xp2, dead2, respawn2, attack2, spin2}:
              Monsters.Hit{Monsters.State{mid, kind, rare, zone, x, y, hp2, maximum, Monsters.choose(fell, 0, target), Monsters.choose(fell, 0, attack2), dead2, respawn2}, fell, Monsters.choose(fell, hp, damage)}

def Monsters.hit_gate(is_dead: Bool, +monster: Monsters.State, +damage: U32, timer: U32) -> Monsters.Hit:
  match is_dead:
    case True{}:
      Monsters.Hit{monster, False{}, 0}
    case False{}:
      Monsters.finish(monster, V.Vitals.hit_gate(False{}, Monsters.vitals(monster), damage, timer), damage)

def Monsters.hit(+monster: Monsters.State, damage: U32, timer: U32) -> Monsters.Hit:
  Monsters.hit_gate(U32.is_eq(V.Vitals.dead(Monsters.vitals(monster)), 1), monster, damage, timer)

law Monsters.finish_ok:
  for +monster: Monsters.State
  for +hit: V.Vitals.Hit
  for +damage: U32
  for +valid: V.Vitals.OK<V.Vitals.hit_state(hit), Monsters.maximum(monster)>
  Monsters.OK(Monsters.result(Monsters.finish(monster, hit, damage)))

def Monsters.finish_ok(monster, hit, damage, valid):
  match monster:
    case Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      match hit:
        case V.Vitals.Hit{next, fell}:
          match next:
            case V.Vitals.State{hp2, xp2, dead2, respawn2, attack2, spin2}:
              match valid:
                case V.Vitals.OK{bound, life}:
                  V.Vitals.OK{bound, life}

law Monsters.hit_gate_ok:
  for +is_dead: Bool
  for +monster: Monsters.State
  for +damage: U32
  for +timer: U32
  for +valid: Monsters.OK(monster)
  Monsters.OK(Monsters.result(Monsters.hit_gate(is_dead, monster, damage, timer)))

def Monsters.hit_gate_ok(is_dead, monster, damage, timer, valid):
  match is_dead:
    case True{}:
      valid
    case False{}:
      Monsters.finish_ok(monster, V.Vitals.hit_gate(False{}, Monsters.vitals(monster), damage, timer), damage, V.Vitals.hit_gate_ok(False{}, Monsters.vitals(monster), damage, timer, Monsters.maximum(monster), valid))

law Monsters.hit_ok:
  for +monster: Monsters.State
  for +damage: U32
  for +timer: U32
  for +valid: Monsters.OK(monster)
  Monsters.OK(Monsters.result(Monsters.hit(monster, damage, timer)))

def Monsters.hit_ok(monster, damage, timer, valid):
  Monsters.hit_gate_ok(U32.is_eq(V.Vitals.dead(Monsters.vitals(monster)), 1), monster, damage, timer, valid)

law Monsters.dead_hit_noop:
  for +monster: Monsters.State
  for +damage: U32
  for +timer: U32
  for +dead: {V.Vitals.dead(Monsters.vitals(monster)) == 1 : U32}
  {Monsters.hit(monster, damage, timer) == Monsters.Hit{monster, False{}, 0} : Monsters.Hit}

def Monsters.dead_hit_noop(monster, damage, timer, dead):
  %Equal.sym(U32, V.Vitals.dead(Monsters.vitals(monster)), 1, dead) : {Monsters.hit_gate(U32.is_eq(_, 1), monster, damage, timer) == Monsters.Hit{monster, False{}, 0} : Monsters.Hit}
  {==}

def Monsters.killed(hit: Monsters.Hit) -> Bool:
  match hit:
    case Monsters.Hit{monster, killed, dealt}:
      killed

law Monsters.finish_killed:
  for +monster: Monsters.State
  for +hit: V.Vitals.Hit
  for +damage: U32
  {Monsters.killed(Monsters.finish(monster, hit, damage)) == V.Vitals.fell(hit) : Bool}

def Monsters.finish_killed(monster, hit, damage):
  match monster:
    case Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      match hit:
        case V.Vitals.Hit{next, fell}:
          match next:
            case V.Vitals.State{hp2, xp2, dead2, respawn2, attack2, spin2}:
              {==}

law Monsters.finish_dead:
  for +monster: Monsters.State
  for +hit: V.Vitals.Hit
  for +damage: U32
  {V.Vitals.dead(Monsters.vitals(Monsters.result(Monsters.finish(monster, hit, damage)))) == V.Vitals.dead(V.Vitals.hit_state(hit)) : U32}

def Monsters.finish_dead(monster, hit, damage):
  match monster:
    case Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      match hit:
        case V.Vitals.Hit{next, fell}:
          match next:
            case V.Vitals.State{hp2, xp2, dead2, respawn2, attack2, spin2}:
              {==}

law Monsters.hit_gate_killed_dead:
  for +is_dead: Bool
  for +monster: Monsters.State
  for +damage: U32
  for +timer: U32
  for +killed: {Monsters.killed(Monsters.hit_gate(is_dead, monster, damage, timer)) == True{} : Bool}
  {V.Vitals.dead(Monsters.vitals(Monsters.result(Monsters.hit_gate(is_dead, monster, damage, timer)))) == 1 : U32}

def Monsters.hit_gate_killed_dead(is_dead, monster, damage, timer, killed):
  match is_dead:
    case True{}:
      Empty.absurd({V.Vitals.dead(Monsters.vitals(monster)) == 1 : U32}, G.Bq.Bool.false_ne_true(killed))
    case False{}:
      %Equal.sym(U32, V.Vitals.dead(Monsters.vitals(Monsters.result(Monsters.finish(monster, V.Vitals.hit_gate(False{}, Monsters.vitals(monster), damage, timer), damage)))), V.Vitals.dead(V.Vitals.hit_state(V.Vitals.hit_gate(False{}, Monsters.vitals(monster), damage, timer))), Monsters.finish_dead(monster, V.Vitals.hit_gate(False{}, Monsters.vitals(monster), damage, timer), damage)) : {_ == 1 : U32}
      V.Vitals.hit_gate_fell_dead(False{}, Monsters.vitals(monster), damage, timer,
        (%Monsters.finish_killed(monster, V.Vitals.hit_gate(False{}, Monsters.vitals(monster), damage, timer), damage) : {_ == True{} : Bool}; killed))

law Monsters.hit_killed_dead:
  for +monster: Monsters.State
  for +damage: U32
  for +timer: U32
  for +killed: {Monsters.killed(Monsters.hit(monster, damage, timer)) == True{} : Bool}
  {V.Vitals.dead(Monsters.vitals(Monsters.result(Monsters.hit(monster, damage, timer)))) == 1 : U32}

def Monsters.hit_killed_dead(monster, damage, timer, killed):
  Monsters.hit_gate_killed_dead(U32.is_eq(V.Vitals.dead(Monsters.vitals(monster)), 1), monster, damage, timer, killed)

law Monsters.kill_cannot_repeat:
  for +monster: Monsters.State
  for +first_damage: U32
  for +second_damage: U32
  for +first_timer: U32
  for +second_timer: U32
  for +killed: {Monsters.killed(Monsters.hit(monster, first_damage, first_timer)) == True{} : Bool}
  {Monsters.hit(Monsters.result(Monsters.hit(monster, first_damage, first_timer)), second_damage, second_timer) == Monsters.Hit{Monsters.result(Monsters.hit(monster, first_damage, first_timer)), False{}, 0} : Monsters.Hit}

def Monsters.kill_cannot_repeat(monster, first_damage, second_damage, first_timer, second_timer, killed):
  Monsters.dead_hit_noop(Monsters.result(Monsters.hit(monster, first_damage, first_timer)), second_damage, second_timer, Monsters.hit_killed_dead(monster, first_damage, first_timer, killed))

law Monsters.lethal_hit_reports_kill:
  for +monster: Monsters.State
  for +damage: U32
  for +timer: U32
  for +alive: {V.Vitals.dead(Monsters.vitals(monster)) == 0 : U32}
  for +lethal: {G.Bq.Nat.le(U32.to_nat(V.Vitals.hp(Monsters.vitals(monster))), U32.to_nat(damage)) == True{} : Bool}
  {Monsters.killed(Monsters.hit(monster, damage, timer)) == True{} : Bool}

def Monsters.lethal_hit_reports_kill(monster, damage, timer, alive, lethal):
  %Equal.sym(U32, V.Vitals.dead(Monsters.vitals(monster)), 0, alive) : {Monsters.killed(Monsters.hit_gate(U32.is_eq(_, 1), monster, damage, timer)) == True{} : Bool}
  %Equal.sym(Bool, Monsters.killed(Monsters.finish(monster, V.Vitals.hit_gate(False{}, Monsters.vitals(monster), damage, timer), damage)), V.Vitals.fell(V.Vitals.hit_gate(False{}, Monsters.vitals(monster), damage, timer)), Monsters.finish_killed(monster, V.Vitals.hit_gate(False{}, Monsters.vitals(monster), damage, timer), damage)) : {_ == True{} : Bool}
  V.Vitals.lethal_hit_reports_death(Monsters.vitals(monster), damage, timer, lethal)

def Monsters.kind(monster: Monsters.State) -> U32:
  match monster:
    case Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      kind

# A zero maximum is invalid; initialization normalizes it to one.
def Monsters.spawn_positive(value: Nat, mid: U32, kind: U32, rare: U32, zone: U32, x: U32, y: U32, +maximum: U32) -> Monsters.State:
  match value:
    case Zero{}:
      Monsters.State{mid, kind, rare, zone, x, y, 1, 1, 0, 0, 0, 0}
    case Succ{rest}:
      Monsters.State{mid, kind, rare, zone, x, y, maximum, maximum, 0, 0, 0, 0}

def Monsters.spawn(mid: U32, kind: U32, rare: U32, zone: U32, x: U32, y: U32, +maximum: U32) -> Monsters.State:
  Monsters.spawn_positive(U32.to_nat(maximum), mid, kind, rare, zone, x, y, maximum)

law Monsters.spawn_positive_ok:
  for +value: Nat
  for +mid: U32
  for +kind: U32
  for +rare: U32
  for +zone: U32
  for +x: U32
  for +y: U32
  for +maximum: U32
  for +exact: {U32.to_nat(maximum) == value : Nat}
  Monsters.OK(Monsters.spawn_positive(value, mid, kind, rare, zone, x, y, maximum))

def Monsters.spawn_positive_ok(value, mid, kind, rare, zone, x, y, maximum, exact):
  match value:
    case Zero{}:
      V.Vitals.OK{{==}, V.Vitals.Alive{{==}, {==}}}
    case Succ{rest}:
      V.Vitals.OK{H.Health.le_refl(U32.to_nat(maximum)), V.Vitals.Alive{{==}, (%Equal.sym(Nat, U32.to_nat(maximum), Succ{rest}, exact) : {G.Bq.Nat.le(1n, _) == True{} : Bool}; {==})}}

law Monsters.spawn_ok:
  for +mid: U32
  for +kind: U32
  for +rare: U32
  for +zone: U32
  for +x: U32
  for +y: U32
  for +maximum: U32
  Monsters.OK(Monsters.spawn(mid, kind, rare, zone, x, y, maximum))

def Monsters.spawn_ok(mid, kind, rare, zone, x, y, maximum):
  Monsters.spawn_positive_ok(U32.to_nat(maximum), mid, kind, rare, zone, x, y, maximum, {==})

def Monsters.wait(monster: Monsters.State) -> Monsters.State:
  match monster:
    case Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, V.Vitals.dec(respawn)}

law Monsters.wait_ok:
  for +monster: Monsters.State
  for +valid: Monsters.OK(monster)
  Monsters.OK(Monsters.wait(monster))

def Monsters.wait_ok(monster, valid):
  match monster:
    case Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      match valid:
        case V.Vitals.OK{bound, life}:
          V.Vitals.OK{bound, life}

def Monsters.with_vitals(monster: Monsters.State, vitals: V.Vitals.State) -> Monsters.State:
  match monster:
    case Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      match vitals:
        case V.Vitals.State{hp2, xp2, dead2, respawn2, attack2, spin2}:
          Monsters.State{mid, kind, rare, zone, x, y, hp2, maximum, target, attack2, dead2, respawn2}

def Monsters.active(+monster: Monsters.State, amount: U32) -> Monsters.State:
  Monsters.with_vitals(monster, V.Vitals.live_tick(Monsters.vitals(monster), amount, Monsters.maximum(monster)))

law Monsters.with_vitals_ok:
  for +monster: Monsters.State
  for +vitals: V.Vitals.State
  for +valid: V.Vitals.OK<vitals, Monsters.maximum(monster)>
  Monsters.OK(Monsters.with_vitals(monster, vitals))

def Monsters.with_vitals_ok(monster, vitals, valid):
  match monster:
    case Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      match vitals:
        case V.Vitals.State{hp2, xp2, dead2, respawn2, attack2, spin2}:
          match valid:
            case V.Vitals.OK{bound, life}:
              V.Vitals.OK{bound, life}

law Monsters.active_ok:
  for +monster: Monsters.State
  for +amount: U32
  for +bound: {G.Bq.Nat.le(U32.to_nat(V.Vitals.hp(Monsters.vitals(monster))), U32.to_nat(Monsters.maximum(monster))) == True{} : Bool}
  for +positive: {G.Bq.Nat.le(1n, U32.to_nat(V.Vitals.hp(Monsters.vitals(monster)))) == True{} : Bool}
  Monsters.OK(Monsters.active(monster, amount))

def Monsters.active_ok(monster, amount, bound, positive):
  Monsters.with_vitals_ok(monster, V.Vitals.live_tick(Monsters.vitals(monster), amount, Monsters.maximum(monster)), V.Vitals.live_tick_ok(Monsters.vitals(monster), amount, Monsters.maximum(monster), bound, positive))

type Monsters.Phase is Data:
  Monsters.Active{}
  Monsters.Dormant{}
  Monsters.Rebirth{}

type Monsters.Tick is Data:
  Monsters.Tick{monster: Monsters.State, phase: Monsters.Phase}

def Monsters.tick_state(tick: Monsters.Tick) -> Monsters.State:
  match tick:
    case Monsters.Tick{monster, phase}:
      monster

def Monsters.ready_tick(ready: Bool, monster: Monsters.State) -> Monsters.Tick:
  match ready:
    case True{}:
      Monsters.Tick{monster, Monsters.Rebirth{}}
    case False{}:
      Monsters.Tick{Monsters.wait(monster), Monsters.Dormant{}}

def Monsters.dead_tick(permanent: Bool, ready: Bool, monster: Monsters.State) -> Monsters.Tick:
  match permanent:
    case True{}:
      Monsters.Tick{monster, Monsters.Dormant{}}
    case False{}:
      Monsters.ready_tick(ready, monster)

def Monsters.tick_gate(is_dead: Bool, permanent: Bool, ready: Bool, monster: Monsters.State, amount: U32) -> Monsters.Tick:
  match is_dead:
    case True{}:
      Monsters.dead_tick(permanent, ready, monster)
    case False{}:
      Monsters.Tick{Monsters.active(monster, amount), Monsters.Active{}}

def Monsters.tick(+monster: Monsters.State) -> Monsters.Tick:
  match monster:
    case Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      Monsters.tick_gate(U32.is_eq(dead, 1), U32.is_eq(respawn, 4294967295), U32.is_le(respawn, 1), Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}, Monsters.choose(U32.is_eq(kind, 9), 30, 0))

law Monsters.ready_tick_ok:
  for +ready: Bool
  for +monster: Monsters.State
  for +valid: Monsters.OK(monster)
  Monsters.OK(Monsters.tick_state(Monsters.ready_tick(ready, monster)))

def Monsters.ready_tick_ok(ready, monster, valid):
  match ready:
    case True{}:
      valid
    case False{}:
      Monsters.wait_ok(monster, valid)

law Monsters.dead_tick_ok:
  for +permanent: Bool
  for +ready: Bool
  for +monster: Monsters.State
  for +valid: Monsters.OK(monster)
  Monsters.OK(Monsters.tick_state(Monsters.dead_tick(permanent, ready, monster)))

def Monsters.dead_tick_ok(permanent, ready, monster, valid):
  match permanent:
    case True{}:
      valid
    case False{}:
      Monsters.ready_tick_ok(ready, monster, valid)

law Monsters.tick_ok:
  for +monster: Monsters.State
  for +valid: Monsters.OK(monster)
  Monsters.OK(Monsters.tick_state(Monsters.tick(monster)))

def Monsters.tick_ok(monster, valid):
  match monster:
    case Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      match valid:
        case V.Vitals.OK{bound, life}:
          match life:
            case V.Vitals.Alive{flag, positive}:
              %Equal.sym(U32, dead, 0, flag) : Monsters.OK(Monsters.tick_state(Monsters.tick(Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, _, respawn})))
              Monsters.active_ok(Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, 0, respawn}, Monsters.choose(U32.is_eq(kind, 9), 30, 0), bound, positive)
            case V.Vitals.Dead{flag, zero}:
              %Equal.sym(U32, dead, 1, flag) : Monsters.OK(Monsters.tick_state(Monsters.tick(Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, _, respawn})))
              Monsters.dead_tick_ok(U32.is_eq(respawn, 4294967295), U32.is_le(respawn, 1), Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, 1, respawn}, V.Vitals.OK{bound, V.Vitals.Dead{{==}, zero}})

def Monsters.aim(monster: Monsters.State, nx: U32, ny: U32, ntarget: U32, nattack: U32) -> Monsters.State:
  match monster:
    case Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      Monsters.State{mid, kind, rare, zone, nx, ny, hp, maximum, ntarget, nattack, dead, respawn}

law Monsters.aim_ok:
  for +monster: Monsters.State
  for +x: U32
  for +y: U32
  for +target: U32
  for +attack: U32
  for +valid: Monsters.OK(monster)
  Monsters.OK(Monsters.aim(monster, x, y, target, attack))

def Monsters.aim_ok(monster, x, y, target, attack, valid):
  match monster:
    case Monsters.State{mid, kind, rare, zone, ox, oy, hp, maximum, otarget, oattack, dead, respawn}:
      match valid:
        case V.Vitals.OK{bound, life}:
          V.Vitals.OK{bound, life}

def Monsters.timer(monster: Monsters.State) -> U32:
  match monster:
    case Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      respawn

law Monsters.permanent_death_stays:
  for +monster: Monsters.State
  for +dead: {V.Vitals.dead(Monsters.vitals(monster)) == 1 : U32}
  for +permanent: {Monsters.timer(monster) == 4294967295 : U32}
  {Monsters.tick(monster) == Monsters.Tick{monster, Monsters.Dormant{}} : Monsters.Tick}

def Monsters.permanent_death_stays(monster, dead, permanent):
  match monster:
    case Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, flag, respawn}:
      %Equal.sym(U32, flag, 1, dead) : {Monsters.tick(Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, _, respawn}) == Monsters.Tick{Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, _, respawn}, Monsters.Dormant{}} : Monsters.Tick}
      %Equal.sym(U32, respawn, 4294967295, permanent) : {Monsters.tick(Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, 1, _}) == Monsters.Tick{Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, 1, _}, Monsters.Dormant{}} : Monsters.Tick}
      {==}

# The trace folds the exact server hit transition, with no intervening respawn.
def Monsters.add_event(killed: Bool, count: Nat) -> Nat:
  match killed:
    case False{}:
      count
    case True{}:
      Succ{count}

def Monsters.kill_count(damages: List<&2, U32>, +monster: Monsters.State, +timer: U32) -> Nat:
  match damages:
    case Nil{}:
      0n
    case Con{damage, rest}:
      +hit = Monsters.hit(monster, damage, timer)
      Monsters.add_event(Monsters.killed(hit), Monsters.kill_count(rest, Monsters.result(hit), timer))

law Monsters.dead_trace_no_kills:
  for +damages: List<&2, U32>
  for +monster: Monsters.State
  for +timer: U32
  for +dead: {V.Vitals.dead(Monsters.vitals(monster)) == 1 : U32}
  {Monsters.kill_count(damages, monster, timer) == 0n : Nat}

def Monsters.dead_trace_no_kills(damages, monster, timer, dead):
  match damages:
    case Nil{}:
      {==}
    case Con{damage, rest}:
      %Equal.sym(Monsters.Hit, Monsters.hit(monster, damage, timer), Monsters.Hit{monster, False{}, 0}, Monsters.dead_hit_noop(monster, damage, timer, dead)) : {Monsters.add_event(Monsters.killed(_), Monsters.kill_count(rest, Monsters.result(_), timer)) == 0n : Nat}
      Monsters.dead_trace_no_kills(rest, monster, timer, dead)

law Monsters.add_event_bounded:
  for +killed: Bool
  for +count: Nat
  for +bound: {G.Bq.Nat.le(count, 1n) == True{} : Bool}
  for zero: (@+event: {killed == True{} : Bool} -> {count == 0n : Nat})
  {G.Bq.Nat.le(Monsters.add_event(killed, count), 1n) == True{} : Bool}

def Monsters.add_event_bounded(killed, count, bound, zero):
  match killed:
    case False{}:
      bound
    case True{}:
      %Equal.sym(Nat, count, 0n, zero({==})) : {G.Bq.Nat.le(Succ{_}, 1n) == True{} : Bool}
      {==}

law Monsters.trace_at_most_one_kill:
  for +damages: List<&2, U32>
  for +monster: Monsters.State
  for +timer: U32
  {G.Bq.Nat.le(Monsters.kill_count(damages, monster, timer), 1n) == True{} : Bool}

def Monsters.trace_at_most_one_kill(damages, monster, timer):
  match damages:
    case Nil{}:
      {==}
    case Con{damage, rest}:
      Monsters.add_event_bounded(Monsters.killed(Monsters.hit(monster, damage, timer)), Monsters.kill_count(rest, Monsters.result(Monsters.hit(monster, damage, timer)), timer), Monsters.trace_at_most_one_kill(rest, Monsters.result(Monsters.hit(monster, damage, timer)), timer), (event => Monsters.dead_trace_no_kills(rest, Monsters.result(Monsters.hit(monster, damage, timer)), timer, Monsters.hit_killed_dead(monster, damage, timer, event))))

law Monsters.lethal_trace_exactly_one:
  for +damage: U32
  for +rest: List<&2, U32>
  for +monster: Monsters.State
  for +timer: U32
  for +alive: {V.Vitals.dead(Monsters.vitals(monster)) == 0 : U32}
  for +lethal: {G.Bq.Nat.le(U32.to_nat(V.Vitals.hp(Monsters.vitals(monster))), U32.to_nat(damage)) == True{} : Bool}
  {Monsters.kill_count(Con{damage, rest}, monster, timer) == 1n : Nat}

def Monsters.lethal_trace_exactly_one(damage, rest, monster, timer, alive, lethal):
  %Equal.sym(Nat, Monsters.kill_count(rest, Monsters.result(Monsters.hit(monster, damage, timer)), timer), 0n, Monsters.dead_trace_no_kills(rest, Monsters.result(Monsters.hit(monster, damage, timer)), timer, Monsters.hit_killed_dead(monster, damage, timer, Monsters.lethal_hit_reports_kill(monster, damage, timer, alive, lethal)))) : {Monsters.add_event(Monsters.killed(Monsters.hit(monster, damage, timer)), _) == 1n : Nat}
  %Equal.sym(Bool, Monsters.killed(Monsters.hit(monster, damage, timer)), True{}, Monsters.lethal_hit_reports_kill(monster, damage, timer, alive, lethal)) : {Monsters.add_event(_, 0n) == 1n : Nat}
  {==}
