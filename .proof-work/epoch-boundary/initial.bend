# Exact world and monster at a corpse lifetime's Done/Birth boundary.
import Base
import ./epoch_history.bend as E
import ./tick_life.bend as TL
import ./combat_history.bend as H
import ./live_combat.bend as L
import ./monsters.bend as M
import ./vitals.bend as V
import ./roster.bend as R
import ./identity.bend as I
import ./combat_targets.bend as Member
import ./terrain.bend as T
import ./simulation.bend as S
import ./seeded_world.bend as SW
import ./sessions.bend as Sess
import ./ai.bend as A

type Boundary.State is Data:
  Boundary.State{world: T.Terrain.World,monster: M.Monsters.State,born: Bool}

def Boundary.world(state: Boundary.State) -> T.Terrain.World:
  match state:
    case Boundary.State{world,monster,born}: world

def Boundary.monster(state: Boundary.State) -> M.Monsters.State:
  match state:
    case Boundary.State{world,monster,born}: monster

def Boundary.born(state: Boundary.State) -> Bool:
  match state:
    case Boundary.State{world,monster,born}: born

def Boundary.point(-entries: List<&2,H.History.Entry>,-world: T.Terrain.World,-monster: M.Monsters.State,follow: E.Epoch.Follow<entries,world,monster>) -> (@+start: T.Terrain.World -> @+current: M.Monsters.State -> Boundary.State):
  match follow:
    case E.Epoch.Done{empty,inside,unique,dead}: (start => (current => Boundary.State{start,current,False{}}))
    case E.Epoch.Birth{timer,rest,shape,zone,inside,dead,mode,chosen,tracked,born}:
      +timer = timer
      +mode = mode
      (start => (current => Boundary.State{H.History.step(start,H.History.Tick{timer}),TL.TickLife.after(current,mode),True{}}))
    case E.Epoch.Wait{timer,rest,shape,zone,inside,dead,mode,chosen,tracked,none,same_id,tail}:
      later = Boundary.point(rest,H.History.step(world,H.History.Tick{timer}),TL.TickLife.after(monster,mode),tail)
      +timer = timer
      +mode = mode
      (start => (current => later(H.History.step(start,H.History.Tick{timer}),TL.TickLife.after(current,mode))))
    case E.Epoch.Command{now,kind,pid,score,plan,rest,shape,dead,actual,same,safe,tail}:
      later = Boundary.point(rest,H.History.step(world,H.History.Command{now,kind,pid,score,plan}),monster,tail)
      +operation = {H.History.Command{now,kind,pid,score,plan} : H.History.Operation}
      (start => (current => later(H.History.step(start,operation),current)))

type Boundary.OK<-original: M.Monsters.State,-point: Boundary.State> is Data:
  Boundary.OK{inside: Member.Targets.In<Boundary.monster(point),S.Simulation.monsters(T.Terrain.simulation(Boundary.world(point)))>,unique: I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(Boundary.world(point)))),dead: {V.Vitals.dead(M.Monsters.vitals(Boundary.monster(point))) == Member.Targets.pick(Boundary.born(point),0,1) : U32},same_id: {R.Roster.id(Boundary.monster(point)) == R.Roster.id(original) : U32}}

law Boundary.previous:
  for -original: M.Monsters.State
  for -middle: M.Monsters.State
  for -point: Boundary.State
  for +same_id: {R.Roster.id(middle) == R.Roster.id(original) : U32}
  for +valid: Boundary.OK<middle,point>
  Boundary.OK<original,point>

def Boundary.previous(original,middle,point,same_id,valid):
  match valid:
    case Boundary.OK{inside,unique,dead,later_id}: Boundary.OK{inside,unique,dead,Equal.trans(U32,R.Roster.id(Boundary.monster(point)),R.Roster.id(middle),R.Roster.id(original),later_id,same_id)}

law Boundary.birth:
  for +world: T.Terrain.World
  for +timer: U32
  for +monster: M.Monsters.State
  for +mode: Maybe<&2,A.AI.Plan>
  for +tracked: TL.TickLife.Tracked<monster,mode,S.Simulation.monsters(T.Terrain.simulation(H.History.step(world,H.History.Tick{timer})))>
  for +born: {TL.TickLife.event(monster,mode) == True{} : Bool}
  Boundary.OK<monster,Boundary.State{H.History.step(world,H.History.Tick{timer}),TL.TickLife.after(monster,mode),True{}}>

