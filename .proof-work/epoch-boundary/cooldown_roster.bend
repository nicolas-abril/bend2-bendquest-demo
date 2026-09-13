# ID-paired cooldown evolution through full rosters and authoritative world ticks.
import Base
import ./players.bend as P
import ./playerids.bend as Id
import ./combat.bend as C
import ./vitals.bend as V
import ./cooldown_tick.bend as CD
import ./simulation.bend as S
import ./ai.bend as AI
import ./terrain.bend as T
import ./locomotion.bend as Walk
import ./planning.bend as Plan
import ./ai_refs.bend as AR
import ./live_tick.bend as L

type TickCooldown.Frame is Data:
  TickCooldown.Frame{pid: U32,cid: U32,attack: U32,spin: U32}

def TickCooldown.frame(+player: P.Players.State) -> TickCooldown.Frame:
  TickCooldown.Frame{P.Players.id(player),Id.PlayerIds.key(Id.PlayerIds.Connection{},player),C.Combat.cooldown(C.Combat.Attack{},P.Players.vitals(player)),C.Combat.cooldown(C.Combat.Spin{},P.Players.vitals(player))}

def TickCooldown.frames(players: List<&2,P.Players.State>) -> List<&2,TickCooldown.Frame>:
  match players:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{TickCooldown.frame(head),TickCooldown.frames(rest)}

# Permutations keep IDs and both counters together in the same record.
type TickCooldown.Perm<-left: List<&2,TickCooldown.Frame>,-right: List<&2,TickCooldown.Frame>> is Data:
  TickCooldown.Same{equal: {left == right : List<&2,TickCooldown.Frame>}}
  TickCooldown.Common{head: TickCooldown.Frame,lt: List<&2,TickCooldown.Frame>,rt: List<&2,TickCooldown.Frame>,ls: {left == Con{head,lt} : List<&2,TickCooldown.Frame>},rs: {right == Con{head,rt} : List<&2,TickCooldown.Frame>},tails: TickCooldown.Perm<lt,rt>}
  TickCooldown.Swap{first: TickCooldown.Frame,second: TickCooldown.Frame,rest: List<&2,TickCooldown.Frame>,ls: {left == Con{first,Con{second,rest}} : List<&2,TickCooldown.Frame>},rs: {right == Con{second,Con{first,rest}} : List<&2,TickCooldown.Frame>}}
  TickCooldown.Then{middle: List<&2,TickCooldown.Frame>,before: TickCooldown.Perm<left,middle>,after: TickCooldown.Perm<middle,right>}

law TickCooldown.permutation:
  for -left: List<&2,P.Players.State>
  for -right: List<&2,P.Players.State>
  for +permutation: P.Players.Perm<left,right>
  TickCooldown.Perm<TickCooldown.frames(left),TickCooldown.frames(right)>

def TickCooldown.permutation(left,right,permutation):
  match permutation:
    case P.Players.Same{equal}: TickCooldown.Same{Equal.cong(List<&2,P.Players.State>,List<&2,TickCooldown.Frame>,(ps => TickCooldown.frames(ps)),left,right,equal)}
    case P.Players.Common{head,lt,rt,ls,rs,tails}: TickCooldown.Common{TickCooldown.frame(head),TickCooldown.frames(lt),TickCooldown.frames(rt),Equal.cong(List<&2,P.Players.State>,List<&2,TickCooldown.Frame>,(ps => TickCooldown.frames(ps)),left,Con{head,lt},ls),Equal.cong(List<&2,P.Players.State>,List<&2,TickCooldown.Frame>,(ps => TickCooldown.frames(ps)),right,Con{head,rt},rs),TickCooldown.permutation(lt,rt,tails)}
    case P.Players.Swap{first,second,rest,ls,rs}: TickCooldown.Swap{TickCooldown.frame(first),TickCooldown.frame(second),TickCooldown.frames(rest),Equal.cong(List<&2,P.Players.State>,List<&2,TickCooldown.Frame>,(ps => TickCooldown.frames(ps)),left,Con{first,Con{second,rest}},ls),Equal.cong(List<&2,P.Players.State>,List<&2,TickCooldown.Frame>,(ps => TickCooldown.frames(ps)),right,Con{second,Con{first,rest}},rs)}
    case P.Players.Then{middle,before,after}: TickCooldown.Then{TickCooldown.frames(middle),TickCooldown.permutation(left,middle,before),TickCooldown.permutation(middle,right,after)}

