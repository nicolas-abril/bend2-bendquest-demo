# Effective live-tick bounds between accepted uses of one combat kind.
import Base
import ./live_combat.bend as L
import ./targeting.bend as Member
import ./admission.bend as J
import ./playerids.bend as Id
import ./combat_repeat.bend as Repeat
import ./combat.bend as C
import ./combat_history.bend as H
import ./combat_transition.bend as Transition
import ./combat_cooling.bend as Cooling
import ./cooldown_tick.bend as CD
import ./cooldown_actor.bend as Tracked
import ./cooldown_roster.bend as TC
import ./players.bend as P
import ./vitals.bend as V
import ./simulation.bend as S
import ./terrain.bend as T
import ./world_clock.bend as Clock
import ./game.bend as G
import ./numeric.bend as N

# Count only actual active upkeep steps that take the live branch.
def Bounds.count_gate(running: Bool,dead: Bool) -> Nat:
  match running:
    case False{}: 0n
    case True{}:
      match dead:
        case False{}: 1n
        case True{}: 0n

def Bounds.count(+world: T.Terrain.World,operation: H.History.Operation,+player: P.Players.State) -> Nat:
  match operation:
    case H.History.Tick{timer}: Bounds.count_gate(U32.is_eq(S.Simulation.phase(S.Simulation.meta(T.Terrain.simulation(world))),1),U32.is_eq(V.Vitals.dead(P.Players.vitals(player)),1))
    case H.History.Command{now,kind,pid,score,plan}: 0n

# A protected use occurs only for this PID, this kind and accepted admission.
def Bounds.used(same: Bool,blocked: Bool) -> Bool:
  match same:
    case False{}: False{}
    case True{}: Bool.not(blocked)

def Bounds.claim(protected: C.Combat.Kind,kind: C.Combat.Kind,same: Bool,blocked: Bool) -> Bool:
  match protected:
    case C.Combat.Attack{}:
      match kind:
        case C.Combat.Attack{}: Bounds.used(same,blocked)
        case C.Combat.Spin{}: False{}
    case C.Combat.Spin{}:
      match kind:
        case C.Combat.Attack{}: False{}
        case C.Combat.Spin{}: Bounds.used(same,blocked)

def Bounds.use(+protected: C.Combat.Kind,+world: T.Terrain.World,operation: H.History.Operation,+player: P.Players.State) -> Bool:
  match operation:
    case H.History.Tick{timer}: False{}
    case H.History.Command{now,kind,pid,score,plan}:
      +kind = kind
      Bounds.claim(protected,kind,U32.is_eq(P.Players.id(player),pid),C.Combat.blocked(kind,S.Simulation.phase(S.Simulation.meta(T.Terrain.simulation(Clock.WorldClock.set(world,now)))),player))

def Bounds.rest(entries: List<&2,H.History.Entry>) -> List<&2,H.History.Entry>:
  match entries:
    case Nil{}: Nil{}
    case Con{head,rest}: rest

law Bounds.tails:
  for +a: H.History.Entry
  for +b: H.History.Entry
  for +xs: List<&2,H.History.Entry>
  for +ys: List<&2,H.History.Entry>
  for +same: {Con{a,xs} == Con{b,ys} : List<&2,H.History.Entry>}
  {xs == ys : List<&2,H.History.Entry>}

def Bounds.tails(a,b,xs,ys,same):
  %same : {xs == Bounds.rest(_) : List<&2,H.History.Entry>}
  {==}

def Bounds.ticks(+entries: List<&2,H.History.Entry>,+world: T.Terrain.World,+player: P.Players.State,-last_world: T.Terrain.World,-last_player: P.Players.State,+follow: H.History.Follow<entries,world,player,last_world,last_player>) -> Nat:
  match entries:
    case Nil{}: 0n
    case Con{entry,rest}:
      match follow:
        case H.History.Done{empty,world_same,player_same,inside}: 0n
        case H.History.Step{operation,later,shape,before_inside,after,inside,same,guard,tail}:
          +tail_rest = {(%Equal.sym(List<&2,H.History.Entry>,rest,later,Bounds.tails(entry,H.History.Entry{world,operation,H.History.step(world,operation)},rest,later,shape)) : H.History.Follow<_,H.History.step(world,operation),after,last_world,last_player>; tail) : H.History.Follow<rest,H.History.step(world,operation),after,last_world,last_player>}
          Nat.add(Bounds.count(world,operation,player),Bounds.ticks(rest,H.History.step(world,operation),after,last_world,last_player,tail_rest))

