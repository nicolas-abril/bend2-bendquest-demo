# Exact player/cooldown histories across arbitrary live ticks and combat commands.
import Base
import ./numeric.bend as N
import ./combat_rejected.bend as R
import ./combat.bend as C
import ./live_combat.bend as L
import ./live_tick.bend as Tick
import ./terrain.bend as T
import ./simulation.bend as S
import ./players.bend as P
import ./targeting.bend as Member
import ./admission.bend as J
import ./playerids.bend as Id
import ./allocation.bend as A
import ./ai_refs.bend as AI
import ./planning.bend as Plan
import ./locomotion.bend as Walk
import ./combat_repeat.bend as Repeat
import ./combat_transition.bend as Transition
import ./cooldown_actor.bend as Tracked
import ./cooldown_roster.bend as TC
import ./combat_clock.bend as CC
import ./world_clock.bend as Clock
import ./seeded_world.bend as SW
import ./sessions.bend as Sess

# Requests carry affine callbacks; recorded operations contain their actual plans.
type History.Request is Type:
  History.TickRequest{timer: U32}
  History.CommandRequest{now: U32,kind: C.Combat.Kind,pid: U32,score: U32,planner: L.LiveCombat.Ready -> L.LiveCombat.Plan}

type History.Operation is Data:
  History.Tick{timer: U32}
  History.Command{now: U32,kind: C.Combat.Kind,pid: U32,score: U32,plan: L.LiveCombat.Plan}

def History.step(+world: T.Terrain.World,operation: History.Operation) -> T.Terrain.World:
  match operation:
    case History.Tick{timer}: Tick.LiveTick.world(Tick.LiveTick.run(world,timer))
    case History.Command{now,kind,pid,score,plan}: L.LiveCombat.world(L.LiveCombat.at(Clock.WorldClock.set(world,now),kind,pid,score,plan))

def History.expected(+world: T.Terrain.World,operation: History.Operation,+player: P.Players.State) -> TC.TickCooldown.Frame:
  match operation:
    case History.Tick{timer}: Tracked.Tracked.next(world,player)
    case History.Command{now,kind,pid,score,plan}: Transition.Transition.next(Clock.WorldClock.set(world,now),kind,pid,player)

# Unique IDs survive actual live-tick AI selection, even without health premises.
law History.selected_unique:
  for +kind: Id.PlayerIds.Kind
  for +prepared: S.Simulation.Prepared
  for +maps: T.Terrain.Maps
  for +d0: List<&2,U32>
  for +d1: List<&2,U32>
  for +d2: List<&2,U32>
  for +d3: List<&2,U32>
  for +rules: S.Simulation.Rules
  for +valid: A.Allocation.Unique(Id.PlayerIds.project(kind,P.Players.roster(S.Simulation.prepared_upkeep(prepared))))
  A.Allocation.Unique(Id.PlayerIds.project(kind,S.Simulation.players(S.Simulation.state(AI.AIRefs.finish(prepared,maps,d0,d1,d2,d3,rules)))))

def History.selected_unique(kind,prepared,maps,d0,d1,d2,d3,rules,valid):
  match prepared:
    case S.Simulation.Prepared{meta,monsters,upkeep,running}:
      match running:
        case False{}: Id.PlayerIds.planning_finish_unique(kind,S.Simulation.Prepared{meta,monsters,upkeep,False{}},maps,Nil{},Nil{},Nil{},Nil{},rules,valid)
        case True{}:
          +players = P.Players.roster(upkeep)
          Id.PlayerIds.planning_finish_unique(kind,S.Simulation.Prepared{meta,monsters,upkeep,True{}},maps,AI.AIRefs.contexts(monsters,players,0,d0),AI.AIRefs.contexts(monsters,players,1,d1),AI.AIRefs.contexts(monsters,players,2,d2),AI.AIRefs.contexts(monsters,players,3,d3),rules,valid)

