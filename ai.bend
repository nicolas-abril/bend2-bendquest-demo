# Checked monster AI state updates. Planning supplies movement/target choices;
# these transitions own health, lifecycle, and attack cooldown changes.
import Base
import ./monsters.bend as M
import ./roster.bend as R
import ./vitals.bend as V

type AI.Plan is Data:
  AI.Rest{}
  AI.Move{x: U32, y: U32, target: U32}
  AI.Attack{target: U32, damage: U32}
  AI.Spawn{kind: U32, rare: U32, x: U32, y: U32, maximum: U32}

type AI.Hit is Data:
  AI.Hit{target: U32, damage: U32}

type AI.Step is Data:
  AI.Step{monster: M.Monsters.State, hit: Maybe<&2, AI.Hit>}

def AI.monster(step: AI.Step) -> M.Monsters.State:
  match step:
    case AI.Step{monster, hit}:
      monster

def AI.attack(ready: Bool, +monster: M.Monsters.State, +target: U32, damage: U32) -> AI.Step:
  match ready:
    case False{}:
      AI.Step{monster, None{}}
    case True{}:
      match monster:
        case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, old_target, attack, dead, respawn}:
          AI.Step{M.Monsters.aim(M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, old_target, attack, dead, respawn}, x, y, target, 9), Some{AI.Hit{target, damage}}}

def AI.active(+monster: M.Monsters.State, plan: AI.Plan) -> AI.Step:
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      match plan:
        case AI.Rest{}:
          AI.Step{M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}, None{}}
        case AI.Move{nx, ny, next_target}:
          AI.Step{M.Monsters.aim(M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}, nx, ny, next_target, attack), None{}}
        case AI.Attack{next_target, damage}:
          AI.attack(U32.is_eq(attack, 0), M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}, next_target, damage)
        case AI.Spawn{new_kind, new_rare, nx, ny, new_maximum}:
          AI.Step{M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}, None{}}

def AI.rebirth(monster: M.Monsters.State, plan: AI.Plan) -> AI.Step:
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      match plan:
        case AI.Rest{}:
          AI.Step{M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}, None{}}
        case AI.Move{nx, ny, next_target}:
          AI.Step{M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}, None{}}
        case AI.Attack{next_target, damage}:
          AI.Step{M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}, None{}}
        case AI.Spawn{new_kind, new_rare, nx, ny, new_maximum}:
          AI.Step{M.Monsters.spawn(mid, new_kind, new_rare, zone, nx, ny, new_maximum), None{}}

def AI.commit(tick: M.Monsters.Tick, plan: AI.Plan) -> AI.Step:
  match tick:
    case M.Monsters.Tick{monster, phase}:
      match phase:
        case M.Monsters.Active{}:
          AI.active(monster, plan)
        case M.Monsters.Dormant{}:
          AI.Step{monster, None{}}
        case M.Monsters.Rebirth{}:
          AI.rebirth(monster, plan)

def AI.step(monster: M.Monsters.State, plan: AI.Plan) -> AI.Step:
  AI.commit(M.Monsters.tick(monster), plan)

law AI.attack_ok:
  for +ready: Bool
  for +monster: M.Monsters.State
  for +target: U32
  for +damage: U32
  for +valid: M.Monsters.OK(monster)
  M.Monsters.OK(AI.monster(AI.attack(ready, monster, target, damage)))

def AI.attack_ok(ready, monster, target, damage, valid):
  match ready:
    case False{}:
      valid
    case True{}:
      match monster:
        case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, old_target, attack, dead, respawn}:
          M.Monsters.aim_ok(M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, old_target, attack, dead, respawn}, x, y, target, 9, valid)

law AI.active_ok:
  for +monster: M.Monsters.State
  for +plan: AI.Plan
  for +valid: M.Monsters.OK(monster)
  M.Monsters.OK(AI.monster(AI.active(monster, plan)))

def AI.active_ok(monster, plan, valid):
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      match plan:
        case AI.Rest{}:
          valid
        case AI.Move{nx, ny, next_target}:
          M.Monsters.aim_ok(M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}, nx, ny, next_target, attack, valid)
        case AI.Attack{next_target, damage}:
          AI.attack_ok(U32.is_eq(attack, 0), M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}, next_target, damage, valid)
        case AI.Spawn{new_kind, new_rare, nx, ny, new_maximum}:
          valid

law AI.rebirth_ok:
  for +monster: M.Monsters.State
  for +plan: AI.Plan
  for +valid: M.Monsters.OK(monster)
  M.Monsters.OK(AI.monster(AI.rebirth(monster, plan)))

