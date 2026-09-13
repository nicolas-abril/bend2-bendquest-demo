# Pure connection lifecycle decisions used by the effectful server adapter.
import Base
import ./numeric.bend as N
import ./allocation.bend as Alloc

type Sessions.State is Data:
  Sessions.State{cid: U32,phase: U32,pid: U32,name: List<&2,Char>}

def Sessions.cid(state: Sessions.State) -> U32:
  match state:
    case Sessions.State{cid,phase,pid,name}: cid

def Sessions.phase(state: Sessions.State) -> U32:
  match state:
    case Sessions.State{cid,phase,pid,name}: phase

def Sessions.pid(state: Sessions.State) -> U32:
  match state:
    case Sessions.State{cid,phase,pid,name}: pid

def Sessions.name(state: Sessions.State) -> List<&2,Char>:
  match state:
    case Sessions.State{cid,phase,pid,name}: name

# At most twelve characters, with no machine-word length overflow.
def Sessions.fits(name: List<&2,Char>,fuel: Nat) -> Bool:
  match name:
    case Nil{}: True{}
    case Con{head,rest}:
      match fuel:
        case Zero{}: False{}
        case Succ{left}: Sessions.fits(rest,left)

def Sessions.valid_name(name: List<&2,Char>) -> Bool:
  match name:
    case Nil{}: False{}
    case Con{head,rest}: Sessions.fits(rest,11n)

def Sessions.char_eq(left: Char,right: Char) -> Bool:
  match left:
    case Chr{a}:
      match right:
        case Chr{b}: U32.is_eq(a,b)

def Sessions.name_eq(left: List<&2,Char>,right: List<&2,Char>) -> Bool:
  match left:
    case Nil{}:
      match right:
        case Nil{}: True{}
        case Con{head,rest}: False{}
    case Con{head,rest}:
      match right:
        case Nil{}: False{}
        case Con{other,later}: Bool.and(Sessions.char_eq(head,other),Sessions.name_eq(rest,later))

def Sessions.online(states: List<&2,Sessions.State>,+name: List<&2,Char>) -> Bool:
  match states:
    case Nil{}: False{}
    case Con{head,rest}: Bool.or(Sessions.name_eq(Sessions.name(head),name),Sessions.online(rest,name))

type Sessions.Reply is Data:
  Sessions.Locked{}
  Sessions.BadName{}
  Sessions.Taken{}
  Sessions.Welcome{}

type Sessions.Result is Data:
  Sessions.Result{state: Sessions.State,reply: Sessions.Reply}

def Sessions.state(result: Sessions.Result) -> Sessions.State:
  match result:
    case Sessions.Result{state,reply}: state

def Sessions.reply(result: Sessions.Result) -> Sessions.Reply:
  match result:
    case Sessions.Result{state,reply}: reply

def Sessions.commit(state: Sessions.State,name: List<&2,Char>) -> Sessions.Result:
  match state:
    case Sessions.State{cid,phase,pid,old}: Sessions.Result{Sessions.State{cid,1,pid,name},Sessions.Welcome{}}

def Sessions.online_gate(online: Bool,state: Sessions.State,name: List<&2,Char>) -> Sessions.Result:
  match online:
    case True{}: Sessions.Result{state,Sessions.Taken{}}
    case False{}: Sessions.commit(state,name)

def Sessions.name_gate(valid: Bool,state: Sessions.State,+name: List<&2,Char>,others: List<&2,Sessions.State>) -> Sessions.Result:
  match valid:
    case False{}: Sessions.Result{state,Sessions.BadName{}}
    case True{}: Sessions.online_gate(Sessions.online(others,name),state,name)

def Sessions.phase_gate(open: Bool,state: Sessions.State,+name: List<&2,Char>,others: List<&2,Sessions.State>) -> Sessions.Result:
  match open:
    case False{}: Sessions.Result{state,Sessions.Locked{}}
    case True{}: Sessions.name_gate(Sessions.valid_name(name),state,name,others)

