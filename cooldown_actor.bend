# Recover the actual player record from a live tick's paired cooldown frames.
import Base
import ./cooldown_roster.bend as TC
import ./players.bend as P
import ./targeting.bend as T
import ./numeric.bend as N
import ./player_membership.bend as PM
import ./combat_repeat.bend as Repeat
import ./playerids.bend as Id
import ./allocation.bend as A
import ./admission.bend as J
import ./simulation.bend as S
import ./terrain.bend as Terrain
import ./live_tick.bend as L
import ./seeded_world.bend as SW
import ./connections.bend as Conn
import ./worldstate.bend as W
import ./sessions.bend as Sess

type Tracked.In<-frame: TC.TickCooldown.Frame,-frames: List<&2,TC.TickCooldown.Frame>> is Data:
  Tracked.Here{rest: List<&2,TC.TickCooldown.Frame>,shape: {frames == Con{frame,rest} : List<&2,TC.TickCooldown.Frame>}}
  Tracked.There{head: TC.TickCooldown.Frame,rest: List<&2,TC.TickCooldown.Frame>,shape: {frames == Con{head,rest} : List<&2,TC.TickCooldown.Frame>},inside: Tracked.In<frame,rest>}

def Tracked.first(headers: List<&2,TC.TickCooldown.Frame>,fallback: TC.TickCooldown.Frame) -> TC.TickCooldown.Frame:
  match headers:
    case Nil{}: fallback
    case Con{head,rest}: head

def Tracked.rest(headers: List<&2,TC.TickCooldown.Frame>) -> List<&2,TC.TickCooldown.Frame>:
  match headers:
    case Nil{}: Nil{}
    case Con{head,rest}: rest

def Tracked.nonempty(headers: List<&2,TC.TickCooldown.Frame>) -> Bool:
  match headers:
    case Nil{}: False{}
    case Con{head,rest}: True{}

law Tracked.nil_cons:
  for +head: TC.TickCooldown.Frame
  for +rest: List<&2,TC.TickCooldown.Frame>
  for +same: {Nil{} == Con{head,rest} : List<&2,TC.TickCooldown.Frame>}
  Empty

def Tracked.nil_cons(head,rest,same): N.Numeric.true_ne_false((%same : {Tracked.nonempty(_) == False{} : Bool}; {==}))

law Tracked.heads_equal:
  for +a: TC.TickCooldown.Frame
  for +b: TC.TickCooldown.Frame
  for +xs: List<&2,TC.TickCooldown.Frame>
  for +ys: List<&2,TC.TickCooldown.Frame>
  for +same: {Con{a,xs} == Con{b,ys} : List<&2,TC.TickCooldown.Frame>}
  {a == b : TC.TickCooldown.Frame}

def Tracked.heads_equal(a,b,xs,ys,same):
  %same : {a == Tracked.first(_,a) : TC.TickCooldown.Frame}
  {==}

law Tracked.tails_equal:
  for +a: TC.TickCooldown.Frame
  for +b: TC.TickCooldown.Frame
  for +xs: List<&2,TC.TickCooldown.Frame>
  for +ys: List<&2,TC.TickCooldown.Frame>
  for +same: {Con{a,xs} == Con{b,ys} : List<&2,TC.TickCooldown.Frame>}
  {xs == ys : List<&2,TC.TickCooldown.Frame>}

def Tracked.tails_equal(a,b,xs,ys,same):
  %same : {xs == Tracked.rest(_) : List<&2,TC.TickCooldown.Frame>}
  {==}

law Tracked.head_member:
  for +session: TC.TickCooldown.Frame
  for +head: TC.TickCooldown.Frame
  for +rest: List<&2,TC.TickCooldown.Frame>
  for +equal: {head == session : TC.TickCooldown.Frame}
  Tracked.In<session,Con{head,rest}>

def Tracked.head_member(session,head,rest,equal):
  %equal : Tracked.In<_,Con{head,rest}>
  Tracked.Here{rest,{==}}

law Tracked.swap_later:
  for +session: TC.TickCooldown.Frame
  for +first: TC.TickCooldown.Frame
  for +second: TC.TickCooldown.Frame
  for +rest: List<&2,TC.TickCooldown.Frame>
  for +inside: Tracked.In<session,Con{first,rest}>
  Tracked.In<session,Con{first,Con{second,rest}}>

