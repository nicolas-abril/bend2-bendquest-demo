# Joint disconnection: remove the selected connection and its bound player.
import Base
import ./player_membership.bend as PM
import ./connections.bend as C
import ./selection.bend as Q
import ./creation.bend as K
import ./sessions.bend as S
import ./players.bend as P
import ./targeting.bend as T
import ./admission.bend as J
import ./allocation.bend as A
import ./playerids.bend as Id
import ./identity.bend as I
import ./references.bend as R
import ./worldstate.bend as W
import ./nonzero.bend as NZ
import ./simulation.bend as Sim
import ./population.bend as Pop
import ./terrain.bend as Terrain

# A retained player cannot use the departing session as its reverse witness.
law Disconnect.drop_present:
  for +player: P.Players.State
  for +head: S.Sessions.State
  for +others: List<&2,S.Sessions.State>
  for +different: {U32.is_eq(P.Players.id(player),S.Sessions.pid(head)) == False{} : Bool}
  for +present: C.Connections.Present<player,Con{head,others}>
  C.Connections.Present<player,others>

def Disconnect.drop_present(player,head,others,different,present):
  match present:
    case C.Connections.Present{session,inside,positive,cid,pid,name}:
      match inside:
        case C.Connections.Here{rest,shape}:
          Empty.absurd(C.Connections.Present<player,others>,PM.PlayerMembership.eq_ne(P.Players.id(player),S.Sessions.pid(head),Equal.sym(U32,S.Sessions.pid(head),P.Players.id(player),Equal.trans(U32,S.Sessions.pid(head),S.Sessions.pid(session),P.Players.id(player),Equal.cong(S.Sessions.State,U32,(s => S.Sessions.pid(s)),head,session,C.Connections.cons_head(head,session,others,rest,shape)),pid)),different))
        case C.Connections.There{before,rest,shape,later}: C.Connections.Present{session,(%Equal.sym(List<&2,S.Sessions.State>,others,rest,C.Connections.cons_tail(head,before,others,rest,shape)) : C.Connections.In<session,_>; later),positive,cid,pid,name}

law Disconnect.covers_gate:
  for +matches: Bool
  for +player: P.Players.State
  for +rest: List<&2,P.Players.State>
  for +head: S.Sessions.State
  for +others: List<&2,S.Sessions.State>
  for +decision: {U32.is_eq(P.Players.id(player),S.Sessions.pid(head)) == matches : Bool}
  for +present: C.Connections.Present<player,Con{head,others}>
  for +covers: C.Connections.Covers(others,rest)
  C.Connections.Covers(others,PM.PlayerMembership.filter_gate(matches,player,rest))

def Disconnect.covers_gate(matches,player,rest,head,others,decision,present,covers):
  match matches:
    case True{}: covers
    case False{}: Tuple{Disconnect.drop_present(player,head,others,decision,present),covers}

law Disconnect.filter_covers:
  for +players: List<&2,P.Players.State>
  for +head: S.Sessions.State
  for +others: List<&2,S.Sessions.State>
  for +covers: C.Connections.Covers(Con{head,others},players)
  C.Connections.Covers(others,PM.PlayerMembership.filter(players,S.Sessions.pid(head)))

def Disconnect.filter_covers(players,head,others,covers):
  match players:
    case Nil{}: Unit{}
    case Con{player,rest}:
      match covers:
        case Tuple{first,later}: Disconnect.covers_gate(U32.is_eq(P.Players.id(player),S.Sessions.pid(head)),player,PM.PlayerMembership.filter(rest,S.Sessions.pid(head)),head,others,{==},first,Disconnect.filter_covers(rest,head,others,later))

