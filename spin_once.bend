# Exactly-once certificates for every actual selected spin target.
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

def SpinOnce.commands(inputs: List<&2,B.Battle.Input>,+pid: U32,+score: U32) -> List<&2,Dead.Dead.Command>:
  match inputs:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{Dead.Dead.Command{head,pid,score},SpinOnce.commands(rest,pid,score)}

law SpinOnce.commands_run:
  for +inputs: List<&2,B.Battle.Input>
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  {Dead.Dead.trace(SpinOnce.commands(inputs,pid,score),state) == B.Battle.run(inputs,state,pid,score) : B.Battle.Result}

def SpinOnce.commands_run(inputs,state,pid,score):
  match inputs:
    case Nil{}: {==}
    case Con{head,rest}:
      %SpinOnce.commands_run(rest,B.Battle.state(B.Battle.strike(head,state,pid,score)),pid,score) : {B.Battle.before(B.Battle.strike(head,state,pid,score),Dead.Dead.trace(SpinOnce.commands(rest,pid,score),B.Battle.state(B.Battle.strike(head,state,pid,score)))) == B.Battle.before(B.Battle.strike(head,state,pid,score),_) : B.Battle.Result}
      {==}

law SpinOnce.head:
  for +monster: M.Monsters.State
  for +power: TP.TargetPlans.Power
  for +later: List<&2,B.Battle.Input>
  for +state: S.Simulation.State
  for +original: P.Players.State
  for +pid: U32
  for +score: U32
  for +point: Targets.Targets.Point
  for +source: Targets.Targets.Source<S.Simulation.monsters(state),point,monster>
  for +unique: I.Identity.Monsters(S.Simulation.monsters(state))
  for +member: Actor.Actor.Member<original,S.Simulation.players(state)>
  for +same: {P.Players.id(original) == pid : U32}
  for +enough: Kill.Lethal.Enough(monster,Kill.Lethal.damage(power))
  Once.Once.Certificate<monster,Kill.Lethal.damage(power),B.Battle.run(Con{Plan.SpinPlans.input(monster,power),later},state,pid,score)>

def SpinOnce.head(monster,power,later,state,original,pid,score,point,source,unique,member,same,enough):
  match power:
    case TP.TargetPlans.Power{damage,payout}:
      %SpinOnce.commands_run(later,B.Battle.state(Once.Once.first(monster,damage,payout,state,pid,score)),pid,score) : Once.Once.Certificate<monster,damage,B.Battle.before(Once.Once.first(monster,damage,payout,state,pid,score),_)>
      Once.Once.prove(SpinOnce.commands(later,pid,score),monster,damage,payout,state,pid,score,point,source,unique,enough,(%same : {P.Players.has_id(S.Simulation.players(state),_) == True{} : Bool}; SK.SpinKill.member_has(original,S.Simulation.players(state),member)))

# Prepending a different target's hit preserves the tracked target's count=1.
law SpinOnce.prepend:
  for +monster: M.Monsters.State
  for +damage: U32
  for +first: B.Battle.Result
  for +second: B.Battle.Result
  for +clear: Dead.Dead.Clear(R.Roster.id(monster),B.Battle.notices(first))
  for +once: Once.Once.Certificate<monster,damage,second>
  Once.Once.Certificate<monster,damage,B.Battle.before(first,second)>

def SpinOnce.prepend(monster,damage,first,second,clear,once):
  match once:
    case Once.Once.Certificate{inside,unique,dead,count}:
      Once.Once.Certificate{inside,unique,dead,(%Equal.sym(Nat,Dead.Dead.count(R.Roster.id(monster),B.Battle.concat(B.Battle.notices(first),B.Battle.notices(second))),Nat.add(Dead.Dead.count(R.Roster.id(monster),B.Battle.notices(first)),Dead.Dead.count(R.Roster.id(monster),B.Battle.notices(second))),Once.Once.concat_count(B.Battle.notices(first),B.Battle.notices(second),R.Roster.id(monster))) : {_ == 1n : Nat}; (%Equal.sym(Nat,Dead.Dead.count(R.Roster.id(monster),B.Battle.notices(first)),0n,Dead.Dead.clear_zero(B.Battle.notices(first),R.Roster.id(monster),clear)) : {Nat.add(_,Dead.Dead.count(R.Roster.id(monster),B.Battle.notices(second))) == 1n : Nat}; count))}

