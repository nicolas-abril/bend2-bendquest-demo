# Exactly-once reward for a selected lethal hit among arbitrary spin powers.
import Base
import ./combat_lethal.bend as Kill
import ./spin_plans.bend as Plan
import ./target_plans.bend as TP
import ./combat_targets.bend as Targets
import ./combat_frame.bend as Frame
import ./combat_actor.bend as Actor
import ./combat_admitted.bend as Admit
import ./targeting.bend as Member
import ./identity.bend as I
import ./zones.bend as Z
import ./players.bend as P
import ./monsters.bend as M
import ./roster.bend as R
import ./battle.bend as B
import ./simulation.bend as S
import ./terrain.bend as T
import ./combat.bend as C
import ./live_combat.bend as L
import ./live_spin.bend as Spin

import ./spin_lethal.bend as SK
import ./reward_once.bend as Once
import ./dead_rewards.bend as Dead
import ./attack_once.bend as AO
import ./live_dead.bend as LD

import ./spin_once.bend as SO

# This witness selects one actual power. Other selected powers are unrestricted.
def MixedSpin.Slot(+monster: M.Monsters.State,selected: List<&2,M.Monsters.State>,powers: Plan.SpinPlans.Powers(selected)) -> Data:
  match selected:
    case Nil{}: Empty
    case Con{head,rest}:
      match powers:
        case Tuple{power,later}:
          +head = head
          Either<&2,&2,Sigma<&2,&2,{head == monster : M.Monsters.State},(same => Kill.Lethal.Enough(head,Kill.Lethal.damage(power)))>,MixedSpin.Slot(monster,rest,later)>

law MixedSpin.member:
  for +monster: M.Monsters.State
  for +selected: List<&2,M.Monsters.State>
  for +powers: Plan.SpinPlans.Powers(selected)
  for +slot: MixedSpin.Slot(monster,selected,powers)
  Targets.Targets.In<monster,selected>

def MixedSpin.member(monster,selected,powers,slot):
  match selected:
    case Nil{}: Empty.absurd(Targets.Targets.In<monster,Nil{}>,slot)
    case Con{head,rest}:
      match powers:
        case Tuple{power,later}:
          match slot:
            case Inl{value}:
              match value:
                case Tuple{same,enough}:
                  %same : Targets.Targets.In<_,Con{head,rest}>
                  Targets.Targets.Here{rest,{==}}
            case Inr{value}: Targets.Targets.There{head,rest,{==},MixedSpin.member(monster,rest,later,value)}

law MixedSpin.prepend:
  for +monster: M.Monsters.State
  for +first: B.Battle.Result
  for +second: B.Battle.Result
  for +clear: Dead.Dead.Clear(R.Roster.id(monster),B.Battle.notices(first))
  for +chosen: SO.SpinOnce.Chosen<monster,second>
  SO.SpinOnce.Chosen<monster,B.Battle.before(first,second)>

def MixedSpin.prepend(monster,first,second,clear,chosen):
  match chosen:
    case SO.SpinOnce.Chosen{damage,once}: SO.SpinOnce.Chosen{damage,SO.SpinOnce.prepend(monster,damage,first,second,clear,once)}

law MixedSpin.run:
  for +monster: M.Monsters.State
  for +selected: List<&2,M.Monsters.State>
  for +powers: Plan.SpinPlans.Powers(selected)
  for +state: S.Simulation.State
  for +original: P.Players.State
  for +pid: U32
  for +score: U32
  for +point: Targets.Targets.Point
  for +sources: Targets.Targets.Sources(S.Simulation.monsters(state),point,selected)
  for +unique: I.Identity.Monsters(S.Simulation.monsters(state))
  for +selected_unique: I.Identity.Monsters(selected)
  for +member: Actor.Actor.Member<original,S.Simulation.players(state)>
  for +same: {P.Players.id(original) == pid : U32}
  for +slot: MixedSpin.Slot(monster,selected,powers)
  SO.SpinOnce.Chosen<monster,B.Battle.run(Plan.SpinPlans.inputs(selected,powers),state,pid,score)>

