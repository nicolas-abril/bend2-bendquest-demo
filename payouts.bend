# Complete player-state composition of server-authored kill payouts.
import Base
import ./game.bend as G
import ./rewards.bend as R
import ./players.bend as P
import ./vitals.bend as V

def Payout.xp(player: P.Players.State) -> U32:
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match vitals:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: xp

def Payout.quest(player: P.Players.State) -> P.Players.Quest:
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}: quest

def Payout.meta(player: P.Players.State) -> P.Players.Meta:
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}: meta

def Payout.install(player: P.Players.State, hero: G.Bq.Hero, xp: U32) -> P.Players.State:
  match player:
    case P.Players.State{pid,cid,old,pos,vitals,style,quest,meta}:
      match vitals:
        case V.Vitals.State{hp,old_xp,dead,respawn,attack,spin}:
          P.Players.State{pid,cid,hero,pos,V.Vitals.State{hp,xp,dead,respawn,attack,spin},style,quest,meta}

law Payout.install_ok:
  for +player: P.Players.State
  for +hero: G.Bq.Hero
  for +xp: U32
  for +life: V.Vitals.Life<V.Vitals.hp(P.Players.vitals(player)),V.Vitals.dead(P.Players.vitals(player))>
  for +bound: {G.Bq.Nat.le(U32.to_nat(V.Vitals.hp(P.Players.vitals(player))),U32.to_nat(R.Rewards.maximum(hero,4294967295))) == True{} : Bool}
  for +equipped: G.Bq.WellEquipped(hero)
  P.Players.OK<Payout.install(player,hero,xp)>

def Payout.install_ok(player,hero,xp,life,bound,equipped):
  match player:
    case P.Players.State{pid,cid,old,pos,vitals,style,quest,meta}:
      match vitals:
        case V.Vitals.State{hp,old_xp,dead,respawn,attack,spin}:
          P.Players.OK{V.Vitals.OK{bound,life},equipped}

def Payout.profile(player: P.Players.State, quest: P.Players.Quest, meta: P.Players.Meta) -> P.Players.State:
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,old_q,old_m}:
      match old_m:
        case P.Players.Meta{old_score,old_kills,old_found,name}:
          match meta:
            case P.Players.Meta{score,kills,found,unused_name}:
              P.Players.State{pid,cid,hero,pos,vitals,style,quest,P.Players.Meta{score,kills,found,name}}

law Payout.profile_ok:
  for +player: P.Players.State
  for +quest: P.Players.Quest
  for +meta: P.Players.Meta
  for +valid: P.Players.OK<player>
  P.Players.OK<Payout.profile(player,quest,meta)>

def Payout.profile_ok(player,quest,meta,valid):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,old_q,old_m}:
      match old_m:
        case P.Players.Meta{old_score,old_kills,old_found,name}:
          match meta:
            case P.Players.Meta{score,kills,found,unused_name}:
              match valid:
                case P.Players.OK{vitals_ok,equipped}: P.Players.OK{vitals_ok,equipped}

type Payout.Experience is Data:
  Payout.Experience{player: P.Players.State, levels: U32}

def Payout.experienced(result: Payout.Experience) -> P.Players.State:
  match result:
    case Payout.Experience{player,levels}: player

def Payout.levels(result: Payout.Experience) -> U32:
  match result:
    case Payout.Experience{player,levels}: levels

def Payout.finish_xp(player: P.Players.State, gained: R.Rewards.Result) -> Payout.Experience:
  match gained:
    case R.Rewards.Result{hero,xp,levels}:
      Payout.Experience{Payout.install(player,hero,xp),levels}

def Payout.experience(+player: P.Players.State, gained: U32) -> Payout.Experience:
  Payout.finish_xp(player,R.Rewards.gain(P.Players.hero(player),Payout.xp(player),gained))

law Payout.finish_xp_ok:
  for +player: P.Players.State
  for +gained: R.Rewards.Result
  for +life: V.Vitals.Life<V.Vitals.hp(P.Players.vitals(player)),V.Vitals.dead(P.Players.vitals(player))>
  for +bound: {G.Bq.Nat.le(U32.to_nat(V.Vitals.hp(P.Players.vitals(player))),U32.to_nat(R.Rewards.maximum(R.Rewards.hero(gained),4294967295))) == True{} : Bool}
  for +equipped: G.Bq.WellEquipped(R.Rewards.hero(gained))
  P.Players.OK<Payout.experienced(Payout.finish_xp(player,gained))>

def Payout.finish_xp_ok(player,gained,life,bound,equipped):
  match gained:
    case R.Rewards.Result{hero,xp,levels}: Payout.install_ok(player,hero,xp,life,bound,equipped)

law Payout.experience_ok:
  for +player: P.Players.State
  for +gained: U32
  for +valid: P.Players.OK<player>
  P.Players.OK<Payout.experienced(Payout.experience(player,gained))>

def Payout.experience_ok(player,gained,valid):
  match valid:
    case P.Players.OK{vitals,equipped}:
      match vitals:
        case V.Vitals.OK{bound,life}:
          Payout.finish_xp_ok(player,R.Rewards.gain(P.Players.hero(player),Payout.xp(player),gained),life,R.Rewards.gain_health(P.Players.hero(player),Payout.xp(player),gained,V.Vitals.hp(P.Players.vitals(player)),4294967295,bound),R.Rewards.gain_equipped(P.Players.hero(player),Payout.xp(player),gained,equipped))

def Payout.gold(+player: P.Players.State, amount: U32) -> P.Players.State:
  Payout.install(player,R.Rewards.add_gold(P.Players.hero(player),amount),Payout.xp(player))

def Payout.item(+player: P.Players.State, kind: U32) -> P.Players.State:
  Payout.install(player,R.Rewards.add_item(P.Players.hero(player),kind),Payout.xp(player))

def Payout.side_reward(+player: P.Players.State, quest: U32) -> P.Players.State:
  Payout.install(player,R.Rewards.sidequest(P.Players.hero(player),quest),Payout.xp(player))

law Payout.gold_ok:
  for +player: P.Players.State
  for +amount: U32
  for +valid: P.Players.OK<player>
  P.Players.OK<Payout.gold(player,amount)>

def Payout.gold_ok(player,amount,valid):
  match valid:
    case P.Players.OK{vitals,equipped}:
      match vitals:
        case V.Vitals.OK{bound,life}:
          Payout.install_ok(player,R.Rewards.add_gold(P.Players.hero(player),amount),Payout.xp(player),life,R.Rewards.add_gold_health(P.Players.hero(player),amount,V.Vitals.hp(P.Players.vitals(player)),4294967295,bound),R.Rewards.add_gold_equipped(P.Players.hero(player),amount,equipped))

law Payout.item_ok:
  for +player: P.Players.State
  for +kind: U32
  for +valid: P.Players.OK<player>
  P.Players.OK<Payout.item(player,kind)>

def Payout.item_ok(player,kind,valid):
  match valid:
    case P.Players.OK{vitals,equipped}:
      match vitals:
        case V.Vitals.OK{bound,life}:
          Payout.install_ok(player,R.Rewards.add_item(P.Players.hero(player),kind),Payout.xp(player),life,R.Rewards.add_item_health(P.Players.hero(player),kind,V.Vitals.hp(P.Players.vitals(player)),4294967295,bound),R.Rewards.add_item_equipped(P.Players.hero(player),kind,equipped))

law Payout.side_reward_ok:
  for +player: P.Players.State
  for +quest: U32
  for +valid: P.Players.OK<player>
  P.Players.OK<Payout.side_reward(player,quest)>

