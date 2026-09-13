# Authoritative player creation: fresh player IDs and one player per connection.
import Base
import ./allocation.bend as A
import ./players.bend as P
import ./simulation.bend as S
import ./landscape.bend as L
import ./locomotion.bend as Walk

def Admission.cid(player: P.Players.State) -> U32:
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}: cid

def Admission.pids(players: List<&2,P.Players.State>) -> A.Allocation.Ids:
  match players:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{P.Players.id(head),Admission.pids(rest)}

def Admission.cids(players: List<&2,P.Players.State>) -> A.Allocation.Ids:
  match players:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{Admission.cid(head),Admission.cids(rest)}

type Admission.Unique<-players: List<&2,P.Players.State>> is Data:
  Admission.Unique{pids: A.Allocation.Unique(Admission.pids(players)),connections: A.Allocation.Unique(Admission.cids(players))}

def Admission.hint(meta: S.Simulation.Meta) -> U32:
  match meta:
    case S.Simulation.Meta{phase,world,seed,tick,started,now,sigils,fame,next_player,next_monster}: next_player

def Admission.advance(meta: S.Simulation.Meta,next: U32) -> S.Simulation.Meta:
  match meta:
    case S.Simulation.Meta{phase,world,seed,tick,started,now,sigils,fame,next_player,next_monster}: S.Simulation.Meta{phase,world,seed,tick,started,now,sigils,fame,next,next_monster}

type Admission.Result is Data:
  Admission.Result{state: S.Simulation.State,pid: U32}

def Admission.state(result: Admission.Result) -> S.Simulation.State:
  match result:
    case Admission.Result{state,pid}: state

def Admission.pid(result: Admission.Result) -> U32:
  match result:
    case Admission.Result{state,pid}: pid

def Admission.commit(state: S.Simulation.State,cid: U32,style: P.Players.Style,name: List<&2,Char>,+choice: A.Allocation.Choice) -> Admission.Result:
  match state:
    case S.Simulation.State{meta,players,monsters}:
      +pid = A.Allocation.id(choice)
      Admission.Result{S.Simulation.State{Admission.advance(meta,A.Allocation.cursor(choice)),Con{P.Players.spawn(pid,cid,style,name,L.Landscape.spawn_x,L.Landscape.spawn_y),players},monsters},pid}

def Admission.choose(result: Maybe<&2,A.Allocation.Choice>,state: S.Simulation.State,cid: U32,style: P.Players.Style,name: List<&2,Char>) -> Admission.Result:
  match result:
    case None{}: Admission.Result{state,0}
    case Some{choice}: Admission.commit(state,cid,style,name,choice)

def Admission.reject(+cid: U32,players: List<&2,P.Players.State>) -> Bool:
  Bool.or(U32.is_eq(cid,0),A.Allocation.contains(cid,Admission.cids(players)))

def Admission.gate(reject: Bool,+state: S.Simulation.State,cid: U32,style: P.Players.Style,name: List<&2,Char>) -> Admission.Result:
  match reject:
    case True{}: Admission.Result{state,0}
    case False{}: Admission.choose(A.Allocation.find(Admission.pids(S.Simulation.players(state)),Admission.hint(S.Simulation.meta(state))),state,cid,style,name)

def Admission.add(+state: S.Simulation.State,+cid: U32,style: P.Players.Style,name: List<&2,Char>) -> Admission.Result:
  Admission.gate(Admission.reject(cid,S.Simulation.players(state)),state,cid,style,name)

law Admission.commit_unique:
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +choice: A.Allocation.Choice
  for +fresh: A.Allocation.Fresh<Admission.pids(S.Simulation.players(state)),choice>
  for +available: A.Allocation.Absent(cid,Admission.cids(S.Simulation.players(state)))
  for +valid: Admission.Unique<S.Simulation.players(state)>
  Admission.Unique<S.Simulation.players(Admission.state(Admission.commit(state,cid,style,name,choice)))>

def Admission.commit_unique(state,cid,style,name,choice,fresh,available,valid):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      match valid:
        case Admission.Unique{pids,cids}: Admission.Unique{A.Allocation.extend_unique(Admission.pids(players),choice,fresh,pids),Tuple{available,cids}}

law Admission.choose_unique:
  for +result: Maybe<&2,A.Allocation.Choice>
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +safe: A.Allocation.Safe(Admission.pids(S.Simulation.players(state)),result)
  for +available: A.Allocation.Absent(cid,Admission.cids(S.Simulation.players(state)))
  for +valid: Admission.Unique<S.Simulation.players(state)>
  Admission.Unique<S.Simulation.players(Admission.state(Admission.choose(result,state,cid,style,name)))>

