# Exact roster membership and target references across command operations.
import Base
import ./references.bend as Ref
import ./playerids.bend as Id
import ./players.bend as P
import ./allocation.bend as A
import ./admission.bend as J
import ./inventory.bend as Inv
import ./interactions.bend as Inter
import ./combat.bend as C
import ./payouts.bend as Pay
import ./battle.bend as B
import ./simulation.bend as S
import ./monsters.bend as M
import ./roster.bend as R
import ./vitals.bend as V
import ./game.bend as G
import ./ai.bend as AI
import ./terrain.bend as T
import ./population.bend as Pop

# Match Players.has_id's operand order exactly.
def Membership.lookup(ids: A.Allocation.Ids,+target: U32) -> Bool:
  match ids:
    case Nil{}: False{}
    case Con{head,rest}: Bool.or(U32.is_eq(head,target),Membership.lookup(rest,target))

law Membership.projection:
  for +players: List<&2,P.Players.State>
  for +target: U32
  {Membership.lookup(Id.PlayerIds.project(Id.PlayerIds.Player{},players),target) == P.Players.has_id(players,target) : Bool}

def Membership.projection(players,target):
  match players:
    case Nil{}: {==}
    case Con{head,rest}:
      %Membership.projection(rest,target) : {Bool.or(U32.is_eq(P.Players.id(head),target),Membership.lookup(Id.PlayerIds.project(Id.PlayerIds.Player{},rest),target)) == Bool.or(U32.is_eq(P.Players.id(head),target),_) : Bool}
      {==}

law Membership.or_swap:
  for +a: Bool
  for +b: Bool
  for +c: Bool
  {Bool.or(a,Bool.or(b,c)) == Bool.or(b,Bool.or(a,c)) : Bool}

def Membership.or_swap(a,b,c):
  match a:
    case True{}:
      match b:
        case True{}: {==}
        case False{}: {==}
    case False{}:
      match b:
        case True{}: {==}
        case False{}: {==}

law Membership.permutation:
  for -left: List<&2,P.Players.State>
  for -right: List<&2,P.Players.State>
  for +permutation: P.Players.Perm<left,right>
  for +target: U32
  {P.Players.has_id(left,target) == P.Players.has_id(right,target) : Bool}

def Membership.permutation(left,right,permutation,target):
  match permutation:
    case P.Players.Same{equal}:
      %equal : {P.Players.has_id(left,target) == P.Players.has_id(_,target) : Bool}
      {==}
    case P.Players.Common{head,lt,rt,ls,rs,tails}:
      %Equal.sym(List<&2,P.Players.State>,left,Con{head,lt},ls) : {P.Players.has_id(_,target) == P.Players.has_id(right,target) : Bool}
      %Equal.sym(List<&2,P.Players.State>,right,Con{head,rt},rs) : {P.Players.has_id(Con{head,lt},target) == P.Players.has_id(_,target) : Bool}
      %Membership.permutation(lt,rt,tails,target) : {Bool.or(U32.is_eq(P.Players.id(head),target),P.Players.has_id(lt,target)) == Bool.or(U32.is_eq(P.Players.id(head),target),_) : Bool}
      {==}
    case P.Players.Swap{first,second,rest,ls,rs}:
      %Equal.sym(List<&2,P.Players.State>,left,Con{first,Con{second,rest}},ls) : {P.Players.has_id(_,target) == P.Players.has_id(right,target) : Bool}
      %Equal.sym(List<&2,P.Players.State>,right,Con{second,Con{first,rest}},rs) : {P.Players.has_id(Con{first,Con{second,rest}},target) == P.Players.has_id(_,target) : Bool}
      Membership.or_swap(U32.is_eq(P.Players.id(first),target),U32.is_eq(P.Players.id(second),target),P.Players.has_id(rest,target))
    case P.Players.Then{middle,before,after}: Equal.trans(Bool,P.Players.has_id(left,target),P.Players.has_id(middle,target),P.Players.has_id(right,target),Membership.permutation(left,middle,before,target),Membership.permutation(middle,right,after,target))

law Membership.same_ids:
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +target: U32
  for +same: {Id.PlayerIds.project(Id.PlayerIds.Player{},after) == Id.PlayerIds.project(Id.PlayerIds.Player{},before) : A.Allocation.Ids}
  {P.Players.has_id(after,target) == P.Players.has_id(before,target) : Bool}

def Membership.same_ids(before,after,target,same):
  %Membership.projection(after,target) : {_ == P.Players.has_id(before,target) : Bool}
  %Membership.projection(before,target) : {Membership.lookup(Id.PlayerIds.project(Id.PlayerIds.Player{},after),target) == _ : Bool}
  %same : {Membership.lookup(Id.PlayerIds.project(Id.PlayerIds.Player{},after),target) == Membership.lookup(_,target) : Bool}
  {==}