def Sessions.open(+phase: U32) -> Bool: Bool.or(U32.is_eq(phase,0),U32.is_eq(phase,1))

def Sessions.unbound_gate(unbound: Bool,+state: Sessions.State,name: List<&2,Char>,others: List<&2,Sessions.State>) -> Sessions.Result:
  match unbound:
    case False{}: Sessions.Result{state,Sessions.Locked{}}
    case True{}: Sessions.phase_gate(Sessions.open(Sessions.phase(state)),state,name,others)

def Sessions.hello(+state: Sessions.State,name: List<&2,Char>,others: List<&2,Sessions.State>) -> Sessions.Result:
  Sessions.unbound_gate(U32.is_eq(Sessions.pid(state),0),state,name,others)

# Valid lifecycle states: fresh(0), awaiting creation(1), and playing(2).
def Sessions.Lifecycle(stage: Nat,pid: U32,name: List<&2,Char>) -> Data:
  match stage:
    case Zero{}: Sigma<&2,&2,{pid == 0 : U32},(zero => {name == Nil{} : List<&2,Char>})>
    case Succ{one}:
      match one:
        case Zero{}: Sigma<&2,&2,{pid == 0 : U32},(zero => {Sessions.valid_name(name) == True{} : Bool})>
        case Succ{two}:
          match two:
            case Zero{}: Sigma<&2,&2,{U32.is_eq(pid,0) == False{} : Bool},(positive => {Sessions.valid_name(name) == True{} : Bool})>
            case Succ{invalid}: Empty

type Sessions.OK<-state: Sessions.State> is Data:
  Sessions.OK{cid: {U32.is_eq(Sessions.cid(state),0) == False{} : Bool},lifecycle: Sessions.Lifecycle(U32.to_nat(Sessions.phase(state)),Sessions.pid(state),Sessions.name(state))}

law Sessions.bound_locked:
  for +state: Sessions.State
  for +name: List<&2,Char>
  for +others: List<&2,Sessions.State>
  for +bound: {U32.is_eq(Sessions.pid(state),0) == False{} : Bool}
  {Sessions.hello(state,name,others) == Sessions.Result{state,Sessions.Locked{}} : Sessions.Result}

def Sessions.bound_locked(state,name,others,bound):
  %Equal.sym(Bool,U32.is_eq(Sessions.pid(state),0),False{},bound) : {Sessions.unbound_gate(_,state,name,others) == Sessions.Result{state,Sessions.Locked{}} : Sessions.Result}
  {==}

law Sessions.playing_gate:
  for +unbound: Bool
  for +cid: U32
  for +pid: U32
  for +old: List<&2,Char>
  for +name: List<&2,Char>
  for +others: List<&2,Sessions.State>
  {Sessions.unbound_gate(unbound,Sessions.State{cid,2,pid,old},name,others) == Sessions.Result{Sessions.State{cid,2,pid,old},Sessions.Locked{}} : Sessions.Result}

def Sessions.playing_gate(unbound,cid,pid,old,name,others):
  match unbound:
    case False{}: {==}
    case True{}: {==}

law Sessions.playing_locked:
  for +cid: U32
  for +pid: U32
  for +old: List<&2,Char>
  for +name: List<&2,Char>
  for +others: List<&2,Sessions.State>
  {Sessions.hello(Sessions.State{cid,2,pid,old},name,others) == Sessions.Result{Sessions.State{cid,2,pid,old},Sessions.Locked{}} : Sessions.Result}

def Sessions.playing_locked(cid,pid,old,name,others):
  Sessions.playing_gate(U32.is_eq(pid,0),cid,pid,old,name,others)

def Sessions.Rejected(reply: Sessions.Reply) -> Data:
  match reply:
    case Sessions.Locked{}: Unit
    case Sessions.BadName{}: Unit
    case Sessions.Taken{}: Unit
    case Sessions.Welcome{}: Empty