def MixedSpin.run(monster,selected,powers,state,original,pid,score,point,sources,unique,selected_unique,member,same,slot):
  match selected:
    case Nil{}: Empty.absurd(SO.SpinOnce.Chosen<monster,B.Battle.run(Plan.SpinPlans.inputs(Nil{},powers),state,pid,score)>,slot)
    case Con{head,rest}:
      match powers:
        case Tuple{power,later_powers}:
          match sources:
            case Tuple{source,later_sources}:
              match selected_unique:
                case Tuple{absent,remaining_unique}:
                  match slot:
                    case Inl{value}:
                      match value:
                        case Tuple{equal,enough}:
                          %equal : SO.SpinOnce.Chosen<_,B.Battle.run(Plan.SpinPlans.inputs(Con{head,rest},Tuple{power,later_powers}),state,pid,score)>
                          SO.SpinOnce.Chosen{Kill.Lethal.damage(power),SO.SpinOnce.head(head,power,Plan.SpinPlans.inputs(rest,later_powers),state,original,pid,score,point,source,unique,member,same,enough)}
                    case Inr{value}:
                      +input = Plan.SpinPlans.input(head,power)
                      +other_ids = {(%Equal.sym(U32,TP.TargetPlans.id(input),R.Roster.id(head),Plan.SpinPlans.input_id(head,power)) : I.Identity.Absent(_,Z.Zones.keys(rest)); (%Targets.Targets.key_id(head) : I.Identity.Absent(_,Z.Zones.keys(rest)); absent)) : I.Identity.Absent(TP.TargetPlans.id(input),Z.Zones.keys(rest))}
                      +clear = Dead.Dead.only_clear(B.Battle.notices(B.Battle.strike(input,state,pid,score)),TP.TargetPlans.id(input),R.Roster.id(monster),Dead.Dead.battle_target(input,state,pid,score),I.Identity.neq_sym(TP.TargetPlans.id(input),R.Roster.id(monster),Targets.Targets.absent_member(monster,rest,TP.TargetPlans.id(input),MixedSpin.member(monster,rest,later_powers,value),other_ids)))
                      MixedSpin.prepend(monster,B.Battle.strike(input,state,pid,score),B.Battle.run(Plan.SpinPlans.inputs(rest,later_powers),B.Battle.state(B.Battle.strike(input,state,pid,score)),pid,score),clear,MixedSpin.run(monster,rest,later_powers,B.Battle.state(B.Battle.strike(input,state,pid,score)),original,pid,score,point,Frame.CombatFrame.survivor_sources(rest,input,state,pid,score,point,later_sources,other_ids),I.Identity.battle_strike_unique(input,state,pid,score,unique),remaining_unique,Actor.Actor.battle_strike(original,input,state,pid,score,member),same,value))

law MixedSpin.pack:
  for +monster: M.Monsters.State
  for +result: B.Battle.Result
  for +maps: T.Terrain.Maps
  for +visual: L.LiveCombat.Visual
  for +chosen: SO.SpinOnce.Chosen<monster,result>
  AO.AttackOnce.Prefix<monster,L.LiveCombat.pack(result,maps,visual)>

def MixedSpin.pack(monster,result,maps,visual,chosen):
  SO.SpinOnce.from_chosen(monster,L.LiveCombat.pack(result,maps,visual),L.LiveCombat.pack(result,maps,visual),{==},(%Equal.sym(B.Battle.Result,AO.AttackOnce.view(L.LiveCombat.pack(result,maps,visual)),result,AO.AttackOnce.view_pack(result,maps,visual)) : SO.SpinOnce.Chosen<monster,_>; chosen))