def Tracked.swap_later(session,first,second,rest,inside):
  match inside:
    case Tracked.Here{tail,shape}: Tracked.head_member(session,first,Con{second,rest},Tracked.heads_equal(first,session,rest,tail,shape))
    case Tracked.There{head,tail,shape,later}:
      Tracked.There{first,Con{second,rest},{==},Tracked.There{second,rest,{==},(%Equal.sym(List<&2,TC.TickCooldown.Frame>,rest,tail,Tracked.tails_equal(first,head,rest,tail,shape)) : Tracked.In<session,_>; later)}}

law Tracked.swap_member:
  for +session: TC.TickCooldown.Frame
  for +first: TC.TickCooldown.Frame
  for +second: TC.TickCooldown.Frame
  for +rest: List<&2,TC.TickCooldown.Frame>
  for +inside: Tracked.In<session,Con{second,Con{first,rest}}>
  Tracked.In<session,Con{first,Con{second,rest}}>

def Tracked.swap_member(session,first,second,rest,inside):
  match inside:
    case Tracked.Here{tail,shape}: Tracked.There{first,Con{second,rest},{==},Tracked.head_member(session,second,rest,Tracked.heads_equal(second,session,Con{first,rest},tail,shape))}
    case Tracked.There{head,tail,shape,later}: Tracked.swap_later(session,first,second,rest,(%Equal.sym(List<&2,TC.TickCooldown.Frame>,Con{first,rest},tail,Tracked.tails_equal(second,head,Con{first,rest},tail,shape)) : Tracked.In<session,_>; later))

law Tracked.perm_member:
  for +session: TC.TickCooldown.Frame
  for -left: List<&2,TC.TickCooldown.Frame>
  for -right: List<&2,TC.TickCooldown.Frame>
  for +permutation: TC.TickCooldown.Perm<left,right>
  for +inside: Tracked.In<session,right>
  Tracked.In<session,left>

def Tracked.perm_member(session,left,right,permutation,inside):
  match permutation:
    case TC.TickCooldown.Same{equal}:
      %Equal.sym(List<&2,TC.TickCooldown.Frame>,left,right,equal) : Tracked.In<session,_>
      inside
    case TC.TickCooldown.Common{head,lt,rt,ls,rs,tails}:
      match inside:
        case Tracked.Here{rest,shape}:
          %Equal.sym(List<&2,TC.TickCooldown.Frame>,left,Con{head,lt},ls) : Tracked.In<session,_>
          Tracked.head_member(session,head,lt,Tracked.heads_equal(head,session,rt,rest,Equal.trans(List<&2,TC.TickCooldown.Frame>,Con{head,rt},right,Con{session,rest},Equal.sym(List<&2,TC.TickCooldown.Frame>,right,Con{head,rt},rs),shape)))
        case Tracked.There{before,rest,shape,later}:
          %Equal.sym(List<&2,TC.TickCooldown.Frame>,left,Con{head,lt},ls) : Tracked.In<session,_>
          Tracked.There{head,lt,{==},Tracked.perm_member(session,lt,rt,tails,(%Equal.sym(List<&2,TC.TickCooldown.Frame>,rt,rest,Tracked.tails_equal(head,before,rt,rest,Equal.trans(List<&2,TC.TickCooldown.Frame>,Con{head,rt},right,Con{before,rest},Equal.sym(List<&2,TC.TickCooldown.Frame>,right,Con{head,rt},rs),shape))) : Tracked.In<session,_>; later))}
    case TC.TickCooldown.Swap{first,second,rest,ls,rs}:
      %Equal.sym(List<&2,TC.TickCooldown.Frame>,left,Con{first,Con{second,rest}},ls) : Tracked.In<session,_>
      Tracked.swap_member(session,first,second,rest,(%rs : Tracked.In<session,_>; inside))
    case TC.TickCooldown.Then{middle,before,after}: Tracked.perm_member(session,left,middle,before,Tracked.perm_member(session,middle,right,after,inside))


law Tracked.projected:
  for +player: P.Players.State
  for -players: List<&2,P.Players.State>
  for +inside: T.Targeting.In<player,players>
  Tracked.In<TC.TickCooldown.frame(player),TC.TickCooldown.frames(players)>

