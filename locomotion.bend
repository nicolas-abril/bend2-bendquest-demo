# The authoritative player movement planner and positional tick preservation.
import Base
import ./terrain.bend as T
import ./navigation.bend as N
import ./players.bend as P
import ./vitals.bend as V
import ./simulation.bend as S
import ./ai.bend as A
import ./game.bend as G

def Locomotion.On(maps: T.Terrain.Maps,player: P.Players.State) -> Data:
  T.Terrain.On<maps,N.Navigation.pos(player)>

def Locomotion.All(+maps: T.Terrain.Maps,players: List<&2,P.Players.State>) -> Data:
  match players:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,Locomotion.On(maps,head),(valid => Locomotion.All(maps,rest))>

def Locomotion.Spawn(maps: T.Terrain.Maps,x: U32,y: U32) -> Data:
  T.Terrain.On<maps,P.Players.Pos{0,x,y,1,0}>

def Locomotion.xy(pos: P.Players.Pos) -> P.Players.Plan:
  match pos:
    case P.Players.Pos{zone,x,y,dir,moving}: P.Players.Walk{x,y}

def Locomotion.plan(maps: T.Terrain.Maps,player: P.Players.State) -> P.Players.Plan:
  Locomotion.xy(T.Terrain.walk_if(maps,N.Navigation.pos(player)))

def Locomotion.plans(players: List<&2,P.Players.State>,+maps: T.Terrain.Maps) -> List<&2,P.Players.Plan>:
  match players:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{Locomotion.plan(maps,head),Locomotion.plans(rest,maps)}

def Locomotion.repose(controls: T.Terrain.Controls,x: U32,y: U32) -> P.Players.Pos:
  match controls:
    case T.Terrain.Controls{zone,heading,moving}: P.Players.Pos{zone,x,y,heading,moving}

law Locomotion.walk_commit:
  for +pos: P.Players.Pos
  for +next: P.Players.Pos
  for +same: {T.Terrain.controls(next) == T.Terrain.controls(pos) : T.Terrain.Controls}
  {P.Players.walk_pos(pos,Locomotion.xy(next),True{}) == next : P.Players.Pos}

def Locomotion.walk_commit(pos,next,same):
  match pos:
    case P.Players.Pos{zone,x,y,dir,moving}:
      match next:
        case P.Players.Pos{nz,nx,ny,nd,nm}:
          %same : {Locomotion.repose(_,nx,ny) == P.Players.Pos{nz,nx,ny,nd,nm} : P.Players.Pos}
          {==}

law Locomotion.planned_walk_exact:
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  {P.Players.walk_pos(pos,Locomotion.xy(T.Terrain.walk_if(maps,pos)),True{}) == T.Terrain.walk_if(maps,pos) : P.Players.Pos}

def Locomotion.planned_walk_exact(maps,pos):
  Locomotion.walk_commit(pos,T.Terrain.walk_if(maps,pos),T.Terrain.walk_if_controls(maps,pos))

law Locomotion.walk_idle:
  for +pos: P.Players.Pos
  for +plan: P.Players.Plan
  {P.Players.walk_pos(pos,plan,False{}) == pos : P.Players.Pos}

def Locomotion.walk_idle(pos,plan):
  match pos:
    case P.Players.Pos{zone,x,y,dir,moving}:
      match plan:
        case P.Players.Walk{nx,ny}: {==}

law Locomotion.walk_on:
  for +walk: Bool
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  for +valid: T.Terrain.On<maps,pos>
  T.Terrain.On<maps,P.Players.walk_pos(pos,Locomotion.xy(T.Terrain.walk_if(maps,pos)),walk)>

def Locomotion.walk_on(walk,maps,pos,valid):
  match walk:
    case False{}:
      %Equal.sym(P.Players.Pos,P.Players.walk_pos(pos,Locomotion.xy(T.Terrain.walk_if(maps,pos)),False{}),pos,Locomotion.walk_idle(pos,Locomotion.xy(T.Terrain.walk_if(maps,pos)))) : T.Terrain.On<maps,_>
      valid
    case True{}:
      %Equal.sym(P.Players.Pos,P.Players.walk_pos(pos,Locomotion.xy(T.Terrain.walk_if(maps,pos)),True{}),T.Terrain.walk_if(maps,pos),Locomotion.planned_walk_exact(maps,pos)) : T.Terrain.On<maps,_>
      T.Terrain.walk_if_on(maps,pos,valid)

