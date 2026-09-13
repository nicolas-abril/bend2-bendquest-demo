# Exact cooldown transitions through actual vitals and player upkeep.
import Base
import ./combat.bend as C
import ./vitals.bend as V
import ./players.bend as P
import ./health.bend as H
import ./numeric.bend as N
import ./game.bend as G

law Cooldown.live:
  for +kind: C.Combat.Kind
  for +state: V.Vitals.State
  for +amount: U32
  for +maximum: U32
  {C.Combat.cooldown(kind,V.Vitals.live_tick(state,amount,maximum)) == V.Vitals.dec(C.Combat.cooldown(kind,state)) : U32}

def Cooldown.live(kind,state,amount,maximum):
  match kind:
    case C.Combat.Attack{}:
      match state:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: {==}
    case C.Combat.Spin{}:
      match state:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: {==}

law Cooldown.wait:
  for +kind: C.Combat.Kind
  for +state: V.Vitals.State
  {C.Combat.cooldown(kind,V.Vitals.wait(state)) == C.Combat.cooldown(kind,state) : U32}

def Cooldown.wait(kind,state):
  match kind:
    case C.Combat.Attack{}:
      match state:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: {==}
    case C.Combat.Spin{}:
      match state:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: {==}

law Cooldown.fall:
  for +kind: C.Combat.Kind
  for +state: V.Vitals.State
  for +timer: U32
  {C.Combat.cooldown(kind,V.Vitals.fall(state,timer)) == C.Combat.cooldown(kind,state) : U32}

def Cooldown.fall(kind,state,timer):
  match kind:
    case C.Combat.Attack{}:
      match state:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: {==}
    case C.Combat.Spin{}:
      match state:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: {==}

law Cooldown.revive:
  for +kind: C.Combat.Kind
  for +state: V.Vitals.State
  for +maximum: U32
  {C.Combat.cooldown(kind,V.Vitals.revive(state,maximum)) == 0 : U32}

def Cooldown.revive(kind,state,maximum):
  match kind:
    case C.Combat.Attack{}:
      match state:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: {==}
    case C.Combat.Spin{}:
      match state:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: {==}

law Cooldown.finish_hit:
  for +remaining: Nat
  for +kind: C.Combat.Kind
  for +word: U32
  for +state: V.Vitals.State
  for +timer: U32
  {C.Combat.cooldown(kind,V.Vitals.hit_state(V.Vitals.finish_hit(remaining,word,state,timer))) == C.Combat.cooldown(kind,state) : U32}

def Cooldown.finish_hit(remaining,kind,word,state,timer):
  match remaining:
    case Zero{}: Cooldown.fall(kind,state,timer)
    case Succ{rest}:
      match kind:
        case C.Combat.Attack{}:
          match state:
            case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: {==}
        case C.Combat.Spin{}:
          match state:
            case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: {==}

law Cooldown.hit_gate:
  for +dead: Bool
  for +kind: C.Combat.Kind
  for +state: V.Vitals.State
  for +damage: U32
  for +timer: U32
  {C.Combat.cooldown(kind,V.Vitals.hit_state(V.Vitals.hit_gate(dead,state,damage,timer))) == C.Combat.cooldown(kind,state) : U32}

def Cooldown.hit_gate(dead,kind,state,damage,timer):
  match dead:
    case True{}: {==}
    case False{}: Cooldown.finish_hit(U32.to_nat(H.Health.hurt_word(V.Vitals.hp(state),damage)),kind,H.Health.hurt_word(V.Vitals.hp(state),damage),state,timer)

law Cooldown.hit:
  for +kind: C.Combat.Kind
  for +state: V.Vitals.State
  for +damage: U32
  for +timer: U32
  {C.Combat.cooldown(kind,V.Vitals.hit_state(V.Vitals.hit(state,damage,timer))) == C.Combat.cooldown(kind,state) : U32}

