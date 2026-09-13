# Nonzero player IDs and player-to-connection IDs across world transitions.
# This says nothing about authentication or the separate active-connection roster.
import Base
import ./references.bend as Ref
import ./allocation.bend as A
import ./admission.bend as J
import ./identity.bend as I
import ./players.bend as P
import ./terrain.bend as T
import ./simulation.bend as S
import ./locomotion.bend as Walk
import ./inventory.bend as Inv
import ./interactions.bend as Inter
import ./combat.bend as C
import ./game.bend as G
import ./payouts.bend as Pay
import ./battle.bend as B
import ./monsters.bend as M
import ./roster.bend as R
import ./ai.bend as AI
import ./planning.bend as Plan
import ./population.bend as Pop
import ./landscape.bend as Land

import ./playerids.bend as Id
import ./ai_refs.bend as AR
import ./targeting.bend as Sel

type Nonzero.All<-players: List<&2,P.Players.State>> is Data:
  Nonzero.All{pids: A.Allocation.Absent(0,Id.PlayerIds.project(Id.PlayerIds.Player{},players)),cids: A.Allocation.Absent(0,Id.PlayerIds.project(Id.PlayerIds.Connection{},players))}

law Nonzero.get:
  for +kind: Id.PlayerIds.Kind
  for +players: List<&2,P.Players.State>
  for +valid: Nonzero.All<players>
  A.Allocation.Absent(0,Id.PlayerIds.project(kind,players))

def Nonzero.get(kind,players,valid):
  match kind:
    case Id.PlayerIds.Player{}:
      match valid:
        case Nonzero.All{pids,cids}: pids
    case Id.PlayerIds.Connection{}:
      match valid:
        case Nonzero.All{pids,cids}: cids

law Nonzero.pack:
  for +players: List<&2,P.Players.State>
  for +pids: A.Allocation.Absent(0,Id.PlayerIds.project(Id.PlayerIds.Player{},players))
  for +cids: A.Allocation.Absent(0,Id.PlayerIds.project(Id.PlayerIds.Connection{},players))
  Nonzero.All<players>

def Nonzero.pack(players,pids,cids): Nonzero.All{pids,cids}

law Nonzero.permutation:
  for +kind: Id.PlayerIds.Kind
  for -left: List<&2,P.Players.State>
  for -right: List<&2,P.Players.State>
  for +permutation: P.Players.Perm<left,right>
  for +valid: A.Allocation.Absent(0,Id.PlayerIds.project(kind,right))
  A.Allocation.Absent(0,Id.PlayerIds.project(kind,left))

def Nonzero.permutation(kind,left,right,permutation,valid): Id.PlayerIds.perm_absent(kind,left,right,permutation,0,valid)

def Nonzero.tail(head: U32,rest: A.Allocation.Ids,valid: A.Allocation.Absent(0,Con{head,rest})) -> A.Allocation.Absent(0,rest): Id.PlayerIds.absent_tail(0,head,rest,valid)

law Nonzero.take_positive:
  for +kind: Id.PlayerIds.Kind
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +valid: A.Allocation.Absent(0,Id.PlayerIds.project(kind,players))
  A.Allocation.Absent(0,Id.PlayerIds.project(kind,P.Players.restore(P.Players.take(players,target))))

def Nonzero.take_positive(kind,players,target,valid):
  Nonzero.permutation(kind,P.Players.restore(P.Players.take(players,target)),players,P.Players.take_restores(players,target),valid)

law Nonzero.others_positive:
  for +kind: Id.PlayerIds.Kind
  for +taken: P.Players.Take
  for +valid: A.Allocation.Absent(0,Id.PlayerIds.project(kind,P.Players.restore(taken)))
  A.Allocation.Absent(0,Id.PlayerIds.project(kind,P.Players.others(taken)))

def Nonzero.others_positive(kind,taken,valid):
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}: valid
        case Some{player}: Nonzero.tail(Id.PlayerIds.key(kind,player),Id.PlayerIds.project(kind,others),valid)

law Nonzero.remove_positive:
  for +kind: Id.PlayerIds.Kind
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +valid: A.Allocation.Absent(0,Id.PlayerIds.project(kind,players))
  A.Allocation.Absent(0,Id.PlayerIds.project(kind,P.Players.others(P.Players.take(players,target))))

def Nonzero.remove_positive(kind,players,target,valid):
  Nonzero.others_positive(kind,P.Players.take(players,target),Nonzero.take_positive(kind,players,target,valid))

law Nonzero.remove_both:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +valid: Nonzero.All<players>
  Nonzero.All<P.Players.others(P.Players.take(players,target))>

def Nonzero.remove_both(players,target,valid):
  Nonzero.pack(P.Players.others(P.Players.take(players,target)),Nonzero.remove_positive(Id.PlayerIds.Player{},players,target,Nonzero.get(Id.PlayerIds.Player{},players,valid)),Nonzero.remove_positive(Id.PlayerIds.Connection{},players,target,Nonzero.get(Id.PlayerIds.Connection{},players,valid)))

