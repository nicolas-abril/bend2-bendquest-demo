# Channel-bearing restart with exact refinement to the complete pure theorem.
import Base
import ./sessions.bend as Sess
import ./rebinding.bend as Rebinding
import ./connection.bend as C
import ./connections.bend as Conn
import ./restart.bend as R
import ./rebuild.bend as Rebuild
import ./simulation.bend as S
import ./terrain.bend as T
import ./population.bend as Pop
import ./landscape.bend as L

type ChannelRestart.Result is Type:
  ChannelRestart.Result{world: T.Terrain.World,connections: List<&1,C.Connection.Record>}

def ChannelRestart.descriptor(result: ChannelRestart.Result) -> R.Restart.Result:
  match result:
    case ChannelRestart.Result{world,connections}: R.Restart.Result{world,C.Connection.descriptors(connections)}

def ChannelRestart.channels(result: ChannelRestart.Result) -> List<&2,Chan<List<&1,Char>>>:
  match result:
    case ChannelRestart.Result{world,connections}: C.Connection.channels(connections)

def ChannelRestart.names(result: ChannelRestart.Result) -> List<&1,List<&1,Char>>:
  match result:
    case ChannelRestart.Result{world,connections}: C.Connection.names(connections)

def ChannelRestart.OK(seed: U32,result: ChannelRestart.Result) -> Data:
  R.Restart.OK(seed,ChannelRestart.descriptor(result))

def ChannelRestart.finish(+world: T.Terrain.World,connections: List<&1,C.Connection.Record>) -> ChannelRestart.Result:
  ChannelRestart.Result{world,C.Connection.rebind(connections,S.Simulation.players(T.Terrain.simulation(world)))}

def ChannelRestart.run(before: S.Simulation.State,connections: List<&1,C.Connection.Record>,world: U32,seed: U32,now: U32) -> ChannelRestart.Result:
  ChannelRestart.finish(Rebuild.Rebuild.world(S.Simulation.players(before),Pop.Population.fresh(world,seed,now)),connections)

law ChannelRestart.finish_refines:
  for +world: T.Terrain.World
  for connections: List<&1,C.Connection.Record>
  {ChannelRestart.descriptor(ChannelRestart.finish(world,connections)) == R.Restart.finish(world,C.Connection.descriptors(connections)) : R.Restart.Result}

def ChannelRestart.finish_refines(world,connections):
  %C.Connection.rebind_descriptors(connections,S.Simulation.players(T.Terrain.simulation(world))) : {R.Restart.Result{world,C.Connection.descriptors(C.Connection.rebind(connections,S.Simulation.players(T.Terrain.simulation(world))))} == R.Restart.Result{world,_} : R.Restart.Result}
  {==}

law ChannelRestart.run_refines:
  for +before: S.Simulation.State
  for connections: List<&1,C.Connection.Record>
  for +world: U32
  for +seed: U32
  for +now: U32
  {ChannelRestart.descriptor(ChannelRestart.run(before,connections,world,seed,now)) == R.Restart.run(before,C.Connection.descriptors(connections),world,seed,now) : R.Restart.Result}

def ChannelRestart.run_refines(before,connections,world,seed,now): ChannelRestart.finish_refines(Rebuild.Rebuild.world(S.Simulation.players(before),Pop.Population.fresh(world,seed,now)),connections)

law ChannelRestart.run_with_view:
  for +old_seed: U32
  for +before: S.Simulation.State
  for -connections: List<&1,C.Connection.Record>
  for +world: U32
  for +seed: U32
  for +now: U32
  for +view: C.Connection.Rebound<connections,S.Simulation.players(T.Terrain.simulation(Rebuild.Rebuild.world(S.Simulation.players(before),Pop.Population.fresh(world,seed,now))))>
  for +valid: Conn.Connections.WorldOK<old_seed,before,C.Connection.descriptors(connections)>
  ChannelRestart.OK(seed,ChannelRestart.run(before,connections,world,seed,now))

def ChannelRestart.run_with_view(old_seed,before,connections,world,seed,now,view,valid):
  match view:
    case C.Connection.Rebound{states,old_descriptors,new_descriptors}:
      +rebuilt = Rebuild.Rebuild.world(S.Simulation.players(before),Pop.Population.fresh(world,seed,now))
      %Equal.sym(List<&2,Sess.Sessions.State>,C.Connection.descriptors(C.Connection.rebind(connections,S.Simulation.players(T.Terrain.simulation(rebuilt)))),Rebinding.Rebinding.run(states,S.Simulation.players(T.Terrain.simulation(rebuilt))),new_descriptors) : R.Restart.OK(seed,R.Restart.Result{rebuilt,_})
      R.Restart.run_ok(old_seed,before,states,world,seed,now,(%old_descriptors : Conn.Connections.WorldOK<old_seed,before,_>; valid))

law ChannelRestart.run_ok:
  for +old_seed: U32
  for +before: S.Simulation.State
  for connections: List<&1,C.Connection.Record>
  for +world: U32
  for +seed: U32
  for +now: U32
  for +valid: Conn.Connections.WorldOK<old_seed,before,C.Connection.descriptors(connections)>
  ChannelRestart.OK(seed,ChannelRestart.run(before,connections,world,seed,now))

