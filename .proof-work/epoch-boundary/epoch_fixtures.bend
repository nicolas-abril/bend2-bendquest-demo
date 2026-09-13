
law epoch_actual_record:
  for requests: List<&1,History.History.Request>
  for +world: T.Terrain.World
  E.Epoch.Record<History.History.trace(requests,world),world>
def epoch_actual_record(requests,world): E.Epoch.record(requests,world)

law epoch_actual_report:
  for requests: List<&1,History.History.Request>
  for +world: T.Terrain.World
  for +states: List<&2,Sess.Sessions.State>
  for +monster: M.Monsters.State
  for +valid: SW.SeededWorld.OK<world,states>
  for +inside: Targets.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  E.Epoch.Report<History.History.trace(requests,world),world,monster>
def epoch_actual_report(requests,world,states,monster,valid,inside,dead): E.Epoch.report(requests,world,states,monster,valid,inside,dead)

law epoch_actual_cut:
  for requests: List<&1,History.History.Request>
  for +world: T.Terrain.World
  for +states: List<&2,Sess.Sessions.State>
  for +monster: M.Monsters.State
  for +valid: SW.SeededWorld.OK<world,states>
  for +inside: Targets.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  E.Epoch.Cut<History.History.trace(requests,world),world,monster>
def epoch_actual_cut(requests,world,states,monster,valid,inside,dead): E.Epoch.cut(requests,world,states,monster,valid,inside,dead)

law epoch_arbitrary_split:
  for -entries: List<&2,History.History.Entry>
  for -world: T.Terrain.World
  for -monster: M.Monsters.State
  for +follow: E.Epoch.Follow<entries,world,monster>
  {entries == E.Epoch.concat(E.Epoch.prefix(entries,world,monster,follow)(world,monster),E.Epoch.remaining(entries,world,monster,follow)) : List<&2,History.History.Entry>}
def epoch_arbitrary_split(entries,world,monster,follow): E.Epoch.split(entries,world,monster,follow)

law epoch_arbitrary_zero:
  for +monster: M.Monsters.State
  for -entries: List<&2,History.History.Entry>
  for -world: T.Terrain.World
  for +follow: E.Epoch.Follow<entries,world,monster>
  {Dead.Dead.count(R.Roster.id(monster),PH.Permanent.notices(E.Epoch.prefix(entries,world,monster,follow)(world,monster))) == 0n : Nat}
def epoch_arbitrary_zero(monster,entries,world,follow): E.Epoch.zero(monster,entries,world,follow)

law epoch_arbitrary_exhausted:
  for -entries: List<&2,History.History.Entry>
  for -world: T.Terrain.World
  for -monster: M.Monsters.State
  for +follow: E.Epoch.Follow<entries,world,monster>
  for +none: {E.Epoch.reborn(entries,world,monster,follow) == False{} : Bool}
  {E.Epoch.remaining(entries,world,monster,follow) == Nil{} : List<&2,History.History.Entry>}
def epoch_arbitrary_exhausted(entries,world,monster,follow,none): E.Epoch.exhausted(entries,world,monster,follow,none)

def epoch_corpse(timer: U32) -> M.Monsters.State: M.Monsters.State{7,0,0,0,6,4,0,100,0,0,1,timer}
def epoch_world() -> T.Terrain.World: T.Terrain.World{S.Simulation.meta(fixture_state),[fixture_actor],[epoch_corpse(2)],Nil{}}
def epoch_w1() -> T.Terrain.World: History.History.step(epoch_world,History.History.Tick{2})
def epoch_command() -> History.History.Operation: History.History.Command{4294967295,Combat.Combat.Spin{},99,60,hostile_second(Fight.LiveCombat.prepare(Clock.WorldClock.set(epoch_w1,4294967295),Combat.Combat.Spin{},99,60))}
def epoch_w2() -> T.Terrain.World: History.History.step(epoch_w1,epoch_command)
def epoch_w3() -> T.Terrain.World: History.History.step(epoch_w2,History.History.Tick{2})
def epoch_large_plan(ready: Fight.LiveCombat.Ready) -> Fight.LiveCombat.Plan: Fight.LiveCombat.Plan{[Battle.Battle.Input{7,1000,Pay.Payout.Plan{9,25,0,0,99,0,4294967295,0,0,99,0}}],Fight.LiveCombat.Attack{0,6,4,1,7,1}}
def epoch_later_requests() -> List<&1,History.History.Request>: [History.History.CommandRequest{0,Combat.Combat.Attack{},1,60,epoch_large_plan}]
def epoch_requests() -> List<&1,History.History.Request>: [History.History.TickRequest{2},History.History.CommandRequest{4294967295,Combat.Combat.Spin{},99,60,hostile_second},History.History.TickRequest{2},History.History.CommandRequest{0,Combat.Combat.Attack{},1,60,epoch_large_plan}]
def epoch_run() -> History.History.Run: History.History.trace(epoch_requests,epoch_world)
def epoch_remaining() -> List<&2,History.History.Entry>: History.History.entries(History.History.trace(epoch_later_requests,epoch_w3))
def epoch_birth_entries() -> List<&2,History.History.Entry>: Con{History.History.Entry{epoch_w2,History.History.Tick{2},epoch_w3},epoch_remaining}
def epoch_command_entries() -> List<&2,History.History.Entry>: Con{History.History.Entry{epoch_w1,epoch_command,epoch_w2},epoch_birth_entries}
def epoch_in0() -> Targets.Targets.In<epoch_corpse(2),S.Simulation.monsters(T.Terrain.simulation(epoch_world))>: Targets.Targets.Here{Nil{},{==}}
def epoch_in1() -> Targets.Targets.In<epoch_corpse(1),S.Simulation.monsters(T.Terrain.simulation(epoch_w1))>: Targets.Targets.Here{Nil{},{==}}
def epoch_in2() -> Targets.Targets.In<epoch_corpse(1),S.Simulation.monsters(T.Terrain.simulation(epoch_w2))>: Targets.Targets.Here{Nil{},{==}}
def epoch_unique0() -> I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(epoch_world))): Tuple{Unit{},Unit{}}
def epoch_unique1() -> I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(epoch_w1))): Tuple{Unit{},Unit{}}
def epoch_unique2() -> I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(epoch_w2))): Tuple{Unit{},Unit{}}
def epoch_zones0() -> Z.Zones.All(S.Simulation.monsters(T.Terrain.simulation(epoch_world))): Tuple{Z.Zones.Hollow{{==}},Unit{}}
def epoch_zones2() -> Z.Zones.All(S.Simulation.monsters(T.Terrain.simulation(epoch_w2))): Tuple{Z.Zones.Hollow{{==}},Unit{}}
def epoch_mode2() -> Maybe<&2,AI.AI.Plan>: TL.TickLife.decision(epoch_w2,2,epoch_corpse(1),Z.Zones.Hollow{{==}},epoch_in2)

