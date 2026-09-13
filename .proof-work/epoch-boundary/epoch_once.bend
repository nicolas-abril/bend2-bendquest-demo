# Exactly one lethal reward through the actual dead lifetime, up to respawn.
import Base
import ./epoch_history.bend as E
import ./permanent_history.bend as PH
import ./reward_once.bend as Once
import ./attack_once.bend as AO
import ./live_dead.bend as LD
import ./dead_rewards.bend as Dead
import ./combat_history.bend as H
import ./live_combat.bend as L
import ./combat.bend as C
import ./battle.bend as B
import ./monsters.bend as M
import ./roster.bend as R
import ./terrain.bend as T
import ./seeded_world.bend as SW
import ./sessions.bend as Sess

def Lifetime.prefix(-run: H.History.Run,-world: T.Terrain.World,-monster: M.Monsters.State,cut: E.Epoch.Cut<run,world,monster>) -> List<&2,H.History.Entry>:
  match cut:
    case E.Epoch.Cut{actual,same,follow,prefix,prefix_same,remaining,remaining_same,split,zero}: prefix

def Lifetime.born(-run: H.History.Run,-world: T.Terrain.World,-monster: M.Monsters.State,cut: E.Epoch.Cut<run,world,monster>) -> Bool:
  match cut:
    case E.Epoch.Cut{actual,same,follow,prefix,prefix_same,remaining,remaining_same,split,zero}: E.Epoch.reborn(H.History.entries(actual),world,monster,follow)

law Lifetime.concat_nil:
  for +entries: List<&2,H.History.Entry>
  {E.Epoch.concat(entries,Nil{}) == entries : List<&2,H.History.Entry>}

def Lifetime.concat_nil(entries):
  match entries:
    case Nil{}: {==}
    case Con{head,rest}:
      %Lifetime.concat_nil(rest) : {Con{head,E.Epoch.concat(rest,Nil{})} == Con{head,_} : List<&2,H.History.Entry>}
      {==}

law Lifetime.full_prefix:
  for -run: H.History.Run
  for -world: T.Terrain.World
  for -monster: M.Monsters.State
  for +cut: E.Epoch.Cut<run,world,monster>
  for +none: {Lifetime.born(run,world,monster,cut) == False{} : Bool}
  {H.History.entries(run) == Lifetime.prefix(run,world,monster,cut) : List<&2,H.History.Entry>}

def Lifetime.full_prefix(run,world,monster,cut,none):
  match cut:
    case E.Epoch.Cut{actual,same,follow,prefix,prefix_same,remaining,remaining_same,split,zero}:
      +empty = Equal.trans(List<&2,H.History.Entry>,remaining,E.Epoch.remaining(H.History.entries(actual),world,monster,follow),Nil{},remaining_same,E.Epoch.exhausted(H.History.entries(actual),world,monster,follow,none))
      %same : {H.History.entries(_) == prefix : List<&2,H.History.Entry>}
      Equal.trans(List<&2,H.History.Entry>,H.History.entries(actual),E.Epoch.concat(prefix,remaining),prefix,split,(%Equal.sym(List<&2,H.History.Entry>,remaining,Nil{},empty) : {E.Epoch.concat(prefix,_) == prefix : List<&2,H.History.Entry>}; Lifetime.concat_nil(prefix)))

law Lifetime.prefix_zero:
  for +monster: M.Monsters.State
  for -run: H.History.Run
  for -world: T.Terrain.World
  for +cut: E.Epoch.Cut<run,world,monster>
  {Dead.Dead.count(R.Roster.id(monster),PH.Permanent.notices(Lifetime.prefix(run,world,monster,cut))) == 0n : Nat}

def Lifetime.prefix_zero(monster,run,world,cut):
  match cut:
    case E.Epoch.Cut{actual,same,follow,prefix,prefix_same,remaining,remaining_same,split,zero}: zero

