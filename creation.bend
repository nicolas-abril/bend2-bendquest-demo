# Joint player admission and connection binding.
import Base
import ./connections.bend as C
import ./selection.bend as Q
import ./sessions.bend as S
import ./players.bend as P
import ./targeting.bend as T
import ./allocation.bend as A
import ./admission.bend as J
import ./identity.bend as Id
import ./numeric.bend as N
import ./landscape.bend as L
import ./simulation.bend as Sim
import ./worldstate.bend as W
import ./population.bend as Pop
import ./terrain.bend as Terrain

law Creation.bind_cid:
  for +session: S.Sessions.State
  for +pid: U32
  {S.Sessions.cid(S.Sessions.bind(session,pid)) == S.Sessions.cid(session) : U32}

def Creation.bind_cid(session,pid):
  match session:
    case S.Sessions.State{cid,phase,old,name}: {==}

law Creation.bind_name:
  for +session: S.Sessions.State
  for +pid: U32
  {S.Sessions.name(S.Sessions.bind(session,pid)) == S.Sessions.name(session) : List<&2,Char>}

def Creation.bind_name(session,pid):
  match session:
    case S.Sessions.State{cid,phase,old,name}: {==}

def Creation.ready_zero(pid: U32,name: List<&2,Char>,valid: S.Sessions.Lifecycle(1n,pid,name)) -> {pid == 0 : U32}:
  match valid:
    case Tuple{zero,named}: zero

law Creation.ready_unbound:
  for +session: S.Sessions.State
  for +ready: {S.Sessions.phase(session) == 1 : U32}
  for +valid: S.Sessions.OK<session>
  {S.Sessions.pid(session) == 0 : U32}

def Creation.ready_unbound(session,ready,valid):
  match session:
    case S.Sessions.State{cid,phase,pid,name}:
      match valid:
        case S.Sessions.OK{positive,lifecycle}: Creation.ready_zero(pid,name,(%ready : S.Sessions.Lifecycle(U32.to_nat(_),pid,name); lifecycle))

law Creation.bound_unbound:
  for +pid: U32
  for +zero: {pid == 0 : U32}
  for +positive: {U32.is_eq(pid,0) == False{} : Bool}
  Empty

def Creation.bound_unbound(pid,zero,positive): N.Numeric.true_ne_false((%zero : {U32.is_eq(_,0) == False{} : Bool}; positive))

# Old links survive inserting a different player's CID.
law Creation.extend_link:
  for +players: List<&2,P.Players.State>
  for +player: P.Players.State
  for +session: S.Sessions.State
  for +different: {U32.is_eq(S.Sessions.cid(session),J.Admission.cid(player)) == False{} : Bool}
  for +linked: C.Connections.Link<players,session>
  C.Connections.Link<Con{player,players},session>

def Creation.extend_link(players,player,session,different,linked):
  match linked:
    case C.Connections.Waiting{unbound,unused}: C.Connections.Waiting{unbound,Tuple{different,unused}}
    case C.Connections.Playing{actual,inside,positive,cid,pid,name}: C.Connections.Playing{actual,T.Targeting.There{player,players,{==},inside},positive,cid,pid,name}

law Creation.extend_links:
  for +states: List<&2,S.Sessions.State>
  for +players: List<&2,P.Players.State>
  for +player: P.Players.State
  for +unused: A.Allocation.Absent(J.Admission.cid(player),C.Connections.cids(states))
  for +links: C.Connections.Links(players,states)
  C.Connections.Links(Con{player,players},states)

def Creation.extend_links(states,players,player,unused,links):
  match states:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match unused:
        case Tuple{different,later}:
          match links:
            case Tuple{first,tail}: Tuple{Creation.extend_link(players,player,head,Id.Identity.neq_sym(J.Admission.cid(player),S.Sessions.cid(head),different),first),Creation.extend_links(rest,players,player,later,tail)}

# A waiting connection cannot be the reverse witness for an existing player.
law Creation.replace_present:
  for +player: P.Players.State
  for +before: S.Sessions.State
  for +after: S.Sessions.State
  for +others: List<&2,S.Sessions.State>
  for +zero: {S.Sessions.pid(before) == 0 : U32}
  for +present: C.Connections.Present<player,Con{before,others}>
  C.Connections.Present<player,Con{after,others}>