law History.simulated_unique:
  for +kind: Id.PlayerIds.Kind
  for +damages: AI.AIRefs.Damages
  for +prepared: S.Simulation.Prepared
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  for +valid: A.Allocation.Unique(Id.PlayerIds.project(kind,P.Players.roster(S.Simulation.prepared_upkeep(prepared))))
  A.Allocation.Unique(Id.PlayerIds.project(kind,S.Simulation.players(S.Simulation.state(Tick.LiveTick.simulate(damages,prepared,maps,rules)))))

def History.simulated_unique(kind,damages,prepared,maps,rules,valid):
  match damages:
    case AI.AIRefs.Damages{d0,d1,d2,d3}: History.selected_unique(kind,prepared,maps,d0,d1,d2,d3,rules,valid)

law History.tick_key:
  for +kind: Id.PlayerIds.Kind
  for +world: T.Terrain.World
  for +timer: U32
  for +valid: A.Allocation.Unique(Id.PlayerIds.project(kind,S.Simulation.players(T.Terrain.simulation(world))))
  A.Allocation.Unique(Id.PlayerIds.project(kind,S.Simulation.players(T.Terrain.simulation(Tick.LiveTick.world(Tick.LiveTick.run(world,timer))))))

def History.tick_key(kind,world,timer,valid):
  +state = T.Terrain.simulation(world)
  +maps = T.Terrain.maps(world)
  +rules = Plan.Planning.rules(timer)
  +running = U32.is_eq(S.Simulation.phase(S.Simulation.meta(state)),1)
  +plans = Walk.Locomotion.tick_plans(running,S.Simulation.players(state),maps)
  +prepared = Walk.Locomotion.begin(state,maps,rules)
  +damages = Tick.LiveTick.damages(prepared)
  %Equal.sym(S.Simulation.State,T.Terrain.simulation(Tick.LiveTick.world(Tick.LiveTick.pack(Tick.LiveTick.simulate(damages,prepared,maps,rules),maps,S.Simulation.clock(S.Simulation.prepared_meta(prepared))))),S.Simulation.state(Tick.LiveTick.simulate(damages,prepared,maps,rules)),Tick.LiveTick.pack_simulation(Tick.LiveTick.simulate(damages,prepared,maps,rules),maps,S.Simulation.clock(S.Simulation.prepared_meta(prepared)))) : A.Allocation.Unique(Id.PlayerIds.project(kind,S.Simulation.players(_)))
  History.simulated_unique(kind,damages,prepared,maps,rules,(%Equal.sym(A.Allocation.Ids,Id.PlayerIds.project(kind,P.Players.roster(S.Simulation.prepared_upkeep(prepared))),Id.PlayerIds.project(kind,S.Simulation.players(state)),Id.PlayerIds.begin_gate_projection(kind,running,state,plans,rules)) : A.Allocation.Unique(_); valid))

law History.tick_unique:
  for +world: T.Terrain.World
  for +timer: U32
  for +valid: J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(world))>
  J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(Tick.LiveTick.world(Tick.LiveTick.run(world,timer))))>

def History.tick_unique(world,timer,valid): Id.PlayerIds.to_admission(S.Simulation.players(T.Terrain.simulation(Tick.LiveTick.world(Tick.LiveTick.run(world,timer)))),History.tick_key(Id.PlayerIds.Player{},world,timer,Id.PlayerIds.from_admission(Id.PlayerIds.Player{},S.Simulation.players(T.Terrain.simulation(world)),valid)),History.tick_key(Id.PlayerIds.Connection{},world,timer,Id.PlayerIds.from_admission(Id.PlayerIds.Connection{},S.Simulation.players(T.Terrain.simulation(world)),valid)))

law History.unique:
  for +world: T.Terrain.World
  for +operation: History.Operation
  for +valid: J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(world))>
  J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(History.step(world,operation)))>

def History.unique(world,operation,valid):
  match operation:
    case History.Tick{timer}: History.tick_unique(world,timer,valid)
    case History.Command{now,kind,pid,score,plan}: Repeat.Repeat.at_unique(Clock.WorldClock.set(world,now),kind,pid,score,plan,CC.CombatClock.unique(world,now,valid))