def Payout.side_reward_ok(player,quest,valid):
  match valid:
    case P.Players.OK{vitals,equipped}:
      match vitals:
        case V.Vitals.OK{bound,life}:
          Payout.install_ok(player,R.Rewards.sidequest(P.Players.hero(player),quest),Payout.xp(player),life,R.Rewards.sidequest_health(P.Players.hero(player),quest,V.Vitals.hp(P.Players.vitals(player)),4294967295,bound),R.Rewards.sidequest_equipped(P.Players.hero(player),quest,equipped))

def Payout.bit(value: Bool) -> U32:
  match value:
    case False{}: 0
    case True{}: 1

def Payout.choose(value: Bool, yes: U32, no: U32) -> U32:
  match value:
    case False{}: no
    case True{}: yes

def Payout.score_meta(meta: P.Players.Meta, score_gain: U32, kill_gain: U32) -> P.Players.Meta:
  match meta:
    case P.Players.Meta{score,kills,found,name}:
      P.Players.Meta{U32.add(score,score_gain),U32.add(kills,kill_gain),found,name}

def Payout.score(+player: P.Players.State, score_gain: U32, kill_gain: U32) -> P.Players.State:
  Payout.profile(player,Payout.quest(player),Payout.score_meta(Payout.meta(player),score_gain,kill_gain))

law Payout.score_ok:
  for +player: P.Players.State
  for +score_gain: U32
  for +kill_gain: U32
  for +valid: P.Players.OK<player>
  P.Players.OK<Payout.score(player,score_gain,kill_gain)>

def Payout.score_ok(player,score_gain,kill_gain,valid):
  Payout.profile_ok(player,Payout.quest(player),Payout.score_meta(Payout.meta(player),score_gain,kill_gain),valid)

type Payout.Cull is Data:
  Payout.Cull{quest: P.Players.Quest, score: U32}

def Payout.cull_finish(+active: Bool, +count: U32, quest: P.Players.Quest, need: U32, score: U32) -> Payout.Cull:
  match quest:
    case P.Players.Quest{main,old,side0,side1,side2,claimed}:
      +done = Bool.and(active,U32.is_ge(count,need))
      Payout.Cull{P.Players.Quest{U32.add(main,Payout.bit(done)),count,side0,side1,side2,claimed},Payout.choose(done,score,0)}

def Payout.cull_quest(+quest: P.Players.Quest, kind: U32, need: U32, score: U32) -> Payout.Cull:
  match quest:
    case P.Players.Quest{main,count,side0,side1,side2,claimed}:
      +active = U32.is_eq(main,1)
      Payout.cull_finish(active,U32.add(count,Payout.bit(Bool.and(active,U32.is_eq(kind,0)))),P.Players.Quest{main,count,side0,side1,side2,claimed},need,score)

def Payout.cull_apply(+player: P.Players.State, result: Payout.Cull) -> P.Players.State:
  match result:
    case Payout.Cull{quest,score}:
      Payout.profile(player,quest,Payout.score_meta(Payout.meta(player),score,0))

def Payout.cull(+player: P.Players.State, kind: U32, need: U32, score: U32) -> P.Players.State:
  Payout.cull_apply(player,Payout.cull_quest(Payout.quest(player),kind,need,score))

law Payout.cull_apply_ok:
  for +player: P.Players.State
  for +result: Payout.Cull
  for +valid: P.Players.OK<player>
  P.Players.OK<Payout.cull_apply(player,result)>

def Payout.cull_apply_ok(player,result,valid):
  match result:
    case Payout.Cull{quest,score}: Payout.profile_ok(player,quest,Payout.score_meta(Payout.meta(player),score,0),valid)

law Payout.cull_ok:
  for +player: P.Players.State
  for +kind: U32
  for +need: U32
  for +score: U32
  for +valid: P.Players.OK<player>
  P.Players.OK<Payout.cull(player,kind,need,score)>

def Payout.cull_ok(player,kind,need,score,valid):
  Payout.cull_apply_ok(player,Payout.cull_quest(Payout.quest(player),kind,need,score),valid)

def Payout.side_index(+kind: U32) -> U32:
  Payout.choose(U32.is_eq(kind,1),0,Payout.choose(U32.is_eq(kind,3),1,Payout.choose(U32.is_eq(kind,4),2,9)))

def Payout.counter(+q: U32, quest: P.Players.Quest) -> U32:
  match quest:
    case P.Players.Quest{main,cull,side0,side1,side2,claimed}:
      Payout.choose(U32.is_eq(q,0),side0,Payout.choose(U32.is_eq(q,1),side1,side2))

def Payout.claimed(quest: P.Players.Quest) -> U32:
  match quest:
    case P.Players.Quest{main,cull,side0,side1,side2,claimed}: claimed

def Payout.mask(q: U32) -> U32:
  U32.shln(1,U32.to_nat(U32.and(q,31)))

def Payout.has_bit(word: U32, q: U32) -> Bool:
  U32.is_eq(U32.and(U32.shrn(word,U32.to_nat(U32.and(q,31))),1),1)

def Payout.side_quest(quest: P.Players.Quest, +q: U32, +count: U32, claimed: U32) -> P.Players.Quest:
  match quest:
    case P.Players.Quest{main,cull,side0,side1,side2,old}:
      P.Players.Quest{main,cull,Payout.choose(U32.is_eq(q,0),count,side0),Payout.choose(U32.is_eq(q,1),count,side1),Payout.choose(U32.is_eq(q,2),count,side2),claimed}

type Payout.Side is Data:
  Payout.Side{player: P.Players.State, completed: Maybe<&2,U32>}

def Payout.side_player(result: Payout.Side) -> P.Players.State:
  match result:
    case Payout.Side{player,completed}: player

def Payout.completed(result: Payout.Side) -> Maybe<&2,U32>:
  match result:
    case Payout.Side{player,completed}: completed

def Payout.side_finish(done: Bool, +player: P.Players.State, +q: U32, count: U32, claimed: U32, score: U32) -> Payout.Side:
  match done:
    case False{}:
      Payout.Side{Payout.profile(player,Payout.side_quest(Payout.quest(player),q,count,claimed),Payout.meta(player)),None{}}
    case True{}:
      Payout.Side{Payout.profile(Payout.side_reward(player,q),Payout.side_quest(Payout.quest(player),q,count,U32.or(claimed,Payout.mask(q))),Payout.score_meta(Payout.meta(player),score,0)),Some{q}}

def Payout.side_gate(blocked: Bool, +player: P.Players.State, +q: U32, need: U32, score: U32) -> Payout.Side:
  match blocked:
    case True{}: Payout.Side{player,None{}}
    case False{}:
      +count = U32.add(Payout.counter(q,Payout.quest(player)),1)
      Payout.side_finish(U32.is_ge(count,need),player,q,count,Payout.claimed(Payout.quest(player)),score)

def Payout.side(+player: P.Players.State, +q: U32, need: U32, score: U32) -> Payout.Side:
  Payout.side_gate(Bool.or(U32.is_gt(q,2),Payout.has_bit(Payout.claimed(Payout.quest(player)),q)),player,q,need,score)

law Payout.side_finish_ok:
  for +done: Bool
  for +player: P.Players.State
  for +q: U32
  for +count: U32
  for +claimed: U32
  for +score: U32
  for +valid: P.Players.OK<player>
  P.Players.OK<Payout.side_player(Payout.side_finish(done,player,q,count,claimed,score))>

def Payout.side_finish_ok(done,player,q,count,claimed,score,valid):
  match done:
    case False{}: Payout.profile_ok(player,Payout.side_quest(Payout.quest(player),q,count,claimed),Payout.meta(player),valid)
    case True{}: Payout.profile_ok(Payout.side_reward(player,q),Payout.side_quest(Payout.quest(player),q,count,U32.or(claimed,Payout.mask(q))),Payout.score_meta(Payout.meta(player),score,0),Payout.side_reward_ok(player,q,valid))

