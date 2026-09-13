# Authoritative ordered monster strikes, conditional rewards, and world metadata.
# Simulation.OK is the established health/equipment/monster-zone invariant.
import Base
import ./numeric.bend as Num
import ./combat.bend as K
import ./players.bend as P
import ./monsters.bend as M
import ./roster.bend as R
import ./payouts.bend as Pay
import ./simulation.bend as S
import ./zones.bend as Z

# Catalog amounts are supplied by the planner. The actual kill fixes the kind.
def Battle.bind_kind(plan: Pay.Payout.Plan,kind: U32) -> Pay.Payout.Plan:
  match plan:
    case Pay.Payout.Plan{old,xp,gold,score,side_need,side_score,drop,find_score,bonus,cull_need,cull_score}:
      Pay.Payout.Plan{kind,xp,gold,score,side_need,side_score,drop,find_score,bonus,cull_need,cull_score}

def Battle.kind(kill: R.Roster.Kill) -> U32:
  match kill:
    case R.Roster.Kill{kind,rare,zone,mid}: kind

def Battle.sigil(+kind: U32) -> U32:
  Pay.Payout.choose(U32.is_eq(kind,6),1,Pay.Payout.choose(U32.is_eq(kind,7),2,Pay.Payout.choose(U32.is_eq(kind,8),4,0)))

def Battle.elapsed(meta: S.Simulation.Meta) -> U32:
  match meta:
    case S.Simulation.Meta{phase,world,seed,tick,started,now,sigils,fame,next_player,next_monster}: U32.sub(now,started)

def Battle.end_meta(ended: Bool,+meta: S.Simulation.Meta,kind: U32) -> S.Simulation.Meta:
  match ended:
    case False{}:
      match meta:
        case S.Simulation.Meta{phase,world,seed,tick,started,now,sigils,fame,next_player,next_monster}:
          S.Simulation.Meta{phase,world,seed,tick,started,now,U32.or(sigils,Battle.sigil(kind)),fame,next_player,next_monster}
    case True{}:
      match meta:
        case S.Simulation.Meta{phase,world,seed,tick,started,now,sigils,fame,next_player,next_monster}:
          S.Simulation.Meta{2,world,seed,tick,started,now,U32.or(sigils,Battle.sigil(kind)),now,next_player,next_monster}

def Battle.reward_meta(meta: S.Simulation.Meta,+kind: U32) -> S.Simulation.Meta:
  Battle.end_meta(U32.is_eq(kind,9),meta,kind)

type Battle.Notice is Data:
  Battle.Notice{kill: R.Roster.Kill,award: Pay.Payout.Kill,elapsed: U32,ended: Bool,players: List<&2,P.Players.State>}

type Battle.Result is Data:
  Battle.Result{state: S.Simulation.State,notices: List<&2,Battle.Notice>}

def Battle.state(result: Battle.Result) -> S.Simulation.State:
  match result:
    case Battle.Result{state,notices}: state

def Battle.notices(result: Battle.Result) -> List<&2,Battle.Notice>:
  match result:
    case Battle.Result{state,notices}: notices

def Battle.paid(+meta: S.Simulation.Meta,+players: List<&2,P.Players.State>,monsters: List<&2,M.Monsters.State>,+kill: R.Roster.Kill,paid: Maybe<&2,Pay.Payout.Kill>) -> Battle.Result:
  match paid:
    case None{}: Battle.Result{S.Simulation.State{meta,players,monsters},Nil{}}
    case Some{award}:
      Battle.Result{S.Simulation.State{Battle.reward_meta(meta,Battle.kind(kill)),players,monsters},[Battle.Notice{kill,award,Battle.elapsed(meta),U32.is_eq(Battle.kind(kill),9),players}]}

def Battle.finish_reward(meta: S.Simulation.Meta,monsters: List<&2,M.Monsters.State>,kill: R.Roster.Kill,result: Pay.Payout.Result) -> Battle.Result:
  match result:
    case Pay.Payout.Result{players,paid}: Battle.paid(meta,players,monsters,kill,paid)

def Battle.reward(state: S.Simulation.State,pid: U32,+kill: R.Roster.Kill,plan: Pay.Payout.Plan,score: U32) -> Battle.Result:
  match state:
    case S.Simulation.State{meta,players,monsters}:
      Battle.finish_reward(meta,monsters,kill,Pay.Payout.run(players,pid,Battle.bind_kind(plan,Battle.kind(kill)),score))

def Battle.after(kill: Maybe<&2,R.Roster.Kill>,state: S.Simulation.State,pid: U32,plan: Pay.Payout.Plan,score: U32) -> Battle.Result:
  match kill:
    case None{}: Battle.Result{state,Nil{}}
    case Some{info}: Battle.reward(state,pid,info,plan,score)

def Battle.finish_hit(meta: S.Simulation.Meta,players: List<&2,P.Players.State>,hit: R.Roster.Strike,pid: U32,plan: Pay.Payout.Plan,score: U32) -> Battle.Result:
  match hit:
    case R.Roster.Strike{monsters,kill,dealt}: Battle.after(kill,S.Simulation.State{meta,players,monsters},pid,plan,score)

type Battle.Input is Data:
  Battle.Input{mid: U32,damage: U32,plan: Pay.Payout.Plan}

def Battle.strike(input: Battle.Input,state: S.Simulation.State,pid: U32,score: U32) -> Battle.Result:
  match input:
    case Battle.Input{mid,damage,plan}:
      match state:
        case S.Simulation.State{meta,players,monsters}:
          Battle.finish_hit(meta,players,R.Roster.strike(monsters,mid,damage),pid,plan,score)

def Battle.concat(left: List<&2,Battle.Notice>,right: List<&2,Battle.Notice>) -> List<&2,Battle.Notice>:
  match left:
    case Nil{}: right
    case Con{head,rest}: Con{head,Battle.concat(rest,right)}

