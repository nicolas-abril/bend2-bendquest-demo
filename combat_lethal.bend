# Positive lethal-strike and actual attack reward liveness.
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

def Lethal.Enough(monster: M.Monsters.State,damage: U32) -> Data:
  {G.Bq.Nat.le(U32.to_nat(V.Vitals.hp(M.Monsters.vitals(monster))),U32.to_nat(damage)) == True{} : Bool}

def Lethal.info(monster: M.Monsters.State) -> R.Roster.Kill:
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}: R.Roster.Kill{kind,rare,zone,mid}

law Lethal.result_reported:
  for +hit: M.Monsters.Hit
  for +others: List<&2,M.Monsters.State>
  for +killed: {M.Monsters.killed(hit) == True{} : Bool}
  {B.Battle.kill(R.Roster.strike_result(hit,others)) == Some{Lethal.info(M.Monsters.result(hit))} : Maybe<&2,R.Roster.Kill>}

def Lethal.result_reported(hit,others,killed):
  match hit:
    case M.Monsters.Hit{monster,reported,dealt}:
      match monster:
        case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}:
          %Equal.sym(Bool,reported,True{},killed) : {B.Battle.kill(R.Roster.strike_result(M.Monsters.Hit{M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn},_,dealt},others)) == Some{R.Roster.Kill{kind,rare,zone,mid}} : Maybe<&2,R.Roster.Kill>}
          {==}

law Lethal.info_finish:
  for +monster: M.Monsters.State
  for +hit: V.Vitals.Hit
  for +damage: U32
  {Lethal.info(M.Monsters.result(M.Monsters.finish(monster,hit,damage))) == Lethal.info(monster) : R.Roster.Kill}

def Lethal.info_finish(monster,hit,damage):
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}:
      match hit:
        case V.Vitals.Hit{next,fell}:
          match next:
            case V.Vitals.State{hp2,xp2,dead2,respawn2,attack2,spin2}: {==}

law Lethal.info_gate:
  for +dead: Bool
  for +monster: M.Monsters.State
  for +damage: U32
  for +timer: U32
  {Lethal.info(M.Monsters.result(M.Monsters.hit_gate(dead,monster,damage,timer))) == Lethal.info(monster) : R.Roster.Kill}

def Lethal.info_gate(dead,monster,damage,timer):
  match dead:
    case True{}: {==}
    case False{}: Lethal.info_finish(monster,V.Vitals.hit_gate(False{},M.Monsters.vitals(monster),damage,timer),damage)

law Lethal.info_hit:
  for +monster: M.Monsters.State
  for +damage: U32
  for +timer: U32
  {Lethal.info(M.Monsters.result(M.Monsters.hit(monster,damage,timer))) == Lethal.info(monster) : R.Roster.Kill}

def Lethal.info_hit(monster,damage,timer): Lethal.info_gate(U32.is_eq(V.Vitals.dead(M.Monsters.vitals(monster)),1),monster,damage,timer)

law Lethal.taken_reported:
  for +taken: R.Roster.Take
  for +monster: M.Monsters.State
  for +damage: U32
  for +found: {R.Roster.found(taken) == Some{monster} : Maybe<&2,M.Monsters.State>}
  for +alive: {V.Vitals.dead(M.Monsters.vitals(monster)) == 0 : U32}
  for +enough: Lethal.Enough(monster,damage)
  {B.Battle.kill(R.Roster.strike_taken(taken,damage)) == Some{Lethal.info(monster)} : Maybe<&2,R.Roster.Kill>}