law Payout.side_gate_ok:
  for +blocked: Bool
  for +player: P.Players.State
  for +q: U32
  for +need: U32
  for +score: U32
  for +valid: P.Players.OK<player>
  P.Players.OK<Payout.side_player(Payout.side_gate(blocked,player,q,need,score))>

def Payout.side_gate_ok(blocked,player,q,need,score,valid):
  match blocked:
    case True{}: valid
    case False{}: Payout.side_finish_ok(U32.is_ge(U32.add(Payout.counter(q,Payout.quest(player)),1),need),player,q,U32.add(Payout.counter(q,Payout.quest(player)),1),Payout.claimed(Payout.quest(player)),score,valid)

law Payout.side_ok:
  for +player: P.Players.State
  for +q: U32
  for +need: U32
  for +score: U32
  for +valid: P.Players.OK<player>
  P.Players.OK<Payout.side_player(Payout.side(player,q,need,score))>

def Payout.side_ok(player,q,need,score,valid):
  Payout.side_gate_ok(Bool.or(U32.is_gt(q,2),Payout.has_bit(Payout.claimed(Payout.quest(player)),q)),player,q,need,score,valid)

def Payout.found(player: P.Players.State) -> U32:
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match meta:
        case P.Players.Meta{score,kills,found,name}: found

def Payout.loot_meta(meta: P.Players.Meta, kind: U32, score_gain: U32) -> P.Players.Meta:
  match meta:
    case P.Players.Meta{score,kills,found,name}:
      P.Players.Meta{U32.add(score,score_gain),kills,U32.or(found,Payout.mask(kind)),name}

type Payout.Drop is Data:
  Payout.Drop{player: P.Players.State, item: Maybe<&2,U32>}

def Payout.drop_player(result: Payout.Drop) -> P.Players.State:
  match result:
    case Payout.Drop{player,item}: player

def Payout.dropped(result: Payout.Drop) -> Maybe<&2,U32>:
  match result:
    case Payout.Drop{player,item}: item

def Payout.drop_gate(missing: Bool, +player: P.Players.State, +kind: U32, score: U32) -> Payout.Drop:
  match missing:
    case True{}: Payout.Drop{player,None{}}
    case False{}:
      Payout.Drop{Payout.profile(Payout.item(player,kind),Payout.quest(player),Payout.loot_meta(Payout.meta(player),kind,Payout.choose(Payout.has_bit(Payout.found(player),kind),0,score))),Some{kind}}

def Payout.drop(+player: P.Players.State, +kind: U32, score: U32) -> Payout.Drop:
  Payout.drop_gate(U32.is_eq(kind,4294967295),player,kind,score)

law Payout.drop_gate_ok:
  for +missing: Bool
  for +player: P.Players.State
  for +kind: U32
  for +score: U32
  for +valid: P.Players.OK<player>
  P.Players.OK<Payout.drop_player(Payout.drop_gate(missing,player,kind,score))>

def Payout.drop_gate_ok(missing,player,kind,score,valid):
  match missing:
    case True{}: valid
    case False{}: Payout.profile_ok(Payout.item(player,kind),Payout.quest(player),Payout.loot_meta(Payout.meta(player),kind,Payout.choose(Payout.has_bit(Payout.found(player),kind),0,score)),Payout.item_ok(player,kind,valid))

law Payout.drop_ok:
  for +player: P.Players.State
  for +kind: U32
  for +score: U32
  for +valid: P.Players.OK<player>
  P.Players.OK<Payout.drop_player(Payout.drop(player,kind,score))>

def Payout.drop_ok(player,kind,score,valid):
  Payout.drop_gate_ok(U32.is_eq(kind,4294967295),player,kind,score,valid)

# Catalog-derived amounts and drop choice are supplied by the server. The
# checked composition below applies every award to the preceding result.
type Payout.Plan is Data:
  Payout.Plan{kind: U32, xp: U32, gold: U32, score: U32, side_need: U32, side_score: U32, drop: U32, find_score: U32, bonus: U32, cull_need: U32, cull_score: U32}

type Payout.Kill is Data:
  Payout.Kill{player: P.Players.State, side: Maybe<&2,U32>, drop: Maybe<&2,U32>, levels: U32}

def Payout.killer(result: Payout.Kill) -> P.Players.State:
  match result:
    case Payout.Kill{player,side,drop,levels}: player

def Payout.kill_finish(side: Maybe<&2,U32>, drop: Payout.Drop, levels: U32, bonus: U32) -> Payout.Kill:
  match drop:
    case Payout.Drop{player,item}:
      Payout.Kill{Payout.score(player,bonus,0),side,item,levels}

def Payout.kill_drop(+side: Payout.Side, drop: U32, find_score: U32, levels: U32, bonus: U32) -> Payout.Kill:
  Payout.kill_finish(Payout.completed(side),Payout.drop(Payout.side_player(side),drop,find_score),levels,bonus)

def Payout.kill_side(player: P.Players.State, +plan: Payout.Plan, levels: U32) -> Payout.Kill:
  match plan:
    case Payout.Plan{kind,xp,gold,score,side_need,side_score,drop,find_score,bonus,cull_need,cull_score}:
      Payout.kill_drop(Payout.side(Payout.cull(Payout.score(Payout.gold(player,gold),score,1),kind,cull_need,cull_score),Payout.side_index(kind),side_need,side_score),drop,find_score,levels,bonus)

def Payout.kill_xp(result: Payout.Experience, plan: Payout.Plan) -> Payout.Kill:
  match result:
    case Payout.Experience{player,levels}: Payout.kill_side(player,plan,levels)

def Payout.plan_xp(plan: Payout.Plan) -> U32:
  match plan:
    case Payout.Plan{kind,xp,gold,score,side_need,side_score,drop,find_score,bonus,cull_need,cull_score}: xp

def Payout.kill(player: P.Players.State, +plan: Payout.Plan) -> Payout.Kill:
  Payout.kill_xp(Payout.experience(player,Payout.plan_xp(plan)),plan)

law Payout.kill_finish_ok:
  for +side: Maybe<&2,U32>
  for +drop: Payout.Drop
  for +levels: U32
  for +bonus: U32
  for +valid: P.Players.OK<Payout.drop_player(drop)>
  P.Players.OK<Payout.killer(Payout.kill_finish(side,drop,levels,bonus))>

def Payout.kill_finish_ok(side,drop,levels,bonus,valid):
  match drop:
    case Payout.Drop{player,item}: Payout.score_ok(player,bonus,0,valid)

law Payout.kill_drop_ok:
  for +side: Payout.Side
  for +drop: U32
  for +find_score: U32
  for +levels: U32
  for +bonus: U32
  for +valid: P.Players.OK<Payout.side_player(side)>
  P.Players.OK<Payout.killer(Payout.kill_drop(side,drop,find_score,levels,bonus))>

def Payout.kill_drop_ok(side,drop,find_score,levels,bonus,valid):
  Payout.kill_finish_ok(Payout.completed(side),Payout.drop(Payout.side_player(side),drop,find_score),levels,bonus,Payout.drop_ok(Payout.side_player(side),drop,find_score,valid))

law Payout.kill_side_ok:
  for +player: P.Players.State
  for +plan: Payout.Plan
  for +levels: U32
  for +valid: P.Players.OK<player>
  P.Players.OK<Payout.killer(Payout.kill_side(player,plan,levels))>