def Cooldown.hit(kind,state,damage,timer): Cooldown.hit_gate(U32.is_eq(V.Vitals.dead(state),1),kind,state,damage,timer)

law Cooldown.upkeep_live:
  for +state: V.Vitals.State
  for +amount: U32
  for +maximum: U32
  for +alive: {V.Vitals.dead(state) == 0 : U32}
  {V.Vitals.upkeep(state,amount,maximum) == V.Vitals.Upkeep{V.Vitals.live_tick(state,amount,maximum),False{},True{}} : V.Vitals.Upkeep}

def Cooldown.upkeep_live(state,amount,maximum,alive):
  match state:
    case V.Vitals.State{hp,xp,dead,respawn,attack,spin}:
      %Equal.sym(U32,dead,0,alive) : {V.Vitals.upkeep(V.Vitals.State{hp,xp,_,respawn,attack,spin},amount,maximum) == V.Vitals.Upkeep{V.Vitals.live_tick(V.Vitals.State{hp,xp,_,respawn,attack,spin},amount,maximum),False{},True{}} : V.Vitals.Upkeep}
      {==}

# This equation includes the real respawn readiness test, not an assumed branch.
law Cooldown.upkeep_dead:
  for +hp: U32
  for +xp: U32
  for +respawn: U32
  for +attack: U32
  for +spin: U32
  for +amount: U32
  for +maximum: U32
  {V.Vitals.upkeep(V.Vitals.State{hp,xp,1,respawn,attack,spin},amount,maximum) == V.Vitals.dead_tick(U32.is_le(respawn,1),V.Vitals.State{hp,xp,1,respawn,attack,spin},maximum) : V.Vitals.Upkeep}

def Cooldown.upkeep_dead(hp,xp,respawn,attack,spin,amount,maximum): {==}

law Cooldown.player_finish_upkeep:
  for +player: P.Players.State
  for +plan: P.Players.Plan
  for +result: V.Vitals.Upkeep
  for +x: U32
  for +y: U32
  {P.Players.vitals(P.Players.player(P.Players.finish_upkeep(player,plan,result,x,y))) == V.Vitals.upkeep_state(result) : V.Vitals.State}

def Cooldown.player_finish_upkeep(player,plan,result,x,y):
  match player:
    case P.Players.State{pid,cid,hero,pos,old,style,quest,meta}:
      match result:
        case V.Vitals.Upkeep{state,revived,walk}:
          match revived:
            case False{}: {==}
            case True{}: {==}

law Cooldown.player_upkeep:
  for +player: P.Players.State
  for +plan: P.Players.Plan
  for +tick: U32
  for +x: U32
  for +y: U32
  {P.Players.vitals(P.Players.player(P.Players.upkeep(player,plan,tick,x,y))) == V.Vitals.upkeep_state(V.Vitals.upkeep(P.Players.vitals(player),P.Players.regen(tick,V.Vitals.hp(P.Players.vitals(player)),P.Players.maximum(player)),P.Players.maximum(player))) : V.Vitals.State}

def Cooldown.player_upkeep(player,plan,tick,x,y): Cooldown.player_finish_upkeep(player,plan,V.Vitals.upkeep_hero(P.Players.vitals(player),P.Players.regen(tick,V.Vitals.hp(P.Players.vitals(player)),P.Players.maximum(player)),P.Players.hero(player),4294967295),x,y)

law Cooldown.live_dead:
  for +state: V.Vitals.State
  for +amount: U32
  for +maximum: U32
  {V.Vitals.dead(V.Vitals.live_tick(state,amount,maximum)) == 0 : U32}

def Cooldown.live_dead(state,amount,maximum):
  match state:
    case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: {==}

# The exact actual player step, including movement and hero-derived healing.
law Cooldown.player_live:
  for +player: P.Players.State
  for +plan: P.Players.Plan
  for +tick: U32
  for +x: U32
  for +y: U32
  for +alive: {V.Vitals.dead(P.Players.vitals(player)) == 0 : U32}
  {P.Players.vitals(P.Players.player(P.Players.upkeep(player,plan,tick,x,y))) == V.Vitals.live_tick(P.Players.vitals(player),P.Players.regen(tick,V.Vitals.hp(P.Players.vitals(player)),P.Players.maximum(player)),P.Players.maximum(player)) : V.Vitals.State}

