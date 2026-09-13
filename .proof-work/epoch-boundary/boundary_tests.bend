
law boundary_arbitrary_observed:
  for +world: T.Terrain.World
  for +monster: M.Monsters.State
  for -entries: List<&2,History.History.Entry>
  for +follow: E.Epoch.Follow<entries,world,monster>
  EB.Boundary.OK<monster,EB.Boundary.point(entries,world,monster,follow)(world,monster)>
def boundary_arbitrary_observed(world,monster,entries,follow): EB.Boundary.observe(entries,world,monster,follow)(world,monster,{==},{==})

law boundary_arbitrary_lookup:
  for +world: T.Terrain.World
  for +monster: M.Monsters.State
  for -entries: List<&2,History.History.Entry>
  for +follow: E.Epoch.Follow<entries,world,monster>
  {R.Roster.found(R.Roster.take(S.Simulation.monsters(T.Terrain.simulation(EB.Boundary.world(EB.Boundary.point(entries,world,monster,follow)(world,monster)))),R.Roster.id(monster))) == Some{EB.Boundary.monster(EB.Boundary.point(entries,world,monster,follow)(world,monster))} : Maybe<&2,M.Monsters.State>}
def boundary_arbitrary_lookup(world,monster,entries,follow): EB.Boundary.lookup(monster,EB.Boundary.point(entries,world,monster,follow)(world,monster),EB.Boundary.observe(entries,world,monster,follow)(world,monster,{==},{==}))

law boundary_arbitrary_marker:
  for -entries: List<&2,History.History.Entry>
  for -world: T.Terrain.World
  for -monster: M.Monsters.State
  for +follow: E.Epoch.Follow<entries,world,monster>
  {EB.Boundary.born(EB.Boundary.point(entries,world,monster,follow)(world,monster)) == E.Epoch.reborn(entries,world,monster,follow) : Bool}
def boundary_arbitrary_marker(entries,world,monster,follow): EB.Boundary.marker(entries,world,monster,follow)

law boundary_arbitrary_prefix_end:
  for -entries: List<&2,History.History.Entry>
  for -world: T.Terrain.World
  for -monster: M.Monsters.State
  for +follow: E.Epoch.Follow<entries,world,monster>
  {EB.Boundary.world(EB.Boundary.point(entries,world,monster,follow)(world,monster)) == EB.Boundary.last(E.Epoch.prefix(entries,world,monster,follow)(world,monster),world) : T.Terrain.World}
def boundary_arbitrary_prefix_end(entries,world,monster,follow): EB.Boundary.prefix_end(entries,world,monster,follow)

law boundary_arbitrary_valid:
  for +world: T.Terrain.World
  for +monster: M.Monsters.State
  for -entries: List<&2,History.History.Entry>
  for +states: List<&2,Sess.Sessions.State>
  for +follow: E.Epoch.Follow<entries,world,monster>
  for +valid: SW.SeededWorld.OK<world,states>
  SW.SeededWorld.OK<EB.Boundary.world(EB.Boundary.point(entries,world,monster,follow)(world,monster)),states>
def boundary_arbitrary_valid(world,monster,entries,states,follow,valid): EB.Boundary.valid(entries,world,monster,states,follow)(world,monster,valid)

law boundary_arbitrary_report:
  for requests: List<&1,History.History.Request>
  for +world: T.Terrain.World
  for +monster: M.Monsters.State
  for +states: List<&2,Sess.Sessions.State>
  for +valid: SW.SeededWorld.OK<world,states>
  for +inside: Targets.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  EB.Boundary.Report<History.History.trace(requests,world),world,monster,states>
def boundary_arbitrary_report(requests,world,monster,states,valid,inside,dead): EB.Boundary.report(requests,world,monster,states,valid,inside,dead)

law boundary_arbitrary_report_lookup:
  for -run: History.History.Run
  for -world: T.Terrain.World
  for +monster: M.Monsters.State
  for -states: List<&2,Sess.Sessions.State>
  for +report: EB.Boundary.Report<run,world,monster,states>
  {R.Roster.found(R.Roster.take(S.Simulation.monsters(T.Terrain.simulation(EB.Boundary.world(EB.Boundary.result(run,world,monster,states,report)))),R.Roster.id(monster))) == Some{EB.Boundary.monster(EB.Boundary.result(run,world,monster,states,report))} : Maybe<&2,M.Monsters.State>}
def boundary_arbitrary_report_lookup(run,world,monster,states,report): EB.Boundary.report_lookup(run,world,monster,states,report)

law boundary_arbitrary_cut:
  for -run: History.History.Run
  for +world: T.Terrain.World
  for +monster: M.Monsters.State
  for -states: List<&2,Sess.Sessions.State>
  for +report: EB.Boundary.Report<run,world,monster,states>
  E.Epoch.Cut<run,world,monster>
def boundary_arbitrary_cut(run,world,monster,states,report): EB.Boundary.to_cut(run,world,monster,states,report)

def boundary_birth() -> EB.Boundary.State: EB.Boundary.point(History.History.entries(epoch_run),epoch_world,epoch_corpse(2),epoch_follow)(epoch_world,epoch_corpse(2))
def boundary_birth_ok() -> EB.Boundary.OK<epoch_corpse(2),boundary_birth>: EB.Boundary.observe(History.History.entries(epoch_run),epoch_world,epoch_corpse(2),epoch_follow)(epoch_world,epoch_corpse(2),{==},{==})

