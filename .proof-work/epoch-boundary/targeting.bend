# Authoritative AI candidate filtering and target selection.
import Base
import ./players.bend as P
import ./vitals.bend as V
import ./terrain.bend as T
import ./navigation.bend as N
import ./landscape.bend as L
import ./interactions.bend as Inter
import ./pursuit.bend as Q
import ./numeric.bend as Num
import ./references.bend as Ref
import ./monsters.bend as M
import ./planning.bend as Plan
import ./game.bend as G

type Targeting.Candidate is Data:
  Targeting.Candidate{pid: U32,x: U32,y: U32}

def Targeting.Candidates() -> Data: List<&2,Targeting.Candidate>

def Targeting.id(candidate: Targeting.Candidate) -> U32:
  match candidate:
    case Targeting.Candidate{pid,x,y}: pid

def Targeting.of_player(player: P.Players.State) -> Targeting.Candidate:
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match pos:
        case P.Players.Pos{zone,x,y,dir,moving}: Targeting.Candidate{pid,x,y}

def Targeting.position(player: P.Players.State) -> P.Players.Pos:
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}: pos

def Targeting.eligible(+player: P.Players.State,zone: U32) -> Bool:
  Bool.and(Bool.and(U32.is_eq(N.Navigation.zone(Targeting.position(player)),zone),U32.is_eq(V.Vitals.dead(P.Players.vitals(player)),0)),Bool.not(T.Terrain.in_village(Targeting.position(player))))

def Targeting.filter_gate(eligible: Bool,head: Targeting.Candidate,rest: Targeting.Candidates) -> Targeting.Candidates:
  match eligible:
    case True{}: Con{head,rest}
    case False{}: rest

def Targeting.filter(players: List<&2,P.Players.State>,+zone: U32) -> Targeting.Candidates:
  match players:
    case Nil{}: Nil{}
    case Con{head,rest}:
      +head = head
      Targeting.filter_gate(Targeting.eligible(head,zone),Targeting.of_player(head),Targeting.filter(rest,zone))

# First matching ID, preserving the legacy lookup behavior for duplicate inputs.
def Targeting.scan(tail: Targeting.Candidates,head: Targeting.Candidate,matches: Bool,+pid: U32) -> Maybe<&2,Targeting.Candidate>:
  match tail:
    case Nil{}:
      match matches:
        case True{}: Some{head}
        case False{}: None{}
    case Con{next,rest}:
      match matches:
        case True{}: Some{head}
        case False{}:
          +next = next
          Targeting.scan(rest,next,U32.is_eq(Targeting.id(next),pid),pid)

def Targeting.find(candidates: Targeting.Candidates,+pid: U32) -> Maybe<&2,Targeting.Candidate>:
  match candidates:
    case Nil{}: None{}
    case Con{head,rest}:
      +head = head
      Targeting.scan(rest,head,U32.is_eq(Targeting.id(head),pid),pid)

def Targeting.distance(x: U32,y: U32,candidate: Targeting.Candidate) -> U32:
  match candidate:
    case Targeting.Candidate{pid,tx,ty}:
      +dx = Inter.Interaction.distance(x,tx)
      +dy = Inter.Interaction.distance(y,ty)
      L.Landscape.pick(U32.is_ge(dx,dy),dx,dy)

type Targeting.Best is Data:
  Targeting.Best{pid: U32,distance: U32}

def Targeting.best_id(best: Targeting.Best) -> U32:
  match best:
    case Targeting.Best{pid,distance}: pid

def Targeting.best_distance(best: Targeting.Best) -> U32:
  match best:
    case Targeting.Best{pid,distance}: distance

def Targeting.better(closer: Bool,pid: U32,distance: U32,best: Targeting.Best) -> Targeting.Best:
  match closer:
    case True{}: Targeting.Best{pid,distance}
    case False{}: best

# Strict comparison retains the earlier candidate on a distance tie.
def Targeting.nearest(candidates: Targeting.Candidates,+x: U32,+y: U32,+best: Targeting.Best) -> Targeting.Best:
  match candidates:
    case Nil{}: best
    case Con{head,rest}:
      +head = head
      +distance = Targeting.distance(x,y,head)
      Targeting.nearest(rest,x,y,Targeting.better(U32.is_lt(distance,Targeting.best_distance(best)),Targeting.id(head),distance,best))

def Targeting.absent() -> Q.Pursuit.Target: Q.Pursuit.Target{0,0,0,False{}}

def Targeting.present(candidate: Targeting.Candidate) -> Q.Pursuit.Target:
  match candidate:
    case Targeting.Candidate{pid,x,y}: Q.Pursuit.Target{pid,x,y,True{}}

def Targeting.found(found: Maybe<&2,Targeting.Candidate>) -> Q.Pursuit.Target:
  match found:
    case None{}: Targeting.absent
    case Some{candidate}: Targeting.present(candidate)

