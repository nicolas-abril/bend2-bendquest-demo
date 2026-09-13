# Live inventory and interaction commands retain the actual world frame.
import Base
import ./terrain.bend as T
import ./simulation.bend as S
import ./players.bend as P
import ./monsters.bend as M
import ./game.bend as G
import ./inventory.bend as I
import ./interactions.bend as Inter
import ./frame_bindings.bend as F
import ./playerids.bend as Id
import ./creation.bend as K
import ./connections.bend as C
import ./sessions.bend as Sess
import ./seeded_world.bend as SW
import ./channel_restart.bend as CR
import ./landscape.bend as L

type LiveCommands.Notice is Data:
  LiveCommands.Inventory{reply: Maybe<&2,I.Inventory.Reply>}
  LiveCommands.Interaction{reply: Maybe<&2,Inter.Interaction.Reply>}

type LiveCommands.Result is Data:
  LiveCommands.Result{world: T.Terrain.World,notice: LiveCommands.Notice}

def LiveCommands.world(result: LiveCommands.Result) -> T.Terrain.World:
  match result:
    case LiveCommands.Result{world,notice}: world

def LiveCommands.notice(result: LiveCommands.Result) -> LiveCommands.Notice:
  match result:
    case LiveCommands.Result{world,notice}: notice

def LiveCommands.sigils(meta: S.Simulation.Meta) -> U32:
  match meta:
    case S.Simulation.Meta{phase,world,seed,tick,started,now,sigils,fame,next_player,next_monster}: sigils

def LiveCommands.near(found: Maybe<&2,P.Players.State>) -> Bool:
  match found:
    case None{}: False{}
    case Some{player}:
      match player:
        case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}: Inter.Interaction.near(pos,Inter.Interaction.shop_x,Inter.Interaction.shop_y)

def LiveCommands.inventory_result(meta: S.Simulation.Meta,monsters: List<&2,M.Monsters.State>,maps: T.Terrain.Maps,result: I.Inventory.Result) -> LiveCommands.Result:
  match result:
    case I.Inventory.Result{players,reply}: LiveCommands.Result{T.Terrain.World{meta,players,monsters,maps},LiveCommands.Inventory{reply}}

def LiveCommands.interaction_result(meta: S.Simulation.Meta,monsters: List<&2,M.Monsters.State>,maps: T.Terrain.Maps,result: Inter.Interaction.Result) -> LiveCommands.Result:
  match result:
    case Inter.Interaction.Result{players,reply}: LiveCommands.Result{T.Terrain.World{meta,players,monsters,maps},LiveCommands.Interaction{reply}}

def LiveCommands.inventory(world: T.Terrain.World,pid: U32,op: G.Bq.HOp,amount: U32) -> LiveCommands.Result:
  match world:
    case T.Terrain.World{meta,players,monsters,maps}:
      +taken = P.Players.take(players,pid)
      LiveCommands.inventory_result(meta,monsters,maps,I.Inventory.apply_taken(taken,op,LiveCommands.near(P.Players.found(taken)),amount))

def LiveCommands.interact(world: T.Terrain.World,pid: U32,command: Inter.Interaction.Command) -> LiveCommands.Result:
  match world:
    case T.Terrain.World{meta,players,monsters,maps}: LiveCommands.interaction_result(meta,monsters,maps,Inter.Interaction.run(players,pid,command))

type LiveCommands.Input is Data:
  LiveCommands.Hero{pid: U32,op: G.Bq.HOp,amount: U32}
  LiveCommands.Act{pid: U32,command: Inter.Interaction.Command}
  LiveCommands.Enter{pid: U32}

def LiveCommands.run(input: LiveCommands.Input,+world: T.Terrain.World) -> LiveCommands.Result:
  match input:
    case LiveCommands.Hero{pid,op,amount}: LiveCommands.inventory(world,pid,op,amount)
    case LiveCommands.Act{pid,command}: LiveCommands.interact(world,pid,command)
    case LiveCommands.Enter{pid}: LiveCommands.interact(world,pid,Inter.Interaction.Enter{LiveCommands.sigils(S.Simulation.meta(T.Terrain.simulation(world)))})

def LiveCommands.command(input: LiveCommands.Input,world: T.Terrain.World) -> F.FrameBindings.Command:
  match input:
    case LiveCommands.Hero{pid,op,amount}:
      +pid = pid
      F.FrameBindings.Inventory{pid,op,LiveCommands.near(P.Players.found(P.Players.take(S.Simulation.players(T.Terrain.simulation(world)),pid))),amount}
    case LiveCommands.Act{pid,command}: F.FrameBindings.Interact{pid,command}
    case LiveCommands.Enter{pid}: F.FrameBindings.Interact{pid,Inter.Interaction.Enter{LiveCommands.sigils(S.Simulation.meta(T.Terrain.simulation(world)))}}