law Nonzero.inventory_positive:
  for +kind: Id.PlayerIds.Kind
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: Inv.Inventory.Conserved<before,after>
  for +valid: A.Allocation.Absent(0,Id.PlayerIds.project(kind,before))
  A.Allocation.Absent(0,Id.PlayerIds.project(kind,after))

def Nonzero.inventory_positive(kind,before,after,conserved,valid):
  match conserved:
    case Inv.Inventory.Conserved{ordered,permutation,frames}:
      %Id.PlayerIds.inventory_projection(kind,after) : A.Allocation.Absent(0,_)
      %Equal.sym(List<&2,Inv.Inventory.Frame>,Inv.Inventory.frames(after),Inv.Inventory.frames(ordered),frames) : A.Allocation.Absent(0,Id.PlayerIds.inventory_keys(kind,_))
      %Equal.sym(A.Allocation.Ids,Id.PlayerIds.inventory_keys(kind,Inv.Inventory.frames(ordered)),Id.PlayerIds.project(kind,ordered),Id.PlayerIds.inventory_projection(kind,ordered)) : A.Allocation.Absent(0,_)
      Nonzero.permutation(kind,ordered,before,permutation,valid)

law Nonzero.inventory_both:
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: Inv.Inventory.Conserved<before,after>
  for +valid: Nonzero.All<before>
  Nonzero.All<after>

def Nonzero.inventory_both(before,after,conserved,valid):
  Nonzero.pack(after,Nonzero.inventory_positive(Id.PlayerIds.Player{},before,after,conserved,Nonzero.get(Id.PlayerIds.Player{},before,valid)),Nonzero.inventory_positive(Id.PlayerIds.Connection{},before,after,conserved,Nonzero.get(Id.PlayerIds.Connection{},before,valid)))

law Nonzero.inventory_run:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +op: G.Bq.HOp
  for +near_shop: Bool
  for +amount: U32
  for +valid: Nonzero.All<players>
  Nonzero.All<Inv.Inventory.roster(Inv.Inventory.run(players,target,op,near_shop,amount))>

def Nonzero.inventory_run(players,target,op,near_shop,amount,valid):
  Nonzero.inventory_both(players,Inv.Inventory.roster(Inv.Inventory.run(players,target,op,near_shop,amount)),Inv.Inventory.run_conserves(players,target,op,near_shop,amount),valid)

law Nonzero.interaction_positive:
  for +kind: Id.PlayerIds.Kind
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: Inter.Interaction.Conserved<before,after>
  for +valid: A.Allocation.Absent(0,Id.PlayerIds.project(kind,before))
  A.Allocation.Absent(0,Id.PlayerIds.project(kind,after))

def Nonzero.interaction_positive(kind,before,after,conserved,valid):
  match conserved:
    case Inter.Interaction.Conserved{ordered,permutation,frames}:
      %Id.PlayerIds.interaction_projection(kind,after) : A.Allocation.Absent(0,_)
      %Equal.sym(List<&2,Inter.Interaction.Frame>,Inter.Interaction.frames(after),Inter.Interaction.frames(ordered),frames) : A.Allocation.Absent(0,Id.PlayerIds.interaction_keys(kind,_))
      %Equal.sym(A.Allocation.Ids,Id.PlayerIds.interaction_keys(kind,Inter.Interaction.frames(ordered)),Id.PlayerIds.project(kind,ordered),Id.PlayerIds.interaction_projection(kind,ordered)) : A.Allocation.Absent(0,_)
      Nonzero.permutation(kind,ordered,before,permutation,valid)

law Nonzero.interaction_both:
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: Inter.Interaction.Conserved<before,after>
  for +valid: Nonzero.All<before>
  Nonzero.All<after>

def Nonzero.interaction_both(before,after,conserved,valid):
  Nonzero.pack(after,Nonzero.interaction_positive(Id.PlayerIds.Player{},before,after,conserved,Nonzero.get(Id.PlayerIds.Player{},before,valid)),Nonzero.interaction_positive(Id.PlayerIds.Connection{},before,after,conserved,Nonzero.get(Id.PlayerIds.Connection{},before,valid)))

law Nonzero.interaction_run:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +command: Inter.Interaction.Command
  for +valid: Nonzero.All<players>
  Nonzero.All<Inter.Interaction.roster(Inter.Interaction.run(players,target,command))>

def Nonzero.interaction_run(players,target,command,valid):
  Nonzero.interaction_both(players,Inter.Interaction.roster(Inter.Interaction.run(players,target,command)),Inter.Interaction.run_conserves(players,target,command),valid)

law Nonzero.combat_positive:
  for +kind: Id.PlayerIds.Kind
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: C.Combat.Conserved<before,after>
  for +valid: A.Allocation.Absent(0,Id.PlayerIds.project(kind,before))
  A.Allocation.Absent(0,Id.PlayerIds.project(kind,after))