# These witnesses preserve membership, including when the player records change.
# Added only preserves old membership; it does not claim absence is preserved.
type Membership.Rel<-before: List<&2,P.Players.State>,-after: List<&2,P.Players.State>> is Data:
  Membership.SameIds{old: List<&2,P.Players.State>,new: List<&2,P.Players.State>,old_shape: {old == before : List<&2,P.Players.State>},new_shape: {new == after : List<&2,P.Players.State>},equal: {Id.PlayerIds.project(Id.PlayerIds.Player{},new) == Id.PlayerIds.project(Id.PlayerIds.Player{},old) : A.Allocation.Ids}}
  Membership.Reordered{permutation: P.Players.Perm<after,before>}
  Membership.Added{player: P.Players.State,rest: List<&2,P.Players.State>,old_shape: {rest == before : List<&2,P.Players.State>},shape: {after == Con{player,rest} : List<&2,P.Players.State>}}
  Membership.Then{middle: List<&2,P.Players.State>,first: Membership.Rel<before,middle>,second: Membership.Rel<middle,after>}

def Membership.same(+before: List<&2,P.Players.State>,+after: List<&2,P.Players.State>,equal: {Id.PlayerIds.project(Id.PlayerIds.Player{},after) == Id.PlayerIds.project(Id.PlayerIds.Player{},before) : A.Allocation.Ids}) -> Membership.Rel<before,after>:
  Membership.SameIds{before,after,{==},{==},equal}

law Membership.extend:
  for +zero: Bool
  for +head: Bool
  for +tail: Bool
  for +valid: {Bool.or(zero,tail) == True{} : Bool}
  {Bool.or(zero,Bool.or(head,tail)) == True{} : Bool}

def Membership.extend(zero,head,tail,valid):
  match zero:
    case True{}: {==}
    case False{}:
      match head:
        case True{}: {==}
        case False{}: valid

law Membership.exists_equal:
  for -before: List<&2,P.Players.State>
  for -after: List<&2,P.Players.State>
  for +target: U32
  for +same: {P.Players.has_id(after,target) == P.Players.has_id(before,target) : Bool}
  for +valid: {Ref.References.exists(before,target) == True{} : Bool}
  {Ref.References.exists(after,target) == True{} : Bool}

def Membership.exists_equal(before,after,target,same,valid):
  %Equal.sym(Bool,P.Players.has_id(after,target),P.Players.has_id(before,target),same) : {Bool.or(U32.is_eq(target,0),_) == True{} : Bool}
  valid

law Membership.related_exists:
  for -before: List<&2,P.Players.State>
  for -after: List<&2,P.Players.State>
  for +relation: Membership.Rel<before,after>
  for +target: U32
  for +valid: {Ref.References.exists(before,target) == True{} : Bool}
  {Ref.References.exists(after,target) == True{} : Bool}

def Membership.related_exists(before,after,relation,target,valid):
  match relation:
    case Membership.SameIds{old,new,old_shape,new_shape,equal}:
      %new_shape : {Ref.References.exists(_,target) == True{} : Bool}
      Membership.exists_equal(old,new,target,Membership.same_ids(old,new,target,equal),(%Equal.sym(List<&2,P.Players.State>,old,before,old_shape) : {Ref.References.exists(_,target) == True{} : Bool}; valid))
    case Membership.Reordered{permutation}: Membership.exists_equal(before,after,target,Membership.permutation(after,before,permutation,target),valid)
    case Membership.Added{player,rest,old_shape,shape}:
      %Equal.sym(List<&2,P.Players.State>,after,Con{player,rest},shape) : {Ref.References.exists(_,target) == True{} : Bool}
      Membership.extend(U32.is_eq(target,0),U32.is_eq(P.Players.id(player),target),P.Players.has_id(rest,target),(%Equal.sym(List<&2,P.Players.State>,rest,before,old_shape) : {Ref.References.exists(_,target) == True{} : Bool}; valid))
    case Membership.Then{middle,first,second}: Membership.related_exists(middle,after,second,target,Membership.related_exists(before,middle,first,target,valid))

law Membership.related_all:
  for +monsters: List<&2,M.Monsters.State>
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +relation: Membership.Rel<before,after>
  for +valid: Ref.References.All(before,monsters)
  Ref.References.All(after,monsters)

def Membership.related_all(monsters,before,after,relation,valid):
  match monsters:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match valid:
        case Tuple{head_ok,rest_ok}: Tuple{Membership.related_exists(before,after,relation,Ref.References.target(head),head_ok),Membership.related_all(rest,before,after,relation,rest_ok)}

law Membership.inventory_ids:
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +frames: {Inv.Inventory.frames(after) == Inv.Inventory.frames(before) : List<&2,Inv.Inventory.Frame>}
  {Id.PlayerIds.project(Id.PlayerIds.Player{},after) == Id.PlayerIds.project(Id.PlayerIds.Player{},before) : A.Allocation.Ids}

def Membership.inventory_ids(before,after,frames):
  %Id.PlayerIds.inventory_projection(Id.PlayerIds.Player{},after) : {_ == Id.PlayerIds.project(Id.PlayerIds.Player{},before) : A.Allocation.Ids}
  %Id.PlayerIds.inventory_projection(Id.PlayerIds.Player{},before) : {Id.PlayerIds.inventory_keys(Id.PlayerIds.Player{},Inv.Inventory.frames(after)) == _ : A.Allocation.Ids}
  %frames : {Id.PlayerIds.inventory_keys(Id.PlayerIds.Player{},Inv.Inventory.frames(after)) == Id.PlayerIds.inventory_keys(Id.PlayerIds.Player{},_) : A.Allocation.Ids}
  {==}