def Bounds.Unused(+entries: List<&2,H.History.Entry>,+world: T.Terrain.World,+player: P.Players.State,-last_world: T.Terrain.World,-last_player: P.Players.State,+follow: H.History.Follow<entries,world,player,last_world,last_player>,+kind: C.Combat.Kind) -> Data:
  match entries:
    case Nil{}: Unit
    case Con{entry,rest}:
      match follow:
        case H.History.Done{empty,world_same,player_same,inside}: Unit
        case H.History.Step{operation,later,shape,before_inside,after,inside,same,guard,tail}:
          +tail_rest = {(%Equal.sym(List<&2,H.History.Entry>,rest,later,Bounds.tails(entry,H.History.Entry{world,operation,H.History.step(world,operation)},rest,later,shape)) : H.History.Follow<_,H.History.step(world,operation),after,last_world,last_player>; tail) : H.History.Follow<rest,H.History.step(world,operation),after,last_world,last_player>}
          Sigma<&2,&2,{Bounds.use(kind,world,operation,player) == False{} : Bool},(none => Bounds.Unused(rest,H.History.step(world,operation),after,last_world,last_player,tail_rest,kind))>

law Bounds.le_self:
  for +value: Nat
  {G.Bq.Nat.le(value,value) == True{} : Bool}

def Bounds.le_self(value):
  match value:
    case Zero{}: {==}
    case Succ{rest}: Bounds.le_self(rest)

law Bounds.pred_mono:
  for +a: Nat
  for +b: Nat
  for +less: {G.Bq.Nat.le(a,b) == True{} : Bool}
  {G.Bq.Nat.le(CD.Cooldown.pred(a),CD.Cooldown.pred(b)) == True{} : Bool}

def Bounds.pred_mono(a,b,less):
  match a:
    case Zero{}: {==}
    case Succ{ap}:
      match b:
        case Zero{}: Empty.absurd({G.Bq.Nat.le(ap,0n) == True{} : Bool},G.Bq.Bool.false_ne_true(less))
        case Succ{bp}: less

law Bounds.remaining_mono:
  for +ticks: Nat
  for +a: Nat
  for +b: Nat
  for +less: {G.Bq.Nat.le(a,b) == True{} : Bool}
  {G.Bq.Nat.le(CD.Cooldown.remaining(ticks,a),CD.Cooldown.remaining(ticks,b)) == True{} : Bool}

def Bounds.remaining_mono(ticks,a,b,less):
  match ticks:
    case Zero{}: less
    case Succ{rest}: Bounds.remaining_mono(rest,CD.Cooldown.pred(a),CD.Cooldown.pred(b),Bounds.pred_mono(a,b,less))

law Bounds.remaining_add:
  for +first: Nat
  for +second: Nat
  for +value: Nat
  {CD.Cooldown.remaining(Nat.add(first,second),value) == CD.Cooldown.remaining(second,CD.Cooldown.remaining(first,value)) : Nat}

def Bounds.remaining_add(first,second,value):
  match first:
    case Zero{}: {==}
    case Succ{rest}: Bounds.remaining_add(rest,second,CD.Cooldown.pred(value))

law Bounds.same_compute:
  for +same: Bool
  for +blocked: Bool
  for +kind: C.Combat.Kind
  for +frame: TC.TickCooldown.Frame
  for +unused: {Bounds.used(same,blocked) == False{} : Bool}
  {Cooling.Cooling.counter(kind,Transition.Transition.compute(same,blocked,kind,frame)) == Cooling.Cooling.counter(kind,frame) : U32}

def Bounds.same_compute(same,blocked,kind,frame,unused):
  match same:
    case False{}: {==}
    case True{}:
      match blocked:
        case True{}: {==}
        case False{}: Empty.absurd({Cooling.Cooling.counter(kind,Transition.Transition.stamp(kind,frame)) == Cooling.Cooling.counter(kind,frame) : U32},N.Numeric.true_ne_false(unused))

