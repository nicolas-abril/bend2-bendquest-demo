# The authoritative phase-gated tick, with planning between its two stages.
import Base
import ./players.bend as P
import ./monsters.bend as M
import ./roster.bend as R
import ./ai.bend as A
import ./zones.bend as Z

type Simulation.Meta is Data:
  Simulation.Meta{phase: U32, world: U32, seed: U32, tick: U32, started: U32, now: U32, sigils: U32, fame: U32, next_player: U32, next_monster: U32}

type Simulation.State is Data:
  Simulation.State{meta: Simulation.Meta, players: List<&2, P.Players.State>, monsters: List<&2, M.Monsters.State>}

type Simulation.Rules is Data:
  Simulation.Rules{spawn_x: U32, spawn_y: U32, death_timer: U32}

type Simulation.Plan is Data:
  Simulation.Plan{players: List<&2, P.Players.Plan>, zone0: List<&2, A.AI.Plan>, zone1: List<&2, A.AI.Plan>, zone2: List<&2, A.AI.Plan>, zone3: List<&2, A.AI.Plan>}

type Simulation.Prepared is Data:
  Simulation.Prepared{meta: Simulation.Meta, monsters: List<&2, M.Monsters.State>, upkeep: P.Players.Result, running: Bool}

type Simulation.Result is Data:
  Simulation.Result{state: Simulation.State, events: List<&2, P.Players.Event>}

def Simulation.meta(state: Simulation.State) -> Simulation.Meta:
  match state:
    case Simulation.State{meta, players, monsters}:
      meta

def Simulation.players(state: Simulation.State) -> List<&2, P.Players.State>:
  match state:
    case Simulation.State{meta, players, monsters}:
      players

def Simulation.monsters(state: Simulation.State) -> List<&2, M.Monsters.State>:
  match state:
    case Simulation.State{meta, players, monsters}:
      monsters

def Simulation.phase(meta: Simulation.Meta) -> U32:
  match meta:
    case Simulation.Meta{phase, world, seed, tick, started, now, sigils, fame, next_player, next_monster}:
      phase

def Simulation.clock(meta: Simulation.Meta) -> U32:
  match meta:
    case Simulation.Meta{phase, world, seed, tick, started, now, sigils, fame, next_player, next_monster}:
      tick

# Tick arithmetic remains U32; its wraparound/accounting obligation is separate.
def Simulation.advance(meta: Simulation.Meta) -> Simulation.Meta:
  match meta:
    case Simulation.Meta{phase, world, seed, tick, started, now, sigils, fame, next_player, next_monster}:
      Simulation.Meta{phase, world, seed, U32.add(tick, 1), started, now, sigils, fame, next_player, next_monster}

def Simulation.prepared_meta(prepared: Simulation.Prepared) -> Simulation.Meta:
  match prepared:
    case Simulation.Prepared{meta, monsters, upkeep, running}:
      meta

def Simulation.prepared_monsters(prepared: Simulation.Prepared) -> List<&2, M.Monsters.State>:
  match prepared:
    case Simulation.Prepared{meta, monsters, upkeep, running}:
      monsters

def Simulation.prepared_upkeep(prepared: Simulation.Prepared) -> P.Players.Result:
  match prepared:
    case Simulation.Prepared{meta, monsters, upkeep, running}:
      upkeep

def Simulation.state(result: Simulation.Result) -> Simulation.State:
  match result:
    case Simulation.Result{state, events}:
      state

def Simulation.events(result: Simulation.Result) -> List<&2, P.Players.Event>:
  match result:
    case Simulation.Result{state, events}:
      events

# These are the currently established components, not the full WorldOK.
type Simulation.OK<-state: Simulation.State> is Data:
  Simulation.OK{players: P.Players.All(Simulation.players(state)), monsters: R.Roster.OK(Simulation.monsters(state)), zones: Z.Zones.All(Simulation.monsters(state))}

type Simulation.PreparedOK<-prepared: Simulation.Prepared> is Data:
  Simulation.PreparedOK{players: P.Players.All(P.Players.roster(Simulation.prepared_upkeep(prepared))), monsters: R.Roster.OK(Simulation.prepared_monsters(prepared)), zones: Z.Zones.All(Simulation.prepared_monsters(prepared))}