law Locomotion.finish_upkeep_on:
  for +player: P.Players.State
  for +maps: T.Terrain.Maps
  for +result: V.Vitals.Upkeep
  for +spawn_x: U32
  for +spawn_y: U32
  for +valid: Locomotion.On(maps,player)
  for +spawn: Locomotion.Spawn(maps,spawn_x,spawn_y)
  Locomotion.On(maps,P.Players.player(P.Players.finish_upkeep(player,Locomotion.plan(maps,player),result,spawn_x,spawn_y)))

def Locomotion.finish_upkeep_on(player,maps,result,spawn_x,spawn_y,valid,spawn):
  match player:
    case P.Players.State{pid,cid,hero,pos,old,style,quest,meta}:
      match result:
        case V.Vitals.Upkeep{vitals,revived,walk}:
          match revived:
            case False{}: Locomotion.walk_on(walk,maps,pos,valid)
            case True{}: spawn

law Locomotion.upkeep_on:
  for +player: P.Players.State
  for +maps: T.Terrain.Maps
  for +tick: U32
  for +spawn_x: U32
  for +spawn_y: U32
  for +valid: Locomotion.On(maps,player)
  for +spawn: Locomotion.Spawn(maps,spawn_x,spawn_y)
  Locomotion.On(maps,P.Players.player(P.Players.upkeep(player,Locomotion.plan(maps,player),tick,spawn_x,spawn_y)))

def Locomotion.upkeep_on(player,maps,tick,spawn_x,spawn_y,valid,spawn):
  Locomotion.finish_upkeep_on(player,maps,V.Vitals.upkeep_hero(P.Players.vitals(player),P.Players.regen(tick,V.Vitals.hp(P.Players.vitals(player)),P.Players.maximum(player)),P.Players.hero(player),4294967295),spawn_x,spawn_y,valid,spawn)

law Locomotion.prepend_step_on:
  for +maps: T.Terrain.Maps
  for +step: P.Players.Step
  for +result: P.Players.Result
  for +head_ok: Locomotion.On(maps,P.Players.player(step))
  for +rest_ok: Locomotion.All(maps,P.Players.roster(result))
  Locomotion.All(maps,P.Players.roster(P.Players.prepend_step(step,result)))

def Locomotion.prepend_step_on(maps,step,result,head_ok,rest_ok):
  match step:
    case P.Players.Step{player,event}:
      match result:
        case P.Players.Result{players,events}: Tuple{head_ok,rest_ok}

law Locomotion.upkeep_all_on:
  for +players: List<&2,P.Players.State>
  for +maps: T.Terrain.Maps
  for +tick: U32
  for +spawn_x: U32
  for +spawn_y: U32
  for +valid: Locomotion.All(maps,players)
  for +spawn: Locomotion.Spawn(maps,spawn_x,spawn_y)
  Locomotion.All(maps,P.Players.roster(P.Players.upkeep_all(players,Locomotion.plans(players,maps),tick,spawn_x,spawn_y)))

def Locomotion.upkeep_all_on(players,maps,tick,spawn_x,spawn_y,valid,spawn):
  match players:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match valid:
        case Tuple{head_ok,rest_ok}:
          Locomotion.prepend_step_on(maps,P.Players.upkeep(head,Locomotion.plan(maps,head),tick,spawn_x,spawn_y),P.Players.upkeep_all(rest,Locomotion.plans(rest,maps),tick,spawn_x,spawn_y),Locomotion.upkeep_on(head,maps,tick,spawn_x,spawn_y,head_ok,spawn),Locomotion.upkeep_all_on(rest,maps,tick,spawn_x,spawn_y,rest_ok,spawn))

law Locomotion.halt_on:
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  for +valid: T.Terrain.On<maps,pos>
  T.Terrain.On<maps,P.Players.halt(pos)>

def Locomotion.halt_on(maps,pos,valid):
  match pos:
    case P.Players.Pos{zone,x,y,dir,moving}:
      match valid:
        case T.Terrain.On{bounds,walkable}:
          match bounds:
            case N.Navigation.Bounds{z_ok,x_ok,y_ok}: T.Terrain.On{N.Navigation.Bounds{z_ok,x_ok,y_ok},walkable}