def AI.rebirth_ok(monster, plan, valid):
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      match plan:
        case AI.Rest{}:
          valid
        case AI.Move{nx, ny, next_target}:
          valid
        case AI.Attack{next_target, damage}:
          valid
        case AI.Spawn{new_kind, new_rare, nx, ny, new_maximum}:
          M.Monsters.spawn_ok(mid, new_kind, new_rare, zone, nx, ny, new_maximum)

law AI.commit_ok:
  for +tick: M.Monsters.Tick
  for +plan: AI.Plan
  for +valid: M.Monsters.OK(M.Monsters.tick_state(tick))
  M.Monsters.OK(AI.monster(AI.commit(tick, plan)))

def AI.commit_ok(tick, plan, valid):
  match tick:
    case M.Monsters.Tick{monster, phase}:
      match phase:
        case M.Monsters.Active{}:
          AI.active_ok(monster, plan, valid)
        case M.Monsters.Dormant{}:
          valid
        case M.Monsters.Rebirth{}:
          AI.rebirth_ok(monster, plan, valid)

law AI.step_ok:
  for +monster: M.Monsters.State
  for +plan: AI.Plan
  for +valid: M.Monsters.OK(monster)
  M.Monsters.OK(AI.monster(AI.step(monster, plan)))

def AI.step_ok(monster, plan, valid):
  AI.commit_ok(M.Monsters.tick(monster), plan, M.Monsters.tick_ok(monster, valid))

type AI.Result is Data:
  AI.Result{monsters: List<&2, M.Monsters.State>, hits: List<&2, AI.Hit>}

def AI.monsters(result: AI.Result) -> List<&2, M.Monsters.State>:
  match result:
    case AI.Result{monsters, hits}:
      monsters

def AI.add_hit(hit: Maybe<&2, AI.Hit>, hits: List<&2, AI.Hit>) -> List<&2, AI.Hit>:
  match hit:
    case None{}:
      hits
    case Some{hit}:
      Con{hit, hits}

def AI.prepend(step: AI.Step, result: AI.Result) -> AI.Result:
  match step:
    case AI.Step{monster, hit}:
      match result:
        case AI.Result{monsters, hits}:
          AI.Result{Con{monster, monsters}, AI.add_hit(hit, hits)}

# Missing plans mean no optional action; lifecycle upkeep still runs.
# Extra plans are ignored. Neither case can create or drop a monster.
def AI.run(monsters: List<&2, M.Monsters.State>, plans: List<&2, AI.Plan>) -> AI.Result:
  match monsters:
    case Nil{}:
      AI.Result{Nil{}, Nil{}}
    case Con{head, rest}:
      match plans:
        case Nil{}:
          AI.prepend(AI.step(head, AI.Rest{}), AI.run(rest, Nil{}))
        case Con{plan, later}:
          AI.prepend(AI.step(head, plan), AI.run(rest, later))

law AI.prepend_ok:
  for +step: AI.Step
  for +result: AI.Result
  for +head_ok: M.Monsters.OK(AI.monster(step))
  for +rest_ok: R.Roster.OK(AI.monsters(result))
  R.Roster.OK(AI.monsters(AI.prepend(step, result)))

def AI.prepend_ok(step, result, head_ok, rest_ok):
  match step:
    case AI.Step{monster, hit}:
      match result:
        case AI.Result{monsters, hits}:
          Tuple{head_ok, rest_ok}

law AI.run_ok:
  for +monsters: List<&2, M.Monsters.State>
  for +plans: List<&2, AI.Plan>
  for +valid: R.Roster.OK(monsters)
  R.Roster.OK(AI.monsters(AI.run(monsters, plans)))

def AI.run_ok(monsters, plans, valid):
  match monsters:
    case Nil{}:
      Unit{}
    case Con{head, rest}:
      match plans:
        case Nil{}:
          match valid:
            case Tuple{head_ok, rest_ok}:
              AI.prepend_ok(AI.step(head, AI.Rest{}), AI.run(rest, Nil{}), AI.step_ok(head, AI.Rest{}, head_ok), AI.run_ok(rest, Nil{}, rest_ok))
        case Con{plan, later}:
          match valid:
            case Tuple{head_ok, rest_ok}:
              AI.prepend_ok(AI.step(head, plan), AI.run(rest, later), AI.step_ok(head, plan, head_ok), AI.run_ok(rest, later, rest_ok))

