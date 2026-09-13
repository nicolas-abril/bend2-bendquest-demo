# Cooldown preservation and exact lookup after completed combat commands.
import Base
import ./battle.bend as B
import ./players.bend as P
import ./targeting.bend as T
import ./player_membership.bend as PM
import ./playerids.bend as Id
import ./allocation.bend as Alloc
import ./admission.bend as J
import ./combat.bend as C
import ./payouts.bend as Pay
import ./combat_actor.bend as Actor
import ./combat_admitted.bend as Admit
import ./vitals.bend as V
import ./live_combat.bend as L
import ./simulation.bend as S
import ./terrain.bend as Terrain

law Repeat.scan_skip:
  for +tail: List<&2,P.Players.State>
  for +head: P.Players.State
  for +id: U32
  {P.Players.found(P.Players.scan(tail,head,False{},id)) == P.Players.found(P.Players.take(tail,id)) : Maybe<&2,P.Players.State>}

def Repeat.scan_skip(tail,head,id):
  match tail:
    case Nil{}: {==}
    case Con{next,rest}: P.Players.prepend_found(head,P.Players.scan(rest,next,U32.is_eq(P.Players.id(next),id),id))

law Repeat.lookup_member:
  for +player: P.Players.State
  for -players: List<&2,P.Players.State>
  for +inside: T.Targeting.In<player,players>
  for +unique: Alloc.Allocation.Unique(Id.PlayerIds.project(Id.PlayerIds.Player{},players))
  {P.Players.found(P.Players.take(players,P.Players.id(player))) == Some{player} : Maybe<&2,P.Players.State>}

def Repeat.lookup_member(player,players,inside,unique):
  match inside:
    case T.Targeting.Here{rest,shape}:
      %Equal.sym(List<&2,P.Players.State>,players,Con{player,rest},shape) : {P.Players.found(P.Players.take(_,P.Players.id(player))) == Some{player} : Maybe<&2,P.Players.State>}
      Equal.cong(P.Players.Take,Maybe<&2,P.Players.State>,(taken => P.Players.found(taken)),P.Players.take(Con{player,rest},P.Players.id(player)),P.Players.Take{rest,Some{player}},P.Players.take_head(player,rest))
    case T.Targeting.There{head,rest,shape,later}:
      +valid = {(%shape : Alloc.Allocation.Unique(Id.PlayerIds.project(Id.PlayerIds.Player{},_)); unique) : Alloc.Allocation.Unique(Con{P.Players.id(head),Id.PlayerIds.project(Id.PlayerIds.Player{},rest)})}
      +different = PM.PlayerMembership.absent_member(Id.PlayerIds.Player{},player,rest,later,P.Players.id(head),Id.PlayerIds.unique_head(P.Players.id(head),Id.PlayerIds.project(Id.PlayerIds.Player{},rest),valid))
      %Equal.sym(List<&2,P.Players.State>,players,Con{head,rest},shape) : {P.Players.found(P.Players.take(_,P.Players.id(player))) == Some{player} : Maybe<&2,P.Players.State>}
      %Equal.sym(Bool,U32.is_eq(P.Players.id(head),P.Players.id(player)),False{},different) : {P.Players.found(P.Players.scan(rest,head,_,P.Players.id(player))) == Some{player} : Maybe<&2,P.Players.State>}
      Equal.trans(Maybe<&2,P.Players.State>,P.Players.found(P.Players.scan(rest,head,False{},P.Players.id(player))),P.Players.found(P.Players.take(rest,P.Players.id(player))),Some{player},Repeat.scan_skip(rest,head,P.Players.id(player)),Repeat.lookup_member(player,rest,later,Id.PlayerIds.unique_tail(P.Players.id(head),Id.PlayerIds.project(Id.PlayerIds.Player{},rest),valid)))

def Repeat.Locked(+kind: C.Combat.Kind,+player: P.Players.State) -> Data:
  {C.Combat.cooldown(kind,P.Players.vitals(player)) == C.Combat.delay(kind) : U32}