law TickCooldown.assemble:
  for +player: P.Players.State
  for +pid: U32
  for +cid: U32
  for +attack: U32
  for +spin: U32
  for +p: {P.Players.id(player) == pid : U32}
  for +c: {Id.PlayerIds.key(Id.PlayerIds.Connection{},player) == cid : U32}
  for +a: {C.Combat.cooldown(C.Combat.Attack{},P.Players.vitals(player)) == attack : U32}
  for +s: {C.Combat.cooldown(C.Combat.Spin{},P.Players.vitals(player)) == spin : U32}
  {TickCooldown.frame(player) == TickCooldown.Frame{pid,cid,attack,spin} : TickCooldown.Frame}

def TickCooldown.assemble(player,pid,cid,attack,spin,p,c,a,s):
  %s : {TickCooldown.frame(player) == TickCooldown.Frame{pid,cid,attack,_} : TickCooldown.Frame}
  %a : {TickCooldown.frame(player) == TickCooldown.Frame{pid,cid,_,C.Combat.cooldown(C.Combat.Spin{},P.Players.vitals(player))} : TickCooldown.Frame}
  %c : {TickCooldown.frame(player) == TickCooldown.Frame{pid,_,C.Combat.cooldown(C.Combat.Attack{},P.Players.vitals(player)),C.Combat.cooldown(C.Combat.Spin{},P.Players.vitals(player))} : TickCooldown.Frame}
  %p : {TickCooldown.frame(player) == TickCooldown.Frame{_,Id.PlayerIds.key(Id.PlayerIds.Connection{},player),C.Combat.cooldown(C.Combat.Attack{},P.Players.vitals(player)),C.Combat.cooldown(C.Combat.Spin{},P.Players.vitals(player))} : TickCooldown.Frame}
  {==}

law TickCooldown.hurt:
  for +player: P.Players.State
  for +attack: U32
  for +timer: U32
  {TickCooldown.frame(P.Players.player(P.Players.hurt(player,attack,timer))) == TickCooldown.frame(player) : TickCooldown.Frame}

def TickCooldown.hurt(player,attack,timer): TickCooldown.assemble(P.Players.player(P.Players.hurt(player,attack,timer)),P.Players.id(player),Id.PlayerIds.key(Id.PlayerIds.Connection{},player),C.Combat.cooldown(C.Combat.Attack{},P.Players.vitals(player)),C.Combat.cooldown(C.Combat.Spin{},P.Players.vitals(player)),Id.PlayerIds.hurt_key(Id.PlayerIds.Player{},player,attack,timer),Id.PlayerIds.hurt_key(Id.PlayerIds.Connection{},player,attack,timer),CD.Cooldown.player_hurt(C.Combat.Attack{},player,attack,timer),CD.Cooldown.player_hurt(C.Combat.Spin{},player,attack,timer))

law TickCooldown.prepend:
  for +step: P.Players.Step
  for +result: P.Players.Result
  {TickCooldown.frames(P.Players.roster(P.Players.prepend_step(step,result))) == Con{TickCooldown.frame(P.Players.player(step)),TickCooldown.frames(P.Players.roster(result))} : List<&2,TickCooldown.Frame>}

def TickCooldown.prepend(step,result):
  match step:
    case P.Players.Step{player,event}:
      match result:
        case P.Players.Result{players,events}: {==}