def Nonzero.combat_positive(kind,before,after,conserved,valid):
  match conserved:
    case C.Combat.Conserved{ordered,permutation,frames}:
      %Id.PlayerIds.combat_projection(kind,after) : A.Allocation.Absent(0,_)
      %Equal.sym(List<&2,C.Combat.Frame>,C.Combat.frames(after),C.Combat.frames(ordered),frames) : A.Allocation.Absent(0,Id.PlayerIds.combat_keys(kind,_))
      %Equal.sym(A.Allocation.Ids,Id.PlayerIds.combat_keys(kind,C.Combat.frames(ordered)),Id.PlayerIds.project(kind,ordered),Id.PlayerIds.combat_projection(kind,ordered)) : A.Allocation.Absent(0,_)
      Nonzero.permutation(kind,ordered,before,permutation,valid)

law Nonzero.combat_both:
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: C.Combat.Conserved<before,after>
  for +valid: Nonzero.All<before>
  Nonzero.All<after>

def Nonzero.combat_both(before,after,conserved,valid):
  Nonzero.pack(after,Nonzero.combat_positive(Id.PlayerIds.Player{},before,after,conserved,Nonzero.get(Id.PlayerIds.Player{},before,valid)),Nonzero.combat_positive(Id.PlayerIds.Connection{},before,after,conserved,Nonzero.get(Id.PlayerIds.Connection{},before,valid)))

law Nonzero.combat_run:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +kind: C.Combat.Kind
  for +phase: U32
  for +valid: Nonzero.All<players>
  Nonzero.All<C.Combat.roster(C.Combat.run(players,target,kind,phase))>

def Nonzero.combat_run(players,target,kind,phase,valid):
  Nonzero.combat_both(players,C.Combat.roster(C.Combat.run(players,target,kind,phase)),C.Combat.run_conserves(players,target,kind,phase),valid)

law Nonzero.payout_positive:
  for +kind: Id.PlayerIds.Kind
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: Pay.Payout.Conserved<before,after>
  for +valid: A.Allocation.Absent(0,Id.PlayerIds.project(kind,before))
  A.Allocation.Absent(0,Id.PlayerIds.project(kind,after))

def Nonzero.payout_positive(kind,before,after,conserved,valid):
  match conserved:
    case Pay.Payout.Conserved{ordered,permutation,frames}:
      %Id.PlayerIds.payout_projection(kind,after) : A.Allocation.Absent(0,_)
      %Equal.sym(List<&2,Pay.Payout.Frame>,Pay.Payout.frames(after),Pay.Payout.frames(ordered),frames) : A.Allocation.Absent(0,Id.PlayerIds.payout_keys(kind,_))
      %Equal.sym(A.Allocation.Ids,Id.PlayerIds.payout_keys(kind,Pay.Payout.frames(ordered)),Id.PlayerIds.project(kind,ordered),Id.PlayerIds.payout_projection(kind,ordered)) : A.Allocation.Absent(0,_)
      Nonzero.permutation(kind,ordered,before,permutation,valid)

law Nonzero.payout_both:
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: Pay.Payout.Conserved<before,after>
  for +valid: Nonzero.All<before>
  Nonzero.All<after>

def Nonzero.payout_both(before,after,conserved,valid):
  Nonzero.pack(after,Nonzero.payout_positive(Id.PlayerIds.Player{},before,after,conserved,Nonzero.get(Id.PlayerIds.Player{},before,valid)),Nonzero.payout_positive(Id.PlayerIds.Connection{},before,after,conserved,Nonzero.get(Id.PlayerIds.Connection{},before,valid)))

law Nonzero.payout_run:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +valid: Nonzero.All<players>
  Nonzero.All<Pay.Payout.roster(Pay.Payout.run(players,target,plan,score))>

def Nonzero.payout_run(players,target,plan,score,valid):
  Nonzero.payout_both(players,Pay.Payout.roster(Pay.Payout.run(players,target,plan,score)),Pay.Payout.run_conserves(players,target,plan,score),valid)

law Nonzero.strike_positive:
  for +kind: Id.PlayerIds.Kind
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +attack: U32
  for +timer: U32
  for +valid: A.Allocation.Absent(0,Id.PlayerIds.project(kind,players))
  A.Allocation.Absent(0,Id.PlayerIds.project(kind,P.Players.roster(P.Players.strike(players,target,attack,timer))))

def Nonzero.strike_positive(kind,players,target,attack,timer,valid):
  %Equal.sym(A.Allocation.Ids,Id.PlayerIds.project(kind,P.Players.roster(P.Players.strike(players,target,attack,timer))),Id.PlayerIds.project(kind,P.Players.restore(P.Players.take(players,target))),Id.PlayerIds.hit_taken_projection(kind,P.Players.take(players,target),attack,timer)) : A.Allocation.Absent(0,_)
  Nonzero.take_positive(kind,players,target,valid)