def SpinOnce.Certificates(selected: List<&2,M.Monsters.State>,powers: Plan.SpinPlans.Powers(selected),+result: B.Battle.Result) -> Data:
  match selected:
    case Nil{}: Unit
    case Con{head,rest}:
      match powers:
        case Tuple{power,later}: Sigma<&2,&2,Once.Once.Certificate<head,Kill.Lethal.damage(power),result>,(once => SpinOnce.Certificates(rest,later,result))>

law SpinOnce.prepend_all:
  for +selected: List<&2,M.Monsters.State>
  for +powers: Plan.SpinPlans.Powers(selected)
  for +target: U32
  for +first: B.Battle.Result
  for +second: B.Battle.Result
  for +absent: I.Identity.Absent(target,Z.Zones.keys(selected))
  for +only: Dead.Dead.Only(target,B.Battle.notices(first))
  for +certificates: SpinOnce.Certificates(selected,powers,second)
  SpinOnce.Certificates(selected,powers,B.Battle.before(first,second))

def SpinOnce.prepend_all(selected,powers,target,first,second,absent,only,certificates):
  match selected:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match powers:
        case Tuple{power,later}:
          match absent:
            case Tuple{different,remaining}:
              match certificates:
                case Tuple{once,others}:
                  Tuple{SpinOnce.prepend(head,Kill.Lethal.damage(power),first,second,Dead.Dead.only_clear(B.Battle.notices(first),target,R.Roster.id(head),only,I.Identity.neq_sym(target,R.Roster.id(head),(%Targets.Targets.key_id(head) : {U32.is_eq(target,_) == False{} : Bool}; different))),once),SpinOnce.prepend_all(rest,later,target,first,second,remaining,only,others)}

law SpinOnce.run:
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
  for +enough: SK.SpinKill.Enough(selected,powers)
  SpinOnce.Certificates(selected,powers,B.Battle.run(Plan.SpinPlans.inputs(selected,powers),state,pid,score))

def SpinOnce.run(selected,powers,state,original,pid,score,point,sources,unique,selected_unique,member,same,enough):
  match selected:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match powers:
        case Tuple{power,later_powers}:
          match sources:
            case Tuple{source,later_sources}:
              match selected_unique:
                case Tuple{absent,remaining_unique}:
                  match enough:
                    case Tuple{first_enough,later_enough}:
                      +input = Plan.SpinPlans.input(head,power)
                      +other_ids = {(%Equal.sym(U32,TP.TargetPlans.id(input),R.Roster.id(head),Plan.SpinPlans.input_id(head,power)) : I.Identity.Absent(_,Z.Zones.keys(rest)); (%Targets.Targets.key_id(head) : I.Identity.Absent(_,Z.Zones.keys(rest)); absent)) : I.Identity.Absent(TP.TargetPlans.id(input),Z.Zones.keys(rest))}
                      Tuple{SpinOnce.head(head,power,Plan.SpinPlans.inputs(rest,later_powers),state,original,pid,score,point,source,unique,member,same,first_enough),SpinOnce.prepend_all(rest,later_powers,TP.TargetPlans.id(input),B.Battle.strike(input,state,pid,score),B.Battle.run(Plan.SpinPlans.inputs(rest,later_powers),B.Battle.state(B.Battle.strike(input,state,pid,score)),pid,score),other_ids,Dead.Dead.battle_target(input,state,pid,score),SpinOnce.run(rest,later_powers,B.Battle.state(B.Battle.strike(input,state,pid,score)),original,pid,score,point,Frame.CombatFrame.survivor_sources(rest,input,state,pid,score,point,later_sources,other_ids),I.Identity.battle_strike_unique(input,state,pid,score,unique),remaining_unique,Actor.Actor.battle_strike(original,input,state,pid,score,member),same,later_enough))}