type Sessions.Outcome<-before: Sessions.State,-name: List<&2,Char>,-others: List<&2,Sessions.State>,-result: Sessions.Result> is Data:
  Sessions.Denied{reason: Sessions.Reply,rejected: Sessions.Rejected(reason),exact: {result == Sessions.Result{before,reason} : Sessions.Result}}
  Sessions.Accepted{exact: {result == Sessions.commit(before,name) : Sessions.Result},unbound: {Sessions.pid(before) == 0 : U32},open: {Sessions.open(Sessions.phase(before)) == True{} : Bool},valid: {Sessions.valid_name(name) == True{} : Bool},available: {Sessions.online(others,name) == False{} : Bool}}

law Sessions.online_outcome:
  for +online: Bool
  for +state: Sessions.State
  for +name: List<&2,Char>
  for +others: List<&2,Sessions.State>
  for +decision: {Sessions.online(others,name) == online : Bool}
  for +unbound: {Sessions.pid(state) == 0 : U32}
  for +open: {Sessions.open(Sessions.phase(state)) == True{} : Bool}
  for +valid: {Sessions.valid_name(name) == True{} : Bool}
  Sessions.Outcome<state,name,others,Sessions.online_gate(online,state,name)>

def Sessions.online_outcome(online,state,name,others,decision,unbound,open,valid):
  match online:
    case True{}: Sessions.Denied{Sessions.Taken{},Unit{},{==}}
    case False{}: Sessions.Accepted{{==},unbound,open,valid,decision}

law Sessions.name_outcome:
  for +valid: Bool
  for +state: Sessions.State
  for +name: List<&2,Char>
  for +others: List<&2,Sessions.State>
  for +decision: {Sessions.valid_name(name) == valid : Bool}
  for +unbound: {Sessions.pid(state) == 0 : U32}
  for +open: {Sessions.open(Sessions.phase(state)) == True{} : Bool}
  Sessions.Outcome<state,name,others,Sessions.name_gate(valid,state,name,others)>

def Sessions.name_outcome(valid,state,name,others,decision,unbound,open):
  match valid:
    case False{}: Sessions.Denied{Sessions.BadName{},Unit{},{==}}
    case True{}: Sessions.online_outcome(Sessions.online(others,name),state,name,others,{==},unbound,open,decision)

law Sessions.phase_outcome:
  for +open: Bool
  for +state: Sessions.State
  for +name: List<&2,Char>
  for +others: List<&2,Sessions.State>
  for +decision: {Sessions.open(Sessions.phase(state)) == open : Bool}
  for +unbound: {Sessions.pid(state) == 0 : U32}
  Sessions.Outcome<state,name,others,Sessions.phase_gate(open,state,name,others)>

def Sessions.phase_outcome(open,state,name,others,decision,unbound):
  match open:
    case False{}: Sessions.Denied{Sessions.Locked{},Unit{},{==}}
    case True{}: Sessions.name_outcome(Sessions.valid_name(name),state,name,others,{==},unbound,decision)

law Sessions.unbound_outcome:
  for +unbound: Bool
  for +state: Sessions.State
  for +name: List<&2,Char>
  for +others: List<&2,Sessions.State>
  for +decision: {U32.is_eq(Sessions.pid(state),0) == unbound : Bool}
  Sessions.Outcome<state,name,others,Sessions.unbound_gate(unbound,state,name,others)>

def Sessions.unbound_outcome(unbound,state,name,others,decision):
  match unbound:
    case False{}: Sessions.Denied{Sessions.Locked{},Unit{},{==}}
    case True{}: Sessions.phase_outcome(Sessions.open(Sessions.phase(state)),state,name,others,{==},N.Numeric.u32_eq_sound(Sessions.pid(state),0,decision))

law Sessions.hello_outcome:
  for +state: Sessions.State
  for +name: List<&2,Char>
  for +others: List<&2,Sessions.State>
  Sessions.Outcome<state,name,others,Sessions.hello(state,name,others)>