def Creation.replace_present(player,before,after,others,zero,present):
  match present:
    case C.Connections.Present{session,inside,positive,cid,pid,name}:
      match inside:
        case C.Connections.Here{rest,shape}:
          Empty.absurd(C.Connections.Present<player,Con{after,others}>,Creation.bound_unbound(S.Sessions.pid(session),(%C.Connections.cons_head(before,session,others,rest,shape) : {S.Sessions.pid(_) == 0 : U32}; zero),positive))
        case C.Connections.There{head,rest,shape,later}: C.Connections.Present{session,C.Connections.There{after,others,{==},(%Equal.sym(List<&2,S.Sessions.State>,others,rest,C.Connections.cons_tail(before,head,others,rest,shape)) : C.Connections.In<session,_>; later)},positive,cid,pid,name}

law Creation.replace_covers:
  for +players: List<&2,P.Players.State>
  for +before: S.Sessions.State
  for +after: S.Sessions.State
  for +others: List<&2,S.Sessions.State>
  for +zero: {S.Sessions.pid(before) == 0 : U32}
  for +covers: C.Connections.Covers(Con{before,others},players)
  C.Connections.Covers(Con{after,others},players)

def Creation.replace_covers(players,before,after,others,zero,covers):
  match players:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match covers:
        case Tuple{first,later}: Tuple{Creation.replace_present(head,before,after,others,zero,first),Creation.replace_covers(rest,before,after,others,zero,later)}

def Creation.player(session: S.Sessions.State,pid: U32,style: P.Players.Style) -> P.Players.State:
  match session:
    case S.Sessions.State{cid,phase,old,name}: P.Players.spawn(pid,cid,style,name,L.Landscape.spawn_x,L.Landscape.spawn_y)

law Creation.player_cid:
  for +session: S.Sessions.State
  for +pid: U32
  for +style: P.Players.Style
  {J.Admission.cid(Creation.player(session,pid,style)) == S.Sessions.cid(session) : U32}

def Creation.player_cid(session,pid,style):
  match session:
    case S.Sessions.State{cid,phase,old,name}: {==}

law Creation.player_pid:
  for +session: S.Sessions.State
  for +pid: U32
  for +style: P.Players.Style
  {P.Players.id(Creation.player(session,pid,style)) == pid : U32}

def Creation.player_pid(session,pid,style):
  match session:
    case S.Sessions.State{cid,phase,old,name}: {==}

law Creation.player_name:
  for +session: S.Sessions.State
  for +pid: U32
  for +style: P.Players.Style
  {C.Connections.player_name(Creation.player(session,pid,style)) == S.Sessions.name(session) : List<&2,Char>}

def Creation.player_name(session,pid,style):
  match session:
    case S.Sessions.State{cid,phase,old,name}: {==}

law Creation.insert_ok:
  for +players: List<&2,P.Players.State>
  for +head: S.Sessions.State
  for +others: List<&2,S.Sessions.State>
  for +style: P.Players.Style
  for +pid: U32
  for +ready: {S.Sessions.phase(head) == 1 : U32}
  for +positive: {U32.is_eq(pid,0) == False{} : Bool}
  for +valid: C.Connections.OK<players,Con{head,others}>
  C.Connections.OK<Con{Creation.player(head,pid,style),players},Con{S.Sessions.bind(head,pid),others}>