law TickCooldown.hit_taken:
  for +taken: P.Players.Take
  for +attack: U32
  for +timer: U32
  {TickCooldown.frames(P.Players.roster(P.Players.hit_taken(taken,attack,timer))) == TickCooldown.frames(P.Players.restore(taken)) : List<&2,TickCooldown.Frame>}

def TickCooldown.hit_taken(taken,attack,timer):
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}: {==}
        case Some{player}:
          %TickCooldown.hurt(player,attack,timer) : {TickCooldown.frames(P.Players.roster(P.Players.hit_taken(P.Players.Take{others,Some{player}},attack,timer))) == Con{_,TickCooldown.frames(others)} : List<&2,TickCooldown.Frame>}
          TickCooldown.prepend(P.Players.hurt(player,attack,timer),P.Players.Result{others,Nil{}})

law TickCooldown.strike:
  for +players: List<&2,P.Players.State>
  for +pid: U32
  for +attack: U32
  for +timer: U32
  TickCooldown.Perm<TickCooldown.frames(P.Players.roster(P.Players.strike(players,pid,attack,timer))),TickCooldown.frames(players)>

def TickCooldown.strike(players,pid,attack,timer):
  %Equal.sym(List<&2,TickCooldown.Frame>,TickCooldown.frames(P.Players.roster(P.Players.strike(players,pid,attack,timer))),TickCooldown.frames(P.Players.restore(P.Players.take(players,pid))),TickCooldown.hit_taken(P.Players.take(players,pid),attack,timer)) : TickCooldown.Perm<_,TickCooldown.frames(players)>
  TickCooldown.permutation(P.Players.restore(P.Players.take(players,pid)),players,P.Players.take_restores(players,pid))

law TickCooldown.hits:
  for +hits: List<&2,P.Players.Attack>
  for +players: List<&2,P.Players.State>
  for +timer: U32
  TickCooldown.Perm<TickCooldown.frames(P.Players.roster(P.Players.apply_hits(hits,players,timer))),TickCooldown.frames(players)>

def TickCooldown.hits(hits,players,timer):
  match hits:
    case Nil{}: TickCooldown.Same{{==}}
    case Con{head,rest}:
      match head:
        case P.Players.Attack{pid,attack}:
          +first = P.Players.strike(players,pid,attack,timer)
          %Equal.sym(List<&2,P.Players.State>,P.Players.roster(P.Players.before(first,P.Players.apply_hits(rest,P.Players.roster(first),timer))),P.Players.roster(P.Players.apply_hits(rest,P.Players.roster(first),timer)),P.Players.before_roster(first,P.Players.apply_hits(rest,P.Players.roster(first),timer))) : TickCooldown.Perm<TickCooldown.frames(_),TickCooldown.frames(players)>
          TickCooldown.Then{TickCooldown.frames(P.Players.roster(first)),TickCooldown.hits(rest,P.Players.roster(first),timer),TickCooldown.strike(players,pid,attack,timer)}

# A specification depending only on the pre-upkeep death flag and respawn
# readiness: live decrement, dead wait unchanged, revival zero.
def TickCooldown.evolve(dead: Bool,ready: Bool,value: U32) -> U32:
  match dead:
    case False{}: V.Vitals.dec(value)
    case True{}: CD.Cooldown.dead_value(ready,value)

def TickCooldown.next(+kind: C.Combat.Kind,+state: V.Vitals.State) -> U32:
  TickCooldown.evolve(U32.is_eq(V.Vitals.dead(state),1),U32.is_le(CD.Cooldown.respawn(state),1),C.Combat.cooldown(kind,state))

def TickCooldown.expected(+player: P.Players.State) -> TickCooldown.Frame:
  TickCooldown.Frame{P.Players.id(player),Id.PlayerIds.key(Id.PlayerIds.Connection{},player),TickCooldown.next(C.Combat.Attack{},P.Players.vitals(player)),TickCooldown.next(C.Combat.Spin{},P.Players.vitals(player))}