law Bounds.other_compute:
  for +same: Bool
  for +blocked: Bool
  for +kind: C.Combat.Kind
  for +frame: TC.TickCooldown.Frame
  {Cooling.Cooling.counter(C.Combat.other(kind),Transition.Transition.compute(same,blocked,kind,frame)) == Cooling.Cooling.counter(C.Combat.other(kind),frame) : U32}

def Bounds.other_compute(same,blocked,kind,frame):
  match same:
    case False{}: {==}
    case True{}:
      match blocked:
        case True{}: {==}
        case False{}:
          match kind:
            case C.Combat.Attack{}:
              match frame:
                case TC.TickCooldown.Frame{pid,cid,attack,spin}: {==}
            case C.Combat.Spin{}:
              match frame:
                case TC.TickCooldown.Frame{pid,cid,attack,spin}: {==}

law Bounds.compute:
  for +protected: C.Combat.Kind
  for +kind: C.Combat.Kind
  for +same: Bool
  for +blocked: Bool
  for +frame: TC.TickCooldown.Frame
  for +unused: {Bounds.claim(protected,kind,same,blocked) == False{} : Bool}
  {Cooling.Cooling.counter(protected,Transition.Transition.compute(same,blocked,kind,frame)) == Cooling.Cooling.counter(protected,frame) : U32}

def Bounds.compute(protected,kind,same,blocked,frame,unused):
  match protected:
    case C.Combat.Attack{}:
      match kind:
        case C.Combat.Attack{}: Bounds.same_compute(same,blocked,C.Combat.Attack{},frame,unused)
        case C.Combat.Spin{}: Bounds.other_compute(same,blocked,C.Combat.Spin{},frame)
    case C.Combat.Spin{}:
      match kind:
        case C.Combat.Attack{}: Bounds.other_compute(same,blocked,C.Combat.Attack{},frame)
        case C.Combat.Spin{}: Bounds.same_compute(same,blocked,C.Combat.Spin{},frame,unused)

def Bounds.evolve(running: Bool,dead: Bool,ready: Bool,value: U32) -> U32:
  match running:
    case False{}: value
    case True{}: TC.TickCooldown.evolve(dead,ready,value)

law Bounds.tick_formula:
  for +running: Bool
  for +kind: C.Combat.Kind
  for +player: P.Players.State
  {Cooling.Cooling.counter(kind,Tracked.Tracked.choose(running,player)) == Bounds.evolve(running,U32.is_eq(V.Vitals.dead(P.Players.vitals(player)),1),U32.is_le(CD.Cooldown.respawn(P.Players.vitals(player)),1),C.Combat.cooldown(kind,P.Players.vitals(player))) : U32}

def Bounds.tick_formula(running,kind,player):
  match running:
    case False{}: Cooling.Cooling.counter_of(kind,player)
    case True{}:
      match kind:
        case C.Combat.Attack{}: {==}
        case C.Combat.Spin{}: {==}

law Bounds.tick_bound:
  for +running: Bool
  for +dead: Bool
  for +ready: Bool
  for +value: U32
  {G.Bq.Nat.le(U32.to_nat(Bounds.evolve(running,dead,ready,value)),CD.Cooldown.remaining(Bounds.count_gate(running,dead),U32.to_nat(value))) == True{} : Bool}

def Bounds.tick_bound(running,dead,ready,value):
  match running:
    case False{}: Bounds.le_self(U32.to_nat(value))
    case True{}:
      match dead:
        case False{}:
          %Equal.sym(Nat,U32.to_nat(V.Vitals.dec(value)),CD.Cooldown.pred(U32.to_nat(value)),CD.Cooldown.dec(value)) : {G.Bq.Nat.le(_,CD.Cooldown.pred(U32.to_nat(value))) == True{} : Bool}
          Bounds.le_self(CD.Cooldown.pred(U32.to_nat(value)))
        case True{}:
          match ready:
            case False{}: Bounds.le_self(U32.to_nat(value))
            case True{}: {==}