def Targeting.acquire_id(zero: Bool,candidates: Targeting.Candidates,pid: U32) -> Q.Pursuit.Target:
  match zero:
    case True{}: Targeting.absent
    case False{}: Targeting.found(Targeting.find(candidates,pid))

def Targeting.acquire(+candidates: Targeting.Candidates,x: U32,y: U32) -> Q.Pursuit.Target:
  +pid = Targeting.best_id(Targeting.nearest(candidates,x,y,Targeting.Best{0,4}))
  Targeting.acquire_id(U32.is_eq(pid,0),candidates,pid)

def Targeting.keep_near(near: Bool,candidate: Targeting.Candidate,candidates: Targeting.Candidates,x: U32,y: U32) -> Q.Pursuit.Target:
  match near:
    case True{}: Targeting.present(candidate)
    case False{}: Targeting.acquire(candidates,x,y)

def Targeting.keep_found(found: Maybe<&2,Targeting.Candidate>,candidates: Targeting.Candidates,+x: U32,+y: U32) -> Q.Pursuit.Target:
  match found:
    case None{}: Targeting.acquire(candidates,x,y)
    case Some{candidate}:
      +candidate = candidate
      Targeting.keep_near(U32.is_le(Targeting.distance(x,y,candidate),9),candidate,candidates,x,y)

def Targeting.keep_gate(zero: Bool,+candidates: Targeting.Candidates,+pid: U32,x: U32,y: U32) -> Q.Pursuit.Target:
  match zero:
    case True{}: Targeting.acquire(candidates,x,y)
    case False{}: Targeting.keep_found(Targeting.find(candidates,pid),candidates,x,y)

def Targeting.keep(candidates: Targeting.Candidates,+pid: U32,x: U32,y: U32) -> Q.Pursuit.Target:
  Targeting.keep_gate(U32.is_eq(pid,0),candidates,pid,x,y)

def Targeting.select(players: List<&2,P.Players.State>,zone: U32,pid: U32,x: U32,y: U32) -> Q.Pursuit.Target:
  Targeting.keep(Targeting.filter(players,zone),pid,x,y)

def Targeting.context(result: M.Monsters.Tick,candidates: Targeting.Candidates,damage: U32) -> Plan.Planning.Context:
  match result:
    case M.Monsters.Tick{monster,phase}:
      match monster:
        case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}: Plan.Planning.Context{Targeting.keep(candidates,target,x,y),damage}

# Full-record membership witnesses connect candidate coordinates and eligibility
# to an actual player in the supplied roster, even with duplicate input IDs.
type Targeting.In<-player: P.Players.State,-players: List<&2,P.Players.State>> is Data:
  Targeting.Here{rest: List<&2,P.Players.State>,shape: {players == Con{player,rest} : List<&2,P.Players.State>}}
  Targeting.There{head: P.Players.State,rest: List<&2,P.Players.State>,shape: {players == Con{head,rest} : List<&2,P.Players.State>},inside: Targeting.In<player,rest>}

type Targeting.Source<-players: List<&2,P.Players.State>,-zone: U32,-candidate: Targeting.Candidate> is Data:
  Targeting.Source{player: P.Players.State,inside: Targeting.In<player,players>,exact: {candidate == Targeting.of_player(player) : Targeting.Candidate},eligible: {Targeting.eligible(player,zone) == True{} : Bool}}

def Targeting.Sources(+players: List<&2,P.Players.State>,+zone: U32,candidates: Targeting.Candidates) -> Data:
  match candidates:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,Targeting.Source<players,zone,head>,(source => Targeting.Sources(players,zone,rest))>

def Targeting.FoundSource(players: List<&2,P.Players.State>,zone: U32,found: Maybe<&2,Targeting.Candidate>) -> Data:
  match found:
    case None{}: Unit
    case Some{candidate}: Targeting.Source<players,zone,candidate>

type Targeting.Selected<-players: List<&2,P.Players.State>,-zone: U32,-target: Q.Pursuit.Target> is Data:
  Targeting.Missing{exact: {target == Targeting.absent : Q.Pursuit.Target}}
  Targeting.Selected{candidate: Targeting.Candidate,exact: {target == Targeting.present(candidate) : Q.Pursuit.Target},source: Targeting.Source<players,zone,candidate>}

law Targeting.weaken_source:
  for +head: P.Players.State
  for +players: List<&2,P.Players.State>
  for +zone: U32
  for +candidate: Targeting.Candidate
  for +source: Targeting.Source<players,zone,candidate>
  Targeting.Source<Con{head,players},zone,candidate>

def Targeting.weaken_source(head,players,zone,candidate,source):
  match source:
    case Targeting.Source{player,inside,exact,eligible}: Targeting.Source{player,Targeting.There{head,players,{==},inside},exact,eligible}