def Simulation.begin_gate(running: Bool, state: Simulation.State, plans: List<&2, P.Players.Plan>, rules: Simulation.Rules) -> Simulation.Prepared:
  match running:
    case False{}:
      match state:
        case Simulation.State{meta, players, monsters}:
          Simulation.Prepared{meta, monsters, P.Players.Result{players, Nil{}}, False{}}
    case True{}:
      match state:
        case Simulation.State{meta, players, monsters}:
          match rules:
            case Simulation.Rules{spawn_x, spawn_y, death_timer}:
              +shared_meta = meta
              Simulation.Prepared{shared_meta, monsters, P.Players.upkeep_all(players, plans, Simulation.clock(shared_meta), spawn_x, spawn_y), True{}}

def Simulation.begin(+state: Simulation.State, plans: List<&2, P.Players.Plan>, rules: Simulation.Rules) -> Simulation.Prepared:
  Simulation.begin_gate(U32.is_eq(Simulation.phase(Simulation.meta(state)), 1), state, plans, rules)

def Simulation.ai_hits(result: A.AI.Result) -> List<&2, A.AI.Hit>:
  match result:
    case A.AI.Result{monsters, hits}:
      hits

def Simulation.attacks(hits: List<&2, A.AI.Hit>) -> List<&2, P.Players.Attack>:
  match hits:
    case Nil{}:
      Nil{}
    case Con{hit, rest}:
      match hit:
        case A.AI.Hit{pid, damage}:
          Con{P.Players.Attack{pid, damage}, Simulation.attacks(rest)}

def Simulation.finish_active(meta: Simulation.Meta, +upkeep: P.Players.Result, +ai: A.AI.Result, timer: U32) -> Simulation.Result:
  +struck = P.Players.apply_hits(Simulation.attacks(Simulation.ai_hits(ai)), P.Players.roster(upkeep), timer)
  Simulation.Result{Simulation.State{Simulation.advance(meta), P.Players.roster(struck), A.AI.monsters(ai)}, P.Players.concat_events(P.Players.events(upkeep), P.Players.events(struck))}

def Simulation.finish(prepared: Simulation.Prepared, p0: List<&2, A.AI.Plan>, p1: List<&2, A.AI.Plan>, p2: List<&2, A.AI.Plan>, p3: List<&2, A.AI.Plan>, rules: Simulation.Rules) -> Simulation.Result:
  match prepared:
    case Simulation.Prepared{meta, monsters, upkeep, running}:
      match running:
        case False{}:
          Simulation.Result{Simulation.State{Simulation.advance(meta), P.Players.roster(upkeep), monsters}, Nil{}}
        case True{}:
          match rules:
            case Simulation.Rules{spawn_x, spawn_y, death_timer}:
              Simulation.finish_active(meta, upkeep, A.AI.run_zones(monsters, p0, p1, p2, p3), death_timer)

# The server calls begin once, plans monster actions against its updated
# players, then calls finish once. This wrapper states their composition.
def Simulation.tick(state: Simulation.State, plan: Simulation.Plan, +rules: Simulation.Rules) -> Simulation.Result:
  match plan:
    case Simulation.Plan{players, p0, p1, p2, p3}:
      Simulation.finish(Simulation.begin(state, players, rules), p0, p1, p2, p3, rules)

law Simulation.begin_gate_ok:
  for +running: Bool
  for +state: Simulation.State
  for +plans: List<&2, P.Players.Plan>
  for +rules: Simulation.Rules
  for +valid: Simulation.OK<state>
  Simulation.PreparedOK<Simulation.begin_gate(running, state, plans, rules)>

def Simulation.begin_gate_ok(running, state, plans, rules, valid):
  match running:
    case False{}:
      match state:
        case Simulation.State{meta, players, monsters}:
          match valid:
            case Simulation.OK{players_ok, monsters_ok, zones_ok}:
              Simulation.PreparedOK{players_ok, monsters_ok, zones_ok}
    case True{}:
      match state:
        case Simulation.State{meta, players, monsters}:
          match rules:
            case Simulation.Rules{spawn_x, spawn_y, death_timer}:
              match valid:
                case Simulation.OK{players_ok, monsters_ok, zones_ok}:
                  Simulation.PreparedOK{P.Players.upkeep_all_ok(players, plans, Simulation.clock(meta), spawn_x, spawn_y, players_ok), monsters_ok, zones_ok}