def Lethal.taken_reported(taken,monster,damage,found,alive,enough):
  match taken:
    case R.Roster.Take{others,selected}:
      %Equal.sym(Maybe<&2,M.Monsters.State>,selected,Some{monster},found) : {B.Battle.kill(R.Roster.strike_taken(R.Roster.Take{others,_},damage)) == Some{Lethal.info(monster)} : Maybe<&2,R.Roster.Kill>}
      %Lethal.info_hit(monster,damage,R.Roster.respawn_time(M.Monsters.kind(monster))) : {B.Battle.kill(R.Roster.strike_result(M.Monsters.hit(monster,damage,R.Roster.respawn_time(M.Monsters.kind(monster))),others)) == Some{_} : Maybe<&2,R.Roster.Kill>}
      Lethal.result_reported(M.Monsters.hit(monster,damage,R.Roster.respawn_time(M.Monsters.kind(monster))),others,M.Monsters.lethal_hit_reports_kill(monster,damage,R.Roster.respawn_time(M.Monsters.kind(monster)),alive,enough))

law Lethal.dead_field:
  for +monster: M.Monsters.State
  {Targets.Targets.dead(monster) == V.Vitals.dead(M.Monsters.vitals(monster)) : U32}

def Lethal.dead_field(monster):
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}: {==}

law Lethal.source_reported:
  for +monsters: List<&2,M.Monsters.State>
  for +point: Targets.Targets.Point
  for +monster: M.Monsters.State
  for +damage: U32
  for +source: Targets.Targets.Source<monsters,point,monster>
  for +unique: I.Identity.Monsters(monsters)
  for +enough: Lethal.Enough(monster,damage)
  {B.Battle.kill(R.Roster.strike(monsters,R.Roster.id(monster),damage)) == Some{Lethal.info(monster)} : Maybe<&2,R.Roster.Kill>}

def Lethal.source_reported(monsters,point,monster,damage,source,unique,enough):
  match source:
    case Targets.Targets.Source{inside,eligible}:
      Lethal.taken_reported(R.Roster.take(monsters,R.Roster.id(monster)),monster,damage,Targets.Targets.lookup_member(monster,monsters,inside,unique),(%Lethal.dead_field(monster) : {_ == 0 : U32}; Targets.Targets.eligible_alive(monster,point,eligible)),enough)

law Lethal.reward:
  for +state: S.Simulation.State
  for +point: Targets.Targets.Point
  for +monster: M.Monsters.State
  for +damage: U32
  for +payout: Pay.Payout.Plan
  for +pid: U32
  for +score: U32
  for +source: Targets.Targets.Source<S.Simulation.monsters(state),point,monster>
  for +unique: I.Identity.Monsters(S.Simulation.monsters(state))
  for +enough: Lethal.Enough(monster,damage)
  for +present: {P.Players.has_id(S.Simulation.players(state),pid) == True{} : Bool}
  {B.Battle.notice_count(B.Battle.notices(B.Battle.strike(B.Battle.Input{R.Roster.id(monster),damage,payout},state,pid,score))) == 1n : Nat}

def Lethal.reward(state,point,monster,damage,payout,pid,score,source,unique,enough,present):
  B.Battle.strike_reported(R.Roster.id(monster),damage,payout,state,pid,score,Lethal.info(monster),Lethal.source_reported(S.Simulation.monsters(state),point,monster,damage,source,unique,enough),present)

law Lethal.concat_nil:
  for +notices: List<&2,B.Battle.Notice>
  {B.Battle.concat(notices,Nil{}) == notices : List<&2,B.Battle.Notice>}

def Lethal.concat_nil(notices):
  match notices:
    case Nil{}: {==}
    case Con{head,rest}:
      %Lethal.concat_nil(rest) : {Con{head,B.Battle.concat(rest,Nil{})} == Con{head,_} : List<&2,B.Battle.Notice>}
      {==}

law Lethal.singleton:
  for +input: B.Battle.Input
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  {B.Battle.notices(B.Battle.run([input],state,pid,score)) == B.Battle.notices(B.Battle.strike(input,state,pid,score)) : List<&2,B.Battle.Notice>}

def Lethal.singleton(input,state,pid,score): Lethal.concat_nil(B.Battle.notices(B.Battle.strike(input,state,pid,score)))