def Payout.kill_side_ok(player,plan,levels,valid):
  match plan:
    case Payout.Plan{kind,xp,gold,score,side_need,side_score,drop,find_score,bonus,cull_need,cull_score}:
      +funded = Payout.gold(player,gold)
      +scored = Payout.score(funded,score,1)
      +culled = Payout.cull(scored,kind,cull_need,cull_score)
      Payout.kill_drop_ok(Payout.side(culled,Payout.side_index(kind),side_need,side_score),drop,find_score,levels,bonus,Payout.side_ok(culled,Payout.side_index(kind),side_need,side_score,Payout.cull_ok(scored,kind,cull_need,cull_score,Payout.score_ok(funded,score,1,Payout.gold_ok(player,gold,valid)))))

law Payout.kill_xp_ok:
  for +result: Payout.Experience
  for +plan: Payout.Plan
  for +valid: P.Players.OK<Payout.experienced(result)>
  P.Players.OK<Payout.killer(Payout.kill_xp(result,plan))>

def Payout.kill_xp_ok(result,plan,valid):
  match result:
    case Payout.Experience{player,levels}: Payout.kill_side_ok(player,plan,levels,valid)

law Payout.kill_ok:
  for +player: P.Players.State
  for +plan: Payout.Plan
  for +valid: P.Players.OK<player>
  P.Players.OK<Payout.killer(Payout.kill(player,plan))>

def Payout.kill_ok(player,plan,valid):
  Payout.kill_xp_ok(Payout.experience(player,Payout.plan_xp(plan)),plan,Payout.experience_ok(player,Payout.plan_xp(plan),valid))

def Payout.main(quest: P.Players.Quest) -> U32:
  match quest:
    case P.Players.Quest{main,cull,side0,side1,side2,claimed}: main

def Payout.next_main(quest: P.Players.Quest) -> P.Players.Quest:
  match quest:
    case P.Players.Quest{main,cull,side0,side1,side2,claimed}:
      P.Players.Quest{U32.add(main,1),cull,side0,side1,side2,claimed}

def Payout.sigil_gate(advance: Bool, +player: P.Players.State, score: U32) -> P.Players.State:
  match advance:
    case False{}: player
    case True{}: Payout.profile(player,Payout.next_main(Payout.quest(player)),Payout.score_meta(Payout.meta(player),score,0))

def Payout.sigil(+player: P.Players.State, stage: U32, score: U32) -> P.Players.State:
  Payout.sigil_gate(U32.is_eq(Payout.main(Payout.quest(player)),stage),player,score)

def Payout.sigil_all(players: List<&2,P.Players.State>, +stage: U32, +score: U32) -> List<&2,P.Players.State>:
  match players:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{Payout.sigil(head,stage,score),Payout.sigil_all(rest,stage,score)}

law Payout.sigil_gate_ok:
  for +advance: Bool
  for +player: P.Players.State
  for +score: U32
  for +valid: P.Players.OK<player>
  P.Players.OK<Payout.sigil_gate(advance,player,score)>

def Payout.sigil_gate_ok(advance,player,score,valid):
  match advance:
    case False{}: valid
    case True{}: Payout.profile_ok(player,Payout.next_main(Payout.quest(player)),Payout.score_meta(Payout.meta(player),score,0),valid)

law Payout.sigil_ok:
  for +player: P.Players.State
  for +stage: U32
  for +score: U32
  for +valid: P.Players.OK<player>
  P.Players.OK<Payout.sigil(player,stage,score)>

def Payout.sigil_ok(player,stage,score,valid):
  Payout.sigil_gate_ok(U32.is_eq(Payout.main(Payout.quest(player)),stage),player,score,valid)

law Payout.sigil_all_ok:
  for +players: List<&2,P.Players.State>
  for +stage: U32
  for +score: U32
  for +valid: P.Players.All(players)
  P.Players.All(Payout.sigil_all(players,stage,score))

def Payout.sigil_all_ok(players,stage,score,valid):
  match players:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match valid:
        case Tuple{head_ok,rest_ok}:
          Tuple{Payout.sigil_ok(head,stage,score,head_ok),Payout.sigil_all_ok(rest,stage,score,rest_ok)}

law Payout.sigil_all_count:
  for +players: List<&2,P.Players.State>
  for +stage: U32
  for +score: U32
  {P.Players.length(Payout.sigil_all(players,stage,score)) == P.Players.length(players) : Nat}

def Payout.sigil_all_count(players,stage,score):
  match players:
    case Nil{}: {==}
    case Con{head,rest}:
      %Payout.sigil_all_count(rest,stage,score) : {Succ{P.Players.length(Payout.sigil_all(rest,stage,score))} == Succ{_} : Nat}
      {==}

def Payout.boss_stage(+kind: U32) -> U32:
  Payout.choose(U32.is_eq(kind,6),2,Payout.choose(U32.is_eq(kind,7),3,Payout.choose(U32.is_eq(kind,8),4,9)))

def Payout.advance_gate(skip: Bool, players: List<&2,P.Players.State>, stage: U32, score: U32) -> List<&2,P.Players.State>:
  match skip:
    case True{}: players
    case False{}: Payout.sigil_all(players,stage,score)

def Payout.advance(players: List<&2,P.Players.State>, kind: U32, score: U32) -> List<&2,P.Players.State>:
  +stage = Payout.boss_stage(kind)
  Payout.advance_gate(U32.is_eq(stage,9),players,stage,score)

law Payout.advance_gate_ok:
  for +skip: Bool
  for +players: List<&2,P.Players.State>
  for +stage: U32
  for +score: U32
  for +valid: P.Players.All(players)
  P.Players.All(Payout.advance_gate(skip,players,stage,score))

def Payout.advance_gate_ok(skip,players,stage,score,valid):
  match skip:
    case True{}: valid
    case False{}: Payout.sigil_all_ok(players,stage,score,valid)

law Payout.advance_ok:
  for +players: List<&2,P.Players.State>
  for +kind: U32
  for +score: U32
  for +valid: P.Players.All(players)
  P.Players.All(Payout.advance(players,kind,score))

def Payout.advance_ok(players,kind,score,valid):
  Payout.advance_gate_ok(U32.is_eq(Payout.boss_stage(kind),9),players,Payout.boss_stage(kind),score,valid)

law Payout.advance_gate_count:
  for +skip: Bool
  for +players: List<&2,P.Players.State>
  for +stage: U32
  for +score: U32
  {P.Players.length(Payout.advance_gate(skip,players,stage,score)) == P.Players.length(players) : Nat}

def Payout.advance_gate_count(skip,players,stage,score):
  match skip:
    case True{}: {==}
    case False{}: Payout.sigil_all_count(players,stage,score)

law Payout.advance_count:
  for +players: List<&2,P.Players.State>
  for +kind: U32
  for +score: U32
  {P.Players.length(Payout.advance(players,kind,score)) == P.Players.length(players) : Nat}

def Payout.advance_count(players,kind,score):
  Payout.advance_gate_count(U32.is_eq(Payout.boss_stage(kind),9),players,Payout.boss_stage(kind),score)

def Payout.kind(plan: Payout.Plan) -> U32:
  match plan:
    case Payout.Plan{kind,xp,gold,score,side_need,side_score,drop,find_score,bonus,cull_need,cull_score}: kind

type Payout.Result is Data:
  Payout.Result{players: List<&2,P.Players.State>, paid: Maybe<&2,Payout.Kill>}

def Payout.roster(result: Payout.Result) -> List<&2,P.Players.State>:
  match result:
    case Payout.Result{players,paid}: players

def Payout.finish_taken(others: List<&2,P.Players.State>, +paid: Payout.Kill, kind: U32, score: U32) -> Payout.Result:
  Payout.Result{Payout.advance(Con{Payout.killer(paid),others},kind,score),Some{paid}}