law Simulation.begin_ok:
  for +state: Simulation.State
  for +plans: List<&2, P.Players.Plan>
  for +rules: Simulation.Rules
  for +valid: Simulation.OK<state>
  Simulation.PreparedOK<Simulation.begin(state, plans, rules)>

def Simulation.begin_ok(state, plans, rules, valid):
  Simulation.begin_gate_ok(U32.is_eq(Simulation.phase(Simulation.meta(state)), 1), state, plans, rules, valid)

law Simulation.finish_active_ok:
  for +meta: Simulation.Meta
  for +upkeep: P.Players.Result
  for +ai: A.AI.Result
  for +timer: U32
  for +players_ok: P.Players.All(P.Players.roster(upkeep))
  for +monsters_ok: R.Roster.OK(A.AI.monsters(ai))
  for +zones_ok: Z.Zones.All(A.AI.monsters(ai))
  Simulation.OK<Simulation.state(Simulation.finish_active(meta, upkeep, ai, timer))>

def Simulation.finish_active_ok(meta, upkeep, ai, timer, players_ok, monsters_ok, zones_ok):
  Simulation.OK{P.Players.apply_hits_all(Simulation.attacks(Simulation.ai_hits(ai)), P.Players.roster(upkeep), timer, players_ok), monsters_ok, zones_ok}

law Simulation.finish_ok:
  for +prepared: Simulation.Prepared
  for +p0: List<&2, A.AI.Plan>
  for +p1: List<&2, A.AI.Plan>
  for +p2: List<&2, A.AI.Plan>
  for +p3: List<&2, A.AI.Plan>
  for +rules: Simulation.Rules
  for +valid: Simulation.PreparedOK<prepared>
  Simulation.OK<Simulation.state(Simulation.finish(prepared, p0, p1, p2, p3, rules))>

def Simulation.finish_ok(prepared, p0, p1, p2, p3, rules, valid):
  match prepared:
    case Simulation.Prepared{meta, monsters, upkeep, running}:
      match running:
        case False{}:
          match valid:
            case Simulation.PreparedOK{players_ok, monsters_ok, zones_ok}:
              Simulation.OK{players_ok, monsters_ok, zones_ok}
        case True{}:
          match rules:
            case Simulation.Rules{spawn_x, spawn_y, death_timer}:
              match valid:
                case Simulation.PreparedOK{players_ok, monsters_ok, zones_ok}:
                  Simulation.finish_active_ok(meta, upkeep, A.AI.run_zones(monsters, p0, p1, p2, p3), death_timer, players_ok, A.AI.run_zones_ok(monsters, p0, p1, p2, p3, monsters_ok), Z.Zones.run_zones_all(monsters, p0, p1, p2, p3, zones_ok))

law Simulation.tick_ok:
  for +state: Simulation.State
  for +plan: Simulation.Plan
  for +rules: Simulation.Rules
  for +valid: Simulation.OK<state>
  Simulation.OK<Simulation.state(Simulation.tick(state, plan, rules))>

def Simulation.tick_ok(state, plan, rules, valid):
  match plan:
    case Simulation.Plan{players, p0, p1, p2, p3}:
      Simulation.finish_ok(Simulation.begin(state, players, rules), p0, p1, p2, p3, rules, Simulation.begin_ok(state, players, rules, valid))

def Simulation.trace(plans: List<&2, Simulation.Plan>, state: Simulation.State, +rules: Simulation.Rules) -> Simulation.State:
  match plans:
    case Nil{}:
      state
    case Con{plan, rest}:
      Simulation.trace(rest, Simulation.state(Simulation.tick(state, plan, rules)), rules)

