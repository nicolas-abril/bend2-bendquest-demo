# World metadata and map-seed agreement through actual reconstruction.
import Base
import ./terrain.bend as T
import ./population.bend as Pop
import ./landscape.bend as L
import ./channel_restart.bend as CR
import ./simulation.bend as S
import ./admission.bend as J
import ./allocation.bend as A
import ./players.bend as P
import ./rebuild.bend as R
import ./connections.bend as C

def RestartMetadata.frame(meta: S.Simulation.Meta) -> S.Simulation.Meta:
  match meta:
    case S.Simulation.Meta{phase,world,seed,tick,started,now,sigils,fame,next_player,next_monster}: S.Simulation.Meta{phase,world,seed,tick,started,now,sigils,fame,0,next_monster}

law RestartMetadata.advance:
  for +meta: S.Simulation.Meta
  for +next: U32
  {RestartMetadata.frame(J.Admission.advance(meta,next)) == RestartMetadata.frame(meta) : S.Simulation.Meta}

def RestartMetadata.advance(meta,next):
  match meta:
    case S.Simulation.Meta{phase,world,seed,tick,started,now,sigils,fame,next_player,next_monster}: {==}

law RestartMetadata.commit:
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +choice: A.Allocation.Choice
  {RestartMetadata.frame(S.Simulation.meta(J.Admission.state(J.Admission.commit(state,cid,style,name,choice)))) == RestartMetadata.frame(S.Simulation.meta(state)) : S.Simulation.Meta}

def RestartMetadata.commit(state,cid,style,name,choice):
  match state:
    case S.Simulation.State{meta,players,monsters}: RestartMetadata.advance(meta,A.Allocation.cursor(choice))

law RestartMetadata.choose:
  for +result: Maybe<&2,A.Allocation.Choice>
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  {RestartMetadata.frame(S.Simulation.meta(J.Admission.state(J.Admission.choose(result,state,cid,style,name)))) == RestartMetadata.frame(S.Simulation.meta(state)) : S.Simulation.Meta}

def RestartMetadata.choose(result,state,cid,style,name):
  match result:
    case None{}: {==}
    case Some{choice}: RestartMetadata.commit(state,cid,style,name,choice)

law RestartMetadata.gate:
  for +reject: Bool
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  {RestartMetadata.frame(S.Simulation.meta(J.Admission.state(J.Admission.gate(reject,state,cid,style,name)))) == RestartMetadata.frame(S.Simulation.meta(state)) : S.Simulation.Meta}

def RestartMetadata.gate(reject,state,cid,style,name):
  match reject:
    case True{}: {==}
    case False{}: RestartMetadata.choose(A.Allocation.find(J.Admission.pids(S.Simulation.players(state)),J.Admission.hint(S.Simulation.meta(state))),state,cid,style,name)

law RestartMetadata.add:
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  {RestartMetadata.frame(S.Simulation.meta(J.Admission.state(J.Admission.add(state,cid,style,name)))) == RestartMetadata.frame(S.Simulation.meta(state)) : S.Simulation.Meta}

def RestartMetadata.add(state,cid,style,name): RestartMetadata.gate(J.Admission.reject(cid,S.Simulation.players(state)),state,cid,style,name)

law RestartMetadata.run:
  for +players: List<&2,P.Players.State>
  for +state: S.Simulation.State
  {RestartMetadata.frame(S.Simulation.meta(R.Rebuild.run(players,state))) == RestartMetadata.frame(S.Simulation.meta(state)) : S.Simulation.Meta}

def RestartMetadata.run(players,state):
  match players:
    case Nil{}: {==}
    case Con{head,rest}: Equal.trans(S.Simulation.Meta,RestartMetadata.frame(S.Simulation.meta(R.Rebuild.run(rest,J.Admission.state(R.Rebuild.step(state,head))))),RestartMetadata.frame(S.Simulation.meta(J.Admission.state(R.Rebuild.step(state,head)))),RestartMetadata.frame(S.Simulation.meta(state)),RestartMetadata.run(rest,J.Admission.state(R.Rebuild.step(state,head))),RestartMetadata.add(state,J.Admission.cid(head),R.Rebuild.style(head),C.Connections.player_name(head)))