law Targeting.weaken_sources:
  for +candidates: Targeting.Candidates
  for +head: P.Players.State
  for +players: List<&2,P.Players.State>
  for +zone: U32
  for +sources: Targeting.Sources(players,zone,candidates)
  Targeting.Sources(Con{head,players},zone,candidates)

def Targeting.weaken_sources(candidates,head,players,zone,sources):
  match candidates:
    case Nil{}: Unit{}
    case Con{candidate,rest}:
      match sources:
        case Tuple{source,remaining}: Tuple{Targeting.weaken_source(head,players,zone,candidate,source),Targeting.weaken_sources(rest,head,players,zone,remaining)}

law Targeting.filter_gate_sources:
  for +flag: Bool
  for +head: P.Players.State
  for +players: List<&2,P.Players.State>
  for +zone: U32
  for +candidates: Targeting.Candidates
  for +decision: {Targeting.eligible(head,zone) == flag : Bool}
  for +sources: Targeting.Sources(Con{head,players},zone,candidates)
  Targeting.Sources(Con{head,players},zone,Targeting.filter_gate(flag,Targeting.of_player(head),candidates))

def Targeting.filter_gate_sources(flag,head,players,zone,candidates,decision,sources):
  match flag:
    case True{}: Tuple{Targeting.Source{head,Targeting.Here{players,{==}},{==},decision},sources}
    case False{}: sources

law Targeting.filter_sources:
  for +players: List<&2,P.Players.State>
  for +zone: U32
  Targeting.Sources(players,zone,Targeting.filter(players,zone))

def Targeting.filter_sources(players,zone):
  match players:
    case Nil{}: Unit{}
    case Con{head,rest}: Targeting.filter_gate_sources(Targeting.eligible(head,zone),head,rest,zone,Targeting.filter(rest,zone),{==},Targeting.weaken_sources(Targeting.filter(rest,zone),head,rest,zone,Targeting.filter_sources(rest,zone)))

law Targeting.scan_source:
  for +tail: Targeting.Candidates
  for +head: Targeting.Candidate
  for +matches: Bool
  for +pid: U32
  for +players: List<&2,P.Players.State>
  for +zone: U32
  for +head_source: Targeting.Source<players,zone,head>
  for +sources: Targeting.Sources(players,zone,tail)
  Targeting.FoundSource(players,zone,Targeting.scan(tail,head,matches,pid))

def Targeting.scan_source(tail,head,matches,pid,players,zone,head_source,sources):
  match tail:
    case Nil{}:
      match matches:
        case True{}: head_source
        case False{}: Unit{}
    case Con{next,rest}:
      match matches:
        case True{}: head_source
        case False{}:
          match sources:
            case Tuple{next_source,remaining}: Targeting.scan_source(rest,next,U32.is_eq(Targeting.id(next),pid),pid,players,zone,next_source,remaining)

law Targeting.find_source:
  for +candidates: Targeting.Candidates
  for +pid: U32
  for +players: List<&2,P.Players.State>
  for +zone: U32
  for +sources: Targeting.Sources(players,zone,candidates)
  Targeting.FoundSource(players,zone,Targeting.find(candidates,pid))

def Targeting.find_source(candidates,pid,players,zone,sources):
  match candidates:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match sources:
        case Tuple{head_source,remaining}: Targeting.scan_source(rest,head,U32.is_eq(Targeting.id(head),pid),pid,players,zone,head_source,remaining)

law Targeting.found_selected:
  for +found: Maybe<&2,Targeting.Candidate>
  for +players: List<&2,P.Players.State>
  for +zone: U32
  for +source: Targeting.FoundSource(players,zone,found)
  Targeting.Selected<players,zone,Targeting.found(found)>

def Targeting.found_selected(found,players,zone,source):
  match found:
    case None{}: Targeting.Missing{{==}}
    case Some{candidate}: Targeting.Selected{candidate,{==},source}

law Targeting.acquire_id_selected:
  for +zero: Bool
  for +candidates: Targeting.Candidates
  for +pid: U32
  for +players: List<&2,P.Players.State>
  for +zone: U32
  for +sources: Targeting.Sources(players,zone,candidates)
  Targeting.Selected<players,zone,Targeting.acquire_id(zero,candidates,pid)>

def Targeting.acquire_id_selected(zero,candidates,pid,players,zone,sources):
  match zero:
    case True{}: Targeting.Missing{{==}}
    case False{}: Targeting.found_selected(Targeting.find(candidates,pid),players,zone,Targeting.find_source(candidates,pid,players,zone,sources))

law Targeting.acquire_selected:
  for +candidates: Targeting.Candidates
  for +x: U32
  for +y: U32
  for +players: List<&2,P.Players.State>
  for +zone: U32
  for +sources: Targeting.Sources(players,zone,candidates)
  Targeting.Selected<players,zone,Targeting.acquire(candidates,x,y)>