def Sessions.hello_outcome(state,name,others): Sessions.unbound_outcome(U32.is_eq(Sessions.pid(state),0),state,name,others,{==})

type Sessions.Binding is Data:
  Sessions.Binding{cid: U32,pid: U32}

def Sessions.binding(state: Sessions.State) -> Sessions.Binding:
  match state:
    case Sessions.State{cid,phase,pid,name}: Sessions.Binding{cid,pid}

law Sessions.commit_binding:
  for +state: Sessions.State
  for +name: List<&2,Char>
  {Sessions.binding(Sessions.state(Sessions.commit(state,name))) == Sessions.binding(state) : Sessions.Binding}

def Sessions.commit_binding(state,name):
  match state:
    case Sessions.State{cid,phase,pid,old}: {==}

law Sessions.outcome_binding:
  for +state: Sessions.State
  for +name: List<&2,Char>
  for +others: List<&2,Sessions.State>
  for +result: Sessions.Result
  for +outcome: Sessions.Outcome<state,name,others,result>
  {Sessions.binding(Sessions.state(result)) == Sessions.binding(state) : Sessions.Binding}

def Sessions.outcome_binding(state,name,others,result,outcome):
  match outcome:
    case Sessions.Denied{reason,rejected,exact}:
      %Equal.sym(Sessions.Result,result,Sessions.Result{state,reason},exact) : {Sessions.binding(Sessions.state(_)) == Sessions.binding(state) : Sessions.Binding}
      {==}
    case Sessions.Accepted{exact,unbound,open,valid,available}:
      %Equal.sym(Sessions.Result,result,Sessions.commit(state,name),exact) : {Sessions.binding(Sessions.state(_)) == Sessions.binding(state) : Sessions.Binding}
      Sessions.commit_binding(state,name)

law Sessions.hello_binding:
  for +state: Sessions.State
  for +name: List<&2,Char>
  for +others: List<&2,Sessions.State>
  {Sessions.binding(Sessions.state(Sessions.hello(state,name,others))) == Sessions.binding(state) : Sessions.Binding}

def Sessions.hello_binding(state,name,others): Sessions.outcome_binding(state,name,others,Sessions.hello(state,name,others),Sessions.hello_outcome(state,name,others))

law Sessions.commit_ok:
  for +state: Sessions.State
  for +name: List<&2,Char>
  for +unbound: {Sessions.pid(state) == 0 : U32}
  for +valid_name: {Sessions.valid_name(name) == True{} : Bool}
  for +valid: Sessions.OK<state>
  Sessions.OK<Sessions.state(Sessions.commit(state,name))>

def Sessions.commit_ok(state,name,unbound,valid_name,valid):
  match state:
    case Sessions.State{cid,phase,pid,old}:
      match valid:
        case Sessions.OK{positive,lifecycle}: Sessions.OK{positive,Tuple{unbound,valid_name}}

law Sessions.outcome_ok:
  for +state: Sessions.State
  for +name: List<&2,Char>
  for +others: List<&2,Sessions.State>
  for +result: Sessions.Result
  for +outcome: Sessions.Outcome<state,name,others,result>
  for +valid: Sessions.OK<state>
  Sessions.OK<Sessions.state(result)>

def Sessions.outcome_ok(state,name,others,result,outcome,valid):
  match outcome:
    case Sessions.Denied{reason,rejected,exact}:
      %Equal.sym(Sessions.Result,result,Sessions.Result{state,reason},exact) : Sessions.OK<Sessions.state(_)>
      valid
    case Sessions.Accepted{exact,unbound,open,name_valid,available}:
      %Equal.sym(Sessions.Result,result,Sessions.commit(state,name),exact) : Sessions.OK<Sessions.state(_)>
      Sessions.commit_ok(state,name,unbound,name_valid,valid)