law Membership.inventory_related:
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: Inv.Inventory.Conserved<before,after>
  Membership.Rel<before,after>

def Membership.inventory_related(before,after,conserved):
  match conserved:
    case Inv.Inventory.Conserved{ordered,permutation,frames}: Membership.Then{ordered,Membership.Reordered{permutation},Membership.same(ordered,after,Membership.inventory_ids(ordered,after,frames))}

law Membership.interaction_ids:
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +frames: {Inter.Interaction.frames(after) == Inter.Interaction.frames(before) : List<&2,Inter.Interaction.Frame>}
  {Id.PlayerIds.project(Id.PlayerIds.Player{},after) == Id.PlayerIds.project(Id.PlayerIds.Player{},before) : A.Allocation.Ids}

def Membership.interaction_ids(before,after,frames):
  %Id.PlayerIds.interaction_projection(Id.PlayerIds.Player{},after) : {_ == Id.PlayerIds.project(Id.PlayerIds.Player{},before) : A.Allocation.Ids}
  %Id.PlayerIds.interaction_projection(Id.PlayerIds.Player{},before) : {Id.PlayerIds.interaction_keys(Id.PlayerIds.Player{},Inter.Interaction.frames(after)) == _ : A.Allocation.Ids}
  %frames : {Id.PlayerIds.interaction_keys(Id.PlayerIds.Player{},Inter.Interaction.frames(after)) == Id.PlayerIds.interaction_keys(Id.PlayerIds.Player{},_) : A.Allocation.Ids}
  {==}

law Membership.interaction_related:
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: Inter.Interaction.Conserved<before,after>
  Membership.Rel<before,after>

def Membership.interaction_related(before,after,conserved):
  match conserved:
    case Inter.Interaction.Conserved{ordered,permutation,frames}: Membership.Then{ordered,Membership.Reordered{permutation},Membership.same(ordered,after,Membership.interaction_ids(ordered,after,frames))}

law Membership.combat_ids:
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +frames: {C.Combat.frames(after) == C.Combat.frames(before) : List<&2,C.Combat.Frame>}
  {Id.PlayerIds.project(Id.PlayerIds.Player{},after) == Id.PlayerIds.project(Id.PlayerIds.Player{},before) : A.Allocation.Ids}

def Membership.combat_ids(before,after,frames):
  %Id.PlayerIds.combat_projection(Id.PlayerIds.Player{},after) : {_ == Id.PlayerIds.project(Id.PlayerIds.Player{},before) : A.Allocation.Ids}
  %Id.PlayerIds.combat_projection(Id.PlayerIds.Player{},before) : {Id.PlayerIds.combat_keys(Id.PlayerIds.Player{},C.Combat.frames(after)) == _ : A.Allocation.Ids}
  %frames : {Id.PlayerIds.combat_keys(Id.PlayerIds.Player{},C.Combat.frames(after)) == Id.PlayerIds.combat_keys(Id.PlayerIds.Player{},_) : A.Allocation.Ids}
  {==}

law Membership.combat_related:
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: C.Combat.Conserved<before,after>
  Membership.Rel<before,after>

def Membership.combat_related(before,after,conserved):
  match conserved:
    case C.Combat.Conserved{ordered,permutation,frames}: Membership.Then{ordered,Membership.Reordered{permutation},Membership.same(ordered,after,Membership.combat_ids(ordered,after,frames))}

law Membership.payout_ids:
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +frames: {Pay.Payout.frames(after) == Pay.Payout.frames(before) : List<&2,Pay.Payout.Frame>}
  {Id.PlayerIds.project(Id.PlayerIds.Player{},after) == Id.PlayerIds.project(Id.PlayerIds.Player{},before) : A.Allocation.Ids}

def Membership.payout_ids(before,after,frames):
  %Id.PlayerIds.payout_projection(Id.PlayerIds.Player{},after) : {_ == Id.PlayerIds.project(Id.PlayerIds.Player{},before) : A.Allocation.Ids}
  %Id.PlayerIds.payout_projection(Id.PlayerIds.Player{},before) : {Id.PlayerIds.payout_keys(Id.PlayerIds.Player{},Pay.Payout.frames(after)) == _ : A.Allocation.Ids}
  %frames : {Id.PlayerIds.payout_keys(Id.PlayerIds.Player{},Pay.Payout.frames(after)) == Id.PlayerIds.payout_keys(Id.PlayerIds.Player{},_) : A.Allocation.Ids}
  {==}

law Membership.payout_related:
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: Pay.Payout.Conserved<before,after>
  Membership.Rel<before,after>

def Membership.payout_related(before,after,conserved):
  match conserved:
    case Pay.Payout.Conserved{ordered,permutation,frames}: Membership.Then{ordered,Membership.Reordered{permutation},Membership.same(ordered,after,Membership.payout_ids(ordered,after,frames))}