law MixedSpin.ready:
  for +monster: M.Monsters.State
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +monsters: List<&2,M.Monsters.State>
  for +maps: T.Terrain.Maps
  for +actor: P.Players.State
  for +pid: U32
  for +score: U32
  for +selected: List<&2,M.Monsters.State>
  for +point: Targets.Targets.Point
  for +powers: Plan.SpinPlans.Powers(selected)
  for +sources: Targets.Targets.Sources(monsters,point,selected)
  for +unique: I.Identity.Monsters(monsters)
  for +selected_unique: I.Identity.Monsters(selected)
  for +inside: Member.Targeting.In<actor,players>
  for +same: {P.Players.id(actor) == pid : U32}
  for +slot: MixedSpin.Slot(monster,selected,powers)
  AO.AttackOnce.Prefix<monster,L.LiveCombat.finish(L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,Some{actor}},pid,score},Plan.SpinPlans.ready(selected,point,powers))>

def MixedSpin.ready(monster,meta,players,monsters,maps,actor,pid,score,selected,point,powers,sources,unique,selected_unique,inside,same,slot):
  match point:
    case Targets.Targets.Point{zone,x,y}:
      MixedSpin.pack(monster,B.Battle.run(Plan.SpinPlans.inputs(selected,powers),S.Simulation.State{meta,players,monsters},pid,score),maps,L.LiveCombat.Spin{zone,x,y},MixedSpin.run(monster,selected,powers,S.Simulation.State{meta,players,monsters},actor,pid,score,Targets.Targets.Point{zone,x,y},sources,unique,selected_unique,Actor.Actor.Member{actor,inside,{==}},same,slot))

law MixedSpin.filtered:
  for +monster: M.Monsters.State
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +monsters: List<&2,M.Monsters.State>
  for +maps: T.Terrain.Maps
  for +actor: P.Players.State
  for +pid: U32
  for +score: U32
  for build: (@+selected: List<&2,M.Monsters.State> -> Plan.SpinPlans.Powers(selected))
  for +unique: I.Identity.Monsters(monsters)
  for +inside: Member.Targeting.In<actor,players>
  for +same: {P.Players.id(actor) == pid : U32}
  for +slot: MixedSpin.Slot(monster,Targets.Targets.filter(monsters,Spin.LiveSpin.point(actor)),build(Targets.Targets.filter(monsters,Spin.LiveSpin.point(actor))))
  AO.AttackOnce.Prefix<monster,L.LiveCombat.finish(L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,Some{actor}},pid,score},Plan.SpinPlans.run(monsters,Spin.LiveSpin.point(actor),build))>

def MixedSpin.filtered(monster,meta,players,monsters,maps,actor,pid,score,build,unique,inside,same,slot):
  +selected = Targets.Targets.filter(monsters,Spin.LiveSpin.point(actor))
  MixedSpin.ready(monster,meta,players,monsters,maps,actor,pid,score,selected,Spin.LiveSpin.point(actor),build(selected),Targets.Targets.filter_sources(monsters,Spin.LiveSpin.point(actor)),unique,Targets.Targets.filter_unique(monsters,Spin.LiveSpin.point(actor),unique),inside,same,slot)

def MixedSpin.BuiltSlot(ready: L.LiveCombat.Ready,+monster: M.Monsters.State,build: Spin.LiveSpin.Builder) -> Data:
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}: Empty
            case Some{player}:
              +player = player
              +monsters = monsters
              +selected = Targets.Targets.filter(monsters,Spin.LiveSpin.point(player))
              MixedSpin.Slot(monster,selected,build(monsters,player,meta,selected))

law MixedSpin.planned:
  for +ready: L.LiveCombat.Ready
  for +monster: M.Monsters.State
  for build: Spin.LiveSpin.Builder
  for +valid: Admit.Admitted.Ready(ready)
  for +unique: Spin.LiveSpin.Unique(ready)
  for +slot: MixedSpin.BuiltSlot(ready,monster,build)
  AO.AttackOnce.Prefix<monster,L.LiveCombat.finish(ready,Spin.LiveSpin.plan(ready,build))>