law Lifetime.full_zero:
  for +monster: M.Monsters.State
  for -run: H.History.Run
  for -world: T.Terrain.World
  for +cut: E.Epoch.Cut<run,world,monster>
  for +none: {Lifetime.born(run,world,monster,cut) == False{} : Bool}
  {Dead.Dead.count(R.Roster.id(monster),PH.Permanent.notices(H.History.entries(run))) == 0n : Nat}

def Lifetime.full_zero(monster,run,world,cut,none):
  %Equal.sym(List<&2,H.History.Entry>,H.History.entries(run),Lifetime.prefix(run,world,monster,cut),Lifetime.full_prefix(run,world,monster,cut,none)) : {Dead.Dead.count(R.Roster.id(monster),PH.Permanent.notices(_)) == 0n : Nat}
  Lifetime.prefix_zero(monster,run,world,cut)

# The Cut retains the entire actual mixed run and its exact lifetime boundary.
type Lifetime.Certificate<-monster: M.Monsters.State,-damage: U32,-first: L.LiveCombat.Result,-run: H.History.Run> is Data:
  Lifetime.Certificate{cut: E.Epoch.Cut<run,L.LiveCombat.world(first),Once.Once.after(monster,damage)>,one: {Dead.Dead.count(R.Roster.id(monster),B.Battle.concat(L.LiveCombat.notices(first),PH.Permanent.notices(Lifetime.prefix(run,L.LiveCombat.world(first),Once.Once.after(monster,damage),cut)))) == 1n : Nat}}

law Lifetime.compose:
  for +monster: M.Monsters.State
  for +damage: U32
  for +first: L.LiveCombat.Result
  for -run: H.History.Run
  for +one: {Dead.Dead.count(R.Roster.id(monster),L.LiveCombat.notices(first)) == 1n : Nat}
  for +cut: E.Epoch.Cut<run,L.LiveCombat.world(first),Once.Once.after(monster,damage)>
  Lifetime.Certificate<monster,damage,first,run>

def Lifetime.compose(monster,damage,first,run,one,cut):
  Lifetime.Certificate{cut,LD.LiveDead.one_plus_zero(L.LiveCombat.notices(first),PH.Permanent.notices(Lifetime.prefix(run,L.LiveCombat.world(first),Once.Once.after(monster,damage),cut)),R.Roster.id(monster),one,(%Once.Once.after_id(monster,damage) : {Dead.Dead.count(_,PH.Permanent.notices(Lifetime.prefix(run,L.LiveCombat.world(first),Once.Once.after(monster,damage),cut))) == 0n : Nat}; Lifetime.prefix_zero(Once.Once.after(monster,damage),run,L.LiveCombat.world(first),cut)))}

law Lifetime.after_once:
  for requests: List<&1,H.History.Request>
  for +monster: M.Monsters.State
  for +damage: U32
  for +first: L.LiveCombat.Result
  for +states: List<&2,Sess.Sessions.State>
  for +certificate: Once.Once.Certificate<monster,damage,AO.AttackOnce.view(first)>
  for +valid: SW.SeededWorld.OK<L.LiveCombat.world(first),states>
  Lifetime.Certificate<monster,damage,first,H.History.trace(requests,L.LiveCombat.world(first))>

def Lifetime.after_once(requests,monster,damage,first,states,certificate,valid):
  match certificate:
    case Once.Once.Certificate{inside,unique,dead,count}:
      Lifetime.compose(monster,damage,first,H.History.trace(requests,L.LiveCombat.world(first)),count,E.Epoch.cut(requests,L.LiveCombat.world(first),states,Once.Once.after(monster,damage),valid,inside,dead))