def Targeting.acquire_selected(candidates,x,y,players,zone,sources):
  +pid = Targeting.best_id(Targeting.nearest(candidates,x,y,Targeting.Best{0,4}))
  Targeting.acquire_id_selected(U32.is_eq(pid,0),candidates,pid,players,zone,sources)

law Targeting.keep_near_selected:
  for +near: Bool
  for +candidate: Targeting.Candidate
  for +candidates: Targeting.Candidates
  for +x: U32
  for +y: U32
  for +players: List<&2,P.Players.State>
  for +zone: U32
  for +source: Targeting.Source<players,zone,candidate>
  for +sources: Targeting.Sources(players,zone,candidates)
  Targeting.Selected<players,zone,Targeting.keep_near(near,candidate,candidates,x,y)>

def Targeting.keep_near_selected(near,candidate,candidates,x,y,players,zone,source,sources):
  match near:
    case True{}: Targeting.Selected{candidate,{==},source}
    case False{}: Targeting.acquire_selected(candidates,x,y,players,zone,sources)

law Targeting.keep_found_selected:
  for +found: Maybe<&2,Targeting.Candidate>
  for +candidates: Targeting.Candidates
  for +x: U32
  for +y: U32
  for +players: List<&2,P.Players.State>
  for +zone: U32
  for +source: Targeting.FoundSource(players,zone,found)
  for +sources: Targeting.Sources(players,zone,candidates)
  Targeting.Selected<players,zone,Targeting.keep_found(found,candidates,x,y)>

def Targeting.keep_found_selected(found,candidates,x,y,players,zone,source,sources):
  match found:
    case None{}: Targeting.acquire_selected(candidates,x,y,players,zone,sources)
    case Some{candidate}: Targeting.keep_near_selected(U32.is_le(Targeting.distance(x,y,candidate),9),candidate,candidates,x,y,players,zone,source,sources)

law Targeting.keep_gate_selected:
  for +zero: Bool
  for +candidates: Targeting.Candidates
  for +pid: U32
  for +x: U32
  for +y: U32
  for +players: List<&2,P.Players.State>
  for +zone: U32
  for +sources: Targeting.Sources(players,zone,candidates)
  Targeting.Selected<players,zone,Targeting.keep_gate(zero,candidates,pid,x,y)>

def Targeting.keep_gate_selected(zero,candidates,pid,x,y,players,zone,sources):
  match zero:
    case True{}: Targeting.acquire_selected(candidates,x,y,players,zone,sources)
    case False{}: Targeting.keep_found_selected(Targeting.find(candidates,pid),candidates,x,y,players,zone,Targeting.find_source(candidates,pid,players,zone,sources),sources)

law Targeting.keep_selected:
  for +candidates: Targeting.Candidates
  for +pid: U32
  for +x: U32
  for +y: U32
  for +players: List<&2,P.Players.State>
  for +zone: U32
  for +sources: Targeting.Sources(players,zone,candidates)
  Targeting.Selected<players,zone,Targeting.keep(candidates,pid,x,y)>

def Targeting.keep_selected(candidates,pid,x,y,players,zone,sources): Targeting.keep_gate_selected(U32.is_eq(pid,0),candidates,pid,x,y,players,zone,sources)

law Targeting.select_source:
  for +players: List<&2,P.Players.State>
  for +zone: U32
  for +pid: U32
  for +x: U32
  for +y: U32
  Targeting.Selected<players,zone,Targeting.select(players,zone,pid,x,y)>

def Targeting.select_source(players,zone,pid,x,y): Targeting.keep_selected(Targeting.filter(players,zone),pid,x,y,players,zone,Targeting.filter_sources(players,zone))

law Targeting.or_right:
  for +left: Bool
  for +right: Bool
  for +valid: {right == True{} : Bool}
  {Bool.or(left,right) == True{} : Bool}

def Targeting.or_right(left,right,valid):
  match left:
    case True{}: {==}
    case False{}: valid

law Targeting.in_has:
  for +player: P.Players.State
  for -players: List<&2,P.Players.State>
  for +inside: Targeting.In<player,players>
  {P.Players.has_id(players,P.Players.id(player)) == True{} : Bool}

def Targeting.in_has(player,players,inside):
  match inside:
    case Targeting.Here{rest,shape}:
      %Equal.sym(List<&2,P.Players.State>,players,Con{player,rest},shape) : {P.Players.has_id(_,P.Players.id(player)) == True{} : Bool}
      %Equal.sym(Bool,U32.is_eq(P.Players.id(player),P.Players.id(player)),True{},Num.Numeric.u32_eq_refl(P.Players.id(player))) : {Bool.or(_,P.Players.has_id(rest,P.Players.id(player))) == True{} : Bool}
      {==}
    case Targeting.There{head,rest,shape,earlier}:
      %Equal.sym(List<&2,P.Players.State>,players,Con{head,rest},shape) : {P.Players.has_id(_,P.Players.id(player)) == True{} : Bool}
      Targeting.or_right(U32.is_eq(P.Players.id(head),P.Players.id(player)),P.Players.has_id(rest,P.Players.id(player)),Targeting.in_has(player,rest,earlier))

