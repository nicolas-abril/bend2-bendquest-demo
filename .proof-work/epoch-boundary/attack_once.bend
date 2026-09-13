# Actual lethal attack certificates and complete no-tick command suffixes.
import Base
import ./game.bend as G
import ./vitals.bend as V
import ./monsters.bend as M
import ./roster.bend as R
import ./combat_targets.bend as Targets
import ./identity.bend as I
import ./battle.bend as B
import ./payouts.bend as Pay
import ./players.bend as P
import ./targeting.bend as Member
import ./simulation.bend as S
import ./terrain.bend as T
import ./combat.bend as C
import ./combat_admitted.bend as Admit
import ./live_combat.bend as L
import ./live_attack.bend as Attack
import ./live_spin.bend as Spin
import ./target_plans.bend as TP
import ./numeric.bend as N

import ./combat_lethal.bend as Lethal
import ./dead_rewards.bend as Dead
import ./reward_once.bend as Once
import ./live_dead.bend as LD

def AttackOnce.view(+result: L.LiveCombat.Result) -> B.Battle.Result:
  B.Battle.Result{T.Terrain.simulation(L.LiveCombat.world(result)),L.LiveCombat.notices(result)}

law AttackOnce.view_pack:
  for +result: B.Battle.Result
  for +maps: T.Terrain.Maps
  for +visual: L.LiveCombat.Visual
  {AttackOnce.view(L.LiveCombat.pack(result,maps,visual)) == result : B.Battle.Result}

def AttackOnce.view_pack(result,maps,visual):
  match result:
    case B.Battle.Result{state,notices}:
      match state:
        case S.Simulation.State{meta,players,monsters}: {==}

type AttackOnce.Prefix<-monster: M.Monsters.State,-result: L.LiveCombat.Result> is Data:
  AttackOnce.Prefix{actual: L.LiveCombat.Result,same: {actual == result : L.LiveCombat.Result},damage: U32,once: Once.Once.Certificate<monster,damage,AttackOnce.view(actual)>}

law AttackOnce.ready:
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +monsters: List<&2,M.Monsters.State>
  for +maps: T.Terrain.Maps
  for +actor: P.Players.State
  for +pid: U32
  for +score: U32
  for +monster: M.Monsters.State
  for +point: Targets.Targets.Point
  for +dir: U32
  for +crit: U32
  for +power: TP.TargetPlans.Power
  for +source: Targets.Targets.Source<monsters,point,monster>
  for +unique: I.Identity.Monsters(monsters)
  for +enough: Lethal.Lethal.Enough(monster,Lethal.Lethal.damage(power))
  for +present: {P.Players.has_id(players,pid) == True{} : Bool}
  AttackOnce.Prefix<monster,L.LiveCombat.finish(L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,Some{actor}},pid,score},TP.TargetPlans.ready(monster,point,dir,crit,power))>

def AttackOnce.ready(meta,players,monsters,maps,actor,pid,score,monster,point,dir,crit,power,source,unique,enough,present):
  match point:
    case Targets.Targets.Point{zone,x,y}:
      match power:
        case TP.TargetPlans.Power{damage,payout}:
          +battle = B.Battle.run([B.Battle.Input{R.Roster.id(monster),damage,payout}],S.Simulation.State{meta,players,monsters},pid,score)
          +visual = {L.LiveCombat.Attack{zone,x,y,dir,R.Roster.id(monster),crit} : L.LiveCombat.Visual}
          AttackOnce.Prefix{L.LiveCombat.pack(battle,maps,visual),{==},damage,(%Equal.sym(B.Battle.Result,AttackOnce.view(L.LiveCombat.pack(battle,maps,visual)),battle,AttackOnce.view_pack(battle,maps,visual)) : Once.Once.Certificate<monster,damage,_>; Once.Once.prove(Nil{},monster,damage,payout,S.Simulation.State{meta,players,monsters},pid,score,Targets.Targets.Point{zone,x,y},source,unique,enough,present))}

law AttackOnce.selected_attack:
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +monsters: List<&2,M.Monsters.State>
  for +maps: T.Terrain.Maps
  for +actor: P.Players.State
  for +pid: U32
  for +score: U32
  for +crit: U32
  for +monster: M.Monsters.State
  for build: M.Monsters.State -> TP.TargetPlans.Power
  for +selected: {Targets.Targets.first(monsters,Spin.LiveSpin.point(actor)) == Some{monster} : Maybe<&2,M.Monsters.State>}
  for +unique: I.Identity.Monsters(monsters)
  for +enough: Lethal.Lethal.Enough(monster,Lethal.Lethal.damage(build(monster)))
  for +inside: Member.Targeting.In<actor,players>
  for +same: {P.Players.id(actor) == pid : U32}
  AttackOnce.Prefix<monster,L.LiveCombat.finish(L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,Some{actor}},pid,score},Attack.LiveAttack.finish(monsters,actor,Attack.LiveAttack.Tuning{crit,build}))>