# Derive post-command validity from the initial world instead of assuming it.
law Lifetime.at:
  for requests: List<&1,H.History.Request>
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for +plan: L.LiveCombat.Plan
  for +monster: M.Monsters.State
  for +damage: U32
  for +states: List<&2,Sess.Sessions.State>
  for +valid: SW.SeededWorld.OK<world,states>
  for +certificate: Once.Once.Certificate<monster,damage,AO.AttackOnce.view(L.LiveCombat.at(world,kind,pid,score,plan))>
  Lifetime.Certificate<monster,damage,L.LiveCombat.at(world,kind,pid,score,plan),H.History.trace(requests,L.LiveCombat.world(L.LiveCombat.at(world,kind,pid,score,plan)))>

def Lifetime.at(requests,world,kind,pid,score,plan,monster,damage,states,valid,certificate):
  Lifetime.after_once(requests,monster,damage,L.LiveCombat.at(world,kind,pid,score,plan),states,certificate,L.LiveCombat.at_seeded(world,kind,pid,score,plan,states,valid))

law Lifetime.run:
  for requests: List<&1,H.History.Request>
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for planner: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +monster: M.Monsters.State
  for +damage: U32
  for +states: List<&2,Sess.Sessions.State>
  for +valid: SW.SeededWorld.OK<world,states>
  for +certificate: Once.Once.Certificate<monster,damage,AO.AttackOnce.view(L.LiveCombat.run(world,kind,pid,score,planner))>
  Lifetime.Certificate<monster,damage,L.LiveCombat.run(world,kind,pid,score,planner),H.History.trace(requests,L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,score,planner)))>

def Lifetime.run(requests,world,kind,pid,score,planner,monster,damage,states,valid,certificate):
  +plan = planner(L.LiveCombat.prepare(world,kind,pid,score))
  Lifetime.at(requests,world,kind,pid,score,plan,monster,damage,states,valid,certificate)

def Lifetime.cut(-monster: M.Monsters.State,-damage: U32,-first: L.LiveCombat.Result,-run: H.History.Run,certificate: Lifetime.Certificate<monster,damage,first,run>) -> E.Epoch.Cut<run,L.LiveCombat.world(first),Once.Once.after(monster,damage)>:
  match certificate:
    case Lifetime.Certificate{cut,one}: cut

law Lifetime.exactly_once:
  for +monster: M.Monsters.State
  for +damage: U32
  for +first: L.LiveCombat.Result
  for -run: H.History.Run
  for +certificate: Lifetime.Certificate<monster,damage,first,run>
  {Dead.Dead.count(R.Roster.id(monster),B.Battle.concat(L.LiveCombat.notices(first),PH.Permanent.notices(Lifetime.prefix(run,L.LiveCombat.world(first),Once.Once.after(monster,damage),Lifetime.cut(monster,damage,first,run,certificate))))) == 1n : Nat}

def Lifetime.exactly_once(monster,damage,first,run,certificate):
  match certificate:
    case Lifetime.Certificate{cut,one}: one

law Lifetime.full_once:
  for +monster: M.Monsters.State
  for +damage: U32
  for +first: L.LiveCombat.Result
  for -run: H.History.Run
  for +certificate: Lifetime.Certificate<monster,damage,first,run>
  for +none: {Lifetime.born(run,L.LiveCombat.world(first),Once.Once.after(monster,damage),Lifetime.cut(monster,damage,first,run,certificate)) == False{} : Bool}
  {Dead.Dead.count(R.Roster.id(monster),B.Battle.concat(L.LiveCombat.notices(first),PH.Permanent.notices(H.History.entries(run)))) == 1n : Nat}

def Lifetime.full_once(monster,damage,first,run,certificate,none):
  match certificate:
    case Lifetime.Certificate{cut,one}:
      %Equal.sym(List<&2,H.History.Entry>,H.History.entries(run),Lifetime.prefix(run,L.LiveCombat.world(first),Once.Once.after(monster,damage),cut),Lifetime.full_prefix(run,L.LiveCombat.world(first),Once.Once.after(monster,damage),cut,none)) : {Dead.Dead.count(R.Roster.id(monster),B.Battle.concat(L.LiveCombat.notices(first),PH.Permanent.notices(_))) == 1n : Nat}
      one