def MixedSpin.planned(ready,monster,build,valid,unique,slot):
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}: Empty.absurd(AO.AttackOnce.Prefix<monster,L.LiveCombat.finish(L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,None{}},pid,score},Spin.LiveSpin.plan(L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,None{}},pid,score},build))>,slot)
            case Some{player}:
              match valid:
                case Tuple{inside,same}: MixedSpin.filtered(monster,meta,players,monsters,maps,player,pid,score,build(monsters,player,meta),unique,inside,same,slot)

law MixedSpin.live:
  for +world: T.Terrain.World
  for +pid: U32
  for +score: U32
  for +monster: M.Monsters.State
  for build: Spin.LiveSpin.Builder
  for +unique: I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(world)))
  for +slot: MixedSpin.BuiltSlot(L.LiveCombat.prepare(world,C.Combat.Spin{},pid,score),monster,build)
  AO.AttackOnce.Prefix<monster,L.LiveCombat.run(world,C.Combat.Spin{},pid,score,(ready => Spin.LiveSpin.plan(ready,build)))>

def MixedSpin.live(world,pid,score,monster,build,unique,slot): MixedSpin.planned(L.LiveCombat.prepare(world,C.Combat.Spin{},pid,score),monster,build,Admit.Admitted.live_prepare(world,C.Combat.Spin{},pid,score),Spin.LiveSpin.prepare_unique(world,pid,score,unique),slot)

law MixedSpin.live_history:
  for requests: List<&1,LD.LiveDead.Request>
  for +world: T.Terrain.World
  for +pid: U32
  for +score: U32
  for +monster: M.Monsters.State
  for build: Spin.LiveSpin.Builder
  for +unique: I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(world)))
  for +slot: MixedSpin.BuiltSlot(L.LiveCombat.prepare(world,C.Combat.Spin{},pid,score),monster,build)
  AO.AttackOnce.History<monster,L.LiveCombat.run(world,C.Combat.Spin{},pid,score,(ready => Spin.LiveSpin.plan(ready,build))),requests>

def MixedSpin.live_history(requests,world,pid,score,monster,build,unique,slot):
  AO.AttackOnce.extend(requests,monster,L.LiveCombat.run(world,C.Combat.Spin{},pid,score,(ready => Spin.LiveSpin.plan(ready,build))),MixedSpin.live(world,pid,score,monster,build,unique,slot))

law MixedSpin.live_exactly_once:
  for requests: List<&1,LD.LiveDead.Request>
  for +world: T.Terrain.World
  for +pid: U32
  for +score: U32
  for +monster: M.Monsters.State
  for build: Spin.LiveSpin.Builder
  for +unique: I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(world)))
  for +slot: MixedSpin.BuiltSlot(L.LiveCombat.prepare(world,C.Combat.Spin{},pid,score),monster,build)
  {Dead.Dead.count(R.Roster.id(monster),B.Battle.concat(L.LiveCombat.notices(L.LiveCombat.run(world,C.Combat.Spin{},pid,score,(ready => Spin.LiveSpin.plan(ready,build)))),LD.LiveDead.notices(LD.LiveDead.trace(requests,L.LiveCombat.world(L.LiveCombat.run(world,C.Combat.Spin{},pid,score,(ready => Spin.LiveSpin.plan(ready,build)))))))) == 1n : Nat}

def MixedSpin.live_exactly_once(requests,world,pid,score,monster,build,unique,slot):
  AO.AttackOnce.exactly_once(monster,L.LiveCombat.run(world,C.Combat.Spin{},pid,score,(ready => Spin.LiveSpin.plan(ready,build))),requests,MixedSpin.live_history(requests,world,pid,score,monster,build,unique,slot))