law Repeat.stamp_locked:
  for +kind: C.Combat.Kind
  for +player: P.Players.State
  Repeat.Locked(kind,C.Combat.stamp(kind,player))

def Repeat.stamp_locked(kind,player):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}: C.Combat.stamp_cooldown(kind,vitals)

law Repeat.delay_positive:
  for +kind: C.Combat.Kind
  {U32.is_gt(C.Combat.delay(kind),0) == True{} : Bool}

def Repeat.delay_positive(kind):
  match kind:
    case C.Combat.Attack{}: {==}
    case C.Combat.Spin{}: {==}

law Repeat.locked_rejected:
  for +kind: C.Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  for +locked: Repeat.Locked(kind,player)
  {C.Combat.prepare(kind,phase,player) == C.Combat.Step{player,False{}} : C.Combat.Step}

def Repeat.locked_rejected(kind,phase,player,locked): C.Combat.cooling_rejected(kind,phase,player,(%Equal.sym(U32,C.Combat.cooldown(kind,P.Players.vitals(player)),C.Combat.delay(kind),locked) : {U32.is_gt(_,0) == True{} : Bool}; Repeat.delay_positive(kind)))

def Repeat.frame_cooldown(kind: C.Combat.Kind,frame: Pay.Payout.Frame) -> U32:
  match kind:
    case C.Combat.Attack{}:
      match frame:
        case Pay.Payout.Frame{pid,cid,pos,hp,dead,respawn,attack,spin,style,name}: attack
    case C.Combat.Spin{}:
      match frame:
        case Pay.Payout.Frame{pid,cid,pos,hp,dead,respawn,attack,spin,style,name}: spin

law Repeat.frame_cooldown_of:
  for +kind: C.Combat.Kind
  for +player: P.Players.State
  {Repeat.frame_cooldown(kind,Pay.Payout.frame(player)) == C.Combat.cooldown(kind,P.Players.vitals(player)) : U32}

def Repeat.frame_cooldown_of(kind,player):
  match kind:
    case C.Combat.Attack{}:
      match player:
        case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
          match vitals:
            case V.Vitals.State{hp,xp,dead,respawn,attack,spin}:
              match meta:
                case P.Players.Meta{score,kills,found,name}: {==}
    case C.Combat.Spin{}:
      match player:
        case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
          match vitals:
            case V.Vitals.State{hp,xp,dead,respawn,attack,spin}:
              match meta:
                case P.Players.Meta{score,kills,found,name}: {==}

law Repeat.frame_locked:
  for +kind: C.Combat.Kind
  for +before: P.Players.State
  for +after: P.Players.State
  for +same: {Pay.Payout.frame(after) == Pay.Payout.frame(before) : Pay.Payout.Frame}
  for +locked: Repeat.Locked(kind,before)
  Repeat.Locked(kind,after)

def Repeat.frame_locked(kind,before,after,same,locked):
  %Repeat.frame_cooldown_of(kind,after) : {_ == C.Combat.delay(kind) : U32}
  %Equal.sym(Pay.Payout.Frame,Pay.Payout.frame(after),Pay.Payout.frame(before),same) : {Repeat.frame_cooldown(kind,_) == C.Combat.delay(kind) : U32}
  %Equal.sym(U32,Repeat.frame_cooldown(kind,Pay.Payout.frame(before)),C.Combat.cooldown(kind,P.Players.vitals(before)),Repeat.frame_cooldown_of(kind,before)) : {_ == C.Combat.delay(kind) : U32}
  locked

# Accepted actors have the exact newly stamped delay, including zero-target
# attacks/spins. The predicate is conditional on actual Some admission.
def Repeat.Found(found: Maybe<&2,P.Players.State>,+kind: C.Combat.Kind) -> Data:
  match found:
    case None{}: Unit
    case Some{player}: Repeat.Locked(kind,player)

def Repeat.Cooled(result: C.Combat.Result,+kind: C.Combat.Kind) -> Data:
  match result:
    case C.Combat.Result{players,actor}: Repeat.Found(actor,kind)