type SpinOnce.Bundle<-selected: List<&2,M.Monsters.State>,-result: B.Battle.Result> is Data:
  SpinOnce.Bundle{powers: Plan.SpinPlans.Powers(selected),certificates: SpinOnce.Certificates(selected,powers,result)}

type SpinOnce.Prefix<-selected: List<&2,M.Monsters.State>,-result: L.LiveCombat.Result> is Data:
  SpinOnce.Prefix{actual: L.LiveCombat.Result,same: {actual == result : L.LiveCombat.Result},bundle: SpinOnce.Bundle<selected,AO.AttackOnce.view(actual)>}

law SpinOnce.ready:
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
  for +enough: SK.SpinKill.Enough(selected,powers)
  SpinOnce.Prefix<selected,L.LiveCombat.finish(L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,Some{actor}},pid,score},Plan.SpinPlans.ready(selected,point,powers))>

def SpinOnce.ready(meta,players,monsters,maps,actor,pid,score,selected,point,powers,sources,unique,selected_unique,inside,same,enough):
  match point:
    case Targets.Targets.Point{zone,x,y}:
      +battle = B.Battle.run(Plan.SpinPlans.inputs(selected,powers),S.Simulation.State{meta,players,monsters},pid,score)
      +visual = {L.LiveCombat.Spin{zone,x,y} : L.LiveCombat.Visual}
      SpinOnce.Prefix{L.LiveCombat.pack(battle,maps,visual),{==},SpinOnce.Bundle{powers,(%Equal.sym(B.Battle.Result,AO.AttackOnce.view(L.LiveCombat.pack(battle,maps,visual)),battle,AO.AttackOnce.view_pack(battle,maps,visual)) : SpinOnce.Certificates(selected,powers,_); SpinOnce.run(selected,powers,S.Simulation.State{meta,players,monsters},actor,pid,score,Targets.Targets.Point{zone,x,y},sources,unique,selected_unique,Actor.Actor.Member{actor,inside,{==}},same,enough))}}

law SpinOnce.filtered:
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
  for +enough: SK.SpinKill.Enough(Targets.Targets.filter(monsters,Spin.LiveSpin.point(actor)),build(Targets.Targets.filter(monsters,Spin.LiveSpin.point(actor))))
  SpinOnce.Prefix<Targets.Targets.filter(monsters,Spin.LiveSpin.point(actor)),L.LiveCombat.finish(L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,Some{actor}},pid,score},Plan.SpinPlans.run(monsters,Spin.LiveSpin.point(actor),build))>

def SpinOnce.filtered(meta,players,monsters,maps,actor,pid,score,build,unique,inside,same,enough):
  +selected = Targets.Targets.filter(monsters,Spin.LiveSpin.point(actor))
  SpinOnce.ready(meta,players,monsters,maps,actor,pid,score,selected,Spin.LiveSpin.point(actor),build(selected),Targets.Targets.filter_sources(monsters,Spin.LiveSpin.point(actor)),unique,Targets.Targets.filter_unique(monsters,Spin.LiveSpin.point(actor),unique),inside,same,enough)

def SpinOnce.selected(ready: L.LiveCombat.Ready) -> List<&2,M.Monsters.State>:
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}: Nil{}
            case Some{player}: Targets.Targets.filter(monsters,Spin.LiveSpin.point(player))

law SpinOnce.planned:
  for +ready: L.LiveCombat.Ready
  for build: Spin.LiveSpin.Builder
  for +valid: Admit.Admitted.Ready(ready)
  for +unique: Spin.LiveSpin.Unique(ready)
  for +enough: SK.SpinKill.BuiltEnough(ready,build)
  SpinOnce.Prefix<SpinOnce.selected(ready),L.LiveCombat.finish(ready,Spin.LiveSpin.plan(ready,build))>