law Nonzero.apply_hits_positive:
  for +hits: List<&2,P.Players.Attack>
  for +kind: Id.PlayerIds.Kind
  for +players: List<&2,P.Players.State>
  for +timer: U32
  for +valid: A.Allocation.Absent(0,Id.PlayerIds.project(kind,players))
  A.Allocation.Absent(0,Id.PlayerIds.project(kind,P.Players.roster(P.Players.apply_hits(hits,players,timer))))

def Nonzero.apply_hits_positive(hits,kind,players,timer,valid):
  match hits:
    case Nil{}: valid
    case Con{head,rest}:
      match head:
        case P.Players.Attack{target,attack}:
          +first = P.Players.strike(players,target,attack,timer)
          +later = P.Players.apply_hits(rest,P.Players.roster(first),timer)
          %Equal.sym(List<&2,P.Players.State>,P.Players.roster(P.Players.before(first,later)),P.Players.roster(later),P.Players.before_roster(first,later)) : A.Allocation.Absent(0,Id.PlayerIds.project(kind,_))
          Nonzero.apply_hits_positive(rest,kind,P.Players.roster(first),timer,Nonzero.strike_positive(kind,players,target,attack,timer,valid))

law Nonzero.finish_positive:
  for +kind: Id.PlayerIds.Kind
  for +prepared: S.Simulation.Prepared
  for +p0: List<&2,AI.AI.Plan>
  for +p1: List<&2,AI.AI.Plan>
  for +p2: List<&2,AI.AI.Plan>
  for +p3: List<&2,AI.AI.Plan>
  for +rules: S.Simulation.Rules
  for +valid: A.Allocation.Absent(0,Id.PlayerIds.project(kind,P.Players.roster(S.Simulation.prepared_upkeep(prepared))))
  A.Allocation.Absent(0,Id.PlayerIds.project(kind,S.Simulation.players(S.Simulation.state(S.Simulation.finish(prepared,p0,p1,p2,p3,rules)))))

def Nonzero.finish_positive(kind,prepared,p0,p1,p2,p3,rules,valid):
  match prepared:
    case S.Simulation.Prepared{meta,monsters,upkeep,running}:
      match running:
        case False{}: valid
        case True{}:
          match rules:
            case S.Simulation.Rules{spawn_x,spawn_y,timer}: Nonzero.apply_hits_positive(S.Simulation.attacks(S.Simulation.ai_hits(AI.AI.run_zones(monsters,p0,p1,p2,p3))),kind,P.Players.roster(upkeep),timer,valid)

law Nonzero.actions_positive:
  for +kind: Id.PlayerIds.Kind
  for +prepared: S.Simulation.Prepared
  for +actions: Walk.Locomotion.Actions
  for +rules: S.Simulation.Rules
  for +valid: A.Allocation.Absent(0,Id.PlayerIds.project(kind,P.Players.roster(S.Simulation.prepared_upkeep(prepared))))
  A.Allocation.Absent(0,Id.PlayerIds.project(kind,S.Simulation.players(S.Simulation.state(Walk.Locomotion.finish(prepared,actions,rules)))))

def Nonzero.actions_positive(kind,prepared,actions,rules,valid):
  match actions:
    case Walk.Locomotion.Actions{p0,p1,p2,p3}: Nonzero.finish_positive(kind,prepared,p0,p1,p2,p3,rules,valid)

law Nonzero.planning_finish_positive:
  for +kind: Id.PlayerIds.Kind
  for +prepared: S.Simulation.Prepared
  for +maps: T.Terrain.Maps
  for +c0: List<&2,Plan.Planning.Context>
  for +c1: List<&2,Plan.Planning.Context>
  for +c2: List<&2,Plan.Planning.Context>
  for +c3: List<&2,Plan.Planning.Context>
  for +rules: S.Simulation.Rules
  for +valid: A.Allocation.Absent(0,Id.PlayerIds.project(kind,P.Players.roster(S.Simulation.prepared_upkeep(prepared))))
  A.Allocation.Absent(0,Id.PlayerIds.project(kind,S.Simulation.players(S.Simulation.state(Plan.Planning.finish(prepared,maps,c0,c1,c2,c3,rules)))))

def Nonzero.planning_finish_positive(kind,prepared,maps,c0,c1,c2,c3,rules,valid):
  +actions = Plan.Planning.actions(S.Simulation.prepared_monsters(prepared),c0,c1,c2,c3,maps,S.Simulation.clock(S.Simulation.prepared_meta(prepared)))
  %Equal.sym(S.Simulation.Result,Plan.Planning.finish(prepared,maps,c0,c1,c2,c3,rules),Walk.Locomotion.finish(prepared,actions,rules),Plan.Planning.finish_refines(prepared,maps,c0,c1,c2,c3,rules)) : A.Allocation.Absent(0,Id.PlayerIds.project(kind,S.Simulation.players(S.Simulation.state(_))))
  Nonzero.actions_positive(kind,prepared,actions,rules,valid)