law Membership.inventory_run:
  for +players: List<&2,P.Players.State>
  for +pid: U32
  for +op: G.Bq.HOp
  for +near_shop: Bool
  for +amount: U32
  Membership.Rel<players,Inv.Inventory.roster(Inv.Inventory.run(players,pid,op,near_shop,amount))>

def Membership.inventory_run(players,pid,op,near_shop,amount): Membership.inventory_related(players,Inv.Inventory.roster(Inv.Inventory.run(players,pid,op,near_shop,amount)),Inv.Inventory.run_conserves(players,pid,op,near_shop,amount))

law Membership.interaction_run:
  for +players: List<&2,P.Players.State>
  for +pid: U32
  for +command: Inter.Interaction.Command
  Membership.Rel<players,Inter.Interaction.roster(Inter.Interaction.run(players,pid,command))>

def Membership.interaction_run(players,pid,command): Membership.interaction_related(players,Inter.Interaction.roster(Inter.Interaction.run(players,pid,command)),Inter.Interaction.run_conserves(players,pid,command))

law Membership.combat_run:
  for +players: List<&2,P.Players.State>
  for +pid: U32
  for +kind: C.Combat.Kind
  for +phase: U32
  Membership.Rel<players,C.Combat.roster(C.Combat.run(players,pid,kind,phase))>

def Membership.combat_run(players,pid,kind,phase): Membership.combat_related(players,C.Combat.roster(C.Combat.run(players,pid,kind,phase)),C.Combat.run_conserves(players,pid,kind,phase))

law Membership.payout_run:
  for +players: List<&2,P.Players.State>
  for +pid: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  Membership.Rel<players,Pay.Payout.roster(Pay.Payout.run(players,pid,plan,score))>

def Membership.payout_run(players,pid,plan,score): Membership.payout_related(players,Pay.Payout.roster(Pay.Payout.run(players,pid,plan,score)),Pay.Payout.run_conserves(players,pid,plan,score))

law Membership.strike:
  for +players: List<&2,P.Players.State>
  for +pid: U32
  for +attack: U32
  for +timer: U32
  Membership.Rel<players,P.Players.roster(P.Players.strike(players,pid,attack,timer))>

def Membership.strike(players,pid,attack,timer):
  Membership.Then{P.Players.restore(P.Players.take(players,pid)),Membership.Reordered{P.Players.take_restores(players,pid)},Membership.same(P.Players.restore(P.Players.take(players,pid)),P.Players.roster(P.Players.strike(players,pid,attack,timer)),Id.PlayerIds.hit_taken_projection(Id.PlayerIds.Player{},P.Players.take(players,pid),attack,timer))}

law Membership.apply_hits:
  for +hits: List<&2,P.Players.Attack>
  for +players: List<&2,P.Players.State>
  for +timer: U32
  Membership.Rel<players,P.Players.roster(P.Players.apply_hits(hits,players,timer))>

def Membership.apply_hits(hits,players,timer):
  match hits:
    case Nil{}: Membership.same(players,players,{==})
    case Con{head,rest}:
      match head:
        case P.Players.Attack{pid,attack}:
          +first = P.Players.strike(players,pid,attack,timer)
          +later = P.Players.apply_hits(rest,P.Players.roster(first),timer)
          %Equal.sym(List<&2,P.Players.State>,P.Players.roster(P.Players.before(first,later)),P.Players.roster(later),P.Players.before_roster(first,later)) : Membership.Rel<players,_>
          Membership.Then{P.Players.roster(first),Membership.strike(players,pid,attack,timer),Membership.apply_hits(rest,P.Players.roster(first),timer)}

law Membership.upkeep:
  for +players: List<&2,P.Players.State>
  for +plans: List<&2,P.Players.Plan>
  for +tick: U32
  for +x: U32
  for +y: U32
  Membership.Rel<players,P.Players.roster(P.Players.upkeep_all(players,plans,tick,x,y))>

def Membership.upkeep(players,plans,tick,x,y): Membership.same(players,P.Players.roster(P.Players.upkeep_all(players,plans,tick,x,y)),Id.PlayerIds.upkeep_projection(players,plans,Id.PlayerIds.Player{},tick,x,y))

law Membership.begin:
  for +state: S.Simulation.State
  for +plans: List<&2,P.Players.Plan>
  for +rules: S.Simulation.Rules
  Membership.Rel<S.Simulation.players(state),P.Players.roster(S.Simulation.prepared_upkeep(S.Simulation.begin(state,plans,rules)))>

def Membership.begin(state,plans,rules): Membership.same(S.Simulation.players(state),P.Players.roster(S.Simulation.prepared_upkeep(S.Simulation.begin(state,plans,rules))),Id.PlayerIds.begin_projection(Id.PlayerIds.Player{},state,plans,rules))

law Membership.commit:
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +choice: A.Allocation.Choice
  Membership.Rel<S.Simulation.players(state),S.Simulation.players(J.Admission.state(J.Admission.commit(state,cid,style,name,choice)))>

def Membership.commit(state,cid,style,name,choice):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      Membership.Added{P.Players.spawn(A.Allocation.id(choice),cid,style,name,4,8),players,{==},{==}}