law boundary_real_birth_world:
  {EB.Boundary.world(boundary_birth) == epoch_w3 : T.Terrain.World}
def boundary_real_birth_world(): {==}

law boundary_real_birth_record:
  {EB.Boundary.monster(boundary_birth) == TL.TickLife.after(epoch_corpse(1),epoch_mode2) : M.Monsters.State}
def boundary_real_birth_record(): {==}

law boundary_real_birth_marker:
  {EB.Boundary.born(boundary_birth) == True{} : Bool}
def boundary_real_birth_marker(): EB.Boundary.marker(History.History.entries(epoch_run),epoch_world,epoch_corpse(2),epoch_follow)

law boundary_real_birth_lookup:
  {R.Roster.found(R.Roster.take(S.Simulation.monsters(T.Terrain.simulation(epoch_w3)),7)) == Some{TL.TickLife.after(epoch_corpse(1),epoch_mode2)} : Maybe<&2,M.Monsters.State>}
def boundary_real_birth_lookup(): EB.Boundary.lookup(epoch_corpse(2),boundary_birth,boundary_birth_ok)

law boundary_real_birth_alive:
  {V.Vitals.dead(M.Monsters.vitals(EB.Boundary.monster(boundary_birth))) == 0 : U32}
def boundary_real_birth_alive(): EB.Boundary.alive(epoch_corpse(2),boundary_birth,boundary_birth_ok,{==})

law boundary_real_birth_prefix:
  {EB.Boundary.world(boundary_birth) == EB.Boundary.last(epoch_prefix,epoch_world) : T.Terrain.World}
def boundary_real_birth_prefix(): EB.Boundary.prefix_end(History.History.entries(epoch_run),epoch_world,epoch_corpse(2),epoch_follow)

def boundary_found_dead(found: Maybe<&2,M.Monsters.State>) -> Maybe<&2,U32>:
  match found:
    case None{}: None{}
    case Some{monster}: Some{V.Vitals.dead(M.Monsters.vitals(monster))}

law boundary_later_final_dead:
  {boundary_found_dead(R.Roster.found(R.Roster.take(S.Simulation.monsters(T.Terrain.simulation(History.History.world(epoch_run))),7))) == Some{1} : Maybe<&2,U32>}
def boundary_later_final_dead(): {==}

def boundary_short() -> EB.Boundary.State: EB.Boundary.point(epoch_short_entries,epoch_world,epoch_corpse(2),epoch_short_follow)(epoch_world,epoch_corpse(2))
def boundary_short_ok() -> EB.Boundary.OK<epoch_corpse(2),boundary_short>: EB.Boundary.observe(epoch_short_entries,epoch_world,epoch_corpse(2),epoch_short_follow)(epoch_world,epoch_corpse(2),{==},{==})

law boundary_short_world:
  {EB.Boundary.world(boundary_short) == epoch_w1 : T.Terrain.World}
def boundary_short_world(): {==}

law boundary_short_record:
  {EB.Boundary.monster(boundary_short) == epoch_corpse(1) : M.Monsters.State}
def boundary_short_record(): {==}

law boundary_short_dead:
  {V.Vitals.dead(M.Monsters.vitals(EB.Boundary.monster(boundary_short))) == 1 : U32}
def boundary_short_dead(): EB.Boundary.dead(epoch_corpse(2),boundary_short,boundary_short_ok,{==})

law boundary_short_lookup:
  {R.Roster.found(R.Roster.take(S.Simulation.monsters(T.Terrain.simulation(epoch_w1)),7)) == Some{epoch_corpse(1)} : Maybe<&2,M.Monsters.State>}
def boundary_short_lookup(): EB.Boundary.lookup(epoch_corpse(2),boundary_short,boundary_short_ok)

def boundary_lifetime() -> EB.Boundary.State: EB.Boundary.point(History.History.entries(lifetime_run),attacked_world,dead_tracked,lifetime_follow)(attacked_world,dead_tracked)
def boundary_lifetime_ok() -> EB.Boundary.OK<dead_tracked,boundary_lifetime>: EB.Boundary.observe(History.History.entries(lifetime_run),attacked_world,dead_tracked,lifetime_follow)(attacked_world,dead_tracked,{==},{==})

law boundary_lifetime_world:
  {EB.Boundary.world(boundary_lifetime) == History.History.world(lifetime_run) : T.Terrain.World}
def boundary_lifetime_world(): {==}

law boundary_lifetime_record:
  {EB.Boundary.monster(boundary_lifetime) == tick_life_attack_after : M.Monsters.State}
def boundary_lifetime_record(): {==}

law boundary_lifetime_lookup:
  {R.Roster.found(R.Roster.take(S.Simulation.monsters(T.Terrain.simulation(History.History.world(lifetime_run))),7)) == Some{tick_life_attack_after} : Maybe<&2,M.Monsters.State>}
def boundary_lifetime_lookup(): EB.Boundary.lookup(dead_tracked,boundary_lifetime,boundary_lifetime_ok)

law boundary_lifetime_dead:
  {V.Vitals.dead(M.Monsters.vitals(EB.Boundary.monster(boundary_lifetime))) == 1 : U32}
def boundary_lifetime_dead(): EB.Boundary.dead(dead_tracked,boundary_lifetime,boundary_lifetime_ok,{==})