law Simulation.trace_ok:
  for +plans: List<&2, Simulation.Plan>
  for +state: Simulation.State
  for +rules: Simulation.Rules
  for +valid: Simulation.OK<state>
  Simulation.OK<Simulation.trace(plans, state, rules)>

def Simulation.trace_ok(plans, state, rules, valid):
  match plans:
    case Nil{}:
      valid
    case Con{plan, rest}:
      Simulation.trace_ok(rest, Simulation.state(Simulation.tick(state, plan, rules)), rules, Simulation.tick_ok(state, plan, rules, valid))

law Simulation.begin_gate_meta:
  for +running: Bool
  for +state: Simulation.State
  for +plans: List<&2, P.Players.Plan>
  for +rules: Simulation.Rules
  {Simulation.prepared_meta(Simulation.begin_gate(running, state, plans, rules)) == Simulation.meta(state) : Simulation.Meta}

def Simulation.begin_gate_meta(running, state, plans, rules):
  match running:
    case False{}:
      match state:
        case Simulation.State{meta, players, monsters}:
          {==}
    case True{}:
      match state:
        case Simulation.State{meta, players, monsters}:
          match rules:
            case Simulation.Rules{spawn_x, spawn_y, death_timer}:
              {==}

law Simulation.begin_meta:
  for +state: Simulation.State
  for +plans: List<&2, P.Players.Plan>
  for +rules: Simulation.Rules
  {Simulation.prepared_meta(Simulation.begin(state, plans, rules)) == Simulation.meta(state) : Simulation.Meta}

def Simulation.begin_meta(state, plans, rules):
  Simulation.begin_gate_meta(U32.is_eq(Simulation.phase(Simulation.meta(state)), 1), state, plans, rules)

law Simulation.finish_meta:
  for +prepared: Simulation.Prepared
  for +p0: List<&2, A.AI.Plan>
  for +p1: List<&2, A.AI.Plan>
  for +p2: List<&2, A.AI.Plan>
  for +p3: List<&2, A.AI.Plan>
  for +rules: Simulation.Rules
  {Simulation.meta(Simulation.state(Simulation.finish(prepared, p0, p1, p2, p3, rules))) == Simulation.advance(Simulation.prepared_meta(prepared)) : Simulation.Meta}

def Simulation.finish_meta(prepared, p0, p1, p2, p3, rules):
  match prepared:
    case Simulation.Prepared{meta, monsters, upkeep, running}:
      match running:
        case False{}:
          {==}
        case True{}:
          match rules:
            case Simulation.Rules{spawn_x, spawn_y, death_timer}:
              {==}

law Simulation.tick_meta:
  for +state: Simulation.State
  for +plan: Simulation.Plan
  for +rules: Simulation.Rules
  {Simulation.meta(Simulation.state(Simulation.tick(state, plan, rules))) == Simulation.advance(Simulation.meta(state)) : Simulation.Meta}

def Simulation.tick_meta(state, plan, rules):
  match plan:
    case Simulation.Plan{players, p0, p1, p2, p3}:
      Equal.trans(Simulation.Meta, Simulation.meta(Simulation.state(Simulation.tick(state, Simulation.Plan{players, p0, p1, p2, p3}, rules))), Simulation.advance(Simulation.prepared_meta(Simulation.begin(state, players, rules))), Simulation.advance(Simulation.meta(state)), Simulation.finish_meta(Simulation.begin(state, players, rules), p0, p1, p2, p3, rules), Equal.cong(Simulation.Meta, Simulation.Meta, (meta => Simulation.advance(meta)), Simulation.prepared_meta(Simulation.begin(state, players, rules)), Simulation.meta(state), Simulation.begin_meta(state, players, rules)))

law Simulation.tick_inactive:
  for +state: Simulation.State
  for +plan: Simulation.Plan
  for +rules: Simulation.Rules
  for +inactive: {U32.is_eq(Simulation.phase(Simulation.meta(state)), 1) == False{} : Bool}
  {Simulation.tick(state, plan, rules) == Simulation.Result{Simulation.State{Simulation.advance(Simulation.meta(state)), Simulation.players(state), Simulation.monsters(state)}, Nil{}} : Simulation.Result}