def Battle.before(first: Battle.Result,+second: Battle.Result) -> Battle.Result:
  Battle.Result{Battle.state(second),Battle.concat(Battle.notices(first),Battle.notices(second))}

def Battle.run(inputs: List<&2,Battle.Input>,state: S.Simulation.State,+pid: U32,+score: U32) -> Battle.Result:
  match inputs:
    case Nil{}: Battle.Result{state,Nil{}}
    case Con{head,rest}:
      +first = Battle.strike(head,state,pid,score)
      Battle.before(first,Battle.run(rest,Battle.state(first),pid,score))

law Battle.paid_ok:
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +monsters: List<&2,M.Monsters.State>
  for +kill: R.Roster.Kill
  for +paid: Maybe<&2,Pay.Payout.Kill>
  for +players_ok: P.Players.All(players)
  for +monsters_ok: R.Roster.OK(monsters)
  for +zones_ok: Z.Zones.All(monsters)
  S.Simulation.OK<Battle.state(Battle.paid(meta,players,monsters,kill,paid))>

def Battle.paid_ok(meta,players,monsters,kill,paid,players_ok,monsters_ok,zones_ok):
  match paid:
    case None{}: S.Simulation.OK{players_ok,monsters_ok,zones_ok}
    case Some{award}: S.Simulation.OK{players_ok,monsters_ok,zones_ok}

law Battle.finish_reward_ok:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +kill: R.Roster.Kill
  for +result: Pay.Payout.Result
  for +players_ok: P.Players.All(Pay.Payout.roster(result))
  for +monsters_ok: R.Roster.OK(monsters)
  for +zones_ok: Z.Zones.All(monsters)
  S.Simulation.OK<Battle.state(Battle.finish_reward(meta,monsters,kill,result))>

def Battle.finish_reward_ok(meta,monsters,kill,result,players_ok,monsters_ok,zones_ok):
  match result:
    case Pay.Payout.Result{players,paid}: Battle.paid_ok(meta,players,monsters,kill,paid,players_ok,monsters_ok,zones_ok)

law Battle.reward_ok:
  for +state: S.Simulation.State
  for +pid: U32
  for +kill: R.Roster.Kill
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +valid: S.Simulation.OK<state>
  S.Simulation.OK<Battle.state(Battle.reward(state,pid,kill,plan,score))>

def Battle.reward_ok(state,pid,kill,plan,score,valid):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      match valid:
        case S.Simulation.OK{players_ok,monsters_ok,zones_ok}:
          Battle.finish_reward_ok(meta,monsters,kill,Pay.Payout.run(players,pid,Battle.bind_kind(plan,Battle.kind(kill)),score),Pay.Payout.run_ok(players,pid,Battle.bind_kind(plan,Battle.kind(kill)),score,players_ok),monsters_ok,zones_ok)

law Battle.after_ok:
  for +kill: Maybe<&2,R.Roster.Kill>
  for +state: S.Simulation.State
  for +pid: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +valid: S.Simulation.OK<state>
  S.Simulation.OK<Battle.state(Battle.after(kill,state,pid,plan,score))>

def Battle.after_ok(kill,state,pid,plan,score,valid):
  match kill:
    case None{}: valid
    case Some{info}: Battle.reward_ok(state,pid,info,plan,score,valid)

law Battle.finish_hit_ok:
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +hit: R.Roster.Strike
  for +pid: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +players_ok: P.Players.All(players)
  for +monsters_ok: R.Roster.OK(R.Roster.struck(hit))
  for +zones_ok: Z.Zones.All(R.Roster.struck(hit))
  S.Simulation.OK<Battle.state(Battle.finish_hit(meta,players,hit,pid,plan,score))>

def Battle.finish_hit_ok(meta,players,hit,pid,plan,score,players_ok,monsters_ok,zones_ok):
  match hit:
    case R.Roster.Strike{monsters,kill,dealt}: Battle.after_ok(kill,S.Simulation.State{meta,players,monsters},pid,plan,score,S.Simulation.OK{players_ok,monsters_ok,zones_ok})

law Battle.strike_ok:
  for +input: Battle.Input
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +valid: S.Simulation.OK<state>
  S.Simulation.OK<Battle.state(Battle.strike(input,state,pid,score))>

def Battle.strike_ok(input,state,pid,score,valid):
  match input:
    case Battle.Input{mid,damage,plan}:
      match state:
        case S.Simulation.State{meta,players,monsters}:
          match valid:
            case S.Simulation.OK{players_ok,monsters_ok,zones_ok}:
              Battle.finish_hit_ok(meta,players,R.Roster.strike(monsters,mid,damage),pid,plan,score,players_ok,R.Roster.strike_ok(monsters,mid,damage,monsters_ok),Z.Zones.strike_all(monsters,mid,damage,zones_ok))

law Battle.run_ok:
  for +inputs: List<&2,Battle.Input>
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +valid: S.Simulation.OK<state>
  S.Simulation.OK<Battle.state(Battle.run(inputs,state,pid,score))>

def Battle.run_ok(inputs,state,pid,score,valid):
  match inputs:
    case Nil{}: valid
    case Con{head,rest}:
      Battle.run_ok(rest,Battle.state(Battle.strike(head,state,pid,score)),pid,score,Battle.strike_ok(head,state,pid,score,valid))

law Battle.paid_players:
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +monsters: List<&2,M.Monsters.State>
  for +kill: R.Roster.Kill
  for +paid: Maybe<&2,Pay.Payout.Kill>
  {S.Simulation.players(Battle.state(Battle.paid(meta,players,monsters,kill,paid))) == players : List<&2,P.Players.State>}

def Battle.paid_players(meta,players,monsters,kill,paid):
  match paid:
    case None{}: {==}
    case Some{award}: {==}

law Battle.finish_reward_players:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +kill: R.Roster.Kill
  for +result: Pay.Payout.Result
  {S.Simulation.players(Battle.state(Battle.finish_reward(meta,monsters,kill,result))) == Pay.Payout.roster(result) : List<&2,P.Players.State>}