law Nonzero.planning_tick_positive:
  for +kind: Id.PlayerIds.Kind
  for +state: S.Simulation.State
  for +input: Plan.Planning.Input
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  for +valid: A.Allocation.Absent(0,Id.PlayerIds.project(kind,S.Simulation.players(state)))
  A.Allocation.Absent(0,Id.PlayerIds.project(kind,S.Simulation.players(S.Simulation.state(Plan.Planning.tick(state,input,maps,rules)))))

def Nonzero.planning_tick_positive(kind,state,input,maps,rules,valid):
  match input:
    case Plan.Planning.Input{c0,c1,c2,c3}:
      +running = U32.is_eq(S.Simulation.phase(S.Simulation.meta(state)),1)
      +plans = Walk.Locomotion.tick_plans(running,S.Simulation.players(state),maps)
      +prepared = Walk.Locomotion.begin(state,maps,rules)
      Nonzero.planning_finish_positive(kind,prepared,maps,c0,c1,c2,c3,rules,(%Equal.sym(A.Allocation.Ids,Id.PlayerIds.project(kind,P.Players.roster(S.Simulation.prepared_upkeep(prepared))),Id.PlayerIds.project(kind,S.Simulation.players(state)),Id.PlayerIds.begin_gate_projection(kind,running,state,plans,rules)) : A.Allocation.Absent(0,_); valid))

law Nonzero.planning_tick_both:
  for +state: S.Simulation.State
  for +input: Plan.Planning.Input
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  for +valid: Nonzero.All<S.Simulation.players(state)>
  Nonzero.All<S.Simulation.players(S.Simulation.state(Plan.Planning.tick(state,input,maps,rules)))>

def Nonzero.planning_tick_both(state,input,maps,rules,valid):
  Nonzero.pack(S.Simulation.players(S.Simulation.state(Plan.Planning.tick(state,input,maps,rules))),Nonzero.planning_tick_positive(Id.PlayerIds.Player{},state,input,maps,rules,Nonzero.get(Id.PlayerIds.Player{},S.Simulation.players(state),valid)),Nonzero.planning_tick_positive(Id.PlayerIds.Connection{},state,input,maps,rules,Nonzero.get(Id.PlayerIds.Connection{},S.Simulation.players(state),valid)))

law Nonzero.reward_positive:
  for +state: S.Simulation.State
  for +pid: U32
  for +kill: R.Roster.Kill
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +valid: Nonzero.All<S.Simulation.players(state)>
  Nonzero.All<S.Simulation.players(B.Battle.state(B.Battle.reward(state,pid,kill,plan,score)))>

def Nonzero.reward_positive(state,pid,kill,plan,score,valid):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      +bound = B.Battle.bind_kind(plan,B.Battle.kind(kill))
      +paid = Pay.Payout.run(players,pid,bound,score)
      %Equal.sym(List<&2,P.Players.State>,S.Simulation.players(B.Battle.state(B.Battle.finish_reward(meta,monsters,kill,paid))),Pay.Payout.roster(paid),B.Battle.finish_reward_players(meta,monsters,kill,paid)) : Nonzero.All<_>
      Nonzero.payout_run(players,pid,bound,score,valid)

law Nonzero.after_positive:
  for +kill: Maybe<&2,R.Roster.Kill>
  for +state: S.Simulation.State
  for +pid: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +valid: Nonzero.All<S.Simulation.players(state)>
  Nonzero.All<S.Simulation.players(B.Battle.state(B.Battle.after(kill,state,pid,plan,score)))>

def Nonzero.after_positive(kill,state,pid,plan,score,valid):
  match kill:
    case None{}: valid
    case Some{info}: Nonzero.reward_positive(state,pid,info,plan,score,valid)

law Nonzero.finish_hit_positive:
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +hit: R.Roster.Strike
  for +pid: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +valid: Nonzero.All<players>
  Nonzero.All<S.Simulation.players(B.Battle.state(B.Battle.finish_hit(meta,players,hit,pid,plan,score)))>

def Nonzero.finish_hit_positive(meta,players,hit,pid,plan,score,valid):
  match hit:
    case R.Roster.Strike{monsters,kill,dealt}: Nonzero.after_positive(kill,S.Simulation.State{meta,players,monsters},pid,plan,score,valid)

law Nonzero.battle_strike_positive:
  for +input: B.Battle.Input
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +valid: Nonzero.All<S.Simulation.players(state)>
  Nonzero.All<S.Simulation.players(B.Battle.state(B.Battle.strike(input,state,pid,score)))>

def Nonzero.battle_strike_positive(input,state,pid,score,valid):
  match input:
    case B.Battle.Input{mid,damage,plan}:
      match state:
        case S.Simulation.State{meta,players,monsters}: Nonzero.finish_hit_positive(meta,players,R.Roster.strike(monsters,mid,damage),pid,plan,score,valid)