law Locomotion.finish_hit_on:
  for +player: P.Players.State
  for +maps: T.Terrain.Maps
  for +hit: V.Vitals.Hit
  for +valid: Locomotion.On(maps,player)
  Locomotion.On(maps,P.Players.player(P.Players.finish_hit(player,hit)))

def Locomotion.finish_hit_on(player,maps,hit,valid):
  match player:
    case P.Players.State{pid,cid,hero,pos,old,style,quest,meta}:
      match hit:
        case V.Vitals.Hit{vitals,fell}:
          match fell:
            case False{}: valid
            case True{}: Locomotion.halt_on(maps,pos,valid)

law Locomotion.hurt_on:
  for +player: P.Players.State
  for +maps: T.Terrain.Maps
  for +attack: U32
  for +timer: U32
  for +valid: Locomotion.On(maps,player)
  Locomotion.On(maps,P.Players.player(P.Players.hurt(player,attack,timer)))

def Locomotion.hurt_on(player,maps,attack,timer,valid):
  Locomotion.finish_hit_on(player,maps,V.Vitals.hit(P.Players.vitals(player),P.Players.mob_hit(attack,P.Players.hero(player)),timer),valid)

law Locomotion.swap_on:
  for +maps: T.Terrain.Maps
  for +first: P.Players.State
  for +second: P.Players.State
  for +rest: List<&2,P.Players.State>
  for +valid: Locomotion.All(maps,Con{second,Con{first,rest}})
  Locomotion.All(maps,Con{first,Con{second,rest}})

def Locomotion.swap_on(maps,first,second,rest,valid):
  match valid:
    case Tuple{second_ok,tail_ok}:
      match tail_ok:
        case Tuple{first_ok,rest_ok}: Tuple{first_ok,Tuple{second_ok,rest_ok}}

def Locomotion.head_on(+maps: T.Terrain.Maps,+head: P.Players.State, +rest: List<&2,P.Players.State>, valid: Locomotion.All(maps,Con{head,rest})) -> Locomotion.On(maps,head):
  match valid:
    case Tuple{head_ok,rest_ok}: head_ok

def Locomotion.tail_on(+maps: T.Terrain.Maps,+head: P.Players.State, +rest: List<&2,P.Players.State>, valid: Locomotion.All(maps,Con{head,rest})) -> Locomotion.All(maps,rest):
  match valid:
    case Tuple{head_ok,rest_ok}: rest_ok

law Locomotion.perm_on:
  for +maps: T.Terrain.Maps
  for -left: List<&2,P.Players.State>
  for -right: List<&2,P.Players.State>
  for +permutation: P.Players.Perm<left,right>
  for +valid: Locomotion.All(maps,right)
  Locomotion.All(maps,left)

def Locomotion.perm_on(maps,left,right,permutation,valid):
  match permutation:
    case P.Players.Same{equal}:
      %Equal.sym(List<&2,P.Players.State>,left,right,equal) : Locomotion.All(maps,_)
      valid
    case P.Players.Common{head,lt,rt,ls,rs,tails}:
      %Equal.sym(List<&2,P.Players.State>,left,Con{head,lt},ls) : Locomotion.All(maps,_)
      +right_ok = {(%rs : Locomotion.All(maps,_); valid) : Locomotion.All(maps,Con{head,rt})}
      Tuple{Locomotion.head_on(maps,head,rt,right_ok),Locomotion.perm_on(maps,lt,rt,tails,Locomotion.tail_on(maps,head,rt,right_ok))}
    case P.Players.Swap{first,second,rest,ls,rs}:
      %Equal.sym(List<&2,P.Players.State>,left,Con{first,Con{second,rest}},ls) : Locomotion.All(maps,_)
      Locomotion.swap_on(maps,first,second,rest,(%rs : Locomotion.All(maps,_); valid))
    case P.Players.Then{middle,before,after}:
      Locomotion.perm_on(maps,left,middle,before,Locomotion.perm_on(maps,middle,right,after,valid))