def ChannelRestart.run_ok(old_seed,before,connections,world,seed,now,valid): ChannelRestart.run_with_view(old_seed,before,connections,world,seed,now,C.Connection.describe(connections,S.Simulation.players(T.Terrain.simulation(Rebuild.Rebuild.world(S.Simulation.players(before),Pop.Population.fresh(world,seed,now))))),valid)

law ChannelRestart.run_channels:
  for +before: S.Simulation.State
  for connections: List<&1,C.Connection.Record>
  for +world: U32
  for +seed: U32
  for +now: U32
  {ChannelRestart.channels(ChannelRestart.run(before,connections,world,seed,now)) == C.Connection.channels(connections) : List<&2,Chan<List<&1,Char>>>}

def ChannelRestart.run_channels(before,connections,world,seed,now): C.Connection.rebind_channels(connections,S.Simulation.players(T.Terrain.simulation(Rebuild.Rebuild.world(S.Simulation.players(before),Pop.Population.fresh(world,seed,now)))))

law ChannelRestart.run_names:
  for +before: S.Simulation.State
  for connections: List<&1,C.Connection.Record>
  for +world: U32
  for +seed: U32
  for +now: U32
  {ChannelRestart.names(ChannelRestart.run(before,connections,world,seed,now)) == C.Connection.names(connections) : List<&1,List<&1,Char>>}

def ChannelRestart.run_names(before,connections,world,seed,now): C.Connection.rebind_names(connections,S.Simulation.players(T.Terrain.simulation(Rebuild.Rebuild.world(S.Simulation.players(before),Pop.Population.fresh(world,seed,now)))))

# These are the server's actual next-world inputs, including U32 world wrap.
def ChannelRestart.number(meta: S.Simulation.Meta) -> U32:
  match meta:
    case S.Simulation.Meta{phase,world,seed,tick,started,now,sigils,fame,next_player,next_monster}: world

def ChannelRestart.seed(meta: S.Simulation.Meta) -> U32:
  match meta:
    case S.Simulation.Meta{phase,world,seed,tick,started,now,sigils,fame,next_player,next_monster}: seed

def ChannelRestart.now(meta: S.Simulation.Meta) -> U32:
  match meta:
    case S.Simulation.Meta{phase,world,seed,tick,started,now,sigils,fame,next_player,next_monster}: now

def ChannelRestart.next_seed(+before: S.Simulation.State) -> U32:
  L.Landscape.hash(ChannelRestart.seed(S.Simulation.meta(before)),ChannelRestart.now(S.Simulation.meta(before)))

def ChannelRestart.restart(+before: S.Simulation.State,connections: List<&1,C.Connection.Record>) -> ChannelRestart.Result:
  ChannelRestart.run(before,connections,U32.add(ChannelRestart.number(S.Simulation.meta(before)),1),ChannelRestart.next_seed(before),ChannelRestart.now(S.Simulation.meta(before)))

law ChannelRestart.restart_refines:
  for +before: S.Simulation.State
  for connections: List<&1,C.Connection.Record>
  {ChannelRestart.descriptor(ChannelRestart.restart(before,connections)) == R.Restart.run(before,C.Connection.descriptors(connections),U32.add(ChannelRestart.number(S.Simulation.meta(before)),1),ChannelRestart.next_seed(before),ChannelRestart.now(S.Simulation.meta(before))) : R.Restart.Result}

def ChannelRestart.restart_refines(before,connections): ChannelRestart.run_refines(before,connections,U32.add(ChannelRestart.number(S.Simulation.meta(before)),1),ChannelRestart.next_seed(before),ChannelRestart.now(S.Simulation.meta(before)))

law ChannelRestart.restart_ok:
  for +old_seed: U32
  for +before: S.Simulation.State
  for connections: List<&1,C.Connection.Record>
  for +valid: Conn.Connections.WorldOK<old_seed,before,C.Connection.descriptors(connections)>
  ChannelRestart.OK(ChannelRestart.next_seed(before),ChannelRestart.restart(before,connections))

def ChannelRestart.restart_ok(old_seed,before,connections,valid): ChannelRestart.run_ok(old_seed,before,connections,U32.add(ChannelRestart.number(S.Simulation.meta(before)),1),ChannelRestart.next_seed(before),ChannelRestart.now(S.Simulation.meta(before)),valid)

law ChannelRestart.restart_channels:
  for +before: S.Simulation.State
  for connections: List<&1,C.Connection.Record>
  {ChannelRestart.channels(ChannelRestart.restart(before,connections)) == C.Connection.channels(connections) : List<&2,Chan<List<&1,Char>>>}

def ChannelRestart.restart_channels(before,connections): ChannelRestart.run_channels(before,connections,U32.add(ChannelRestart.number(S.Simulation.meta(before)),1),ChannelRestart.next_seed(before),ChannelRestart.now(S.Simulation.meta(before)))

law ChannelRestart.restart_names:
  for +before: S.Simulation.State
  for connections: List<&1,C.Connection.Record>
  {ChannelRestart.names(ChannelRestart.restart(before,connections)) == C.Connection.names(connections) : List<&1,List<&1,Char>>}

def ChannelRestart.restart_names(before,connections): ChannelRestart.run_names(before,connections,U32.add(ChannelRestart.number(S.Simulation.meta(before)),1),ChannelRestart.next_seed(before),ChannelRestart.now(S.Simulation.meta(before)))