def Battle.finish_reward_players(meta,monsters,kill,result):
  match result:
    case Pay.Payout.Result{players,paid}: Battle.paid_players(meta,players,monsters,kill,paid)

law Battle.paid_monsters:
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +monsters: List<&2,M.Monsters.State>
  for +kill: R.Roster.Kill
  for +paid: Maybe<&2,Pay.Payout.Kill>
  {S.Simulation.monsters(Battle.state(Battle.paid(meta,players,monsters,kill,paid))) == monsters : List<&2,M.Monsters.State>}

def Battle.paid_monsters(meta,players,monsters,kill,paid):
  match paid:
    case None{}: {==}
    case Some{award}: {==}

law Battle.finish_reward_monsters:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +kill: R.Roster.Kill
  for +result: Pay.Payout.Result
  {S.Simulation.monsters(Battle.state(Battle.finish_reward(meta,monsters,kill,result))) == monsters : List<&2,M.Monsters.State>}

def Battle.finish_reward_monsters(meta,monsters,kill,result):
  match result:
    case Pay.Payout.Result{players,paid}: Battle.paid_monsters(meta,players,monsters,kill,paid)

law Battle.reward_monsters:
  for +state: S.Simulation.State
  for +pid: U32
  for +kill: R.Roster.Kill
  for +plan: Pay.Payout.Plan
  for +score: U32
  {S.Simulation.monsters(Battle.state(Battle.reward(state,pid,kill,plan,score))) == S.Simulation.monsters(state) : List<&2,M.Monsters.State>}

def Battle.reward_monsters(state,pid,kill,plan,score):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      Battle.finish_reward_monsters(meta,monsters,kill,Pay.Payout.run(players,pid,Battle.bind_kind(plan,Battle.kind(kill)),score))

law Battle.reward_count:
  for +state: S.Simulation.State
  for +pid: U32
  for +kill: R.Roster.Kill
  for +plan: Pay.Payout.Plan
  for +score: U32
  {P.Players.length(S.Simulation.players(Battle.state(Battle.reward(state,pid,kill,plan,score)))) == P.Players.length(S.Simulation.players(state)) : Nat}

def Battle.reward_count(state,pid,kill,plan,score):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      %Equal.sym(List<&2,P.Players.State>,S.Simulation.players(Battle.state(Battle.finish_reward(meta,monsters,kill,Pay.Payout.run(players,pid,Battle.bind_kind(plan,Battle.kind(kill)),score)))),Pay.Payout.roster(Pay.Payout.run(players,pid,Battle.bind_kind(plan,Battle.kind(kill)),score)),Battle.finish_reward_players(meta,monsters,kill,Pay.Payout.run(players,pid,Battle.bind_kind(plan,Battle.kind(kill)),score))) : {P.Players.length(_) == P.Players.length(players) : Nat}
      Pay.Payout.run_count(players,pid,Battle.bind_kind(plan,Battle.kind(kill)),score)

law Battle.after_monsters:
  for +kill: Maybe<&2,R.Roster.Kill>
  for +state: S.Simulation.State
  for +pid: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  {S.Simulation.monsters(Battle.state(Battle.after(kill,state,pid,plan,score))) == S.Simulation.monsters(state) : List<&2,M.Monsters.State>}

def Battle.after_monsters(kill,state,pid,plan,score):
  match kill:
    case None{}: {==}
    case Some{info}: Battle.reward_monsters(state,pid,info,plan,score)

law Battle.after_count:
  for +kill: Maybe<&2,R.Roster.Kill>
  for +state: S.Simulation.State
  for +pid: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  {P.Players.length(S.Simulation.players(Battle.state(Battle.after(kill,state,pid,plan,score)))) == P.Players.length(S.Simulation.players(state)) : Nat}

def Battle.after_count(kill,state,pid,plan,score):
  match kill:
    case None{}: {==}
    case Some{info}: Battle.reward_count(state,pid,info,plan,score)

law Battle.finish_hit_monsters:
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +hit: R.Roster.Strike
  for +pid: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  {S.Simulation.monsters(Battle.state(Battle.finish_hit(meta,players,hit,pid,plan,score))) == R.Roster.struck(hit) : List<&2,M.Monsters.State>}

def Battle.finish_hit_monsters(meta,players,hit,pid,plan,score):
  match hit:
    case R.Roster.Strike{monsters,kill,dealt}: Battle.after_monsters(kill,S.Simulation.State{meta,players,monsters},pid,plan,score)

law Battle.finish_hit_count:
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +hit: R.Roster.Strike
  for +pid: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  {P.Players.length(S.Simulation.players(Battle.state(Battle.finish_hit(meta,players,hit,pid,plan,score)))) == P.Players.length(players) : Nat}

def Battle.finish_hit_count(meta,players,hit,pid,plan,score):
  match hit:
    case R.Roster.Strike{monsters,kill,dealt}: Battle.after_count(kill,S.Simulation.State{meta,players,monsters},pid,plan,score)

law Battle.strike_monsters:
  for +mid: U32
  for +damage: U32
  for +plan: Pay.Payout.Plan
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  {S.Simulation.monsters(Battle.state(Battle.strike(Battle.Input{mid,damage,plan},state,pid,score))) == R.Roster.struck(R.Roster.strike(S.Simulation.monsters(state),mid,damage)) : List<&2,M.Monsters.State>}

def Battle.strike_monsters(mid,damage,plan,state,pid,score):
  match state:
    case S.Simulation.State{meta,players,monsters}: Battle.finish_hit_monsters(meta,players,R.Roster.strike(monsters,mid,damage),pid,plan,score)

law Battle.strike_player_count:
  for +input: Battle.Input
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  {P.Players.length(S.Simulation.players(Battle.state(Battle.strike(input,state,pid,score)))) == P.Players.length(S.Simulation.players(state)) : Nat}