def Lethal.damage(power: TP.TargetPlans.Power) -> U32:
  match power:
    case TP.TargetPlans.Power{damage,payout}: damage

law Lethal.ready_reward:
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
  for +enough: Lethal.Enough(monster,Lethal.damage(power))
  for +present: {P.Players.has_id(players,pid) == True{} : Bool}
  {B.Battle.notice_count(L.LiveCombat.notices(L.LiveCombat.finish(L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,Some{actor}},pid,score},TP.TargetPlans.ready(monster,point,dir,crit,power)))) == 1n : Nat}

def Lethal.ready_reward(meta,players,monsters,maps,actor,pid,score,monster,point,dir,crit,power,source,unique,enough,present):
  match point:
    case Targets.Targets.Point{zone,x,y}:
      match power:
        case TP.TargetPlans.Power{damage,payout}:
          %Equal.sym(List<&2,B.Battle.Notice>,L.LiveCombat.notices(L.LiveCombat.pack(B.Battle.run([B.Battle.Input{R.Roster.id(monster),damage,payout}],S.Simulation.State{meta,players,monsters},pid,score),maps,L.LiveCombat.Attack{zone,x,y,dir,R.Roster.id(monster),crit})),B.Battle.notices(B.Battle.run([B.Battle.Input{R.Roster.id(monster),damage,payout}],S.Simulation.State{meta,players,monsters},pid,score)),L.LiveCombat.pack_notices(B.Battle.run([B.Battle.Input{R.Roster.id(monster),damage,payout}],S.Simulation.State{meta,players,monsters},pid,score),maps,L.LiveCombat.Attack{zone,x,y,dir,R.Roster.id(monster),crit})) : {B.Battle.notice_count(_) == 1n : Nat}
          %Equal.sym(List<&2,B.Battle.Notice>,B.Battle.notices(B.Battle.run([B.Battle.Input{R.Roster.id(monster),damage,payout}],S.Simulation.State{meta,players,monsters},pid,score)),B.Battle.notices(B.Battle.strike(B.Battle.Input{R.Roster.id(monster),damage,payout},S.Simulation.State{meta,players,monsters},pid,score)),Lethal.singleton(B.Battle.Input{R.Roster.id(monster),damage,payout},S.Simulation.State{meta,players,monsters},pid,score)) : {B.Battle.notice_count(_) == 1n : Nat}
          Lethal.reward(S.Simulation.State{meta,players,monsters},Targets.Targets.Point{zone,x,y},monster,damage,payout,pid,score,source,unique,enough,present)

def Lethal.rejected_head(-head: M.Monsters.State,-rest: List<&2,M.Monsters.State>,-point: Targets.Targets.Point,rejected: Targets.Targets.Rejected(Con{head,rest},point)) -> {Targets.Targets.eligible(head,point) == False{} : Bool}:
  match rejected:
    case Tuple{first,tail}: first

def Lethal.rejected_tail(-head: M.Monsters.State,-rest: List<&2,M.Monsters.State>,-point: Targets.Targets.Point,rejected: Targets.Targets.Rejected(Con{head,rest},point)) -> Targets.Targets.Rejected(rest,point):
  match rejected:
    case Tuple{first,tail}: tail

law Lethal.rejected_member:
  for +monster: M.Monsters.State
  for -monsters: List<&2,M.Monsters.State>
  for +point: Targets.Targets.Point
  for +inside: Targets.Targets.In<monster,monsters>
  for +rejected: Targets.Targets.Rejected(monsters,point)
  {Targets.Targets.eligible(monster,point) == False{} : Bool}

def Lethal.rejected_member(monster,monsters,point,inside,rejected):
  match inside:
    case Targets.Targets.Here{rest,shape}:
      Lethal.rejected_head(monster,rest,point,(%shape : Targets.Targets.Rejected(_,point); rejected))
    case Targets.Targets.There{head,rest,shape,earlier}:
      Lethal.rejected_member(monster,rest,point,earlier,Lethal.rejected_tail(head,rest,point,(%shape : Targets.Targets.Rejected(_,point); rejected)))