def Boundary.birth(world,timer,monster,mode,tracked,born):
  match tracked:
    case TL.TickLife.Tracked{inside,key,dead,quiet,unique}: Boundary.OK{inside,unique,(%born : {V.Vitals.dead(M.Monsters.vitals(TL.TickLife.after(monster,mode))) == Member.Targets.pick(_,0,1) : U32}; dead),TL.TickLife.after_id(monster,mode)}

law Boundary.observe:
  for -entries: List<&2,H.History.Entry>
  for -world: T.Terrain.World
  for -monster: M.Monsters.State
  for +follow: E.Epoch.Follow<entries,world,monster>
  (@+start: T.Terrain.World -> @+current: M.Monsters.State -> @+world_same: {start == world : T.Terrain.World} -> @+monster_same: {current == monster : M.Monsters.State} -> Boundary.OK<current,Boundary.point(entries,world,monster,follow)(start,current)>)

def Boundary.observe(entries,world,monster,follow):
  match follow:
    case E.Epoch.Done{empty,inside,unique,dead}:
      (start => (current => (world_same => (monster_same =>
        (%Equal.sym(T.Terrain.World,start,world,world_same) : Boundary.OK<current,Boundary.State{_,current,False{}}>;
         %Equal.sym(M.Monsters.State,current,monster,monster_same) : Boundary.OK<_,Boundary.State{world,_,False{}}>;
         Boundary.OK{inside,unique,dead,{==}})))))
    case E.Epoch.Birth{timer,rest,shape,zone,inside,dead,mode,chosen,tracked,born}:
      +timer = timer
      +mode = mode
      (start => (current => (world_same => (monster_same =>
        Boundary.birth(start,timer,current,mode,(%Equal.sym(T.Terrain.World,start,world,world_same) : TL.TickLife.Tracked<current,mode,S.Simulation.monsters(T.Terrain.simulation(H.History.step(_,H.History.Tick{timer})))>; %Equal.sym(M.Monsters.State,current,monster,monster_same) : TL.TickLife.Tracked<_,mode,S.Simulation.monsters(T.Terrain.simulation(H.History.step(world,H.History.Tick{timer})))>; tracked),(%Equal.sym(M.Monsters.State,current,monster,monster_same) : {TL.TickLife.event(_,mode) == True{} : Bool}; born))))))
    case E.Epoch.Wait{timer,rest,shape,zone,inside,dead,mode,chosen,tracked,none,same_id,tail}:
      later = Boundary.observe(rest,H.History.step(world,H.History.Tick{timer}),TL.TickLife.after(monster,mode),tail)
      +timer = timer
      +mode = mode
      +tail = tail
      +rest = rest
      (start => (current => (world_same => (monster_same =>
        Boundary.previous(current,TL.TickLife.after(current,mode),Boundary.point(rest,H.History.step(world,H.History.Tick{timer}),TL.TickLife.after(monster,mode),tail)(H.History.step(start,H.History.Tick{timer}),TL.TickLife.after(current,mode)),TL.TickLife.after_id(current,mode),later(H.History.step(start,H.History.Tick{timer}),TL.TickLife.after(current,mode),Equal.cong(T.Terrain.World,T.Terrain.World,(w => H.History.step(w,H.History.Tick{timer})),start,world,world_same),Equal.cong(M.Monsters.State,M.Monsters.State,(m => TL.TickLife.after(m,mode)),current,monster,monster_same)))))))
    case E.Epoch.Command{now,kind,pid,score,plan,rest,shape,dead,actual,same,safe,tail}:
      later = Boundary.observe(rest,H.History.step(world,H.History.Command{now,kind,pid,score,plan}),monster,tail)
      +operation = {H.History.Command{now,kind,pid,score,plan} : H.History.Operation}
      (start => (current => (world_same => (monster_same => later(H.History.step(start,operation),current,Equal.cong(T.Terrain.World,T.Terrain.World,(w => H.History.step(w,operation)),start,world,world_same),monster_same)))))

law Boundary.marker:
  for -entries: List<&2,H.History.Entry>
  for -world: T.Terrain.World
  for -monster: M.Monsters.State
  for +follow: E.Epoch.Follow<entries,world,monster>
  {Boundary.born(Boundary.point(entries,world,monster,follow)(world,monster)) == E.Epoch.reborn(entries,world,monster,follow) : Bool}