def LiveCommands.frame(world: T.Terrain.World) -> T.Terrain.World:
  match world:
    case T.Terrain.World{meta,players,monsters,maps}: T.Terrain.World{meta,Nil{},monsters,maps}

def LiveCommands.emit(-A: Type,+result: LiveCommands.Result,render: LiveCommands.Result -> List<&1,A>) -> T.Terrain.World & List<&1,A>:
  Tuple{LiveCommands.world(result),render(result)}

def LiveCommands.output_world(-A: Type,result: T.Terrain.World & List<&1,A>) -> T.Terrain.World:
  match result:
    case Tuple{world,lines}: world

def LiveCommands.output_lines(-A: Type,result: T.Terrain.World & List<&1,A>) -> List<&1,A>:
  match result:
    case Tuple{world,lines}: lines

law LiveCommands.inventory_frame:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +maps: T.Terrain.Maps
  for +result: I.Inventory.Result
  {LiveCommands.frame(LiveCommands.world(LiveCommands.inventory_result(meta,monsters,maps,result))) == T.Terrain.World{meta,Nil{},monsters,maps} : T.Terrain.World}

def LiveCommands.inventory_frame(meta,monsters,maps,result):
  match result:
    case I.Inventory.Result{players,reply}: {==}

law LiveCommands.interaction_frame:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +maps: T.Terrain.Maps
  for +result: Inter.Interaction.Result
  {LiveCommands.frame(LiveCommands.world(LiveCommands.interaction_result(meta,monsters,maps,result))) == T.Terrain.World{meta,Nil{},monsters,maps} : T.Terrain.World}

def LiveCommands.interaction_frame(meta,monsters,maps,result):
  match result:
    case Inter.Interaction.Result{players,reply}: {==}

law LiveCommands.run_frame:
  for +input: LiveCommands.Input
  for +world: T.Terrain.World
  {LiveCommands.frame(LiveCommands.world(LiveCommands.run(input,world))) == LiveCommands.frame(world) : T.Terrain.World}

def LiveCommands.run_frame(input,world):
  match input:
    case LiveCommands.Hero{pid,op,amount}:
      match world:
        case T.Terrain.World{meta,players,monsters,maps}:
          +taken = P.Players.take(players,pid)
          LiveCommands.inventory_frame(meta,monsters,maps,I.Inventory.apply_taken(taken,op,LiveCommands.near(P.Players.found(taken)),amount))
    case LiveCommands.Act{pid,command}:
      match world:
        case T.Terrain.World{meta,players,monsters,maps}: LiveCommands.interaction_frame(meta,monsters,maps,Inter.Interaction.run(players,pid,command))
    case LiveCommands.Enter{pid}:
      match world:
        case T.Terrain.World{meta,players,monsters,maps}: LiveCommands.interaction_frame(meta,monsters,maps,Inter.Interaction.run(players,pid,Inter.Interaction.Enter{LiveCommands.sigils(meta)}))

law LiveCommands.frame_maps:
  for +world: T.Terrain.World
  {T.Terrain.maps(LiveCommands.frame(world)) == T.Terrain.maps(world) : T.Terrain.Maps}

def LiveCommands.frame_maps(world):
  match world:
    case T.Terrain.World{meta,players,monsters,maps}: {==}

law LiveCommands.frame_meta:
  for +world: T.Terrain.World
  {S.Simulation.meta(T.Terrain.simulation(LiveCommands.frame(world))) == S.Simulation.meta(T.Terrain.simulation(world)) : S.Simulation.Meta}

def LiveCommands.frame_meta(world):
  match world:
    case T.Terrain.World{meta,players,monsters,maps}: {==}

law LiveCommands.run_maps:
  for +input: LiveCommands.Input
  for +world: T.Terrain.World
  {T.Terrain.maps(LiveCommands.world(LiveCommands.run(input,world))) == T.Terrain.maps(world) : T.Terrain.Maps}

def LiveCommands.run_maps(input,world):
  +after = LiveCommands.world(LiveCommands.run(input,world))
  Equal.trans(T.Terrain.Maps,T.Terrain.maps(after),T.Terrain.maps(LiveCommands.frame(after)),T.Terrain.maps(world),Equal.sym(T.Terrain.Maps,T.Terrain.maps(LiveCommands.frame(after)),T.Terrain.maps(after),LiveCommands.frame_maps(after)),Equal.trans(T.Terrain.Maps,T.Terrain.maps(LiveCommands.frame(after)),T.Terrain.maps(LiveCommands.frame(world)),T.Terrain.maps(world),Equal.cong(T.Terrain.World,T.Terrain.Maps,(w => T.Terrain.maps(w)),LiveCommands.frame(after),LiveCommands.frame(world),LiveCommands.run_frame(input,world)),LiveCommands.frame_maps(world)))

