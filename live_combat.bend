# Actual combat admission/execution with typed planning and affine output.
import Base
import ./terrain.bend as T
import ./simulation.bend as S
import ./players.bend as P
import ./monsters.bend as M
import ./combat.bend as C
import ./battle.bend as B
import ./world_seed.bend as Seed
import ./seeded_world.bend as SW
import ./connections.bend as Conn
import ./sessions.bend as Sess
import ./frame_bindings.bend as F
import ./landscape.bend as L

type LiveCombat.Visual is Data:
  LiveCombat.Quiet{}
  LiveCombat.Attack{zone: U32,x: U32,y: U32,dir: U32,mid: U32,crit: U32}
  LiveCombat.Spin{zone: U32,x: U32,y: U32}

type LiveCombat.Plan is Data:
  LiveCombat.Plan{inputs: List<&2,B.Battle.Input>,visual: LiveCombat.Visual}

def LiveCombat.inputs(plan: LiveCombat.Plan) -> List<&2,B.Battle.Input>:
  match plan:
    case LiveCombat.Plan{inputs,visual}: inputs

type LiveCombat.Ready is Data:
  LiveCombat.Ready{meta: S.Simulation.Meta,monsters: List<&2,M.Monsters.State>,maps: T.Terrain.Maps,admitted: C.Combat.Result,pid: U32,score: U32}

type LiveCombat.Result is Data:
  LiveCombat.Result{world: T.Terrain.World,notices: List<&2,B.Battle.Notice>,visual: LiveCombat.Visual}

def LiveCombat.world(result: LiveCombat.Result) -> T.Terrain.World:
  match result:
    case LiveCombat.Result{world,notices,visual}: world

def LiveCombat.notices(result: LiveCombat.Result) -> List<&2,B.Battle.Notice>:
  match result:
    case LiveCombat.Result{world,notices,visual}: notices

def LiveCombat.visual(result: LiveCombat.Result) -> LiveCombat.Visual:
  match result:
    case LiveCombat.Result{world,notices,visual}: visual

def LiveCombat.pack(result: B.Battle.Result,maps: T.Terrain.Maps,visual: LiveCombat.Visual) -> LiveCombat.Result:
  match result:
    case B.Battle.Result{state,notices}: LiveCombat.Result{T.Terrain.world(maps,state),notices,visual}

def LiveCombat.prepare(world: T.Terrain.World,kind: C.Combat.Kind,+pid: U32,score: U32) -> LiveCombat.Ready:
  match world:
    case T.Terrain.World{meta,players,monsters,maps}:
      +meta = meta
      LiveCombat.Ready{meta,monsters,maps,C.Combat.run(players,pid,kind,S.Simulation.phase(meta)),pid,score}

# Rejected admission cannot execute supplied plans or emit a combat visual.
def LiveCombat.finish(ready: LiveCombat.Ready,plan: LiveCombat.Plan) -> LiveCombat.Result:
  match ready:
    case LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,attacker}:
          match attacker:
            case None{}: LiveCombat.pack(B.Battle.execute(meta,monsters,C.Combat.Result{players,None{}},Nil{},pid,score),maps,LiveCombat.Quiet{})
            case Some{player}:
              match plan:
                case LiveCombat.Plan{inputs,visual}: LiveCombat.pack(B.Battle.execute(meta,monsters,C.Combat.Result{players,Some{player}},inputs,pid,score),maps,visual)

def LiveCombat.at(world: T.Terrain.World,kind: C.Combat.Kind,pid: U32,score: U32,plan: LiveCombat.Plan) -> LiveCombat.Result:
  LiveCombat.finish(LiveCombat.prepare(world,kind,pid,score),plan)

def LiveCombat.run(world: T.Terrain.World,kind: C.Combat.Kind,pid: U32,score: U32,planner: LiveCombat.Ready -> LiveCombat.Plan) -> LiveCombat.Result:
  +ready = LiveCombat.prepare(world,kind,pid,score)
  LiveCombat.finish(ready,planner(ready))

def LiveCombat.emit(-A: Type,+result: LiveCombat.Result,render: LiveCombat.Result -> List<&1,A>) -> T.Terrain.World & List<&1,A>:
  Tuple{LiveCombat.world(result),render(result)}