def Payout.apply_taken(taken: P.Players.Take, +plan: Payout.Plan, score: U32) -> Payout.Result:
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}: Payout.Result{others,None{}}
        case Some{player}: Payout.finish_taken(others,Payout.kill(player,plan),Payout.kind(plan),score)

def Payout.run(players: List<&2,P.Players.State>, target: U32, plan: Payout.Plan, score: U32) -> Payout.Result:
  Payout.apply_taken(P.Players.take(players,target),plan,score)

law Payout.finish_taken_ok:
  for +others: List<&2,P.Players.State>
  for +paid: Payout.Kill
  for +kind: U32
  for +score: U32
  for +others_ok: P.Players.All(others)
  for +paid_ok: P.Players.OK<Payout.killer(paid)>
  P.Players.All(Payout.roster(Payout.finish_taken(others,paid,kind,score)))

def Payout.finish_taken_ok(others,paid,kind,score,others_ok,paid_ok):
  Payout.advance_ok(Con{Payout.killer(paid),others},kind,score,Tuple{paid_ok,others_ok})

law Payout.apply_taken_ok:
  for +taken: P.Players.Take
  for +plan: Payout.Plan
  for +score: U32
  for +valid: P.Players.TakeOK<taken>
  P.Players.All(Payout.roster(Payout.apply_taken(taken,plan,score)))

def Payout.apply_taken_ok(taken,plan,score,valid):
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}:
          match valid:
            case P.Players.ValidTake{others_ok,found_ok}: others_ok
        case Some{player}:
          match valid:
            case P.Players.ValidTake{others_ok,found_ok}:
              Payout.finish_taken_ok(others,Payout.kill(player,plan),Payout.kind(plan),score,others_ok,Payout.kill_ok(player,plan,found_ok))

law Payout.run_ok:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +plan: Payout.Plan
  for +score: U32
  for +valid: P.Players.All(players)
  P.Players.All(Payout.roster(Payout.run(players,target,plan,score)))

def Payout.run_ok(players,target,plan,score,valid):
  Payout.apply_taken_ok(P.Players.take(players,target),plan,score,P.Players.take_ok(players,target,valid))

law Payout.apply_taken_count:
  for +taken: P.Players.Take
  for +plan: Payout.Plan
  for +score: U32
  {P.Players.length(Payout.roster(Payout.apply_taken(taken,plan,score))) == P.Players.length(P.Players.restore(taken)) : Nat}

def Payout.apply_taken_count(taken,plan,score):
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}: {==}
        case Some{player}: Payout.advance_count(Con{Payout.killer(Payout.kill(player,plan)),others},Payout.kind(plan),score)

law Payout.run_count:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +plan: Payout.Plan
  for +score: U32
  {P.Players.length(Payout.roster(Payout.run(players,target,plan,score))) == P.Players.length(players) : Nat}

def Payout.run_count(players,target,plan,score):
  Equal.trans(Nat,P.Players.length(Payout.roster(Payout.run(players,target,plan,score))),P.Players.length(P.Players.restore(P.Players.take(players,target))),P.Players.length(players),Payout.apply_taken_count(P.Players.take(players,target),plan,score),P.Players.take_count(players,target))

law Payout.run_missing:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +plan: Payout.Plan
  for +score: U32
  for +missing: {P.Players.has_id(players,target) == False{} : Bool}
  {Payout.run(players,target,plan,score) == Payout.Result{players,None{}} : Payout.Result}

def Payout.run_missing(players,target,plan,score,missing):
  %Equal.sym(P.Players.Take,P.Players.take(players,target),P.Players.Take{players,None{}},P.Players.take_missing(players,target,missing)) : {Payout.apply_taken(_,plan,score) == Payout.Result{players,None{}} : Payout.Result}
  {==}

# Payouts retain identity, position, health, death state, timers, cosmetics,
# and name. Only the explicitly rewarded hero/XP/quest/counter fields vary.
type Payout.Frame is Data:
  Payout.Frame{pid: U32,cid: U32,pos: P.Players.Pos,hp: U32,dead: U32,respawn: U32,attack: U32,spin: U32,style: P.Players.Style,name: List<&2,Char>}

def Payout.frame(player: P.Players.State) -> Payout.Frame:
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match vitals:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}:
          match meta:
            case P.Players.Meta{score,kills,found,name}: Payout.Frame{pid,cid,pos,hp,dead,respawn,attack,spin,style,name}

law Payout.install_frame:
  for +player: P.Players.State
  for +hero: G.Bq.Hero
  for +xp: U32
  {Payout.frame(Payout.install(player,hero,xp)) == Payout.frame(player) : Payout.Frame}

def Payout.install_frame(player,hero,xp):
  match player:
    case P.Players.State{pid,cid,old,pos,vitals,style,quest,meta}:
      match vitals:
        case V.Vitals.State{hp,old_xp,dead,respawn,attack,spin}:
          match meta:
            case P.Players.Meta{score,kills,found,name}: {==}

law Payout.profile_frame:
  for +player: P.Players.State
  for +quest: P.Players.Quest
  for +meta: P.Players.Meta
  {Payout.frame(Payout.profile(player,quest,meta)) == Payout.frame(player) : Payout.Frame}

def Payout.profile_frame(player,quest,meta):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,old_q,old_m}:
      match vitals:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}:
          match old_m:
            case P.Players.Meta{old_score,old_kills,old_found,name}:
              match meta:
                case P.Players.Meta{score,kills,found,unused_name}: {==}

law Payout.finish_xp_frame:
  for +player: P.Players.State
  for +gained: R.Rewards.Result
  {Payout.frame(Payout.experienced(Payout.finish_xp(player,gained))) == Payout.frame(player) : Payout.Frame}

def Payout.finish_xp_frame(player,gained):
  match gained:
    case R.Rewards.Result{hero,xp,levels}: Payout.install_frame(player,hero,xp)

law Payout.experience_frame:
  for +player: P.Players.State
  for +gained: U32
  {Payout.frame(Payout.experienced(Payout.experience(player,gained))) == Payout.frame(player) : Payout.Frame}

def Payout.experience_frame(player,gained):
  Payout.finish_xp_frame(player,R.Rewards.gain(P.Players.hero(player),Payout.xp(player),gained))

law Payout.gold_frame:
  for +player: P.Players.State
  for +amount: U32
  {Payout.frame(Payout.gold(player,amount)) == Payout.frame(player) : Payout.Frame}

def Payout.gold_frame(player,amount):
  Payout.install_frame(player,R.Rewards.add_gold(P.Players.hero(player),amount),Payout.xp(player))

law Payout.item_frame:
  for +player: P.Players.State
  for +kind: U32
  {Payout.frame(Payout.item(player,kind)) == Payout.frame(player) : Payout.Frame}

def Payout.item_frame(player,kind):
  Payout.install_frame(player,R.Rewards.add_item(P.Players.hero(player),kind),Payout.xp(player))

law Payout.side_reward_frame:
  for +player: P.Players.State
  for +quest: U32
  {Payout.frame(Payout.side_reward(player,quest)) == Payout.frame(player) : Payout.Frame}

def Payout.side_reward_frame(player,quest):
  Payout.install_frame(player,R.Rewards.sidequest(P.Players.hero(player),quest),Payout.xp(player))

law Payout.score_frame:
  for +player: P.Players.State
  for +score: U32
  for +kills: U32
  {Payout.frame(Payout.score(player,score,kills)) == Payout.frame(player) : Payout.Frame}

def Payout.score_frame(player,score,kills):
  Payout.profile_frame(player,Payout.quest(player),Payout.score_meta(Payout.meta(player),score,kills))

law Payout.cull_apply_frame:
  for +player: P.Players.State
  for +result: Payout.Cull
  {Payout.frame(Payout.cull_apply(player,result)) == Payout.frame(player) : Payout.Frame}