law Targeting.of_player_id:
  for +player: P.Players.State
  {Targeting.id(Targeting.of_player(player)) == P.Players.id(player) : U32}

def Targeting.of_player_id(player):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match pos:
        case P.Players.Pos{zone,x,y,dir,moving}: {==}

law Targeting.source_has:
  for +players: List<&2,P.Players.State>
  for +zone: U32
  for +candidate: Targeting.Candidate
  for +source: Targeting.Source<players,zone,candidate>
  {P.Players.has_id(players,Targeting.id(candidate)) == True{} : Bool}

def Targeting.source_has(players,zone,candidate,source):
  match source:
    case Targeting.Source{player,inside,exact,eligible}:
      %Equal.sym(Targeting.Candidate,candidate,Targeting.of_player(player),exact) : {P.Players.has_id(players,Targeting.id(_)) == True{} : Bool}
      %Equal.sym(U32,Targeting.id(Targeting.of_player(player)),P.Players.id(player),Targeting.of_player_id(player)) : {P.Players.has_id(players,_) == True{} : Bool}
      Targeting.in_has(player,players,inside)

def Targeting.target_id(target: Q.Pursuit.Target) -> U32:
  match target:
    case Q.Pursuit.Target{pid,x,y,present}: pid

law Targeting.present_id:
  for +candidate: Targeting.Candidate
  {Targeting.target_id(Targeting.present(candidate)) == Targeting.id(candidate) : U32}

def Targeting.present_id(candidate):
  match candidate:
    case Targeting.Candidate{pid,x,y}: {==}

law Targeting.selected_exists:
  for +players: List<&2,P.Players.State>
  for +zone: U32
  for +target: Q.Pursuit.Target
  for +selected: Targeting.Selected<players,zone,target>
  {Ref.References.exists(players,Targeting.target_id(target)) == True{} : Bool}

def Targeting.selected_exists(players,zone,target,selected):
  match selected:
    case Targeting.Missing{exact}:
      %Equal.sym(Q.Pursuit.Target,target,Targeting.absent,exact) : {Ref.References.exists(players,Targeting.target_id(_)) == True{} : Bool}
      {==}
    case Targeting.Selected{candidate,exact,source}:
      %Equal.sym(Q.Pursuit.Target,target,Targeting.present(candidate),exact) : {Ref.References.exists(players,Targeting.target_id(_)) == True{} : Bool}
      %Equal.sym(U32,Targeting.target_id(Targeting.present(candidate)),Targeting.id(candidate),Targeting.present_id(candidate)) : {Ref.References.exists(players,_) == True{} : Bool}
      Targeting.or_right(U32.is_eq(Targeting.id(candidate),0),P.Players.has_id(players,Targeting.id(candidate)),Targeting.source_has(players,zone,candidate,source))

law Targeting.select_exists:
  for +players: List<&2,P.Players.State>
  for +zone: U32
  for +pid: U32
  for +x: U32
  for +y: U32
  {Ref.References.exists(players,Targeting.target_id(Targeting.select(players,zone,pid,x,y))) == True{} : Bool}

def Targeting.select_exists(players,zone,pid,x,y): Targeting.selected_exists(players,zone,Targeting.select(players,zone,pid,x,y),Targeting.select_source(players,zone,pid,x,y))

law Targeting.and_left:
  for +a: Bool
  for +b: Bool
  for +valid: {Bool.and(a,b) == True{} : Bool}
  {a == True{} : Bool}

def Targeting.and_left(a,b,valid):
  match a:
    case True{}: {==}
    case False{}: valid

law Targeting.and_right:
  for +a: Bool
  for +b: Bool
  for +valid: {Bool.and(a,b) == True{} : Bool}
  {b == True{} : Bool}

def Targeting.and_right(a,b,valid):
  match a:
    case True{}: valid
    case False{}: Empty.absurd({b == True{} : Bool},G.Bq.Bool.false_ne_true(valid))

law Targeting.eligible_zone:
  for +player: P.Players.State
  for +zone: U32
  for +eligible: {Targeting.eligible(player,zone) == True{} : Bool}
  {U32.is_eq(N.Navigation.zone(Targeting.position(player)),zone) == True{} : Bool}

def Targeting.eligible_zone(player,zone,eligible):
  +a = U32.is_eq(N.Navigation.zone(Targeting.position(player)),zone)
  +b = U32.is_eq(V.Vitals.dead(P.Players.vitals(player)),0)
  +c = Bool.not(T.Terrain.in_village(Targeting.position(player)))
  Targeting.and_left(a,b,Targeting.and_left(Bool.and(a,b),c,eligible))