law Membership.admitted:
  for +before: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +result: J.Admission.Result
  for +outcome: J.Admission.Outcome<before,cid,style,name,result>
  Membership.Rel<S.Simulation.players(before),S.Simulation.players(J.Admission.state(result))>

def Membership.admitted(before,cid,style,name,result,outcome):
  match outcome:
    case J.Admission.Rejected{exact}:
      %Equal.sym(J.Admission.Result,result,J.Admission.Result{before,0},exact) : Membership.Rel<S.Simulation.players(before),S.Simulation.players(J.Admission.state(_))>
      Membership.same(S.Simulation.players(before),S.Simulation.players(before),{==})
    case J.Admission.Created{choice,exact,fresh,positive,available}:
      %Equal.sym(J.Admission.Result,result,J.Admission.commit(before,cid,style,name,choice),exact) : Membership.Rel<S.Simulation.players(before),S.Simulation.players(J.Admission.state(_))>
      Membership.commit(before,cid,style,name,choice)

law Membership.admission:
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  Membership.Rel<S.Simulation.players(state),S.Simulation.players(J.Admission.state(J.Admission.add(state,cid,style,name)))>

def Membership.admission(state,cid,style,name): Membership.admitted(state,cid,style,name,J.Admission.add(state,cid,style,name),J.Admission.add_outcome(state,cid,style,name))

# Reference validity of a complete simulation state.
def Membership.World(+state: S.Simulation.State) -> Data:
  Ref.References.All(S.Simulation.players(state),S.Simulation.monsters(state))

law Membership.chosen_target:
  for +fell: Bool
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +valid: {Ref.References.exists(players,target) == True{} : Bool}
  {Ref.References.exists(players,M.Monsters.choose(fell,0,target)) == True{} : Bool}

def Membership.chosen_target(fell,players,target,valid):
  match fell:
    case False{}: valid
    case True{}: {==}

law Membership.monster_finish:
  for +monster: M.Monsters.State
  for +hit: V.Vitals.Hit
  for +damage: U32
  for +players: List<&2,P.Players.State>
  for +valid: Ref.References.Valid(players,monster)
  Ref.References.Valid(players,M.Monsters.result(M.Monsters.finish(monster,hit,damage)))

def Membership.monster_finish(monster,hit,damage,players,valid):
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}:
      match hit:
        case V.Vitals.Hit{next,fell}:
          match next:
            case V.Vitals.State{hp2,xp2,dead2,respawn2,attack2,spin2}: Membership.chosen_target(fell,players,target,valid)

law Membership.monster_hit_gate:
  for +dead: Bool
  for +monster: M.Monsters.State
  for +damage: U32
  for +timer: U32
  for +players: List<&2,P.Players.State>
  for +valid: Ref.References.Valid(players,monster)
  Ref.References.Valid(players,M.Monsters.result(M.Monsters.hit_gate(dead,monster,damage,timer)))

def Membership.monster_hit_gate(dead,monster,damage,timer,players,valid):
  match dead:
    case True{}: valid
    case False{}: Membership.monster_finish(monster,V.Vitals.hit_gate(False{},M.Monsters.vitals(monster),damage,timer),damage,players,valid)

law Membership.monster_hit:
  for +monster: M.Monsters.State
  for +damage: U32
  for +timer: U32
  for +players: List<&2,P.Players.State>
  for +valid: Ref.References.Valid(players,monster)
  Ref.References.Valid(players,M.Monsters.result(M.Monsters.hit(monster,damage,timer)))

def Membership.monster_hit(monster,damage,timer,players,valid): Membership.monster_hit_gate(U32.is_eq(V.Vitals.dead(M.Monsters.vitals(monster)),1),monster,damage,timer,players,valid)

def Membership.ref_head(players: List<&2,P.Players.State>,head: M.Monsters.State,rest: List<&2,M.Monsters.State>,valid: Ref.References.All(players,Con{head,rest})) -> Ref.References.Valid(players,head):
  match valid:
    case Tuple{head_ok,rest_ok}: head_ok

def Membership.ref_tail(players: List<&2,P.Players.State>,head: M.Monsters.State,rest: List<&2,M.Monsters.State>,valid: Ref.References.All(players,Con{head,rest})) -> Ref.References.All(players,rest):
  match valid:
    case Tuple{head_ok,rest_ok}: rest_ok

law Membership.swap_refs:
  for +players: List<&2,P.Players.State>
  for +first: M.Monsters.State
  for +second: M.Monsters.State
  for +rest: List<&2,M.Monsters.State>
  for +valid: Ref.References.All(players,Con{first,Con{second,rest}})
  Ref.References.All(players,Con{second,Con{first,rest}})

def Membership.swap_refs(players,first,second,rest,valid):
  match valid:
    case Tuple{a,later}:
      match later:
        case Tuple{b,tail}: Tuple{b,Tuple{a,tail}}

law Membership.monster_permutation:
  for -left: List<&2,M.Monsters.State>
  for -right: List<&2,M.Monsters.State>
  for +permutation: R.Roster.Perm<left,right>
  for +players: List<&2,P.Players.State>
  for +valid: Ref.References.All(players,right)
  Ref.References.All(players,left)