def AttackOnce.selected_attack(meta,players,monsters,maps,actor,pid,score,crit,monster,build,selected,unique,enough,inside,same):
  %Equal.sym(Maybe<&2,M.Monsters.State>,Targets.Targets.first(monsters,Spin.LiveSpin.point(actor)),Some{monster},selected) : AttackOnce.Prefix<monster,L.LiveCombat.finish(L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,Some{actor}},pid,score},TP.TargetPlans.attack(_,Spin.LiveSpin.point(actor),Attack.LiveAttack.direction(actor),crit,build))>
  AttackOnce.ready(meta,players,monsters,maps,actor,pid,score,monster,Spin.LiveSpin.point(actor),Attack.LiveAttack.direction(actor),crit,build(monster),(%selected : Targets.Targets.FoundSource(monsters,Spin.LiveSpin.point(actor),_); Targets.Targets.first_source(monsters,Spin.LiveSpin.point(actor))),unique,enough,(%same : {P.Players.has_id(players,_) == True{} : Bool}; Member.Targeting.in_has(actor,players,inside)))


law AttackOnce.selected_tuning:
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +monsters: List<&2,M.Monsters.State>
  for +maps: T.Terrain.Maps
  for +actor: P.Players.State
  for +pid: U32
  for +score: U32
  for +monster: M.Monsters.State
  for tuning: Attack.LiveAttack.Tuning
  for +selected: {Targets.Targets.first(monsters,Spin.LiveSpin.point(actor)) == Some{monster} : Maybe<&2,M.Monsters.State>}
  for +unique: I.Identity.Monsters(monsters)
  for +enough: Lethal.Lethal.TuningEnough(monster,tuning)
  for +inside: Member.Targeting.In<actor,players>
  for +same: {P.Players.id(actor) == pid : U32}
  AttackOnce.Prefix<monster,L.LiveCombat.finish(L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,Some{actor}},pid,score},Attack.LiveAttack.finish(monsters,actor,tuning))>

def AttackOnce.selected_tuning(meta,players,monsters,maps,actor,pid,score,monster,tuning,selected,unique,enough,inside,same):
  match tuning:
    case Attack.LiveAttack.Tuning{crit,build}: AttackOnce.selected_attack(meta,players,monsters,maps,actor,pid,score,crit,monster,build,selected,unique,enough,inside,same)


law AttackOnce.planned:
  for +ready: L.LiveCombat.Ready
  for +monster: M.Monsters.State
  for build: Attack.LiveAttack.Builder
  for +criteria: Lethal.Lethal.Criteria(ready,monster)
  for +valid: Admit.Admitted.Ready(ready)
  for +enough: Lethal.Lethal.BuiltEnough(ready,monster,build)
  AttackOnce.Prefix<monster,L.LiveCombat.finish(ready,Attack.LiveAttack.plan(ready,build))>

def AttackOnce.planned(ready,monster,build,criteria,valid,enough):
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}: Empty.absurd(AttackOnce.Prefix<monster,L.LiveCombat.finish(L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,None{}},pid,score},Attack.LiveAttack.plan(L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,None{}},pid,score},build))>,criteria)
            case Some{player}:
              match criteria:
                case Tuple{selected,unique}:
                  match valid:
                    case Tuple{inside,same}: AttackOnce.selected_tuning(meta,players,monsters,maps,player,pid,score,monster,build(monsters,player,meta,pid),selected,unique,enough,inside,same)


law AttackOnce.live:
  for +world: T.Terrain.World
  for +pid: U32
  for +score: U32
  for +monster: M.Monsters.State
  for build: Attack.LiveAttack.Builder
  for +criteria: Lethal.Lethal.Criteria(L.LiveCombat.prepare(world,C.Combat.Attack{},pid,score),monster)
  for +enough: Lethal.Lethal.BuiltEnough(L.LiveCombat.prepare(world,C.Combat.Attack{},pid,score),monster,build)
  AttackOnce.Prefix<monster,L.LiveCombat.run(world,C.Combat.Attack{},pid,score,(ready => Attack.LiveAttack.plan(ready,build)))>

def AttackOnce.live(world,pid,score,monster,build,criteria,enough): AttackOnce.planned(L.LiveCombat.prepare(world,C.Combat.Attack{},pid,score),monster,build,criteria,Admit.Admitted.live_prepare(world,C.Combat.Attack{},pid,score),enough)

# Continue from the actual output world, including its original maps.
law AttackOnce.after_result:
  for requests: List<&1,LD.LiveDead.Request>
  for +monster: M.Monsters.State
  for +damage: U32
  for +first: L.LiveCombat.Result
  for +once: Once.Once.Certificate<monster,damage,AttackOnce.view(first)>
  LD.LiveDead.OnceTrace<monster,damage,AttackOnce.view(first),LD.LiveDead.trace(requests,L.LiveCombat.world(first))>