def TickCooldown.updated(players: List<&2,P.Players.State>) -> List<&2,TickCooldown.Frame>:
  match players:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{TickCooldown.expected(head),TickCooldown.updated(rest)}

law TickCooldown.gate:
  for +dead: Bool
  for +ready: Bool
  for +kind: C.Combat.Kind
  for +state: V.Vitals.State
  for +amount: U32
  for +maximum: U32
  {C.Combat.cooldown(kind,V.Vitals.upkeep_state(V.Vitals.upkeep_gate(dead,ready,state,amount,maximum))) == TickCooldown.evolve(dead,ready,C.Combat.cooldown(kind,state)) : U32}

def TickCooldown.gate(dead,ready,kind,state,amount,maximum):
  match dead:
    case False{}: CD.Cooldown.live(kind,state,amount,maximum)
    case True{}: CD.Cooldown.dead_tick(ready,kind,state,maximum)

law TickCooldown.vitals:
  for +kind: C.Combat.Kind
  for +state: V.Vitals.State
  for +amount: U32
  for +maximum: U32
  {C.Combat.cooldown(kind,V.Vitals.upkeep_state(V.Vitals.upkeep(state,amount,maximum))) == TickCooldown.next(kind,state) : U32}

def TickCooldown.vitals(kind,state,amount,maximum):
  match state:
    case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: TickCooldown.gate(U32.is_eq(dead,1),U32.is_le(respawn,1),kind,V.Vitals.State{hp,xp,dead,respawn,attack,spin},amount,maximum)

law TickCooldown.player_counter:
  for +kind: C.Combat.Kind
  for +player: P.Players.State
  for +plan: P.Players.Plan
  for +tick: U32
  for +x: U32
  for +y: U32
  {C.Combat.cooldown(kind,P.Players.vitals(P.Players.player(P.Players.upkeep(player,plan,tick,x,y)))) == TickCooldown.next(kind,P.Players.vitals(player)) : U32}

def TickCooldown.player_counter(kind,player,plan,tick,x,y):
  %Equal.sym(V.Vitals.State,P.Players.vitals(P.Players.player(P.Players.upkeep(player,plan,tick,x,y))),V.Vitals.upkeep_state(V.Vitals.upkeep(P.Players.vitals(player),P.Players.regen(tick,V.Vitals.hp(P.Players.vitals(player)),P.Players.maximum(player)),P.Players.maximum(player))),CD.Cooldown.player_upkeep(player,plan,tick,x,y)) : {C.Combat.cooldown(kind,_) == TickCooldown.next(kind,P.Players.vitals(player)) : U32}
  TickCooldown.vitals(kind,P.Players.vitals(player),P.Players.regen(tick,V.Vitals.hp(P.Players.vitals(player)),P.Players.maximum(player)),P.Players.maximum(player))

law TickCooldown.upkeep:
  for +player: P.Players.State
  for +plan: P.Players.Plan
  for +tick: U32
  for +x: U32
  for +y: U32
  {TickCooldown.frame(P.Players.player(P.Players.upkeep(player,plan,tick,x,y))) == TickCooldown.expected(player) : TickCooldown.Frame}

def TickCooldown.upkeep(player,plan,tick,x,y): TickCooldown.assemble(P.Players.player(P.Players.upkeep(player,plan,tick,x,y)),P.Players.id(player),Id.PlayerIds.key(Id.PlayerIds.Connection{},player),TickCooldown.next(C.Combat.Attack{},P.Players.vitals(player)),TickCooldown.next(C.Combat.Spin{},P.Players.vitals(player)),Id.PlayerIds.upkeep_key(Id.PlayerIds.Player{},player,plan,tick,x,y),Id.PlayerIds.upkeep_key(Id.PlayerIds.Connection{},player,plan,tick,x,y),TickCooldown.player_counter(C.Combat.Attack{},player,plan,tick,x,y),TickCooldown.player_counter(C.Combat.Spin{},player,plan,tick,x,y))