law Repeat.gate_cooled:
  for +blocked: Bool
  for +kind: C.Combat.Kind
  for +player: P.Players.State
  for +others: List<&2,P.Players.State>
  Repeat.Cooled(C.Combat.finish(C.Combat.gate(blocked,kind,player),others),kind)

def Repeat.gate_cooled(blocked,kind,player,others):
  match blocked:
    case True{}: Unit{}
    case False{}: Repeat.stamp_locked(kind,player)

law Repeat.taken_cooled:
  for +taken: P.Players.Take
  for +kind: C.Combat.Kind
  for +phase: U32
  Repeat.Cooled(C.Combat.apply_taken(taken,kind,phase),kind)

def Repeat.taken_cooled(taken,kind,phase):
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}: Unit{}
        case Some{player}: Repeat.gate_cooled(C.Combat.blocked(kind,phase,player),kind,player,others)

law Repeat.run_cooled:
  for +players: List<&2,P.Players.State>
  for +pid: U32
  for +kind: C.Combat.Kind
  for +phase: U32
  Repeat.Cooled(C.Combat.run(players,pid,kind,phase),kind)

def Repeat.run_cooled(players,pid,kind,phase): Repeat.taken_cooled(P.Players.take(players,pid),kind,phase)

def Repeat.Ready(ready: L.LiveCombat.Ready,+kind: C.Combat.Kind) -> Data:
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,result,pid,score}: Repeat.Cooled(result,kind)

law Repeat.prepare_cooled:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  Repeat.Ready(L.LiveCombat.prepare(world,kind,pid,score),kind)

def Repeat.prepare_cooled(world,kind,pid,score):
  match world:
    case Terrain.Terrain.World{meta,players,monsters,maps}: Repeat.run_cooled(players,pid,kind,S.Simulation.phase(meta))

type Repeat.Held<-kind: C.Combat.Kind,-pid: U32,-players: List<&2,P.Players.State>> is Data:
  Repeat.Held{player: P.Players.State,inside: T.Targeting.In<player,players>,same: {P.Players.id(player) == pid : U32},locked: Repeat.Locked(kind,player)}

law Repeat.member_held:
  for +kind: C.Combat.Kind
  for +pid: U32
  for +before: P.Players.State
  for +players: List<&2,P.Players.State>
  for +member: Actor.Actor.Member<before,players>
  for +same: {P.Players.id(before) == pid : U32}
  for +locked: Repeat.Locked(kind,before)
  Repeat.Held<kind,pid,players>

def Repeat.member_held(kind,pid,before,players,member,same,locked):
  match member:
    case Actor.Actor.Member{after,inside,frame}: Repeat.Held{after,inside,Equal.trans(U32,P.Players.id(after),P.Players.id(before),pid,Actor.Actor.same_pid(after,before,frame),same),Repeat.frame_locked(kind,before,after,frame,locked)}

# This is conditional on the first command being accepted. It does not assume
# which player record rewards return; member_held recovers that exact record.
def Repeat.WhenAccepted(ready: L.LiveCombat.Ready,+kind: C.Combat.Kind,+world: Terrain.Terrain.World) -> Data:
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}: Unit
            case Some{player}: Repeat.Held<kind,pid,S.Simulation.players(Terrain.Terrain.simulation(world))>

law Repeat.finish_held:
  for +ready: L.LiveCombat.Ready
  for +kind: C.Combat.Kind
  for +plan: L.LiveCombat.Plan
  for +valid: Admit.Admitted.Ready(ready)
  for +cooled: Repeat.Ready(ready,kind)
  Repeat.WhenAccepted(ready,kind,L.LiveCombat.world(L.LiveCombat.finish(ready,plan)))

def Repeat.finish_held(ready,kind,plan,valid,cooled):
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}: Unit{}
            case Some{player}:
              match valid:
                case Tuple{inside,same}: Repeat.member_held(kind,pid,player,S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.finish(L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,Some{player}},pid,score},plan)))),Admit.Admitted.finish_accepted(meta,monsters,maps,players,player,pid,score,plan,inside),same,cooled)

law Repeat.run_held:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  Repeat.WhenAccepted(L.LiveCombat.prepare(world,kind,pid,score),kind,L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,planner)))