law History.observe:
  for +world: T.Terrain.World
  for +operation: History.Operation
  for +player: P.Players.State
  for +inside: Member.Targeting.In<player,S.Simulation.players(T.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(world))>
  Tracked.Tracked.Observed<History.expected(world,operation,player),S.Simulation.players(T.Terrain.simulation(History.step(world,operation)))>

def History.observe(world,operation,player,inside,unique):
  match operation:
    case History.Tick{timer}: Tracked.Tracked.live(world,player,timer,inside)
    case History.Command{now,kind,pid,score,plan}: Transition.Transition.live_computed(Clock.WorldClock.set(world,now),kind,pid,score,(unused => plan),player,(%Equal.sym(List<&2,P.Players.State>,S.Simulation.players(T.Terrain.simulation(Clock.WorldClock.set(world,now))),S.Simulation.players(T.Terrain.simulation(world)),CC.CombatClock.players(world,now)) : Member.Targeting.In<player,_>; inside),CC.CombatClock.unique(world,now,unique))

law History.frame_pid:
  for +world: T.Terrain.World
  for +operation: History.Operation
  for +player: P.Players.State
  {Tracked.Tracked.pid(History.expected(world,operation,player)) == P.Players.id(player) : U32}

def History.frame_pid(world,operation,player):
  match operation:
    case History.Tick{timer}: Tracked.Tracked.next_pid(U32.is_eq(S.Simulation.phase(S.Simulation.meta(T.Terrain.simulation(world))),1),player)
    case History.Command{now,kind,pid,score,plan}:
      +timed = Clock.WorldClock.set(world,now)
      +expected = Transition.Transition.expected(timed,kind,pid,player)
      %Transition.Transition.formula(timed,kind,pid,player) : {Tracked.Tracked.pid(_) == P.Players.id(player) : U32}
      Equal.trans(U32,Tracked.Tracked.pid(TC.TickCooldown.frame(expected)),P.Players.id(expected),P.Players.id(player),Tracked.Tracked.next_pid(False{},expected),Transition.Transition.expected_pid(timed,kind,pid,player))

law History.observed_pid:
  for +world: T.Terrain.World
  for +operation: History.Operation
  for +before: P.Players.State
  for +after: P.Players.State
  for +same: {TC.TickCooldown.frame(after) == History.expected(world,operation,before) : TC.TickCooldown.Frame}
  {P.Players.id(after) == P.Players.id(before) : U32}

def History.observed_pid(world,operation,before,after,same):
  %Tracked.Tracked.next_pid(False{},after) : {_ == P.Players.id(before) : U32}
  %History.frame_pid(world,operation,before) : {Tracked.Tracked.pid(TC.TickCooldown.frame(after)) == _ : U32}
  Equal.cong(TC.TickCooldown.Frame,U32,(frame => Tracked.Tracked.pid(frame)),TC.TickCooldown.frame(after),History.expected(world,operation,before),same)

type History.Entry is Data:
  History.Entry{before: T.Terrain.World,operation: History.Operation,after: T.Terrain.World}

type History.Run is Data:
  History.Run{world: T.Terrain.World,entries: List<&2,History.Entry>}

def History.world(run: History.Run) -> T.Terrain.World:
  match run:
    case History.Run{world,entries}: world

def History.entries(run: History.Run) -> List<&2,History.Entry>:
  match run:
    case History.Run{world,entries}: entries

def History.prepend(entry: History.Entry,+run: History.Run) -> History.Run: History.Run{History.world(run),Con{entry,History.entries(run)}}

def History.trace(requests: List<&1,History.Request>,+world: T.Terrain.World) -> History.Run:
  match requests:
    case Nil{}: History.Run{world,Nil{}}
    case Con{head,rest}:
      match head:
        case History.TickRequest{timer}:
          +operation = {History.Tick{timer} : History.Operation}
          +after = History.step(world,operation)
          History.prepend(History.Entry{world,operation,after},History.trace(rest,after))
        case History.CommandRequest{now,kind,pid,score,planner}:
          +now = now
          +kind = kind
          +pid = pid
          +score = score
          +plan = planner(L.LiveCombat.prepare(Clock.WorldClock.set(world,now),kind,pid,score))
          +operation = {History.Command{now,kind,pid,score,plan} : History.Operation}
          +after = History.step(world,operation)
          History.prepend(History.Entry{world,operation,after},History.trace(rest,after))