law Targeting.eligible_live:
  for +player: P.Players.State
  for +zone: U32
  for +eligible: {Targeting.eligible(player,zone) == True{} : Bool}
  {U32.is_eq(V.Vitals.dead(P.Players.vitals(player)),0) == True{} : Bool}

def Targeting.eligible_live(player,zone,eligible):
  +a = U32.is_eq(N.Navigation.zone(Targeting.position(player)),zone)
  +b = U32.is_eq(V.Vitals.dead(P.Players.vitals(player)),0)
  +c = Bool.not(T.Terrain.in_village(Targeting.position(player)))
  Targeting.and_right(a,b,Targeting.and_left(Bool.and(a,b),c,eligible))

law Targeting.eligible_outside:
  for +player: P.Players.State
  for +zone: U32
  for +eligible: {Targeting.eligible(player,zone) == True{} : Bool}
  {Bool.not(T.Terrain.in_village(Targeting.position(player))) == True{} : Bool}

def Targeting.eligible_outside(player,zone,eligible): Targeting.and_right(Bool.and(U32.is_eq(N.Navigation.zone(Targeting.position(player)),zone),U32.is_eq(V.Vitals.dead(P.Players.vitals(player)),0)),Bool.not(T.Terrain.in_village(Targeting.position(player))),eligible)

def Targeting.context_target(context: Plan.Planning.Context) -> Q.Pursuit.Target:
  match context:
    case Plan.Planning.Context{target,damage}: target

law Targeting.context_selected:
  for +result: M.Monsters.Tick
  for +candidates: Targeting.Candidates
  for +damage: U32
  for +players: List<&2,P.Players.State>
  for +zone: U32
  for +sources: Targeting.Sources(players,zone,candidates)
  Targeting.Selected<players,zone,Targeting.context_target(Targeting.context(result,candidates,damage))>

def Targeting.context_selected(result,candidates,damage,players,zone,sources):
  match result:
    case M.Monsters.Tick{monster,phase}:
      match monster:
        case M.Monsters.State{mid,kind,rare,mzone,x,y,hp,maximum,target,attack,dead,respawn}: Targeting.keep_selected(candidates,target,x,y,players,zone,sources)

def Targeting.FoundID(found: Maybe<&2,Targeting.Candidate>,pid: U32) -> Data:
  match found:
    case None{}: Unit
    case Some{candidate}: {Targeting.id(candidate) == pid : U32}

law Targeting.scan_id:
  for +tail: Targeting.Candidates
  for +head: Targeting.Candidate
  for +matches: Bool
  for +pid: U32
  for +decision: {U32.is_eq(Targeting.id(head),pid) == matches : Bool}
  Targeting.FoundID(Targeting.scan(tail,head,matches,pid),pid)

def Targeting.scan_id(tail,head,matches,pid,decision):
  match tail:
    case Nil{}:
      match matches:
        case True{}: Num.Numeric.u32_eq_sound(Targeting.id(head),pid,decision)
        case False{}: Unit{}
    case Con{next,rest}:
      match matches:
        case True{}: Num.Numeric.u32_eq_sound(Targeting.id(head),pid,decision)
        case False{}: Targeting.scan_id(rest,next,U32.is_eq(Targeting.id(next),pid),pid,{==})

law Targeting.find_id:
  for +candidates: Targeting.Candidates
  for +pid: U32
  Targeting.FoundID(Targeting.find(candidates,pid),pid)

def Targeting.find_id(candidates,pid):
  match candidates:
    case Nil{}: Unit{}
    case Con{head,rest}: Targeting.scan_id(rest,head,U32.is_eq(Targeting.id(head),pid),pid,{==})

law Targeting.scan_hit:
  for +tail: Targeting.Candidates
  for +head: Targeting.Candidate
  for +pid: U32
  {Targeting.scan(tail,head,True{},pid) == Some{head} : Maybe<&2,Targeting.Candidate>}

def Targeting.scan_hit(tail,head,pid):
  match tail:
    case Nil{}: {==}
    case Con{next,rest}: {==}

law Targeting.find_head:
  for +head: Targeting.Candidate
  for +tail: Targeting.Candidates
  {Targeting.find(Con{head,tail},Targeting.id(head)) == Some{head} : Maybe<&2,Targeting.Candidate>}

def Targeting.find_head(head,tail):
  %Equal.sym(Bool,U32.is_eq(Targeting.id(head),Targeting.id(head)),True{},Num.Numeric.u32_eq_refl(Targeting.id(head))) : {Targeting.scan(tail,head,_,Targeting.id(head)) == Some{head} : Maybe<&2,Targeting.Candidate>}
  Targeting.scan_hit(tail,head,Targeting.id(head))

law Targeting.keep_zero:
  for +candidates: Targeting.Candidates
  for +x: U32
  for +y: U32
  {Targeting.keep(candidates,0,x,y) == Targeting.acquire(candidates,x,y) : Q.Pursuit.Target}