def Creation.insert_ok(players,head,others,style,pid,ready,positive,valid):
  match valid:
    case C.Connections.OK{sessions,unique,links,covers}:
      match sessions:
        case Tuple{first,later}:
          match unique:
            case Tuple{unused,tail}:
              match links:
                case Tuple{old_link,rest}:
                  +player = Creation.player(head,pid,style)
                  +bound = S.Sessions.bind(head,pid)
                  +first = first
                  +cid = Equal.trans(U32,S.Sessions.cid(bound),S.Sessions.cid(head),J.Admission.cid(player),Creation.bind_cid(head,pid),Equal.sym(U32,J.Admission.cid(player),S.Sessions.cid(head),Creation.player_cid(head,pid,style)))
                  +id = Equal.trans(U32,S.Sessions.pid(bound),pid,P.Players.id(player),S.Sessions.bind_pid(head,pid),Equal.sym(U32,P.Players.id(player),pid,Creation.player_pid(head,pid,style)))
                  +name = Equal.trans(List<&2,Char>,S.Sessions.name(bound),S.Sessions.name(head),C.Connections.player_name(player),Creation.bind_name(head,pid),Equal.sym(List<&2,Char>,C.Connections.player_name(player),S.Sessions.name(head),Creation.player_name(head,pid,style)))
                  +bound_positive = {(%Equal.sym(U32,S.Sessions.pid(bound),pid,S.Sessions.bind_pid(head,pid)) : {U32.is_eq(_,0) == False{} : Bool}; positive) : {U32.is_eq(S.Sessions.pid(bound),0) == False{} : Bool}}
                  +unused = unused
                  C.Connections.OK{
                    Tuple{S.Sessions.bind_ok(head,pid,ready,positive,first),later},
                    (%Equal.sym(U32,S.Sessions.cid(bound),S.Sessions.cid(head),Creation.bind_cid(head,pid)) : A.Allocation.Unique(Con{_,C.Connections.cids(others)}); Tuple{unused,tail}),
                    Tuple{C.Connections.Playing{player,T.Targeting.Here{players,{==}},bound_positive,cid,id,name},Creation.extend_links(others,players,player,(%Equal.sym(U32,J.Admission.cid(player),S.Sessions.cid(head),Creation.player_cid(head,pid,style)) : A.Allocation.Absent(_,C.Connections.cids(others)); unused),rest)},
                    Tuple{C.Connections.Present{bound,C.Connections.Here{others,{==}},bound_positive,cid,id,name},Creation.replace_covers(players,head,bound,others,Creation.ready_unbound(head,ready,first),covers)}}

law Creation.commit_players:
  for +before: Sim.Simulation.State
  for +head: S.Sessions.State
  for +style: P.Players.Style
  for +choice: A.Allocation.Choice
  {Sim.Simulation.players(J.Admission.state(J.Admission.commit(before,S.Sessions.cid(head),style,S.Sessions.name(head),choice))) == Con{Creation.player(head,A.Allocation.id(choice),style),Sim.Simulation.players(before)} : List<&2,P.Players.State>}

def Creation.commit_players(before,head,style,choice):
  match before:
    case Sim.Simulation.State{meta,players,monsters}:
      match head:
        case S.Sessions.State{cid,phase,pid,name}: {==}

law Creation.commit_pid:
  for +before: Sim.Simulation.State
  for +head: S.Sessions.State
  for +style: P.Players.Style
  for +choice: A.Allocation.Choice
  {J.Admission.pid(J.Admission.commit(before,S.Sessions.cid(head),style,S.Sessions.name(head),choice)) == A.Allocation.id(choice) : U32}

def Creation.commit_pid(before,head,style,choice):
  match before:
    case Sim.Simulation.State{meta,players,monsters}: {==}

law Creation.commit_world:
  for +seed: U32
  for +before: Sim.Simulation.State
  for +head: S.Sessions.State
  for +others: List<&2,S.Sessions.State>
  for +style: P.Players.Style
  for +choice: A.Allocation.Choice
  for +fresh: A.Allocation.Fresh<J.Admission.pids(Sim.Simulation.players(before)),choice>
  for +positive: {U32.is_eq(S.Sessions.cid(head),0) == False{} : Bool}
  for +available: A.Allocation.Absent(S.Sessions.cid(head),J.Admission.cids(Sim.Simulation.players(before)))
  for +ready: {S.Sessions.phase(head) == 1 : U32}
  for +valid: C.Connections.WorldOK<seed,before,Con{head,others}>
  C.Connections.WorldOK<seed,J.Admission.state(J.Admission.commit(before,S.Sessions.cid(head),style,S.Sessions.name(head),choice)),Con{S.Sessions.bind(head,A.Allocation.id(choice)),others}>