# Every blocked command by the tracked player has its actual inert result.
law History.rejected_taken:
  for +taken: P.Players.Take
  for +kind: C.Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  for +same: {P.Players.found(taken) == Some{player} : Maybe<&2,P.Players.State>}
  for +blocked: {C.Combat.blocked(kind,phase,player) == True{} : Bool}
  {C.Combat.apply_taken(taken,kind,phase) == C.Combat.Result{P.Players.restore(taken),None{}} : C.Combat.Result}

def History.rejected_taken(taken,kind,phase,player,same,blocked):
  match taken:
    case P.Players.Take{others,found}:
      %Equal.sym(Maybe<&2,P.Players.State>,found,Some{player},same) : {C.Combat.apply_taken(P.Players.Take{others,_},kind,phase) == C.Combat.Result{P.Players.restore(P.Players.Take{others,_}),None{}} : C.Combat.Result}
      %Equal.sym(C.Combat.Step,C.Combat.prepare(kind,phase,player),C.Combat.Step{player,False{}},C.Combat.reject(kind,phase,player,blocked)) : {C.Combat.finish(_,others) == C.Combat.Result{Con{player,others},None{}} : C.Combat.Result}
      {==}

law History.blocked_exact:
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +player: P.Players.State
  for +score: U32
  for +plan: L.LiveCombat.Plan
  for +inside: Member.Targeting.In<player,S.Simulation.players(T.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(world))>
  for +blocked: {C.Combat.blocked(kind,S.Simulation.phase(S.Simulation.meta(T.Terrain.simulation(world))),player) == True{} : Bool}
  {L.LiveCombat.at(world,kind,P.Players.id(player),score,plan) == Repeat.Repeat.quiet(world,P.Players.id(player)) : L.LiveCombat.Result}

def History.blocked_exact(world,kind,player,score,plan,inside,unique,blocked):
  match world:
    case T.Terrain.World{meta,players,monsters,maps}:
      +pid = P.Players.id(player)
      +rejected = History.rejected_taken(P.Players.take(players,pid),kind,S.Simulation.phase(meta),player,Repeat.Repeat.lookup_member(player,players,inside,Id.PlayerIds.from_admission(Id.PlayerIds.Player{},players,unique)),blocked)
      %Equal.sym(C.Combat.Result,C.Combat.run(players,pid,kind,S.Simulation.phase(meta)),C.Combat.Result{P.Players.restore(P.Players.take(players,pid)),None{}},rejected) : {L.LiveCombat.finish(L.LiveCombat.Ready{meta,monsters,maps,_,pid,score},plan) == Repeat.Repeat.quiet(T.Terrain.World{meta,players,monsters,maps},pid) : L.LiveCombat.Result}
      L.LiveCombat.finish_rejected(meta,P.Players.restore(P.Players.take(players,pid)),monsters,maps,pid,score,plan)

def History.Check(same: Bool,blocked: Bool,+world: T.Terrain.World,+result: L.LiveCombat.Result) -> Data:
  match same:
    case False{}: Unit
    case True{}:
      match blocked:
        case False{}: Unit
        case True{}: R.Rejected.Inert<world,result>

def History.Guard(+world: T.Terrain.World,operation: History.Operation,+player: P.Players.State) -> Data:
  match operation:
    case History.Tick{timer}: Unit
    case History.Command{now,kind,pid,score,plan}:
      +kind = kind
      +pid = pid
      +timed = Clock.WorldClock.set(world,now)
      History.Check(U32.is_eq(P.Players.id(player),pid),C.Combat.blocked(kind,S.Simulation.phase(S.Simulation.meta(T.Terrain.simulation(timed))),player),timed,L.LiveCombat.at(timed,kind,pid,score,plan))