law LiveCommands.run_meta:
  for +input: LiveCommands.Input
  for +world: T.Terrain.World
  {S.Simulation.meta(T.Terrain.simulation(LiveCommands.world(LiveCommands.run(input,world)))) == S.Simulation.meta(T.Terrain.simulation(world)) : S.Simulation.Meta}

def LiveCommands.run_meta(input,world):
  +after = LiveCommands.world(LiveCommands.run(input,world))
  Equal.trans(S.Simulation.Meta,S.Simulation.meta(T.Terrain.simulation(after)),S.Simulation.meta(T.Terrain.simulation(LiveCommands.frame(after))),S.Simulation.meta(T.Terrain.simulation(world)),Equal.sym(S.Simulation.Meta,S.Simulation.meta(T.Terrain.simulation(LiveCommands.frame(after))),S.Simulation.meta(T.Terrain.simulation(after)),LiveCommands.frame_meta(after)),Equal.trans(S.Simulation.Meta,S.Simulation.meta(T.Terrain.simulation(LiveCommands.frame(after))),S.Simulation.meta(T.Terrain.simulation(LiveCommands.frame(world))),S.Simulation.meta(T.Terrain.simulation(world)),Equal.cong(T.Terrain.World,S.Simulation.Meta,(w => S.Simulation.meta(T.Terrain.simulation(w))),LiveCommands.frame(after),LiveCommands.frame(world),LiveCommands.run_frame(input,world)),LiveCommands.frame_meta(world)))

law LiveCommands.inventory_simulation:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +maps: T.Terrain.Maps
  for +result: I.Inventory.Result
  {T.Terrain.simulation(LiveCommands.world(LiveCommands.inventory_result(meta,monsters,maps,result))) == S.Simulation.State{meta,I.Inventory.roster(result),monsters} : S.Simulation.State}

def LiveCommands.inventory_simulation(meta,monsters,maps,result):
  match result:
    case I.Inventory.Result{players,reply}: {==}

law LiveCommands.interaction_simulation:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +maps: T.Terrain.Maps
  for +result: Inter.Interaction.Result
  {T.Terrain.simulation(LiveCommands.world(LiveCommands.interaction_result(meta,monsters,maps,result))) == S.Simulation.State{meta,Inter.Interaction.roster(result),monsters} : S.Simulation.State}

def LiveCommands.interaction_simulation(meta,monsters,maps,result):
  match result:
    case Inter.Interaction.Result{players,reply}: {==}

law LiveCommands.refines:
  for +input: LiveCommands.Input
  for +world: T.Terrain.World
  for +maps: T.Terrain.Maps
  {T.Terrain.simulation(LiveCommands.world(LiveCommands.run(input,world))) == Id.PlayerIds.run_change(F.FrameBindings.change(LiveCommands.command(input,world)),T.Terrain.simulation(world),maps) : S.Simulation.State}

def LiveCommands.refines(input,world,maps):
  match input:
    case LiveCommands.Hero{pid,op,amount}:
      match world:
        case T.Terrain.World{meta,players,monsters,tiles}:
          +taken = P.Players.take(players,pid)
          LiveCommands.inventory_simulation(meta,monsters,tiles,I.Inventory.apply_taken(taken,op,LiveCommands.near(P.Players.found(taken)),amount))
    case LiveCommands.Act{pid,command}:
      match world:
        case T.Terrain.World{meta,players,monsters,tiles}: LiveCommands.interaction_simulation(meta,monsters,tiles,Inter.Interaction.run(players,pid,command))
    case LiveCommands.Enter{pid}:
      match world:
        case T.Terrain.World{meta,players,monsters,tiles}: LiveCommands.interaction_simulation(meta,monsters,tiles,Inter.Interaction.run(players,pid,Inter.Interaction.Enter{LiveCommands.sigils(meta)}))

law LiveCommands.seeded:
  for +input: LiveCommands.Input
  for +world: T.Terrain.World
  for +states: List<&2,Sess.Sessions.State>
  for +valid: SW.SeededWorld.OK<world,states>
  SW.SeededWorld.OK<LiveCommands.world(LiveCommands.run(input,world)),states>