def Tracked.projected(player,players,inside):
  match inside:
    case T.Targeting.Here{rest,shape}:
      %Equal.sym(List<&2,P.Players.State>,players,Con{player,rest},shape) : Tracked.In<TC.TickCooldown.frame(player),TC.TickCooldown.frames(_)>
      Tracked.Here{TC.TickCooldown.frames(rest),{==}}
    case T.Targeting.There{head,rest,shape,later}:
      %Equal.sym(List<&2,P.Players.State>,players,Con{head,rest},shape) : Tracked.In<TC.TickCooldown.frame(player),TC.TickCooldown.frames(_)>
      Tracked.There{TC.TickCooldown.frame(head),TC.TickCooldown.frames(rest),{==},Tracked.projected(player,rest,later)}

law Tracked.updated:
  for +player: P.Players.State
  for -players: List<&2,P.Players.State>
  for +inside: T.Targeting.In<player,players>
  Tracked.In<TC.TickCooldown.expected(player),TC.TickCooldown.updated(players)>

def Tracked.updated(player,players,inside):
  match inside:
    case T.Targeting.Here{rest,shape}:
      %Equal.sym(List<&2,P.Players.State>,players,Con{player,rest},shape) : Tracked.In<TC.TickCooldown.expected(player),TC.TickCooldown.updated(_)>
      Tracked.Here{TC.TickCooldown.updated(rest),{==}}
    case T.Targeting.There{head,rest,shape,later}:
      %Equal.sym(List<&2,P.Players.State>,players,Con{head,rest},shape) : Tracked.In<TC.TickCooldown.expected(player),TC.TickCooldown.updated(_)>
      Tracked.There{TC.TickCooldown.expected(head),TC.TickCooldown.updated(rest),{==},Tracked.updated(player,rest,later)}

def Tracked.choose(running: Bool,player: P.Players.State) -> TC.TickCooldown.Frame:
  match running:
    case False{}: TC.TickCooldown.frame(player)
    case True{}: TC.TickCooldown.expected(player)

def Tracked.next(world: Terrain.Terrain.World,player: P.Players.State) -> TC.TickCooldown.Frame:
  Tracked.choose(U32.is_eq(S.Simulation.phase(S.Simulation.meta(Terrain.Terrain.simulation(world))),1),player)

law Tracked.source:
  for +running: Bool
  for +player: P.Players.State
  for -players: List<&2,P.Players.State>
  for +inside: T.Targeting.In<player,players>
  Tracked.In<Tracked.choose(running,player),TC.TickCooldown.choose(running,players)>

def Tracked.source(running,player,players,inside):
  match running:
    case False{}: Tracked.projected(player,players,inside)
    case True{}: Tracked.updated(player,players,inside)

# Carries an actual full player in the final roster, not only a matching frame.
type Tracked.Observed<-frame: TC.TickCooldown.Frame,-players: List<&2,P.Players.State>> is Data:
  Tracked.Observed{player: P.Players.State,inside: T.Targeting.In<player,players>,same: {TC.TickCooldown.frame(player) == frame : TC.TickCooldown.Frame}}

law Tracked.weaken:
  for +frame: TC.TickCooldown.Frame
  for +head: P.Players.State
  for +rest: List<&2,P.Players.State>
  for +observed: Tracked.Observed<frame,rest>
  Tracked.Observed<frame,Con{head,rest}>

def Tracked.weaken(frame,head,rest,observed):
  match observed:
    case Tracked.Observed{player,inside,same}: Tracked.Observed{player,T.Targeting.There{head,rest,{==},inside},same}

law Tracked.reify:
  for +players: List<&2,P.Players.State>
  for +frame: TC.TickCooldown.Frame
  for +inside: Tracked.In<frame,TC.TickCooldown.frames(players)>
  Tracked.Observed<frame,players>