law History.checked:
  for +same: Bool
  for +blocked: Bool
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for +plan: L.LiveCombat.Plan
  for +player: P.Players.State
  for +comparison: {U32.is_eq(P.Players.id(player),pid) == same : Bool}
  for +decision: {C.Combat.blocked(kind,S.Simulation.phase(S.Simulation.meta(T.Terrain.simulation(world))),player) == blocked : Bool}
  for +inside: Member.Targeting.In<player,S.Simulation.players(T.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(world))>
  History.Check(same,blocked,world,L.LiveCombat.at(world,kind,pid,score,plan))

def History.checked(same,blocked,world,kind,pid,score,plan,player,comparison,decision,inside,unique):
  match same:
    case False{}: Unit{}
    case True{}:
      match blocked:
        case False{}: Unit{}
        case True{}:
          %N.Numeric.u32_eq_sound(P.Players.id(player),pid,comparison) : R.Rejected.Inert<world,L.LiveCombat.at(world,kind,_,score,plan)>
          %Equal.sym(L.LiveCombat.Result,L.LiveCombat.at(world,kind,P.Players.id(player),score,plan),Repeat.Repeat.quiet(world,P.Players.id(player)),History.blocked_exact(world,kind,player,score,plan,inside,unique,decision)) : R.Rejected.Inert<world,_>
          R.Rejected.quiet_inert(world,P.Players.id(player))

law History.guard:
  for +world: T.Terrain.World
  for +operation: History.Operation
  for +player: P.Players.State
  for +inside: Member.Targeting.In<player,S.Simulation.players(T.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(world))>
  History.Guard(world,operation,player)

def History.guard(world,operation,player,inside,unique):
  match operation:
    case History.Tick{timer}: Unit{}
    case History.Command{now,kind,pid,score,plan}:
      +timed = Clock.WorldClock.set(world,now)
      History.checked(U32.is_eq(P.Players.id(player),pid),C.Combat.blocked(kind,S.Simulation.phase(S.Simulation.meta(T.Terrain.simulation(timed))),player),timed,kind,pid,score,plan,player,{==},{==},(%Equal.sym(List<&2,P.Players.State>,S.Simulation.players(T.Terrain.simulation(timed)),S.Simulation.players(T.Terrain.simulation(world)),CC.CombatClock.players(world,now)) : Member.Targeting.In<player,_>; inside),CC.CombatClock.unique(world,now,unique))

# Every step connects both actual full player records and both actual worlds.
# The terminal indices link the final witness to the last record in the history.
type History.Follow<-entries: List<&2,History.Entry>,-world: T.Terrain.World,-player: P.Players.State,-last_world: T.Terrain.World,-last_player: P.Players.State> is Data:
  History.Done{empty: {entries == Nil{} : List<&2,History.Entry>},world_same: {world == last_world : T.Terrain.World},player_same: {player == last_player : P.Players.State},inside: Member.Targeting.In<player,S.Simulation.players(T.Terrain.simulation(world))>}
  History.Step{operation: History.Operation,rest: List<&2,History.Entry>,shape: {entries == Con{History.Entry{world,operation,History.step(world,operation)},rest} : List<&2,History.Entry>},before_inside: Member.Targeting.In<player,S.Simulation.players(T.Terrain.simulation(world))>,after: P.Players.State,inside: Member.Targeting.In<after,S.Simulation.players(T.Terrain.simulation(History.step(world,operation)))>,same: {TC.TickCooldown.frame(after) == History.expected(world,operation,player) : TC.TickCooldown.Frame},guard: History.Guard(world,operation,player),tail: History.Follow<rest,History.step(world,operation),after,last_world,last_player>}

type History.OK<-run: History.Run,-before: T.Terrain.World,-player: P.Players.State> is Data:
  History.OK{world: T.Terrain.World,world_same: {world == History.world(run) : T.Terrain.World},entries: List<&2,History.Entry>,entries_same: {entries == History.entries(run) : List<&2,History.Entry>},after: P.Players.State,inside: Member.Targeting.In<after,S.Simulation.players(T.Terrain.simulation(world))>,unique: J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(world))>,follow: History.Follow<entries,before,player,world,after>,same_pid: {P.Players.id(after) == P.Players.id(player) : U32}}