law Locomotion.take_on:
  for +maps: T.Terrain.Maps
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +valid: Locomotion.All(maps,players)
  Locomotion.All(maps,P.Players.restore(P.Players.take(players,target)))

def Locomotion.take_on(maps,players,target,valid):
  Locomotion.perm_on(maps,P.Players.restore(P.Players.take(players,target)),players,P.Players.take_restores(players,target),valid)

law Locomotion.hit_taken_on:
  for +taken: P.Players.Take
  for +maps: T.Terrain.Maps
  for +attack: U32
  for +timer: U32
  for +valid: Locomotion.All(maps,P.Players.restore(taken))
  Locomotion.All(maps,P.Players.roster(P.Players.hit_taken(taken,attack,timer)))

def Locomotion.hit_taken_on(taken,maps,attack,timer,valid):
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}: valid
        case Some{player}:
          match valid:
            case Tuple{head_ok,rest_ok}:
              Locomotion.prepend_step_on(maps,P.Players.hurt(player,attack,timer),P.Players.Result{others,Nil{}},Locomotion.hurt_on(player,maps,attack,timer,head_ok),rest_ok)

law Locomotion.strike_on:
  for +players: List<&2,P.Players.State>
  for +maps: T.Terrain.Maps
  for +pid: U32
  for +attack: U32
  for +timer: U32
  for +valid: Locomotion.All(maps,players)
  Locomotion.All(maps,P.Players.roster(P.Players.strike(players,pid,attack,timer)))

def Locomotion.strike_on(players,maps,pid,attack,timer,valid):
  Locomotion.hit_taken_on(P.Players.take(players,pid),maps,attack,timer,Locomotion.take_on(maps,players,pid,valid))

law Locomotion.before_on:
  for +maps: T.Terrain.Maps
  for +first: P.Players.Result
  for +later: P.Players.Result
  for +valid: Locomotion.All(maps,P.Players.roster(later))
  Locomotion.All(maps,P.Players.roster(P.Players.before(first,later)))

def Locomotion.before_on(maps,first,later,valid):
  match first:
    case P.Players.Result{old,earlier}:
      match later:
        case P.Players.Result{players,events}: valid

law Locomotion.apply_hits_on:
  for +hits: List<&2,P.Players.Attack>
  for +players: List<&2,P.Players.State>
  for +maps: T.Terrain.Maps
  for +timer: U32
  for +valid: Locomotion.All(maps,players)
  Locomotion.All(maps,P.Players.roster(P.Players.apply_hits(hits,players,timer)))

def Locomotion.apply_hits_on(hits,players,maps,timer,valid):
  match hits:
    case Nil{}: valid
    case Con{hit,rest}:
      match hit:
        case P.Players.Attack{pid,attack}:
          Locomotion.before_on(maps,P.Players.strike(players,pid,attack,timer),P.Players.apply_hits(rest,P.Players.roster(P.Players.strike(players,pid,attack,timer)),timer),Locomotion.apply_hits_on(rest,P.Players.roster(P.Players.strike(players,pid,attack,timer)),maps,timer,Locomotion.strike_on(players,maps,pid,attack,timer,valid)))

law Locomotion.spawn_on:
  for +maps: T.Terrain.Maps
  for +pid: U32
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +spawn_x: U32
  for +spawn_y: U32
  for +spawn: Locomotion.Spawn(maps,spawn_x,spawn_y)
  Locomotion.On(maps,P.Players.spawn(pid,cid,style,name,spawn_x,spawn_y))

def Locomotion.spawn_on(maps,pid,cid,style,name,spawn_x,spawn_y,spawn): spawn

# Phase gating stays in the planner so inactive ticks do not traverse maps.
def Locomotion.tick_plans(running: Bool,players: List<&2,P.Players.State>,maps: T.Terrain.Maps) -> List<&2,P.Players.Plan>:
  match running:
    case False{}: Nil{}
    case True{}: Locomotion.plans(players,maps)

def Locomotion.begin_gate(+running: Bool,+state: S.Simulation.State,maps: T.Terrain.Maps,rules: S.Simulation.Rules) -> S.Simulation.Prepared:
  S.Simulation.begin_gate(running,state,Locomotion.tick_plans(running,S.Simulation.players(state),maps),rules)