law Bounds.expected_bound:
  for +world: T.Terrain.World
  for +operation: H.History.Operation
  for +kind: C.Combat.Kind
  for +player: P.Players.State
  for +unused: {Bounds.use(kind,world,operation,player) == False{} : Bool}
  {G.Bq.Nat.le(U32.to_nat(Cooling.Cooling.counter(kind,H.History.expected(world,operation,player))),CD.Cooldown.remaining(Bounds.count(world,operation,player),U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(player))))) == True{} : Bool}

def Bounds.expected_bound(world,operation,kind,player,unused):
  match operation:
    case H.History.Tick{timer}:
      +running = U32.is_eq(S.Simulation.phase(S.Simulation.meta(T.Terrain.simulation(world))),1)
      +dead = U32.is_eq(V.Vitals.dead(P.Players.vitals(player)),1)
      +ready = U32.is_le(CD.Cooldown.respawn(P.Players.vitals(player)),1)
      +value = C.Combat.cooldown(kind,P.Players.vitals(player))
      %Equal.sym(U32,Cooling.Cooling.counter(kind,Tracked.Tracked.choose(running,player)),Bounds.evolve(running,dead,ready,value),Bounds.tick_formula(running,kind,player)) : {G.Bq.Nat.le(U32.to_nat(_),CD.Cooldown.remaining(Bounds.count_gate(running,dead),U32.to_nat(value))) == True{} : Bool}
      Bounds.tick_bound(running,dead,ready,value)
    case H.History.Command{now,acting,pid,score,plan}:
      +timed = Clock.WorldClock.set(world,now)
      +same = U32.is_eq(P.Players.id(player),pid)
      +blocked = C.Combat.blocked(acting,S.Simulation.phase(S.Simulation.meta(T.Terrain.simulation(timed))),player)
      %Equal.sym(U32,Cooling.Cooling.counter(kind,Transition.Transition.compute(same,blocked,acting,TC.TickCooldown.frame(player))),Cooling.Cooling.counter(kind,TC.TickCooldown.frame(player)),Bounds.compute(kind,acting,same,blocked,TC.TickCooldown.frame(player),unused)) : {G.Bq.Nat.le(U32.to_nat(_),U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(player)))) == True{} : Bool}
      %Equal.sym(U32,Cooling.Cooling.counter(kind,TC.TickCooldown.frame(player)),C.Combat.cooldown(kind,P.Players.vitals(player)),Cooling.Cooling.counter_of(kind,player)) : {G.Bq.Nat.le(U32.to_nat(_),U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(player)))) == True{} : Bool}
      Bounds.le_self(U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(player))))

law Bounds.step:
  for +world: T.Terrain.World
  for +operation: H.History.Operation
  for +kind: C.Combat.Kind
  for +before: P.Players.State
  for +after: P.Players.State
  for +same: {TC.TickCooldown.frame(after) == H.History.expected(world,operation,before) : TC.TickCooldown.Frame}
  for +unused: {Bounds.use(kind,world,operation,before) == False{} : Bool}
  {G.Bq.Nat.le(U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(after))),CD.Cooldown.remaining(Bounds.count(world,operation,before),U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(before))))) == True{} : Bool}

def Bounds.step(world,operation,kind,before,after,same,unused):
  %Cooling.Cooling.counter_of(kind,after) : {G.Bq.Nat.le(U32.to_nat(_),CD.Cooldown.remaining(Bounds.count(world,operation,before),U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(before))))) == True{} : Bool}
  %Equal.sym(TC.TickCooldown.Frame,TC.TickCooldown.frame(after),H.History.expected(world,operation,before),same) : {G.Bq.Nat.le(U32.to_nat(Cooling.Cooling.counter(kind,_)),CD.Cooldown.remaining(Bounds.count(world,operation,before),U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(before))))) == True{} : Bool}
  Bounds.expected_bound(world,operation,kind,before,unused)

def Bounds.nonempty(entries: List<&2,H.History.Entry>) -> Bool:
  match entries:
    case Nil{}: False{}
    case Con{head,rest}: True{}

law Bounds.cons_nil:
  for +head: H.History.Entry
  for +rest: List<&2,H.History.Entry>
  for +same: {Con{head,rest} == Nil{} : List<&2,H.History.Entry>}
  Empty

def Bounds.cons_nil(head,rest,same): N.Numeric.true_ne_false((%same : {True{} == Bounds.nonempty(_) : Bool}; {==}))