def Repeat.run_held(world,kind,pid,score,planner):
  +ready = L.LiveCombat.prepare(world,kind,pid,score)
  Repeat.finish_held(ready,kind,planner(ready),Admit.Admitted.live_prepare(world,kind,pid,score),Repeat.prepare_cooled(world,kind,pid,score))

law Repeat.reject_taken:
  for +taken: P.Players.Take
  for +kind: C.Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  for +same: {P.Players.found(taken) == Some{player} : Maybe<&2,P.Players.State>}
  for +locked: Repeat.Locked(kind,player)
  {C.Combat.apply_taken(taken,kind,phase) == C.Combat.Result{P.Players.restore(taken),None{}} : C.Combat.Result}

def Repeat.reject_taken(taken,kind,phase,player,same,locked):
  match taken:
    case P.Players.Take{others,found}:
      %Equal.sym(Maybe<&2,P.Players.State>,found,Some{player},same) : {C.Combat.apply_taken(P.Players.Take{others,_},kind,phase) == C.Combat.Result{P.Players.restore(P.Players.Take{others,_}),None{}} : C.Combat.Result}
      %Equal.sym(C.Combat.Step,C.Combat.prepare(kind,phase,player),C.Combat.Step{player,False{}},Repeat.locked_rejected(kind,phase,player,locked)) : {C.Combat.finish(_,others) == C.Combat.Result{Con{player,others},None{}} : C.Combat.Result}
      {==}

law Repeat.held_rejected:
  for +players: List<&2,P.Players.State>
  for +kind: C.Combat.Kind
  for +pid: U32
  for +phase: U32
  for +held: Repeat.Held<kind,pid,players>
  for +unique: J.Admission.Unique<players>
  {C.Combat.run(players,pid,kind,phase) == C.Combat.Result{P.Players.restore(P.Players.take(players,pid)),None{}} : C.Combat.Result}

def Repeat.held_rejected(players,kind,pid,phase,held,unique):
  match held:
    case Repeat.Held{player,inside,same,locked}: Repeat.reject_taken(P.Players.take(players,pid),kind,phase,player,(%same : {P.Players.found(P.Players.take(players,_)) == Some{player} : Maybe<&2,P.Players.State>}; Repeat.lookup_member(player,players,inside,Id.PlayerIds.from_admission(Id.PlayerIds.Player{},players,unique))),locked)

# Exact result of rejection: no messages/visual, unchanged metadata/maps/
# monsters and the same complete player records restored after the lookup.
def Repeat.quiet(world: Terrain.Terrain.World,pid: U32) -> L.LiveCombat.Result:
  match world:
    case Terrain.Terrain.World{meta,players,monsters,maps}: L.LiveCombat.Result{Terrain.Terrain.world(maps,S.Simulation.State{meta,P.Players.restore(P.Players.take(players,pid)),monsters}),Nil{},L.LiveCombat.Quiet{}}

law Repeat.live_rejected:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for +plan: L.LiveCombat.Plan
  for +held: Repeat.Held<kind,pid,S.Simulation.players(Terrain.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(Terrain.Terrain.simulation(world))>
  {L.LiveCombat.at(world,kind,pid,score,plan) == Repeat.quiet(world,pid) : L.LiveCombat.Result}

def Repeat.live_rejected(world,kind,pid,score,plan,held,unique):
  match world:
    case Terrain.Terrain.World{meta,players,monsters,maps}:
      %Equal.sym(C.Combat.Result,C.Combat.run(players,pid,kind,S.Simulation.phase(meta)),C.Combat.Result{P.Players.restore(P.Players.take(players,pid)),None{}},Repeat.held_rejected(players,kind,pid,S.Simulation.phase(meta),held,unique)) : {L.LiveCombat.finish(L.LiveCombat.Ready{meta,monsters,maps,_,pid,score},plan) == Repeat.quiet(Terrain.Terrain.World{meta,players,monsters,maps},pid) : L.LiveCombat.Result}
      L.LiveCombat.finish_rejected(meta,P.Players.restore(P.Players.take(players,pid)),monsters,maps,pid,score,plan)

law Repeat.live_run_rejected:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +held: Repeat.Held<kind,pid,S.Simulation.players(Terrain.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(Terrain.Terrain.simulation(world))>
  {L.LiveCombat.run(world,kind,pid,score,planner) == Repeat.quiet(world,pid) : L.LiveCombat.Result}

def Repeat.live_run_rejected(world,kind,pid,score,planner,held,unique): Repeat.live_rejected(world,kind,pid,score,planner(L.LiveCombat.prepare(world,kind,pid,score)),held,unique)

law Repeat.at_unique:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for +plan: L.LiveCombat.Plan
  for +unique: J.Admission.Unique<S.Simulation.players(Terrain.Terrain.simulation(world))>
  J.Admission.Unique<S.Simulation.players(Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.at(world,kind,pid,score,plan))))>