def Locomotion.begin(+state: S.Simulation.State,maps: T.Terrain.Maps,rules: S.Simulation.Rules) -> S.Simulation.Prepared:
  Locomotion.begin_gate(U32.is_eq(S.Simulation.phase(S.Simulation.meta(state)),1),state,maps,rules)

def Locomotion.RulesOn(maps: T.Terrain.Maps,rules: S.Simulation.Rules) -> Data:
  match rules:
    case S.Simulation.Rules{spawn_x,spawn_y,timer}: Locomotion.Spawn(maps,spawn_x,spawn_y)

def Locomotion.PreparedOn(maps: T.Terrain.Maps,prepared: S.Simulation.Prepared) -> Data:
  Locomotion.All(maps,P.Players.roster(S.Simulation.prepared_upkeep(prepared)))

law Locomotion.begin_gate_on:
  for +running: Bool
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  for +valid: Locomotion.All(maps,S.Simulation.players(state))
  for +spawn: Locomotion.RulesOn(maps,rules)
  Locomotion.PreparedOn(maps,Locomotion.begin_gate(running,state,maps,rules))

def Locomotion.begin_gate_on(running,state,maps,rules,valid,spawn):
  match running:
    case False{}:
      match state:
        case S.Simulation.State{meta,players,monsters}: valid
    case True{}:
      match state:
        case S.Simulation.State{meta,players,monsters}:
          match rules:
            case S.Simulation.Rules{spawn_x,spawn_y,timer}:
              Locomotion.upkeep_all_on(players,maps,S.Simulation.clock(meta),spawn_x,spawn_y,valid,spawn)

law Locomotion.begin_on:
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  for +valid: Locomotion.All(maps,S.Simulation.players(state))
  for +spawn: Locomotion.RulesOn(maps,rules)
  Locomotion.PreparedOn(maps,Locomotion.begin(state,maps,rules))

def Locomotion.begin_on(state,maps,rules,valid,spawn):
  Locomotion.begin_gate_on(U32.is_eq(S.Simulation.phase(S.Simulation.meta(state)),1),state,maps,rules,valid,spawn)

law Locomotion.finish_on:
  for +prepared: S.Simulation.Prepared
  for +maps: T.Terrain.Maps
  for +p0: List<&2,A.AI.Plan>
  for +p1: List<&2,A.AI.Plan>
  for +p2: List<&2,A.AI.Plan>
  for +p3: List<&2,A.AI.Plan>
  for +rules: S.Simulation.Rules
  for +valid: Locomotion.PreparedOn(maps,prepared)
  Locomotion.All(maps,S.Simulation.players(S.Simulation.state(S.Simulation.finish(prepared,p0,p1,p2,p3,rules))))

def Locomotion.finish_on(prepared,maps,p0,p1,p2,p3,rules,valid):
  match prepared:
    case S.Simulation.Prepared{meta,monsters,upkeep,running}:
      match running:
        case False{}: valid
        case True{}:
          match rules:
            case S.Simulation.Rules{spawn_x,spawn_y,timer}:
              Locomotion.apply_hits_on(S.Simulation.attacks(S.Simulation.ai_hits(A.AI.run_zones(monsters,p0,p1,p2,p3))),P.Players.roster(upkeep),maps,timer,valid)

# Monster planning remains separate. The server plans against begin's players.
type Locomotion.Actions is Data:
  Locomotion.Actions{zone0: List<&2,A.AI.Plan>,zone1: List<&2,A.AI.Plan>,zone2: List<&2,A.AI.Plan>,zone3: List<&2,A.AI.Plan>}

def Locomotion.finish(prepared: S.Simulation.Prepared,actions: Locomotion.Actions,rules: S.Simulation.Rules) -> S.Simulation.Result:
  match actions:
    case Locomotion.Actions{p0,p1,p2,p3}: S.Simulation.finish(prepared,p0,p1,p2,p3,rules)

def Locomotion.tick(state: S.Simulation.State,maps: T.Terrain.Maps,actions: Locomotion.Actions,+rules: S.Simulation.Rules) -> S.Simulation.Result:
  Locomotion.finish(Locomotion.begin(state,maps,rules),actions,rules)

