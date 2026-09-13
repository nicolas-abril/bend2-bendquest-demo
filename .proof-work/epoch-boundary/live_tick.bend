# The authoritative tick retains its actual maps and separates state from output.
import Base
import ./monster_damage.bend as D
import ./simulation.bend as S
import ./terrain.bend as T
import ./locomotion.bend as Walk
import ./planning.bend as Plan
import ./ai_refs.bend as AI
import ./players.bend as P
import ./world_seed.bend as Seed
import ./seeded_world.bend as SW
import ./connections.bend as C
import ./sessions.bend as Sess
import ./tick_bindings.bend as Bind
import ./landscape.bend as L

type LiveTick.Result is Data:
  LiveTick.Result{world: T.Terrain.World,events: List<&2,P.Players.Event>,clock: U32}

def LiveTick.world(result: LiveTick.Result) -> T.Terrain.World:
  match result:
    case LiveTick.Result{world,events,clock}: world

def LiveTick.events(result: LiveTick.Result) -> List<&2,P.Players.Event>:
  match result:
    case LiveTick.Result{world,events,clock}: events

def LiveTick.clock(result: LiveTick.Result) -> U32:
  match result:
    case LiveTick.Result{world,events,clock}: clock

def LiveTick.pack(result: S.Simulation.Result,maps: T.Terrain.Maps,clock: U32) -> LiveTick.Result:
  match result:
    case S.Simulation.Result{state,events}: LiveTick.Result{T.Terrain.world(maps,state),events,clock}

def LiveTick.damages(prepared: S.Simulation.Prepared) -> AI.AIRefs.Damages:
  match prepared:
    case S.Simulation.Prepared{meta,monsters,upkeep,running}:
      match running:
        case False{}: AI.AIRefs.Damages{Nil{},Nil{},Nil{},Nil{}}
        case True{}: D.MonsterDamage.zones(monsters)

def LiveTick.simulate(damages: AI.AIRefs.Damages,prepared: S.Simulation.Prepared,maps: T.Terrain.Maps,rules: S.Simulation.Rules) -> S.Simulation.Result:
  match damages:
    case AI.AIRefs.Damages{d0,d1,d2,d3}: AI.AIRefs.finish(prepared,maps,d0,d1,d2,d3,rules)

def LiveTick.finish(+prepared: S.Simulation.Prepared,+maps: T.Terrain.Maps,rules: S.Simulation.Rules) -> LiveTick.Result:
  LiveTick.pack(LiveTick.simulate(LiveTick.damages(prepared),prepared,maps,rules),maps,S.Simulation.clock(S.Simulation.prepared_meta(prepared)))

def LiveTick.run(+world: T.Terrain.World,timer: U32) -> LiveTick.Result:
  +maps = T.Terrain.maps(world)
  +rules = Plan.Planning.rules(timer)
  LiveTick.finish(Walk.Locomotion.begin(T.Terrain.simulation(world),maps,rules),maps,rules)

def LiveTick.at(+state: S.Simulation.State,+maps: T.Terrain.Maps,timer: U32) -> S.Simulation.State:
  +rules = Plan.Planning.rules(timer)
  AI.AIRefs.run_tick(LiveTick.damages(Walk.Locomotion.begin(state,maps,rules)),state,maps,rules)

# The renderer receives data once. Its affine output cannot alter the world.
def LiveTick.emit(-A: Type,+result: LiveTick.Result,render: LiveTick.Result -> List<&1,A>) -> Sigma<&1,&1,T.Terrain.World,(world => List<&1,A>)>:
  Tuple{LiveTick.world(result),render(result)}

def LiveTick.output_world(-A: Type,output: Sigma<&1,&1,T.Terrain.World,(world => List<&1,A>)>) -> T.Terrain.World:
  match output:
    case Tuple{world,lines}: world

def LiveTick.output_lines(-A: Type,output: Sigma<&1,&1,T.Terrain.World,(world => List<&1,A>)>) -> List<&1,A>:
  match output:
    case Tuple{world,lines}: lines

law LiveTick.pack_simulation:
  for +result: S.Simulation.Result
  for +maps: T.Terrain.Maps
  for +clock: U32
  {T.Terrain.simulation(LiveTick.world(LiveTick.pack(result,maps,clock))) == S.Simulation.state(result) : S.Simulation.State}

def LiveTick.pack_simulation(result,maps,clock):
  match result:
    case S.Simulation.Result{state,events}: T.Terrain.world_simulation(maps,state)

law LiveTick.pack_maps:
  for +result: S.Simulation.Result
  for +maps: T.Terrain.Maps
  for +clock: U32
  {T.Terrain.maps(LiveTick.world(LiveTick.pack(result,maps,clock))) == maps : T.Terrain.Maps}

def LiveTick.pack_maps(result,maps,clock):
  match result:
    case S.Simulation.Result{state,events}: T.Terrain.world_maps(maps,state)

law LiveTick.pack_events:
  for +result: S.Simulation.Result
  for +maps: T.Terrain.Maps
  for +clock: U32
  {LiveTick.events(LiveTick.pack(result,maps,clock)) == S.Simulation.events(result) : List<&2,P.Players.Event>}