law TickCooldown.prepend_expected:
  for +step: P.Players.Step
  for +result: P.Players.Result
  for +head: P.Players.State
  for +rest: List<&2,P.Players.State>
  for +first: {TickCooldown.frame(P.Players.player(step)) == TickCooldown.expected(head) : TickCooldown.Frame}
  for +later: {TickCooldown.frames(P.Players.roster(result)) == TickCooldown.updated(rest) : List<&2,TickCooldown.Frame>}
  {TickCooldown.frames(P.Players.roster(P.Players.prepend_step(step,result))) == TickCooldown.updated(Con{head,rest}) : List<&2,TickCooldown.Frame>}

def TickCooldown.prepend_expected(step,result,head,rest,first,later):
  %first : {TickCooldown.frames(P.Players.roster(P.Players.prepend_step(step,result))) == Con{_,TickCooldown.updated(rest)} : List<&2,TickCooldown.Frame>}
  %later : {TickCooldown.frames(P.Players.roster(P.Players.prepend_step(step,result))) == Con{TickCooldown.frame(P.Players.player(step)),_} : List<&2,TickCooldown.Frame>}
  TickCooldown.prepend(step,result)

law TickCooldown.upkeep_all:
  for +players: List<&2,P.Players.State>
  for +plans: List<&2,P.Players.Plan>
  for +tick: U32
  for +x: U32
  for +y: U32
  {TickCooldown.frames(P.Players.roster(P.Players.upkeep_all(players,plans,tick,x,y))) == TickCooldown.updated(players) : List<&2,TickCooldown.Frame>}

def TickCooldown.upkeep_all(players,plans,tick,x,y):
  match players:
    case Nil{}: {==}
    case Con{head,rest}:
      match plans:
        case Nil{}: TickCooldown.prepend_expected(P.Players.upkeep(head,P.Players.stay(head),tick,x,y),P.Players.upkeep_all(rest,Nil{},tick,x,y),head,rest,TickCooldown.upkeep(head,P.Players.stay(head),tick,x,y),TickCooldown.upkeep_all(rest,Nil{},tick,x,y))
        case Con{plan,later}: TickCooldown.prepend_expected(P.Players.upkeep(head,plan,tick,x,y),P.Players.upkeep_all(rest,later,tick,x,y),head,rest,TickCooldown.upkeep(head,plan,tick,x,y),TickCooldown.upkeep_all(rest,later,tick,x,y))

def TickCooldown.choose(running: Bool,players: List<&2,P.Players.State>) -> List<&2,TickCooldown.Frame>:
  match running:
    case False{}: TickCooldown.frames(players)
    case True{}: TickCooldown.updated(players)

def TickCooldown.spec(+state: S.Simulation.State) -> List<&2,TickCooldown.Frame>:
  TickCooldown.choose(U32.is_eq(S.Simulation.phase(S.Simulation.meta(state)),1),S.Simulation.players(state))

law TickCooldown.begin:
  for +running: Bool
  for +state: S.Simulation.State
  for +plans: List<&2,P.Players.Plan>
  for +rules: S.Simulation.Rules
  {TickCooldown.frames(P.Players.roster(S.Simulation.prepared_upkeep(S.Simulation.begin_gate(running,state,plans,rules)))) == TickCooldown.choose(running,S.Simulation.players(state)) : List<&2,TickCooldown.Frame>}

def TickCooldown.begin(running,state,plans,rules):
  match running:
    case False{}:
      match state:
        case S.Simulation.State{meta,players,monsters}: {==}
    case True{}:
      match state:
        case S.Simulation.State{meta,players,monsters}:
          match rules:
            case S.Simulation.Rules{x,y,timer}: TickCooldown.upkeep_all(players,plans,S.Simulation.clock(meta),x,y)