law Locomotion.tick_on:
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +actions: Locomotion.Actions
  for +rules: S.Simulation.Rules
  for +valid: Locomotion.All(maps,S.Simulation.players(state))
  for +spawn: Locomotion.RulesOn(maps,rules)
  Locomotion.All(maps,S.Simulation.players(S.Simulation.state(Locomotion.tick(state,maps,actions,rules))))

def Locomotion.tick_on(state,maps,actions,rules,valid,spawn):
  match actions:
    case Locomotion.Actions{p0,p1,p2,p3}:
      Locomotion.finish_on(Locomotion.begin(state,maps,rules),maps,p0,p1,p2,p3,rules,Locomotion.begin_on(state,maps,rules,valid,spawn))

def Locomotion.trace(actions: List<&2,Locomotion.Actions>,state: S.Simulation.State,+maps: T.Terrain.Maps,+rules: S.Simulation.Rules) -> S.Simulation.State:
  match actions:
    case Nil{}: state
    case Con{head,rest}: Locomotion.trace(rest,S.Simulation.state(Locomotion.tick(state,maps,head,rules)),maps,rules)

law Locomotion.trace_on:
  for +actions: List<&2,Locomotion.Actions>
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  for +valid: Locomotion.All(maps,S.Simulation.players(state))
  for +spawn: Locomotion.RulesOn(maps,rules)
  Locomotion.All(maps,S.Simulation.players(Locomotion.trace(actions,state,maps,rules)))

def Locomotion.trace_on(actions,state,maps,rules,valid,spawn):
  match actions:
    case Nil{}: valid
    case Con{head,rest}:
      Locomotion.trace_on(rest,S.Simulation.state(Locomotion.tick(state,maps,head,rules)),maps,rules,Locomotion.tick_on(state,maps,head,rules,valid,spawn),spawn)

law Locomotion.begin_ok:
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  for +valid: S.Simulation.OK<state>
  S.Simulation.PreparedOK<Locomotion.begin(state,maps,rules)>

def Locomotion.begin_ok(state,maps,rules,valid):
  S.Simulation.begin_gate_ok(U32.is_eq(S.Simulation.phase(S.Simulation.meta(state)),1),state,Locomotion.tick_plans(U32.is_eq(S.Simulation.phase(S.Simulation.meta(state)),1),S.Simulation.players(state),maps),rules,valid)

law Locomotion.tick_ok:
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +actions: Locomotion.Actions
  for +rules: S.Simulation.Rules
  for +valid: S.Simulation.OK<state>
  S.Simulation.OK<S.Simulation.state(Locomotion.tick(state,maps,actions,rules))>

def Locomotion.tick_ok(state,maps,actions,rules,valid):
  match actions:
    case Locomotion.Actions{p0,p1,p2,p3}:
      S.Simulation.finish_ok(Locomotion.begin(state,maps,rules),p0,p1,p2,p3,rules,Locomotion.begin_ok(state,maps,rules,valid))

law Locomotion.trace_ok:
  for +actions: List<&2,Locomotion.Actions>
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  for +valid: S.Simulation.OK<state>
  S.Simulation.OK<Locomotion.trace(actions,state,maps,rules)>

def Locomotion.trace_ok(actions,state,maps,rules,valid):
  match actions:
    case Nil{}: valid
    case Con{head,rest}:
      Locomotion.trace_ok(rest,S.Simulation.state(Locomotion.tick(state,maps,head,rules)),maps,rules,Locomotion.tick_ok(state,maps,head,rules,valid))

def Locomotion.walk(walk: Bool,maps: T.Terrain.Maps,pos: P.Players.Pos) -> P.Players.Pos:
  match walk:
    case False{}: pos
    case True{}: T.Terrain.walk_if(maps,pos)

law Locomotion.walk_exact:
  for +walk: Bool
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  {P.Players.walk_pos(pos,Locomotion.xy(T.Terrain.walk_if(maps,pos)),walk) == Locomotion.walk(walk,maps,pos) : P.Players.Pos}

def Locomotion.walk_exact(walk,maps,pos):
  match walk:
    case False{}: Locomotion.walk_idle(pos,Locomotion.xy(T.Terrain.walk_if(maps,pos)))
    case True{}: Locomotion.planned_walk_exact(maps,pos)