def Targeting.keep_zero(candidates,x,y): {==}

law Targeting.keep_retains:
  for +candidates: Targeting.Candidates
  for +pid: U32
  for +x: U32
  for +y: U32
  for +candidate: Targeting.Candidate
  for +nonzero: {U32.is_eq(pid,0) == False{} : Bool}
  for +found: {Targeting.find(candidates,pid) == Some{candidate} : Maybe<&2,Targeting.Candidate>}
  for +near: {U32.is_le(Targeting.distance(x,y,candidate),9) == True{} : Bool}
  {Targeting.keep(candidates,pid,x,y) == Targeting.present(candidate) : Q.Pursuit.Target}

def Targeting.keep_retains(candidates,pid,x,y,candidate,nonzero,found,near):
  %Equal.sym(Bool,U32.is_eq(pid,0),False{},nonzero) : {Targeting.keep_gate(_,candidates,pid,x,y) == Targeting.present(candidate) : Q.Pursuit.Target}
  %Equal.sym(Maybe<&2,Targeting.Candidate>,Targeting.find(candidates,pid),Some{candidate},found) : {Targeting.keep_found(_,candidates,x,y) == Targeting.present(candidate) : Q.Pursuit.Target}
  %Equal.sym(Bool,U32.is_le(Targeting.distance(x,y,candidate),9),True{},near) : {Targeting.keep_near(_,candidate,candidates,x,y) == Targeting.present(candidate) : Q.Pursuit.Target}
  {==}

law Targeting.keep_far:
  for +candidates: Targeting.Candidates
  for +pid: U32
  for +x: U32
  for +y: U32
  for +candidate: Targeting.Candidate
  for +nonzero: {U32.is_eq(pid,0) == False{} : Bool}
  for +found: {Targeting.find(candidates,pid) == Some{candidate} : Maybe<&2,Targeting.Candidate>}
  for +far: {U32.is_le(Targeting.distance(x,y,candidate),9) == False{} : Bool}
  {Targeting.keep(candidates,pid,x,y) == Targeting.acquire(candidates,x,y) : Q.Pursuit.Target}

def Targeting.keep_far(candidates,pid,x,y,candidate,nonzero,found,far):
  %Equal.sym(Bool,U32.is_eq(pid,0),False{},nonzero) : {Targeting.keep_gate(_,candidates,pid,x,y) == Targeting.acquire(candidates,x,y) : Q.Pursuit.Target}
  %Equal.sym(Maybe<&2,Targeting.Candidate>,Targeting.find(candidates,pid),Some{candidate},found) : {Targeting.keep_found(_,candidates,x,y) == Targeting.acquire(candidates,x,y) : Q.Pursuit.Target}
  %Equal.sym(Bool,U32.is_le(Targeting.distance(x,y,candidate),9),False{},far) : {Targeting.keep_near(_,candidate,candidates,x,y) == Targeting.acquire(candidates,x,y) : Q.Pursuit.Target}
  {==}

law Targeting.keep_missing:
  for +candidates: Targeting.Candidates
  for +pid: U32
  for +x: U32
  for +y: U32
  for +nonzero: {U32.is_eq(pid,0) == False{} : Bool}
  for +missing: {Targeting.find(candidates,pid) == None{} : Maybe<&2,Targeting.Candidate>}
  {Targeting.keep(candidates,pid,x,y) == Targeting.acquire(candidates,x,y) : Q.Pursuit.Target}

def Targeting.keep_missing(candidates,pid,x,y,nonzero,missing):
  %Equal.sym(Bool,U32.is_eq(pid,0),False{},nonzero) : {Targeting.keep_gate(_,candidates,pid,x,y) == Targeting.acquire(candidates,x,y) : Q.Pursuit.Target}
  %Equal.sym(Maybe<&2,Targeting.Candidate>,Targeting.find(candidates,pid),None{},missing) : {Targeting.keep_found(_,candidates,x,y) == Targeting.acquire(candidates,x,y) : Q.Pursuit.Target}
  {==}

law Targeting.acquire_empty:
  for +x: U32
  for +y: U32
  {Targeting.acquire(Nil{},x,y) == Targeting.absent : Q.Pursuit.Target}

def Targeting.acquire_empty(x,y): {==}

# Damage amounts are separate inputs; they cannot affect target provenance.
def Targeting.contexts(monsters: List<&2,M.Monsters.State>,+candidates: Targeting.Candidates,damages: List<&2,U32>) -> List<&2,Plan.Planning.Context>:
  match monsters:
    case Nil{}: Nil{}
    case Con{head,rest}:
      match damages:
        case Nil{}: Con{Targeting.context(M.Monsters.tick(head),candidates,0),Targeting.contexts(rest,candidates,Nil{})}
        case Con{damage,later}: Con{Targeting.context(M.Monsters.tick(head),candidates,damage),Targeting.contexts(rest,candidates,later)}