# Unique player IDs and distinct CIDs separate every other bound session.
law Disconnect.other_pid:
  for +players: List<&2,P.Players.State>
  for +head: S.Sessions.State
  for +other: S.Sessions.State
  for +head_link: C.Connections.Link<players,head>
  for +actual: P.Players.State
  for +inside: T.Targeting.In<actual,players>
  for +positive: {U32.is_eq(S.Sessions.pid(other),0) == False{} : Bool}
  for +cid: {S.Sessions.cid(other) == J.Admission.cid(actual) : U32}
  for +pid: {S.Sessions.pid(other) == P.Players.id(actual) : U32}
  for +different: {U32.is_eq(S.Sessions.cid(head),S.Sessions.cid(other)) == False{} : Bool}
  for +unique: A.Allocation.Unique(Id.PlayerIds.project(Id.PlayerIds.Player{},players))
  {U32.is_eq(S.Sessions.pid(other),S.Sessions.pid(head)) == False{} : Bool}

def Disconnect.other_pid(players,head,other,head_link,actual,inside,positive,cid,pid,different,unique):
  match head_link:
    case C.Connections.Waiting{unbound,unused}:
      %Equal.sym(U32,S.Sessions.pid(head),0,unbound) : {U32.is_eq(S.Sessions.pid(other),_) == False{} : Bool}
      positive
    case C.Connections.Playing{departing,member,bound,head_cid,head_pid,name}:
      %Equal.sym(U32,S.Sessions.pid(other),P.Players.id(actual),pid) : {U32.is_eq(_,S.Sessions.pid(head)) == False{} : Bool}
      %Equal.sym(U32,S.Sessions.pid(head),P.Players.id(departing),head_pid) : {U32.is_eq(P.Players.id(actual),_) == False{} : Bool}
      PM.PlayerMembership.different_pid(actual,departing,players,inside,member,unique,(%head_cid : {U32.is_eq(J.Admission.cid(actual),_) == False{} : Bool}; (%cid : {U32.is_eq(_,S.Sessions.cid(head)) == False{} : Bool}; I.Identity.neq_sym(S.Sessions.cid(head),S.Sessions.cid(other),different))))

law Disconnect.other_link:
  for +players: List<&2,P.Players.State>
  for +head: S.Sessions.State
  for +other: S.Sessions.State
  for +head_link: C.Connections.Link<players,head>
  for +linked: C.Connections.Link<players,other>
  for +different: {U32.is_eq(S.Sessions.cid(head),S.Sessions.cid(other)) == False{} : Bool}
  for +unique: A.Allocation.Unique(Id.PlayerIds.project(Id.PlayerIds.Player{},players))
  C.Connections.Link<PM.PlayerMembership.filter(players,S.Sessions.pid(head)),other>

def Disconnect.other_link(players,head,other,head_link,linked,different,unique):
  match linked:
    case C.Connections.Waiting{unbound,unused}:
      C.Connections.Waiting{unbound,(%Id.PlayerIds.connection_projection(PM.PlayerMembership.filter(players,S.Sessions.pid(head))) : A.Allocation.Absent(S.Sessions.cid(other),_); PM.PlayerMembership.filter_absence(players,Id.PlayerIds.Connection{},S.Sessions.pid(head),S.Sessions.cid(other),(%Equal.sym(A.Allocation.Ids,Id.PlayerIds.project(Id.PlayerIds.Connection{},players),J.Admission.cids(players),Id.PlayerIds.connection_projection(players)) : A.Allocation.Absent(S.Sessions.cid(other),_); unused)))}
    case C.Connections.Playing{actual,inside,positive,cid,pid,name}:
      +actual = actual
      +inside = inside
      +positive = positive
      +cid = cid
      +pid = pid
      C.Connections.Playing{actual,PM.PlayerMembership.filter_member(actual,players,inside,S.Sessions.pid(head),(%pid : {U32.is_eq(_,S.Sessions.pid(head)) == False{} : Bool}; Disconnect.other_pid(players,head,other,head_link,actual,inside,positive,cid,pid,different,unique))),positive,cid,pid,name}

law Disconnect.filter_links:
  for +states: List<&2,S.Sessions.State>
  for +players: List<&2,P.Players.State>
  for +head: S.Sessions.State
  for +head_link: C.Connections.Link<players,head>
  for +unused: A.Allocation.Absent(S.Sessions.cid(head),C.Connections.cids(states))
  for +unique: A.Allocation.Unique(Id.PlayerIds.project(Id.PlayerIds.Player{},players))
  for +links: C.Connections.Links(players,states)
  C.Connections.Links(PM.PlayerMembership.filter(players,S.Sessions.pid(head)),states)

