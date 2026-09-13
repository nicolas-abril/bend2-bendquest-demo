# Exact reward count for the actual ordered spin and its selected powers.
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

# Every bound power must actually kill its own selected complete record.
def SpinKill.Enough(selected: List<&2,M.Monsters.State>,powers: Plan.SpinPlans.Powers(selected)) -> Data:
  match selected:
    case Nil{}: Unit
    case Con{head,rest}:
      match powers:
        case Tuple{power,later}: Sigma<&2,&2,Kill.Lethal.Enough(head,Kill.Lethal.damage(power)),(enough => SpinKill.Enough(rest,later))>

law SpinKill.member_has:
  for +original: P.Players.State
  for -players: List<&2,P.Players.State>
  for +member: Actor.Actor.Member<original,players>
  {P.Players.has_id(players,P.Players.id(original)) == True{} : Bool}

def SpinKill.member_has(original,players,member):
  match member:
    case Actor.Actor.Member{after,inside,same}:
      %Actor.Actor.same_pid(after,original,same) : {P.Players.has_id(players,_) == True{} : Bool}
      Member.Targeting.in_has(after,players,inside)

law SpinKill.concat_count:
  for +left: List<&2,B.Battle.Notice>
  for +right: List<&2,B.Battle.Notice>
  {B.Battle.notice_count(B.Battle.concat(left,right)) == Nat.add(B.Battle.notice_count(left),B.Battle.notice_count(right)) : Nat}

def SpinKill.concat_count(left,right):
  match left:
    case Nil{}: {==}
    case Con{head,rest}:
      Equal.cong(Nat,Nat,(n => Succ{n}),B.Battle.notice_count(B.Battle.concat(rest,right)),Nat.add(B.Battle.notice_count(rest),B.Battle.notice_count(right)),SpinKill.concat_count(rest,right))

law SpinKill.one_more:
  for +first: B.Battle.Result
  for +second: B.Battle.Result
  for +count: Nat
  for +one: {B.Battle.notice_count(B.Battle.notices(first)) == 1n : Nat}
  for +later: {B.Battle.notice_count(B.Battle.notices(second)) == count : Nat}
  {B.Battle.notice_count(B.Battle.notices(B.Battle.before(first,second))) == Succ{count} : Nat}

def SpinKill.one_more(first,second,count,one,later):
  %Equal.sym(Nat,B.Battle.notice_count(B.Battle.concat(B.Battle.notices(first),B.Battle.notices(second))),Nat.add(B.Battle.notice_count(B.Battle.notices(first)),B.Battle.notice_count(B.Battle.notices(second))),SpinKill.concat_count(B.Battle.notices(first),B.Battle.notices(second))) : {_ == Succ{count} : Nat}
  %Equal.sym(Nat,B.Battle.notice_count(B.Battle.notices(first)),1n,one) : {Nat.add(_,B.Battle.notice_count(B.Battle.notices(second))) == Succ{count} : Nat}
  %Equal.sym(Nat,B.Battle.notice_count(B.Battle.notices(second)),count,later) : {Succ{_} == Succ{count} : Nat}
  {==}

law SpinKill.input_reward:
  for +monster: M.Monsters.State
  for +power: TP.TargetPlans.Power
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
  {B.Battle.notice_count(B.Battle.notices(B.Battle.strike(Plan.SpinPlans.input(monster,power),state,pid,score))) == 1n : Nat}

def SpinKill.input_reward(monster,power,state,original,pid,score,point,source,unique,member,same,enough):
  match power:
    case TP.TargetPlans.Power{damage,payout}:
      Kill.Lethal.reward(state,point,monster,damage,payout,pid,score,source,unique,enough,(%same : {P.Players.has_id(S.Simulation.players(state),_) == True{} : Bool}; SpinKill.member_has(original,S.Simulation.players(state),member)))

law SpinKill.run:
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
  for +enough: SpinKill.Enough(selected,powers)
  {B.Battle.notice_count(B.Battle.notices(B.Battle.run(Plan.SpinPlans.inputs(selected,powers),state,pid,score))) == R.Roster.length(selected) : Nat}

def SpinKill.run(selected,powers,state,original,pid,score,point,sources,unique,selected_unique,member,same,enough):
  match selected:
    case Nil{}: {==}
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
                      SpinKill.one_more(B.Battle.strike(input,state,pid,score),B.Battle.run(Plan.SpinPlans.inputs(rest,later_powers),B.Battle.state(B.Battle.strike(input,state,pid,score)),pid,score),R.Roster.length(rest),SpinKill.input_reward(head,power,state,original,pid,score,point,source,unique,member,same,first_enough),SpinKill.run(rest,later_powers,B.Battle.state(B.Battle.strike(input,state,pid,score)),original,pid,score,point,Frame.CombatFrame.survivor_sources(rest,input,state,pid,score,point,later_sources,other_ids),I.Identity.battle_strike_unique(input,state,pid,score,unique),remaining_unique,Actor.Actor.battle_strike(original,input,state,pid,score,member),same,later_enough))