def LiveCommands.seeded(input,world,states,valid):
  match valid:
    case SW.SeededWorld.OK{world_ok,maps}:
      +seed = SW.SeededWorld.seed(world)
      SW.SeededWorld.from_external(LiveCommands.world(LiveCommands.run(input,world)),states,seed,Equal.cong(S.Simulation.Meta,U32,(m => CR.ChannelRestart.seed(m)),S.Simulation.meta(T.Terrain.simulation(LiveCommands.world(LiveCommands.run(input,world)))),S.Simulation.meta(T.Terrain.simulation(world)),LiveCommands.run_meta(input,world)),(%Equal.sym(S.Simulation.State,T.Terrain.simulation(LiveCommands.world(LiveCommands.run(input,world))),Id.PlayerIds.run_change(F.FrameBindings.change(LiveCommands.command(input,world)),T.Terrain.simulation(world),L.Landscape.maps(seed)),LiveCommands.refines(input,world,L.Landscape.maps(seed))) : C.Connections.WorldOK<seed,_,states>; F.FrameBindings.run_ok(LiveCommands.command(input,world),seed,K.Creation.Result{T.Terrain.simulation(world),states},world_ok)),Equal.trans(T.Terrain.Maps,T.Terrain.maps(LiveCommands.world(LiveCommands.run(input,world))),T.Terrain.maps(world),L.Landscape.maps(seed),LiveCommands.run_maps(input,world),maps))

law LiveCommands.emit_world:
  for -A: Type
  for +result: LiveCommands.Result
  for render: LiveCommands.Result -> List<&1,A>
  {LiveCommands.output_world(A,LiveCommands.emit(A,result,render)) == LiveCommands.world(result) : T.Terrain.World}

def LiveCommands.emit_world(A,result,render): {==}

law LiveCommands.emit_lines:
  for -A: Type
  for +result: LiveCommands.Result
  for render: LiveCommands.Result -> List<&1,A>
  {LiveCommands.output_lines(A,LiveCommands.emit(A,result,render)) == render(result) : List<&1,A>}

def LiveCommands.emit_lines(A,result,render): {==}

law LiveCommands.run_emitted:
  for -A: Type
  for +input: LiveCommands.Input
  for +world: T.Terrain.World
  for +states: List<&2,Sess.Sessions.State>
  for render: LiveCommands.Result -> List<&1,A>
  for +valid: SW.SeededWorld.OK<world,states>
  SW.SeededWorld.OK<LiveCommands.output_world(A,LiveCommands.emit(A,LiveCommands.run(input,world),render)),states>

def LiveCommands.run_emitted(A,input,world,states,render,valid):
  %Equal.sym(T.Terrain.World,LiveCommands.output_world(A,LiveCommands.emit(A,LiveCommands.run(input,world),render)),LiveCommands.world(LiveCommands.run(input,world)),LiveCommands.emit_world(A,LiveCommands.run(input,world),render)) : SW.SeededWorld.OK<_,states>
  LiveCommands.seeded(input,world,states,valid)

law LiveCommands.inventory_notice:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +maps: T.Terrain.Maps
  for +players: List<&2,P.Players.State>
  for +reply: Maybe<&2,I.Inventory.Reply>
  {LiveCommands.notice(LiveCommands.inventory_result(meta,monsters,maps,I.Inventory.Result{players,reply})) == LiveCommands.Inventory{reply} : LiveCommands.Notice}

def LiveCommands.inventory_notice(meta,monsters,maps,players,reply): {==}

law LiveCommands.interaction_notice:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +maps: T.Terrain.Maps
  for +players: List<&2,P.Players.State>
  for +reply: Maybe<&2,Inter.Interaction.Reply>
  {LiveCommands.notice(LiveCommands.interaction_result(meta,monsters,maps,Inter.Interaction.Result{players,reply})) == LiveCommands.Interaction{reply} : LiveCommands.Notice}

def LiveCommands.interaction_notice(meta,monsters,maps,players,reply): {==}

def LiveCommands.trace(inputs: List<&2,LiveCommands.Input>,world: T.Terrain.World) -> T.Terrain.World:
  match inputs:
    case Nil{}: world
    case Con{head,rest}: LiveCommands.trace(rest,LiveCommands.world(LiveCommands.run(head,world)))

law LiveCommands.trace_seeded:
  for +inputs: List<&2,LiveCommands.Input>
  for +world: T.Terrain.World
  for +states: List<&2,Sess.Sessions.State>
  for +valid: SW.SeededWorld.OK<world,states>
  SW.SeededWorld.OK<LiveCommands.trace(inputs,world),states>

def LiveCommands.trace_seeded(inputs,world,states,valid):
  match inputs:
    case Nil{}: valid
    case Con{head,rest}: LiveCommands.trace_seeded(rest,LiveCommands.world(LiveCommands.run(head,world)),states,LiveCommands.seeded(head,world,states,valid))