def Simulation.tick_inactive(state, plan, rules, inactive):
  match state:
    case Simulation.State{meta, players, monsters}:
      match plan:
        case Simulation.Plan{pp, p0, p1, p2, p3}:
          %Equal.sym(Bool, U32.is_eq(Simulation.phase(meta), 1), False{}, inactive) : {Simulation.finish(Simulation.begin_gate(_, Simulation.State{meta, players, monsters}, pp, rules), p0, p1, p2, p3, rules) == Simulation.Result{Simulation.State{Simulation.advance(meta), players, monsters}, Nil{}} : Simulation.Result}
          {==}

law Simulation.tick_active_order:
  for +meta: Simulation.Meta
  for +players: List<&2, P.Players.State>
  for +monsters: List<&2, M.Monsters.State>
  for +pp: List<&2, P.Players.Plan>
  for +p0: List<&2, A.AI.Plan>
  for +p1: List<&2, A.AI.Plan>
  for +p2: List<&2, A.AI.Plan>
  for +p3: List<&2, A.AI.Plan>
  for +spawn_x: U32
  for +spawn_y: U32
  for +timer: U32
  for +active: {U32.is_eq(Simulation.phase(meta), 1) == True{} : Bool}
  {Simulation.tick(Simulation.State{meta, players, monsters}, Simulation.Plan{pp, p0, p1, p2, p3}, Simulation.Rules{spawn_x, spawn_y, timer}) == Simulation.finish_active(meta, P.Players.upkeep_all(players, pp, Simulation.clock(meta), spawn_x, spawn_y), A.AI.run_zones(monsters, p0, p1, p2, p3), timer) : Simulation.Result}

def Simulation.tick_active_order(meta, players, monsters, pp, p0, p1, p2, p3, spawn_x, spawn_y, timer, active):
  %Equal.sym(Bool, U32.is_eq(Simulation.phase(meta), 1), True{}, active) : {Simulation.finish(Simulation.begin_gate(_, Simulation.State{meta, players, monsters}, pp, Simulation.Rules{spawn_x, spawn_y, timer}), p0, p1, p2, p3, Simulation.Rules{spawn_x, spawn_y, timer}) == Simulation.finish_active(meta, P.Players.upkeep_all(players, pp, Simulation.clock(meta), spawn_x, spawn_y), A.AI.run_zones(monsters, p0, p1, p2, p3), timer) : Simulation.Result}
  {==}

law Simulation.finish_active_players:
  for +meta: Simulation.Meta
  for +upkeep: P.Players.Result
  for +ai: A.AI.Result
  for +timer: U32
  {Simulation.players(Simulation.state(Simulation.finish_active(meta, upkeep, ai, timer))) == P.Players.roster(P.Players.apply_hits(Simulation.attacks(Simulation.ai_hits(ai)), P.Players.roster(upkeep), timer)) : List<&2, P.Players.State>}

def Simulation.finish_active_players(meta, upkeep, ai, timer):
  {==}

law Simulation.finish_active_events:
  for +meta: Simulation.Meta
  for +upkeep: P.Players.Result
  for +ai: A.AI.Result
  for +timer: U32
  {Simulation.events(Simulation.finish_active(meta, upkeep, ai, timer)) == P.Players.concat_events(P.Players.events(upkeep), P.Players.events(P.Players.apply_hits(Simulation.attacks(Simulation.ai_hits(ai)), P.Players.roster(upkeep), timer))) : List<&2, P.Players.Event>}

def Simulation.finish_active_events(meta, upkeep, ai, timer):
  {==}

law Simulation.begin_gate_player_count:
  for +running: Bool
  for +state: Simulation.State
  for +plans: List<&2, P.Players.Plan>
  for +rules: Simulation.Rules
  {P.Players.length(P.Players.roster(Simulation.prepared_upkeep(Simulation.begin_gate(running, state, plans, rules)))) == P.Players.length(Simulation.players(state)) : Nat}

def Simulation.begin_gate_player_count(running, state, plans, rules):
  match running:
    case False{}:
      match state:
        case Simulation.State{meta, players, monsters}:
          {==}
    case True{}:
      match state:
        case Simulation.State{meta, players, monsters}:
          match rules:
            case Simulation.Rules{spawn_x, spawn_y, death_timer}:
              P.Players.upkeep_count(players, plans, Simulation.clock(meta), spawn_x, spawn_y)