law SpinKill.ready:
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
  for +enough: SpinKill.Enough(selected,powers)
  {B.Battle.notice_count(L.LiveCombat.notices(L.LiveCombat.finish(L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,Some{actor}},pid,score},Plan.SpinPlans.ready(selected,point,powers)))) == R.Roster.length(selected) : Nat}

def SpinKill.ready(meta,players,monsters,maps,actor,pid,score,selected,point,powers,sources,unique,selected_unique,inside,same,enough):
  match point:
    case Targets.Targets.Point{zone,x,y}:
      %Equal.sym(List<&2,B.Battle.Notice>,L.LiveCombat.notices(L.LiveCombat.pack(B.Battle.run(Plan.SpinPlans.inputs(selected,powers),S.Simulation.State{meta,players,monsters},pid,score),maps,L.LiveCombat.Spin{zone,x,y})),B.Battle.notices(B.Battle.run(Plan.SpinPlans.inputs(selected,powers),S.Simulation.State{meta,players,monsters},pid,score)),L.LiveCombat.pack_notices(B.Battle.run(Plan.SpinPlans.inputs(selected,powers),S.Simulation.State{meta,players,monsters},pid,score),maps,L.LiveCombat.Spin{zone,x,y})) : {B.Battle.notice_count(_) == R.Roster.length(selected) : Nat}
      SpinKill.run(selected,powers,S.Simulation.State{meta,players,monsters},actor,pid,score,Targets.Targets.Point{zone,x,y},sources,unique,selected_unique,Actor.Actor.Member{actor,inside,{==}},same,enough)

law SpinKill.filtered:
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
  for +enough: SpinKill.Enough(Targets.Targets.filter(monsters,Spin.LiveSpin.point(actor)),build(Targets.Targets.filter(monsters,Spin.LiveSpin.point(actor))))
  {B.Battle.notice_count(L.LiveCombat.notices(L.LiveCombat.finish(L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,Some{actor}},pid,score},Plan.SpinPlans.run(monsters,Spin.LiveSpin.point(actor),build)))) == R.Roster.length(Targets.Targets.filter(monsters,Spin.LiveSpin.point(actor))) : Nat}

def SpinKill.filtered(meta,players,monsters,maps,actor,pid,score,build,unique,inside,same,enough):
  +selected = Targets.Targets.filter(monsters,Spin.LiveSpin.point(actor))
  SpinKill.ready(meta,players,monsters,maps,actor,pid,score,selected,Spin.LiveSpin.point(actor),build(selected),Targets.Targets.filter_sources(monsters,Spin.LiveSpin.point(actor)),unique,Targets.Targets.filter_unique(monsters,Spin.LiveSpin.point(actor),unique),inside,same,enough)

# A rejected admission has no selected targets. An admitted spin selects every
# eligible monster, including the empty-list case.
def SpinKill.count(ready: L.LiveCombat.Ready) -> Nat:
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}: 0n
            case Some{player}: R.Roster.length(Targets.Targets.filter(monsters,Spin.LiveSpin.point(player)))

def SpinKill.BuiltEnough(ready: L.LiveCombat.Ready,build: Spin.LiveSpin.Builder) -> Data:
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}: Unit
            case Some{player}:
              +player = player
              +monsters = monsters
              +selected = Targets.Targets.filter(monsters,Spin.LiveSpin.point(player))
              SpinKill.Enough(selected,build(monsters,player,meta,selected))

law SpinKill.planned:
  for +ready: L.LiveCombat.Ready
  for build: Spin.LiveSpin.Builder
  for +valid: Admit.Admitted.Ready(ready)
  for +unique: Spin.LiveSpin.Unique(ready)
  for +enough: SpinKill.BuiltEnough(ready,build)
  {B.Battle.notice_count(L.LiveCombat.notices(L.LiveCombat.finish(ready,Spin.LiveSpin.plan(ready,build)))) == SpinKill.count(ready) : Nat}

def SpinKill.planned(ready,build,valid,unique,enough):
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}: {==}
            case Some{player}:
              match valid:
                case Tuple{inside,same}: SpinKill.filtered(meta,players,monsters,maps,player,pid,score,build(monsters,player,meta),unique,inside,same,enough)

law SpinKill.live:
  for +world: T.Terrain.World
  for +pid: U32
  for +score: U32
  for build: Spin.LiveSpin.Builder
  for +unique: I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(world)))
  for +enough: SpinKill.BuiltEnough(L.LiveCombat.prepare(world,C.Combat.Spin{},pid,score),build)
  {B.Battle.notice_count(L.LiveCombat.notices(L.LiveCombat.run(world,C.Combat.Spin{},pid,score,(ready => Spin.LiveSpin.plan(ready,build))))) == SpinKill.count(L.LiveCombat.prepare(world,C.Combat.Spin{},pid,score)) : Nat}

def SpinKill.live(world,pid,score,build,unique,enough): SpinKill.planned(L.LiveCombat.prepare(world,C.Combat.Spin{},pid,score),build,Admit.Admitted.live_prepare(world,C.Combat.Spin{},pid,score),Spin.LiveSpin.prepare_unique(world,pid,score,unique),enough)

