# The actual server clock update preserves rosters, maps and every other field.
import Base
import ./simulation.bend as S
import ./terrain.bend as T
import ./worldstate.bend as W
import ./planning.bend as Plan
import ./connections.bend as C
import ./sessions.bend as Sess
import ./seeded_world.bend as SW
import ./channel_restart.bend as CR
import ./players.bend as P
import ./monsters.bend as M
import ./landscape.bend as L

def WorldClock.meta(meta: S.Simulation.Meta,now: U32) -> S.Simulation.Meta:
  match meta:
    case S.Simulation.Meta{phase,world,seed,tick,started,old_now,sigils,fame,next_player,next_monster}:
      S.Simulation.Meta{phase,world,seed,tick,started,now,sigils,fame,next_player,next_monster}

def WorldClock.state(state: S.Simulation.State,now: U32) -> S.Simulation.State:
  match state:
    case S.Simulation.State{meta,players,monsters}: S.Simulation.State{WorldClock.meta(meta,now),players,monsters}

def WorldClock.set(world: T.Terrain.World,now: U32) -> T.Terrain.World:
  match world:
    case T.Terrain.World{meta,players,monsters,maps}: T.Terrain.World{WorldClock.meta(meta,now),players,monsters,maps}

law WorldClock.exact:
  for +phase: U32
  for +world: U32
  for +seed: U32
  for +tick: U32
  for +started: U32
  for +old_now: U32
  for +sigils: U32
  for +fame: U32
  for +next_player: U32
  for +next_monster: U32
  for +players: List<&2,P.Players.State>
  for +monsters: List<&2,M.Monsters.State>
  for +maps: T.Terrain.Maps
  for +now: U32
  {WorldClock.set(T.Terrain.World{S.Simulation.Meta{phase,world,seed,tick,started,old_now,sigils,fame,next_player,next_monster},players,monsters,maps},now) == T.Terrain.World{S.Simulation.Meta{phase,world,seed,tick,started,now,sigils,fame,next_player,next_monster},players,monsters,maps} : T.Terrain.World}

def WorldClock.exact(phase,world,seed,tick,started,old_now,sigils,fame,next_player,next_monster,players,monsters,maps,now): {==}

law WorldClock.meta_seed:
  for +meta: S.Simulation.Meta
  for +now: U32
  {CR.ChannelRestart.seed(WorldClock.meta(meta,now)) == CR.ChannelRestart.seed(meta) : U32}

def WorldClock.meta_seed(meta,now):
  match meta:
    case S.Simulation.Meta{phase,world,seed,tick,started,old_now,sigils,fame,next_player,next_monster}: {==}

law WorldClock.meta_now:
  for +meta: S.Simulation.Meta
  for +now: U32
  {CR.ChannelRestart.now(WorldClock.meta(meta,now)) == now : U32}

def WorldClock.meta_now(meta,now):
  match meta:
    case S.Simulation.Meta{phase,world,seed,tick,started,old_now,sigils,fame,next_player,next_monster}: {==}

law WorldClock.state_seed:
  for +state: S.Simulation.State
  for +now: U32
  {CR.ChannelRestart.seed(S.Simulation.meta(WorldClock.state(state,now))) == CR.ChannelRestart.seed(S.Simulation.meta(state)) : U32}

def WorldClock.state_seed(state,now):
  match state:
    case S.Simulation.State{meta,players,monsters}: WorldClock.meta_seed(meta,now)

law WorldClock.simulation:
  for +world: T.Terrain.World
  for +now: U32
  {T.Terrain.simulation(WorldClock.set(world,now)) == WorldClock.state(T.Terrain.simulation(world),now) : S.Simulation.State}

def WorldClock.simulation(world,now):
  match world:
    case T.Terrain.World{meta,players,monsters,maps}: {==}

law WorldClock.maps:
  for +world: T.Terrain.World
  for +now: U32
  {T.Terrain.maps(WorldClock.set(world,now)) == T.Terrain.maps(world) : T.Terrain.Maps}