law Simulation.begin_player_count:
  for +state: Simulation.State
  for +plans: List<&2, P.Players.Plan>
  for +rules: Simulation.Rules
  {P.Players.length(P.Players.roster(Simulation.prepared_upkeep(Simulation.begin(state, plans, rules)))) == P.Players.length(Simulation.players(state)) : Nat}

def Simulation.begin_player_count(state, plans, rules):
  Simulation.begin_gate_player_count(U32.is_eq(Simulation.phase(Simulation.meta(state)), 1), state, plans, rules)

law Simulation.begin_gate_monsters:
  for +running: Bool
  for +state: Simulation.State
  for +plans: List<&2, P.Players.Plan>
  for +rules: Simulation.Rules
  {Simulation.prepared_monsters(Simulation.begin_gate(running, state, plans, rules)) == Simulation.monsters(state) : List<&2, M.Monsters.State>}

def Simulation.begin_gate_monsters(running, state, plans, rules):
  match running:
    case False{}:
      match state:
        case Simulation.State{meta, players, monsters}:
          {==}
    case True{}:
      match state:
        case Simulation.State{meta, players, monsters}:
          match rules:
            case Simulation.Rules{spawn_x, spawn_y, death_timer}:
              {==}

law Simulation.begin_monsters:
  for +state: Simulation.State
  for +plans: List<&2, P.Players.Plan>
  for +rules: Simulation.Rules
  {Simulation.prepared_monsters(Simulation.begin(state, plans, rules)) == Simulation.monsters(state) : List<&2, M.Monsters.State>}

def Simulation.begin_monsters(state, plans, rules):
  Simulation.begin_gate_monsters(U32.is_eq(Simulation.phase(Simulation.meta(state)), 1), state, plans, rules)

law Simulation.finish_player_count:
  for +prepared: Simulation.Prepared
  for +p0: List<&2, A.AI.Plan>
  for +p1: List<&2, A.AI.Plan>
  for +p2: List<&2, A.AI.Plan>
  for +p3: List<&2, A.AI.Plan>
  for +rules: Simulation.Rules
  {P.Players.length(Simulation.players(Simulation.state(Simulation.finish(prepared, p0, p1, p2, p3, rules)))) == P.Players.length(P.Players.roster(Simulation.prepared_upkeep(prepared))) : Nat}

def Simulation.finish_player_count(prepared, p0, p1, p2, p3, rules):
  match prepared:
    case Simulation.Prepared{meta, monsters, upkeep, running}:
      match running:
        case False{}:
          {==}
        case True{}:
          match rules:
            case Simulation.Rules{spawn_x, spawn_y, death_timer}:
              P.Players.apply_hits_count(Simulation.attacks(Simulation.ai_hits(A.AI.run_zones(monsters, p0, p1, p2, p3))), P.Players.roster(upkeep), death_timer)

law Simulation.finish_monster_count:
  for +prepared: Simulation.Prepared
  for +p0: List<&2, A.AI.Plan>
  for +p1: List<&2, A.AI.Plan>
  for +p2: List<&2, A.AI.Plan>
  for +p3: List<&2, A.AI.Plan>
  for +rules: Simulation.Rules
  for +zones: Z.Zones.All(Simulation.prepared_monsters(prepared))
  {R.Roster.length(Simulation.monsters(Simulation.state(Simulation.finish(prepared, p0, p1, p2, p3, rules)))) == R.Roster.length(Simulation.prepared_monsters(prepared)) : Nat}

def Simulation.finish_monster_count(prepared, p0, p1, p2, p3, rules, zones):
  match prepared:
    case Simulation.Prepared{meta, monsters, upkeep, running}:
      match running:
        case False{}:
          {==}
        case True{}:
          match rules:
            case Simulation.Rules{spawn_x, spawn_y, death_timer}:
              Z.Zones.run_zones_count(monsters, p0, p1, p2, p3, zones)

