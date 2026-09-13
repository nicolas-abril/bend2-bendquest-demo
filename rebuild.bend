# Successful reconstruction of players through the actual admission function.
import Base
import ./players.bend as P
import ./admission.bend as J
import ./admission_search.bend as AS
import ./id_capacity.bend as IC
import ./allocation.bend as A
import ./allocation_search.bend as Search
import ./playerids.bend as Id
import ./simulation.bend as S
import ./worldstate.bend as W
import ./connections.bend as Conn
import ./landscape.bend as L
import ./terrain.bend as T
import ./population.bend as Pop
import ./nonzero.bend as NZ

type Rebuild.Profile is Data:
  Rebuild.Profile{cid: U32,style: P.Players.Style,name: List<&2,Char>}

def Rebuild.style(player: P.Players.State) -> P.Players.Style:
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}: style

def Rebuild.profile(+player: P.Players.State) -> Rebuild.Profile:
  Rebuild.Profile{J.Admission.cid(player),Rebuild.style(player),Conn.Connections.player_name(player)}

def Rebuild.profiles(players: List<&2,P.Players.State>) -> List<&2,Rebuild.Profile>:
  match players:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{Rebuild.profile(head),Rebuild.profiles(rest)}

def Rebuild.reverse_into(players: List<&2,P.Players.State>,profiles: List<&2,Rebuild.Profile>) -> List<&2,Rebuild.Profile>:
  match players:
    case Nil{}: profiles
    case Con{head,rest}: Rebuild.reverse_into(rest,Con{Rebuild.profile(head),profiles})

def Rebuild.step(state: S.Simulation.State,+player: P.Players.State) -> J.Admission.Result:
  J.Admission.add(state,J.Admission.cid(player),Rebuild.style(player),Conn.Connections.player_name(player))

def Rebuild.run(players: List<&2,P.Players.State>,state: S.Simulation.State) -> S.Simulation.State:
  match players:
    case Nil{}: state
    case Con{head,rest}: Rebuild.run(rest,J.Admission.state(Rebuild.step(state,head)))

def Rebuild.world(players: List<&2,P.Players.State>,world: T.Terrain.World) -> T.Terrain.World:
  match world:
    case T.Terrain.World{meta,roster,monsters,maps}: T.Terrain.world(maps,Rebuild.run(players,S.Simulation.State{meta,roster,monsters}))

type Rebuild.Valid<-players: List<&2,P.Players.State>> is Data:
  Rebuild.Valid{unique: A.Allocation.Unique(J.Admission.cids(players)),nonzero: A.Allocation.Absent(0,J.Admission.cids(players))}

def Rebuild.Separate(left: List<&2,P.Players.State>,+right: List<&2,P.Players.State>) -> Data:
  match left:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,A.Allocation.Absent(J.Admission.cid(head),J.Admission.cids(right)),(absent => Rebuild.Separate(rest,right))>

law Rebuild.empty:
  Rebuild.Valid<Nil{}>

def Rebuild.empty(): Rebuild.Valid{Unit{},Unit{}}

law Rebuild.tail:
  for +head: P.Players.State
  for +rest: List<&2,P.Players.State>
  for +valid: Rebuild.Valid<Con{head,rest}>
  Rebuild.Valid<rest>

def Rebuild.tail(head,rest,valid):
  match valid:
    case Rebuild.Valid{unique,nonzero}: Rebuild.Valid{Id.PlayerIds.unique_tail(J.Admission.cid(head),J.Admission.cids(rest),unique),Id.PlayerIds.absent_tail(0,J.Admission.cid(head),J.Admission.cids(rest),nonzero)}

law Rebuild.head_positive:
  for +head: P.Players.State
  for +rest: List<&2,P.Players.State>
  for +valid: Rebuild.Valid<Con{head,rest}>
  {U32.is_eq(J.Admission.cid(head),0) == False{} : Bool}

def Rebuild.head_positive(head,rest,valid):
  match valid:
    case Rebuild.Valid{unique,nonzero}: Search.AllocationSearch.neq_sym(0,J.Admission.cid(head),Id.PlayerIds.absent_head(0,J.Admission.cid(head),J.Admission.cids(rest),nonzero))

law Rebuild.head_absent:
  for +head: P.Players.State
  for +rest: List<&2,P.Players.State>
  for +valid: Rebuild.Valid<Con{head,rest}>
  A.Allocation.Absent(J.Admission.cid(head),J.Admission.cids(rest))