law TickCooldown.finish_active:
  for +meta: S.Simulation.Meta
  for +upkeep: P.Players.Result
  for +ai: AI.AI.Result
  for +timer: U32
  TickCooldown.Perm<TickCooldown.frames(S.Simulation.players(S.Simulation.state(S.Simulation.finish_active(meta,upkeep,ai,timer)))),TickCooldown.frames(P.Players.roster(upkeep))>

def TickCooldown.finish_active(meta,upkeep,ai,timer): TickCooldown.hits(S.Simulation.attacks(S.Simulation.ai_hits(ai)),P.Players.roster(upkeep),timer)

law TickCooldown.finish:
  for +prepared: S.Simulation.Prepared
  for +p0: List<&2,AI.AI.Plan>
  for +p1: List<&2,AI.AI.Plan>
  for +p2: List<&2,AI.AI.Plan>
  for +p3: List<&2,AI.AI.Plan>
  for +rules: S.Simulation.Rules
  TickCooldown.Perm<TickCooldown.frames(S.Simulation.players(S.Simulation.state(S.Simulation.finish(prepared,p0,p1,p2,p3,rules)))),TickCooldown.frames(P.Players.roster(S.Simulation.prepared_upkeep(prepared)))>

def TickCooldown.finish(prepared,p0,p1,p2,p3,rules):
  match prepared:
    case S.Simulation.Prepared{meta,monsters,upkeep,running}:
      match running:
        case False{}: TickCooldown.Same{{==}}
        case True{}:
          match rules:
            case S.Simulation.Rules{x,y,timer}: TickCooldown.finish_active(meta,upkeep,AI.AI.run_zones(monsters,p0,p1,p2,p3),timer)

law TickCooldown.tick:
  for +state: S.Simulation.State
  for +plan: S.Simulation.Plan
  for +rules: S.Simulation.Rules
  TickCooldown.Perm<TickCooldown.frames(S.Simulation.players(S.Simulation.state(S.Simulation.tick(state,plan,rules)))),TickCooldown.spec(state)>

def TickCooldown.tick(state,plan,rules):
  match plan:
    case S.Simulation.Plan{players,p0,p1,p2,p3}:
      %TickCooldown.begin(U32.is_eq(S.Simulation.phase(S.Simulation.meta(state)),1),state,players,rules) : TickCooldown.Perm<TickCooldown.frames(S.Simulation.players(S.Simulation.state(S.Simulation.tick(state,S.Simulation.Plan{players,p0,p1,p2,p3},rules)))),_>
      TickCooldown.finish(S.Simulation.begin(state,players,rules),p0,p1,p2,p3,rules)

law TickCooldown.actions:
  for +prepared: S.Simulation.Prepared
  for +actions: Walk.Locomotion.Actions
  for +rules: S.Simulation.Rules
  TickCooldown.Perm<TickCooldown.frames(S.Simulation.players(S.Simulation.state(Walk.Locomotion.finish(prepared,actions,rules)))),TickCooldown.frames(P.Players.roster(S.Simulation.prepared_upkeep(prepared)))>

def TickCooldown.actions(prepared,actions,rules):
  match actions:
    case Walk.Locomotion.Actions{p0,p1,p2,p3}: TickCooldown.finish(prepared,p0,p1,p2,p3,rules)

law TickCooldown.planned:
  for +prepared: S.Simulation.Prepared
  for +maps: T.Terrain.Maps
  for +c0: List<&2,Plan.Planning.Context>
  for +c1: List<&2,Plan.Planning.Context>
  for +c2: List<&2,Plan.Planning.Context>
  for +c3: List<&2,Plan.Planning.Context>
  for +rules: S.Simulation.Rules
  TickCooldown.Perm<TickCooldown.frames(S.Simulation.players(S.Simulation.state(Plan.Planning.finish(prepared,maps,c0,c1,c2,c3,rules)))),TickCooldown.frames(P.Players.roster(S.Simulation.prepared_upkeep(prepared)))>