def Battle.strike_player_count(input,state,pid,score):
  match input:
    case Battle.Input{mid,damage,plan}:
      match state:
        case S.Simulation.State{meta,players,monsters}: Battle.finish_hit_count(meta,players,R.Roster.strike(monsters,mid,damage),pid,plan,score)

law Battle.strike_monster_count:
  for +input: Battle.Input
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  {R.Roster.length(S.Simulation.monsters(Battle.state(Battle.strike(input,state,pid,score)))) == R.Roster.length(S.Simulation.monsters(state)) : Nat}

def Battle.strike_monster_count(input,state,pid,score):
  match input:
    case Battle.Input{mid,damage,plan}:
      %Equal.sym(List<&2,M.Monsters.State>,S.Simulation.monsters(Battle.state(Battle.strike(Battle.Input{mid,damage,plan},state,pid,score))),R.Roster.struck(R.Roster.strike(S.Simulation.monsters(state),mid,damage)),Battle.strike_monsters(mid,damage,plan,state,pid,score)) : {R.Roster.length(_) == R.Roster.length(S.Simulation.monsters(state)) : Nat}
      R.Roster.strike_count(S.Simulation.monsters(state),mid,damage)

law Battle.run_player_count:
  for +inputs: List<&2,Battle.Input>
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  {P.Players.length(S.Simulation.players(Battle.state(Battle.run(inputs,state,pid,score)))) == P.Players.length(S.Simulation.players(state)) : Nat}

def Battle.run_player_count(inputs,state,pid,score):
  match inputs:
    case Nil{}: {==}
    case Con{head,rest}:
      Equal.trans(Nat,P.Players.length(S.Simulation.players(Battle.state(Battle.run(rest,Battle.state(Battle.strike(head,state,pid,score)),pid,score)))),P.Players.length(S.Simulation.players(Battle.state(Battle.strike(head,state,pid,score)))),P.Players.length(S.Simulation.players(state)),Battle.run_player_count(rest,Battle.state(Battle.strike(head,state,pid,score)),pid,score),Battle.strike_player_count(head,state,pid,score))

law Battle.run_monster_count:
  for +inputs: List<&2,Battle.Input>
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  {R.Roster.length(S.Simulation.monsters(Battle.state(Battle.run(inputs,state,pid,score)))) == R.Roster.length(S.Simulation.monsters(state)) : Nat}

def Battle.run_monster_count(inputs,state,pid,score):
  match inputs:
    case Nil{}: {==}
    case Con{head,rest}:
      Equal.trans(Nat,R.Roster.length(S.Simulation.monsters(Battle.state(Battle.run(rest,Battle.state(Battle.strike(head,state,pid,score)),pid,score)))),R.Roster.length(S.Simulation.monsters(Battle.state(Battle.strike(head,state,pid,score)))),R.Roster.length(S.Simulation.monsters(state)),Battle.run_monster_count(rest,Battle.state(Battle.strike(head,state,pid,score)),pid,score),Battle.strike_monster_count(head,state,pid,score))

# The server computes plans from the admitted actor, then calls this commit.
# A rejected/missing actor cannot execute even a nonempty supplied plan list.
def Battle.execute(meta: S.Simulation.Meta,monsters: List<&2,M.Monsters.State>,admitted: K.Combat.Result,inputs: List<&2,Battle.Input>,pid: U32,score: U32) -> Battle.Result:
  match admitted:
    case K.Combat.Result{players,attacker}:
      match attacker:
        case None{}: Battle.Result{S.Simulation.State{meta,players,monsters},Nil{}}
        case Some{actor}: Battle.run(inputs,S.Simulation.State{meta,players,monsters},pid,score)

def Battle.command(kind: K.Combat.Kind,state: S.Simulation.State,inputs: List<&2,Battle.Input>,+pid: U32,score: U32) -> Battle.Result:
  match state:
    case S.Simulation.State{meta,players,monsters}:
      +shared_meta = meta
      Battle.execute(shared_meta,monsters,K.Combat.run(players,pid,kind,S.Simulation.phase(shared_meta)),inputs,pid,score)

law Battle.execute_ok:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +admitted: K.Combat.Result
  for +inputs: List<&2,Battle.Input>
  for +pid: U32
  for +score: U32
  for +players_ok: P.Players.All(K.Combat.roster(admitted))
  for +monsters_ok: R.Roster.OK(monsters)
  for +zones_ok: Z.Zones.All(monsters)
  S.Simulation.OK<Battle.state(Battle.execute(meta,monsters,admitted,inputs,pid,score))>

def Battle.execute_ok(meta,monsters,admitted,inputs,pid,score,players_ok,monsters_ok,zones_ok):
  match admitted:
    case K.Combat.Result{players,attacker}:
      match attacker:
        case None{}: S.Simulation.OK{players_ok,monsters_ok,zones_ok}
        case Some{actor}: Battle.run_ok(inputs,S.Simulation.State{meta,players,monsters},pid,score,S.Simulation.OK{players_ok,monsters_ok,zones_ok})

law Battle.command_ok:
  for +kind: K.Combat.Kind
  for +state: S.Simulation.State
  for +inputs: List<&2,Battle.Input>
  for +pid: U32
  for +score: U32
  for +valid: S.Simulation.OK<state>
  S.Simulation.OK<Battle.state(Battle.command(kind,state,inputs,pid,score))>

def Battle.command_ok(kind,state,inputs,pid,score,valid):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      match valid:
        case S.Simulation.OK{players_ok,monsters_ok,zones_ok}:
          Battle.execute_ok(meta,monsters,K.Combat.run(players,pid,kind,S.Simulation.phase(meta)),inputs,pid,score,K.Combat.run_ok(players,pid,kind,S.Simulation.phase(meta),players_ok),monsters_ok,zones_ok)

law Battle.execute_rejected:
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +monsters: List<&2,M.Monsters.State>
  for +inputs: List<&2,Battle.Input>
  for +pid: U32
  for +score: U32
  {Battle.execute(meta,monsters,K.Combat.Result{players,None{}},inputs,pid,score) == Battle.Result{S.Simulation.State{meta,players,monsters},Nil{}} : Battle.Result}