def Admission.choose_unique(result,state,cid,style,name,safe,available,valid):
  match result:
    case None{}: valid
    case Some{choice}: Admission.commit_unique(state,cid,style,name,choice,safe,available,valid)

law Admission.gate_unique:
  for +reject: Bool
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +decision: {Admission.reject(cid,S.Simulation.players(state)) == reject : Bool}
  for +valid: Admission.Unique<S.Simulation.players(state)>
  Admission.Unique<S.Simulation.players(Admission.state(Admission.gate(reject,state,cid,style,name)))>

def Admission.gate_unique(reject,state,cid,style,name,decision,valid):
  match reject:
    case True{}: valid
    case False{}:
      +ids = Admission.pids(S.Simulation.players(state))
      +hint = Admission.hint(S.Simulation.meta(state))
      +parts = A.Allocation.or_false(U32.is_eq(cid,0),A.Allocation.contains(cid,Admission.cids(S.Simulation.players(state))),decision)
      Admission.choose_unique(A.Allocation.find(ids,hint),state,cid,style,name,A.Allocation.find_safe(ids,hint),A.Allocation.contains_absent(Admission.cids(S.Simulation.players(state)),cid,A.Allocation.false_right(U32.is_eq(cid,0),A.Allocation.contains(cid,Admission.cids(S.Simulation.players(state))),parts)),valid)

law Admission.add_unique:
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +valid: Admission.Unique<S.Simulation.players(state)>
  Admission.Unique<S.Simulation.players(Admission.state(Admission.add(state,cid,style,name)))>

def Admission.add_unique(state,cid,style,name,valid):
  Admission.gate_unique(Admission.reject(cid,S.Simulation.players(state)),state,cid,style,name,{==},valid)

law Admission.commit_ok:
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +choice: A.Allocation.Choice
  for +valid: S.Simulation.OK<state>
  S.Simulation.OK<Admission.state(Admission.commit(state,cid,style,name,choice))>

def Admission.commit_ok(state,cid,style,name,choice,valid):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      match valid:
        case S.Simulation.OK{ps,ms,zs}: S.Simulation.OK{Tuple{P.Players.spawn_ok(A.Allocation.id(choice),cid,style,name,L.Landscape.spawn_x,L.Landscape.spawn_y),ps},ms,zs}

law Admission.choose_ok:
  for +result: Maybe<&2,A.Allocation.Choice>
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +valid: S.Simulation.OK<state>
  S.Simulation.OK<Admission.state(Admission.choose(result,state,cid,style,name))>

def Admission.choose_ok(result,state,cid,style,name,valid):
  match result:
    case None{}: valid
    case Some{choice}: Admission.commit_ok(state,cid,style,name,choice,valid)

law Admission.gate_ok:
  for +reject: Bool
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +valid: S.Simulation.OK<state>
  S.Simulation.OK<Admission.state(Admission.gate(reject,state,cid,style,name))>

def Admission.gate_ok(reject,state,cid,style,name,valid):
  match reject:
    case True{}: valid
    case False{}: Admission.choose_ok(A.Allocation.find(Admission.pids(S.Simulation.players(state)),Admission.hint(S.Simulation.meta(state))),state,cid,style,name,valid)

law Admission.add_ok:
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +valid: S.Simulation.OK<state>
  S.Simulation.OK<Admission.state(Admission.add(state,cid,style,name))>

def Admission.add_ok(state,cid,style,name,valid): Admission.gate_ok(Admission.reject(cid,S.Simulation.players(state)),state,cid,style,name,valid)

law Admission.rejected:
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +reject: {Admission.reject(cid,S.Simulation.players(state)) == True{} : Bool}
  {Admission.add(state,cid,style,name) == Admission.Result{state,0} : Admission.Result}

def Admission.rejected(state,cid,style,name,reject):
  %Equal.sym(Bool,Admission.reject(cid,S.Simulation.players(state)),True{},reject) : {Admission.gate(_,state,cid,style,name) == Admission.Result{state,0} : Admission.Result}
  {==}

law Admission.exhausted:
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  {Admission.choose(None{},state,cid,style,name) == Admission.Result{state,0} : Admission.Result}

def Admission.exhausted(state,cid,style,name): {==}

type Admission.Outcome<-before: S.Simulation.State,-cid: U32,-style: P.Players.Style,-name: List<&2,Char>,-result: Admission.Result> is Data:
  Admission.Rejected{exact: {result == Admission.Result{before,0} : Admission.Result}}
  Admission.Created{choice: A.Allocation.Choice,exact: {result == Admission.commit(before,cid,style,name,choice) : Admission.Result},fresh: A.Allocation.Fresh<Admission.pids(S.Simulation.players(before)),choice>,cid_positive: {U32.is_eq(cid,0) == False{} : Bool},cid_absent: A.Allocation.Absent(cid,Admission.cids(S.Simulation.players(before)))}