law Bounds.fold:
  for +entries: List<&2,H.History.Entry>
  for +world: T.Terrain.World
  for +player: P.Players.State
  for -last_world: T.Terrain.World
  for +last_player: P.Players.State
  for +follow: H.History.Follow<entries,world,player,last_world,last_player>
  for +kind: C.Combat.Kind
  for +unused: Bounds.Unused(entries,world,player,last_world,last_player,follow,kind)
  {G.Bq.Nat.le(U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(last_player))),CD.Cooldown.remaining(Bounds.ticks(entries,world,player,last_world,last_player,follow),U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(player))))) == True{} : Bool}

def Bounds.fold(entries,world,player,last_world,last_player,follow,kind,unused):
  match entries:
    case Nil{}:
      match follow:
        case H.History.Done{empty,world_same,player_same,inside}:
          %player_same : {G.Bq.Nat.le(U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(_))),U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(player)))) == True{} : Bool}
          Bounds.le_self(U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(player))))
        case H.History.Step{operation,later,shape,before_inside,after,inside,same,guard,tail}: Empty.absurd({G.Bq.Nat.le(U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(last_player))),U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(player)))) == True{} : Bool},Bounds.cons_nil(H.History.Entry{world,operation,H.History.step(world,operation)},later,Equal.sym(List<&2,H.History.Entry>,Nil{},Con{H.History.Entry{world,operation,H.History.step(world,operation)},later},shape)))
    case Con{entry,rest}:
      match follow:
        case H.History.Done{empty,world_same,player_same,inside}: Empty.absurd({G.Bq.Nat.le(U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(last_player))),U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(player)))) == True{} : Bool},Bounds.cons_nil(entry,rest,empty))
        case H.History.Step{operation,later,shape,before_inside,after,inside,same,guard,tail}:
          match unused:
            case Tuple{none,remaining}:
              +tail_rest = {(%Equal.sym(List<&2,H.History.Entry>,rest,later,Bounds.tails(entry,H.History.Entry{world,operation,H.History.step(world,operation)},rest,later,shape)) : H.History.Follow<_,H.History.step(world,operation),after,last_world,last_player>; tail) : H.History.Follow<rest,H.History.step(world,operation),after,last_world,last_player>}
              +step_ticks = Bounds.count(world,operation,player)
              +tail_ticks = Bounds.ticks(rest,H.History.step(world,operation),after,last_world,last_player,tail_rest)
              +first_value = U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(player)))
              +middle_value = U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(after)))
              +last_value = U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(last_player)))
              %Equal.sym(Nat,CD.Cooldown.remaining(Nat.add(step_ticks,tail_ticks),first_value),CD.Cooldown.remaining(tail_ticks,CD.Cooldown.remaining(step_ticks,first_value)),Bounds.remaining_add(step_ticks,tail_ticks,first_value)) : {G.Bq.Nat.le(last_value,_) == True{} : Bool}
              N.Numeric.le_trans(last_value,CD.Cooldown.remaining(tail_ticks,middle_value),CD.Cooldown.remaining(tail_ticks,CD.Cooldown.remaining(step_ticks,first_value)),Bounds.fold(rest,H.History.step(world,operation),after,last_world,last_player,tail_rest,kind,remaining),Bounds.remaining_mono(tail_ticks,middle_value,CD.Cooldown.remaining(step_ticks,first_value),Bounds.step(world,operation,kind,player,after,same,none)))

law Bounds.le_zero:
  for +value: Nat
  for +less: {G.Bq.Nat.le(value,0n) == True{} : Bool}
  {value == 0n : Nat}

def Bounds.le_zero(value,less):
  match value:
    case Zero{}: {==}
    case Succ{rest}: Empty.absurd({Succ{rest} == 0n : Nat},G.Bq.Bool.false_ne_true(less))

law Bounds.expired:
  for +entries: List<&2,H.History.Entry>
  for +world: T.Terrain.World
  for +player: P.Players.State
  for -last_world: T.Terrain.World
  for +last_player: P.Players.State
  for +follow: H.History.Follow<entries,world,player,last_world,last_player>
  for +kind: C.Combat.Kind
  for +unused: Bounds.Unused(entries,world,player,last_world,last_player,follow,kind)
  for +enough: {G.Bq.Nat.le(U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(player))),Bounds.ticks(entries,world,player,last_world,last_player,follow)) == True{} : Bool}
  {C.Combat.cooldown(kind,P.Players.vitals(last_player)) == 0 : U32}