type Lethal.Selection<-monsters: List<&2,M.Monsters.State>,-point: Targets.Targets.Point> is Data:
  Lethal.Selection{monster: M.Monsters.State,selected: {Targets.Targets.first(monsters,point) == Some{monster} : Maybe<&2,M.Monsters.State>},source: Targets.Targets.Source<monsters,point,monster>}

law Lethal.choose:
  for +found: Maybe<&2,M.Monsters.State>
  for +monsters: List<&2,M.Monsters.State>
  for +point: Targets.Targets.Point
  for +witness: M.Monsters.State
  for +source: Targets.Targets.Source<monsters,point,witness>
  for +selected: {Targets.Targets.first(monsters,point) == found : Maybe<&2,M.Monsters.State>}
  Lethal.Selection<monsters,point>

def Lethal.choose(found,monsters,point,witness,source,selected):
  match found:
    case None{}:
      match source:
        case Targets.Targets.Source{inside,eligible}:
          Empty.absurd(Lethal.Selection<monsters,point>,N.Numeric.true_ne_false(Equal.trans(Bool,True{},Targets.Targets.eligible(witness,point),False{},Equal.sym(Bool,Targets.Targets.eligible(witness,point),True{},eligible),Lethal.rejected_member(witness,monsters,point,inside,Targets.Targets.first_none_rejected(monsters,point,selected)))))
    case Some{monster}: Lethal.Selection{monster,selected,(%selected : Targets.Targets.FoundSource(monsters,point,_); Targets.Targets.first_source(monsters,point))}

law Lethal.select:
  for +monsters: List<&2,M.Monsters.State>
  for +point: Targets.Targets.Point
  for +witness: M.Monsters.State
  for +source: Targets.Targets.Source<monsters,point,witness>
  Lethal.Selection<monsters,point>

def Lethal.select(monsters,point,witness,source): Lethal.choose(Targets.Targets.first(monsters,point),monsters,point,witness,source,{==})

law Lethal.selected_attack:
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
  for +enough: Lethal.Enough(monster,Lethal.damage(build(monster)))
  for +inside: Member.Targeting.In<actor,players>
  for +same: {P.Players.id(actor) == pid : U32}
  {B.Battle.notice_count(L.LiveCombat.notices(L.LiveCombat.finish(L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,Some{actor}},pid,score},Attack.LiveAttack.finish(monsters,actor,Attack.LiveAttack.Tuning{crit,build})))) == 1n : Nat}

def Lethal.selected_attack(meta,players,monsters,maps,actor,pid,score,crit,monster,build,selected,unique,enough,inside,same):
  %Equal.sym(Maybe<&2,M.Monsters.State>,Targets.Targets.first(monsters,Spin.LiveSpin.point(actor)),Some{monster},selected) : {B.Battle.notice_count(L.LiveCombat.notices(L.LiveCombat.finish(L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,Some{actor}},pid,score},TP.TargetPlans.attack(_,Spin.LiveSpin.point(actor),Attack.LiveAttack.direction(actor),crit,build)))) == 1n : Nat}
  Lethal.ready_reward(meta,players,monsters,maps,actor,pid,score,monster,Spin.LiveSpin.point(actor),Attack.LiveAttack.direction(actor),crit,build(monster),(%selected : Targets.Targets.FoundSource(monsters,Spin.LiveSpin.point(actor),_); Targets.Targets.first_source(monsters,Spin.LiveSpin.point(actor))),unique,enough,(%same : {P.Players.has_id(players,_) == True{} : Bool}; Member.Targeting.in_has(actor,players,inside)))