law Admission.choose_outcome:
  for +result: Maybe<&2,A.Allocation.Choice>
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +safe: A.Allocation.Safe(Admission.pids(S.Simulation.players(state)),result)
  for +positive: {U32.is_eq(cid,0) == False{} : Bool}
  for +available: A.Allocation.Absent(cid,Admission.cids(S.Simulation.players(state)))
  Admission.Outcome<state,cid,style,name,Admission.choose(result,state,cid,style,name)>

def Admission.choose_outcome(result,state,cid,style,name,safe,positive,available):
  match result:
    case None{}: Admission.Rejected{{==}}
    case Some{choice}: Admission.Created{choice,{==},safe,positive,available}

law Admission.gate_outcome:
  for +reject: Bool
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +decision: {Admission.reject(cid,S.Simulation.players(state)) == reject : Bool}
  Admission.Outcome<state,cid,style,name,Admission.gate(reject,state,cid,style,name)>

def Admission.gate_outcome(reject,state,cid,style,name,decision):
  match reject:
    case True{}: Admission.Rejected{{==}}
    case False{}:
      +ids = Admission.pids(S.Simulation.players(state))
      +hint = Admission.hint(S.Simulation.meta(state))
      +parts = A.Allocation.or_false(U32.is_eq(cid,0),A.Allocation.contains(cid,Admission.cids(S.Simulation.players(state))),decision)
      Admission.choose_outcome(A.Allocation.find(ids,hint),state,cid,style,name,A.Allocation.find_safe(ids,hint),A.Allocation.false_left(U32.is_eq(cid,0),A.Allocation.contains(cid,Admission.cids(S.Simulation.players(state))),parts),A.Allocation.contains_absent(Admission.cids(S.Simulation.players(state)),cid,A.Allocation.false_right(U32.is_eq(cid,0),A.Allocation.contains(cid,Admission.cids(S.Simulation.players(state))),parts)))

law Admission.add_outcome:
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  Admission.Outcome<state,cid,style,name,Admission.add(state,cid,style,name)>

def Admission.add_outcome(state,cid,style,name): Admission.gate_outcome(Admission.reject(cid,S.Simulation.players(state)),state,cid,style,name,{==})

law Admission.commit_on:
  for +seed: U32
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +choice: A.Allocation.Choice
  for +valid: Walk.Locomotion.All(L.Landscape.maps(seed),S.Simulation.players(state))
  Walk.Locomotion.All(L.Landscape.maps(seed),S.Simulation.players(Admission.state(Admission.commit(state,cid,style,name,choice))))

def Admission.commit_on(seed,state,cid,style,name,choice,valid):
  match state:
    case S.Simulation.State{meta,players,monsters}: Tuple{L.Landscape.player_spawn_on(seed,A.Allocation.id(choice),cid,style,name),valid}

law Admission.choose_on:
  for +result: Maybe<&2,A.Allocation.Choice>
  for +seed: U32
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +valid: Walk.Locomotion.All(L.Landscape.maps(seed),S.Simulation.players(state))
  Walk.Locomotion.All(L.Landscape.maps(seed),S.Simulation.players(Admission.state(Admission.choose(result,state,cid,style,name))))

def Admission.choose_on(result,seed,state,cid,style,name,valid):
  match result:
    case None{}: valid
    case Some{choice}: Admission.commit_on(seed,state,cid,style,name,choice,valid)

law Admission.gate_on:
  for +reject: Bool
  for +seed: U32
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +valid: Walk.Locomotion.All(L.Landscape.maps(seed),S.Simulation.players(state))
  Walk.Locomotion.All(L.Landscape.maps(seed),S.Simulation.players(Admission.state(Admission.gate(reject,state,cid,style,name))))

def Admission.gate_on(reject,seed,state,cid,style,name,valid):
  match reject:
    case True{}: valid
    case False{}: Admission.choose_on(A.Allocation.find(Admission.pids(S.Simulation.players(state)),Admission.hint(S.Simulation.meta(state))),seed,state,cid,style,name,valid)

law Admission.add_on:
  for +seed: U32
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +valid: Walk.Locomotion.All(L.Landscape.maps(seed),S.Simulation.players(state))
  Walk.Locomotion.All(L.Landscape.maps(seed),S.Simulation.players(Admission.state(Admission.add(state,cid,style,name))))

def Admission.add_on(seed,state,cid,style,name,valid): Admission.gate_on(Admission.reject(cid,S.Simulation.players(state)),seed,state,cid,style,name,valid)