def epoch_birth() -> E.Epoch.Follow<epoch_birth_entries,epoch_w2,epoch_corpse(1)>:
  E.Epoch.Birth{2,epoch_remaining,{==},Z.Zones.Hollow{{==}},epoch_in2,{==},epoch_mode2,{==},TL.TickLife.run(epoch_w2,2,epoch_corpse(1),Z.Zones.Hollow{{==}},epoch_in2,{==},epoch_zones2,epoch_unique2),{==}}

def epoch_before_birth() -> E.Epoch.Follow<epoch_command_entries,epoch_w1,epoch_corpse(1)>:
  +plan = hostile_second(Fight.LiveCombat.prepare(Clock.WorldClock.set(epoch_w1,4294967295),Combat.Combat.Spin{},99,60))
  E.Epoch.Command{4294967295,Combat.Combat.Spin{},99,60,plan,epoch_birth_entries,{==},{==},Fight.LiveCombat.at(Clock.WorldClock.set(epoch_w1,4294967295),Combat.Combat.Spin{},99,60,plan),{==},LiveDead.LiveDead.timed_safe(epoch_w1,4294967295,Combat.Combat.Spin{},99,60,plan,epoch_corpse(1),epoch_in1,epoch_unique1,{==}),epoch_birth}

def epoch_follow() -> E.Epoch.Follow<History.History.entries(epoch_run),epoch_world,epoch_corpse(2)>:
  E.Epoch.Wait{2,epoch_command_entries,{==},Z.Zones.Hollow{{==}},epoch_in0,{==},Some{AI.AI.Rest{}},{==},TL.TickLife.run(epoch_world,2,epoch_corpse(2),Z.Zones.Hollow{{==}},epoch_in0,{==},epoch_zones0,epoch_unique0),{==},{==},epoch_before_birth}

def epoch_prefix() -> List<&2,History.History.Entry>: E.Epoch.prefix(History.History.entries(epoch_run),epoch_world,epoch_corpse(2),epoch_follow)(epoch_world,epoch_corpse(2))

law epoch_real_follow:
  E.Epoch.Follow<History.History.entries(epoch_run),epoch_world,epoch_corpse(2)>
def epoch_real_follow(): epoch_follow

law epoch_real_cut:
  E.Epoch.Cut<epoch_run,epoch_world,epoch_corpse(2)>
def epoch_real_cut(): E.Epoch.cut_from(epoch_run,epoch_world,epoch_corpse(2),E.Epoch.Report{epoch_run,{==},epoch_follow})

law epoch_waits_first:
  {S.Simulation.monsters(T.Terrain.simulation(epoch_w1)) == [epoch_corpse(1)] : List<&2,M.Monsters.State>}
def epoch_waits_first(): {==}

law epoch_birth_marker:
  {E.Epoch.reborn(History.History.entries(epoch_run),epoch_world,epoch_corpse(2),epoch_follow) == True{} : Bool}
def epoch_birth_marker(): {==}

law epoch_prefix_length:
  {History.History.count(epoch_prefix) == 3n : Nat}
def epoch_prefix_length(): {==}

law epoch_retained_suffix:
  {E.Epoch.remaining(History.History.entries(epoch_run),epoch_world,epoch_corpse(2),epoch_follow) == epoch_remaining : List<&2,History.History.Entry>}
def epoch_retained_suffix(): {==}

law epoch_retained_length:
  {History.History.count(epoch_remaining) == 1n : Nat}
def epoch_retained_length(): History.History.length(epoch_later_requests,epoch_w3)

law epoch_real_zero:
  {Dead.Dead.count(7,PH.Permanent.notices(epoch_prefix)) == 0n : Nat}
def epoch_real_zero(): E.Epoch.zero(epoch_corpse(2),History.History.entries(epoch_run),epoch_world,epoch_follow)

law epoch_real_split:
  {History.History.entries(epoch_run) == E.Epoch.concat(epoch_prefix,epoch_remaining) : List<&2,History.History.Entry>}
def epoch_real_split(): E.Epoch.split(History.History.entries(epoch_run),epoch_world,epoch_corpse(2),epoch_follow)

law epoch_later_reward:
  {Dead.Dead.count(7,PH.Permanent.notices(epoch_remaining)) == 1n : Nat}
def epoch_later_reward(): {==}

law epoch_full_history_reward:
  {Dead.Dead.count(7,PH.Permanent.notices(History.History.entries(epoch_run))) == 1n : Nat}
def epoch_full_history_reward(): {==}