def Rebuild.head_absent(head,rest,valid):
  match valid:
    case Rebuild.Valid{unique,nonzero}: Id.PlayerIds.unique_head(J.Admission.cid(head),J.Admission.cids(rest),unique)

law Rebuild.separate_empty:
  for +players: List<&2,P.Players.State>
  Rebuild.Separate(players,Nil{})

def Rebuild.separate_empty(players):
  match players:
    case Nil{}: Unit{}
    case Con{head,rest}: Tuple{Unit{},Rebuild.separate_empty(rest)}

def Rebuild.separate_head(head: P.Players.State,rest: List<&2,P.Players.State>,right: List<&2,P.Players.State>,separate: Rebuild.Separate(Con{head,rest},right)) -> A.Allocation.Absent(J.Admission.cid(head),J.Admission.cids(right)):
  match separate:
    case Tuple{first,later}: first

def Rebuild.separate_tail(head: P.Players.State,rest: List<&2,P.Players.State>,right: List<&2,P.Players.State>,separate: Rebuild.Separate(Con{head,rest},right)) -> Rebuild.Separate(rest,right):
  match separate:
    case Tuple{first,later}: later

law Rebuild.separate_cons:
  for +left: List<&2,P.Players.State>
  for +head: P.Players.State
  for +right: List<&2,P.Players.State>
  for +absent: A.Allocation.Absent(J.Admission.cid(head),J.Admission.cids(left))
  for +separate: Rebuild.Separate(left,right)
  Rebuild.Separate(left,Con{head,right})

def Rebuild.separate_cons(left,head,right,absent,separate):
  match left:
    case Nil{}: Unit{}
    case Con{first,rest}:
      match absent:
        case Tuple{different,later}:
          match separate:
            case Tuple{available,tail}: Tuple{Tuple{Search.AllocationSearch.neq_sym(J.Admission.cid(head),J.Admission.cid(first),different),available},Rebuild.separate_cons(rest,head,right,later,tail)}

law Rebuild.spawn_profile:
  for +pid: U32
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  {Rebuild.profile(P.Players.spawn(pid,cid,style,name,L.Landscape.spawn_x,L.Landscape.spawn_y)) == Rebuild.Profile{cid,style,name} : Rebuild.Profile}

def Rebuild.spawn_profile(pid,cid,style,name): {==}

law Rebuild.step_success:
  for +state: S.Simulation.State
  for +player: P.Players.State
  for +valid: Rebuild.Valid<S.Simulation.players(state)>
  for +positive: {U32.is_eq(J.Admission.cid(player),0) == False{} : Bool}
  for +absent: A.Allocation.Absent(J.Admission.cid(player),J.Admission.cids(S.Simulation.players(state)))
  AS.AdmissionSearch.Success<state,J.Admission.cid(player),Rebuild.style(player),Conn.Connections.player_name(player),Rebuild.step(state,player)>

def Rebuild.step_success(state,player,valid,positive,absent):
  match valid:
    case Rebuild.Valid{unique,nonzero}: IC.IdCapacity.admission_available(state,J.Admission.cid(player),Rebuild.style(player),Conn.Connections.player_name(player),unique,nonzero,positive,absent)

law Rebuild.step_players:
  for +state: S.Simulation.State
  for +player: P.Players.State
  for +success: AS.AdmissionSearch.Success<state,J.Admission.cid(player),Rebuild.style(player),Conn.Connections.player_name(player),Rebuild.step(state,player)>
  {S.Simulation.players(J.Admission.state(Rebuild.step(state,player))) == Con{P.Players.spawn(J.Admission.pid(Rebuild.step(state,player)),J.Admission.cid(player),Rebuild.style(player),Conn.Connections.player_name(player),L.Landscape.spawn_x,L.Landscape.spawn_y),S.Simulation.players(state)} : List<&2,P.Players.State>}

def Rebuild.step_players(state,player,success): AS.AdmissionSearch.inserted(state,J.Admission.cid(player),Rebuild.style(player),Conn.Connections.player_name(player),Rebuild.step(state,player),success)