def Tracked.reify(players,frame,inside):
  match players:
    case Nil{}:
      match inside:
        case Tracked.Here{rest,shape}: Empty.absurd(Tracked.Observed<frame,Nil{}>,Tracked.nil_cons(frame,rest,shape))
        case Tracked.There{head,rest,shape,later}: Empty.absurd(Tracked.Observed<frame,Nil{}>,Tracked.nil_cons(head,rest,shape))
    case Con{player,rest}:
      match inside:
        case Tracked.Here{tail,shape}: Tracked.Observed{player,T.Targeting.Here{rest,{==}},Tracked.heads_equal(TC.TickCooldown.frame(player),frame,TC.TickCooldown.frames(rest),tail,shape)}
        case Tracked.There{head,tail,shape,later}:
          Tracked.weaken(frame,player,rest,Tracked.reify(rest,frame,(%Equal.sym(List<&2,TC.TickCooldown.Frame>,TC.TickCooldown.frames(rest),tail,Tracked.tails_equal(TC.TickCooldown.frame(player),head,TC.TickCooldown.frames(rest),tail,shape)) : Tracked.In<frame,_>; later)))

law Tracked.live:
  for +world: Terrain.Terrain.World
  for +player: P.Players.State
  for +timer: U32
  for +inside: T.Targeting.In<player,S.Simulation.players(Terrain.Terrain.simulation(world))>
  Tracked.Observed<Tracked.next(world,player),S.Simulation.players(Terrain.Terrain.simulation(L.LiveTick.world(L.LiveTick.run(world,timer))))>

def Tracked.live(world,player,timer,inside):
  +before = S.Simulation.players(Terrain.Terrain.simulation(world))
  +after = S.Simulation.players(Terrain.Terrain.simulation(L.LiveTick.world(L.LiveTick.run(world,timer))))
  +running = U32.is_eq(S.Simulation.phase(S.Simulation.meta(Terrain.Terrain.simulation(world))),1)
  Tracked.reify(after,Tracked.next(world,player),Tracked.perm_member(Tracked.next(world,player),TC.TickCooldown.frames(after),TC.TickCooldown.spec(Terrain.Terrain.simulation(world)),TC.TickCooldown.live(world,timer),Tracked.source(running,player,before,inside)))

def Tracked.pid(frame: TC.TickCooldown.Frame) -> U32:
  match frame:
    case TC.TickCooldown.Frame{pid,cid,attack,spin}: pid

def Tracked.cid(frame: TC.TickCooldown.Frame) -> U32:
  match frame:
    case TC.TickCooldown.Frame{pid,cid,attack,spin}: cid

law Tracked.next_pid:
  for +running: Bool
  for +player: P.Players.State
  {Tracked.pid(Tracked.choose(running,player)) == P.Players.id(player) : U32}

def Tracked.next_pid(running,player):
  match running:
    case False{}: {==}
    case True{}: {==}

law Tracked.next_cid:
  for +running: Bool
  for +player: P.Players.State
  {Tracked.cid(Tracked.choose(running,player)) == Id.PlayerIds.key(Id.PlayerIds.Connection{},player) : U32}

def Tracked.next_cid(running,player):
  match running:
    case False{}: {==}
    case True{}: {==}

# Exact lookup of the full final player by the expected PID.
type Tracked.Lookup<-frame: TC.TickCooldown.Frame,-players: List<&2,P.Players.State>> is Data:
  Tracked.Lookup{player: P.Players.State,inside: T.Targeting.In<player,players>,found: {P.Players.found(P.Players.take(players,Tracked.pid(frame))) == Some{player} : Maybe<&2,P.Players.State>},same: {TC.TickCooldown.frame(player) == frame : TC.TickCooldown.Frame}}

law Tracked.lookup:
  for +frame: TC.TickCooldown.Frame
  for +players: List<&2,P.Players.State>
  for +observed: Tracked.Observed<frame,players>
  for +unique: A.Allocation.Unique(Id.PlayerIds.project(Id.PlayerIds.Player{},players))
  Tracked.Lookup<frame,players>

def Tracked.lookup(frame,players,observed,unique):
  match observed:
    case Tracked.Observed{player,inside,same}:
      +pid = Equal.cong(TC.TickCooldown.Frame,U32,(frame => Tracked.pid(frame)),TC.TickCooldown.frame(player),frame,same)
      Tracked.Lookup{player,inside,(%pid : {P.Players.found(P.Players.take(players,_)) == Some{player} : Maybe<&2,P.Players.State>}; Repeat.Repeat.lookup_member(player,players,inside,unique)),same}