def Creation.commit_world(seed,before,head,others,style,choice,fresh,positive,available,ready,valid):
  match fresh:
    case A.Allocation.Fresh{pid_positive,pid_available,next_positive}:
      match valid:
        case C.Connections.WorldOK{world_ok,connections}:
          +pid_positive = pid_positive
          C.Connections.WorldOK{W.WorldState.commit(seed,before,S.Sessions.cid(head),style,S.Sessions.name(head),choice,A.Allocation.Fresh{pid_positive,pid_available,next_positive},positive,available,world_ok),(%Equal.sym(List<&2,P.Players.State>,Sim.Simulation.players(J.Admission.state(J.Admission.commit(before,S.Sessions.cid(head),style,S.Sessions.name(head),choice))),Con{Creation.player(head,A.Allocation.id(choice),style),Sim.Simulation.players(before)},Creation.commit_players(before,head,style,choice)) : C.Connections.OK<_,Con{S.Sessions.bind(head,A.Allocation.id(choice)),others}>; Creation.insert_ok(Sim.Simulation.players(before),head,others,style,A.Allocation.id(choice),ready,pid_positive,connections))}

type Creation.Result is Data:
  Creation.Result{world: Sim.Simulation.State,states: List<&2,S.Sessions.State>}

def Creation.world(result: Creation.Result) -> Sim.Simulation.State:
  match result:
    case Creation.Result{world,states}: world

def Creation.states(result: Creation.Result) -> List<&2,S.Sessions.State>:
  match result:
    case Creation.Result{world,states}: states

def Creation.OK(seed: U32,+result: Creation.Result) -> Data: C.Connections.WorldOK<seed,Creation.world(result),Creation.states(result)>

# PID zero is the actual allocation-failure sentinel. Failure retains both sides.
def Creation.finish_gate(failed: Bool,result: J.Admission.Result,before: Sim.Simulation.State,head: S.Sessions.State,others: List<&2,S.Sessions.State>) -> Creation.Result:
  match failed:
    case True{}: Creation.Result{before,Con{head,others}}
    case False{}:
      +result = result
      Creation.Result{J.Admission.state(result),Con{S.Sessions.bind(head,J.Admission.pid(result)),others}}

def Creation.finish(+result: J.Admission.Result,before: Sim.Simulation.State,head: S.Sessions.State,others: List<&2,S.Sessions.State>) -> Creation.Result: Creation.finish_gate(U32.is_eq(J.Admission.pid(result),0),result,before,head,others)

law Creation.commit_finish:
  for +before: Sim.Simulation.State
  for +head: S.Sessions.State
  for +others: List<&2,S.Sessions.State>
  for +style: P.Players.Style
  for +choice: A.Allocation.Choice
  for +positive: {U32.is_eq(A.Allocation.id(choice),0) == False{} : Bool}
  {Creation.finish(J.Admission.commit(before,S.Sessions.cid(head),style,S.Sessions.name(head),choice),before,head,others) == Creation.Result{J.Admission.state(J.Admission.commit(before,S.Sessions.cid(head),style,S.Sessions.name(head),choice)),Con{S.Sessions.bind(head,A.Allocation.id(choice)),others}} : Creation.Result}

def Creation.commit_finish(before,head,others,style,choice,positive):
  +result = J.Admission.commit(before,S.Sessions.cid(head),style,S.Sessions.name(head),choice)
  %Equal.sym(U32,J.Admission.pid(result),A.Allocation.id(choice),Creation.commit_pid(before,head,style,choice)) : {Creation.finish_gate(U32.is_eq(_,0),result,before,head,others) == Creation.Result{J.Admission.state(result),Con{S.Sessions.bind(head,A.Allocation.id(choice)),others}} : Creation.Result}
  %Equal.sym(Bool,U32.is_eq(A.Allocation.id(choice),0),False{},positive) : {Creation.finish_gate(_,result,before,head,others) == Creation.Result{J.Admission.state(result),Con{S.Sessions.bind(head,A.Allocation.id(choice)),others}} : Creation.Result}
  %Creation.commit_pid(before,head,style,choice) : {Creation.Result{J.Admission.state(result),Con{S.Sessions.bind(head,J.Admission.pid(result)),others}} == Creation.Result{J.Admission.state(result),Con{S.Sessions.bind(head,_),others}} : Creation.Result}
  {==}

law Creation.finish_ok:
  for +seed: U32
  for +before: Sim.Simulation.State
  for +head: S.Sessions.State
  for +others: List<&2,S.Sessions.State>
  for +style: P.Players.Style
  for +result: J.Admission.Result
  for +outcome: J.Admission.Outcome<before,S.Sessions.cid(head),style,S.Sessions.name(head),result>
  for +ready: {S.Sessions.phase(head) == 1 : U32}
  for +valid: C.Connections.WorldOK<seed,before,Con{head,others}>
  Creation.OK(seed,Creation.finish(result,before,head,others))