def LiveCombat.output_world(-A: Type,result: T.Terrain.World & List<&1,A>) -> T.Terrain.World:
  match result:
    case Tuple{world,lines}: world

def LiveCombat.output_lines(-A: Type,result: T.Terrain.World & List<&1,A>) -> List<&1,A>:
  match result:
    case Tuple{world,lines}: lines

law LiveCombat.pack_simulation:
  for +result: B.Battle.Result
  for +maps: T.Terrain.Maps
  for +visual: LiveCombat.Visual
  {T.Terrain.simulation(LiveCombat.world(LiveCombat.pack(result,maps,visual))) == B.Battle.state(result) : S.Simulation.State}

def LiveCombat.pack_simulation(result,maps,visual):
  match result:
    case B.Battle.Result{state,notices}: T.Terrain.world_simulation(maps,state)

law LiveCombat.pack_maps:
  for +result: B.Battle.Result
  for +maps: T.Terrain.Maps
  for +visual: LiveCombat.Visual
  {T.Terrain.maps(LiveCombat.world(LiveCombat.pack(result,maps,visual))) == maps : T.Terrain.Maps}

def LiveCombat.pack_maps(result,maps,visual):
  match result:
    case B.Battle.Result{state,notices}: T.Terrain.world_maps(maps,state)

law LiveCombat.pack_notices:
  for +result: B.Battle.Result
  for +maps: T.Terrain.Maps
  for +visual: LiveCombat.Visual
  {LiveCombat.notices(LiveCombat.pack(result,maps,visual)) == B.Battle.notices(result) : List<&2,B.Battle.Notice>}

def LiveCombat.pack_notices(result,maps,visual):
  match result:
    case B.Battle.Result{state,notices}: {==}

law LiveCombat.pack_visual:
  for +result: B.Battle.Result
  for +maps: T.Terrain.Maps
  for +visual: LiveCombat.Visual
  {LiveCombat.visual(LiveCombat.pack(result,maps,visual)) == visual : LiveCombat.Visual}

def LiveCombat.pack_visual(result,maps,visual):
  match result:
    case B.Battle.Result{state,notices}: {==}

law LiveCombat.finish_rejected:
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +monsters: List<&2,M.Monsters.State>
  for +maps: T.Terrain.Maps
  for +pid: U32
  for +score: U32
  for +plan: LiveCombat.Plan
  {LiveCombat.finish(LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,None{}},pid,score},plan) == LiveCombat.Result{T.Terrain.world(maps,S.Simulation.State{meta,players,monsters}),Nil{},LiveCombat.Quiet{}} : LiveCombat.Result}

def LiveCombat.finish_rejected(meta,players,monsters,maps,pid,score,plan): {==}

law LiveCombat.finish_simulation:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +maps: T.Terrain.Maps
  for +admitted: C.Combat.Result
  for +pid: U32
  for +score: U32
  for +plan: LiveCombat.Plan
  {T.Terrain.simulation(LiveCombat.world(LiveCombat.finish(LiveCombat.Ready{meta,monsters,maps,admitted,pid,score},plan))) == B.Battle.state(B.Battle.execute(meta,monsters,admitted,LiveCombat.inputs(plan),pid,score)) : S.Simulation.State}

def LiveCombat.finish_simulation(meta,monsters,maps,admitted,pid,score,plan):
  match admitted:
    case C.Combat.Result{players,attacker}:
      match attacker:
        case None{}: T.Terrain.world_simulation(maps,S.Simulation.State{meta,players,monsters})
        case Some{player}:
          match plan:
            case LiveCombat.Plan{inputs,visual}: LiveCombat.pack_simulation(B.Battle.execute(meta,monsters,C.Combat.Result{players,Some{player}},inputs,pid,score),maps,visual)

law LiveCombat.finish_maps:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +maps: T.Terrain.Maps
  for +admitted: C.Combat.Result
  for +pid: U32
  for +score: U32
  for +plan: LiveCombat.Plan
  {T.Terrain.maps(LiveCombat.world(LiveCombat.finish(LiveCombat.Ready{meta,monsters,maps,admitted,pid,score},plan))) == maps : T.Terrain.Maps}