def SpinOnce.planned(ready,build,valid,unique,enough):
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}: SpinOnce.Prefix{L.LiveCombat.finish(L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,None{}},pid,score},L.LiveCombat.Plan{Nil{},L.LiveCombat.Quiet{}}),{==},SpinOnce.Bundle{Unit{},Unit{}}}
            case Some{player}:
              match valid:
                case Tuple{inside,same}: SpinOnce.filtered(meta,players,monsters,maps,player,pid,score,build(monsters,player,meta),unique,inside,same,enough)

law SpinOnce.live:
  for +world: T.Terrain.World
  for +pid: U32
  for +score: U32
  for build: Spin.LiveSpin.Builder
  for +unique: I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(world)))
  for +enough: SK.SpinKill.BuiltEnough(L.LiveCombat.prepare(world,C.Combat.Spin{},pid,score),build)
  SpinOnce.Prefix<SpinOnce.selected(L.LiveCombat.prepare(world,C.Combat.Spin{},pid,score)),L.LiveCombat.run(world,C.Combat.Spin{},pid,score,(ready => Spin.LiveSpin.plan(ready,build)))>

def SpinOnce.live(world,pid,score,build,unique,enough): SpinOnce.planned(L.LiveCombat.prepare(world,C.Combat.Spin{},pid,score),build,Admit.Admitted.live_prepare(world,C.Combat.Spin{},pid,score),Spin.LiveSpin.prepare_unique(world,pid,score,unique),enough)

# Membership chooses any selected target, including targets after earlier hits.
type SpinOnce.Chosen<-monster: M.Monsters.State,-result: B.Battle.Result> is Data:
  SpinOnce.Chosen{damage: U32,once: Once.Once.Certificate<monster,damage,result>}

def SpinOnce.head_bundle(+monster: M.Monsters.State,+rest: List<&2,M.Monsters.State>,+result: B.Battle.Result,bundle: SpinOnce.Bundle<Con{monster,rest},result>) -> SpinOnce.Chosen<monster,result>:
  match bundle:
    case SpinOnce.Bundle{powers,certificates}:
      match powers:
        case Tuple{power,later}:
          match certificates:
            case Tuple{once,others}: SpinOnce.Chosen{Kill.Lethal.damage(power),once}

def SpinOnce.tail_bundle(+head: M.Monsters.State,+rest: List<&2,M.Monsters.State>,+result: B.Battle.Result,bundle: SpinOnce.Bundle<Con{head,rest},result>) -> SpinOnce.Bundle<rest,result>:
  match bundle:
    case SpinOnce.Bundle{powers,certificates}:
      match powers:
        case Tuple{power,later}:
          match certificates:
            case Tuple{once,others}: SpinOnce.Bundle{later,others}

law SpinOnce.choose:
  for +monster: M.Monsters.State
  for -selected: List<&2,M.Monsters.State>
  for +result: B.Battle.Result
  for +inside: Targets.Targets.In<monster,selected>
  for +bundle: SpinOnce.Bundle<selected,result>
  SpinOnce.Chosen<monster,result>

def SpinOnce.choose(monster,selected,result,inside,bundle):
  match inside:
    case Targets.Targets.Here{rest,shape}:
      SpinOnce.head_bundle(monster,rest,result,(%shape : SpinOnce.Bundle<_,result>; bundle))
    case Targets.Targets.There{head,rest,shape,earlier}:
      SpinOnce.choose(monster,rest,result,earlier,SpinOnce.tail_bundle(head,rest,result,(%shape : SpinOnce.Bundle<_,result>; bundle)))