def Membership.monster_permutation(left,right,permutation,players,valid):
  match permutation:
    case R.Roster.Same{equal}:
      %Equal.sym(List<&2,M.Monsters.State>,left,right,equal) : Ref.References.All(players,_)
      valid
    case R.Roster.Common{head,lt,rt,ls,rs,tails}:
      +given = {(%rs : Ref.References.All(players,_); valid) : Ref.References.All(players,Con{head,rt})}
      %Equal.sym(List<&2,M.Monsters.State>,left,Con{head,lt},ls) : Ref.References.All(players,_)
      Tuple{Membership.ref_head(players,head,rt,given),Membership.monster_permutation(lt,rt,tails,players,Membership.ref_tail(players,head,rt,given))}
    case R.Roster.Swap{first,second,rest,ls,rs}:
      %Equal.sym(List<&2,M.Monsters.State>,left,Con{first,Con{second,rest}},ls) : Ref.References.All(players,_)
      Membership.swap_refs(players,second,first,rest,(%rs : Ref.References.All(players,_); valid))
    case R.Roster.Then{middle,before,after}: Membership.monster_permutation(left,middle,before,players,Membership.monster_permutation(middle,right,after,players,valid))

law Membership.strike_result:
  for +hit: M.Monsters.Hit
  for +others: List<&2,M.Monsters.State>
  for +players: List<&2,P.Players.State>
  for +head_ok: Ref.References.Valid(players,M.Monsters.result(hit))
  for +rest_ok: Ref.References.All(players,others)
  Ref.References.All(players,R.Roster.struck(R.Roster.strike_result(hit,others)))

def Membership.strike_result(hit,others,players,head_ok,rest_ok):
  match hit:
    case M.Monsters.Hit{monster,killed,dealt}:
      match monster:
        case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}:
          match killed:
            case False{}: Tuple{head_ok,rest_ok}
            case True{}: Tuple{head_ok,rest_ok}

law Membership.strike_taken:
  for +taken: R.Roster.Take
  for +damage: U32
  for +players: List<&2,P.Players.State>
  for +valid: Ref.References.All(players,R.Roster.restore(taken))
  Ref.References.All(players,R.Roster.struck(R.Roster.strike_taken(taken,damage)))

def Membership.strike_taken(taken,damage,players,valid):
  match taken:
    case R.Roster.Take{others,found}:
      match found:
        case None{}: valid
        case Some{monster}:
          match valid:
            case Tuple{head_ok,rest_ok}:
              +timer = R.Roster.respawn_time(M.Monsters.kind(monster))
              Membership.strike_result(M.Monsters.hit(monster,damage,timer),others,players,Membership.monster_hit(monster,damage,timer,players,head_ok),rest_ok)

law Membership.roster_strike:
  for +monsters: List<&2,M.Monsters.State>
  for +mid: U32
  for +damage: U32
  for +players: List<&2,P.Players.State>
  for +valid: Ref.References.All(players,monsters)
  Ref.References.All(players,R.Roster.struck(R.Roster.strike(monsters,mid,damage)))

def Membership.roster_strike(monsters,mid,damage,players,valid): Membership.strike_taken(R.Roster.take(monsters,mid),damage,players,Membership.monster_permutation(R.Roster.restore(R.Roster.take(monsters,mid)),monsters,R.Roster.take_restores(monsters,mid),players,valid))

law Membership.reward_world:
  for +state: S.Simulation.State
  for +pid: U32
  for +kill: R.Roster.Kill
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +valid: Membership.World(state)
  Membership.World(B.Battle.state(B.Battle.reward(state,pid,kill,plan,score)))

def Membership.reward_world(state,pid,kill,plan,score,valid):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      +bound = B.Battle.bind_kind(plan,B.Battle.kind(kill))
      +paid = Pay.Payout.run(players,pid,bound,score)
      %Equal.sym(List<&2,M.Monsters.State>,S.Simulation.monsters(B.Battle.state(B.Battle.finish_reward(meta,monsters,kill,paid))),monsters,B.Battle.finish_reward_monsters(meta,monsters,kill,paid)) : Ref.References.All(S.Simulation.players(B.Battle.state(B.Battle.finish_reward(meta,monsters,kill,paid))),_)
      %Equal.sym(List<&2,P.Players.State>,S.Simulation.players(B.Battle.state(B.Battle.finish_reward(meta,monsters,kill,paid))),Pay.Payout.roster(paid),B.Battle.finish_reward_players(meta,monsters,kill,paid)) : Ref.References.All(_,monsters)
      Membership.related_all(monsters,players,Pay.Payout.roster(paid),Membership.payout_run(players,pid,bound,score),valid)

law Membership.after_world:
  for +kill: Maybe<&2,R.Roster.Kill>
  for +state: S.Simulation.State
  for +pid: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +valid: Membership.World(state)
  Membership.World(B.Battle.state(B.Battle.after(kill,state,pid,plan,score)))