def Repeat.at_unique(world,kind,pid,score,plan,unique):
  %Equal.sym(S.Simulation.State,Terrain.Terrain.simulation(L.LiveCombat.world(L.LiveCombat.at(world,kind,pid,score,plan))),B.Battle.state(B.Battle.command(kind,Terrain.Terrain.simulation(world),L.LiveCombat.inputs(plan),pid,score)),L.LiveCombat.at_refines(world,kind,pid,score,plan)) : J.Admission.Unique<S.Simulation.players(_)>
  Id.PlayerIds.command_unique(kind,Terrain.Terrain.simulation(world),L.LiveCombat.inputs(plan),pid,score,unique)

def Repeat.Outcome(ready: L.LiveCombat.Ready,+world: Terrain.Terrain.World,+second: L.LiveCombat.Result) -> Data:
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}: Unit
            case Some{player}: {second == Repeat.quiet(world,pid) : L.LiveCombat.Result}

def Repeat.pid(ready: L.LiveCombat.Ready) -> U32:
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}: pid

law Repeat.repeat_after:
  for +ready: L.LiveCombat.Ready
  for +kind: C.Combat.Kind
  for +world: Terrain.Terrain.World
  for +score: U32
  for second: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +held: Repeat.WhenAccepted(ready,kind,world)
  for +unique: J.Admission.Unique<S.Simulation.players(Terrain.Terrain.simulation(world))>
  Repeat.Outcome(ready,world,L.LiveCombat.run(world,kind,Repeat.pid(ready),score,second))

def Repeat.repeat_after(ready,kind,world,score,second,held,unique):
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,first_score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}: Unit{}
            case Some{player}: Repeat.live_run_rejected(world,kind,pid,score,second,held,unique)

law Repeat.ready_pid:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  {Repeat.pid(L.LiveCombat.prepare(world,kind,pid,score)) == pid : U32}

def Repeat.ready_pid(world,kind,pid,score):
  match world:
    case Terrain.Terrain.World{meta,players,monsters,maps}: {==}

law Repeat.live_twice:
  for +world: Terrain.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +first_score: U32
  for +second_score: U32
  for first: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for second: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +unique: J.Admission.Unique<S.Simulation.players(Terrain.Terrain.simulation(world))>
  Repeat.Outcome(L.LiveCombat.prepare(world,kind,pid,first_score),L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,first_score,first)),L.LiveCombat.run(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,first_score,first)),kind,pid,second_score,second))

def Repeat.live_twice(world,kind,pid,first_score,second_score,first,second,unique):
  +ready = L.LiveCombat.prepare(world,kind,pid,first_score)
  +plan = first(ready)
  +result = L.LiveCombat.finish(ready,plan)
  %Repeat.ready_pid(world,kind,pid,first_score) : Repeat.Outcome(ready,L.LiveCombat.world(result),L.LiveCombat.run(L.LiveCombat.world(result),kind,_,second_score,second))
  Repeat.repeat_after(ready,kind,L.LiveCombat.world(result),second_score,second,Repeat.finish_held(ready,kind,plan,Admit.Admitted.live_prepare(world,kind,pid,first_score),Repeat.prepare_cooled(world,kind,pid,first_score)),Repeat.at_unique(world,kind,pid,first_score,plan,unique))
