# World validity tied to its own stored seed and actual map data.
import Base
import ./terrain.bend as T
import ./simulation.bend as S
import ./landscape.bend as L
import ./population.bend as Pop
import ./sessions.bend as Sess
import ./connections.bend as C
import ./connection.bend as Net
import ./restart.bend as R
import ./rebuild.bend as Rebuild
import ./rebinding.bend as Rebinding
import ./channel_restart.bend as CR
import ./restart_metadata.bend as M

def SeededWorld.seed(world: T.Terrain.World) -> U32:
  CR.ChannelRestart.seed(S.Simulation.meta(T.Terrain.simulation(world)))

type SeededWorld.OK<-world: T.Terrain.World,-states: List<&2,Sess.Sessions.State>> is Data:
  SeededWorld.OK{valid: C.Connections.WorldOK<SeededWorld.seed(world),T.Terrain.simulation(world),states>,maps: {T.Terrain.maps(world) == L.Landscape.maps(SeededWorld.seed(world)) : T.Terrain.Maps}}

def SeededWorld.ChannelOK(result: CR.ChannelRestart.Result) -> Data:
  match result:
    case CR.ChannelRestart.Result{world,connections}: SeededWorld.OK<world,Net.Connection.descriptors(connections)>

law SeededWorld.from_external:
  for +world: T.Terrain.World
  for -states: List<&2,Sess.Sessions.State>
  for +seed: U32
  for +stored: {SeededWorld.seed(world) == seed : U32}
  for +valid: C.Connections.WorldOK<seed,T.Terrain.simulation(world),states>
  for +maps: {T.Terrain.maps(world) == L.Landscape.maps(seed) : T.Terrain.Maps}
  SeededWorld.OK<world,states>

def SeededWorld.from_external(world,states,seed,stored,valid,maps):
  SeededWorld.OK{(%Equal.sym(U32,SeededWorld.seed(world),seed,stored) : C.Connections.WorldOK<_,T.Terrain.simulation(world),states>; valid),(%Equal.sym(U32,SeededWorld.seed(world),seed,stored) : {T.Terrain.maps(world) == L.Landscape.maps(_) : T.Terrain.Maps}; maps)}

law SeededWorld.fresh:
  for +world: U32
  for +seed: U32
  for +now: U32
  SeededWorld.OK<Pop.Population.fresh(world,seed,now),Nil{}>

def SeededWorld.fresh(world,seed,now): SeededWorld.OK{C.Connections.fresh_world(world,seed,now),{==}}

law SeededWorld.reconstructed:
  for +before: T.Terrain.World
  for +states: List<&2,Sess.Sessions.State>
  for +world: U32
  for +seed: U32
  for +now: U32
  for +valid: SeededWorld.OK<before,states>
  SeededWorld.OK<R.Restart.world(R.Restart.run(T.Terrain.simulation(before),states,world,seed,now)),R.Restart.states(R.Restart.run(T.Terrain.simulation(before),states,world,seed,now))>

def SeededWorld.reconstructed(before,states,world,seed,now,valid):
  match valid:
    case SeededWorld.OK{world_ok,maps}:
      SeededWorld.from_external(Rebuild.Rebuild.world(S.Simulation.players(T.Terrain.simulation(before)),Pop.Population.fresh(world,seed,now)),R.Restart.states(R.Restart.run(T.Terrain.simulation(before),states,world,seed,now)),seed,M.RestartMetadata.fresh_seed(S.Simulation.players(T.Terrain.simulation(before)),world,seed,now),R.Restart.run_ok(SeededWorld.seed(before),T.Terrain.simulation(before),states,world,seed,now,world_ok),M.RestartMetadata.fresh_maps(S.Simulation.players(T.Terrain.simulation(before)),world,seed,now))

# The affine connection roster is consumed once, by the checked restart proof.
# Descriptor/map occurrences in the remaining proof indices are erased.
law SeededWorld.channel_run:
  for +before: T.Terrain.World
  for connections: List<&1,Net.Connection.Record>
  for +world: U32
  for +seed: U32
  for +now: U32
  for +valid: SeededWorld.OK<before,Net.Connection.descriptors(connections)>
  SeededWorld.ChannelOK(CR.ChannelRestart.run(T.Terrain.simulation(before),connections,world,seed,now))

def SeededWorld.channel_run(before,connections,world,seed,now,valid):
  match valid:
    case SeededWorld.OK{world_ok,maps}:
      +rebuilt = Rebuild.Rebuild.world(S.Simulation.players(T.Terrain.simulation(before)),Pop.Population.fresh(world,seed,now))
      SeededWorld.from_external(rebuilt,Net.Connection.descriptors(Net.Connection.rebind(connections,S.Simulation.players(T.Terrain.simulation(rebuilt)))),seed,M.RestartMetadata.fresh_seed(S.Simulation.players(T.Terrain.simulation(before)),world,seed,now),CR.ChannelRestart.run_ok(SeededWorld.seed(before),T.Terrain.simulation(before),connections,world,seed,now,world_ok),M.RestartMetadata.fresh_maps(S.Simulation.players(T.Terrain.simulation(before)),world,seed,now))

law SeededWorld.channel_restart:
  for +before: T.Terrain.World
  for connections: List<&1,Net.Connection.Record>
  for +valid: SeededWorld.OK<before,Net.Connection.descriptors(connections)>
  SeededWorld.ChannelOK(CR.ChannelRestart.restart(T.Terrain.simulation(before),connections))

def SeededWorld.channel_restart(before,connections,valid): SeededWorld.channel_run(before,connections,U32.add(CR.ChannelRestart.number(S.Simulation.meta(T.Terrain.simulation(before))),1),CR.ChannelRestart.next_seed(T.Terrain.simulation(before)),CR.ChannelRestart.now(S.Simulation.meta(T.Terrain.simulation(before))),valid)
