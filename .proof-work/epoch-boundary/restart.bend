# Pure reconstruction and connection rebinding with all correspondence premises
# derived from the old world invariant, for every new world/seed/time.
import Base
import ./players.bend as P
import ./sessions.bend as S
import ./connections.bend as C
import ./bindings.bend as B
import ./rebuild.bend as Rebuild
import ./rebinding.bend as R
import ./restart_profiles.bend as Profiles
import ./reversal.bend as Rev
import ./simulation.bend as Sim
import ./worldstate.bend as W
import ./terrain.bend as T
import ./population.bend as Pop
import ./admission.bend as J
import ./allocation.bend as A
import ./nonzero.bend as NZ

type Restart.Result is Data:
  Restart.Result{world: T.Terrain.World,states: List<&2,S.Sessions.State>}

def Restart.world(result: Restart.Result) -> T.Terrain.World:
  match result:
    case Restart.Result{world,states}: world

def Restart.states(result: Restart.Result) -> List<&2,S.Sessions.State>:
  match result:
    case Restart.Result{world,states}: states

def Restart.OK(seed: U32,+result: Restart.Result) -> Data:
  C.Connections.WorldOK<seed,T.Terrain.simulation(Restart.world(result)),Restart.states(result)>

def Restart.finish(+world: T.Terrain.World,states: List<&2,S.Sessions.State>) -> Restart.Result:
  Restart.Result{world,R.Rebinding.run(states,Sim.Simulation.players(T.Terrain.simulation(world)))}

def Restart.run(before: Sim.Simulation.State,states: List<&2,S.Sessions.State>,world: U32,seed: U32,now: U32) -> Restart.Result:
  Restart.finish(Rebuild.Rebuild.world(Sim.Simulation.players(before),Pop.Population.fresh(world,seed,now)),states)

law Restart.correspondence:
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +states: List<&2,S.Sessions.State>
  for +same: {Rebuild.Rebuild.profiles(after) == Rebuild.Rebuild.reverse_into(before,Nil{}) : List<&2,Rebuild.Rebuild.Profile>}
  for +valid: C.Connections.OK<before,states>
  Profiles.RestartProfiles.Correspondence<after,states>

def Restart.correspondence(before,after,states,same,valid):
  Profiles.RestartProfiles.correspondence(after,Rev.Reversal.into(before,Nil{}),states,Equal.trans(List<&2,Rebuild.Rebuild.Profile>,Rebuild.Rebuild.profiles(after),Rebuild.Rebuild.reverse_into(before,Nil{}),Rebuild.Rebuild.profiles(Rev.Reversal.into(before,Nil{})),same,Equal.sym(List<&2,Rebuild.Rebuild.Profile>,Rebuild.Rebuild.profiles(Rev.Reversal.into(before,Nil{})),Rebuild.Rebuild.reverse_into(before,Nil{}),Rev.Reversal.profiles(before,Nil{}))),B.Bindings.perm_ok(states,Rev.Reversal.into(before,Nil{}),before,Rev.Reversal.roster(before),valid))

law Restart.rebind_proven:
  for +seed: U32
  for +world: Sim.Simulation.State
  for +states: List<&2,S.Sessions.State>
  for +correspondence: Profiles.RestartProfiles.Correspondence<Sim.Simulation.players(world),states>
  for +sessions: C.Connections.All(states)
  for +unique: A.Allocation.Unique(C.Connections.cids(states))
  for +valid: W.WorldState.OK<seed,world>
  C.Connections.WorldOK<seed,world,R.Rebinding.run(states,Sim.Simulation.players(world))>

def Restart.rebind_proven(seed,world,states,correspondence,sessions,unique,valid):
  match correspondence:
    case Profiles.RestartProfiles.Correspondence{targets,reservations}:
      match valid:
        case W.WorldState.OK{health,positions,monsters,players,nonzero,references}:
          match players:
            case J.Admission.Unique{pids,cids}:
              match nonzero:
                case NZ.Nonzero.All{nonzero_pids,nonzero_cids}: C.Connections.WorldOK{W.WorldState.OK{health,positions,monsters,J.Admission.Unique{pids,cids},NZ.Nonzero.All{nonzero_pids,nonzero_cids},references},R.Rebinding.run_ok(Sim.Simulation.players(world),states,targets,reservations,cids,nonzero_pids,sessions,unique)}