def Disconnect.filter_links(states,players,head,head_link,unused,unique,links):
  match states:
    case Nil{}: Unit{}
    case Con{other,rest}:
      match unused:
        case Tuple{different,later}:
          match links:
            case Tuple{first,tail}: Tuple{Disconnect.other_link(players,head,other,head_link,first,different,unique),Disconnect.filter_links(rest,players,head,head_link,later,unique,tail)}

law Disconnect.filter_ok:
  for +players: List<&2,P.Players.State>
  for +head: S.Sessions.State
  for +others: List<&2,S.Sessions.State>
  for +unique_players: A.Allocation.Unique(Id.PlayerIds.project(Id.PlayerIds.Player{},players))
  for +valid: C.Connections.OK<players,Con{head,others}>
  C.Connections.OK<PM.PlayerMembership.filter(players,S.Sessions.pid(head)),others>

def Disconnect.filter_ok(players,head,others,unique_players,valid):
  match valid:
    case C.Connections.OK{sessions,unique,links,covers}:
      match sessions:
        case Tuple{first,later}:
          match unique:
            case Tuple{unused,tail}:
              match links:
                case Tuple{linked,rest}: C.Connections.OK{later,tail,Disconnect.filter_links(others,players,head,linked,unused,unique_players,rest),Disconnect.filter_covers(players,head,others,covers)}

law Disconnect.removed_players:
  for +world: Sim.Simulation.State
  for +pid: U32
  for +unique: A.Allocation.Unique(Id.PlayerIds.project(Id.PlayerIds.Player{},Sim.Simulation.players(world)))
  {Sim.Simulation.players(R.References.remove_state(world,pid)) == PM.PlayerMembership.filter(Sim.Simulation.players(world),pid) : List<&2,P.Players.State>}

def Disconnect.removed_players(world,pid,unique): Equal.trans(List<&2,P.Players.State>,Sim.Simulation.players(R.References.remove_state(world,pid)),P.Players.others(P.Players.take(Sim.Simulation.players(world),pid)),PM.PlayerMembership.filter(Sim.Simulation.players(world),pid),R.References.remove_players(world,pid),PM.PlayerMembership.take_filter(Sim.Simulation.players(world),pid,unique))

def Disconnect.player_unique(seed: U32,world: Sim.Simulation.State,valid: W.WorldState.OK<seed,world>) -> A.Allocation.Unique(Id.PlayerIds.project(Id.PlayerIds.Player{},Sim.Simulation.players(world))):
  match valid:
    case W.WorldState.OK{health,positions,monsters,players,nonzero,references}: Id.PlayerIds.from_admission(Id.PlayerIds.Player{},Sim.Simulation.players(world),players)

def Disconnect.selected(world: Sim.Simulation.State,head: S.Sessions.State,others: List<&2,S.Sessions.State>) -> K.Creation.Result: K.Creation.Result{R.References.remove_state(world,S.Sessions.pid(head)),others}

law Disconnect.selected_ok:
  for +seed: U32
  for +world: Sim.Simulation.State
  for +head: S.Sessions.State
  for +others: List<&2,S.Sessions.State>
  for +valid: C.Connections.WorldOK<seed,world,Con{head,others}>
  K.Creation.OK(seed,Disconnect.selected(world,head,others))

def Disconnect.selected_ok(seed,world,head,others,valid):
  match valid:
    case C.Connections.WorldOK{world_ok,connections}:
      +world_ok = world_ok
      +unique = Disconnect.player_unique(seed,world,world_ok)
      C.Connections.WorldOK{W.WorldState.remove(seed,world,S.Sessions.pid(head),world_ok),(%Equal.sym(List<&2,P.Players.State>,Sim.Simulation.players(R.References.remove_state(world,S.Sessions.pid(head))),PM.PlayerMembership.filter(Sim.Simulation.players(world),S.Sessions.pid(head)),Disconnect.removed_players(world,S.Sessions.pid(head),unique)) : C.Connections.OK<_,others>; Disconnect.filter_ok(Sim.Simulation.players(world),head,others,unique,connections))}