law RestartMetadata.world:
  for +players: List<&2,P.Players.State>
  for +world: T.Terrain.World
  {RestartMetadata.frame(S.Simulation.meta(T.Terrain.simulation(R.Rebuild.world(players,world)))) == RestartMetadata.frame(S.Simulation.meta(T.Terrain.simulation(world))) : S.Simulation.Meta}

def RestartMetadata.world(players,world):
  %Equal.sym(S.Simulation.State,T.Terrain.simulation(R.Rebuild.world(players,world)),R.Rebuild.run(players,T.Terrain.simulation(world)),R.Rebuild.world_simulation(players,world)) : {RestartMetadata.frame(S.Simulation.meta(_)) == RestartMetadata.frame(S.Simulation.meta(T.Terrain.simulation(world))) : S.Simulation.Meta}
  RestartMetadata.run(players,T.Terrain.simulation(world))

law RestartMetadata.fresh:
  for +players: List<&2,P.Players.State>
  for +world: U32
  for +seed: U32
  for +now: U32
  {RestartMetadata.frame(S.Simulation.meta(T.Terrain.simulation(R.Rebuild.world(players,Pop.Population.fresh(world,seed,now))))) == S.Simulation.Meta{1,world,seed,0,now,now,0,0,0,400} : S.Simulation.Meta}

def RestartMetadata.fresh(players,world,seed,now): RestartMetadata.world(players,Pop.Population.fresh(world,seed,now))

law RestartMetadata.frame_number:
  for +meta: S.Simulation.Meta
  {CR.ChannelRestart.number(RestartMetadata.frame(meta)) == CR.ChannelRestart.number(meta) : U32}

def RestartMetadata.frame_number(meta):
  match meta:
    case S.Simulation.Meta{phase,world,seed,tick,started,now,sigils,fame,next_player,next_monster}: {==}

law RestartMetadata.fresh_number:
  for +players: List<&2,P.Players.State>
  for +world: U32
  for +seed: U32
  for +now: U32
  {CR.ChannelRestart.number(S.Simulation.meta(T.Terrain.simulation(R.Rebuild.world(players,Pop.Population.fresh(world,seed,now))))) == world : U32}

def RestartMetadata.fresh_number(players,world,seed,now):
  +meta = S.Simulation.meta(T.Terrain.simulation(R.Rebuild.world(players,Pop.Population.fresh(world,seed,now))))
  Equal.trans(U32,CR.ChannelRestart.number(meta),CR.ChannelRestart.number(RestartMetadata.frame(meta)),world,Equal.sym(U32,CR.ChannelRestart.number(RestartMetadata.frame(meta)),CR.ChannelRestart.number(meta),RestartMetadata.frame_number(meta)),Equal.cong(S.Simulation.Meta,U32,(m => CR.ChannelRestart.number(m)),RestartMetadata.frame(meta),S.Simulation.Meta{1,world,seed,0,now,now,0,0,0,400},RestartMetadata.fresh(players,world,seed,now)))

law RestartMetadata.frame_seed:
  for +meta: S.Simulation.Meta
  {CR.ChannelRestart.seed(RestartMetadata.frame(meta)) == CR.ChannelRestart.seed(meta) : U32}

def RestartMetadata.frame_seed(meta):
  match meta:
    case S.Simulation.Meta{phase,world,seed,tick,started,now,sigils,fame,next_player,next_monster}: {==}

law RestartMetadata.fresh_seed:
  for +players: List<&2,P.Players.State>
  for +world: U32
  for +seed: U32
  for +now: U32
  {CR.ChannelRestart.seed(S.Simulation.meta(T.Terrain.simulation(R.Rebuild.world(players,Pop.Population.fresh(world,seed,now))))) == seed : U32}