law Rebuild.step_cids:
  for +state: S.Simulation.State
  for +player: P.Players.State
  for +success: AS.AdmissionSearch.Success<state,J.Admission.cid(player),Rebuild.style(player),Conn.Connections.player_name(player),Rebuild.step(state,player)>
  {J.Admission.cids(S.Simulation.players(J.Admission.state(Rebuild.step(state,player)))) == Con{J.Admission.cid(player),J.Admission.cids(S.Simulation.players(state))} : A.Allocation.Ids}

def Rebuild.step_cids(state,player,success): Equal.cong(List<&2,P.Players.State>,A.Allocation.Ids,(ps => J.Admission.cids(ps)),S.Simulation.players(J.Admission.state(Rebuild.step(state,player))),Con{P.Players.spawn(J.Admission.pid(Rebuild.step(state,player)),J.Admission.cid(player),Rebuild.style(player),Conn.Connections.player_name(player),L.Landscape.spawn_x,L.Landscape.spawn_y),S.Simulation.players(state)},Rebuild.step_players(state,player,success))

law Rebuild.step_valid:
  for +state: S.Simulation.State
  for +player: P.Players.State
  for +valid: Rebuild.Valid<S.Simulation.players(state)>
  for +success: AS.AdmissionSearch.Success<state,J.Admission.cid(player),Rebuild.style(player),Conn.Connections.player_name(player),Rebuild.step(state,player)>
  Rebuild.Valid<S.Simulation.players(J.Admission.state(Rebuild.step(state,player)))>

def Rebuild.step_valid(state,player,valid,success):
  match valid:
    case Rebuild.Valid{unique,nonzero}:
      match success:
        case AS.AdmissionSearch.Success{choice,exact,fresh,positive,absent}:
          +success = {AS.AdmissionSearch.Success{choice,exact,fresh,positive,absent} : AS.AdmissionSearch.Success<state,J.Admission.cid(player),Rebuild.style(player),Conn.Connections.player_name(player),Rebuild.step(state,player)>}
          +cids = Rebuild.step_cids(state,player,success)
          Rebuild.Valid{(%Equal.sym(A.Allocation.Ids,J.Admission.cids(S.Simulation.players(J.Admission.state(Rebuild.step(state,player)))),Con{J.Admission.cid(player),J.Admission.cids(S.Simulation.players(state))},cids) : A.Allocation.Unique(_); Tuple{absent,unique}),(%Equal.sym(A.Allocation.Ids,J.Admission.cids(S.Simulation.players(J.Admission.state(Rebuild.step(state,player)))),Con{J.Admission.cid(player),J.Admission.cids(S.Simulation.players(state))},cids) : A.Allocation.Absent(0,_); Tuple{Search.AllocationSearch.neq_sym(J.Admission.cid(player),0,positive),nonzero})}

law Rebuild.step_separate:
  for +left: List<&2,P.Players.State>
  for +state: S.Simulation.State
  for +player: P.Players.State
  for +success: AS.AdmissionSearch.Success<state,J.Admission.cid(player),Rebuild.style(player),Conn.Connections.player_name(player),Rebuild.step(state,player)>
  for +absent: A.Allocation.Absent(J.Admission.cid(player),J.Admission.cids(left))
  for +separate: Rebuild.Separate(left,S.Simulation.players(state))
  Rebuild.Separate(left,S.Simulation.players(J.Admission.state(Rebuild.step(state,player))))

def Rebuild.step_separate(left,state,player,success,absent,separate):
  %Equal.sym(List<&2,P.Players.State>,S.Simulation.players(J.Admission.state(Rebuild.step(state,player))),Con{P.Players.spawn(J.Admission.pid(Rebuild.step(state,player)),J.Admission.cid(player),Rebuild.style(player),Conn.Connections.player_name(player),L.Landscape.spawn_x,L.Landscape.spawn_y),S.Simulation.players(state)},Rebuild.step_players(state,player,success)) : Rebuild.Separate(left,_)
  Rebuild.separate_cons(left,P.Players.spawn(J.Admission.pid(Rebuild.step(state,player)),J.Admission.cid(player),Rebuild.style(player),Conn.Connections.player_name(player),L.Landscape.spawn_x,L.Landscape.spawn_y),S.Simulation.players(state),absent,separate)

law Rebuild.step_profiles:
  for +state: S.Simulation.State
  for +player: P.Players.State
  for +success: AS.AdmissionSearch.Success<state,J.Admission.cid(player),Rebuild.style(player),Conn.Connections.player_name(player),Rebuild.step(state,player)>
  {Rebuild.profiles(S.Simulation.players(J.Admission.state(Rebuild.step(state,player)))) == Con{Rebuild.profile(player),Rebuild.profiles(S.Simulation.players(state))} : List<&2,Rebuild.Profile>}