def Cooldown.player_live(player,plan,tick,x,y,alive):
  +state = P.Players.vitals(player)
  +amount = P.Players.regen(tick,V.Vitals.hp(state),P.Players.maximum(player))
  Equal.trans(V.Vitals.State,P.Players.vitals(P.Players.player(P.Players.upkeep(player,plan,tick,x,y))),V.Vitals.upkeep_state(V.Vitals.upkeep(state,amount,P.Players.maximum(player))),V.Vitals.live_tick(state,amount,P.Players.maximum(player)),Cooldown.player_upkeep(player,plan,tick,x,y),Equal.cong(V.Vitals.Upkeep,V.Vitals.State,(result => V.Vitals.upkeep_state(result)),V.Vitals.upkeep(state,amount,P.Players.maximum(player)),V.Vitals.Upkeep{V.Vitals.live_tick(state,amount,P.Players.maximum(player)),False{},True{}},Cooldown.upkeep_live(state,amount,P.Players.maximum(player),alive)))

law Cooldown.player_alive:
  for +player: P.Players.State
  for +plan: P.Players.Plan
  for +tick: U32
  for +x: U32
  for +y: U32
  for +alive: {V.Vitals.dead(P.Players.vitals(player)) == 0 : U32}
  {V.Vitals.dead(P.Players.vitals(P.Players.player(P.Players.upkeep(player,plan,tick,x,y)))) == 0 : U32}

def Cooldown.player_alive(player,plan,tick,x,y,alive):
  %Equal.sym(V.Vitals.State,P.Players.vitals(P.Players.player(P.Players.upkeep(player,plan,tick,x,y))),V.Vitals.live_tick(P.Players.vitals(player),P.Players.regen(tick,V.Vitals.hp(P.Players.vitals(player)),P.Players.maximum(player)),P.Players.maximum(player)),Cooldown.player_live(player,plan,tick,x,y,alive)) : {V.Vitals.dead(_) == 0 : U32}
  Cooldown.live_dead(P.Players.vitals(player),P.Players.regen(tick,V.Vitals.hp(P.Players.vitals(player)),P.Players.maximum(player)),P.Players.maximum(player))

law Cooldown.player_cooldown:
  for +kind: C.Combat.Kind
  for +player: P.Players.State
  for +plan: P.Players.Plan
  for +tick: U32
  for +x: U32
  for +y: U32
  for +alive: {V.Vitals.dead(P.Players.vitals(player)) == 0 : U32}
  {C.Combat.cooldown(kind,P.Players.vitals(P.Players.player(P.Players.upkeep(player,plan,tick,x,y)))) == V.Vitals.dec(C.Combat.cooldown(kind,P.Players.vitals(player))) : U32}

def Cooldown.player_cooldown(kind,player,plan,tick,x,y,alive):
  %Equal.sym(V.Vitals.State,P.Players.vitals(P.Players.player(P.Players.upkeep(player,plan,tick,x,y))),V.Vitals.live_tick(P.Players.vitals(player),P.Players.regen(tick,V.Vitals.hp(P.Players.vitals(player)),P.Players.maximum(player)),P.Players.maximum(player)),Cooldown.player_live(player,plan,tick,x,y,alive)) : {C.Combat.cooldown(kind,_) == V.Vitals.dec(C.Combat.cooldown(kind,P.Players.vitals(player))) : U32}
  Cooldown.live(kind,P.Players.vitals(player),P.Players.regen(tick,V.Vitals.hp(P.Players.vitals(player)),P.Players.maximum(player)),P.Players.maximum(player))

def Cooldown.pred(value: Nat) -> Nat:
  match value:
    case Zero{}: Zero{}
    case Succ{rest}: rest