law Simulation.tick_player_count:
  for +state: Simulation.State
  for +plan: Simulation.Plan
  for +rules: Simulation.Rules
  {P.Players.length(Simulation.players(Simulation.state(Simulation.tick(state, plan, rules)))) == P.Players.length(Simulation.players(state)) : Nat}

def Simulation.tick_player_count(state, plan, rules):
  match plan:
    case Simulation.Plan{players, p0, p1, p2, p3}:
      Equal.trans(Nat, P.Players.length(Simulation.players(Simulation.state(Simulation.tick(state, Simulation.Plan{players, p0, p1, p2, p3}, rules)))), P.Players.length(P.Players.roster(Simulation.prepared_upkeep(Simulation.begin(state, players, rules)))), P.Players.length(Simulation.players(state)), Simulation.finish_player_count(Simulation.begin(state, players, rules), p0, p1, p2, p3, rules), Simulation.begin_player_count(state, players, rules))

law Simulation.tick_monster_count:
  for +state: Simulation.State
  for +plan: Simulation.Plan
  for +rules: Simulation.Rules
  for +zones: Z.Zones.All(Simulation.monsters(state))
  {R.Roster.length(Simulation.monsters(Simulation.state(Simulation.tick(state, plan, rules)))) == R.Roster.length(Simulation.monsters(state)) : Nat}

def Simulation.tick_monster_count(state, plan, rules, zones):
  match plan:
    case Simulation.Plan{players, p0, p1, p2, p3}:
      Equal.trans(Nat, R.Roster.length(Simulation.monsters(Simulation.state(Simulation.tick(state, Simulation.Plan{players, p0, p1, p2, p3}, rules)))), R.Roster.length(Simulation.prepared_monsters(Simulation.begin(state, players, rules))), R.Roster.length(Simulation.monsters(state)), Simulation.finish_monster_count(Simulation.begin(state, players, rules), p0, p1, p2, p3, rules, (%Equal.sym(List<&2, M.Monsters.State>, Simulation.prepared_monsters(Simulation.begin(state, players, rules)), Simulation.monsters(state), Simulation.begin_monsters(state, players, rules)) : Z.Zones.All(_); zones)), Equal.cong(List<&2, M.Monsters.State>, Nat, (monsters => R.Roster.length(monsters)), Simulation.prepared_monsters(Simulation.begin(state, players, rules)), Simulation.monsters(state), Simulation.begin_monsters(state, players, rules)))

def Simulation.valid_zones(state: Simulation.State, valid: Simulation.OK<state>) -> Z.Zones.All(Simulation.monsters(state)):
  match valid:
    case Simulation.OK{players, monsters, zones}:
      zones

law Simulation.trace_player_count:
  for +plans: List<&2, Simulation.Plan>
  for +state: Simulation.State
  for +rules: Simulation.Rules
  {P.Players.length(Simulation.players(Simulation.trace(plans, state, rules))) == P.Players.length(Simulation.players(state)) : Nat}

def Simulation.trace_player_count(plans, state, rules):
  match plans:
    case Nil{}:
      {==}
    case Con{plan, rest}:
      Equal.trans(Nat, P.Players.length(Simulation.players(Simulation.trace(rest, Simulation.state(Simulation.tick(state, plan, rules)), rules))), P.Players.length(Simulation.players(Simulation.state(Simulation.tick(state, plan, rules)))), P.Players.length(Simulation.players(state)), Simulation.trace_player_count(rest, Simulation.state(Simulation.tick(state, plan, rules)), rules), Simulation.tick_player_count(state, plan, rules))

law Simulation.trace_monster_count:
  for +plans: List<&2, Simulation.Plan>
  for +state: Simulation.State
  for +rules: Simulation.Rules
  for +valid: Simulation.OK<state>
  {R.Roster.length(Simulation.monsters(Simulation.trace(plans, state, rules))) == R.Roster.length(Simulation.monsters(state)) : Nat}