def LiveTick.pack_events(result,maps,clock):
  match result:
    case S.Simulation.Result{state,events}: {==}

law LiveTick.pack_clock:
  for +result: S.Simulation.Result
  for +maps: T.Terrain.Maps
  for +clock: U32
  {LiveTick.clock(LiveTick.pack(result,maps,clock)) == clock : U32}

def LiveTick.pack_clock(result,maps,clock):
  match result:
    case S.Simulation.Result{state,events}: {==}

law LiveTick.simulate_refines:
  for +damages: AI.AIRefs.Damages
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  {S.Simulation.state(LiveTick.simulate(damages,Walk.Locomotion.begin(state,maps,rules),maps,rules)) == AI.AIRefs.run_tick(damages,state,maps,rules) : S.Simulation.State}

def LiveTick.simulate_refines(damages,state,maps,rules):
  match damages:
    case AI.AIRefs.Damages{d0,d1,d2,d3}: {==}

law LiveTick.run_simulation:
  for +world: T.Terrain.World
  for +timer: U32
  {T.Terrain.simulation(LiveTick.world(LiveTick.run(world,timer))) == LiveTick.at(T.Terrain.simulation(world),T.Terrain.maps(world),timer) : S.Simulation.State}

def LiveTick.run_simulation(world,timer):
  +state = T.Terrain.simulation(world)
  +maps = T.Terrain.maps(world)
  +rules = Plan.Planning.rules(timer)
  +prepared = Walk.Locomotion.begin(state,maps,rules)
  +damages = LiveTick.damages(prepared)
  +result = LiveTick.simulate(damages,prepared,maps,rules)
  Equal.trans(S.Simulation.State,T.Terrain.simulation(LiveTick.world(LiveTick.run(world,timer))),S.Simulation.state(result),AI.AIRefs.run_tick(damages,state,maps,rules),LiveTick.pack_simulation(result,maps,S.Simulation.clock(S.Simulation.prepared_meta(prepared))),LiveTick.simulate_refines(damages,state,maps,rules))

law LiveTick.run_maps:
  for +world: T.Terrain.World
  for +timer: U32
  {T.Terrain.maps(LiveTick.world(LiveTick.run(world,timer))) == T.Terrain.maps(world) : T.Terrain.Maps}

def LiveTick.run_maps(world,timer):
  +maps = T.Terrain.maps(world)
  +prepared = Walk.Locomotion.begin(T.Terrain.simulation(world),maps,Plan.Planning.rules(timer))
  LiveTick.pack_maps(LiveTick.simulate(LiveTick.damages(prepared),prepared,maps,Plan.Planning.rules(timer)),maps,S.Simulation.clock(S.Simulation.prepared_meta(prepared)))

law LiveTick.run_clock:
  for +world: T.Terrain.World
  for +timer: U32
  {LiveTick.clock(LiveTick.run(world,timer)) == S.Simulation.clock(S.Simulation.meta(T.Terrain.simulation(world))) : U32}

def LiveTick.run_clock(world,timer):
  +state = T.Terrain.simulation(world)
  +maps = T.Terrain.maps(world)
  +rules = Plan.Planning.rules(timer)
  +prepared = Walk.Locomotion.begin(state,maps,rules)
  Equal.trans(U32,LiveTick.clock(LiveTick.run(world,timer)),S.Simulation.clock(S.Simulation.prepared_meta(prepared)),S.Simulation.clock(S.Simulation.meta(state)),LiveTick.pack_clock(LiveTick.simulate(LiveTick.damages(prepared),prepared,maps,rules),maps,S.Simulation.clock(S.Simulation.prepared_meta(prepared))),Equal.cong(S.Simulation.Meta,U32,(meta => S.Simulation.clock(meta)),S.Simulation.prepared_meta(prepared),S.Simulation.meta(state),Seed.WorldSeed.begin_meta(state,maps,rules)))

law LiveTick.run_events:
  for +world: T.Terrain.World
  for +timer: U32
  {LiveTick.events(LiveTick.run(world,timer)) == S.Simulation.events(LiveTick.simulate(LiveTick.damages(Walk.Locomotion.begin(T.Terrain.simulation(world),T.Terrain.maps(world),Plan.Planning.rules(timer))),Walk.Locomotion.begin(T.Terrain.simulation(world),T.Terrain.maps(world),Plan.Planning.rules(timer)),T.Terrain.maps(world),Plan.Planning.rules(timer))) : List<&2,P.Players.Event>}

def LiveTick.run_events(world,timer):
  +maps = T.Terrain.maps(world)
  +rules = Plan.Planning.rules(timer)
  +prepared = Walk.Locomotion.begin(T.Terrain.simulation(world),maps,rules)
  LiveTick.pack_events(LiveTick.simulate(LiveTick.damages(prepared),prepared,maps,rules),maps,S.Simulation.clock(S.Simulation.prepared_meta(prepared)))