def Battle.execute_rejected(meta,players,monsters,inputs,pid,score): {==}

law Battle.execute_ready:
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +monsters: List<&2,M.Monsters.State>
  for +actor: P.Players.State
  for +inputs: List<&2,Battle.Input>
  for +pid: U32
  for +score: U32
  {Battle.execute(meta,monsters,K.Combat.Result{players,Some{actor}},inputs,pid,score) == Battle.run(inputs,S.Simulation.State{meta,players,monsters},pid,score) : Battle.Result}

def Battle.execute_ready(meta,players,monsters,actor,inputs,pid,score): {==}

law Battle.bind_kind_exact:
  for +plan: Pay.Payout.Plan
  for +kind: U32
  {Pay.Payout.kind(Battle.bind_kind(plan,kind)) == kind : U32}

def Battle.bind_kind_exact(plan,kind):
  match plan:
    case Pay.Payout.Plan{old,xp,gold,score,side_need,side_score,drop,find_score,bonus,cull_need,cull_score}: {==}

law Battle.bind_kind_same:
  for +plan: Pay.Payout.Plan
  {Battle.bind_kind(plan,Pay.Payout.kind(plan)) == plan : Pay.Payout.Plan}

def Battle.bind_kind_same(plan):
  match plan:
    case Pay.Payout.Plan{kind,xp,gold,score,side_need,side_score,drop,find_score,bonus,cull_need,cull_score}: {==}

law Battle.paid_exact:
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +monsters: List<&2,M.Monsters.State>
  for +kill: R.Roster.Kill
  for +award: Pay.Payout.Kill
  {Battle.paid(meta,players,monsters,kill,Some{award}) == Battle.Result{S.Simulation.State{Battle.reward_meta(meta,Battle.kind(kill)),players,monsters},[Battle.Notice{kill,award,Battle.elapsed(meta),U32.is_eq(Battle.kind(kill),9),players}]} : Battle.Result}

def Battle.paid_exact(meta,players,monsters,kill,award): {==}

law Battle.after_no_kill:
  for +state: S.Simulation.State
  for +pid: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  {Battle.after(None{},state,pid,plan,score) == Battle.Result{state,Nil{}} : Battle.Result}

def Battle.after_no_kill(state,pid,plan,score): {==}

def Battle.kill(hit: R.Roster.Strike) -> Maybe<&2,R.Roster.Kill>:
  match hit:
    case R.Roster.Strike{monsters,kill,dealt}: kill

law Battle.finish_hit_exact:
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +hit: R.Roster.Strike
  for +pid: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  {Battle.finish_hit(meta,players,hit,pid,plan,score) == Battle.after(Battle.kill(hit),S.Simulation.State{meta,players,R.Roster.struck(hit)},pid,plan,score) : Battle.Result}

def Battle.finish_hit_exact(meta,players,hit,pid,plan,score):
  match hit:
    case R.Roster.Strike{monsters,kill,dealt}: {==}

law Battle.finish_hit_no_kill:
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +hit: R.Roster.Strike
  for +pid: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +no_kill: {Battle.kill(hit) == None{} : Maybe<&2,R.Roster.Kill>}
  {Battle.finish_hit(meta,players,hit,pid,plan,score) == Battle.Result{S.Simulation.State{meta,players,R.Roster.struck(hit)},Nil{}} : Battle.Result}

def Battle.finish_hit_no_kill(meta,players,hit,pid,plan,score,no_kill):
  %Equal.sym(Battle.Result,Battle.finish_hit(meta,players,hit,pid,plan,score),Battle.after(Battle.kill(hit),S.Simulation.State{meta,players,R.Roster.struck(hit)},pid,plan,score),Battle.finish_hit_exact(meta,players,hit,pid,plan,score)) : {_ == Battle.Result{S.Simulation.State{meta,players,R.Roster.struck(hit)},Nil{}} : Battle.Result}
  %Equal.sym(Maybe<&2,R.Roster.Kill>,Battle.kill(hit),None{},no_kill) : {Battle.after(_,S.Simulation.State{meta,players,R.Roster.struck(hit)},pid,plan,score) == Battle.Result{S.Simulation.State{meta,players,R.Roster.struck(hit)},Nil{}} : Battle.Result}
  {==}

law Battle.strike_no_kill:
  for +mid: U32
  for +damage: U32
  for +plan: Pay.Payout.Plan
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +no_kill: {Battle.kill(R.Roster.strike(S.Simulation.monsters(state),mid,damage)) == None{} : Maybe<&2,R.Roster.Kill>}
  {Battle.strike(Battle.Input{mid,damage,plan},state,pid,score) == Battle.Result{S.Simulation.State{S.Simulation.meta(state),S.Simulation.players(state),R.Roster.struck(R.Roster.strike(S.Simulation.monsters(state),mid,damage))},Nil{}} : Battle.Result}

def Battle.strike_no_kill(mid,damage,plan,state,pid,score,no_kill):
  match state:
    case S.Simulation.State{meta,players,monsters}: Battle.finish_hit_no_kill(meta,players,R.Roster.strike(monsters,mid,damage),pid,plan,score,no_kill)

law Battle.strike_missing:
  for +mid: U32
  for +damage: U32
  for +plan: Pay.Payout.Plan
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +missing: {R.Roster.has_id(S.Simulation.monsters(state),mid) == False{} : Bool}
  {Battle.strike(Battle.Input{mid,damage,plan},state,pid,score) == Battle.Result{state,Nil{}} : Battle.Result}

def Battle.strike_missing(mid,damage,plan,state,pid,score,missing):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      %Equal.sym(R.Roster.Strike,R.Roster.strike(monsters,mid,damage),R.Roster.Strike{monsters,None{},0},R.Roster.strike_missing(monsters,mid,damage,missing)) : {Battle.finish_hit(meta,players,_,pid,plan,score) == Battle.Result{S.Simulation.State{meta,players,monsters},Nil{}} : Battle.Result}
      {==}