def AI.concat_hits(left: List<&2, AI.Hit>, right: List<&2, AI.Hit>) -> List<&2, AI.Hit>:
  match left:
    case Nil{}:
      right
    case Con{hit, rest}:
      Con{hit, AI.concat_hits(rest, right)}

def AI.merge(left: AI.Result, right: AI.Result) -> AI.Result:
  match left:
    case AI.Result{lm, lh}:
      match right:
        case AI.Result{rm, rh}:
          AI.Result{R.Roster.concat(lm, rm), AI.concat_hits(lh, rh)}

law AI.merge_ok:
  for +left: AI.Result
  for +right: AI.Result
  for +left_ok: R.Roster.OK(AI.monsters(left))
  for +right_ok: R.Roster.OK(AI.monsters(right))
  R.Roster.OK(AI.monsters(AI.merge(left, right)))

def AI.merge_ok(left, right, left_ok, right_ok):
  match left:
    case AI.Result{lm, lh}:
      match right:
        case AI.Result{rm, rh}:
          R.Roster.concat_ok(lm, rm, left_ok, right_ok)

def AI.run_zones(+monsters: List<&2, M.Monsters.State>, p0: List<&2, AI.Plan>, p1: List<&2, AI.Plan>, p2: List<&2, AI.Plan>, p3: List<&2, AI.Plan>) -> AI.Result:
  r0 r1 r2 r3 = AI.run(R.Roster.zone(monsters, 0), p0) AI.run(R.Roster.zone(monsters, 1), p1) AI.run(R.Roster.zone(monsters, 2), p2) AI.run(R.Roster.zone(monsters, 3), p3)
  AI.merge(r0, AI.merge(r1, AI.merge(r2, r3)))

law AI.run_zones_ok:
  for +monsters: List<&2, M.Monsters.State>
  for +p0: List<&2, AI.Plan>
  for +p1: List<&2, AI.Plan>
  for +p2: List<&2, AI.Plan>
  for +p3: List<&2, AI.Plan>
  for +valid: R.Roster.OK(monsters)
  R.Roster.OK(AI.monsters(AI.run_zones(monsters, p0, p1, p2, p3)))

def AI.run_zones_ok(monsters, p0, p1, p2, p3, valid):
  AI.merge_ok(AI.run(R.Roster.zone(monsters, 0), p0), AI.merge(AI.run(R.Roster.zone(monsters, 1), p1), AI.merge(AI.run(R.Roster.zone(monsters, 2), p2), AI.run(R.Roster.zone(monsters, 3), p3))), AI.run_ok(R.Roster.zone(monsters, 0), p0, R.Roster.zone_ok(monsters, 0, valid)), AI.merge_ok(AI.run(R.Roster.zone(monsters, 1), p1), AI.merge(AI.run(R.Roster.zone(monsters, 2), p2), AI.run(R.Roster.zone(monsters, 3), p3)), AI.run_ok(R.Roster.zone(monsters, 1), p1, R.Roster.zone_ok(monsters, 1, valid)), AI.merge_ok(AI.run(R.Roster.zone(monsters, 2), p2), AI.run(R.Roster.zone(monsters, 3), p3), AI.run_ok(R.Roster.zone(monsters, 2), p2, R.Roster.zone_ok(monsters, 2, valid)), AI.run_ok(R.Roster.zone(monsters, 3), p3, R.Roster.zone_ok(monsters, 3, valid)))))

def AI.hit(step: AI.Step) -> Maybe<&2, AI.Hit>:
  match step:
    case AI.Step{monster, hit}:
      hit

law AI.rebirth_no_hit:
  for +monster: M.Monsters.State
  for +plan: AI.Plan
  {AI.hit(AI.rebirth(monster, plan)) == None{} : Maybe<&2, AI.Hit>}

def AI.rebirth_no_hit(monster, plan):
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      match plan:
        case AI.Rest{}:
          {==}
        case AI.Move{nx, ny, next_target}:
          {==}
        case AI.Attack{next_target, damage}:
          {==}
        case AI.Spawn{new_kind, new_rare, nx, ny, new_maximum}:
          {==}

law AI.dead_tick_no_hit:
  for +permanent: Bool
  for +ready: Bool
  for +monster: M.Monsters.State
  for +plan: AI.Plan
  {AI.hit(AI.commit(M.Monsters.dead_tick(permanent, ready, monster), plan)) == None{} : Maybe<&2, AI.Hit>}

def AI.dead_tick_no_hit(permanent, ready, monster, plan):
  match permanent:
    case True{}:
      {==}
    case False{}:
      match ready:
        case True{}:
          AI.rebirth_no_hit(monster, plan)
        case False{}:
          {==}