def LiveCombat.finish_maps(meta,monsters,maps,admitted,pid,score,plan):
  match admitted:
    case C.Combat.Result{players,attacker}:
      match attacker:
        case None{}: T.Terrain.world_maps(maps,S.Simulation.State{meta,players,monsters})
        case Some{player}:
          match plan:
            case LiveCombat.Plan{inputs,visual}: LiveCombat.pack_maps(B.Battle.execute(meta,monsters,C.Combat.Result{players,Some{player}},inputs,pid,score),maps,visual)

law LiveCombat.finish_notices:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +maps: T.Terrain.Maps
  for +admitted: C.Combat.Result
  for +pid: U32
  for +score: U32
  for +plan: LiveCombat.Plan
  {LiveCombat.notices(LiveCombat.finish(LiveCombat.Ready{meta,monsters,maps,admitted,pid,score},plan)) == B.Battle.notices(B.Battle.execute(meta,monsters,admitted,LiveCombat.inputs(plan),pid,score)) : List<&2,B.Battle.Notice>}

def LiveCombat.finish_notices(meta,monsters,maps,admitted,pid,score,plan):
  match admitted:
    case C.Combat.Result{players,attacker}:
      match attacker:
        case None{}: {==}
        case Some{player}:
          match plan:
            case LiveCombat.Plan{inputs,visual}: LiveCombat.pack_notices(B.Battle.execute(meta,monsters,C.Combat.Result{players,Some{player}},inputs,pid,score),maps,visual)

law LiveCombat.finish_accepted_visual:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +maps: T.Terrain.Maps
  for +players: List<&2,P.Players.State>
  for +player: P.Players.State
  for +pid: U32
  for +score: U32
  for +inputs: List<&2,B.Battle.Input>
  for +visual: LiveCombat.Visual
  {LiveCombat.visual(LiveCombat.finish(LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,Some{player}},pid,score},LiveCombat.Plan{inputs,visual})) == visual : LiveCombat.Visual}

def LiveCombat.finish_accepted_visual(meta,monsters,maps,players,player,pid,score,inputs,visual):
  LiveCombat.pack_visual(B.Battle.execute(meta,monsters,C.Combat.Result{players,Some{player}},inputs,pid,score),maps,visual)

law LiveCombat.at_refines:
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for +plan: LiveCombat.Plan
  {T.Terrain.simulation(LiveCombat.world(LiveCombat.at(world,kind,pid,score,plan))) == B.Battle.state(B.Battle.command(kind,T.Terrain.simulation(world),LiveCombat.inputs(plan),pid,score)) : S.Simulation.State}

def LiveCombat.at_refines(world,kind,pid,score,plan):
  match world:
    case T.Terrain.World{meta,players,monsters,maps}: LiveCombat.finish_simulation(meta,monsters,maps,C.Combat.run(players,pid,kind,S.Simulation.phase(meta)),pid,score,plan)

law LiveCombat.at_maps:
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for +plan: LiveCombat.Plan
  {T.Terrain.maps(LiveCombat.world(LiveCombat.at(world,kind,pid,score,plan))) == T.Terrain.maps(world) : T.Terrain.Maps}

def LiveCombat.at_maps(world,kind,pid,score,plan):
  match world:
    case T.Terrain.World{meta,players,monsters,maps}: LiveCombat.finish_maps(meta,monsters,maps,C.Combat.run(players,pid,kind,S.Simulation.phase(meta)),pid,score,plan)

law LiveCombat.at_seed:
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for +plan: LiveCombat.Plan
  {SW.SeededWorld.seed(LiveCombat.world(LiveCombat.at(world,kind,pid,score,plan))) == SW.SeededWorld.seed(world) : U32}

def LiveCombat.at_seed(world,kind,pid,score,plan):
  %Equal.sym(S.Simulation.State,T.Terrain.simulation(LiveCombat.world(LiveCombat.at(world,kind,pid,score,plan))),B.Battle.state(B.Battle.command(kind,T.Terrain.simulation(world),LiveCombat.inputs(plan),pid,score)),LiveCombat.at_refines(world,kind,pid,score,plan)) : {Seed.WorldSeed.of(_) == SW.SeededWorld.seed(world) : U32}
  Seed.WorldSeed.command(kind,T.Terrain.simulation(world),LiveCombat.inputs(plan),pid,score)