law Cooldown.hurt_zero:
  for +value: Nat
  {H.Health.hurt(value,0n) == value : Nat}

def Cooldown.hurt_zero(value):
  match value:
    case Zero{}: {==}
    case Succ{rest}: {==}

law Cooldown.hurt_one:
  for +value: Nat
  {H.Health.hurt(value,1n) == Cooldown.pred(value) : Nat}

def Cooldown.hurt_one(value):
  match value:
    case Zero{}: {==}
    case Succ{rest}: Cooldown.hurt_zero(rest)

law Cooldown.dec:
  for +value: U32
  {U32.to_nat(V.Vitals.dec(value)) == Cooldown.pred(U32.to_nat(value)) : Nat}

def Cooldown.dec(value): Equal.trans(Nat,U32.to_nat(V.Vitals.dec(value)),H.Health.hurt(U32.to_nat(value),1n),Cooldown.pred(U32.to_nat(value)),H.Health.hurt_word_exact(value,1),Cooldown.hurt_one(U32.to_nat(value)))

def Cooldown.remaining(ticks: Nat,value: Nat) -> Nat:
  match ticks:
    case Zero{}: value
    case Succ{rest}: Cooldown.remaining(rest,Cooldown.pred(value))

law Cooldown.exhausted:
  for +ticks: Nat
  for +value: Nat
  for +enough: {G.Bq.Nat.le(value,ticks) == True{} : Bool}
  {Cooldown.remaining(ticks,value) == 0n : Nat}

def Cooldown.exhausted(ticks,value,enough):
  match ticks:
    case Zero{}:
      match value:
        case Zero{}: {==}
        case Succ{rest}: Empty.absurd({Succ{rest} == 0n : Nat},G.Bq.Bool.false_ne_true(enough))
    case Succ{rest}:
      match value:
        case Zero{}: Cooldown.exhausted(rest,0n,{==})
        case Succ{previous}: Cooldown.exhausted(rest,previous,enough)

# Different movement plans, tick words and spawn coordinates on every step.
type Cooldown.Input is Data:
  Cooldown.Input{plan: P.Players.Plan,tick: U32,x: U32,y: U32}

def Cooldown.run(inputs: List<&2,Cooldown.Input>,player: P.Players.State) -> P.Players.State:
  match inputs:
    case Nil{}: player
    case Con{head,rest}:
      match head:
        case Cooldown.Input{plan,tick,x,y}: Cooldown.run(rest,P.Players.player(P.Players.upkeep(player,plan,tick,x,y)))

def Cooldown.length(inputs: List<&2,Cooldown.Input>) -> Nat:
  match inputs:
    case Nil{}: Zero{}
    case Con{head,rest}: Succ{Cooldown.length(rest)}

law Cooldown.run_alive:
  for +inputs: List<&2,Cooldown.Input>
  for +player: P.Players.State
  for +alive: {V.Vitals.dead(P.Players.vitals(player)) == 0 : U32}
  {V.Vitals.dead(P.Players.vitals(Cooldown.run(inputs,player))) == 0 : U32}

def Cooldown.run_alive(inputs,player,alive):
  match inputs:
    case Nil{}: alive
    case Con{head,rest}:
      match head:
        case Cooldown.Input{plan,tick,x,y}: Cooldown.run_alive(rest,P.Players.player(P.Players.upkeep(player,plan,tick,x,y)),Cooldown.player_alive(player,plan,tick,x,y,alive))

law Cooldown.run_exact:
  for +inputs: List<&2,Cooldown.Input>
  for +kind: C.Combat.Kind
  for +player: P.Players.State
  for +alive: {V.Vitals.dead(P.Players.vitals(player)) == 0 : U32}
  {U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(Cooldown.run(inputs,player)))) == Cooldown.remaining(Cooldown.length(inputs),U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(player)))) : Nat}