law Battle.reward_missing:
  for +state: S.Simulation.State
  for +pid: U32
  for +kill: R.Roster.Kill
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +missing: {P.Players.has_id(S.Simulation.players(state),pid) == False{} : Bool}
  {Battle.reward(state,pid,kill,plan,score) == Battle.Result{state,Nil{}} : Battle.Result}

def Battle.reward_missing(state,pid,kill,plan,score,missing):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      %Equal.sym(Pay.Payout.Result,Pay.Payout.run(players,pid,Battle.bind_kind(plan,Battle.kind(kill)),score),Pay.Payout.Result{players,None{}},Pay.Payout.run_missing(players,pid,Battle.bind_kind(plan,Battle.kind(kill)),score,missing)) : {Battle.finish_reward(meta,monsters,kill,_) == Battle.Result{S.Simulation.State{meta,players,monsters},Nil{}} : Battle.Result}
      {==}

law Battle.before_exact:
  for +first: Battle.Result
  for +second: Battle.Result
  {Battle.before(first,second) == Battle.Result{Battle.state(second),Battle.concat(Battle.notices(first),Battle.notices(second))} : Battle.Result}

def Battle.before_exact(first,second): {==}

law Battle.run_order:
  for +input: Battle.Input
  for +rest: List<&2,Battle.Input>
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  {Battle.run(Con{input,rest},state,pid,score) == Battle.Result{Battle.state(Battle.run(rest,Battle.state(Battle.strike(input,state,pid,score)),pid,score)),Battle.concat(Battle.notices(Battle.strike(input,state,pid,score)),Battle.notices(Battle.run(rest,Battle.state(Battle.strike(input,state,pid,score)),pid,score)))} : Battle.Result}

def Battle.run_order(input,rest,state,pid,score): {==}

def Battle.notice_count(notices: List<&2,Battle.Notice>) -> Nat:
  match notices:
    case Nil{}: Zero{}
    case Con{head,rest}: Succ{Battle.notice_count(rest)}

def Battle.awarded(result: Pay.Payout.Result) -> Maybe<&2,Pay.Payout.Kill>:
  match result:
    case Pay.Payout.Result{players,paid}: paid

def Battle.has_award(paid: Maybe<&2,Pay.Payout.Kill>) -> Bool:
  match paid:
    case None{}: False{}
    case Some{award}: True{}

def Battle.award_count(paid: Maybe<&2,Pay.Payout.Kill>) -> Nat:
  match paid:
    case None{}: Zero{}
    case Some{award}: 1n

law Battle.apply_taken_has:
  for +taken: P.Players.Take
  for +plan: Pay.Payout.Plan
  for +score: U32
  {Battle.has_award(Battle.awarded(Pay.Payout.apply_taken(taken,plan,score))) == P.Players.has(P.Players.found(taken)) : Bool}

def Battle.apply_taken_has(taken,plan,score):
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}: {==}
        case Some{player}: {==}

law Battle.paid_notice_count:
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +monsters: List<&2,M.Monsters.State>
  for +kill: R.Roster.Kill
  for +paid: Maybe<&2,Pay.Payout.Kill>
  {Battle.notice_count(Battle.notices(Battle.paid(meta,players,monsters,kill,paid))) == Battle.award_count(paid) : Nat}

def Battle.paid_notice_count(meta,players,monsters,kill,paid):
  match paid:
    case None{}: {==}
    case Some{award}: {==}

law Battle.finish_reward_notice_count:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +kill: R.Roster.Kill
  for +result: Pay.Payout.Result
  {Battle.notice_count(Battle.notices(Battle.finish_reward(meta,monsters,kill,result))) == Battle.award_count(Battle.awarded(result)) : Nat}

def Battle.finish_reward_notice_count(meta,monsters,kill,result):
  match result:
    case Pay.Payout.Result{players,paid}: Battle.paid_notice_count(meta,players,monsters,kill,paid)

law Battle.award_present_count:
  for +paid: Maybe<&2,Pay.Payout.Kill>
  for +present: {Battle.has_award(paid) == True{} : Bool}
  {Battle.award_count(paid) == 1n : Nat}

def Battle.award_present_count(paid,present):
  match paid:
    case None{}: Empty.absurd({Zero{} == 1n : Nat},Num.Numeric.true_ne_false(Equal.sym(Bool,False{},True{},present)))
    case Some{award}: {==}

law Battle.reward_present:
  for +state: S.Simulation.State
  for +pid: U32
  for +kill: R.Roster.Kill
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +present: {P.Players.has_id(S.Simulation.players(state),pid) == True{} : Bool}
  {Battle.notice_count(Battle.notices(Battle.reward(state,pid,kill,plan,score))) == 1n : Nat}

def Battle.reward_present(state,pid,kill,plan,score,present):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      %Equal.sym(Nat,Battle.notice_count(Battle.notices(Battle.finish_reward(meta,monsters,kill,Pay.Payout.run(players,pid,Battle.bind_kind(plan,Battle.kind(kill)),score)))),Battle.award_count(Battle.awarded(Pay.Payout.run(players,pid,Battle.bind_kind(plan,Battle.kind(kill)),score))),Battle.finish_reward_notice_count(meta,monsters,kill,Pay.Payout.run(players,pid,Battle.bind_kind(plan,Battle.kind(kill)),score))) : {_ == 1n : Nat}
      Battle.award_present_count(Battle.awarded(Pay.Payout.run(players,pid,Battle.bind_kind(plan,Battle.kind(kill)),score)),Equal.trans(Bool,Battle.has_award(Battle.awarded(Pay.Payout.run(players,pid,Battle.bind_kind(plan,Battle.kind(kill)),score))),P.Players.has(P.Players.found(P.Players.take(players,pid))),True{},Battle.apply_taken_has(P.Players.take(players,pid),Battle.bind_kind(plan,Battle.kind(kill)),score),P.Players.take_success(players,pid,present)))