def Targeting.Contexts(+players: List<&2,P.Players.State>,+zone: U32,contexts: List<&2,Plan.Planning.Context>) -> Data:
  match contexts:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,Targeting.Selected<players,zone,Targeting.context_target(head)>,(selected => Targeting.Contexts(players,zone,rest))>

law Targeting.contexts_selected:
  for +monsters: List<&2,M.Monsters.State>
  for +candidates: Targeting.Candidates
  for +damages: List<&2,U32>
  for +players: List<&2,P.Players.State>
  for +zone: U32
  for +sources: Targeting.Sources(players,zone,candidates)
  Targeting.Contexts(players,zone,Targeting.contexts(monsters,candidates,damages))

def Targeting.contexts_selected(monsters,candidates,damages,players,zone,sources):
  match monsters:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match damages:
        case Nil{}: Tuple{Targeting.context_selected(M.Monsters.tick(head),candidates,0,players,zone,sources),Targeting.contexts_selected(rest,candidates,Nil{},players,zone,sources)}
        case Con{damage,later}: Tuple{Targeting.context_selected(M.Monsters.tick(head),candidates,damage,players,zone,sources),Targeting.contexts_selected(rest,candidates,later,players,zone,sources)}

law Targeting.filtered_contexts:
  for +monsters: List<&2,M.Monsters.State>
  for +players: List<&2,P.Players.State>
  for +zone: U32
  for +damages: List<&2,U32>
  Targeting.Contexts(players,zone,Targeting.contexts(monsters,Targeting.filter(players,zone),damages))

def Targeting.filtered_contexts(monsters,players,zone,damages): Targeting.contexts_selected(monsters,Targeting.filter(players,zone),damages,players,zone,Targeting.filter_sources(players,zone))

law Targeting.of_player_coordinates:
  for +player: P.Players.State
  {Targeting.of_player(player) == Targeting.Candidate{P.Players.id(player),N.Navigation.x(Targeting.position(player)),N.Navigation.y(Targeting.position(player))} : Targeting.Candidate}

def Targeting.of_player_coordinates(player):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match pos:
        case P.Players.Pos{zone,x,y,dir,moving}: {==}

law Targeting.nearest_empty:
  for +x: U32
  for +y: U32
  for +best: Targeting.Best
  {Targeting.nearest(Nil{},x,y,best) == best : Targeting.Best}

def Targeting.nearest_empty(x,y,best): {==}

law Targeting.nearest_skips:
  for +head: Targeting.Candidate
  for +rest: Targeting.Candidates
  for +x: U32
  for +y: U32
  for +best: Targeting.Best
  for +not_closer: {U32.is_lt(Targeting.distance(x,y,head),Targeting.best_distance(best)) == False{} : Bool}
  {Targeting.nearest(Con{head,rest},x,y,best) == Targeting.nearest(rest,x,y,best) : Targeting.Best}

def Targeting.nearest_skips(head,rest,x,y,best,not_closer):
  %Equal.sym(Bool,U32.is_lt(Targeting.distance(x,y,head),Targeting.best_distance(best)),False{},not_closer) : {Targeting.nearest(rest,x,y,Targeting.better(_,Targeting.id(head),Targeting.distance(x,y,head),best)) == Targeting.nearest(rest,x,y,best) : Targeting.Best}
  {==}

law Targeting.nearest_picks:
  for +head: Targeting.Candidate
  for +rest: Targeting.Candidates
  for +x: U32
  for +y: U32
  for +best: Targeting.Best
  for +closer: {U32.is_lt(Targeting.distance(x,y,head),Targeting.best_distance(best)) == True{} : Bool}
  {Targeting.nearest(Con{head,rest},x,y,best) == Targeting.nearest(rest,x,y,Targeting.Best{Targeting.id(head),Targeting.distance(x,y,head)}) : Targeting.Best}

def Targeting.nearest_picks(head,rest,x,y,best,closer):
  %Equal.sym(Bool,U32.is_lt(Targeting.distance(x,y,head),Targeting.best_distance(best)),True{},closer) : {Targeting.nearest(rest,x,y,Targeting.better(_,Targeting.id(head),Targeting.distance(x,y,head),best)) == Targeting.nearest(rest,x,y,Targeting.Best{Targeting.id(head),Targeting.distance(x,y,head)}) : Targeting.Best}
  {==}

law Targeting.acquire_refines:
  for +candidates: Targeting.Candidates
  for +x: U32
  for +y: U32
  {Targeting.acquire(candidates,x,y) == Targeting.acquire_id(U32.is_eq(Targeting.best_id(Targeting.nearest(candidates,x,y,Targeting.Best{0,4})),0),candidates,Targeting.best_id(Targeting.nearest(candidates,x,y,Targeting.Best{0,4}))) : Q.Pursuit.Target}

def Targeting.acquire_refines(candidates,x,y): {==}