law Restart.rebind_world:
  for +seed: U32
  for +world: Sim.Simulation.State
  for +before: List<&2,P.Players.State>
  for +states: List<&2,S.Sessions.State>
  for +same: {Rebuild.Rebuild.profiles(Sim.Simulation.players(world)) == Rebuild.Rebuild.reverse_into(before,Nil{}) : List<&2,Rebuild.Rebuild.Profile>}
  for +connections: C.Connections.OK<before,states>
  for +valid: W.WorldState.OK<seed,world>
  C.Connections.WorldOK<seed,world,R.Rebinding.run(states,Sim.Simulation.players(world))>

def Restart.rebind_world(seed,world,before,states,same,connections,valid):
  match connections:
    case C.Connections.OK{sessions,unique,links,covers}: Restart.rebind_proven(seed,world,states,Restart.correspondence(before,Sim.Simulation.players(world),states,same,C.Connections.OK{sessions,unique,links,covers}),sessions,unique,valid)

law Restart.finish_ok:
  for +seed: U32
  for +world: T.Terrain.World
  for +before: List<&2,P.Players.State>
  for +states: List<&2,S.Sessions.State>
  for +same: {Rebuild.Rebuild.profiles(Sim.Simulation.players(T.Terrain.simulation(world))) == Rebuild.Rebuild.reverse_into(before,Nil{}) : List<&2,Rebuild.Rebuild.Profile>}
  for +connections: C.Connections.OK<before,states>
  for +valid: W.WorldState.OK<seed,T.Terrain.simulation(world)>
  Restart.OK(seed,Restart.finish(world,states))

def Restart.finish_ok(seed,world,before,states,same,connections,valid): Restart.rebind_world(seed,T.Terrain.simulation(world),before,states,same,connections,valid)

# No size bound, assumed successful admission, assumed replacement membership,
# or equality between old/new PIDs is required here.
law Restart.run_ok:
  for +old_seed: U32
  for +before: Sim.Simulation.State
  for +states: List<&2,S.Sessions.State>
  for +world: U32
  for +seed: U32
  for +now: U32
  for +valid: C.Connections.WorldOK<old_seed,before,states>
  Restart.OK(seed,Restart.run(before,states,world,seed,now))

def Restart.run_ok(old_seed,before,states,world,seed,now,valid):
  match valid:
    case C.Connections.WorldOK{world_ok,connections}: Restart.finish_ok(seed,Rebuild.Rebuild.world(Sim.Simulation.players(before),Pop.Population.fresh(world,seed,now)),Sim.Simulation.players(before),states,Rebuild.Rebuild.fresh_profiles(Sim.Simulation.players(before),world,seed,now,Rebuild.Rebuild.from_world(old_seed,before,world_ok)),connections,Rebuild.Rebuild.fresh_world(Sim.Simulation.players(before),world,seed,now))

law Restart.run_maps:
  for +before: Sim.Simulation.State
  for +states: List<&2,S.Sessions.State>
  for +world: U32
  for +seed: U32
  for +now: U32
  {T.Terrain.maps(Restart.world(Restart.run(before,states,world,seed,now))) == T.Terrain.maps(Pop.Population.fresh(world,seed,now)) : T.Terrain.Maps}

def Restart.run_maps(before,states,world,seed,now): Rebuild.Rebuild.world_maps(Sim.Simulation.players(before),Pop.Population.fresh(world,seed,now))

law Restart.run_profiles:
  for +old_seed: U32
  for +before: Sim.Simulation.State
  for +states: List<&2,S.Sessions.State>
  for +world: U32
  for +seed: U32
  for +now: U32
  for +valid: C.Connections.WorldOK<old_seed,before,states>
  {Rebuild.Rebuild.profiles(Sim.Simulation.players(T.Terrain.simulation(Restart.world(Restart.run(before,states,world,seed,now))))) == Rebuild.Rebuild.reverse_into(Sim.Simulation.players(before),Nil{}) : List<&2,Rebuild.Rebuild.Profile>}

def Restart.run_profiles(old_seed,before,states,world,seed,now,valid):
  match valid:
    case C.Connections.WorldOK{world_ok,connections}: Rebuild.Rebuild.fresh_profiles(Sim.Simulation.players(before),world,seed,now,Rebuild.Rebuild.from_world(old_seed,before,world_ok))