def Payout.cull_apply_frame(player,result):
  match result:
    case Payout.Cull{quest,score}: Payout.profile_frame(player,quest,Payout.score_meta(Payout.meta(player),score,0))

law Payout.cull_frame:
  for +player: P.Players.State
  for +kind: U32
  for +need: U32
  for +score: U32
  {Payout.frame(Payout.cull(player,kind,need,score)) == Payout.frame(player) : Payout.Frame}

def Payout.cull_frame(player,kind,need,score):
  Payout.cull_apply_frame(player,Payout.cull_quest(Payout.quest(player),kind,need,score))

law Payout.side_finish_frame:
  for +done: Bool
  for +player: P.Players.State
  for +q: U32
  for +count: U32
  for +claimed: U32
  for +score: U32
  {Payout.frame(Payout.side_player(Payout.side_finish(done,player,q,count,claimed,score))) == Payout.frame(player) : Payout.Frame}

def Payout.side_finish_frame(done,player,q,count,claimed,score):
  match done:
    case False{}: Payout.profile_frame(player,Payout.side_quest(Payout.quest(player),q,count,claimed),Payout.meta(player))
    case True{}:
      Equal.trans(Payout.Frame,Payout.frame(Payout.side_player(Payout.side_finish(True{},player,q,count,claimed,score))),Payout.frame(Payout.side_reward(player,q)),Payout.frame(player),Payout.profile_frame(Payout.side_reward(player,q),Payout.side_quest(Payout.quest(player),q,count,U32.or(claimed,Payout.mask(q))),Payout.score_meta(Payout.meta(player),score,0)),Payout.side_reward_frame(player,q))

law Payout.side_gate_frame:
  for +blocked: Bool
  for +player: P.Players.State
  for +q: U32
  for +need: U32
  for +score: U32
  {Payout.frame(Payout.side_player(Payout.side_gate(blocked,player,q,need,score))) == Payout.frame(player) : Payout.Frame}

def Payout.side_gate_frame(blocked,player,q,need,score):
  match blocked:
    case True{}: {==}
    case False{}: Payout.side_finish_frame(U32.is_ge(U32.add(Payout.counter(q,Payout.quest(player)),1),need),player,q,U32.add(Payout.counter(q,Payout.quest(player)),1),Payout.claimed(Payout.quest(player)),score)

law Payout.side_frame:
  for +player: P.Players.State
  for +q: U32
  for +need: U32
  for +score: U32
  {Payout.frame(Payout.side_player(Payout.side(player,q,need,score))) == Payout.frame(player) : Payout.Frame}

def Payout.side_frame(player,q,need,score):
  Payout.side_gate_frame(Bool.or(U32.is_gt(q,2),Payout.has_bit(Payout.claimed(Payout.quest(player)),q)),player,q,need,score)

law Payout.drop_gate_frame:
  for +missing: Bool
  for +player: P.Players.State
  for +kind: U32
  for +score: U32
  {Payout.frame(Payout.drop_player(Payout.drop_gate(missing,player,kind,score))) == Payout.frame(player) : Payout.Frame}

def Payout.drop_gate_frame(missing,player,kind,score):
  match missing:
    case True{}: {==}
    case False{}:
      Equal.trans(Payout.Frame,Payout.frame(Payout.drop_player(Payout.drop_gate(False{},player,kind,score))),Payout.frame(Payout.item(player,kind)),Payout.frame(player),Payout.profile_frame(Payout.item(player,kind),Payout.quest(player),Payout.loot_meta(Payout.meta(player),kind,Payout.choose(Payout.has_bit(Payout.found(player),kind),0,score))),Payout.item_frame(player,kind))

law Payout.drop_frame:
  for +player: P.Players.State
  for +kind: U32
  for +score: U32
  {Payout.frame(Payout.drop_player(Payout.drop(player,kind,score))) == Payout.frame(player) : Payout.Frame}

def Payout.drop_frame(player,kind,score):
  Payout.drop_gate_frame(U32.is_eq(kind,4294967295),player,kind,score)

law Payout.kill_finish_frame:
  for +side: Maybe<&2,U32>
  for +drop: Payout.Drop
  for +levels: U32
  for +bonus: U32
  {Payout.frame(Payout.killer(Payout.kill_finish(side,drop,levels,bonus))) == Payout.frame(Payout.drop_player(drop)) : Payout.Frame}

def Payout.kill_finish_frame(side,drop,levels,bonus):
  match drop:
    case Payout.Drop{player,item}: Payout.score_frame(player,bonus,0)

law Payout.kill_drop_frame:
  for +side: Payout.Side
  for +drop: U32
  for +find_score: U32
  for +levels: U32
  for +bonus: U32
  {Payout.frame(Payout.killer(Payout.kill_drop(side,drop,find_score,levels,bonus))) == Payout.frame(Payout.side_player(side)) : Payout.Frame}

def Payout.kill_drop_frame(side,drop,find_score,levels,bonus):
  Equal.trans(Payout.Frame,Payout.frame(Payout.killer(Payout.kill_drop(side,drop,find_score,levels,bonus))),Payout.frame(Payout.drop_player(Payout.drop(Payout.side_player(side),drop,find_score))),Payout.frame(Payout.side_player(side)),Payout.kill_finish_frame(Payout.completed(side),Payout.drop(Payout.side_player(side),drop,find_score),levels,bonus),Payout.drop_frame(Payout.side_player(side),drop,find_score))

law Payout.kill_side_frame:
  for +player: P.Players.State
  for +plan: Payout.Plan
  for +levels: U32
  {Payout.frame(Payout.killer(Payout.kill_side(player,plan,levels))) == Payout.frame(player) : Payout.Frame}

def Payout.kill_side_frame(player,plan,levels):
  match plan:
    case Payout.Plan{kind,xp,gold,score,side_need,side_score,drop,find_score,bonus,cull_need,cull_score}:
      +funded = Payout.gold(player,gold)
      +scored = Payout.score(funded,score,1)
      +culled = Payout.cull(scored,kind,cull_need,cull_score)
      +side = Payout.side(culled,Payout.side_index(kind),side_need,side_score)
      Equal.trans(Payout.Frame,Payout.frame(Payout.killer(Payout.kill_drop(side,drop,find_score,levels,bonus))),Payout.frame(Payout.side_player(side)),Payout.frame(player),Payout.kill_drop_frame(side,drop,find_score,levels,bonus),
        Equal.trans(Payout.Frame,Payout.frame(Payout.side_player(side)),Payout.frame(culled),Payout.frame(player),Payout.side_frame(culled,Payout.side_index(kind),side_need,side_score),
          Equal.trans(Payout.Frame,Payout.frame(culled),Payout.frame(scored),Payout.frame(player),Payout.cull_frame(scored,kind,cull_need,cull_score),
            Equal.trans(Payout.Frame,Payout.frame(scored),Payout.frame(funded),Payout.frame(player),Payout.score_frame(funded,score,1),Payout.gold_frame(player,gold)))))

law Payout.kill_xp_frame:
  for +result: Payout.Experience
  for +plan: Payout.Plan
  {Payout.frame(Payout.killer(Payout.kill_xp(result,plan))) == Payout.frame(Payout.experienced(result)) : Payout.Frame}

def Payout.kill_xp_frame(result,plan):
  match result:
    case Payout.Experience{player,levels}: Payout.kill_side_frame(player,plan,levels)

law Payout.kill_frame:
  for +player: P.Players.State
  for +plan: Payout.Plan
  {Payout.frame(Payout.killer(Payout.kill(player,plan))) == Payout.frame(player) : Payout.Frame}