def Rebuild.step_profiles(state,player,success):
  Equal.cong(List<&2,P.Players.State>,List<&2,Rebuild.Profile>,(ps => Rebuild.profiles(ps)),S.Simulation.players(J.Admission.state(Rebuild.step(state,player))),Con{P.Players.spawn(J.Admission.pid(Rebuild.step(state,player)),J.Admission.cid(player),Rebuild.style(player),Conn.Connections.player_name(player),L.Landscape.spawn_x,L.Landscape.spawn_y),S.Simulation.players(state)},Rebuild.step_players(state,player,success))

law Rebuild.run_profiles:
  for +players: List<&2,P.Players.State>
  for +state: S.Simulation.State
  for +old_valid: Rebuild.Valid<players>
  for +current_valid: Rebuild.Valid<S.Simulation.players(state)>
  for +separate: Rebuild.Separate(players,S.Simulation.players(state))
  {Rebuild.profiles(S.Simulation.players(Rebuild.run(players,state))) == Rebuild.reverse_into(players,Rebuild.profiles(S.Simulation.players(state))) : List<&2,Rebuild.Profile>}

def Rebuild.run_profiles(players,state,old_valid,current_valid,separate):
  match players:
    case Nil{}: {==}
    case Con{head,rest}:
      +success = Rebuild.step_success(state,head,current_valid,Rebuild.head_positive(head,rest,old_valid),Rebuild.separate_head(head,rest,S.Simulation.players(state),separate))
      %Rebuild.step_profiles(state,head,success) : {Rebuild.profiles(S.Simulation.players(Rebuild.run(rest,J.Admission.state(Rebuild.step(state,head))))) == Rebuild.reverse_into(rest,_) : List<&2,Rebuild.Profile>}
      Rebuild.run_profiles(rest,J.Admission.state(Rebuild.step(state,head)),Rebuild.tail(head,rest,old_valid),Rebuild.step_valid(state,head,current_valid,success),Rebuild.step_separate(rest,state,head,success,Rebuild.head_absent(head,rest,old_valid),Rebuild.separate_tail(head,rest,S.Simulation.players(state),separate)))

law Rebuild.run_world:
  for +players: List<&2,P.Players.State>
  for +seed: U32
  for +state: S.Simulation.State
  for +valid: W.WorldState.OK<seed,state>
  W.WorldState.OK<seed,Rebuild.run(players,state)>

def Rebuild.run_world(players,seed,state,valid):
  match players:
    case Nil{}: valid
    case Con{head,rest}: Rebuild.run_world(rest,seed,J.Admission.state(Rebuild.step(state,head)),W.WorldState.add(seed,state,J.Admission.cid(head),Rebuild.style(head),Conn.Connections.player_name(head),valid))

law Rebuild.from_world:
  for +seed: U32
  for +state: S.Simulation.State
  for +valid: W.WorldState.OK<seed,state>
  Rebuild.Valid<S.Simulation.players(state)>

def Rebuild.from_world(seed,state,valid):
  match valid:
    case W.WorldState.OK{health,positions,monsters,players,nonzero,references}:
      match players:
        case J.Admission.Unique{pids,cids}:
          match nonzero:
            case NZ.Nonzero.All{nonzero_pids,nonzero_cids}: Rebuild.Valid{cids,(%Id.PlayerIds.connection_projection(S.Simulation.players(state)) : A.Allocation.Absent(0,_); nonzero_cids)}

law Rebuild.world_simulation:
  for +players: List<&2,P.Players.State>
  for +world: T.Terrain.World
  {T.Terrain.simulation(Rebuild.world(players,world)) == Rebuild.run(players,T.Terrain.simulation(world)) : S.Simulation.State}

def Rebuild.world_simulation(players,world):
  match world:
    case T.Terrain.World{meta,roster,monsters,maps}: T.Terrain.world_simulation(maps,Rebuild.run(players,S.Simulation.State{meta,roster,monsters}))

law Rebuild.world_maps:
  for +players: List<&2,P.Players.State>
  for +world: T.Terrain.World
  {T.Terrain.maps(Rebuild.world(players,world)) == T.Terrain.maps(world) : T.Terrain.Maps}