def Disconnect.taken(taken: Q.Selection.Take,world: Sim.Simulation.State) -> K.Creation.Result:
  match taken:
    case Q.Selection.Take{others,found}:
      match found:
        case None{}: K.Creation.Result{world,others}
        case Some{head}: Disconnect.selected(world,head,others)

def Disconnect.run(world: Sim.Simulation.State,states: List<&2,S.Sessions.State>,cid: U32) -> K.Creation.Result: Disconnect.taken(Q.Selection.take(states,cid),world)

law Disconnect.taken_ok:
  for +taken: Q.Selection.Take
  for +seed: U32
  for +world: Sim.Simulation.State
  for +valid: C.Connections.WorldOK<seed,world,Q.Selection.restore(taken)>
  K.Creation.OK(seed,Disconnect.taken(taken,world))

def Disconnect.taken_ok(taken,seed,world,valid):
  match taken:
    case Q.Selection.Take{others,found}:
      match found:
        case None{}: valid
        case Some{head}: Disconnect.selected_ok(seed,world,head,others,valid)

law Disconnect.run_ok:
  for +seed: U32
  for +world: Sim.Simulation.State
  for +states: List<&2,S.Sessions.State>
  for +cid: U32
  for +valid: C.Connections.WorldOK<seed,world,states>
  K.Creation.OK(seed,Disconnect.run(world,states,cid))

def Disconnect.run_ok(seed,world,states,cid,valid): Disconnect.taken_ok(Q.Selection.take(states,cid),seed,world,Q.Selection.take_world(seed,world,states,cid,valid))

law Disconnect.retained_player:
  for +player: P.Players.State
  for +world: Sim.Simulation.State
  for +target: U32
  for +inside: T.Targeting.In<player,Sim.Simulation.players(world)>
  for +different: {U32.is_eq(P.Players.id(player),target) == False{} : Bool}
  for +unique: A.Allocation.Unique(Id.PlayerIds.project(Id.PlayerIds.Player{},Sim.Simulation.players(world)))
  T.Targeting.In<player,Sim.Simulation.players(R.References.remove_state(world,target))>

def Disconnect.retained_player(player,world,target,inside,different,unique):
  %Equal.sym(List<&2,P.Players.State>,Sim.Simulation.players(R.References.remove_state(world,target)),PM.PlayerMembership.filter(Sim.Simulation.players(world),target),Disconnect.removed_players(world,target,unique)) : T.Targeting.In<player,_>
  PM.PlayerMembership.filter_member(player,Sim.Simulation.players(world),inside,target,different)

law Disconnect.removed_absent:
  for +world: Sim.Simulation.State
  for +target: U32
  for +unique: A.Allocation.Unique(Id.PlayerIds.project(Id.PlayerIds.Player{},Sim.Simulation.players(world)))
  A.Allocation.Absent(target,Id.PlayerIds.project(Id.PlayerIds.Player{},Sim.Simulation.players(R.References.remove_state(world,target))))

def Disconnect.removed_absent(world,target,unique):
  %Equal.sym(List<&2,P.Players.State>,Sim.Simulation.players(R.References.remove_state(world,target)),PM.PlayerMembership.filter(Sim.Simulation.players(world),target),Disconnect.removed_players(world,target,unique)) : A.Allocation.Absent(target,Id.PlayerIds.project(Id.PlayerIds.Player{},_))
  PM.PlayerMembership.filter_no_target(Sim.Simulation.players(world),target)

law Disconnect.zero_world:
  for +seed: U32
  for +world: Sim.Simulation.State
  for +valid: W.WorldState.OK<seed,world>
  {R.References.remove_state(world,0) == world : Sim.Simulation.State}

def Disconnect.zero_world(seed,world,valid):
  match valid:
    case W.WorldState.OK{health,positions,monsters,players,nonzero,references}: R.References.remove_missing(world,0,NZ.Nonzero.zero_missing(Sim.Simulation.players(world),nonzero),references)