def Membership.after_world(kill,state,pid,plan,score,valid):
  match kill:
    case None{}: valid
    case Some{info}: Membership.reward_world(state,pid,info,plan,score,valid)

law Membership.finish_hit_world:
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +hit: R.Roster.Strike
  for +pid: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +valid: Ref.References.All(players,R.Roster.struck(hit))
  Membership.World(B.Battle.state(B.Battle.finish_hit(meta,players,hit,pid,plan,score)))

def Membership.finish_hit_world(meta,players,hit,pid,plan,score,valid):
  match hit:
    case R.Roster.Strike{monsters,kill,dealt}: Membership.after_world(kill,S.Simulation.State{meta,players,monsters},pid,plan,score,valid)

law Membership.battle_strike_world:
  for +input: B.Battle.Input
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +valid: Membership.World(state)
  Membership.World(B.Battle.state(B.Battle.strike(input,state,pid,score)))

def Membership.battle_strike_world(input,state,pid,score,valid):
  match input:
    case B.Battle.Input{mid,damage,plan}:
      match state:
        case S.Simulation.State{meta,players,monsters}: Membership.finish_hit_world(meta,players,R.Roster.strike(monsters,mid,damage),pid,plan,score,Membership.roster_strike(monsters,mid,damage,players,valid))

law Membership.battle_run_world:
  for +inputs: List<&2,B.Battle.Input>
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +valid: Membership.World(state)
  Membership.World(B.Battle.state(B.Battle.run(inputs,state,pid,score)))

def Membership.battle_run_world(inputs,state,pid,score,valid):
  match inputs:
    case Nil{}: valid
    case Con{head,rest}: Membership.battle_run_world(rest,B.Battle.state(B.Battle.strike(head,state,pid,score)),pid,score,Membership.battle_strike_world(head,state,pid,score,valid))

law Membership.execute_world:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +admitted: C.Combat.Result
  for +inputs: List<&2,B.Battle.Input>
  for +pid: U32
  for +score: U32
  for +valid: Ref.References.All(C.Combat.roster(admitted),monsters)
  Membership.World(B.Battle.state(B.Battle.execute(meta,monsters,admitted,inputs,pid,score)))

def Membership.execute_world(meta,monsters,admitted,inputs,pid,score,valid):
  match admitted:
    case C.Combat.Result{players,attacker}:
      match attacker:
        case None{}: valid
        case Some{actor}: Membership.battle_run_world(inputs,S.Simulation.State{meta,players,monsters},pid,score,valid)

law Membership.command_world:
  for +kind: C.Combat.Kind
  for +state: S.Simulation.State
  for +inputs: List<&2,B.Battle.Input>
  for +pid: U32
  for +score: U32
  for +valid: Membership.World(state)
  Membership.World(B.Battle.state(B.Battle.command(kind,state,inputs,pid,score)))

def Membership.command_world(kind,state,inputs,pid,score,valid):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      +phase = S.Simulation.phase(meta)
      +admitted = C.Combat.run(players,pid,kind,phase)
      Membership.execute_world(meta,monsters,admitted,inputs,pid,score,Membership.related_all(monsters,players,C.Combat.roster(admitted),Membership.combat_run(players,pid,kind,phase),valid))

# Unlike References.exists, this theorem proves actual membership even for ID 0.
law Membership.related_has:
  for -before: List<&2,P.Players.State>
  for -after: List<&2,P.Players.State>
  for +relation: Membership.Rel<before,after>
  for +target: U32
  for +valid: {P.Players.has_id(before,target) == True{} : Bool}
  {P.Players.has_id(after,target) == True{} : Bool}

def Membership.related_has(before,after,relation,target,valid):
  match relation:
    case Membership.SameIds{old,new,old_shape,new_shape,equal}:
      %new_shape : {P.Players.has_id(_,target) == True{} : Bool}
      %Equal.sym(Bool,P.Players.has_id(new,target),P.Players.has_id(old,target),Membership.same_ids(old,new,target,equal)) : {_ == True{} : Bool}
      %Equal.sym(List<&2,P.Players.State>,old,before,old_shape) : {P.Players.has_id(_,target) == True{} : Bool}
      valid
    case Membership.Reordered{permutation}:
      %Equal.sym(Bool,P.Players.has_id(after,target),P.Players.has_id(before,target),Membership.permutation(after,before,permutation,target)) : {_ == True{} : Bool}
      valid
    case Membership.Added{player,rest,old_shape,shape}:
      %Equal.sym(List<&2,P.Players.State>,after,Con{player,rest},shape) : {P.Players.has_id(_,target) == True{} : Bool}
      Membership.extend(False{},U32.is_eq(P.Players.id(player),target),P.Players.has_id(rest,target),(%Equal.sym(List<&2,P.Players.State>,rest,before,old_shape) : {P.Players.has_id(_,target) == True{} : Bool}; valid))
    case Membership.Then{middle,first,second}: Membership.related_has(middle,after,second,target,Membership.related_has(before,middle,first,target,valid))

law Membership.commit_world:
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +choice: A.Allocation.Choice
  for +valid: Membership.World(state)
  Membership.World(J.Admission.state(J.Admission.commit(state,cid,style,name,choice)))