def Tracked.unique(+world: Terrain.Terrain.World,-states: List<&2,Sess.Sessions.State>,valid: SW.SeededWorld.OK<world,states>) -> A.Allocation.Unique(Id.PlayerIds.project(Id.PlayerIds.Player{},S.Simulation.players(Terrain.Terrain.simulation(world)))):
  match valid:
    case SW.SeededWorld.OK{world_ok,maps}:
      match world_ok:
        case Conn.Connections.WorldOK{world_valid,connections}:
          match world_valid:
            case W.WorldState.OK{health,positions,monsters,players,nonzero,references}: Id.PlayerIds.from_admission(Id.PlayerIds.Player{},S.Simulation.players(Terrain.Terrain.simulation(world)),players)

law Tracked.seeded_lookup:
  for +world: Terrain.Terrain.World
  for +player: P.Players.State
  for +timer: U32
  for +states: List<&2,Sess.Sessions.State>
  for +valid: SW.SeededWorld.OK<world,states>
  for +inside: T.Targeting.In<player,S.Simulation.players(Terrain.Terrain.simulation(world))>
  Tracked.Lookup<Tracked.next(world,player),S.Simulation.players(Terrain.Terrain.simulation(L.LiveTick.world(L.LiveTick.run(world,timer))))>

def Tracked.seeded_lookup(world,player,timer,states,valid,inside):
  +after = L.LiveTick.world(L.LiveTick.run(world,timer))
  Tracked.lookup(Tracked.next(world,player),S.Simulation.players(Terrain.Terrain.simulation(after)),Tracked.live(world,player,timer,inside),Tracked.unique(after,states,L.LiveTick.seeded(world,timer,states,valid)))

# Eliminate the observation once while allowing a proof to follow its actual
# player. The callback is affine; all its arguments are proved Data.
law Tracked.eliminate:
  for -Result: Data
  for +frame: TC.TickCooldown.Frame
  for -players: List<&2,P.Players.State>
  for +observed: Tracked.Observed<frame,players>
  for use: (@+player: P.Players.State -> @+inside: T.Targeting.In<player,players> -> @+same: {TC.TickCooldown.frame(player) == frame : TC.TickCooldown.Frame} -> Result)
  Result

def Tracked.eliminate(Result,frame,players,observed,use):
  match observed:
    case Tracked.Observed{player,inside,same}: use(player,inside,same)

# A finite actual tick history. Each U32 supplies that tick's death timer;
# LiveTick itself advances the world's gameplay tick and plans all AI actions.
type Tracked.Trace<-timers: List<&2,U32>,-world: Terrain.Terrain.World,-player: P.Players.State> is Data:
  Tracked.Done{empty: {timers == Nil{} : List<&2,U32>},inside: T.Targeting.In<player,S.Simulation.players(Terrain.Terrain.simulation(world))>}
  Tracked.Step{timer: U32,rest: List<&2,U32>,shape: {timers == Con{timer,rest} : List<&2,U32>},after: P.Players.State,inside: T.Targeting.In<after,S.Simulation.players(Terrain.Terrain.simulation(L.LiveTick.world(L.LiveTick.run(world,timer))))>,same: {TC.TickCooldown.frame(after) == Tracked.next(world,player) : TC.TickCooldown.Frame},tail: Tracked.Trace<rest,L.LiveTick.world(L.LiveTick.run(world,timer)),after>}

law Tracked.follow:
  for +timers: List<&2,U32>
  for +world: Terrain.Terrain.World
  for +player: P.Players.State
  for +inside: T.Targeting.In<player,S.Simulation.players(Terrain.Terrain.simulation(world))>
  Tracked.Trace<timers,world,player>

def Tracked.follow(timers,world,player,inside):
  match timers:
    case Nil{}: Tracked.Done{{==},inside}
    case Con{timer,rest}:
      Tracked.eliminate(Tracked.Trace<Con{timer,rest},world,player>,Tracked.next(world,player),S.Simulation.players(Terrain.Terrain.simulation(L.LiveTick.world(L.LiveTick.run(world,timer)))),Tracked.live(world,player,timer,inside),(after => (present => (same => Tracked.Step{timer,rest,{==},after,present,same,Tracked.follow(rest,L.LiveTick.world(L.LiveTick.run(world,timer)),after,present)}))))