law Nonzero.battle_run_positive:
  for +inputs: List<&2,B.Battle.Input>
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +valid: Nonzero.All<S.Simulation.players(state)>
  Nonzero.All<S.Simulation.players(B.Battle.state(B.Battle.run(inputs,state,pid,score)))>

def Nonzero.battle_run_positive(inputs,state,pid,score,valid):
  match inputs:
    case Nil{}: valid
    case Con{head,rest}: Nonzero.battle_run_positive(rest,B.Battle.state(B.Battle.strike(head,state,pid,score)),pid,score,Nonzero.battle_strike_positive(head,state,pid,score,valid))

law Nonzero.execute_positive:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +admitted: C.Combat.Result
  for +inputs: List<&2,B.Battle.Input>
  for +pid: U32
  for +score: U32
  for +valid: Nonzero.All<C.Combat.roster(admitted)>
  Nonzero.All<S.Simulation.players(B.Battle.state(B.Battle.execute(meta,monsters,admitted,inputs,pid,score)))>

def Nonzero.execute_positive(meta,monsters,admitted,inputs,pid,score,valid):
  match admitted:
    case C.Combat.Result{players,attacker}:
      match attacker:
        case None{}: valid
        case Some{actor}: Nonzero.battle_run_positive(inputs,S.Simulation.State{meta,players,monsters},pid,score,valid)

law Nonzero.command_positive:
  for +kind: C.Combat.Kind
  for +state: S.Simulation.State
  for +inputs: List<&2,B.Battle.Input>
  for +pid: U32
  for +score: U32
  for +valid: Nonzero.All<S.Simulation.players(state)>
  Nonzero.All<S.Simulation.players(B.Battle.state(B.Battle.command(kind,state,inputs,pid,score)))>

def Nonzero.command_positive(kind,state,inputs,pid,score,valid):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      Nonzero.execute_positive(meta,monsters,C.Combat.run(players,pid,kind,S.Simulation.phase(meta)),inputs,pid,score,Nonzero.combat_run(players,pid,kind,S.Simulation.phase(meta),valid))

law Nonzero.remove_state_positive:
  for +state: S.Simulation.State
  for +pid: U32
  for +valid: Nonzero.All<S.Simulation.players(state)>
  Nonzero.All<S.Simulation.players(Ref.References.remove_state(state,pid))>

def Nonzero.remove_state_positive(state,pid,valid):
  match state:
    case S.Simulation.State{meta,players,monsters}: Nonzero.remove_both(players,pid,valid)

law Nonzero.commit:
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +choice: A.Allocation.Choice
  for +fresh: A.Allocation.Fresh<J.Admission.pids(S.Simulation.players(state)),choice>
  for +positive: {U32.is_eq(cid,0) == False{} : Bool}
  for +valid: Nonzero.All<S.Simulation.players(state)>
  Nonzero.All<S.Simulation.players(J.Admission.state(J.Admission.commit(state,cid,style,name,choice)))>

def Nonzero.commit(state,cid,style,name,choice,fresh,positive,valid):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      match fresh:
        case A.Allocation.Fresh{pid_positive,absent,next_positive}:
          match valid:
            case Nonzero.All{pids,cids}: Nonzero.All{Tuple{I.Identity.neq_sym(A.Allocation.id(choice),0,pid_positive),pids},Tuple{I.Identity.neq_sym(cid,0,positive),cids}}

law Nonzero.admitted:
  for +before: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +result: J.Admission.Result
  for +outcome: J.Admission.Outcome<before,cid,style,name,result>
  for +valid: Nonzero.All<S.Simulation.players(before)>
  Nonzero.All<S.Simulation.players(J.Admission.state(result))>

def Nonzero.admitted(before,cid,style,name,result,outcome,valid):
  match outcome:
    case J.Admission.Rejected{exact}:
      %Equal.sym(J.Admission.Result,result,J.Admission.Result{before,0},exact) : Nonzero.All<S.Simulation.players(J.Admission.state(_))>
      valid
    case J.Admission.Created{choice,exact,fresh,positive,available}:
      %Equal.sym(J.Admission.Result,result,J.Admission.commit(before,cid,style,name,choice),exact) : Nonzero.All<S.Simulation.players(J.Admission.state(_))>
      Nonzero.commit(before,cid,style,name,choice,fresh,positive,valid)

law Nonzero.add:
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +valid: Nonzero.All<S.Simulation.players(state)>
  Nonzero.All<S.Simulation.players(J.Admission.state(J.Admission.add(state,cid,style,name)))>

def Nonzero.add(state,cid,style,name,valid): Nonzero.admitted(state,cid,style,name,J.Admission.add(state,cid,style,name),J.Admission.add_outcome(state,cid,style,name),valid)