law LiveTick.run_seed:
  for +world: T.Terrain.World
  for +timer: U32
  {SW.SeededWorld.seed(LiveTick.world(LiveTick.run(world,timer))) == SW.SeededWorld.seed(world) : U32}

def LiveTick.run_seed(world,timer):
  +state = T.Terrain.simulation(world)
  +maps = T.Terrain.maps(world)
  +rules = Plan.Planning.rules(timer)
  +damages = LiveTick.damages(Walk.Locomotion.begin(state,maps,rules))
  %Equal.sym(S.Simulation.State,T.Terrain.simulation(LiveTick.world(LiveTick.run(world,timer))),LiveTick.at(state,maps,timer),LiveTick.run_simulation(world,timer)) : {Seed.WorldSeed.of(_) == SW.SeededWorld.seed(world) : U32}
  Seed.WorldSeed.run_tick(damages,state,maps,rules)

law LiveTick.at_valid:
  for +seed: U32
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +timer: U32
  for +states: List<&2,Sess.Sessions.State>
  for +same_maps: {maps == L.Landscape.maps(seed) : T.Terrain.Maps}
  for +valid: C.Connections.WorldOK<seed,state,states>
  C.Connections.WorldOK<seed,LiveTick.at(state,maps,timer),states>

def LiveTick.at_valid(seed,state,maps,timer,states,same_maps,valid):
  %Equal.sym(T.Terrain.Maps,maps,L.Landscape.maps(seed),same_maps) : C.Connections.WorldOK<seed,LiveTick.at(state,_,timer),states>
  Bind.TickBindings.world(LiveTick.damages(Walk.Locomotion.begin(state,L.Landscape.maps(seed),Plan.Planning.rules(timer))),seed,state,states,timer,valid)

law LiveTick.seeded:
  for +world: T.Terrain.World
  for +timer: U32
  for +states: List<&2,Sess.Sessions.State>
  for +valid: SW.SeededWorld.OK<world,states>
  SW.SeededWorld.OK<LiveTick.world(LiveTick.run(world,timer)),states>

def LiveTick.seeded(world,timer,states,valid):
  match valid:
    case SW.SeededWorld.OK{world_ok,maps}:
      SW.SeededWorld.from_external(LiveTick.world(LiveTick.run(world,timer)),states,SW.SeededWorld.seed(world),LiveTick.run_seed(world,timer),(%Equal.sym(S.Simulation.State,T.Terrain.simulation(LiveTick.world(LiveTick.run(world,timer))),LiveTick.at(T.Terrain.simulation(world),T.Terrain.maps(world),timer),LiveTick.run_simulation(world,timer)) : C.Connections.WorldOK<SW.SeededWorld.seed(world),_,states>; LiveTick.at_valid(SW.SeededWorld.seed(world),T.Terrain.simulation(world),T.Terrain.maps(world),timer,states,maps,world_ok)),Equal.trans(T.Terrain.Maps,T.Terrain.maps(LiveTick.world(LiveTick.run(world,timer))),T.Terrain.maps(world),L.Landscape.maps(SW.SeededWorld.seed(world)),LiveTick.run_maps(world,timer),maps))

law LiveTick.emit_world:
  for -A: Type
  for +result: LiveTick.Result
  for render: LiveTick.Result -> List<&1,A>
  {LiveTick.output_world(A,LiveTick.emit(A,result,render)) == LiveTick.world(result) : T.Terrain.World}

def LiveTick.emit_world(A,result,render): {==}

law LiveTick.emit_lines:
  for -A: Type
  for +result: LiveTick.Result
  for render: LiveTick.Result -> List<&1,A>
  {LiveTick.output_lines(A,LiveTick.emit(A,result,render)) == render(result) : List<&1,A>}

def LiveTick.emit_lines(A,result,render): {==}

law LiveTick.emit_seeded:
  for -A: Type
  for +result: LiveTick.Result
  for +states: List<&2,Sess.Sessions.State>
  for render: LiveTick.Result -> List<&1,A>
  for +valid: SW.SeededWorld.OK<LiveTick.world(result),states>
  SW.SeededWorld.OK<LiveTick.output_world(A,LiveTick.emit(A,result,render)),states>

def LiveTick.emit_seeded(A,result,states,render,valid):
  %Equal.sym(T.Terrain.World,LiveTick.output_world(A,LiveTick.emit(A,result,render)),LiveTick.world(result),LiveTick.emit_world(A,result,render)) : SW.SeededWorld.OK<_,states>
  valid

law LiveTick.run_emitted:
  for -A: Type
  for +world: T.Terrain.World
  for +timer: U32
  for +states: List<&2,Sess.Sessions.State>
  for render: LiveTick.Result -> List<&1,A>
  for +valid: SW.SeededWorld.OK<world,states>
  SW.SeededWorld.OK<LiveTick.output_world(A,LiveTick.emit(A,LiveTick.run(world,timer),render)),states>

def LiveTick.run_emitted(A,world,timer,states,render,valid): LiveTick.emit_seeded(A,LiveTick.run(world,timer),states,render,LiveTick.seeded(world,timer,states,valid))