def Membership.commit_world(state,cid,style,name,choice,valid):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      +before = {S.Simulation.State{meta,players,monsters} : S.Simulation.State}
      Membership.related_all(monsters,players,S.Simulation.players(J.Admission.state(J.Admission.commit(before,cid,style,name,choice))),Membership.commit(before,cid,style,name,choice),valid)

law Membership.admitted_world:
  for +before: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +result: J.Admission.Result
  for +outcome: J.Admission.Outcome<before,cid,style,name,result>
  for +valid: Membership.World(before)
  Membership.World(J.Admission.state(result))

def Membership.admitted_world(before,cid,style,name,result,outcome,valid):
  match outcome:
    case J.Admission.Rejected{exact}:
      %Equal.sym(J.Admission.Result,result,J.Admission.Result{before,0},exact) : Membership.World(J.Admission.state(_))
      valid
    case J.Admission.Created{choice,exact,fresh,positive,available}:
      %Equal.sym(J.Admission.Result,result,J.Admission.commit(before,cid,style,name,choice),exact) : Membership.World(J.Admission.state(_))
      Membership.commit_world(before,cid,style,name,choice,valid)

law Membership.admission_world:
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +valid: Membership.World(state)
  Membership.World(J.Admission.state(J.Admission.add(state,cid,style,name)))

def Membership.admission_world(state,cid,style,name,valid): Membership.admitted_world(state,cid,style,name,J.Admission.add(state,cid,style,name),J.Admission.add_outcome(state,cid,style,name),valid)

# A precise classifier for the command-only fragment of the existing sequence.
# Arbitrary supplied tick contexts can name nonexistent players. The actual
# server's AI target-selection proof is a separate remaining obligation.
def Membership.Command(change: Id.PlayerIds.Change) -> Data:
  match change:
    case Id.PlayerIds.Create{cid,style,name}: Unit
    case Id.PlayerIds.Remove{pid}: Unit
    case Id.PlayerIds.Inventory{pid,op,near_shop,amount}: Unit
    case Id.PlayerIds.Interact{pid,command}: Unit
    case Id.PlayerIds.Fight{kind,inputs,pid,score}: Unit
    case Id.PlayerIds.Tick{input,rules}: Empty

law Membership.change_world:
  for +change: Id.PlayerIds.Change
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +command: Membership.Command(change)
  for +valid: Membership.World(state)
  Membership.World(Id.PlayerIds.run_change(change,state,maps))

def Membership.change_world(change,state,maps,command,valid):
  match change:
    case Id.PlayerIds.Create{cid,style,name}: Membership.admission_world(state,cid,style,name,valid)
    case Id.PlayerIds.Remove{pid}: Ref.References.remove_valid(state,pid)
    case Id.PlayerIds.Inventory{pid,op,near_shop,amount}:
      match state:
        case S.Simulation.State{meta,players,monsters}: Membership.related_all(monsters,players,Inv.Inventory.roster(Inv.Inventory.run(players,pid,op,near_shop,amount)),Membership.inventory_run(players,pid,op,near_shop,amount),valid)
    case Id.PlayerIds.Interact{pid,interaction}:
      match state:
        case S.Simulation.State{meta,players,monsters}: Membership.related_all(monsters,players,Inter.Interaction.roster(Inter.Interaction.run(players,pid,interaction)),Membership.interaction_run(players,pid,interaction),valid)
    case Id.PlayerIds.Fight{kind,inputs,pid,score}: Membership.command_world(kind,state,inputs,pid,score,valid)
    case Id.PlayerIds.Tick{input,rules}: Empty.absurd(Membership.World(Id.PlayerIds.run_change(Id.PlayerIds.Tick{input,rules},state,maps)),command)

def Membership.Commands(changes: List<&2,Id.PlayerIds.Change>) -> Data:
  match changes:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,Membership.Command(head),(command => Membership.Commands(rest))>

law Membership.trace_world:
  for +changes: List<&2,Id.PlayerIds.Change>
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +commands: Membership.Commands(changes)
  for +valid: Membership.World(state)
  Membership.World(Id.PlayerIds.trace(changes,state,maps))

def Membership.trace_world(changes,state,maps,commands,valid):
  match changes:
    case Nil{}: valid
    case Con{head,rest}:
      match commands:
        case Tuple{command,remaining}: Membership.trace_world(rest,Id.PlayerIds.run_change(head,state,maps),maps,remaining,Membership.change_world(head,state,maps,command,valid))

law Membership.fresh_trace_world:
  for +changes: List<&2,Id.PlayerIds.Change>
  for +world: U32
  for +seed: U32
  for +now: U32
  for +maps: T.Terrain.Maps
  for +commands: Membership.Commands(changes)
  Membership.World(Id.PlayerIds.trace(changes,T.Terrain.simulation(Pop.Population.fresh(world,seed,now)),maps))

def Membership.fresh_trace_world(changes,world,seed,now,maps,commands): Membership.trace_world(changes,T.Terrain.simulation(Pop.Population.fresh(world,seed,now)),maps,commands,Ref.References.fresh_valid(world,seed,now))