def TickCooldown.planned(prepared,maps,c0,c1,c2,c3,rules):
  %Equal.sym(S.Simulation.Result,Plan.Planning.finish(prepared,maps,c0,c1,c2,c3,rules),Walk.Locomotion.finish(prepared,Plan.Planning.actions(S.Simulation.prepared_monsters(prepared),c0,c1,c2,c3,maps,S.Simulation.clock(S.Simulation.prepared_meta(prepared))),rules),Plan.Planning.finish_refines(prepared,maps,c0,c1,c2,c3,rules)) : TickCooldown.Perm<TickCooldown.frames(S.Simulation.players(S.Simulation.state(_))),TickCooldown.frames(P.Players.roster(S.Simulation.prepared_upkeep(prepared)))>
  TickCooldown.actions(prepared,Plan.Planning.actions(S.Simulation.prepared_monsters(prepared),c0,c1,c2,c3,maps,S.Simulation.clock(S.Simulation.prepared_meta(prepared))),rules)

law TickCooldown.selected:
  for +prepared: S.Simulation.Prepared
  for +maps: T.Terrain.Maps
  for +d0: List<&2,U32>
  for +d1: List<&2,U32>
  for +d2: List<&2,U32>
  for +d3: List<&2,U32>
  for +rules: S.Simulation.Rules
  TickCooldown.Perm<TickCooldown.frames(S.Simulation.players(S.Simulation.state(AR.AIRefs.finish(prepared,maps,d0,d1,d2,d3,rules)))),TickCooldown.frames(P.Players.roster(S.Simulation.prepared_upkeep(prepared)))>

def TickCooldown.selected(prepared,maps,d0,d1,d2,d3,rules):
  match prepared:
    case S.Simulation.Prepared{meta,monsters,upkeep,running}:
      match running:
        case False{}: TickCooldown.planned(S.Simulation.Prepared{meta,monsters,upkeep,False{}},maps,Nil{},Nil{},Nil{},Nil{},rules)
        case True{}: TickCooldown.planned(S.Simulation.Prepared{meta,monsters,upkeep,True{}},maps,AR.AIRefs.contexts(monsters,P.Players.roster(upkeep),0,d0),AR.AIRefs.contexts(monsters,P.Players.roster(upkeep),1,d1),AR.AIRefs.contexts(monsters,P.Players.roster(upkeep),2,d2),AR.AIRefs.contexts(monsters,P.Players.roster(upkeep),3,d3),rules)

law TickCooldown.simulate:
  for +damages: AR.AIRefs.Damages
  for +prepared: S.Simulation.Prepared
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  TickCooldown.Perm<TickCooldown.frames(S.Simulation.players(S.Simulation.state(L.LiveTick.simulate(damages,prepared,maps,rules)))),TickCooldown.frames(P.Players.roster(S.Simulation.prepared_upkeep(prepared)))>

def TickCooldown.simulate(damages,prepared,maps,rules):
  match damages:
    case AR.AIRefs.Damages{d0,d1,d2,d3}: TickCooldown.selected(prepared,maps,d0,d1,d2,d3,rules)

law TickCooldown.live_finish:
  for +prepared: S.Simulation.Prepared
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  TickCooldown.Perm<TickCooldown.frames(S.Simulation.players(T.Terrain.simulation(L.LiveTick.world(L.LiveTick.finish(prepared,maps,rules))))),TickCooldown.frames(P.Players.roster(S.Simulation.prepared_upkeep(prepared)))>

def TickCooldown.live_finish(prepared,maps,rules):
  +result = L.LiveTick.simulate(L.LiveTick.damages(prepared),prepared,maps,rules)
  %Equal.sym(S.Simulation.State,T.Terrain.simulation(L.LiveTick.world(L.LiveTick.finish(prepared,maps,rules))),S.Simulation.state(result),L.LiveTick.pack_simulation(result,maps,S.Simulation.clock(S.Simulation.prepared_meta(prepared)))) : TickCooldown.Perm<TickCooldown.frames(S.Simulation.players(_)),TickCooldown.frames(P.Players.roster(S.Simulation.prepared_upkeep(prepared)))>
  TickCooldown.simulate(L.LiveTick.damages(prepared),prepared,maps,rules)