law Disconnect.waiting:
  for +seed: U32
  for +world: Sim.Simulation.State
  for +head: S.Sessions.State
  for +others: List<&2,S.Sessions.State>
  for +zero: {S.Sessions.pid(head) == 0 : U32}
  for +valid: W.WorldState.OK<seed,world>
  {Disconnect.selected(world,head,others) == K.Creation.Result{world,others} : K.Creation.Result}

def Disconnect.waiting(seed,world,head,others,zero,valid):
  %Equal.sym(U32,S.Sessions.pid(head),0,zero) : {K.Creation.Result{R.References.remove_state(world,_),others} == K.Creation.Result{world,others} : K.Creation.Result}
  %Disconnect.zero_world(seed,world,valid) : {K.Creation.Result{R.References.remove_state(world,0),others} == K.Creation.Result{_,others} : K.Creation.Result}
  {==}

law Disconnect.missing:
  for +world: Sim.Simulation.State
  for +states: List<&2,S.Sessions.State>
  for +cid: U32
  for +absent: {Q.Selection.has_id(states,cid) == False{} : Bool}
  {Disconnect.run(world,states,cid) == K.Creation.Result{world,states} : K.Creation.Result}

def Disconnect.missing(world,states,cid,absent):
  %Equal.sym(Q.Selection.Take,Q.Selection.take(states,cid),Q.Selection.Take{states,None{}},Q.Selection.take_missing(states,cid,absent)) : {Disconnect.taken(_,world) == K.Creation.Result{world,states} : K.Creation.Result}
  {==}

# Complete connection lifecycle sequences; world commands/ticks remain separate.
type Disconnect.Input is Data:
  Disconnect.Connection{input: K.Creation.Input}
  Disconnect.Gone{cid: U32}

def Disconnect.step(input: Disconnect.Input,result: K.Creation.Result) -> K.Creation.Result:
  match input:
    case Disconnect.Connection{input}: K.Creation.step(input,result)
    case Disconnect.Gone{cid}:
      match result:
        case K.Creation.Result{world,states}: Disconnect.run(world,states,cid)

def Disconnect.trace(inputs: List<&2,Disconnect.Input>,result: K.Creation.Result) -> K.Creation.Result:
  match inputs:
    case Nil{}: result
    case Con{head,rest}: Disconnect.trace(rest,Disconnect.step(head,result))

law Disconnect.step_ok:
  for +input: Disconnect.Input
  for +seed: U32
  for +result: K.Creation.Result
  for +valid: K.Creation.OK(seed,result)
  K.Creation.OK(seed,Disconnect.step(input,result))

def Disconnect.step_ok(input,seed,result,valid):
  match input:
    case Disconnect.Connection{input}: K.Creation.step_ok(input,seed,result,valid)
    case Disconnect.Gone{cid}:
      match result:
        case K.Creation.Result{world,states}: Disconnect.run_ok(seed,world,states,cid,valid)

law Disconnect.trace_ok:
  for +inputs: List<&2,Disconnect.Input>
  for +seed: U32
  for +result: K.Creation.Result
  for +valid: K.Creation.OK(seed,result)
  K.Creation.OK(seed,Disconnect.trace(inputs,result))

def Disconnect.trace_ok(inputs,seed,result,valid):
  match inputs:
    case Nil{}: valid
    case Con{head,rest}: Disconnect.trace_ok(rest,seed,Disconnect.step(head,result),Disconnect.step_ok(head,seed,result,valid))

law Disconnect.fresh_trace:
  for +inputs: List<&2,Disconnect.Input>
  for +world: U32
  for +seed: U32
  for +now: U32
  K.Creation.OK(seed,Disconnect.trace(inputs,K.Creation.Result{Terrain.Terrain.simulation(Pop.Population.fresh(world,seed,now)),Nil{}}))

def Disconnect.fresh_trace(inputs,world,seed,now): Disconnect.trace_ok(inputs,seed,K.Creation.Result{Terrain.Terrain.simulation(Pop.Population.fresh(world,seed,now)),Nil{}},C.Connections.fresh_world(world,seed,now))