def Bounds.expired(entries,world,player,last_world,last_player,follow,kind,unused,enough):
  CD.Cooldown.word_zero(C.Combat.cooldown(kind,P.Players.vitals(last_player)),Bounds.le_zero(U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(last_player))),(%CD.Cooldown.exhausted(Bounds.ticks(entries,world,player,last_world,last_player,follow),U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(player))),enough) : {G.Bq.Nat.le(U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(last_player))),_) == True{} : Bool}; Bounds.fold(entries,world,player,last_world,last_player,follow,kind,unused))))

def Bounds.attacker(result: C.Combat.Result) -> Maybe<&2,P.Players.State>:
  match result:
    case C.Combat.Result{players,attacker}: attacker

def Bounds.ready_actor(ready: L.LiveCombat.Ready) -> Maybe<&2,P.Players.State>:
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}: Bounds.attacker(admitted)

law Bounds.taken_ready:
  for +taken: P.Players.Take
  for +kind: C.Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  for +same: {P.Players.found(taken) == Some{player} : Maybe<&2,P.Players.State>}
  for +alive: {V.Vitals.dead(P.Players.vitals(player)) == 0 : U32}
  for +active: {phase == 1 : U32}
  for +zero: {C.Combat.cooldown(kind,P.Players.vitals(player)) == 0 : U32}
  {Bounds.attacker(C.Combat.apply_taken(taken,kind,phase)) == Some{C.Combat.stamp(kind,player)} : Maybe<&2,P.Players.State>}

def Bounds.taken_ready(taken,kind,phase,player,same,alive,active,zero):
  match taken:
    case P.Players.Take{others,found}:
      %Equal.sym(Maybe<&2,P.Players.State>,found,Some{player},same) : {Bounds.attacker(C.Combat.apply_taken(P.Players.Take{others,_},kind,phase)) == Some{C.Combat.stamp(kind,player)} : Maybe<&2,P.Players.State>}
      %Equal.sym(U32,phase,1,active) : {Bounds.attacker(C.Combat.finish(C.Combat.prepare(kind,_,player),others)) == Some{C.Combat.stamp(kind,player)} : Maybe<&2,P.Players.State>}
      %Equal.sym(C.Combat.Step,C.Combat.prepare(kind,1,player),C.Combat.Step{C.Combat.stamp(kind,player),True{}},C.Combat.live_ready(kind,player,alive,zero)) : {Bounds.attacker(C.Combat.finish(_,others)) == Some{C.Combat.stamp(kind,player)} : Maybe<&2,P.Players.State>}
      {==}

law Bounds.admitted:
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +player: P.Players.State
  for +score: U32
  for +inside: Member.Targeting.In<player,S.Simulation.players(T.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(world))>
  for +alive: {V.Vitals.dead(P.Players.vitals(player)) == 0 : U32}
  for +active: {S.Simulation.phase(S.Simulation.meta(T.Terrain.simulation(world))) == 1 : U32}
  for +zero: {C.Combat.cooldown(kind,P.Players.vitals(player)) == 0 : U32}
  {Bounds.ready_actor(L.LiveCombat.prepare(world,kind,P.Players.id(player),score)) == Some{C.Combat.stamp(kind,player)} : Maybe<&2,P.Players.State>}

def Bounds.admitted(world,kind,player,score,inside,unique,alive,active,zero):
  match world:
    case T.Terrain.World{meta,players,monsters,maps}: Bounds.taken_ready(P.Players.take(players,P.Players.id(player)),kind,S.Simulation.phase(meta),player,Repeat.Repeat.lookup_member(player,players,inside,Id.PlayerIds.from_admission(Id.PlayerIds.Player{},players,unique)),alive,active,zero)

