
law lifetime_arbitrary_prefix:
  for -run: History.History.Run
  for -world: T.Terrain.World
  for -monster: M.Monsters.State
  for +cut: E.Epoch.Cut<run,world,monster>
  for +none: {LT.Lifetime.born(run,world,monster,cut) == False{} : Bool}
  {History.History.entries(run) == LT.Lifetime.prefix(run,world,monster,cut) : List<&2,History.History.Entry>}
def lifetime_arbitrary_prefix(run,world,monster,cut,none): LT.Lifetime.full_prefix(run,world,monster,cut,none)

law lifetime_arbitrary_zero:
  for +monster: M.Monsters.State
  for -run: History.History.Run
  for -world: T.Terrain.World
  for +cut: E.Epoch.Cut<run,world,monster>
  for +none: {LT.Lifetime.born(run,world,monster,cut) == False{} : Bool}
  {Dead.Dead.count(R.Roster.id(monster),PH.Permanent.notices(History.History.entries(run))) == 0n : Nat}
def lifetime_arbitrary_zero(monster,run,world,cut,none): LT.Lifetime.full_zero(monster,run,world,cut,none)

law lifetime_arbitrary_after:
  for requests: List<&1,History.History.Request>
  for +monster: M.Monsters.State
  for +damage: U32
  for +first: Fight.LiveCombat.Result
  for +states: List<&2,Sess.Sessions.State>
  for +certificate: Once.Once.Certificate<monster,damage,AO.AttackOnce.view(first)>
  for +valid: SW.SeededWorld.OK<Fight.LiveCombat.world(first),states>
  LT.Lifetime.Certificate<monster,damage,first,History.History.trace(requests,Fight.LiveCombat.world(first))>
def lifetime_arbitrary_after(requests,monster,damage,first,states,certificate,valid): LT.Lifetime.after_once(requests,monster,damage,first,states,certificate,valid)

law lifetime_arbitrary_at:
  for requests: List<&1,History.History.Request>
  for +world: T.Terrain.World
  for +kind: Combat.Combat.Kind
  for +pid: U32
  for +score: U32
  for +plan: Fight.LiveCombat.Plan
  for +monster: M.Monsters.State
  for +damage: U32
  for +states: List<&2,Sess.Sessions.State>
  for +valid: SW.SeededWorld.OK<world,states>
  for +certificate: Once.Once.Certificate<monster,damage,AO.AttackOnce.view(Fight.LiveCombat.at(world,kind,pid,score,plan))>
  LT.Lifetime.Certificate<monster,damage,Fight.LiveCombat.at(world,kind,pid,score,plan),History.History.trace(requests,Fight.LiveCombat.world(Fight.LiveCombat.at(world,kind,pid,score,plan)))>
def lifetime_arbitrary_at(requests,world,kind,pid,score,plan,monster,damage,states,valid,certificate): LT.Lifetime.at(requests,world,kind,pid,score,plan,monster,damage,states,valid,certificate)

law lifetime_arbitrary_run:
  for requests: List<&1,History.History.Request>
  for +world: T.Terrain.World
  for +kind: Combat.Combat.Kind
  for +pid: U32
  for +score: U32
  for planner: Fight.LiveCombat.Ready -> Fight.LiveCombat.Plan
  for +monster: M.Monsters.State
  for +damage: U32
  for +states: List<&2,Sess.Sessions.State>
  for +valid: SW.SeededWorld.OK<world,states>
  for +certificate: Once.Once.Certificate<monster,damage,AO.AttackOnce.view(Fight.LiveCombat.run(world,kind,pid,score,planner))>
  LT.Lifetime.Certificate<monster,damage,Fight.LiveCombat.run(world,kind,pid,score,planner),History.History.trace(requests,Fight.LiveCombat.world(Fight.LiveCombat.run(world,kind,pid,score,planner)))>
def lifetime_arbitrary_run(requests,world,kind,pid,score,planner,monster,damage,states,valid,certificate): LT.Lifetime.run(requests,world,kind,pid,score,planner,monster,damage,states,valid,certificate)

law lifetime_arbitrary_once:
  for +monster: M.Monsters.State
  for +damage: U32
  for +first: Fight.LiveCombat.Result
  for -run: History.History.Run
  for +certificate: LT.Lifetime.Certificate<monster,damage,first,run>
  {Dead.Dead.count(R.Roster.id(monster),Battle.Battle.concat(Fight.LiveCombat.notices(first),PH.Permanent.notices(LT.Lifetime.prefix(run,Fight.LiveCombat.world(first),Once.Once.after(monster,damage),LT.Lifetime.cut(monster,damage,first,run,certificate))))) == 1n : Nat}