def Cooldown.run_exact(inputs,kind,player,alive):
  match inputs:
    case Nil{}: {==}
    case Con{head,rest}:
      match head:
        case Cooldown.Input{plan,tick,x,y}:
          +next = P.Players.player(P.Players.upkeep(player,plan,tick,x,y))
          %Cooldown.dec(C.Combat.cooldown(kind,P.Players.vitals(player))) : {U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(Cooldown.run(rest,next)))) == Cooldown.remaining(Cooldown.length(rest),_) : Nat}
          %Cooldown.player_cooldown(kind,player,plan,tick,x,y,alive) : {U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(Cooldown.run(rest,next)))) == Cooldown.remaining(Cooldown.length(rest),U32.to_nat(_)) : Nat}
          Cooldown.run_exact(rest,kind,next,Cooldown.player_alive(player,plan,tick,x,y,alive))

law Cooldown.word_zero:
  for +value: U32
  for +zero: {U32.to_nat(value) == 0n : Nat}
  {value == 0 : U32}

def Cooldown.word_zero(value,zero): Equal.trans(U32,value,U32.from_nat(U32.to_nat(value)),0,Equal.sym(U32,U32.from_nat(U32.to_nat(value)),value,N.Numeric.u32_roundtrip(value)),Equal.cong(Nat,U32,(n => U32.from_nat(n)),U32.to_nat(value),0n,zero))

# Positive availability: enough actual living-player upkeep steps release the
# command in active phase. This is not a claim about arbitrary full world ticks.
law Cooldown.run_ready:
  for +inputs: List<&2,Cooldown.Input>
  for +kind: C.Combat.Kind
  for +player: P.Players.State
  for +alive: {V.Vitals.dead(P.Players.vitals(player)) == 0 : U32}
  for +enough: {G.Bq.Nat.le(U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(player))),Cooldown.length(inputs)) == True{} : Bool}
  {C.Combat.prepare(kind,1,Cooldown.run(inputs,player)) == C.Combat.Step{C.Combat.stamp(kind,Cooldown.run(inputs,player)),True{}} : C.Combat.Step}

def Cooldown.run_ready(inputs,kind,player,alive,enough):
  +after = Cooldown.run(inputs,player)
  C.Combat.live_ready(kind,after,Cooldown.run_alive(inputs,player,alive),Cooldown.word_zero(C.Combat.cooldown(kind,P.Players.vitals(after)),Equal.trans(Nat,U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(after))),Cooldown.remaining(Cooldown.length(inputs),U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(player)))),0n,Cooldown.run_exact(inputs,kind,player,alive),Cooldown.exhausted(Cooldown.length(inputs),U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(player))),enough))))

law Cooldown.player_finish_hit:
  for +player: P.Players.State
  for +hit: V.Vitals.Hit
  {P.Players.vitals(P.Players.player(P.Players.finish_hit(player,hit))) == V.Vitals.hit_state(hit) : V.Vitals.State}

def Cooldown.player_finish_hit(player,hit):
  match player:
    case P.Players.State{pid,cid,hero,pos,old,style,quest,meta}:
      match hit:
        case V.Vitals.Hit{state,fell}:
          match fell:
            case False{}: {==}
            case True{}: {==}

law Cooldown.player_hurt:
  for +kind: C.Combat.Kind
  for +player: P.Players.State
  for +attack: U32
  for +timer: U32
  {C.Combat.cooldown(kind,P.Players.vitals(P.Players.player(P.Players.hurt(player,attack,timer)))) == C.Combat.cooldown(kind,P.Players.vitals(player)) : U32}

def Cooldown.player_hurt(kind,player,attack,timer):
  +hit = V.Vitals.hit(P.Players.vitals(player),P.Players.mob_hit(attack,P.Players.hero(player)),timer)
  %Equal.sym(V.Vitals.State,P.Players.vitals(P.Players.player(P.Players.finish_hit(player,hit))),V.Vitals.hit_state(hit),Cooldown.player_finish_hit(player,hit)) : {C.Combat.cooldown(kind,_) == C.Combat.cooldown(kind,P.Players.vitals(player)) : U32}
  Cooldown.hit(kind,P.Players.vitals(player),P.Players.mob_hit(attack,P.Players.hero(player)),timer)