def Rebuild.world_maps(players,world):
  match world:
    case T.Terrain.World{meta,roster,monsters,maps}: T.Terrain.world_maps(maps,Rebuild.run(players,S.Simulation.State{meta,roster,monsters}))

law Rebuild.fresh_world:
  for +players: List<&2,P.Players.State>
  for +world: U32
  for +seed: U32
  for +now: U32
  W.WorldState.OK<seed,T.Terrain.simulation(Rebuild.world(players,Pop.Population.fresh(world,seed,now)))>

def Rebuild.fresh_world(players,world,seed,now):
  %Equal.sym(S.Simulation.State,T.Terrain.simulation(Rebuild.world(players,Pop.Population.fresh(world,seed,now))),Rebuild.run(players,T.Terrain.simulation(Pop.Population.fresh(world,seed,now))),Rebuild.world_simulation(players,Pop.Population.fresh(world,seed,now))) : W.WorldState.OK<seed,_>
  Rebuild.run_world(players,seed,T.Terrain.simulation(Pop.Population.fresh(world,seed,now)),W.WorldState.fresh(world,seed,now))

law Rebuild.fresh_profiles:
  for +players: List<&2,P.Players.State>
  for +world: U32
  for +seed: U32
  for +now: U32
  for +valid: Rebuild.Valid<players>
  {Rebuild.profiles(S.Simulation.players(T.Terrain.simulation(Rebuild.world(players,Pop.Population.fresh(world,seed,now))))) == Rebuild.reverse_into(players,Nil{}) : List<&2,Rebuild.Profile>}

def Rebuild.fresh_profiles(players,world,seed,now,valid):
  %Equal.sym(S.Simulation.State,T.Terrain.simulation(Rebuild.world(players,Pop.Population.fresh(world,seed,now))),Rebuild.run(players,T.Terrain.simulation(Pop.Population.fresh(world,seed,now))),Rebuild.world_simulation(players,Pop.Population.fresh(world,seed,now))) : {Rebuild.profiles(S.Simulation.players(_)) == Rebuild.reverse_into(players,Nil{}) : List<&2,Rebuild.Profile>}
  Rebuild.run_profiles(players,T.Terrain.simulation(Pop.Population.fresh(world,seed,now)),valid,Rebuild.empty,Rebuild.separate_empty(players))

# The previous server loop went through the legacy text-name adapter for every
# player. Its exact pure operation is equivalent for every state and roster,
# including rejected admissions; no validity premise is needed for refinement.
def Rebuild.legacy_step(state: S.Simulation.State,+player: P.Players.State) -> J.Admission.Result:
  J.Admission.add(state,J.Admission.cid(player),Rebuild.style(player),P.Players.share_name(P.Players.text_name(Conn.Connections.player_name(player))))

def Rebuild.legacy_run(players: List<&2,P.Players.State>,state: S.Simulation.State) -> S.Simulation.State:
  match players:
    case Nil{}: state
    case Con{head,rest}: Rebuild.legacy_run(rest,J.Admission.state(Rebuild.legacy_step(state,head)))

law Rebuild.legacy_step_refines:
  for +state: S.Simulation.State
  for +player: P.Players.State
  {Rebuild.legacy_step(state,player) == Rebuild.step(state,player) : J.Admission.Result}

def Rebuild.legacy_step_refines(state,player):
  %P.Players.name_round_trip(Conn.Connections.player_name(player)) : {Rebuild.legacy_step(state,player) == J.Admission.add(state,J.Admission.cid(player),Rebuild.style(player),_) : J.Admission.Result}
  {==}

law Rebuild.legacy_refines:
  for +players: List<&2,P.Players.State>
  for +state: S.Simulation.State
  {Rebuild.legacy_run(players,state) == Rebuild.run(players,state) : S.Simulation.State}

def Rebuild.legacy_refines(players,state):
  match players:
    case Nil{}: {==}
    case Con{head,rest}:
      %Equal.sym(J.Admission.Result,Rebuild.legacy_step(state,head),Rebuild.step(state,head),Rebuild.legacy_step_refines(state,head)) : {Rebuild.legacy_run(rest,J.Admission.state(_)) == Rebuild.run(rest,J.Admission.state(Rebuild.step(state,head))) : S.Simulation.State}
      Rebuild.legacy_refines(rest,J.Admission.state(Rebuild.step(state,head)))