def Creation.finish_ok(seed,before,head,others,style,result,outcome,ready,valid):
  match outcome:
    case J.Admission.Rejected{exact}:
      %Equal.sym(J.Admission.Result,result,J.Admission.Result{before,0},exact) : Creation.OK(seed,Creation.finish(_,before,head,others))
      valid
    case J.Admission.Created{choice,exact,fresh,positive,available}:
      match fresh:
        case A.Allocation.Fresh{pid_positive,pid_available,next_positive}:
          +pid_positive = pid_positive
          %Equal.sym(J.Admission.Result,result,J.Admission.commit(before,S.Sessions.cid(head),style,S.Sessions.name(head),choice),exact) : Creation.OK(seed,Creation.finish(_,before,head,others))
          %Equal.sym(Creation.Result,Creation.finish(J.Admission.commit(before,S.Sessions.cid(head),style,S.Sessions.name(head),choice),before,head,others),Creation.Result{J.Admission.state(J.Admission.commit(before,S.Sessions.cid(head),style,S.Sessions.name(head),choice)),Con{S.Sessions.bind(head,A.Allocation.id(choice)),others}},Creation.commit_finish(before,head,others,style,choice,pid_positive)) : Creation.OK(seed,_)
          Creation.commit_world(seed,before,head,others,style,choice,A.Allocation.Fresh{pid_positive,pid_available,next_positive},positive,available,ready,valid)

# The cosmetic/profile gate may reject for any reason. Only its accepting branch
# can allocate; world validity does not assume the gate accepts valid cosmetics.
def Creation.allow(permitted: Bool,+before: Sim.Simulation.State,+head: S.Sessions.State,others: List<&2,S.Sessions.State>,style: P.Players.Style) -> Creation.Result:
  match permitted:
    case False{}: Creation.Result{before,Con{head,others}}
    case True{}: Creation.finish(J.Admission.add(before,S.Sessions.cid(head),style,S.Sessions.name(head)),before,head,others)

law Creation.allow_ok:
  for +permitted: Bool
  for +seed: U32
  for +before: Sim.Simulation.State
  for +head: S.Sessions.State
  for +others: List<&2,S.Sessions.State>
  for +style: P.Players.Style
  for +ready: {S.Sessions.phase(head) == 1 : U32}
  for +valid: C.Connections.WorldOK<seed,before,Con{head,others}>
  Creation.OK(seed,Creation.allow(permitted,before,head,others,style))

def Creation.allow_ok(permitted,seed,before,head,others,style,ready,valid):
  match permitted:
    case False{}: valid
    case True{}: Creation.finish_ok(seed,before,head,others,style,J.Admission.add(before,S.Sessions.cid(head),style,S.Sessions.name(head)),J.Admission.add_outcome(before,S.Sessions.cid(head),style,S.Sessions.name(head)),ready,valid)

def Creation.ready_gate(ready: Bool,permitted: Bool,before: Sim.Simulation.State,head: S.Sessions.State,others: List<&2,S.Sessions.State>,style: P.Players.Style) -> Creation.Result:
  match ready:
    case False{}: Creation.Result{before,Con{head,others}}
    case True{}: Creation.allow(permitted,before,head,others,style)

def Creation.selected(before: Sim.Simulation.State,+head: S.Sessions.State,others: List<&2,S.Sessions.State>,style: P.Players.Style,permitted: Bool) -> Creation.Result: Creation.ready_gate(U32.is_eq(S.Sessions.phase(head),1),permitted,before,head,others,style)

law Creation.ready_ok:
  for +ready: Bool
  for +permitted: Bool
  for +seed: U32
  for +before: Sim.Simulation.State
  for +head: S.Sessions.State
  for +others: List<&2,S.Sessions.State>
  for +style: P.Players.Style
  for +decision: {U32.is_eq(S.Sessions.phase(head),1) == ready : Bool}
  for +valid: C.Connections.WorldOK<seed,before,Con{head,others}>
  Creation.OK(seed,Creation.ready_gate(ready,permitted,before,head,others,style))

