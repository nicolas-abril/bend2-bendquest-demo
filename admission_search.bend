# Successful admission, refining actual allocation and CID rejection gates.
import Base
import ./allocation_search.bend as Search
import ./allocation.bend as A
import ./admission.bend as J
import ./players.bend as P
import ./simulation.bend as S
import ./landscape.bend as L

type AdmissionSearch.Success<-before: S.Simulation.State,-cid: U32,-style: P.Players.Style,-name: List<&2,Char>,-result: J.Admission.Result> is Data:
  AdmissionSearch.Success{choice: A.Allocation.Choice,exact: {result == J.Admission.commit(before,cid,style,name,choice) : J.Admission.Result},fresh: A.Allocation.Fresh<J.Admission.pids(S.Simulation.players(before)),choice>,positive: {U32.is_eq(cid,0) == False{} : Bool},absent: A.Allocation.Absent(cid,J.Admission.cids(S.Simulation.players(before)))}

law AdmissionSearch.reject_false:
  for +cid: U32
  for +players: List<&2,P.Players.State>
  for +positive: {U32.is_eq(cid,0) == False{} : Bool}
  for +absent: A.Allocation.Absent(cid,J.Admission.cids(players))
  {J.Admission.reject(cid,players) == False{} : Bool}

def AdmissionSearch.reject_false(cid,players,positive,absent):
  %Equal.sym(Bool,U32.is_eq(cid,0),False{},positive) : {Bool.or(_,A.Allocation.contains(cid,J.Admission.cids(players))) == False{} : Bool}
  A.Allocation.absent_contains(J.Admission.cids(players),cid,absent)

law AdmissionSearch.choose_complete:
  for +result: Maybe<&2,A.Allocation.Choice>
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +found: Search.AllocationSearch.Success<J.Admission.pids(S.Simulation.players(state)),result>
  for +positive: {U32.is_eq(cid,0) == False{} : Bool}
  for +absent: A.Allocation.Absent(cid,J.Admission.cids(S.Simulation.players(state)))
  AdmissionSearch.Success<state,cid,style,name,J.Admission.choose(result,state,cid,style,name)>

def AdmissionSearch.choose_complete(result,state,cid,style,name,found,positive,absent):
  match found:
    case Search.AllocationSearch.Success{choice,exact,fresh}:
      %Equal.sym(Maybe<&2,A.Allocation.Choice>,result,Some{choice},exact) : AdmissionSearch.Success<state,cid,style,name,J.Admission.choose(_,state,cid,style,name)>
      AdmissionSearch.Success{choice,{==},fresh,positive,absent}

law AdmissionSearch.add_complete:
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +distinct: A.Allocation.Unique(Search.AllocationSearch.visits(Succ{A.Allocation.length(J.Admission.pids(S.Simulation.players(state)))},A.Allocation.normalize(J.Admission.hint(S.Simulation.meta(state)))))
  for +positive: {U32.is_eq(cid,0) == False{} : Bool}
  for +absent: A.Allocation.Absent(cid,J.Admission.cids(S.Simulation.players(state)))
  AdmissionSearch.Success<state,cid,style,name,J.Admission.add(state,cid,style,name)>

def AdmissionSearch.add_complete(state,cid,style,name,distinct,positive,absent):
  %Equal.sym(Bool,J.Admission.reject(cid,S.Simulation.players(state)),False{},AdmissionSearch.reject_false(cid,S.Simulation.players(state),positive,absent)) : AdmissionSearch.Success<state,cid,style,name,J.Admission.gate(_,state,cid,style,name)>
  AdmissionSearch.choose_complete(A.Allocation.find(J.Admission.pids(S.Simulation.players(state)),J.Admission.hint(S.Simulation.meta(state))),state,cid,style,name,Search.AllocationSearch.find_complete(J.Admission.pids(S.Simulation.players(state)),J.Admission.hint(S.Simulation.meta(state)),distinct),positive,absent)

law AdmissionSearch.commit_pid:
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +choice: A.Allocation.Choice
  {J.Admission.pid(J.Admission.commit(state,cid,style,name,choice)) == A.Allocation.id(choice) : U32}

def AdmissionSearch.commit_pid(state,cid,style,name,choice):
  match state:
    case S.Simulation.State{meta,players,monsters}: {==}

law AdmissionSearch.nonzero:
  for +before: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +result: J.Admission.Result
  for +success: AdmissionSearch.Success<before,cid,style,name,result>
  {U32.is_eq(J.Admission.pid(result),0) == False{} : Bool}

def AdmissionSearch.nonzero(before,cid,style,name,result,success):
  match success:
    case AdmissionSearch.Success{choice,exact,fresh,positive,absent}:
      match fresh:
        case A.Allocation.Fresh{nonzero,unused,next_positive}:
          %Equal.sym(J.Admission.Result,result,J.Admission.commit(before,cid,style,name,choice),exact) : {U32.is_eq(J.Admission.pid(_),0) == False{} : Bool}
          %Equal.sym(U32,J.Admission.pid(J.Admission.commit(before,cid,style,name,choice)),A.Allocation.id(choice),AdmissionSearch.commit_pid(before,cid,style,name,choice)) : {U32.is_eq(_,0) == False{} : Bool}
          nonzero

law AdmissionSearch.commit_players:
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +choice: A.Allocation.Choice
  {S.Simulation.players(J.Admission.state(J.Admission.commit(state,cid,style,name,choice))) == Con{P.Players.spawn(A.Allocation.id(choice),cid,style,name,L.Landscape.spawn_x,L.Landscape.spawn_y),S.Simulation.players(state)} : List<&2,P.Players.State>}

def AdmissionSearch.commit_players(state,cid,style,name,choice):
  match state:
    case S.Simulation.State{meta,players,monsters}: {==}

law AdmissionSearch.inserted:
  for +before: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +result: J.Admission.Result
  for +success: AdmissionSearch.Success<before,cid,style,name,result>
  {S.Simulation.players(J.Admission.state(result)) == Con{P.Players.spawn(J.Admission.pid(result),cid,style,name,L.Landscape.spawn_x,L.Landscape.spawn_y),S.Simulation.players(before)} : List<&2,P.Players.State>}

def AdmissionSearch.inserted(before,cid,style,name,result,success):
  match success:
    case AdmissionSearch.Success{choice,exact,fresh,positive,absent}:
      %Equal.sym(J.Admission.Result,result,J.Admission.commit(before,cid,style,name,choice),exact) : {S.Simulation.players(J.Admission.state(_)) == Con{P.Players.spawn(J.Admission.pid(_),cid,style,name,L.Landscape.spawn_x,L.Landscape.spawn_y),S.Simulation.players(before)} : List<&2,P.Players.State>}
      %Equal.sym(U32,J.Admission.pid(J.Admission.commit(before,cid,style,name,choice)),A.Allocation.id(choice),AdmissionSearch.commit_pid(before,cid,style,name,choice)) : {S.Simulation.players(J.Admission.state(J.Admission.commit(before,cid,style,name,choice))) == Con{P.Players.spawn(_,cid,style,name,L.Landscape.spawn_x,L.Landscape.spawn_y),S.Simulation.players(before)} : List<&2,P.Players.State>}
      AdmissionSearch.commit_players(before,cid,style,name,choice)