def Payout.kill_frame(player,plan):
  Equal.trans(Payout.Frame,Payout.frame(Payout.killer(Payout.kill(player,plan))),Payout.frame(Payout.experienced(Payout.experience(player,Payout.plan_xp(plan)))),Payout.frame(player),Payout.kill_xp_frame(Payout.experience(player,Payout.plan_xp(plan)),plan),Payout.experience_frame(player,Payout.plan_xp(plan)))

law Payout.install_hero:
  for +player: P.Players.State
  for +hero: G.Bq.Hero
  for +xp: U32
  {P.Players.hero(Payout.install(player,hero,xp)) == hero : G.Bq.Hero}

def Payout.install_hero(player,hero,xp):
  match player:
    case P.Players.State{pid,cid,old,pos,vitals,style,quest,meta}:
      match vitals:
        case V.Vitals.State{hp,old_xp,dead,respawn,attack,spin}: {==}

law Payout.install_xp:
  for +player: P.Players.State
  for +hero: G.Bq.Hero
  for +xp: U32
  {Payout.xp(Payout.install(player,hero,xp)) == xp : U32}

def Payout.install_xp(player,hero,xp):
  match player:
    case P.Players.State{pid,cid,old,pos,vitals,style,quest,meta}:
      match vitals:
        case V.Vitals.State{hp,old_xp,dead,respawn,attack,spin}: {==}

law Payout.gold_amount_hero:
  for +hero: G.Bq.Hero
  for +amount: U32
  {G.Bq.hero_gold(R.Rewards.add_gold(hero,amount)) == G.Bq.Nat.add(U32.to_nat(amount),G.Bq.hero_gold(hero)) : Nat}

def Payout.gold_amount_hero(hero,amount):
  match hero:
    case G.Bq.Hero.Hero{bag,wea,arm,hel,charm,gold,lv,str,agi,vit,pts}: {==}

law Payout.gold_amount:
  for +player: P.Players.State
  for +amount: U32
  {G.Bq.hero_gold(P.Players.hero(Payout.gold(player,amount))) == G.Bq.Nat.add(U32.to_nat(amount),G.Bq.hero_gold(P.Players.hero(player))) : Nat}

def Payout.gold_amount(player,amount):
  %Equal.sym(G.Bq.Hero,P.Players.hero(Payout.gold(player,amount)),R.Rewards.add_gold(P.Players.hero(player),amount),Payout.install_hero(player,R.Rewards.add_gold(P.Players.hero(player),amount),Payout.xp(player))) : {G.Bq.hero_gold(_) == G.Bq.Nat.add(U32.to_nat(amount),G.Bq.hero_gold(P.Players.hero(player))) : Nat}
  Payout.gold_amount_hero(P.Players.hero(player),amount)

law Payout.item_census_hero:
  for +hero: G.Bq.Hero
  for +kind: U32
  {G.Bq.census(R.Rewards.add_item(hero,kind)) == G.Bq.Bag.add(G.Bq.one(U32.to_nat(kind)),G.Bq.census(hero)) : G.Bq.Bag}

def Payout.item_census_hero(hero,kind):
  match hero:
    case G.Bq.Hero.Hero{bag,wea,arm,hel,charm,gold,lv,str,agi,vit,pts}:
      G.Bq.Bag.add_assoc(G.Bq.one(U32.to_nat(kind)),bag,G.Bq.gear_bag(wea,arm,hel,charm))

law Payout.item_census:
  for +player: P.Players.State
  for +kind: U32
  {G.Bq.census(P.Players.hero(Payout.item(player,kind))) == G.Bq.Bag.add(G.Bq.one(U32.to_nat(kind)),G.Bq.census(P.Players.hero(player))) : G.Bq.Bag}

def Payout.item_census(player,kind):
  %Equal.sym(G.Bq.Hero,P.Players.hero(Payout.item(player,kind)),R.Rewards.add_item(P.Players.hero(player),kind),Payout.install_hero(player,R.Rewards.add_item(P.Players.hero(player),kind),Payout.xp(player))) : {G.Bq.census(_) == G.Bq.Bag.add(G.Bq.one(U32.to_nat(kind)),G.Bq.census(P.Players.hero(player))) : G.Bq.Bag}
  Payout.item_census_hero(P.Players.hero(player),kind)

# An experience receipt includes all outputs, so retaining valid old state
# cannot satisfy this law by silently dropping the actual XP/level result.
type Payout.XPReceipt is Data:
  Payout.XPReceipt{hero: G.Bq.Hero,xp: U32,levels: U32}

def Payout.xp_receipt(+result: Payout.Experience) -> Payout.XPReceipt:
  Payout.XPReceipt{P.Players.hero(Payout.experienced(result)),Payout.xp(Payout.experienced(result)),Payout.levels(result)}

def Payout.reward_receipt(result: R.Rewards.Result) -> Payout.XPReceipt:
  match result:
    case R.Rewards.Result{hero,xp,levels}: Payout.XPReceipt{hero,xp,levels}

law Payout.finish_xp_exact:
  for +player: P.Players.State
  for +result: R.Rewards.Result
  {Payout.xp_receipt(Payout.finish_xp(player,result)) == Payout.reward_receipt(result) : Payout.XPReceipt}

def Payout.finish_xp_exact(player,result):
  match result:
    case R.Rewards.Result{hero,xp,levels}:
      %Payout.install_hero(player,hero,xp) : {Payout.XPReceipt{P.Players.hero(Payout.install(player,hero,xp)),Payout.xp(Payout.install(player,hero,xp)),levels} == Payout.XPReceipt{_,xp,levels} : Payout.XPReceipt}
      %Payout.install_xp(player,hero,xp) : {Payout.XPReceipt{P.Players.hero(Payout.install(player,hero,xp)),Payout.xp(Payout.install(player,hero,xp)),levels} == Payout.XPReceipt{P.Players.hero(Payout.install(player,hero,xp)),_,levels} : Payout.XPReceipt}
      {==}

law Payout.experience_exact:
  for +player: P.Players.State
  for +gained: U32
  {Payout.xp_receipt(Payout.experience(player,gained)) == Payout.reward_receipt(R.Rewards.gain(P.Players.hero(player),Payout.xp(player),gained)) : Payout.XPReceipt}

def Payout.experience_exact(player,gained):
  Payout.finish_xp_exact(player,R.Rewards.gain(P.Players.hero(player),Payout.xp(player),gained))

law Payout.kill_finish_exact:
  for +side: Maybe<&2,U32>
  for +drop: Payout.Drop
  for +levels: U32
  for +bonus: U32
  {Payout.kill_finish(side,drop,levels,bonus) == Payout.Kill{Payout.score(Payout.drop_player(drop),bonus,0),side,Payout.dropped(drop),levels} : Payout.Kill}

def Payout.kill_finish_exact(side,drop,levels,bonus):
  match drop:
    case Payout.Drop{player,item}: {==}

law Payout.kill_drop_exact:
  for +side: Payout.Side
  for +drop: U32
  for +find_score: U32
  for +levels: U32
  for +bonus: U32
  {Payout.kill_drop(side,drop,find_score,levels,bonus) == Payout.Kill{Payout.score(Payout.drop_player(Payout.drop(Payout.side_player(side),drop,find_score)),bonus,0),Payout.completed(side),Payout.dropped(Payout.drop(Payout.side_player(side),drop,find_score)),levels} : Payout.Kill}

def Payout.kill_drop_exact(side,drop,find_score,levels,bonus):
  Payout.kill_finish_exact(Payout.completed(side),Payout.drop(Payout.side_player(side),drop,find_score),levels,bonus)

law Payout.drop_missing:
  for +player: P.Players.State
  for +score: U32
  {Payout.drop(player,4294967295,score) == Payout.Drop{player,None{}} : Payout.Drop}