law Sessions.hello_ok:
  for +state: Sessions.State
  for +name: List<&2,Char>
  for +others: List<&2,Sessions.State>
  for +valid: Sessions.OK<state>
  Sessions.OK<Sessions.state(Sessions.hello(state,name,others))>

def Sessions.hello_ok(state,name,others,valid): Sessions.outcome_ok(state,name,others,Sessions.hello(state,name,others),Sessions.hello_outcome(state,name,others),valid)

def Sessions.fresh(cid: U32) -> Sessions.State: Sessions.State{cid,0,0,Nil{}}

law Sessions.fresh_ok:
  for +cid: U32
  for +positive: {U32.is_eq(cid,0) == False{} : Bool}
  Sessions.OK<Sessions.fresh(cid)>

def Sessions.fresh_ok(cid,positive): Sessions.OK{positive,Tuple{{==},{==}}}

def Sessions.trace(names: List<&2,List<&2,Char>>,state: Sessions.State,+others: List<&2,Sessions.State>) -> Sessions.State:
  match names:
    case Nil{}: state
    case Con{head,rest}: Sessions.trace(rest,Sessions.state(Sessions.hello(state,head,others)),others)

law Sessions.trace_ok:
  for +names: List<&2,List<&2,Char>>
  for +state: Sessions.State
  for +others: List<&2,Sessions.State>
  for +valid: Sessions.OK<state>
  Sessions.OK<Sessions.trace(names,state,others)>

def Sessions.trace_ok(names,state,others,valid):
  match names:
    case Nil{}: valid
    case Con{head,rest}: Sessions.trace_ok(rest,Sessions.state(Sessions.hello(state,head,others)),others,Sessions.hello_ok(state,head,others,valid))

law Sessions.bound_trace:
  for +names: List<&2,List<&2,Char>>
  for +state: Sessions.State
  for +others: List<&2,Sessions.State>
  for +bound: {U32.is_eq(Sessions.pid(state),0) == False{} : Bool}
  {Sessions.trace(names,state,others) == state : Sessions.State}

def Sessions.bound_trace(names,state,others,bound):
  match names:
    case Nil{}: {==}
    case Con{head,rest}:
      %Equal.sym(Sessions.Result,Sessions.hello(state,head,others),Sessions.Result{state,Sessions.Locked{}},Sessions.bound_locked(state,head,others,bound)) : {Sessions.trace(rest,Sessions.state(_),others) == state : Sessions.State}
      Sessions.bound_trace(rest,state,others,bound)

law Sessions.char_eq_refl:
  for +char: Char
  {Sessions.char_eq(char,char) == True{} : Bool}

def Sessions.char_eq_refl(char):
  match char:
    case Chr{word}: N.Numeric.u32_eq_refl(word)

law Sessions.name_eq_refl:
  for +name: List<&2,Char>
  {Sessions.name_eq(name,name) == True{} : Bool}

def Sessions.name_eq_refl(name):
  match name:
    case Nil{}: {==}
    case Con{head,rest}:
      %Equal.sym(Bool,Sessions.char_eq(head,head),True{},Sessions.char_eq_refl(head)) : {Bool.and(_,Sessions.name_eq(rest,rest)) == True{} : Bool}
      Sessions.name_eq_refl(rest)

law Sessions.online_here:
  for +state: Sessions.State
  for +rest: List<&2,Sessions.State>
  {Sessions.online(Con{state,rest},Sessions.name(state)) == True{} : Bool}

def Sessions.online_here(state,rest):
  %Equal.sym(Bool,Sessions.name_eq(Sessions.name(state),Sessions.name(state)),True{},Sessions.name_eq_refl(Sessions.name(state))) : {Bool.or(_,Sessions.online(rest,Sessions.name(state))) == True{} : Bool}
  {==}

# Player creation supplies an allocated PID while retaining the reservation.
def Sessions.bind(state: Sessions.State,pid: U32) -> Sessions.State:
  match state:
    case Sessions.State{cid,phase,old,name}: Sessions.State{cid,2,pid,name}