# Each report refers to the actual roster immediately before its own hit and
# names the original selected monster. This exposes individual reports as well
# as the aggregate count, including hits after a phase-changing boss reward.
def SpinKill.Reports(selected: List<&2,M.Monsters.State>,powers: Plan.SpinPlans.Powers(selected),+state: S.Simulation.State,+pid: U32,+score: U32) -> Data:
  match selected:
    case Nil{}: Unit
    case Con{head,rest}:
      match powers:
        case Tuple{power,later}:
          +head = head
          +power = power
          Sigma<&2,&2,{B.Battle.kill(R.Roster.strike(S.Simulation.monsters(state),R.Roster.id(head),Kill.Lethal.damage(power))) == Some{Kill.Lethal.info(head)} : Maybe<&2,R.Roster.Kill>},(reported => SpinKill.Reports(rest,later,B.Battle.state(B.Battle.strike(Plan.SpinPlans.input(head,power),state,pid,score)),pid,score))>

law SpinKill.reports:
  for +selected: List<&2,M.Monsters.State>
  for +powers: Plan.SpinPlans.Powers(selected)
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +point: Targets.Targets.Point
  for +sources: Targets.Targets.Sources(S.Simulation.monsters(state),point,selected)
  for +unique: I.Identity.Monsters(S.Simulation.monsters(state))
  for +selected_unique: I.Identity.Monsters(selected)
  for +enough: SpinKill.Enough(selected,powers)
  SpinKill.Reports(selected,powers,state,pid,score)

def SpinKill.reports(selected,powers,state,pid,score,point,sources,unique,selected_unique,enough):
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
                      Tuple{Kill.Lethal.source_reported(S.Simulation.monsters(state),point,head,Kill.Lethal.damage(power),source,unique,first_enough),SpinKill.reports(rest,later_powers,B.Battle.state(B.Battle.strike(input,state,pid,score)),pid,score,point,Frame.CombatFrame.survivor_sources(rest,input,state,pid,score,point,later_sources,other_ids),I.Identity.battle_strike_unique(input,state,pid,score,unique),remaining_unique,later_enough)}

law SpinKill.filtered_reports:
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +point: Targets.Targets.Point
  for build: (@+selected: List<&2,M.Monsters.State> -> Plan.SpinPlans.Powers(selected))
  for +unique: I.Identity.Monsters(S.Simulation.monsters(state))
  for +enough: SpinKill.Enough(Targets.Targets.filter(S.Simulation.monsters(state),point),build(Targets.Targets.filter(S.Simulation.monsters(state),point)))
  SpinKill.Reports(Targets.Targets.filter(S.Simulation.monsters(state),point),build(Targets.Targets.filter(S.Simulation.monsters(state),point)),state,pid,score)

def SpinKill.filtered_reports(state,pid,score,point,build,unique,enough):
  +selected = Targets.Targets.filter(S.Simulation.monsters(state),point)
  SpinKill.reports(selected,build(selected),state,pid,score,point,Targets.Targets.filter_sources(S.Simulation.monsters(state),point),unique,Targets.Targets.filter_unique(S.Simulation.monsters(state),point,unique),enough)

# The individual kill reports use the same actual builder inputs and selected
# powers as LiveSpin.plan, rather than a separately supplied plan list.
def SpinKill.BuiltReports(ready: L.LiveCombat.Ready,build: Spin.LiveSpin.Builder) -> Data:
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}: Unit
            case Some{player}:
              +player = player
              +monsters = monsters
              +meta = meta
              +selected = Targets.Targets.filter(monsters,Spin.LiveSpin.point(player))
              SpinKill.Reports(selected,build(monsters,player,meta,selected),S.Simulation.State{meta,players,monsters},pid,score)

law SpinKill.planned_reports:
  for +ready: L.LiveCombat.Ready
  for build: Spin.LiveSpin.Builder
  for +unique: Spin.LiveSpin.Unique(ready)
  for +enough: SpinKill.BuiltEnough(ready,build)
  SpinKill.BuiltReports(ready,build)

def SpinKill.planned_reports(ready,build,unique,enough):
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}: Unit{}
            case Some{player}: SpinKill.filtered_reports(S.Simulation.State{meta,players,monsters},pid,score,Spin.LiveSpin.point(player),build(monsters,player,meta),unique,enough)

law SpinKill.live_reports:
  for +world: T.Terrain.World
  for +pid: U32
  for +score: U32
  for build: Spin.LiveSpin.Builder
  for +unique: I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(world)))
  for +enough: SpinKill.BuiltEnough(L.LiveCombat.prepare(world,C.Combat.Spin{},pid,score),build)
  SpinKill.BuiltReports(L.LiveCombat.prepare(world,C.Combat.Spin{},pid,score),build)

def SpinKill.live_reports(world,pid,score,build,unique,enough): SpinKill.planned_reports(L.LiveCombat.prepare(world,C.Combat.Spin{},pid,score),build,Spin.LiveSpin.prepare_unique(world,pid,score,unique),enough)