def Creation.ready_ok(ready,permitted,seed,before,head,others,style,decision,valid):
  match ready:
    case False{}: valid
    case True{}: Creation.allow_ok(permitted,seed,before,head,others,style,N.Numeric.u32_eq_sound(S.Sessions.phase(head),1,decision),valid)

law Creation.selected_ok:
  for +seed: U32
  for +before: Sim.Simulation.State
  for +head: S.Sessions.State
  for +others: List<&2,S.Sessions.State>
  for +style: P.Players.Style
  for +permitted: Bool
  for +valid: C.Connections.WorldOK<seed,before,Con{head,others}>
  Creation.OK(seed,Creation.selected(before,head,others,style,permitted))

def Creation.selected_ok(seed,before,head,others,style,permitted,valid): Creation.ready_ok(U32.is_eq(S.Sessions.phase(head),1),permitted,seed,before,head,others,style,{==},valid)

def Creation.taken(taken: Q.Selection.Take,before: Sim.Simulation.State,style: P.Players.Style,permitted: Bool) -> Creation.Result:
  match taken:
    case Q.Selection.Take{others,found}:
      match found:
        case None{}: Creation.Result{before,others}
        case Some{head}: Creation.selected(before,head,others,style,permitted)

def Creation.create(before: Sim.Simulation.State,states: List<&2,S.Sessions.State>,cid: U32,style: P.Players.Style,permitted: Bool) -> Creation.Result: Creation.taken(Q.Selection.take(states,cid),before,style,permitted)

law Creation.taken_ok:
  for +taken: Q.Selection.Take
  for +seed: U32
  for +before: Sim.Simulation.State
  for +style: P.Players.Style
  for +permitted: Bool
  for +valid: C.Connections.WorldOK<seed,before,Q.Selection.restore(taken)>
  Creation.OK(seed,Creation.taken(taken,before,style,permitted))

def Creation.taken_ok(taken,seed,before,style,permitted,valid):
  match taken:
    case Q.Selection.Take{others,found}:
      match found:
        case None{}: valid
        case Some{head}: Creation.selected_ok(seed,before,head,others,style,permitted,valid)

law Creation.create_ok:
  for +seed: U32
  for +before: Sim.Simulation.State
  for +states: List<&2,S.Sessions.State>
  for +cid: U32
  for +style: P.Players.Style
  for +permitted: Bool
  for +valid: C.Connections.WorldOK<seed,before,states>
  Creation.OK(seed,Creation.create(before,states,cid,style,permitted))

def Creation.create_ok(seed,before,states,cid,style,permitted,valid): Creation.taken_ok(Q.Selection.take(states,cid),seed,before,style,permitted,Q.Selection.take_world(seed,before,states,cid,valid))

law Creation.finish_failed:
  for +before: Sim.Simulation.State
  for +candidate: Sim.Simulation.State
  for +head: S.Sessions.State
  for +others: List<&2,S.Sessions.State>
  {Creation.finish(J.Admission.Result{candidate,0},before,head,others) == Creation.Result{before,Con{head,others}} : Creation.Result}

def Creation.finish_failed(before,candidate,head,others): {==}

law Creation.unready:
  for +before: Sim.Simulation.State
  for +head: S.Sessions.State
  for +others: List<&2,S.Sessions.State>
  for +style: P.Players.Style
  for +permitted: Bool
  for +rejected: {U32.is_eq(S.Sessions.phase(head),1) == False{} : Bool}
  {Creation.selected(before,head,others,style,permitted) == Creation.Result{before,Con{head,others}} : Creation.Result}

def Creation.unready(before,head,others,style,permitted,rejected):
  %Equal.sym(Bool,U32.is_eq(S.Sessions.phase(head),1),False{},rejected) : {Creation.ready_gate(_,permitted,before,head,others,style) == Creation.Result{before,Con{head,others}} : Creation.Result}
  {==}

law Creation.denied_gate:
  for +ready: Bool
  for +before: Sim.Simulation.State
  for +head: S.Sessions.State
  for +others: List<&2,S.Sessions.State>
  for +style: P.Players.Style
  {Creation.ready_gate(ready,False{},before,head,others,style) == Creation.Result{before,Con{head,others}} : Creation.Result}