law Battle.finish_hit_reported:
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +hit: R.Roster.Strike
  for +pid: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +kill: R.Roster.Kill
  for +reported: {Battle.kill(hit) == Some{kill} : Maybe<&2,R.Roster.Kill>}
  for +present: {P.Players.has_id(players,pid) == True{} : Bool}
  {Battle.notice_count(Battle.notices(Battle.finish_hit(meta,players,hit,pid,plan,score))) == 1n : Nat}

def Battle.finish_hit_reported(meta,players,hit,pid,plan,score,kill,reported,present):
  %Equal.sym(Battle.Result,Battle.finish_hit(meta,players,hit,pid,plan,score),Battle.after(Battle.kill(hit),S.Simulation.State{meta,players,R.Roster.struck(hit)},pid,plan,score),Battle.finish_hit_exact(meta,players,hit,pid,plan,score)) : {Battle.notice_count(Battle.notices(_)) == 1n : Nat}
  %Equal.sym(Maybe<&2,R.Roster.Kill>,Battle.kill(hit),Some{kill},reported) : {Battle.notice_count(Battle.notices(Battle.after(_,S.Simulation.State{meta,players,R.Roster.struck(hit)},pid,plan,score))) == 1n : Nat}
  Battle.reward_present(S.Simulation.State{meta,players,R.Roster.struck(hit)},pid,kill,plan,score,present)

law Battle.strike_reported:
  for +mid: U32
  for +damage: U32
  for +plan: Pay.Payout.Plan
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +kill: R.Roster.Kill
  for +reported: {Battle.kill(R.Roster.strike(S.Simulation.monsters(state),mid,damage)) == Some{kill} : Maybe<&2,R.Roster.Kill>}
  for +present: {P.Players.has_id(S.Simulation.players(state),pid) == True{} : Bool}
  {Battle.notice_count(Battle.notices(Battle.strike(Battle.Input{mid,damage,plan},state,pid,score))) == 1n : Nat}

def Battle.strike_reported(mid,damage,plan,state,pid,score,kill,reported,present):
  match state:
    case S.Simulation.State{meta,players,monsters}: Battle.finish_hit_reported(meta,players,R.Roster.strike(monsters,mid,damage),pid,plan,score,kill,reported,present)

law Battle.end_meta_exact:
  for +ended: Bool
  for +phase: U32
  for +world: U32
  for +seed: U32
  for +tick: U32
  for +started: U32
  for +now: U32
  for +sigils: U32
  for +fame: U32
  for +next_player: U32
  for +next_monster: U32
  for +kind: U32
  {Battle.end_meta(ended,S.Simulation.Meta{phase,world,seed,tick,started,now,sigils,fame,next_player,next_monster},kind) == S.Simulation.Meta{Pay.Payout.choose(ended,2,phase),world,seed,tick,started,now,U32.or(sigils,Battle.sigil(kind)),Pay.Payout.choose(ended,now,fame),next_player,next_monster} : S.Simulation.Meta}

def Battle.end_meta_exact(ended,phase,world,seed,tick,started,now,sigils,fame,next_player,next_monster,kind):
  match ended:
    case False{}: {==}
    case True{}: {==}

law Battle.reward_meta_exact:
  for +phase: U32
  for +world: U32
  for +seed: U32
  for +tick: U32
  for +started: U32
  for +now: U32
  for +sigils: U32
  for +fame: U32
  for +next_player: U32
  for +next_monster: U32
  for +kind: U32
  {Battle.reward_meta(S.Simulation.Meta{phase,world,seed,tick,started,now,sigils,fame,next_player,next_monster},kind) == S.Simulation.Meta{Pay.Payout.choose(U32.is_eq(kind,9),2,phase),world,seed,tick,started,now,U32.or(sigils,Battle.sigil(kind)),Pay.Payout.choose(U32.is_eq(kind,9),now,fame),next_player,next_monster} : S.Simulation.Meta}

def Battle.reward_meta_exact(phase,world,seed,tick,started,now,sigils,fame,next_player,next_monster,kind):
  Battle.end_meta_exact(U32.is_eq(kind,9),phase,world,seed,tick,started,now,sigils,fame,next_player,next_monster,kind)

law Battle.execute_player_count:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +admitted: K.Combat.Result
  for +inputs: List<&2,Battle.Input>
  for +pid: U32
  for +score: U32
  {P.Players.length(S.Simulation.players(Battle.state(Battle.execute(meta,monsters,admitted,inputs,pid,score)))) == P.Players.length(K.Combat.roster(admitted)) : Nat}

def Battle.execute_player_count(meta,monsters,admitted,inputs,pid,score):
  match admitted:
    case K.Combat.Result{players,attacker}:
      match attacker:
        case None{}: {==}
        case Some{actor}: Battle.run_player_count(inputs,S.Simulation.State{meta,players,monsters},pid,score)

law Battle.command_player_count:
  for +kind: K.Combat.Kind
  for +state: S.Simulation.State
  for +inputs: List<&2,Battle.Input>
  for +pid: U32
  for +score: U32
  {P.Players.length(S.Simulation.players(Battle.state(Battle.command(kind,state,inputs,pid,score)))) == P.Players.length(S.Simulation.players(state)) : Nat}

def Battle.command_player_count(kind,state,inputs,pid,score):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      Equal.trans(Nat,P.Players.length(S.Simulation.players(Battle.state(Battle.command(kind,S.Simulation.State{meta,players,monsters},inputs,pid,score)))),P.Players.length(K.Combat.roster(K.Combat.run(players,pid,kind,S.Simulation.phase(meta)))),P.Players.length(players),Battle.execute_player_count(meta,monsters,K.Combat.run(players,pid,kind,S.Simulation.phase(meta)),inputs,pid,score),K.Combat.run_count(players,pid,kind,S.Simulation.phase(meta)))