law History.add:
  for +world: T.Terrain.World
  for +operation: History.Operation
  for +player: P.Players.State
  for +before_inside: Member.Targeting.In<player,S.Simulation.players(T.Terrain.simulation(world))>
  for +middle: P.Players.State
  for +inside: Member.Targeting.In<middle,S.Simulation.players(T.Terrain.simulation(History.step(world,operation)))>
  for +same: {TC.TickCooldown.frame(middle) == History.expected(world,operation,player) : TC.TickCooldown.Frame}
  for +guard: History.Guard(world,operation,player)
  for -run: History.Run
  for +valid: History.OK<run,History.step(world,operation),middle>
  History.OK<History.prepend(History.Entry{world,operation,History.step(world,operation)},run),world,player>

def History.add(world,operation,player,before_inside,middle,inside,same,guard,run,valid):
  match valid:
    case History.OK{last_world,world_same,entries,entries_same,last_player,last_inside,unique,follow,same_pid}:
      +entry = {History.Entry{world,operation,History.step(world,operation)} : History.Entry}
      History.OK{last_world,world_same,Con{entry,entries},(%entries_same : {Con{entry,entries} == Con{entry,_} : List<&2,History.Entry>}; {==}),last_player,last_inside,unique,History.Step{operation,entries,{==},before_inside,middle,inside,same,guard,follow},Equal.trans(U32,P.Players.id(last_player),P.Players.id(middle),P.Players.id(player),same_pid,History.observed_pid(world,operation,player,middle,same))}

law History.safe:
  for requests: List<&1,History.Request>
  for +world: T.Terrain.World
  for +player: P.Players.State
  for +inside: Member.Targeting.In<player,S.Simulation.players(T.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(world))>
  History.OK<History.trace(requests,world),world,player>

def History.safe(requests,world,player,inside,unique):
  match requests:
    case Nil{}: History.OK{world,{==},Nil{},{==},player,inside,unique,History.Done{{==},{==},{==},inside},{==}}
    case Con{head,rest}:
      match head:
        case History.TickRequest{timer}:
          +operation = {History.Tick{timer} : History.Operation}
          +after = History.step(world,operation)
          +next_unique = History.unique(world,operation,unique)
          Tracked.Tracked.eliminate(History.OK<History.prepend(History.Entry{world,operation,after},History.trace(rest,after)),world,player>,History.expected(world,operation,player),S.Simulation.players(T.Terrain.simulation(after)),History.observe(world,operation,player,inside,unique),(middle => (present => (same => History.add(world,operation,player,inside,middle,present,same,History.guard(world,operation,player,inside,unique),History.trace(rest,after),History.safe(rest,after,middle,present,next_unique))))))
        case History.CommandRequest{now,kind,pid,score,planner}:
          +now = now
          +kind = kind
          +pid = pid
          +score = score
          +plan = planner(L.LiveCombat.prepare(Clock.WorldClock.set(world,now),kind,pid,score))
          +operation = {History.Command{now,kind,pid,score,plan} : History.Operation}
          +after = History.step(world,operation)
          +next_unique = History.unique(world,operation,unique)
          Tracked.Tracked.eliminate(History.OK<History.prepend(History.Entry{world,operation,after},History.trace(rest,after)),world,player>,History.expected(world,operation,player),S.Simulation.players(T.Terrain.simulation(after)),History.observe(world,operation,player,inside,unique),(middle => (present => (same => History.add(world,operation,player,inside,middle,present,same,History.guard(world,operation,player,inside,unique),History.trace(rest,after),History.safe(rest,after,middle,present,next_unique))))))

def History.requests(requests: List<&1,History.Request>) -> Nat:
  match requests:
    case Nil{}: Zero{}
    case Con{head,rest}: Succ{History.requests(rest)}

def History.count(entries: List<&2,History.Entry>) -> Nat:
  match entries:
    case Nil{}: Zero{}
    case Con{head,rest}: Succ{History.count(rest)}

law History.length:
  for requests: List<&1,History.Request>
  for +world: T.Terrain.World
  {History.count(History.entries(History.trace(requests,world))) == History.requests(requests) : Nat}