def Boundary.marker(entries,world,monster,follow):
  match follow:
    case E.Epoch.Done{empty,inside,unique,dead}: {==}
    case E.Epoch.Birth{timer,rest,shape,zone,inside,dead,mode,chosen,tracked,born}: {==}
    case E.Epoch.Wait{timer,rest,shape,zone,inside,dead,mode,chosen,tracked,none,same_id,tail}: Boundary.marker(rest,H.History.step(world,H.History.Tick{timer}),TL.TickLife.after(monster,mode),tail)
    case E.Epoch.Command{now,kind,pid,score,plan,rest,shape,dead,actual,same,safe,tail}: Boundary.marker(rest,H.History.step(world,H.History.Command{now,kind,pid,score,plan}),monster,tail)

def Boundary.last(start: T.Terrain.World,entries: List<&2,H.History.Entry>) -> T.Terrain.World:
  match entries:
    case Nil{}: start
    case Con{head,rest}:
      match head:
        case H.History.Entry{before,operation,after}: Boundary.last(after,rest)

law Boundary.prefix_end:
  for -entries: List<&2,H.History.Entry>
  for -world: T.Terrain.World
  for -monster: M.Monsters.State
  for +follow: E.Epoch.Follow<entries,world,monster>
  {Boundary.world(Boundary.point(entries,world,monster,follow)(world,monster)) == Boundary.last(world,E.Epoch.prefix(entries,world,monster,follow)(world,monster)) : T.Terrain.World}

def Boundary.prefix_end(entries,world,monster,follow):
  match follow:
    case E.Epoch.Done{empty,inside,unique,dead}: {==}
    case E.Epoch.Birth{timer,rest,shape,zone,inside,dead,mode,chosen,tracked,born}: {==}
    case E.Epoch.Wait{timer,rest,shape,zone,inside,dead,mode,chosen,tracked,none,same_id,tail}: Boundary.prefix_end(rest,H.History.step(world,H.History.Tick{timer}),TL.TickLife.after(monster,mode),tail)
    case E.Epoch.Command{now,kind,pid,score,plan,rest,shape,dead,actual,same,safe,tail}: Boundary.prefix_end(rest,H.History.step(world,H.History.Command{now,kind,pid,score,plan}),monster,tail)

law Boundary.lookup:
  for +original: M.Monsters.State
  for +point: Boundary.State
  for +valid: Boundary.OK<original,point>
  {R.Roster.found(R.Roster.take(S.Simulation.monsters(T.Terrain.simulation(Boundary.world(point))),R.Roster.id(original))) == Some{Boundary.monster(point)} : Maybe<&2,M.Monsters.State>}

def Boundary.lookup(original,point,valid):
  match valid:
    case Boundary.OK{inside,unique,dead,same_id}:
      %same_id : {R.Roster.found(R.Roster.take(S.Simulation.monsters(T.Terrain.simulation(Boundary.world(point))),_)) == Some{Boundary.monster(point)} : Maybe<&2,M.Monsters.State>}
      Member.Targets.lookup_member(Boundary.monster(point),S.Simulation.monsters(T.Terrain.simulation(Boundary.world(point))),inside,unique)

law Boundary.alive:
  for -original: M.Monsters.State
  for +point: Boundary.State
  for +valid: Boundary.OK<original,point>
  for +born: {Boundary.born(point) == True{} : Bool}
  {V.Vitals.dead(M.Monsters.vitals(Boundary.monster(point))) == 0 : U32}

def Boundary.alive(original,point,valid,born):
  match valid:
    case Boundary.OK{inside,unique,dead,same_id}:
      %born : {V.Vitals.dead(M.Monsters.vitals(Boundary.monster(point))) == Member.Targets.pick(_,0,1) : U32}
      dead

law Boundary.dead:
  for -original: M.Monsters.State
  for +point: Boundary.State
  for +valid: Boundary.OK<original,point>
  for +none: {Boundary.born(point) == False{} : Bool}
  {V.Vitals.dead(M.Monsters.vitals(Boundary.monster(point))) == 1 : U32}

def Boundary.dead(original,point,valid,none):
  match valid:
    case Boundary.OK{inside,unique,dead,same_id}:
      %none : {V.Vitals.dead(M.Monsters.vitals(Boundary.monster(point))) == Member.Targets.pick(_,0,1) : U32}
      dead