law Nonzero.change_positive:
  for +change: Id.PlayerIds.Change
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +valid: Nonzero.All<S.Simulation.players(state)>
  Nonzero.All<S.Simulation.players(Id.PlayerIds.run_change(change,state,maps))>

def Nonzero.change_positive(change,state,maps,valid):
  match change:
    case Id.PlayerIds.Create{cid,style,name}: Nonzero.add(state,cid,style,name,valid)
    case Id.PlayerIds.Remove{target}: Nonzero.remove_state_positive(state,target,valid)
    case Id.PlayerIds.Inventory{target,op,near_shop,amount}:
      match state:
        case S.Simulation.State{meta,players,monsters}: Nonzero.inventory_run(players,target,op,near_shop,amount,valid)
    case Id.PlayerIds.Interact{target,command}:
      match state:
        case S.Simulation.State{meta,players,monsters}: Nonzero.interaction_run(players,target,command,valid)
    case Id.PlayerIds.Fight{kind,inputs,pid,score}: Nonzero.command_positive(kind,state,inputs,pid,score,valid)
    case Id.PlayerIds.Tick{input,rules}: Nonzero.planning_tick_both(state,input,maps,rules,valid)

law Nonzero.selected_finish:
  for +kind: Id.PlayerIds.Kind
  for +prepared: S.Simulation.Prepared
  for +maps: T.Terrain.Maps
  for +d0: List<&2,U32>
  for +d1: List<&2,U32>
  for +d2: List<&2,U32>
  for +d3: List<&2,U32>
  for +rules: S.Simulation.Rules
  for +valid: A.Allocation.Absent(0,Id.PlayerIds.project(kind,P.Players.roster(S.Simulation.prepared_upkeep(prepared))))
  A.Allocation.Absent(0,Id.PlayerIds.project(kind,S.Simulation.players(S.Simulation.state(AR.AIRefs.finish(prepared,maps,d0,d1,d2,d3,rules)))))

def Nonzero.selected_finish(kind,prepared,maps,d0,d1,d2,d3,rules,valid):
  match prepared:
    case S.Simulation.Prepared{meta,monsters,upkeep,running}:
      match running:
        case False{}: valid
        case True{}:
          +players = P.Players.roster(upkeep)
          Nonzero.planning_finish_positive(kind,S.Simulation.Prepared{meta,monsters,upkeep,True{}},maps,AR.AIRefs.contexts(monsters,players,0,d0),AR.AIRefs.contexts(monsters,players,1,d1),AR.AIRefs.contexts(monsters,players,2,d2),AR.AIRefs.contexts(monsters,players,3,d3),rules,valid)

law Nonzero.selected_tick:
  for +kind: Id.PlayerIds.Kind
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +d0: List<&2,U32>
  for +d1: List<&2,U32>
  for +d2: List<&2,U32>
  for +d3: List<&2,U32>
  for +rules: S.Simulation.Rules
  for +valid: A.Allocation.Absent(0,Id.PlayerIds.project(kind,S.Simulation.players(state)))
  A.Allocation.Absent(0,Id.PlayerIds.project(kind,S.Simulation.players(S.Simulation.state(AR.AIRefs.tick(state,maps,d0,d1,d2,d3,rules)))))

def Nonzero.selected_tick(kind,state,maps,d0,d1,d2,d3,rules,valid):
  +running = U32.is_eq(S.Simulation.phase(S.Simulation.meta(state)),1)
  +plans = Walk.Locomotion.tick_plans(running,S.Simulation.players(state),maps)
  +prepared = Walk.Locomotion.begin(state,maps,rules)
  Nonzero.selected_finish(kind,prepared,maps,d0,d1,d2,d3,rules,(%Equal.sym(A.Allocation.Ids,Id.PlayerIds.project(kind,P.Players.roster(S.Simulation.prepared_upkeep(prepared))),Id.PlayerIds.project(kind,S.Simulation.players(state)),Id.PlayerIds.begin_gate_projection(kind,running,state,plans,rules)) : A.Allocation.Absent(0,_); valid))

law Nonzero.run_tick:
  for +damages: AR.AIRefs.Damages
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  for +valid: Nonzero.All<S.Simulation.players(state)>
  Nonzero.All<S.Simulation.players(AR.AIRefs.run_tick(damages,state,maps,rules))>

def Nonzero.run_tick(damages,state,maps,rules,valid):
  match damages:
    case AR.AIRefs.Damages{d0,d1,d2,d3}:
      Nonzero.pack(S.Simulation.players(S.Simulation.state(AR.AIRefs.tick(state,maps,d0,d1,d2,d3,rules))),Nonzero.selected_tick(Id.PlayerIds.Player{},state,maps,d0,d1,d2,d3,rules,Nonzero.get(Id.PlayerIds.Player{},S.Simulation.players(state),valid)),Nonzero.selected_tick(Id.PlayerIds.Connection{},state,maps,d0,d1,d2,d3,rules,Nonzero.get(Id.PlayerIds.Connection{},S.Simulation.players(state),valid)))