# No uniqueness, survival or AI-plan premise is needed for this paired-roster
# statement. It describes the actual live tick, including inactive phases.
law TickCooldown.live:
  for +world: T.Terrain.World
  for +timer: U32
  TickCooldown.Perm<TickCooldown.frames(S.Simulation.players(T.Terrain.simulation(L.LiveTick.world(L.LiveTick.run(world,timer))))),TickCooldown.spec(T.Terrain.simulation(world))>

def TickCooldown.live(world,timer):
  +state = T.Terrain.simulation(world)
  +maps = T.Terrain.maps(world)
  +rules = Plan.Planning.rules(timer)
  +running = U32.is_eq(S.Simulation.phase(S.Simulation.meta(state)),1)
  %TickCooldown.begin(running,state,Walk.Locomotion.tick_plans(running,S.Simulation.players(state),maps),rules) : TickCooldown.Perm<TickCooldown.frames(S.Simulation.players(T.Terrain.simulation(L.LiveTick.world(L.LiveTick.run(world,timer))))),_>
  TickCooldown.live_finish(Walk.Locomotion.begin(state,maps,rules),maps,rules)

# Independent cardinality checks for the frame projection and permutation.
def TickCooldown.length(frames: List<&2,TickCooldown.Frame>) -> Nat:
  match frames:
    case Nil{}: Zero{}
    case Con{head,rest}: Succ{TickCooldown.length(rest)}

law TickCooldown.frames_length:
  for +players: List<&2,P.Players.State>
  {TickCooldown.length(TickCooldown.frames(players)) == P.Players.length(players) : Nat}

def TickCooldown.frames_length(players):
  match players:
    case Nil{}: {==}
    case Con{head,rest}:
      %TickCooldown.frames_length(rest) : {Succ{TickCooldown.length(TickCooldown.frames(rest))} == Succ{_} : Nat}
      {==}

law TickCooldown.perm_length:
  for -left: List<&2, TickCooldown.Frame>
  for -right: List<&2, TickCooldown.Frame>
  for +permutation: TickCooldown.Perm<left, right>
  {TickCooldown.length(left) == TickCooldown.length(right) : Nat}

def TickCooldown.perm_length(left, right, permutation):
  match permutation:
    case TickCooldown.Same{equal}:
      Equal.cong(List<&2, TickCooldown.Frame>, Nat, (xs => TickCooldown.length(xs)), left, right, equal)
    case TickCooldown.Common{head, lt, rt, ls, rs, tails}:
      %Equal.sym(List<&2, TickCooldown.Frame>, left, Con{head, lt}, ls) : {TickCooldown.length(_) == TickCooldown.length(right) : Nat}
      %Equal.sym(List<&2, TickCooldown.Frame>, right, Con{head, rt}, rs) : {TickCooldown.length(Con{head, lt}) == TickCooldown.length(_) : Nat}
      %TickCooldown.perm_length(lt, rt, tails) : {Succ{TickCooldown.length(lt)} == Succ{_} : Nat}
      {==}
    case TickCooldown.Swap{first, second, rest, ls, rs}:
      %Equal.sym(List<&2, TickCooldown.Frame>, left, Con{first, Con{second, rest}}, ls) : {TickCooldown.length(_) == TickCooldown.length(right) : Nat}
      %Equal.sym(List<&2, TickCooldown.Frame>, right, Con{second, Con{first, rest}}, rs) : {TickCooldown.length(Con{first, Con{second, rest}}) == TickCooldown.length(_) : Nat}
      {==}
    case TickCooldown.Then{middle, before, after}:
      Equal.trans(Nat, TickCooldown.length(left), TickCooldown.length(middle), TickCooldown.length(right), TickCooldown.perm_length(left, middle, before), TickCooldown.perm_length(middle, right, after))