def Simulation.trace_monster_count(plans, state, rules, valid):
  match plans:
    case Nil{}:
      {==}
    case Con{plan, rest}:
      Equal.trans(Nat, R.Roster.length(Simulation.monsters(Simulation.trace(rest, Simulation.state(Simulation.tick(state, plan, rules)), rules))), R.Roster.length(Simulation.monsters(Simulation.state(Simulation.tick(state, plan, rules)))), R.Roster.length(Simulation.monsters(state)), Simulation.trace_monster_count(rest, Simulation.state(Simulation.tick(state, plan, rules)), rules, Simulation.tick_ok(state, plan, rules, valid)), Simulation.tick_monster_count(state, plan, rules, Simulation.valid_zones(state, valid)))

# Reverse conversion gives an exact witness that no AI hit is lost, duplicated,
# reordered, or retargeted at the player-hit boundary.
def Simulation.restore_attacks(attacks: List<&2, P.Players.Attack>) -> List<&2, A.AI.Hit>:
  match attacks:
    case Nil{}:
      Nil{}
    case Con{attack, rest}:
      match attack:
        case P.Players.Attack{pid, damage}:
          Con{A.AI.Hit{pid, damage}, Simulation.restore_attacks(rest)}

law Simulation.attacks_round_trip:
  for +hits: List<&2, A.AI.Hit>
  {Simulation.restore_attacks(Simulation.attacks(hits)) == hits : List<&2, A.AI.Hit>}

def Simulation.attacks_round_trip(hits):
  match hits:
    case Nil{}:
      {==}
    case Con{hit, rest}:
      match hit:
        case A.AI.Hit{pid, damage}:
          %Simulation.attacks_round_trip(rest) : {Con{A.AI.Hit{pid, damage}, Simulation.restore_attacks(Simulation.attacks(rest))} == Con{A.AI.Hit{pid, damage}, _} : List<&2, A.AI.Hit>}
          {==}

# Specify every metadata field independently of the advance implementation.
law Simulation.advance_exact:
  for +phase: U32
  for +world: U32
  for +seed: U32
  for +tick: U32
  for +started: U32
  for +now: U32
  for +sigils: U32
  for +fame: U32
  for +next_player: U32
  for +next_monster: U32
  {Simulation.advance(Simulation.Meta{phase, world, seed, tick, started, now, sigils, fame, next_player, next_monster}) == Simulation.Meta{phase, world, seed, U32.add(tick, 1), started, now, sigils, fame, next_player, next_monster} : Simulation.Meta}

def Simulation.advance_exact(phase, world, seed, tick, started, now, sigils, fame, next_player, next_monster):
  {==}

law Simulation.tick_metadata_exact:
  for +phase: U32
  for +world: U32
  for +seed: U32
  for +tick: U32
  for +started: U32
  for +now: U32
  for +sigils: U32
  for +fame: U32
  for +next_player: U32
  for +next_monster: U32
  for +players: List<&2, P.Players.State>
  for +monsters: List<&2, M.Monsters.State>
  for +plan: Simulation.Plan
  for +rules: Simulation.Rules
  {Simulation.meta(Simulation.state(Simulation.tick(Simulation.State{Simulation.Meta{phase, world, seed, tick, started, now, sigils, fame, next_player, next_monster}, players, monsters}, plan, rules))) == Simulation.Meta{phase, world, seed, U32.add(tick, 1), started, now, sigils, fame, next_player, next_monster} : Simulation.Meta}

def Simulation.tick_metadata_exact(phase, world, seed, tick, started, now, sigils, fame, next_player, next_monster, players, monsters, plan, rules):
  Equal.trans(Simulation.Meta, Simulation.meta(Simulation.state(Simulation.tick(Simulation.State{Simulation.Meta{phase, world, seed, tick, started, now, sigils, fame, next_player, next_monster}, players, monsters}, plan, rules))), Simulation.advance(Simulation.Meta{phase, world, seed, tick, started, now, sigils, fame, next_player, next_monster}), Simulation.Meta{phase, world, seed, U32.add(tick, 1), started, now, sigils, fame, next_player, next_monster}, Simulation.tick_meta(Simulation.State{Simulation.Meta{phase, world, seed, tick, started, now, sigils, fame, next_player, next_monster}, players, monsters}, plan, rules), Simulation.advance_exact(phase, world, seed, tick, started, now, sigils, fame, next_player, next_monster))