law AI.dead_step_no_hit:
  for +monster: M.Monsters.State
  for +plan: AI.Plan
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  {AI.hit(AI.step(monster, plan)) == None{} : Maybe<&2, AI.Hit>}

def AI.dead_step_no_hit(monster, plan, dead):
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, flag, respawn}:
      %Equal.sym(U32, flag, 1, dead) : {AI.hit(AI.step(M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, _, respawn}, plan)) == None{} : Maybe<&2, AI.Hit>}
      AI.dead_tick_no_hit(U32.is_eq(respawn, 4294967295), U32.is_le(respawn, 1), M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, 1, respawn}, plan)

law AI.permanent_stays:
  for +monster: M.Monsters.State
  for +plan: AI.Plan
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  for +permanent: {M.Monsters.timer(monster) == 4294967295 : U32}
  {AI.step(monster, plan) == AI.Step{monster, None{}} : AI.Step}

def AI.permanent_stays(monster, plan, dead, permanent):
  %Equal.sym(M.Monsters.Tick, M.Monsters.tick(monster), M.Monsters.Tick{monster, M.Monsters.Dormant{}}, M.Monsters.permanent_death_stays(monster, dead, permanent)) : {AI.commit(_, plan) == AI.Step{monster, None{}} : AI.Step}
  {==}

def AI.cooldown(monster: M.Monsters.State) -> U32:
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      attack

law AI.cooldown_blocks:
  for +monster: M.Monsters.State
  for +target: U32
  for +damage: U32
  for +blocked: {U32.is_eq(AI.cooldown(monster), 0) == False{} : Bool}
  {AI.active(monster, AI.Attack{target, damage}) == AI.Step{monster, None{}} : AI.Step}

def AI.cooldown_blocks(monster, target, damage, blocked):
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, old_target, attack, dead, respawn}:
      %Equal.sym(Bool, U32.is_eq(attack, 0), False{}, blocked) : {AI.attack(_, M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, old_target, attack, dead, respawn}, target, damage) == AI.Step{M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, old_target, attack, dead, respawn}, None{}} : AI.Step}
      {==}

law AI.attack_sets_cooldown:
  for +monster: M.Monsters.State
  for +target: U32
  for +damage: U32
  {AI.cooldown(AI.monster(AI.attack(True{}, monster, target, damage))) == 9 : U32}

def AI.attack_sets_cooldown(monster, target, damage):
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, old_target, attack, dead, respawn}:
      {==}

law AI.prepend_count:
  for +step: AI.Step
  for +result: AI.Result
  {R.Roster.length(AI.monsters(AI.prepend(step, result))) == Succ{R.Roster.length(AI.monsters(result))} : Nat}

def AI.prepend_count(step, result):
  match step:
    case AI.Step{monster, hit}:
      match result:
        case AI.Result{monsters, hits}:
          {==}

law AI.run_count:
  for +monsters: List<&2, M.Monsters.State>
  for +plans: List<&2, AI.Plan>
  {R.Roster.length(AI.monsters(AI.run(monsters, plans))) == R.Roster.length(monsters) : Nat}

def AI.run_count(monsters, plans):
  match monsters:
    case Nil{}:
      {==}
    case Con{head, rest}:
      match plans:
        case Nil{}:
          %Equal.sym(Nat, R.Roster.length(AI.monsters(AI.prepend(AI.step(head, AI.Rest{}), AI.run(rest, Nil{})))), Succ{R.Roster.length(AI.monsters(AI.run(rest, Nil{})))}, AI.prepend_count(AI.step(head, AI.Rest{}), AI.run(rest, Nil{}))) : {_ == Succ{R.Roster.length(rest)} : Nat}
          %AI.run_count(rest, Nil{}) : {Succ{R.Roster.length(AI.monsters(AI.run(rest, Nil{})))} == Succ{_} : Nat}
          {==}
        case Con{plan, later}:
          %Equal.sym(Nat, R.Roster.length(AI.monsters(AI.prepend(AI.step(head, plan), AI.run(rest, later)))), Succ{R.Roster.length(AI.monsters(AI.run(rest, later)))}, AI.prepend_count(AI.step(head, plan), AI.run(rest, later))) : {_ == Succ{R.Roster.length(rest)} : Nat}
          %AI.run_count(rest, later) : {Succ{R.Roster.length(AI.monsters(AI.run(rest, later)))} == Succ{_} : Nat}
          {==}
