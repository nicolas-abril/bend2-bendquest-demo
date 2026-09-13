
law Boundary.valid:
  for -entries: List<&2,H.History.Entry>
  for -world: T.Terrain.World
  for -monster: M.Monsters.State
  for +states: List<&2,Sess.Sessions.State>
  for +follow: E.Epoch.Follow<entries,world,monster>
  (@+start: T.Terrain.World -> @+current: M.Monsters.State -> @+valid: SW.SeededWorld.OK<start,states> -> SW.SeededWorld.OK<Boundary.world(Boundary.point(entries,world,monster,follow)(start,current)),states>)

def Boundary.valid(entries,world,monster,states,follow):
  match follow:
    case E.Epoch.Done{empty,inside,unique,dead}: (start => (current => (valid => valid)))
    case E.Epoch.Birth{timer,rest,shape,zone,inside,dead,mode,chosen,tracked,born}:
      +timer = timer
      (start => (current => (valid => H.History.step_seeded(start,H.History.Tick{timer},states,valid))))
    case E.Epoch.Wait{timer,rest,shape,zone,inside,dead,mode,chosen,tracked,none,same_id,tail}:
      later = Boundary.valid(rest,H.History.step(world,H.History.Tick{timer}),TL.TickLife.after(monster,mode),states,tail)
      +timer = timer
      +mode = mode
      (start => (current => (valid => later(H.History.step(start,H.History.Tick{timer}),TL.TickLife.after(current,mode),H.History.step_seeded(start,H.History.Tick{timer},states,valid)))))
    case E.Epoch.Command{now,kind,pid,score,plan,rest,shape,dead,actual,same,safe,tail}:
      later = Boundary.valid(rest,H.History.step(world,H.History.Command{now,kind,pid,score,plan}),monster,states,tail)
      +operation = {H.History.Command{now,kind,pid,score,plan} : H.History.Operation}
      (start => (current => (valid => later(H.History.step(start,operation),current,H.History.step_seeded(start,operation,states,valid)))))

# Keep the full Path, including the entries after respawn, for later composition.
type Boundary.Report<-run: H.History.Run,-world: T.Terrain.World,-monster: M.Monsters.State,-states: List<&2,Sess.Sessions.State>> is Data:
  Boundary.Report{actual: H.History.Run,same: {actual == run : H.History.Run},path: E.Epoch.Path<H.History.entries(actual),world,H.History.world(actual)>,follow: E.Epoch.Follow<H.History.entries(actual),world,monster>,point: Boundary.State,point_same: {point == Boundary.point(H.History.entries(actual),world,monster,follow)(world,monster) : Boundary.State},observed: Boundary.OK<monster,point>,valid: SW.SeededWorld.OK<Boundary.world(point),states>,prefix_end: {Boundary.world(point) == Boundary.last(E.Epoch.prefix(H.History.entries(actual),world,monster,follow)(world,monster),world) : T.Terrain.World}}

law Boundary.from_record:
  for -run: H.History.Run
  for +world: T.Terrain.World
  for +monster: M.Monsters.State
  for +states: List<&2,Sess.Sessions.State>
  for +record: E.Epoch.Record<run,world>
  for +valid: SW.SeededWorld.OK<world,states>
  for +inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  Boundary.Report<run,world,monster,states>

def Boundary.from_record(run,world,monster,states,record,valid,inside,dead):
  match record:
    case E.Epoch.Record{actual,same,path}:
      +follow = E.Epoch.follow(H.History.entries(actual),world,H.History.world(actual),states,path,valid)(monster,inside,dead)
      +point = Boundary.point(H.History.entries(actual),world,monster,follow)(world,monster)
      Boundary.Report{actual,same,path,follow,point,{==},Boundary.observe(H.History.entries(actual),world,monster,follow)(world,monster,{==},{==}),Boundary.valid(H.History.entries(actual),world,monster,states,follow)(world,monster,valid),Boundary.prefix_end(H.History.entries(actual),world,monster,follow)}

law Boundary.report:
  for requests: List<&1,H.History.Request>
  for +world: T.Terrain.World
  for +monster: M.Monsters.State
  for +states: List<&2,Sess.Sessions.State>
  for +valid: SW.SeededWorld.OK<world,states>
  for +inside: Member.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  Boundary.Report<H.History.trace(requests,world),world,monster,states>

def Boundary.report(requests,world,monster,states,valid,inside,dead):
  Boundary.from_record(H.History.trace(requests,world),world,monster,states,E.Epoch.record(requests,world),valid,inside,dead)

def Boundary.result(-run: H.History.Run,-world: T.Terrain.World,-monster: M.Monsters.State,-states: List<&2,Sess.Sessions.State>,report: Boundary.Report<run,world,monster,states>) -> Boundary.State:
  match report:
    case Boundary.Report{actual,same,path,follow,point,point_same,observed,valid,prefix_end}: point

law Boundary.report_lookup:
  for -run: H.History.Run
  for -world: T.Terrain.World
  for +monster: M.Monsters.State
  for -states: List<&2,Sess.Sessions.State>
  for +report: Boundary.Report<run,world,monster,states>
  {R.Roster.found(R.Roster.take(S.Simulation.monsters(T.Terrain.simulation(Boundary.world(Boundary.result(run,world,monster,states,report)))),R.Roster.id(monster))) == Some{Boundary.monster(Boundary.result(run,world,monster,states,report))} : Maybe<&2,M.Monsters.State>}

def Boundary.report_lookup(run,world,monster,states,report):
  match report:
    case Boundary.Report{actual,same,path,follow,point,point_same,observed,valid,prefix_end}: Boundary.lookup(monster,point,observed)

law Boundary.to_cut:
  for -run: H.History.Run
  for +world: T.Terrain.World
  for +monster: M.Monsters.State
  for -states: List<&2,Sess.Sessions.State>
  for +report: Boundary.Report<run,world,monster,states>
  E.Epoch.Cut<run,world,monster>

def Boundary.to_cut(run,world,monster,states,report):
  match report:
    case Boundary.Report{actual,same,path,follow,point,point_same,observed,valid,prefix_end}: E.Epoch.cut_from(run,world,monster,E.Epoch.Report{actual,same,follow})