# These conditions inspect the actual history certificate. They do not assume
# the final cooldown, membership, lookup or uniqueness that the proof derives.
def Bounds.Conditions(-run: H.History.Run,+world: T.Terrain.World,+player: P.Players.State,+certificate: H.History.OK<run,world,player>,+kind: C.Combat.Kind) -> Data:
  match certificate:
    case H.History.OK{last_world,world_same,entries,entries_same,last_player,inside,unique,follow,same_pid}:
      Sigma<&2,&2,Bounds.Unused(entries,world,player,last_world,last_player,follow,kind),(unused => Sigma<&2,&2,{G.Bq.Nat.le(U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(player))),Bounds.ticks(entries,world,player,last_world,last_player,follow)) == True{} : Bool},(enough => Sigma<&2,&2,{V.Vitals.dead(P.Players.vitals(last_player)) == 0 : U32},(alive => {S.Simulation.phase(S.Simulation.meta(T.Terrain.simulation(last_world))) == 1 : U32})>)>)>

type Bounds.Ready<-run: H.History.Run,-original: P.Players.State,-kind: C.Combat.Kind,-score: U32> is Data:
  Bounds.Ready{world: T.Terrain.World,same_world: {world == H.History.world(run) : T.Terrain.World},player: P.Players.State,same_pid: {P.Players.id(player) == P.Players.id(original) : U32},admitted: {Bounds.ready_actor(L.LiveCombat.prepare(world,kind,P.Players.id(original),score)) == Some{C.Combat.stamp(kind,player)} : Maybe<&2,P.Players.State>}}

law Bounds.ready:
  for -run: H.History.Run
  for +world: T.Terrain.World
  for +player: P.Players.State
  for +certificate: H.History.OK<run,world,player>
  for +kind: C.Combat.Kind
  for +score: U32
  for +conditions: Bounds.Conditions(run,world,player,certificate,kind)
  Bounds.Ready<run,player,kind,score>

def Bounds.ready(run,world,player,certificate,kind,score,conditions):
  match certificate:
    case H.History.OK{last_world,world_same,entries,entries_same,last_player,inside,unique,follow,same_pid}:
      match conditions:
        case Tuple{unused,next}:
          match next:
            case Tuple{enough,health}:
              match health:
                case Tuple{alive,active}: Bounds.Ready{last_world,world_same,last_player,same_pid,(%same_pid : {Bounds.ready_actor(L.LiveCombat.prepare(last_world,kind,_,score)) == Some{C.Combat.stamp(kind,last_player)} : Maybe<&2,P.Players.State>}; Bounds.admitted(last_world,kind,last_player,score,inside,unique,alive,active,Bounds.expired(entries,world,player,last_world,last_player,follow,kind,unused,enough)))}

def Bounds.NoReuse(-run: H.History.Run,+world: T.Terrain.World,+player: P.Players.State,+certificate: H.History.OK<run,world,player>,+kind: C.Combat.Kind) -> Data:
  match certificate:
    case H.History.OK{last_world,world_same,entries,entries_same,last_player,inside,unique,follow,same_pid}: Bounds.Unused(entries,world,player,last_world,last_player,follow,kind)

def Bounds.Estimate(-run: H.History.Run,+world: T.Terrain.World,+player: P.Players.State,+certificate: H.History.OK<run,world,player>,+kind: C.Combat.Kind) -> Data:
  match certificate:
    case H.History.OK{last_world,world_same,entries,entries_same,last_player,inside,unique,follow,same_pid}: {G.Bq.Nat.le(U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(last_player))),CD.Cooldown.remaining(Bounds.ticks(entries,world,player,last_world,last_player,follow),U32.to_nat(C.Combat.cooldown(kind,P.Players.vitals(player))))) == True{} : Bool}

law Bounds.bound:
  for -run: H.History.Run
  for +world: T.Terrain.World
  for +player: P.Players.State
  for +certificate: H.History.OK<run,world,player>
  for +kind: C.Combat.Kind
  for +unused: Bounds.NoReuse(run,world,player,certificate,kind)
  Bounds.Estimate(run,world,player,certificate,kind)

def Bounds.bound(run,world,player,certificate,kind,unused):
  match certificate:
    case H.History.OK{last_world,world_same,entries,entries_same,last_player,inside,unique,follow,same_pid}: Bounds.fold(entries,world,player,last_world,last_player,follow,kind,unused)