law LiveCombat.at_seeded:
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for +plan: LiveCombat.Plan
  for +states: List<&2,Sess.Sessions.State>
  for +valid: SW.SeededWorld.OK<world,states>
  SW.SeededWorld.OK<LiveCombat.world(LiveCombat.at(world,kind,pid,score,plan)),states>

def LiveCombat.at_seeded(world,kind,pid,score,plan,states,valid):
  match valid:
    case SW.SeededWorld.OK{world_ok,maps}:
      +seed = SW.SeededWorld.seed(world)
      SW.SeededWorld.from_external(LiveCombat.world(LiveCombat.at(world,kind,pid,score,plan)),states,seed,LiveCombat.at_seed(world,kind,pid,score,plan),(%Equal.sym(S.Simulation.State,T.Terrain.simulation(LiveCombat.world(LiveCombat.at(world,kind,pid,score,plan))),B.Battle.state(B.Battle.command(kind,T.Terrain.simulation(world),LiveCombat.inputs(plan),pid,score)),LiveCombat.at_refines(world,kind,pid,score,plan)) : Conn.Connections.WorldOK<seed,_,states>; F.FrameBindings.fight_world(kind,seed,T.Terrain.simulation(world),states,LiveCombat.inputs(plan),pid,score,world_ok)),Equal.trans(T.Terrain.Maps,T.Terrain.maps(LiveCombat.world(LiveCombat.at(world,kind,pid,score,plan))),T.Terrain.maps(world),L.Landscape.maps(seed),LiveCombat.at_maps(world,kind,pid,score,plan),maps))

law LiveCombat.run_seeded:
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for +states: List<&2,Sess.Sessions.State>
  for planner: LiveCombat.Ready -> LiveCombat.Plan
  for +valid: SW.SeededWorld.OK<world,states>
  SW.SeededWorld.OK<LiveCombat.world(LiveCombat.run(world,kind,pid,score,planner)),states>

def LiveCombat.run_seeded(world,kind,pid,score,states,planner,valid):
  +plan = planner(LiveCombat.prepare(world,kind,pid,score))
  LiveCombat.at_seeded(world,kind,pid,score,plan,states,valid)

law LiveCombat.emit_world:
  for -A: Type
  for +result: LiveCombat.Result
  for render: LiveCombat.Result -> List<&1,A>
  {LiveCombat.output_world(A,LiveCombat.emit(A,result,render)) == LiveCombat.world(result) : T.Terrain.World}

def LiveCombat.emit_world(A,result,render): {==}

law LiveCombat.emit_lines:
  for -A: Type
  for +result: LiveCombat.Result
  for render: LiveCombat.Result -> List<&1,A>
  {LiveCombat.output_lines(A,LiveCombat.emit(A,result,render)) == render(result) : List<&1,A>}

def LiveCombat.emit_lines(A,result,render): {==}

law LiveCombat.emit_seeded:
  for -A: Type
  for +result: LiveCombat.Result
  for +states: List<&2,Sess.Sessions.State>
  for render: LiveCombat.Result -> List<&1,A>
  for +valid: SW.SeededWorld.OK<LiveCombat.world(result),states>
  SW.SeededWorld.OK<LiveCombat.output_world(A,LiveCombat.emit(A,result,render)),states>

def LiveCombat.emit_seeded(A,result,states,render,valid):
  %Equal.sym(T.Terrain.World,LiveCombat.output_world(A,LiveCombat.emit(A,result,render)),LiveCombat.world(result),LiveCombat.emit_world(A,result,render)) : SW.SeededWorld.OK<_,states>
  valid

law LiveCombat.run_emitted:
  for -A: Type
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for +states: List<&2,Sess.Sessions.State>
  for planner: LiveCombat.Ready -> LiveCombat.Plan
  for render: LiveCombat.Result -> List<&1,A>
  for +valid: SW.SeededWorld.OK<world,states>
  SW.SeededWorld.OK<LiveCombat.output_world(A,LiveCombat.emit(A,LiveCombat.run(world,kind,pid,score,planner),render)),states>

def LiveCombat.run_emitted(A,world,kind,pid,score,states,planner,render,valid):
  +plan = planner(LiveCombat.prepare(world,kind,pid,score))
  LiveCombat.emit_seeded(A,LiveCombat.at(world,kind,pid,score,plan),states,render,LiveCombat.at_seeded(world,kind,pid,score,plan,states,valid))