type Sessions.Reservation is Data:
  Sessions.Reservation{cid: U32,name: List<&2,Char>}

def Sessions.reservation(state: Sessions.State) -> Sessions.Reservation:
  match state:
    case Sessions.State{cid,phase,pid,name}: Sessions.Reservation{cid,name}

law Sessions.bind_reservation:
  for +state: Sessions.State
  for +pid: U32
  {Sessions.reservation(Sessions.bind(state,pid)) == Sessions.reservation(state) : Sessions.Reservation}

def Sessions.bind_reservation(state,pid):
  match state:
    case Sessions.State{cid,phase,old,name}: {==}

law Sessions.bind_pid:
  for +state: Sessions.State
  for +pid: U32
  {Sessions.pid(Sessions.bind(state,pid)) == pid : U32}

def Sessions.bind_pid(state,pid):
  match state:
    case Sessions.State{cid,phase,old,name}: {==}

def Sessions.ready_name(pid: U32,name: List<&2,Char>,valid: Sessions.Lifecycle(1n,pid,name)) -> {Sessions.valid_name(name) == True{} : Bool}:
  match valid:
    case Tuple{zero,named}: named

law Sessions.bind_ok:
  for +state: Sessions.State
  for +pid: U32
  for +ready: {Sessions.phase(state) == 1 : U32}
  for +positive: {U32.is_eq(pid,0) == False{} : Bool}
  for +valid: Sessions.OK<state>
  Sessions.OK<Sessions.bind(state,pid)>

def Sessions.bind_ok(state,pid,ready,positive,valid):
  match state:
    case Sessions.State{cid,phase,old,name}:
      match valid:
        case Sessions.OK{cid_positive,lifecycle}: Sessions.OK{cid_positive,Tuple{positive,Sessions.ready_name(old,name,(%ready : Sessions.Lifecycle(U32.to_nat(_),old,name); lifecycle))}}

law Sessions.bind_locked:
  for +state: Sessions.State
  for +pid: U32
  for +name: List<&2,Char>
  for +others: List<&2,Sessions.State>
  {Sessions.hello(Sessions.bind(state,pid),name,others) == Sessions.Result{Sessions.bind(state,pid),Sessions.Locked{}} : Sessions.Result}

def Sessions.bind_locked(state,pid,name,others):
  match state:
    case Sessions.State{cid,phase,old,previous}: Sessions.playing_locked(cid,pid,previous,name,others)

law Sessions.one_allowed:
  for +a: Char
  {Sessions.valid_name(Con{a,Nil{}}) == True{} : Bool}

def Sessions.one_allowed(a): {==}

law Sessions.twelve_allowed:
  for +a: Char
  for +b: Char
  for +c: Char
  for +d: Char
  for +e: Char
  for +f: Char
  for +g: Char
  for +h: Char
  for +i: Char
  for +j: Char
  for +k: Char
  for +l: Char
  {Sessions.valid_name(Con{a,Con{b,Con{c,Con{d,Con{e,Con{f,Con{g,Con{h,Con{i,Con{j,Con{k,Con{l,Nil{}}}}}}}}}}}}}) == True{} : Bool}

def Sessions.twelve_allowed(a,b,c,d,e,f,g,h,i,j,k,l): {==}

law Sessions.thirteen_rejected:
  for +a: Char
  for +b: Char
  for +c: Char
  for +d: Char
  for +e: Char
  for +f: Char
  for +g: Char
  for +h: Char
  for +i: Char
  for +j: Char
  for +k: Char
  for +l: Char
  for +m: Char
  for +rest: List<&2,Char>
  {Sessions.valid_name(Con{a,Con{b,Con{c,Con{d,Con{e,Con{f,Con{g,Con{h,Con{i,Con{j,Con{k,Con{l,Con{m,rest}}}}}}}}}}}}}) == False{} : Bool}

def Sessions.thirteen_rejected(a,b,c,d,e,f,g,h,i,j,k,l,m,rest): {==}