def SpinOnce.from_chosen(-monster: M.Monsters.State,-result: L.LiveCombat.Result,+actual: L.LiveCombat.Result,same: {actual == result : L.LiveCombat.Result},chosen: SpinOnce.Chosen<monster,AO.AttackOnce.view(actual)>) -> AO.AttackOnce.Prefix<monster,result>:
  match chosen:
    case SpinOnce.Chosen{damage,once}: AO.AttackOnce.Prefix{actual,same,damage,once}

law SpinOnce.pick:
  for +monster: M.Monsters.State
  for -selected: List<&2,M.Monsters.State>
  for -result: L.LiveCombat.Result
  for +inside: Targets.Targets.In<monster,selected>
  for +prefix: SpinOnce.Prefix<selected,result>
  AO.AttackOnce.Prefix<monster,result>

def SpinOnce.pick(monster,selected,result,inside,prefix):
  match prefix:
    case SpinOnce.Prefix{actual,same,bundle}:
      SpinOnce.from_chosen(monster,result,actual,same,SpinOnce.choose(monster,selected,AO.AttackOnce.view(actual),inside,bundle))

law SpinOnce.live_history:
  for requests: List<&1,LD.LiveDead.Request>
  for +world: T.Terrain.World
  for +pid: U32
  for +score: U32
  for +monster: M.Monsters.State
  for build: Spin.LiveSpin.Builder
  for +unique: I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(world)))
  for +enough: SK.SpinKill.BuiltEnough(L.LiveCombat.prepare(world,C.Combat.Spin{},pid,score),build)
  for +inside: Targets.Targets.In<monster,SpinOnce.selected(L.LiveCombat.prepare(world,C.Combat.Spin{},pid,score))>
  AO.AttackOnce.History<monster,L.LiveCombat.run(world,C.Combat.Spin{},pid,score,(ready => Spin.LiveSpin.plan(ready,build))),requests>

def SpinOnce.live_history(requests,world,pid,score,monster,build,unique,enough,inside):
  AO.AttackOnce.extend(requests,monster,L.LiveCombat.run(world,C.Combat.Spin{},pid,score,(ready => Spin.LiveSpin.plan(ready,build))),SpinOnce.pick(monster,SpinOnce.selected(L.LiveCombat.prepare(world,C.Combat.Spin{},pid,score)),L.LiveCombat.run(world,C.Combat.Spin{},pid,score,(ready => Spin.LiveSpin.plan(ready,build))),inside,SpinOnce.live(world,pid,score,build,unique,enough)))

law SpinOnce.live_exactly_once:
  for requests: List<&1,LD.LiveDead.Request>
  for +world: T.Terrain.World
  for +pid: U32
  for +score: U32
  for +monster: M.Monsters.State
  for build: Spin.LiveSpin.Builder
  for +unique: I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(world)))
  for +enough: SK.SpinKill.BuiltEnough(L.LiveCombat.prepare(world,C.Combat.Spin{},pid,score),build)
  for +inside: Targets.Targets.In<monster,SpinOnce.selected(L.LiveCombat.prepare(world,C.Combat.Spin{},pid,score))>
  {Dead.Dead.count(R.Roster.id(monster),B.Battle.concat(L.LiveCombat.notices(L.LiveCombat.run(world,C.Combat.Spin{},pid,score,(ready => Spin.LiveSpin.plan(ready,build)))),LD.LiveDead.notices(LD.LiveDead.trace(requests,L.LiveCombat.world(L.LiveCombat.run(world,C.Combat.Spin{},pid,score,(ready => Spin.LiveSpin.plan(ready,build)))))))) == 1n : Nat}

def SpinOnce.live_exactly_once(requests,world,pid,score,monster,build,unique,enough,inside):
  AO.AttackOnce.exactly_once(monster,L.LiveCombat.run(world,C.Combat.Spin{},pid,score,(ready => Spin.LiveSpin.plan(ready,build))),requests,SpinOnce.live_history(requests,world,pid,score,monster,build,unique,enough,inside))