def Locomotion.finish_pos(pos: P.Players.Pos,maps: T.Terrain.Maps,result: V.Vitals.Upkeep,spawn_x: U32,spawn_y: U32) -> P.Players.Pos:
  match result:
    case V.Vitals.Upkeep{vitals,revived,walk}:
      match revived:
        case False{}: Locomotion.walk(walk,maps,pos)
        case True{}: P.Players.Pos{0,spawn_x,spawn_y,1,0}

law Locomotion.finish_upkeep_position:
  for +player: P.Players.State
  for +maps: T.Terrain.Maps
  for +result: V.Vitals.Upkeep
  for +spawn_x: U32
  for +spawn_y: U32
  {N.Navigation.pos(P.Players.player(P.Players.finish_upkeep(player,Locomotion.plan(maps,player),result,spawn_x,spawn_y))) == Locomotion.finish_pos(N.Navigation.pos(player),maps,result,spawn_x,spawn_y) : P.Players.Pos}

def Locomotion.finish_upkeep_position(player,maps,result,spawn_x,spawn_y):
  match player:
    case P.Players.State{pid,cid,hero,pos,old,style,quest,meta}:
      match result:
        case V.Vitals.Upkeep{vitals,revived,walk}:
          match revived:
            case False{}: Locomotion.walk_exact(walk,maps,pos)
            case True{}: {==}

law Locomotion.walk_cardinal:
  for +walk: Bool
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  for +valid: N.Navigation.Bounds<pos>
  T.Terrain.Cardinal<pos,Locomotion.walk(walk,maps,pos)>

def Locomotion.walk_cardinal(walk,maps,pos,valid):
  match walk:
    case False{}: T.Terrain.self_cardinal(pos)
    case True{}: T.Terrain.walk_if_cardinal(maps,pos,valid)

# A respawn may change zone and jump to spawn; every other upkeep is cardinal.
def Locomotion.Travel(before: P.Players.Pos,after: P.Players.Pos,result: V.Vitals.Upkeep,spawn_x: U32,spawn_y: U32) -> Data:
  match result:
    case V.Vitals.Upkeep{vitals,revived,walk}:
      match revived:
        case False{}: T.Terrain.Cardinal<before,after>
        case True{}: {after == P.Players.Pos{0,spawn_x,spawn_y,1,0} : P.Players.Pos}

law Locomotion.finish_pos_travel:
  for +pos: P.Players.Pos
  for +maps: T.Terrain.Maps
  for +result: V.Vitals.Upkeep
  for +spawn_x: U32
  for +spawn_y: U32
  for +valid: N.Navigation.Bounds<pos>
  Locomotion.Travel(pos,Locomotion.finish_pos(pos,maps,result,spawn_x,spawn_y),result,spawn_x,spawn_y)

def Locomotion.finish_pos_travel(pos,maps,result,spawn_x,spawn_y,valid):
  match result:
    case V.Vitals.Upkeep{vitals,revived,walk}:
      match revived:
        case False{}: Locomotion.walk_cardinal(walk,maps,pos,valid)
        case True{}: {==}

law Locomotion.finish_upkeep_travel:
  for +player: P.Players.State
  for +maps: T.Terrain.Maps
  for +result: V.Vitals.Upkeep
  for +spawn_x: U32
  for +spawn_y: U32
  for +valid: N.Navigation.Bounds<N.Navigation.pos(player)>
  Locomotion.Travel(N.Navigation.pos(player),N.Navigation.pos(P.Players.player(P.Players.finish_upkeep(player,Locomotion.plan(maps,player),result,spawn_x,spawn_y))),result,spawn_x,spawn_y)

def Locomotion.finish_upkeep_travel(player,maps,result,spawn_x,spawn_y,valid):
  %Equal.sym(P.Players.Pos,N.Navigation.pos(P.Players.player(P.Players.finish_upkeep(player,Locomotion.plan(maps,player),result,spawn_x,spawn_y))),Locomotion.finish_pos(N.Navigation.pos(player),maps,result,spawn_x,spawn_y),Locomotion.finish_upkeep_position(player,maps,result,spawn_x,spawn_y)) : Locomotion.Travel(N.Navigation.pos(player),_,result,spawn_x,spawn_y)
  Locomotion.finish_pos_travel(N.Navigation.pos(player),maps,result,spawn_x,spawn_y,valid)