def Payout.drop_missing(player,score): {==}

law Payout.side_blocked:
  for +player: P.Players.State
  for +q: U32
  for +need: U32
  for +score: U32
  for +blocked: {Bool.or(U32.is_gt(q,2),Payout.has_bit(Payout.claimed(Payout.quest(player)),q)) == True{} : Bool}
  {Payout.side(player,q,need,score) == Payout.Side{player,None{}} : Payout.Side}

def Payout.side_blocked(player,q,need,score,blocked):
  %Equal.sym(Bool,Bool.or(U32.is_gt(q,2),Payout.has_bit(Payout.claimed(Payout.quest(player)),q)),True{},blocked) : {Payout.side_gate(_,player,q,need,score) == Payout.Side{player,None{}} : Payout.Side}
  {==}

law Payout.side_completed_exact:
  for +player: P.Players.State
  for +q: U32
  for +count: U32
  for +claimed: U32
  for +score: U32
  {Payout.side_finish(True{},player,q,count,claimed,score) == Payout.Side{Payout.profile(Payout.side_reward(player,q),Payout.side_quest(Payout.quest(player),q,count,U32.or(claimed,Payout.mask(q))),Payout.score_meta(Payout.meta(player),score,0)),Some{q}} : Payout.Side}

def Payout.side_completed_exact(player,q,count,claimed,score): {==}

law Payout.drop_present_exact:
  for +player: P.Players.State
  for +kind: U32
  for +score: U32
  {Payout.drop_gate(False{},player,kind,score) == Payout.Drop{Payout.profile(Payout.item(player,kind),Payout.quest(player),Payout.loot_meta(Payout.meta(player),kind,Payout.choose(Payout.has_bit(Payout.found(player),kind),0,score))),Some{kind}} : Payout.Drop}

def Payout.drop_present_exact(player,kind,score): {==}

law Payout.sigil_gate_frame:
  for +advance: Bool
  for +player: P.Players.State
  for +score: U32
  {Payout.frame(Payout.sigil_gate(advance,player,score)) == Payout.frame(player) : Payout.Frame}

def Payout.sigil_gate_frame(advance,player,score):
  match advance:
    case False{}: {==}
    case True{}: Payout.profile_frame(player,Payout.next_main(Payout.quest(player)),Payout.score_meta(Payout.meta(player),score,0))

law Payout.sigil_frame:
  for +player: P.Players.State
  for +stage: U32
  for +score: U32
  {Payout.frame(Payout.sigil(player,stage,score)) == Payout.frame(player) : Payout.Frame}

def Payout.sigil_frame(player,stage,score):
  Payout.sigil_gate_frame(U32.is_eq(Payout.main(Payout.quest(player)),stage),player,score)

def Payout.frames(players: List<&2,P.Players.State>) -> List<&2,Payout.Frame>:
  match players:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{Payout.frame(head),Payout.frames(rest)}

law Payout.sigil_all_frames:
  for +players: List<&2,P.Players.State>
  for +stage: U32
  for +score: U32
  {Payout.frames(Payout.sigil_all(players,stage,score)) == Payout.frames(players) : List<&2,Payout.Frame>}

def Payout.sigil_all_frames(players,stage,score):
  match players:
    case Nil{}: {==}
    case Con{head,rest}:
      %Payout.sigil_frame(head,stage,score) : {Con{Payout.frame(Payout.sigil(head,stage,score)),Payout.frames(Payout.sigil_all(rest,stage,score))} == Con{_,Payout.frames(rest)} : List<&2,Payout.Frame>}
      %Payout.sigil_all_frames(rest,stage,score) : {Con{Payout.frame(Payout.sigil(head,stage,score)),Payout.frames(Payout.sigil_all(rest,stage,score))} == Con{Payout.frame(Payout.sigil(head,stage,score)),_} : List<&2,Payout.Frame>}
      {==}

law Payout.advance_gate_frames:
  for +skip: Bool
  for +players: List<&2,P.Players.State>
  for +stage: U32
  for +score: U32
  {Payout.frames(Payout.advance_gate(skip,players,stage,score)) == Payout.frames(players) : List<&2,Payout.Frame>}

def Payout.advance_gate_frames(skip,players,stage,score):
  match skip:
    case True{}: {==}
    case False{}: Payout.sigil_all_frames(players,stage,score)

law Payout.advance_frames:
  for +players: List<&2,P.Players.State>
  for +kind: U32
  for +score: U32
  {Payout.frames(Payout.advance(players,kind,score)) == Payout.frames(players) : List<&2,Payout.Frame>}

def Payout.advance_frames(players,kind,score):
  Payout.advance_gate_frames(U32.is_eq(Payout.boss_stage(kind),9),players,Payout.boss_stage(kind),score)

law Payout.apply_taken_frames:
  for +taken: P.Players.Take
  for +plan: Payout.Plan
  for +score: U32
  {Payout.frames(Payout.roster(Payout.apply_taken(taken,plan,score))) == Payout.frames(P.Players.restore(taken)) : List<&2,Payout.Frame>}

def Payout.apply_taken_frames(taken,plan,score):
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}: {==}
        case Some{player}:
          %Equal.sym(List<&2,Payout.Frame>,Payout.frames(Payout.advance(Con{Payout.killer(Payout.kill(player,plan)),others},Payout.kind(plan),score)),Payout.frames(Con{Payout.killer(Payout.kill(player,plan)),others}),Payout.advance_frames(Con{Payout.killer(Payout.kill(player,plan)),others},Payout.kind(plan),score)) : {_ == Payout.frames(Con{player,others}) : List<&2,Payout.Frame>}
          %Payout.kill_frame(player,plan) : {Con{Payout.frame(Payout.killer(Payout.kill(player,plan))),Payout.frames(others)} == Con{_,Payout.frames(others)} : List<&2,Payout.Frame>}
          {==}

type Payout.Conserved<-before: List<&2,P.Players.State>,-after: List<&2,P.Players.State>> is Data:
  Payout.Conserved{ordered: List<&2,P.Players.State>,permutation: P.Players.Perm<ordered,before>,frames: {Payout.frames(after) == Payout.frames(ordered) : List<&2,Payout.Frame>}}

law Payout.run_conserves:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +plan: Payout.Plan
  for +score: U32
  Payout.Conserved<players,Payout.roster(Payout.run(players,target,plan,score))>

def Payout.run_conserves(players,target,plan,score):
  Payout.Conserved{P.Players.restore(P.Players.take(players,target)),P.Players.take_restores(players,target),Payout.apply_taken_frames(P.Players.take(players,target),plan,score)}

type Payout.Award is Data:
  Payout.Award{target: U32,plan: Payout.Plan}

def Payout.trace(awards: List<&2,Payout.Award>, players: List<&2,P.Players.State>, +sigil_score: U32) -> List<&2,P.Players.State>:
  match awards:
    case Nil{}: players
    case Con{head,rest}:
      match head:
        case Payout.Award{target,plan}: Payout.trace(rest,Payout.roster(Payout.run(players,target,plan,sigil_score)),sigil_score)

law Payout.trace_ok:
  for +awards: List<&2,Payout.Award>
  for +players: List<&2,P.Players.State>
  for +sigil_score: U32
  for +valid: P.Players.All(players)
  P.Players.All(Payout.trace(awards,players,sigil_score))

def Payout.trace_ok(awards,players,sigil_score,valid):
  match awards:
    case Nil{}: valid
    case Con{head,rest}:
      match head:
        case Payout.Award{target,plan}: Payout.trace_ok(rest,Payout.roster(Payout.run(players,target,plan,sigil_score)),sigil_score,Payout.run_ok(players,target,plan,sigil_score,valid))