def AttackOnce.after_result(requests,monster,damage,first,once):
  %T.Terrain.world_roundtrip(L.LiveCombat.world(first)) : LD.LiveDead.OnceTrace<monster,damage,AttackOnce.view(first),LD.LiveDead.trace(requests,_)>
  LD.LiveDead.after_once(requests,monster,damage,AttackOnce.view(first),T.Terrain.maps(L.LiveCombat.world(first)),once)

# Both actual outputs are retained. The erased indices identify the full
# original attack and request stream without evaluating either callback twice.
type AttackOnce.History<-monster: M.Monsters.State,-first: L.LiveCombat.Result,-requests: List<&1,LD.LiveDead.Request>> is Data:
  AttackOnce.History{actual: L.LiveCombat.Result,same: {actual == first : L.LiveCombat.Result},damage: U32,once: Once.Once.Certificate<monster,damage,AttackOnce.view(actual)>,suffix: LD.LiveDead.OnceTrace<monster,damage,AttackOnce.view(actual),LD.LiveDead.trace(requests,L.LiveCombat.world(actual))>}

law AttackOnce.extend:
  for requests: List<&1,LD.LiveDead.Request>
  for +monster: M.Monsters.State
  for -first: L.LiveCombat.Result
  for +prefix: AttackOnce.Prefix<monster,first>
  AttackOnce.History<monster,first,requests>

def AttackOnce.extend(requests,monster,first,prefix):
  match prefix:
    case AttackOnce.Prefix{actual,same,damage,once}:
      AttackOnce.History{actual,same,damage,once,AttackOnce.after_result(requests,monster,damage,actual,once)}

law AttackOnce.live_history:
  for requests: List<&1,LD.LiveDead.Request>
  for +world: T.Terrain.World
  for +pid: U32
  for +score: U32
  for +monster: M.Monsters.State
  for build: Attack.LiveAttack.Builder
  for +criteria: Lethal.Lethal.Criteria(L.LiveCombat.prepare(world,C.Combat.Attack{},pid,score),monster)
  for +enough: Lethal.Lethal.BuiltEnough(L.LiveCombat.prepare(world,C.Combat.Attack{},pid,score),monster,build)
  AttackOnce.History<monster,L.LiveCombat.run(world,C.Combat.Attack{},pid,score,(ready => Attack.LiveAttack.plan(ready,build))),requests>

def AttackOnce.live_history(requests,world,pid,score,monster,build,criteria,enough):
  AttackOnce.extend(requests,monster,L.LiveCombat.run(world,C.Combat.Attack{},pid,score,(ready => Attack.LiveAttack.plan(ready,build))),AttackOnce.live(world,pid,score,monster,build,criteria,enough))

law AttackOnce.exactly_once:
  for +monster: M.Monsters.State
  for -first: L.LiveCombat.Result
  for -requests: List<&1,LD.LiveDead.Request>
  for +history: AttackOnce.History<monster,first,requests>
  {Dead.Dead.count(R.Roster.id(monster),B.Battle.concat(L.LiveCombat.notices(first),LD.LiveDead.notices(LD.LiveDead.trace(requests,L.LiveCombat.world(first))))) == 1n : Nat}

def AttackOnce.exactly_once(monster,first,requests,history):
  match history:
    case AttackOnce.History{actual,same,damage,once,suffix}:
      %same : {Dead.Dead.count(R.Roster.id(monster),B.Battle.concat(L.LiveCombat.notices(_),LD.LiveDead.notices(LD.LiveDead.trace(requests,L.LiveCombat.world(_))))) == 1n : Nat}
      LD.LiveDead.exactly_once(monster,damage,AttackOnce.view(actual),LD.LiveDead.trace(requests,L.LiveCombat.world(actual)),suffix)

law AttackOnce.live_exactly_once:
  for requests: List<&1,LD.LiveDead.Request>
  for +world: T.Terrain.World
  for +pid: U32
  for +score: U32
  for +monster: M.Monsters.State
  for build: Attack.LiveAttack.Builder
  for +criteria: Lethal.Lethal.Criteria(L.LiveCombat.prepare(world,C.Combat.Attack{},pid,score),monster)
  for +enough: Lethal.Lethal.BuiltEnough(L.LiveCombat.prepare(world,C.Combat.Attack{},pid,score),monster,build)
  {Dead.Dead.count(R.Roster.id(monster),B.Battle.concat(L.LiveCombat.notices(L.LiveCombat.run(world,C.Combat.Attack{},pid,score,(ready => Attack.LiveAttack.plan(ready,build)))),LD.LiveDead.notices(LD.LiveDead.trace(requests,L.LiveCombat.world(L.LiveCombat.run(world,C.Combat.Attack{},pid,score,(ready => Attack.LiveAttack.plan(ready,build)))))))) == 1n : Nat}

def AttackOnce.live_exactly_once(requests,world,pid,score,monster,build,criteria,enough):
  AttackOnce.exactly_once(monster,L.LiveCombat.run(world,C.Combat.Attack{},pid,score,(ready => Attack.LiveAttack.plan(ready,build))),requests,AttackOnce.live_history(requests,world,pid,score,monster,build,criteria,enough))