def RestartMetadata.fresh_seed(players,world,seed,now):
  +meta = S.Simulation.meta(T.Terrain.simulation(R.Rebuild.world(players,Pop.Population.fresh(world,seed,now))))
  Equal.trans(U32,CR.ChannelRestart.seed(meta),CR.ChannelRestart.seed(RestartMetadata.frame(meta)),seed,Equal.sym(U32,CR.ChannelRestart.seed(RestartMetadata.frame(meta)),CR.ChannelRestart.seed(meta),RestartMetadata.frame_seed(meta)),Equal.cong(S.Simulation.Meta,U32,(m => CR.ChannelRestart.seed(m)),RestartMetadata.frame(meta),S.Simulation.Meta{1,world,seed,0,now,now,0,0,0,400},RestartMetadata.fresh(players,world,seed,now)))

law RestartMetadata.frame_now:
  for +meta: S.Simulation.Meta
  {CR.ChannelRestart.now(RestartMetadata.frame(meta)) == CR.ChannelRestart.now(meta) : U32}

def RestartMetadata.frame_now(meta):
  match meta:
    case S.Simulation.Meta{phase,world,seed,tick,started,now,sigils,fame,next_player,next_monster}: {==}

law RestartMetadata.fresh_now:
  for +players: List<&2,P.Players.State>
  for +world: U32
  for +seed: U32
  for +now: U32
  {CR.ChannelRestart.now(S.Simulation.meta(T.Terrain.simulation(R.Rebuild.world(players,Pop.Population.fresh(world,seed,now))))) == now : U32}

def RestartMetadata.fresh_now(players,world,seed,now):
  +meta = S.Simulation.meta(T.Terrain.simulation(R.Rebuild.world(players,Pop.Population.fresh(world,seed,now))))
  Equal.trans(U32,CR.ChannelRestart.now(meta),CR.ChannelRestart.now(RestartMetadata.frame(meta)),now,Equal.sym(U32,CR.ChannelRestart.now(RestartMetadata.frame(meta)),CR.ChannelRestart.now(meta),RestartMetadata.frame_now(meta)),Equal.cong(S.Simulation.Meta,U32,(m => CR.ChannelRestart.now(m)),RestartMetadata.frame(meta),S.Simulation.Meta{1,world,seed,0,now,now,0,0,0,400},RestartMetadata.fresh(players,world,seed,now)))

law RestartMetadata.fresh_maps:
  for +players: List<&2,P.Players.State>
  for +world: U32
  for +seed: U32
  for +now: U32
  {T.Terrain.maps(R.Rebuild.world(players,Pop.Population.fresh(world,seed,now))) == L.Landscape.maps(seed) : T.Terrain.Maps}

def RestartMetadata.fresh_maps(players,world,seed,now): R.Rebuild.world_maps(players,Pop.Population.fresh(world,seed,now))

law RestartMetadata.stored_maps:
  for +players: List<&2,P.Players.State>
  for +world: U32
  for +seed: U32
  for +now: U32
  {T.Terrain.maps(R.Rebuild.world(players,Pop.Population.fresh(world,seed,now))) == L.Landscape.maps(CR.ChannelRestart.seed(S.Simulation.meta(T.Terrain.simulation(R.Rebuild.world(players,Pop.Population.fresh(world,seed,now)))))) : T.Terrain.Maps}

def RestartMetadata.stored_maps(players,world,seed,now):
  %Equal.sym(U32,CR.ChannelRestart.seed(S.Simulation.meta(T.Terrain.simulation(R.Rebuild.world(players,Pop.Population.fresh(world,seed,now))))),seed,RestartMetadata.fresh_seed(players,world,seed,now)) : {T.Terrain.maps(R.Rebuild.world(players,Pop.Population.fresh(world,seed,now))) == L.Landscape.maps(_) : T.Terrain.Maps}
  RestartMetadata.fresh_maps(players,world,seed,now)