def WorldClock.maps(world,now):
  match world:
    case T.Terrain.World{meta,players,monsters,maps}: {==}

law WorldClock.seed:
  for +world: T.Terrain.World
  for +now: U32
  {SW.SeededWorld.seed(WorldClock.set(world,now)) == SW.SeededWorld.seed(world) : U32}

def WorldClock.seed(world,now):
  match world:
    case T.Terrain.World{meta,players,monsters,maps}: WorldClock.meta_seed(meta,now)

law WorldClock.overwrite:
  for +world: T.Terrain.World
  for +first: U32
  for +last: U32
  {WorldClock.set(WorldClock.set(world,first),last) == WorldClock.set(world,last) : T.Terrain.World}

def WorldClock.overwrite(world,first,last):
  match world:
    case T.Terrain.World{meta,players,monsters,maps}:
      match meta:
        case S.Simulation.Meta{phase,number,seed,tick,started,old_now,sigils,fame,next_player,next_monster}: {==}

law WorldClock.unchanged:
  for +world: T.Terrain.World
  {WorldClock.set(world,CR.ChannelRestart.now(S.Simulation.meta(T.Terrain.simulation(world)))) == world : T.Terrain.World}

def WorldClock.unchanged(world):
  match world:
    case T.Terrain.World{meta,players,monsters,maps}:
      match meta:
        case S.Simulation.Meta{phase,number,seed,tick,started,now,sigils,fame,next_player,next_monster}: {==}

law WorldClock.state_ok:
  for +seed: U32
  for +state: S.Simulation.State
  for +now: U32
  for +valid: W.WorldState.OK<seed,state>
  W.WorldState.OK<seed,WorldClock.state(state,now)>

def WorldClock.state_ok(seed,state,now,valid):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      match valid:
        case W.WorldState.OK{health,positions,mids,pids,nonzero,references}:
          match health:
            case S.Simulation.OK{ps,ms,zs}:
              match positions:
                case Plan.Planning.Positions{players_on,monsters_on}: W.WorldState.OK{S.Simulation.OK{ps,ms,zs},Plan.Planning.Positions{players_on,monsters_on},mids,pids,nonzero,references}

law WorldClock.connections:
  for +seed: U32
  for +state: S.Simulation.State
  for +now: U32
  for -states: List<&2,Sess.Sessions.State>
  for +valid: C.Connections.WorldOK<seed,state,states>
  C.Connections.WorldOK<seed,WorldClock.state(state,now),states>

def WorldClock.connections(seed,state,now,states,valid):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      match valid:
        case C.Connections.WorldOK{world,connections}: C.Connections.WorldOK{WorldClock.state_ok(seed,S.Simulation.State{meta,players,monsters},now,world),connections}

law WorldClock.seeded:
  for +world: T.Terrain.World
  for +now: U32
  for -states: List<&2,Sess.Sessions.State>
  for +valid: SW.SeededWorld.OK<world,states>
  SW.SeededWorld.OK<WorldClock.set(world,now),states>

def WorldClock.seeded(world,now,states,valid):
  match valid:
    case SW.SeededWorld.OK{world_ok,maps}:
      SW.SeededWorld.from_external(WorldClock.set(world,now),states,SW.SeededWorld.seed(world),WorldClock.seed(world,now),(%Equal.sym(S.Simulation.State,T.Terrain.simulation(WorldClock.set(world,now)),WorldClock.state(T.Terrain.simulation(world),now),WorldClock.simulation(world,now)) : C.Connections.WorldOK<SW.SeededWorld.seed(world),_,states>; WorldClock.connections(SW.SeededWorld.seed(world),T.Terrain.simulation(world),now,states,world_ok)),Equal.trans(T.Terrain.Maps,T.Terrain.maps(WorldClock.set(world,now)),T.Terrain.maps(world),L.Landscape.maps(SW.SeededWorld.seed(world)),WorldClock.maps(world,now),maps))