def Creation.denied_gate(ready,before,head,others,style):
  match ready:
    case False{}: {==}
    case True{}: {==}

law Creation.denied:
  for +before: Sim.Simulation.State
  for +head: S.Sessions.State
  for +others: List<&2,S.Sessions.State>
  for +style: P.Players.Style
  {Creation.selected(before,head,others,style,False{}) == Creation.Result{before,Con{head,others}} : Creation.Result}

def Creation.denied(before,head,others,style): Creation.denied_gate(U32.is_eq(S.Sessions.phase(head),1),before,head,others,style)

law Creation.missing:
  for +before: Sim.Simulation.State
  for +states: List<&2,S.Sessions.State>
  for +cid: U32
  for +style: P.Players.Style
  for +permitted: Bool
  for +absent: {Q.Selection.has_id(states,cid) == False{} : Bool}
  {Creation.create(before,states,cid,style,permitted) == Creation.Result{before,states} : Creation.Result}

def Creation.missing(before,states,cid,style,permitted,absent):
  %Equal.sym(Q.Selection.Take,Q.Selection.take(states,cid),Q.Selection.Take{states,None{}},Q.Selection.take_missing(states,cid,absent)) : {Creation.taken(_,before,style,permitted) == Creation.Result{before,states} : Creation.Result}
  {==}

# Arbitrary mixed sequences, with each CREATE updating the next step's world.
type Creation.Input is Data:
  Creation.Connect{hint: U32}
  Creation.Hello{cid: U32,name: List<&2,Char>}
  Creation.Create{cid: U32,style: P.Players.Style,permitted: Bool}

def Creation.step(input: Creation.Input,result: Creation.Result) -> Creation.Result:
  match input:
    case Creation.Connect{hint}:
      match result:
        case Creation.Result{world,states}:
          +states = states
          Creation.Result{world,C.Connections.admit(A.Allocation.find(C.Connections.cids(states),hint),states)}
    case Creation.Hello{cid,name}:
      match result:
        case Creation.Result{world,states}: Creation.Result{world,Q.Selection.hello(states,cid,name)}
    case Creation.Create{cid,style,permitted}:
      match result:
        case Creation.Result{world,states}: Creation.create(world,states,cid,style,permitted)

def Creation.trace(inputs: List<&2,Creation.Input>,result: Creation.Result) -> Creation.Result:
  match inputs:
    case Nil{}: result
    case Con{head,rest}: Creation.trace(rest,Creation.step(head,result))

law Creation.step_ok:
  for +input: Creation.Input
  for +seed: U32
  for +result: Creation.Result
  for +valid: Creation.OK(seed,result)
  Creation.OK(seed,Creation.step(input,result))

def Creation.step_ok(input,seed,result,valid):
  match input:
    case Creation.Connect{hint}:
      match result:
        case Creation.Result{world,states}: C.Connections.join_world(seed,world,states,hint,valid)
    case Creation.Hello{cid,name}:
      match result:
        case Creation.Result{world,states}: Q.Selection.hello_world(seed,world,states,cid,name,valid)
    case Creation.Create{cid,style,permitted}:
      match result:
        case Creation.Result{world,states}: Creation.create_ok(seed,world,states,cid,style,permitted,valid)

law Creation.trace_ok:
  for +inputs: List<&2,Creation.Input>
  for +seed: U32
  for +result: Creation.Result
  for +valid: Creation.OK(seed,result)
  Creation.OK(seed,Creation.trace(inputs,result))

def Creation.trace_ok(inputs,seed,result,valid):
  match inputs:
    case Nil{}: valid
    case Con{head,rest}: Creation.trace_ok(rest,seed,Creation.step(head,result),Creation.step_ok(head,seed,result,valid))


law Creation.fresh_trace:
  for +inputs: List<&2,Creation.Input>
  for +world: U32
  for +seed: U32
  for +now: U32
  Creation.OK(seed,Creation.trace(inputs,Creation.Result{Terrain.Terrain.simulation(Pop.Population.fresh(world,seed,now)),Nil{}}))

def Creation.fresh_trace(inputs,world,seed,now): Creation.trace_ok(inputs,seed,Creation.Result{Terrain.Terrain.simulation(Pop.Population.fresh(world,seed,now)),Nil{}},C.Connections.fresh_world(world,seed,now))