law Locomotion.upkeep_travel:
  for +player: P.Players.State
  for +maps: T.Terrain.Maps
  for +tick: U32
  for +spawn_x: U32
  for +spawn_y: U32
  for +valid: N.Navigation.Bounds<N.Navigation.pos(player)>
  Locomotion.Travel(N.Navigation.pos(player),N.Navigation.pos(P.Players.player(P.Players.upkeep(player,Locomotion.plan(maps,player),tick,spawn_x,spawn_y))),V.Vitals.upkeep_hero(P.Players.vitals(player),P.Players.regen(tick,V.Vitals.hp(P.Players.vitals(player)),P.Players.maximum(player)),P.Players.hero(player),4294967295),spawn_x,spawn_y)

def Locomotion.upkeep_travel(player,maps,tick,spawn_x,spawn_y,valid):
  Locomotion.finish_upkeep_travel(player,maps,V.Vitals.upkeep_hero(P.Players.vitals(player),P.Players.regen(tick,V.Vitals.hp(P.Players.vitals(player)),P.Players.maximum(player)),P.Players.hero(player),4294967295),spawn_x,spawn_y,valid)

law Locomotion.tick_refines:
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +p0: List<&2,A.AI.Plan>
  for +p1: List<&2,A.AI.Plan>
  for +p2: List<&2,A.AI.Plan>
  for +p3: List<&2,A.AI.Plan>
  for +rules: S.Simulation.Rules
  {Locomotion.tick(state,maps,Locomotion.Actions{p0,p1,p2,p3},rules) == S.Simulation.tick(state,S.Simulation.Plan{Locomotion.tick_plans(U32.is_eq(S.Simulation.phase(S.Simulation.meta(state)),1),S.Simulation.players(state),maps),p0,p1,p2,p3},rules) : S.Simulation.Result}

def Locomotion.tick_refines(state,maps,p0,p1,p2,p3,rules): {==}

law Locomotion.tick_player_count:
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +actions: Locomotion.Actions
  for +rules: S.Simulation.Rules
  {P.Players.length(S.Simulation.players(S.Simulation.state(Locomotion.tick(state,maps,actions,rules)))) == P.Players.length(S.Simulation.players(state)) : Nat}

def Locomotion.tick_player_count(state,maps,actions,rules):
  match actions:
    case Locomotion.Actions{p0,p1,p2,p3}:
      S.Simulation.tick_player_count(state,S.Simulation.Plan{Locomotion.tick_plans(U32.is_eq(S.Simulation.phase(S.Simulation.meta(state)),1),S.Simulation.players(state),maps),p0,p1,p2,p3},rules)

law Locomotion.trace_player_count:
  for +actions: List<&2,Locomotion.Actions>
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  {P.Players.length(S.Simulation.players(Locomotion.trace(actions,state,maps,rules))) == P.Players.length(S.Simulation.players(state)) : Nat}

def Locomotion.trace_player_count(actions,state,maps,rules):
  match actions:
    case Nil{}: {==}
    case Con{head,rest}:
      Equal.trans(Nat,P.Players.length(S.Simulation.players(Locomotion.trace(rest,S.Simulation.state(Locomotion.tick(state,maps,head,rules)),maps,rules))),P.Players.length(S.Simulation.players(S.Simulation.state(Locomotion.tick(state,maps,head,rules)))),P.Players.length(S.Simulation.players(state)),Locomotion.trace_player_count(rest,S.Simulation.state(Locomotion.tick(state,maps,head,rules)),maps,rules),Locomotion.tick_player_count(state,maps,head,rules))

def Locomotion.WorldOn(+world: T.Terrain.World) -> Data:
  Locomotion.All(T.Terrain.maps(world),S.Simulation.players(T.Terrain.simulation(world)))

law Locomotion.world_on:
  for +maps: T.Terrain.Maps
  for +state: S.Simulation.State
  for +valid: Locomotion.All(maps,S.Simulation.players(state))
  Locomotion.WorldOn(T.Terrain.world(maps,state))

def Locomotion.world_on(maps,state,valid):
  match state:
    case S.Simulation.State{meta,players,monsters}: valid