def History.length(requests,world):
  match requests:
    case Nil{}: {==}
    case Con{head,rest}:
      match head:
        case History.TickRequest{timer}:
          +after = History.step(world,History.Tick{timer})
          %History.length(rest,after) : {Succ{History.count(History.entries(History.trace(rest,after)))} == Succ{_} : Nat}
          {==}
        case History.CommandRequest{now,kind,pid,score,planner}:
          +now = now
          +kind = kind
          +pid = pid
          +score = score
          +plan = planner(L.LiveCombat.prepare(Clock.WorldClock.set(world,now),kind,pid,score))
          +after = History.step(world,History.Command{now,kind,pid,score,plan})
          %History.length(rest,after) : {Succ{History.count(History.entries(History.trace(rest,after)))} == Succ{_} : Nat}
          {==}

# In addition to exact player histories, preserve full seeded-world validity.
law History.step_seeded:
  for +world: T.Terrain.World
  for +operation: History.Operation
  for +states: List<&2,Sess.Sessions.State>
  for +valid: SW.SeededWorld.OK<world,states>
  SW.SeededWorld.OK<History.step(world,operation),states>

def History.step_seeded(world,operation,states,valid):
  match operation:
    case History.Tick{timer}: Tick.LiveTick.seeded(world,timer,states,valid)
    case History.Command{now,kind,pid,score,plan}: L.LiveCombat.at_seeded(Clock.WorldClock.set(world,now),kind,pid,score,plan,states,Clock.WorldClock.seeded(world,now,states,valid))

law History.seeded:
  for requests: List<&1,History.Request>
  for +world: T.Terrain.World
  for +states: List<&2,Sess.Sessions.State>
  for +valid: SW.SeededWorld.OK<world,states>
  SW.SeededWorld.OK<History.world(History.trace(requests,world)),states>

def History.seeded(requests,world,states,valid):
  match requests:
    case Nil{}: valid
    case Con{head,rest}:
      match head:
        case History.TickRequest{timer}:
          +operation = {History.Tick{timer} : History.Operation}
          History.seeded(rest,History.step(world,operation),states,History.step_seeded(world,operation,states,valid))
        case History.CommandRequest{now,kind,pid,score,planner}:
          +now = now
          +kind = kind
          +pid = pid
          +score = score
          +plan = planner(L.LiveCombat.prepare(Clock.WorldClock.set(world,now),kind,pid,score))
          +operation = {History.Command{now,kind,pid,score,plan} : History.Operation}
          History.seeded(rest,History.step(world,operation),states,History.step_seeded(world,operation,states,valid))

type History.Lookup<-run: History.Run,-original: P.Players.State> is Data:
  History.Lookup{world: T.Terrain.World,same: {world == History.world(run) : T.Terrain.World},player: P.Players.State,found: {P.Players.found(P.Players.take(S.Simulation.players(T.Terrain.simulation(world)),P.Players.id(original))) == Some{player} : Maybe<&2,P.Players.State>}}

law History.lookup:
  for +original: P.Players.State
  for -run: History.Run
  for -before: T.Terrain.World
  for +valid: History.OK<run,before,original>
  History.Lookup<run,original>

def History.lookup(original,run,before,valid):
  match valid:
    case History.OK{world,world_same,entries,entries_same,player,inside,unique,follow,same_pid}: History.Lookup{world,world_same,player,(%same_pid : {P.Players.found(P.Players.take(S.Simulation.players(T.Terrain.simulation(world)),_)) == Some{player} : Maybe<&2,P.Players.State>}; Repeat.Repeat.lookup_member(player,S.Simulation.players(T.Terrain.simulation(world)),inside,Id.PlayerIds.from_admission(Id.PlayerIds.Player{},S.Simulation.players(T.Terrain.simulation(world)),unique)))}

law History.final_lookup:
  for requests: List<&1,History.Request>
  for +world: T.Terrain.World
  for +player: P.Players.State
  for +inside: Member.Targeting.In<player,S.Simulation.players(T.Terrain.simulation(world))>
  for +unique: J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(world))>
  History.Lookup<History.trace(requests,world),player>

def History.final_lookup(requests,world,player,inside,unique): History.lookup(player,History.trace(requests,world),world,History.safe(requests,world,player,inside,unique))