# These conditions concern the actual prepared world. They require an admitted
# actor and the actual first selected monster; no assumed hit or reward result.
def Lethal.Criteria(ready: L.LiveCombat.Ready,+monster: M.Monsters.State) -> Data:
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}: Empty
            case Some{player}: Sigma<&2,&2,{Targets.Targets.first(monsters,Spin.LiveSpin.point(player)) == Some{monster} : Maybe<&2,M.Monsters.State>},(selected => I.Identity.Monsters(monsters))>

def Lethal.TuningEnough(+monster: M.Monsters.State,tuning: Attack.LiveAttack.Tuning) -> Data:
  match tuning:
    case Attack.LiveAttack.Tuning{crit,build}: Lethal.Enough(monster,Lethal.damage(build(monster)))

law Lethal.selected_tuning:
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
  for +enough: Lethal.TuningEnough(monster,tuning)
  for +inside: Member.Targeting.In<actor,players>
  for +same: {P.Players.id(actor) == pid : U32}
  {B.Battle.notice_count(L.LiveCombat.notices(L.LiveCombat.finish(L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,Some{actor}},pid,score},Attack.LiveAttack.finish(monsters,actor,tuning)))) == 1n : Nat}

def Lethal.selected_tuning(meta,players,monsters,maps,actor,pid,score,monster,tuning,selected,unique,enough,inside,same):
  match tuning:
    case Attack.LiveAttack.Tuning{crit,build}: Lethal.selected_attack(meta,players,monsters,maps,actor,pid,score,crit,monster,build,selected,unique,enough,inside,same)

# The sufficient-damage premise evaluates the same calculator on the same
# actual prepared inputs and selected monster. Runtime callbacks remain affine.
def Lethal.BuiltEnough(ready: L.LiveCombat.Ready,+monster: M.Monsters.State,build: Attack.LiveAttack.Builder) -> Data:
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}: Unit
            case Some{player}: Lethal.TuningEnough(monster,build(monsters,player,meta,pid))

law Lethal.planned:
  for +ready: L.LiveCombat.Ready
  for +monster: M.Monsters.State
  for build: Attack.LiveAttack.Builder
  for +criteria: Lethal.Criteria(ready,monster)
  for +valid: Admit.Admitted.Ready(ready)
  for +enough: Lethal.BuiltEnough(ready,monster,build)
  {B.Battle.notice_count(L.LiveCombat.notices(L.LiveCombat.finish(ready,Attack.LiveAttack.plan(ready,build)))) == 1n : Nat}

def Lethal.planned(ready,monster,build,criteria,valid,enough):
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}: Empty.absurd({B.Battle.notice_count(L.LiveCombat.notices(L.LiveCombat.finish(L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,None{}},pid,score},Attack.LiveAttack.plan(L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,None{}},pid,score},build)))) == 1n : Nat},criteria)
            case Some{player}:
              match criteria:
                case Tuple{selected,unique}:
                  match valid:
                    case Tuple{inside,same}: Lethal.selected_tuning(meta,players,monsters,maps,player,pid,score,monster,build(monsters,player,meta,pid),selected,unique,enough,inside,same)

law Lethal.live:
  for +world: T.Terrain.World
  for +pid: U32
  for +score: U32
  for +monster: M.Monsters.State
  for build: Attack.LiveAttack.Builder
  for +criteria: Lethal.Criteria(L.LiveCombat.prepare(world,C.Combat.Attack{},pid,score),monster)
  for +enough: Lethal.BuiltEnough(L.LiveCombat.prepare(world,C.Combat.Attack{},pid,score),monster,build)
  {B.Battle.notice_count(L.LiveCombat.notices(L.LiveCombat.run(world,C.Combat.Attack{},pid,score,(ready => Attack.LiveAttack.plan(ready,build))))) == 1n : Nat}

def Lethal.live(world,pid,score,monster,build,criteria,enough): Lethal.planned(L.LiveCombat.prepare(world,C.Combat.Attack{},pid,score),monster,build,criteria,Admit.Admitted.live_prepare(world,C.Combat.Attack{},pid,score),enough)