def lifetime_arbitrary_once(monster,damage,first,run,certificate): LT.Lifetime.exactly_once(monster,damage,first,run,certificate)

law lifetime_arbitrary_full:
  for +monster: M.Monsters.State
  for +damage: U32
  for +first: Fight.LiveCombat.Result
  for -run: History.History.Run
  for +certificate: LT.Lifetime.Certificate<monster,damage,first,run>
  for +none: {LT.Lifetime.born(run,Fight.LiveCombat.world(first),Once.Once.after(monster,damage),LT.Lifetime.cut(monster,damage,first,run,certificate)) == False{} : Bool}
  {Dead.Dead.count(R.Roster.id(monster),Battle.Battle.concat(Fight.LiveCombat.notices(first),PH.Permanent.notices(History.History.entries(run)))) == 1n : Nat}
def lifetime_arbitrary_full(monster,damage,first,run,certificate,none): LT.Lifetime.full_once(monster,damage,first,run,certificate,none)

def lifetime_first() -> Fight.LiveCombat.Result: Fight.LiveCombat.run(repeat_world,Combat.Combat.Attack{},1,60,first_attack)
def lifetime_first_once() -> Once.Once.Certificate<minor,1,AO.AttackOnce.view(lifetime_first)>: Once.Once.Certificate{dead_inside,dead_unique,{==},{==}}

def lifetime_tick_member(-monster: M.Monsters.State,-mode: Maybe<&2,AI.AI.Plan>,-monsters: List<&2,M.Monsters.State>,tracked: TL.TickLife.Tracked<monster,mode,monsters>) -> Targets.Targets.In<TL.TickLife.after(monster,mode),monsters>:
  match tracked:
    case TL.TickLife.Tracked{inside,key,dead,quiet,unique}: inside

def lifetime_tick_unique(-monster: M.Monsters.State,-mode: Maybe<&2,AI.AI.Plan>,-monsters: List<&2,M.Monsters.State>,tracked: TL.TickLife.Tracked<monster,mode,monsters>) -> I.Identity.Monsters(monsters):
  match tracked:
    case TL.TickLife.Tracked{inside,key,dead,quiet,unique}: unique

def lifetime_plan() -> Fight.LiveCombat.Plan: large_spin(Fight.LiveCombat.prepare(Clock.WorldClock.set(tick_life_attack_world,4294967295),Combat.Combat.Spin{},2,60))
def lifetime_second() -> Fight.LiveCombat.Result: Fight.LiveCombat.at(Clock.WorldClock.set(tick_life_attack_world,4294967295),Combat.Combat.Spin{},2,60,lifetime_plan)
def lifetime_operation() -> History.History.Operation: History.History.Command{4294967295,Combat.Combat.Spin{},2,60,lifetime_plan}
def lifetime_requests() -> List<&1,History.History.Request>: [History.History.TickRequest{2},History.History.CommandRequest{4294967295,Combat.Combat.Spin{},2,60,large_spin}]
def lifetime_run() -> History.History.Run: History.History.trace(lifetime_requests,attacked_world)
def lifetime_command_entries() -> List<&2,History.History.Entry>: [History.History.Entry{tick_life_attack_world,lifetime_operation,Fight.LiveCombat.world(lifetime_second)}]
def lifetime_safe() -> LiveDead.LiveDead.Safe<tick_life_attack_after,lifetime_second>:
  LiveDead.LiveDead.timed_safe(tick_life_attack_world,4294967295,Combat.Combat.Spin{},2,60,lifetime_plan,tick_life_attack_after,lifetime_tick_member(dead_tracked,Some{AI.AI.Rest{}},S.Simulation.monsters(T.Terrain.simulation(tick_life_attack_world)),tick_life_attack_tracked),lifetime_tick_unique(dead_tracked,Some{AI.AI.Rest{}},S.Simulation.monsters(T.Terrain.simulation(tick_life_attack_world)),tick_life_attack_tracked),{==})

def lifetime_done(-result: Fight.LiveCombat.Result,-monster: M.Monsters.State,dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32},safe: LiveDead.LiveDead.Safe<monster,result>) -> E.Epoch.Follow<Nil{},Fight.LiveCombat.world(result),monster>:
  match safe:
    case LiveDead.LiveDead.Safe{inside,unique,clear}: E.Epoch.Done{{==},inside,unique,dead}

def lifetime_command_follow() -> E.Epoch.Follow<lifetime_command_entries,tick_life_attack_world,tick_life_attack_after>:
  E.Epoch.Command{4294967295,Combat.Combat.Spin{},2,60,lifetime_plan,Nil{},{==},{==},lifetime_second,{==},lifetime_safe,lifetime_done(lifetime_second,tick_life_attack_after,{==},lifetime_safe)}