law Battle.execute_monster_count:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +admitted: K.Combat.Result
  for +inputs: List<&2,Battle.Input>
  for +pid: U32
  for +score: U32
  {R.Roster.length(S.Simulation.monsters(Battle.state(Battle.execute(meta,monsters,admitted,inputs,pid,score)))) == R.Roster.length(monsters) : Nat}

def Battle.execute_monster_count(meta,monsters,admitted,inputs,pid,score):
  match admitted:
    case K.Combat.Result{players,attacker}:
      match attacker:
        case None{}: {==}
        case Some{actor}: Battle.run_monster_count(inputs,S.Simulation.State{meta,players,monsters},pid,score)

law Battle.command_monster_count:
  for +kind: K.Combat.Kind
  for +state: S.Simulation.State
  for +inputs: List<&2,Battle.Input>
  for +pid: U32
  for +score: U32
  {R.Roster.length(S.Simulation.monsters(Battle.state(Battle.command(kind,state,inputs,pid,score)))) == R.Roster.length(S.Simulation.monsters(state)) : Nat}

def Battle.command_monster_count(kind,state,inputs,pid,score):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      Battle.execute_monster_count(meta,monsters,K.Combat.run(players,pid,kind,S.Simulation.phase(meta)),inputs,pid,score)

# Mixed sequences use the exact checked command and tick implementations.
# Planning remains explicit; this does not assert legality of supplied plans.
type Battle.Transition is Data:
  Battle.Fighting{kind: K.Combat.Kind,inputs: List<&2,Battle.Input>,pid: U32,score: U32}
  Battle.Ticking{plan: S.Simulation.Plan,rules: S.Simulation.Rules}

def Battle.transition(transition: Battle.Transition,state: S.Simulation.State) -> S.Simulation.State:
  match transition:
    case Battle.Fighting{kind,inputs,pid,score}: Battle.state(Battle.command(kind,state,inputs,pid,score))
    case Battle.Ticking{plan,rules}: S.Simulation.state(S.Simulation.tick(state,plan,rules))

law Battle.transition_ok:
  for +transition: Battle.Transition
  for +state: S.Simulation.State
  for +valid: S.Simulation.OK<state>
  S.Simulation.OK<Battle.transition(transition,state)>

def Battle.transition_ok(transition,state,valid):
  match transition:
    case Battle.Fighting{kind,inputs,pid,score}: Battle.command_ok(kind,state,inputs,pid,score,valid)
    case Battle.Ticking{plan,rules}: S.Simulation.tick_ok(state,plan,rules,valid)

def Battle.trace(transitions: List<&2,Battle.Transition>,state: S.Simulation.State) -> S.Simulation.State:
  match transitions:
    case Nil{}: state
    case Con{head,rest}: Battle.trace(rest,Battle.transition(head,state))

law Battle.trace_ok:
  for +transitions: List<&2,Battle.Transition>
  for +state: S.Simulation.State
  for +valid: S.Simulation.OK<state>
  S.Simulation.OK<Battle.trace(transitions,state)>

def Battle.trace_ok(transitions,state,valid):
  match transitions:
    case Nil{}: valid
    case Con{head,rest}: Battle.trace_ok(rest,Battle.transition(head,state),Battle.transition_ok(head,state,valid))

law Battle.transition_player_count:
  for +transition: Battle.Transition
  for +state: S.Simulation.State
  {P.Players.length(S.Simulation.players(Battle.transition(transition,state))) == P.Players.length(S.Simulation.players(state)) : Nat}

def Battle.transition_player_count(transition,state):
  match transition:
    case Battle.Fighting{kind,inputs,pid,score}: Battle.command_player_count(kind,state,inputs,pid,score)
    case Battle.Ticking{plan,rules}: S.Simulation.tick_player_count(state,plan,rules)

law Battle.transition_monster_count:
  for +transition: Battle.Transition
  for +state: S.Simulation.State
  for +valid: S.Simulation.OK<state>
  {R.Roster.length(S.Simulation.monsters(Battle.transition(transition,state))) == R.Roster.length(S.Simulation.monsters(state)) : Nat}

def Battle.transition_monster_count(transition,state,valid):
  match transition:
    case Battle.Fighting{kind,inputs,pid,score}: Battle.command_monster_count(kind,state,inputs,pid,score)
    case Battle.Ticking{plan,rules}: S.Simulation.tick_monster_count(state,plan,rules,S.Simulation.valid_zones(state,valid))

law Battle.trace_player_count:
  for +transitions: List<&2,Battle.Transition>
  for +state: S.Simulation.State
  {P.Players.length(S.Simulation.players(Battle.trace(transitions,state))) == P.Players.length(S.Simulation.players(state)) : Nat}

def Battle.trace_player_count(transitions,state):
  match transitions:
    case Nil{}: {==}
    case Con{head,rest}:
      Equal.trans(Nat,P.Players.length(S.Simulation.players(Battle.trace(rest,Battle.transition(head,state)))),P.Players.length(S.Simulation.players(Battle.transition(head,state))),P.Players.length(S.Simulation.players(state)),Battle.trace_player_count(rest,Battle.transition(head,state)),Battle.transition_player_count(head,state))

law Battle.trace_monster_count:
  for +transitions: List<&2,Battle.Transition>
  for +state: S.Simulation.State
  for +valid: S.Simulation.OK<state>
  {R.Roster.length(S.Simulation.monsters(Battle.trace(transitions,state))) == R.Roster.length(S.Simulation.monsters(state)) : Nat}

def Battle.trace_monster_count(transitions,state,valid):
  match transitions:
    case Nil{}: {==}
    case Con{head,rest}:
      Equal.trans(Nat,R.Roster.length(S.Simulation.monsters(Battle.trace(rest,Battle.transition(head,state)))),R.Roster.length(S.Simulation.monsters(Battle.transition(head,state))),R.Roster.length(S.Simulation.monsters(state)),Battle.trace_monster_count(rest,Battle.transition(head,state),Battle.transition_ok(head,state,valid)),Battle.transition_monster_count(head,state,valid))