def Cooldown.dead_value(ready: Bool,old: U32) -> U32:
  match ready:
    case False{}: old
    case True{}: 0

def Cooldown.respawn(state: V.Vitals.State) -> U32:
  match state:
    case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: respawn

law Cooldown.dead_tick:
  for +ready: Bool
  for +kind: C.Combat.Kind
  for +state: V.Vitals.State
  for +maximum: U32
  {C.Combat.cooldown(kind,V.Vitals.upkeep_state(V.Vitals.dead_tick(ready,state,maximum))) == Cooldown.dead_value(ready,C.Combat.cooldown(kind,state)) : U32}

def Cooldown.dead_tick(ready,kind,state,maximum):
  match ready:
    case False{}: Cooldown.wait(kind,state)
    case True{}: Cooldown.revive(kind,state,maximum)

law Cooldown.dead_upkeep:
  for +kind: C.Combat.Kind
  for +state: V.Vitals.State
  for +amount: U32
  for +maximum: U32
  for +dead: {V.Vitals.dead(state) == 1 : U32}
  {C.Combat.cooldown(kind,V.Vitals.upkeep_state(V.Vitals.upkeep(state,amount,maximum))) == Cooldown.dead_value(U32.is_le(Cooldown.respawn(state),1),C.Combat.cooldown(kind,state)) : U32}

def Cooldown.dead_upkeep(kind,state,amount,maximum,dead):
  match state:
    case V.Vitals.State{hp,xp,flag,respawn,attack,spin}:
      %Equal.sym(U32,flag,1,dead) : {C.Combat.cooldown(kind,V.Vitals.upkeep_state(V.Vitals.upkeep(V.Vitals.State{hp,xp,_,respawn,attack,spin},amount,maximum))) == Cooldown.dead_value(U32.is_le(respawn,1),C.Combat.cooldown(kind,V.Vitals.State{hp,xp,_,respawn,attack,spin})) : U32}
      Cooldown.dead_tick(U32.is_le(respawn,1),kind,V.Vitals.State{hp,xp,1,respawn,attack,spin},maximum)

law Cooldown.player_dead:
  for +kind: C.Combat.Kind
  for +player: P.Players.State
  for +plan: P.Players.Plan
  for +tick: U32
  for +x: U32
  for +y: U32
  for +dead: {V.Vitals.dead(P.Players.vitals(player)) == 1 : U32}
  {C.Combat.cooldown(kind,P.Players.vitals(P.Players.player(P.Players.upkeep(player,plan,tick,x,y)))) == Cooldown.dead_value(U32.is_le(Cooldown.respawn(P.Players.vitals(player)),1),C.Combat.cooldown(kind,P.Players.vitals(player))) : U32}

def Cooldown.player_dead(kind,player,plan,tick,x,y,dead):
  %Equal.sym(V.Vitals.State,P.Players.vitals(P.Players.player(P.Players.upkeep(player,plan,tick,x,y))),V.Vitals.upkeep_state(V.Vitals.upkeep(P.Players.vitals(player),P.Players.regen(tick,V.Vitals.hp(P.Players.vitals(player)),P.Players.maximum(player)),P.Players.maximum(player))),Cooldown.player_upkeep(player,plan,tick,x,y)) : {C.Combat.cooldown(kind,_) == Cooldown.dead_value(U32.is_le(Cooldown.respawn(P.Players.vitals(player)),1),C.Combat.cooldown(kind,P.Players.vitals(player))) : U32}
  Cooldown.dead_upkeep(kind,P.Players.vitals(player),P.Players.regen(tick,V.Vitals.hp(P.Players.vitals(player)),P.Players.maximum(player)),P.Players.maximum(player),dead)