def lifetime_follow() -> E.Epoch.Follow<History.History.entries(lifetime_run),attacked_world,dead_tracked>:
  E.Epoch.Wait{2,lifetime_command_entries,{==},Z.Zones.Hollow{{==}},dead_inside,{==},Some{AI.AI.Rest{}},{==},tick_life_attack_tracked,{==},{==},lifetime_command_follow}

def lifetime_cut() -> E.Epoch.Cut<lifetime_run,attacked_world,dead_tracked>: E.Epoch.cut_from(lifetime_run,attacked_world,dead_tracked,E.Epoch.Report{lifetime_run,{==},lifetime_follow})
def lifetime_certificate() -> LT.Lifetime.Certificate<minor,1,lifetime_first,lifetime_run>: LT.Lifetime.compose(minor,1,lifetime_first,lifetime_run,{==},lifetime_cut)

law lifetime_real_lethal:
  Once.Once.Certificate<minor,1,AO.AttackOnce.view(lifetime_first)>
def lifetime_real_lethal(): lifetime_first_once

law lifetime_real_certificate:
  LT.Lifetime.Certificate<minor,1,lifetime_first,lifetime_run>
def lifetime_real_certificate(): lifetime_certificate

law lifetime_real_none:
  {LT.Lifetime.born(lifetime_run,attacked_world,dead_tracked,lifetime_cut) == False{} : Bool}
def lifetime_real_none(): {==}

law lifetime_real_prefix:
  {History.History.entries(lifetime_run) == LT.Lifetime.prefix(lifetime_run,attacked_world,dead_tracked,lifetime_cut) : List<&2,History.History.Entry>}
def lifetime_real_prefix(): LT.Lifetime.full_prefix(lifetime_run,attacked_world,dead_tracked,lifetime_cut,{==})

law lifetime_real_zero:
  {Dead.Dead.count(7,PH.Permanent.notices(History.History.entries(lifetime_run))) == 0n : Nat}
def lifetime_real_zero(): LT.Lifetime.full_zero(dead_tracked,lifetime_run,attacked_world,lifetime_cut,{==})

law lifetime_real_once:
  {Dead.Dead.count(7,Battle.Battle.concat(Fight.LiveCombat.notices(lifetime_first),PH.Permanent.notices(LT.Lifetime.prefix(lifetime_run,attacked_world,dead_tracked,LT.Lifetime.cut(minor,1,lifetime_first,lifetime_run,lifetime_certificate))))) == 1n : Nat}
def lifetime_real_once(): LT.Lifetime.exactly_once(minor,1,lifetime_first,lifetime_run,lifetime_certificate)

law lifetime_real_full_once:
  {Dead.Dead.count(7,Battle.Battle.concat(Fight.LiveCombat.notices(lifetime_first),PH.Permanent.notices(History.History.entries(lifetime_run)))) == 1n : Nat}
def lifetime_real_full_once(): LT.Lifetime.full_once(minor,1,lifetime_first,lifetime_run,lifetime_certificate,{==})

law lifetime_other_reward:
  {Dead.Dead.count(8,Battle.Battle.concat(Fight.LiveCombat.notices(lifetime_first),PH.Permanent.notices(History.History.entries(lifetime_run)))) == 1n : Nat}
def lifetime_other_reward(): {==}

law lifetime_full_notice_count:
  {Battle.Battle.notice_count(Battle.Battle.concat(Fight.LiveCombat.notices(lifetime_first),PH.Permanent.notices(History.History.entries(lifetime_run)))) == 2n : Nat}
def lifetime_full_notice_count(): {==}

law lifetime_after_timer:
  {R.Roster.found(R.Roster.take(S.Simulation.monsters(T.Terrain.simulation(History.History.world(lifetime_run))),7)) == Some{tick_life_attack_after} : Maybe<&2,M.Monsters.State>}
def lifetime_after_timer(): {==}

law lifetime_previous_birth:
  {LT.Lifetime.born(epoch_run,epoch_world,epoch_corpse(2),epoch_real_cut) == True{} : Bool}
def lifetime_previous_birth(): {==}

law lifetime_before_birth_zero:
  {Dead.Dead.count(7,PH.Permanent.notices(LT.Lifetime.prefix(epoch_run,epoch_world,epoch_corpse(2),epoch_real_cut))) == 0n : Nat}
def lifetime_before_birth_zero(): LT.Lifetime.prefix_zero(epoch_corpse(2),epoch_run,epoch_world,epoch_real_cut)