law Nonzero.transition:
  for +transition: AR.AIRefs.Transition
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +valid: Nonzero.All<S.Simulation.players(state)>
  Nonzero.All<S.Simulation.players(AR.AIRefs.transition(transition,state,maps))>

def Nonzero.transition(transition,state,maps,valid):
  match transition:
    case AR.AIRefs.Command{change,command_only}: Nonzero.change_positive(change,state,maps,valid)
    case AR.AIRefs.Ticking{damages,rules}: Nonzero.run_tick(damages,state,maps,rules,valid)

law Nonzero.trace:
  for +transitions: List<&2,AR.AIRefs.Transition>
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +valid: Nonzero.All<S.Simulation.players(state)>
  Nonzero.All<S.Simulation.players(AR.AIRefs.trace(transitions,state,maps))>

def Nonzero.trace(transitions,state,maps,valid):
  match transitions:
    case Nil{}: valid
    case Con{head,rest}: Nonzero.trace(rest,AR.AIRefs.transition(head,state,maps),maps,Nonzero.transition(head,state,maps,valid))

law Nonzero.fresh_trace:
  for +transitions: List<&2,AR.AIRefs.Transition>
  for +world: U32
  for +seed: U32
  for +now: U32
  Nonzero.All<S.Simulation.players(AR.AIRefs.trace(transitions,T.Terrain.simulation(Pop.Population.fresh(world,seed,now)),Land.Landscape.maps(seed)))>

def Nonzero.fresh_trace(transitions,world,seed,now): Nonzero.trace(transitions,T.Terrain.simulation(Pop.Population.fresh(world,seed,now)),Land.Landscape.maps(seed),Nonzero.All{Unit{},Unit{}})

# A member witness yields actual nonzero fields, including selector candidates.
law Nonzero.member:
  for +kind: Id.PlayerIds.Kind
  for +player: P.Players.State
  for -players: List<&2,P.Players.State>
  for +inside: Sel.Targeting.In<player,players>
  for +valid: A.Allocation.Absent(0,Id.PlayerIds.project(kind,players))
  {U32.is_eq(Id.PlayerIds.key(kind,player),0) == False{} : Bool}

def Nonzero.member(kind,player,players,inside,valid):
  match inside:
    case Sel.Targeting.Here{rest,shape}:
      I.Identity.neq_sym(0,Id.PlayerIds.key(kind,player),Id.PlayerIds.absent_head(0,Id.PlayerIds.key(kind,player),Id.PlayerIds.project(kind,rest),(%shape : A.Allocation.Absent(0,Id.PlayerIds.project(kind,_)); valid)))
    case Sel.Targeting.There{head,rest,shape,later}:
      Nonzero.member(kind,player,rest,later,Id.PlayerIds.absent_tail(0,Id.PlayerIds.key(kind,head),Id.PlayerIds.project(kind,rest),(%shape : A.Allocation.Absent(0,Id.PlayerIds.project(kind,_)); valid)))

law Nonzero.player_lookup:
  for +players: List<&2,P.Players.State>
  for +valid: A.Allocation.Absent(0,Id.PlayerIds.project(Id.PlayerIds.Player{},players))
  {P.Players.has_id(players,0) == False{} : Bool}

def Nonzero.player_lookup(players,valid):
  match players:
    case Nil{}: {==}
    case Con{head,rest}:
      match valid:
        case Tuple{positive,tail}:
          %Equal.sym(Bool,U32.is_eq(P.Players.id(head),0),False{},I.Identity.neq_sym(0,P.Players.id(head),positive)) : {Bool.or(_,P.Players.has_id(rest,0)) == False{} : Bool}
          Nonzero.player_lookup(rest,tail)

law Nonzero.zero_missing:
  for +players: List<&2,P.Players.State>
  for +valid: Nonzero.All<players>
  {P.Players.has_id(players,0) == False{} : Bool}

def Nonzero.zero_missing(players,valid): Nonzero.player_lookup(players,Nonzero.get(Id.PlayerIds.Player{},players,valid))

law Nonzero.fresh_trace_zero_missing:
  for +transitions: List<&2,AR.AIRefs.Transition>
  for +world: U32
  for +seed: U32
  for +now: U32
  {P.Players.has_id(S.Simulation.players(AR.AIRefs.trace(transitions,T.Terrain.simulation(Pop.Population.fresh(world,seed,now)),Land.Landscape.maps(seed))),0) == False{} : Bool}

def Nonzero.fresh_trace_zero_missing(transitions,world,seed,now): Nonzero.zero_missing(S.Simulation.players(AR.AIRefs.trace(transitions,T.Terrain.simulation(Pop.Population.fresh(world,seed,now)),Land.Landscape.maps(seed))),Nonzero.fresh_trace(transitions,world,seed,now))
