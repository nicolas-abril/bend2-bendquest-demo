# Combined pure-world invariant. Active connection records and their effectful
# dispatcher are separate obligations before claiming the full server WorldOK.
import Base
import ./players.bend as P
import ./simulation.bend as S
import ./planning.bend as Plan
import ./population.bend as Pop
import ./landscape.bend as L
import ./terrain.bend as T
import ./locomotion.bend as Walk
import ./habitat.bend as H
import ./identity.bend as I
import ./playerids.bend as Id
import ./admission.bend as J
import ./allocation.bend as Alloc
import ./nonzero.bend as NZ
import ./references.bend as Ref
import ./membership.bend as Mem
import ./ai_refs.bend as AR
import ./inventory.bend as Inv
import ./combat.bend as C
import ./interactions.bend as Inter
import ./payouts.bend as Pay
import ./battle.bend as B
import ./navigation.bend as Nav
import ./vitals.bend as V
import ./game.bend as G
import ./monsters.bend as M
import ./roster.bend as R

# The seed identifies the map family used by every transition in this contract.
type WorldState.OK<-seed: U32,-state: S.Simulation.State> is Data:
  WorldState.OK{health: S.Simulation.OK<state>,positions: Plan.Planning.Positions<seed,state>,monsters: I.Identity.Monsters(S.Simulation.monsters(state)),players: J.Admission.Unique<S.Simulation.players(state)>,nonzero: NZ.Nonzero.All<S.Simulation.players(state)>,references: Mem.Membership.World(state)}

def WorldState.input(+prepared: S.Simulation.Prepared,d0: List<&2,U32>,d1: List<&2,U32>,d2: List<&2,U32>,d3: List<&2,U32>) -> Plan.Planning.Input:
  +players = P.Players.roster(S.Simulation.prepared_upkeep(prepared))
  +monsters = S.Simulation.prepared_monsters(prepared)
  Plan.Planning.Input{AR.AIRefs.contexts(monsters,players,0,d0),AR.AIRefs.contexts(monsters,players,1,d1),AR.AIRefs.contexts(monsters,players,2,d2),AR.AIRefs.contexts(monsters,players,3,d3)}

def WorldState.finish(input: Plan.Planning.Input,prepared: S.Simulation.Prepared,maps: T.Terrain.Maps,rules: S.Simulation.Rules) -> S.Simulation.Result:
  match input:
    case Plan.Planning.Input{c0,c1,c2,c3}: Plan.Planning.finish(prepared,maps,c0,c1,c2,c3,rules)

law WorldState.finish_refines:
  for +prepared: S.Simulation.Prepared
  for +maps: T.Terrain.Maps
  for +d0: List<&2,U32>
  for +d1: List<&2,U32>
  for +d2: List<&2,U32>
  for +d3: List<&2,U32>
  for +rules: S.Simulation.Rules
  {AR.AIRefs.finish(prepared,maps,d0,d1,d2,d3,rules) == WorldState.finish(WorldState.input(prepared,d0,d1,d2,d3),prepared,maps,rules) : S.Simulation.Result}

def WorldState.finish_refines(prepared,maps,d0,d1,d2,d3,rules):
  match prepared:
    case S.Simulation.Prepared{meta,monsters,upkeep,running}:
      match running:
        case True{}: {==}
        case False{}: {==}

law WorldState.planning_finish:
  for +input: Plan.Planning.Input
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  {WorldState.finish(input,Walk.Locomotion.begin(state,maps,rules),maps,rules) == Plan.Planning.tick(state,input,maps,rules) : S.Simulation.Result}

def WorldState.planning_finish(input,state,maps,rules):
  match input:
    case Plan.Planning.Input{c0,c1,c2,c3}: {==}

law WorldState.tick_refines:
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +d0: List<&2,U32>
  for +d1: List<&2,U32>
  for +d2: List<&2,U32>
  for +d3: List<&2,U32>
  for +rules: S.Simulation.Rules
  {AR.AIRefs.tick(state,maps,d0,d1,d2,d3,rules) == Plan.Planning.tick(state,WorldState.input(Walk.Locomotion.begin(state,maps,rules),d0,d1,d2,d3),maps,rules) : S.Simulation.Result}

def WorldState.tick_refines(state,maps,d0,d1,d2,d3,rules):
  +prepared = Walk.Locomotion.begin(state,maps,rules)
  %WorldState.planning_finish(WorldState.input(prepared,d0,d1,d2,d3),state,maps,rules) : {AR.AIRefs.tick(state,maps,d0,d1,d2,d3,rules) == _ : S.Simulation.Result}
  WorldState.finish_refines(prepared,maps,d0,d1,d2,d3,rules)

law WorldState.fresh:
  for +world: U32
  for +seed: U32
  for +now: U32
  WorldState.OK<seed,T.Terrain.simulation(Pop.Population.fresh(world,seed,now))>

def WorldState.fresh(world,seed,now): WorldState.OK{Pop.Population.fresh_ok(world,seed,now),Plan.Planning.initial_positions(world,seed,now),I.Identity.fresh_unique(world,seed,now),J.Admission.Unique{Unit{},Unit{}},NZ.Nonzero.All{Unit{},Unit{}},Ref.References.fresh_valid(world,seed,now)}

law WorldState.tick:
  for +seed: U32
  for +state: S.Simulation.State
  for +d0: List<&2,U32>
  for +d1: List<&2,U32>
  for +d2: List<&2,U32>
  for +d3: List<&2,U32>
  for +timer: U32
  for +valid: WorldState.OK<seed,state>
  WorldState.OK<seed,S.Simulation.state(AR.AIRefs.tick(state,L.Landscape.maps(seed),d0,d1,d2,d3,Plan.Planning.rules(timer)))>

def WorldState.tick(seed,state,d0,d1,d2,d3,timer,valid):
  match valid:
    case WorldState.OK{health,positions,monsters,players,nonzero,references}:
      +maps = L.Landscape.maps(seed)
      +rules = Plan.Planning.rules(timer)
      +input = WorldState.input(Walk.Locomotion.begin(state,maps,rules),d0,d1,d2,d3)
      +exact = WorldState.tick_refines(state,maps,d0,d1,d2,d3,rules)
      %Equal.sym(S.Simulation.Result,AR.AIRefs.tick(state,maps,d0,d1,d2,d3,rules),Plan.Planning.tick(state,input,maps,rules),exact) : WorldState.OK<seed,S.Simulation.state(_)>
      WorldState.OK{Plan.Planning.tick_ok(state,input,maps,rules,health),Plan.Planning.tick_positions(seed,state,input,timer,positions),I.Identity.planning_tick_unique(state,input,maps,rules,I.Identity.ok_zones(state,health),monsters),Id.PlayerIds.planning_tick_both(state,input,maps,rules,players),NZ.Nonzero.planning_tick_both(state,input,maps,rules,nonzero),(%exact : Mem.Membership.World(S.Simulation.state(_)); AR.AIRefs.tick_valid_world(state,maps,d0,d1,d2,d3,rules,references))}

# Exact frame conservation transports walkability, including reordered rosters.
def WorldState.positions(players: List<&2,P.Players.State>) -> List<&2,P.Players.Pos>:
  match players:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{Nav.Navigation.pos(head),WorldState.positions(rest)}

def WorldState.OnPositions(+maps: T.Terrain.Maps,positions: List<&2,P.Players.Pos>) -> Data:
  match positions:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,T.Terrain.On<maps,head>,(valid => WorldState.OnPositions(maps,rest))>

law WorldState.positions_valid:
  for +players: List<&2,P.Players.State>
  for +maps: T.Terrain.Maps
  for +valid: Walk.Locomotion.All(maps,players)
  WorldState.OnPositions(maps,WorldState.positions(players))

def WorldState.positions_valid(players,maps,valid):
  match players:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match valid:
        case Tuple{first,later}: Tuple{first,WorldState.positions_valid(rest,maps,later)}

law WorldState.players_valid:
  for +players: List<&2,P.Players.State>
  for +maps: T.Terrain.Maps
  for +valid: WorldState.OnPositions(maps,WorldState.positions(players))
  Walk.Locomotion.All(maps,players)

def WorldState.players_valid(players,maps,valid):
  match players:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match valid:
        case Tuple{first,later}: Tuple{first,WorldState.players_valid(rest,maps,later)}

def WorldState.inventory_pos(frame: Inv.Inventory.Frame) -> P.Players.Pos:
  match frame:
    case Inv.Inventory.Frame{pid,cid,pos,xp,dead,respawn,attack,spin,style,quest,meta}: pos

law WorldState.inventory_position:
  for +player: P.Players.State
  {WorldState.inventory_pos(Inv.Inventory.frame(player)) == Nav.Navigation.pos(player) : P.Players.Pos}

def WorldState.inventory_position(player):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match vitals:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: {==}

def WorldState.inventory_positions(frames: List<&2,Inv.Inventory.Frame>) -> List<&2,P.Players.Pos>:
  match frames:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{WorldState.inventory_pos(head),WorldState.inventory_positions(rest)}

law WorldState.inventory_projection:
  for +players: List<&2,P.Players.State>
  {WorldState.inventory_positions(Inv.Inventory.frames(players)) == WorldState.positions(players) : List<&2,P.Players.Pos>}

def WorldState.inventory_projection(players):
  match players:
    case Nil{}: {==}
    case Con{head,rest}:
      %WorldState.inventory_position(head) : {Con{WorldState.inventory_pos(Inv.Inventory.frame(head)),WorldState.inventory_positions(Inv.Inventory.frames(rest))} == Con{_,WorldState.positions(rest)} : List<&2,P.Players.Pos>}
      %WorldState.inventory_projection(rest) : {Con{WorldState.inventory_pos(Inv.Inventory.frame(head)),WorldState.inventory_positions(Inv.Inventory.frames(rest))} == Con{WorldState.inventory_pos(Inv.Inventory.frame(head)),_} : List<&2,P.Players.Pos>}
      {==}

law WorldState.inventory_conserved_on:
  for +maps: T.Terrain.Maps
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: Inv.Inventory.Conserved<before,after>
  for +valid: Walk.Locomotion.All(maps,before)
  Walk.Locomotion.All(maps,after)

def WorldState.inventory_conserved_on(maps,before,after,conserved,valid):
  match conserved:
    case Inv.Inventory.Conserved{ordered,permutation,frames}:
      WorldState.players_valid(after,maps,(%WorldState.inventory_projection(after) : WorldState.OnPositions(maps,_); %Equal.sym(List<&2,Inv.Inventory.Frame>,Inv.Inventory.frames(after),Inv.Inventory.frames(ordered),frames) : WorldState.OnPositions(maps,WorldState.inventory_positions(_)); %Equal.sym(List<&2,P.Players.Pos>,WorldState.inventory_positions(Inv.Inventory.frames(ordered)),WorldState.positions(ordered),WorldState.inventory_projection(ordered)) : WorldState.OnPositions(maps,_); WorldState.positions_valid(ordered,maps,Walk.Locomotion.perm_on(maps,ordered,before,permutation,valid))))

def WorldState.combat_pos(frame: C.Combat.Frame) -> P.Players.Pos:
  match frame:
    case C.Combat.Frame{pid,cid,hero,pos,hp,xp,dead,respawn,style,quest,meta}: pos

law WorldState.combat_position:
  for +player: P.Players.State
  {WorldState.combat_pos(C.Combat.frame(player)) == Nav.Navigation.pos(player) : P.Players.Pos}

def WorldState.combat_position(player):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match vitals:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: {==}

def WorldState.combat_positions(frames: List<&2,C.Combat.Frame>) -> List<&2,P.Players.Pos>:
  match frames:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{WorldState.combat_pos(head),WorldState.combat_positions(rest)}

law WorldState.combat_projection:
  for +players: List<&2,P.Players.State>
  {WorldState.combat_positions(C.Combat.frames(players)) == WorldState.positions(players) : List<&2,P.Players.Pos>}

def WorldState.combat_projection(players):
  match players:
    case Nil{}: {==}
    case Con{head,rest}:
      %WorldState.combat_position(head) : {Con{WorldState.combat_pos(C.Combat.frame(head)),WorldState.combat_positions(C.Combat.frames(rest))} == Con{_,WorldState.positions(rest)} : List<&2,P.Players.Pos>}
      %WorldState.combat_projection(rest) : {Con{WorldState.combat_pos(C.Combat.frame(head)),WorldState.combat_positions(C.Combat.frames(rest))} == Con{WorldState.combat_pos(C.Combat.frame(head)),_} : List<&2,P.Players.Pos>}
      {==}

law WorldState.combat_conserved_on:
  for +maps: T.Terrain.Maps
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: C.Combat.Conserved<before,after>
  for +valid: Walk.Locomotion.All(maps,before)
  Walk.Locomotion.All(maps,after)

def WorldState.combat_conserved_on(maps,before,after,conserved,valid):
  match conserved:
    case C.Combat.Conserved{ordered,permutation,frames}:
      WorldState.players_valid(after,maps,(%WorldState.combat_projection(after) : WorldState.OnPositions(maps,_); %Equal.sym(List<&2,C.Combat.Frame>,C.Combat.frames(after),C.Combat.frames(ordered),frames) : WorldState.OnPositions(maps,WorldState.combat_positions(_)); %Equal.sym(List<&2,P.Players.Pos>,WorldState.combat_positions(C.Combat.frames(ordered)),WorldState.positions(ordered),WorldState.combat_projection(ordered)) : WorldState.OnPositions(maps,_); WorldState.positions_valid(ordered,maps,Walk.Locomotion.perm_on(maps,ordered,before,permutation,valid))))

def WorldState.payout_pos(frame: Pay.Payout.Frame) -> P.Players.Pos:
  match frame:
    case Pay.Payout.Frame{pid,cid,pos,hp,dead,respawn,attack,spin,style,name}: pos

law WorldState.payout_position:
  for +player: P.Players.State
  {WorldState.payout_pos(Pay.Payout.frame(player)) == Nav.Navigation.pos(player) : P.Players.Pos}

def WorldState.payout_position(player):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match vitals:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}:
          match meta:
            case P.Players.Meta{score,kills,found,name}: {==}

def WorldState.payout_positions(frames: List<&2,Pay.Payout.Frame>) -> List<&2,P.Players.Pos>:
  match frames:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{WorldState.payout_pos(head),WorldState.payout_positions(rest)}

law WorldState.payout_projection:
  for +players: List<&2,P.Players.State>
  {WorldState.payout_positions(Pay.Payout.frames(players)) == WorldState.positions(players) : List<&2,P.Players.Pos>}

def WorldState.payout_projection(players):
  match players:
    case Nil{}: {==}
    case Con{head,rest}:
      %WorldState.payout_position(head) : {Con{WorldState.payout_pos(Pay.Payout.frame(head)),WorldState.payout_positions(Pay.Payout.frames(rest))} == Con{_,WorldState.positions(rest)} : List<&2,P.Players.Pos>}
      %WorldState.payout_projection(rest) : {Con{WorldState.payout_pos(Pay.Payout.frame(head)),WorldState.payout_positions(Pay.Payout.frames(rest))} == Con{WorldState.payout_pos(Pay.Payout.frame(head)),_} : List<&2,P.Players.Pos>}
      {==}

law WorldState.payout_conserved_on:
  for +maps: T.Terrain.Maps
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: Pay.Payout.Conserved<before,after>
  for +valid: Walk.Locomotion.All(maps,before)
  Walk.Locomotion.All(maps,after)

def WorldState.payout_conserved_on(maps,before,after,conserved,valid):
  match conserved:
    case Pay.Payout.Conserved{ordered,permutation,frames}:
      WorldState.players_valid(after,maps,(%WorldState.payout_projection(after) : WorldState.OnPositions(maps,_); %Equal.sym(List<&2,Pay.Payout.Frame>,Pay.Payout.frames(after),Pay.Payout.frames(ordered),frames) : WorldState.OnPositions(maps,WorldState.payout_positions(_)); %Equal.sym(List<&2,P.Players.Pos>,WorldState.payout_positions(Pay.Payout.frames(ordered)),WorldState.positions(ordered),WorldState.payout_projection(ordered)) : WorldState.OnPositions(maps,_); WorldState.positions_valid(ordered,maps,Walk.Locomotion.perm_on(maps,ordered,before,permutation,valid))))

law WorldState.paid_on:
  for +seed: U32
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +monsters: List<&2,M.Monsters.State>
  for +kill: R.Roster.Kill
  for +paid: Maybe<&2,Pay.Payout.Kill>
  for +valid: Plan.Planning.Positions<seed,S.Simulation.State{meta,players,monsters}>
  Plan.Planning.Positions<seed,B.Battle.state(B.Battle.paid(meta,players,monsters,kill,paid))>

def WorldState.paid_on(seed,meta,players,monsters,kill,paid,valid):
  match paid:
    case None{}: valid
    case Some{award}:
      match valid:
        case Plan.Planning.Positions{ps,ms}: Plan.Planning.Positions{ps,ms}

law WorldState.finish_reward_on:
  for +seed: U32
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +kill: R.Roster.Kill
  for +paid: Pay.Payout.Result
  for +ps: Walk.Locomotion.All(L.Landscape.maps(seed),Pay.Payout.roster(paid))
  for +ms: H.Habitat.All(L.Landscape.maps(seed),monsters)
  Plan.Planning.Positions<seed,B.Battle.state(B.Battle.finish_reward(meta,monsters,kill,paid))>

def WorldState.finish_reward_on(seed,meta,monsters,kill,paid,ps,ms):
  match paid:
    case Pay.Payout.Result{players,award}: WorldState.paid_on(seed,meta,players,monsters,kill,award,Plan.Planning.Positions{ps,ms})

law WorldState.reward_on:
  for +seed: U32
  for +state: S.Simulation.State
  for +pid: U32
  for +kill: R.Roster.Kill
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +valid: Plan.Planning.Positions<seed,state>
  Plan.Planning.Positions<seed,B.Battle.state(B.Battle.reward(state,pid,kill,plan,score))>

def WorldState.reward_on(seed,state,pid,kill,plan,score,valid):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      match valid:
        case Plan.Planning.Positions{ps,ms}:
          +bound = B.Battle.bind_kind(plan,B.Battle.kind(kill))
          +paid = Pay.Payout.run(players,pid,bound,score)
          WorldState.finish_reward_on(seed,meta,monsters,kill,paid,WorldState.payout_conserved_on(L.Landscape.maps(seed),players,Pay.Payout.roster(paid),Pay.Payout.run_conserves(players,pid,bound,score),ps),ms)

law WorldState.after_on:
  for +kill: Maybe<&2,R.Roster.Kill>
  for +seed: U32
  for +state: S.Simulation.State
  for +pid: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +valid: Plan.Planning.Positions<seed,state>
  Plan.Planning.Positions<seed,B.Battle.state(B.Battle.after(kill,state,pid,plan,score))>

def WorldState.after_on(kill,seed,state,pid,plan,score,valid):
  match kill:
    case None{}: valid
    case Some{info}: WorldState.reward_on(seed,state,pid,info,plan,score,valid)

law WorldState.finish_hit_on:
  for +seed: U32
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +hit: R.Roster.Strike
  for +pid: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +ps: Walk.Locomotion.All(L.Landscape.maps(seed),players)
  for +ms: H.Habitat.All(L.Landscape.maps(seed),R.Roster.struck(hit))
  Plan.Planning.Positions<seed,B.Battle.state(B.Battle.finish_hit(meta,players,hit,pid,plan,score))>

def WorldState.finish_hit_on(seed,meta,players,hit,pid,plan,score,ps,ms):
  match hit:
    case R.Roster.Strike{monsters,kill,dealt}: WorldState.after_on(kill,seed,S.Simulation.State{meta,players,monsters},pid,plan,score,Plan.Planning.Positions{ps,ms})

law WorldState.strike_on:
  for +input: B.Battle.Input
  for +seed: U32
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +valid: Plan.Planning.Positions<seed,state>
  Plan.Planning.Positions<seed,B.Battle.state(B.Battle.strike(input,state,pid,score))>

def WorldState.strike_on(input,seed,state,pid,score,valid):
  match input:
    case B.Battle.Input{mid,damage,plan}:
      match state:
        case S.Simulation.State{meta,players,monsters}:
          match valid:
            case Plan.Planning.Positions{ps,ms}: WorldState.finish_hit_on(seed,meta,players,R.Roster.strike(monsters,mid,damage),pid,plan,score,ps,H.Habitat.strike_on(L.Landscape.maps(seed),monsters,mid,damage,ms))

law WorldState.battle_run_on:
  for +inputs: List<&2,B.Battle.Input>
  for +seed: U32
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +valid: Plan.Planning.Positions<seed,state>
  Plan.Planning.Positions<seed,B.Battle.state(B.Battle.run(inputs,state,pid,score))>

def WorldState.battle_run_on(inputs,seed,state,pid,score,valid):
  match inputs:
    case Nil{}: valid
    case Con{head,rest}: WorldState.battle_run_on(rest,seed,B.Battle.state(B.Battle.strike(head,state,pid,score)),pid,score,WorldState.strike_on(head,seed,state,pid,score,valid))

law WorldState.execute_on:
  for +seed: U32
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +admitted: C.Combat.Result
  for +inputs: List<&2,B.Battle.Input>
  for +pid: U32
  for +score: U32
  for +ps: Walk.Locomotion.All(L.Landscape.maps(seed),C.Combat.roster(admitted))
  for +ms: H.Habitat.All(L.Landscape.maps(seed),monsters)
  Plan.Planning.Positions<seed,B.Battle.state(B.Battle.execute(meta,monsters,admitted,inputs,pid,score))>

def WorldState.execute_on(seed,meta,monsters,admitted,inputs,pid,score,ps,ms):
  match admitted:
    case C.Combat.Result{players,attacker}:
      match attacker:
        case None{}: Plan.Planning.Positions{ps,ms}
        case Some{actor}: WorldState.battle_run_on(inputs,seed,S.Simulation.State{meta,players,monsters},pid,score,Plan.Planning.Positions{ps,ms})

law WorldState.command_on:
  for +kind: C.Combat.Kind
  for +seed: U32
  for +state: S.Simulation.State
  for +inputs: List<&2,B.Battle.Input>
  for +pid: U32
  for +score: U32
  for +valid: Plan.Planning.Positions<seed,state>
  Plan.Planning.Positions<seed,B.Battle.state(B.Battle.command(kind,state,inputs,pid,score))>

def WorldState.command_on(kind,seed,state,inputs,pid,score,valid):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      match valid:
        case Plan.Planning.Positions{ps,ms}:
          +admitted = C.Combat.run(players,pid,kind,S.Simulation.phase(meta))
          WorldState.execute_on(seed,meta,monsters,admitted,inputs,pid,score,WorldState.combat_conserved_on(L.Landscape.maps(seed),players,C.Combat.roster(admitted),C.Combat.run_conserves(players,pid,kind,S.Simulation.phase(meta)),ps),ms)

law WorldState.fight:
  for +kind: C.Combat.Kind
  for +seed: U32
  for +state: S.Simulation.State
  for +inputs: List<&2,B.Battle.Input>
  for +pid: U32
  for +score: U32
  for +valid: WorldState.OK<seed,state>
  WorldState.OK<seed,B.Battle.state(B.Battle.command(kind,state,inputs,pid,score))>

def WorldState.fight(kind,seed,state,inputs,pid,score,valid):
  match valid:
    case WorldState.OK{health,positions,monsters,players,nonzero,references}:
      WorldState.OK{B.Battle.command_ok(kind,state,inputs,pid,score,health),WorldState.command_on(kind,seed,state,inputs,pid,score,positions),I.Identity.command_unique(kind,state,inputs,pid,score,monsters),Id.PlayerIds.command_unique(kind,state,inputs,pid,score,players),NZ.Nonzero.command_positive(kind,state,inputs,pid,score,nonzero),Mem.Membership.command_world(kind,state,inputs,pid,score,references)}

law WorldState.remove:
  for +seed: U32
  for +state: S.Simulation.State
  for +pid: U32
  for +valid: WorldState.OK<seed,state>
  WorldState.OK<seed,Ref.References.remove_state(state,pid)>

def WorldState.remove(seed,state,pid,valid):
  match valid:
    case WorldState.OK{health,positions,monsters,players,nonzero,references}:
      WorldState.OK{Ref.References.remove_ok(state,pid,health),Ref.References.remove_positions(seed,state,pid,positions),Ref.References.remove_monster_ids(state,pid,monsters),Id.PlayerIds.remove_state_unique(state,pid,players),NZ.Nonzero.remove_state_positive(state,pid,nonzero),Ref.References.remove_valid(state,pid)}

law WorldState.commit:
  for +seed: U32
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +choice: Alloc.Allocation.Choice
  for +fresh: Alloc.Allocation.Fresh<J.Admission.pids(S.Simulation.players(state)),choice>
  for +positive: {U32.is_eq(cid,0) == False{} : Bool}
  for +available: Alloc.Allocation.Absent(cid,J.Admission.cids(S.Simulation.players(state)))
  for +valid: WorldState.OK<seed,state>
  WorldState.OK<seed,J.Admission.state(J.Admission.commit(state,cid,style,name,choice))>

def WorldState.commit(seed,state,cid,style,name,choice,fresh,positive,available,valid):
  match state:
    case S.Simulation.State{meta,roster,mobs}:
      match valid:
        case WorldState.OK{health,positions,monsters,players,nonzero,references}:
          match positions:
            case Plan.Planning.Positions{ps,ms}:
              +before = {S.Simulation.State{meta,roster,mobs} : S.Simulation.State}
              WorldState.OK{J.Admission.commit_ok(before,cid,style,name,choice,health),Plan.Planning.Positions{J.Admission.commit_on(seed,before,cid,style,name,choice,ps),ms},monsters,J.Admission.commit_unique(before,cid,style,name,choice,fresh,available,players),NZ.Nonzero.commit(before,cid,style,name,choice,fresh,positive,nonzero),Mem.Membership.commit_world(before,cid,style,name,choice,references)}

law WorldState.admitted:
  for +seed: U32
  for +before: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +result: J.Admission.Result
  for +outcome: J.Admission.Outcome<before,cid,style,name,result>
  for +valid: WorldState.OK<seed,before>
  WorldState.OK<seed,J.Admission.state(result)>

def WorldState.admitted(seed,before,cid,style,name,result,outcome,valid):
  match outcome:
    case J.Admission.Rejected{exact}:
      %Equal.sym(J.Admission.Result,result,J.Admission.Result{before,0},exact) : WorldState.OK<seed,J.Admission.state(_)>
      valid
    case J.Admission.Created{choice,exact,fresh,positive,available}:
      %Equal.sym(J.Admission.Result,result,J.Admission.commit(before,cid,style,name,choice),exact) : WorldState.OK<seed,J.Admission.state(_)>
      WorldState.commit(seed,before,cid,style,name,choice,fresh,positive,available,valid)

law WorldState.add:
  for +seed: U32
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +valid: WorldState.OK<seed,state>
  WorldState.OK<seed,J.Admission.state(J.Admission.add(state,cid,style,name))>

def WorldState.add(seed,state,cid,style,name,valid): WorldState.admitted(seed,state,cid,style,name,J.Admission.add(state,cid,style,name),J.Admission.add_outcome(state,cid,style,name),valid)

law WorldState.inventory:
  for +seed: U32
  for +state: S.Simulation.State
  for +target: U32
  for +op: G.Bq.HOp
  for +near_shop: Bool
  for +amount: U32
  for +valid: WorldState.OK<seed,state>
  WorldState.OK<seed,Id.PlayerIds.run_change(Id.PlayerIds.Inventory{target,op,near_shop,amount},state,L.Landscape.maps(seed))>

def WorldState.inventory(seed,state,target,op,near_shop,amount,valid):
  match state:
    case S.Simulation.State{meta,roster,mobs}:
      match valid:
        case WorldState.OK{health,positions,monsters,players,nonzero,references}:
          match health:
            case S.Simulation.OK{ps,ms,zs}:
              match positions:
                case Plan.Planning.Positions{pon,mon}:
                  +after = Inv.Inventory.roster(Inv.Inventory.run(roster,target,op,near_shop,amount))
                  WorldState.OK{S.Simulation.OK{Inv.Inventory.run_ok(roster,target,op,near_shop,amount,ps),ms,zs},Plan.Planning.Positions{WorldState.inventory_conserved_on(L.Landscape.maps(seed),roster,after,Inv.Inventory.run_conserves(roster,target,op,near_shop,amount),pon),mon},monsters,Id.PlayerIds.inventory_run(roster,target,op,near_shop,amount,players),NZ.Nonzero.inventory_run(roster,target,op,near_shop,amount,nonzero),Mem.Membership.related_all(mobs,roster,after,Mem.Membership.inventory_run(roster,target,op,near_shop,amount),references)}

law WorldState.interact:
  for +seed: U32
  for +state: S.Simulation.State
  for +target: U32
  for +command: Inter.Interaction.Command
  for +valid: WorldState.OK<seed,state>
  WorldState.OK<seed,Id.PlayerIds.run_change(Id.PlayerIds.Interact{target,command},state,L.Landscape.maps(seed))>

def WorldState.interact(seed,state,target,command,valid):
  match state:
    case S.Simulation.State{meta,roster,mobs}:
      match valid:
        case WorldState.OK{health,positions,monsters,players,nonzero,references}:
          match health:
            case S.Simulation.OK{ps,ms,zs}:
              match positions:
                case Plan.Planning.Positions{pon,mon}:
                  +after = Inter.Interaction.roster(Inter.Interaction.run(roster,target,command))
                  WorldState.OK{S.Simulation.OK{Inter.Interaction.run_ok(roster,target,command,ps),ms,zs},Plan.Planning.Positions{L.Landscape.run_on(seed,roster,target,command,pon),mon},monsters,Id.PlayerIds.interaction_run(roster,target,command,players),NZ.Nonzero.interaction_run(roster,target,command,nonzero),Mem.Membership.related_all(mobs,roster,after,Mem.Membership.interaction_run(roster,target,command),references)}

law WorldState.change:
  for +change: Id.PlayerIds.Change
  for +seed: U32
  for +state: S.Simulation.State
  for +command_only: Mem.Membership.Command(change)
  for +valid: WorldState.OK<seed,state>
  WorldState.OK<seed,Id.PlayerIds.run_change(change,state,L.Landscape.maps(seed))>

def WorldState.change(change,seed,state,command_only,valid):
  match change:
    case Id.PlayerIds.Create{cid,style,name}: WorldState.add(seed,state,cid,style,name,valid)
    case Id.PlayerIds.Remove{target}: WorldState.remove(seed,state,target,valid)
    case Id.PlayerIds.Inventory{target,op,near_shop,amount}: WorldState.inventory(seed,state,target,op,near_shop,amount,valid)
    case Id.PlayerIds.Interact{target,command}: WorldState.interact(seed,state,target,command,valid)
    case Id.PlayerIds.Fight{kind,inputs,pid,score}: WorldState.fight(kind,seed,state,inputs,pid,score,valid)
    case Id.PlayerIds.Tick{input,rules}: Empty.absurd(WorldState.OK<seed,Id.PlayerIds.run_change(Id.PlayerIds.Tick{input,rules},state,L.Landscape.maps(seed))>,command_only)

law WorldState.run_tick:
  for +damages: AR.AIRefs.Damages
  for +seed: U32
  for +state: S.Simulation.State
  for +timer: U32
  for +valid: WorldState.OK<seed,state>
  WorldState.OK<seed,AR.AIRefs.run_tick(damages,state,L.Landscape.maps(seed),Plan.Planning.rules(timer))>

def WorldState.run_tick(damages,seed,state,timer,valid):
  match damages:
    case AR.AIRefs.Damages{d0,d1,d2,d3}: WorldState.tick(seed,state,d0,d1,d2,d3,timer,valid)

# The server's canonical spawn coordinates are necessary for positional safety.
# Timer values and damage lists are unrestricted U32s. These are not auth claims.
def WorldState.Allowed(transition: AR.AIRefs.Transition) -> Data:
  match transition:
    case AR.AIRefs.Command{change,command_only}: Unit
    case AR.AIRefs.Ticking{damages,rules}: Sigma<&2,&2,U32,(timer => {rules == Plan.Planning.rules(timer) : S.Simulation.Rules})>

def WorldState.Schedule(transitions: List<&2,AR.AIRefs.Transition>) -> Data:
  match transitions:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,WorldState.Allowed(head),(first => WorldState.Schedule(rest))>

law WorldState.transition:
  for +transition: AR.AIRefs.Transition
  for +seed: U32
  for +state: S.Simulation.State
  for +allowed: WorldState.Allowed(transition)
  for +valid: WorldState.OK<seed,state>
  WorldState.OK<seed,AR.AIRefs.transition(transition,state,L.Landscape.maps(seed))>

def WorldState.transition(transition,seed,state,allowed,valid):
  match transition:
    case AR.AIRefs.Command{change,command_only}: WorldState.change(change,seed,state,command_only,valid)
    case AR.AIRefs.Ticking{damages,rules}:
      match allowed:
        case Tuple{timer,exact}:
          %Equal.sym(S.Simulation.Rules,rules,Plan.Planning.rules(timer),exact) : WorldState.OK<seed,AR.AIRefs.run_tick(damages,state,L.Landscape.maps(seed),_)>
          WorldState.run_tick(damages,seed,state,timer,valid)

law WorldState.trace:
  for +transitions: List<&2,AR.AIRefs.Transition>
  for +seed: U32
  for +state: S.Simulation.State
  for +schedule: WorldState.Schedule(transitions)
  for +valid: WorldState.OK<seed,state>
  WorldState.OK<seed,AR.AIRefs.trace(transitions,state,L.Landscape.maps(seed))>

def WorldState.trace(transitions,seed,state,schedule,valid):
  match transitions:
    case Nil{}: valid
    case Con{head,rest}:
      match schedule:
        case Tuple{first,later}: WorldState.trace(rest,seed,AR.AIRefs.transition(head,state,L.Landscape.maps(seed)),later,WorldState.transition(head,seed,state,first,valid))

law WorldState.fresh_trace:
  for +transitions: List<&2,AR.AIRefs.Transition>
  for +world: U32
  for +seed: U32
  for +now: U32
  for +schedule: WorldState.Schedule(transitions)
  WorldState.OK<seed,AR.AIRefs.trace(transitions,T.Terrain.simulation(Pop.Population.fresh(world,seed,now)),L.Landscape.maps(seed))>

def WorldState.fresh_trace(transitions,world,seed,now,schedule): WorldState.trace(transitions,seed,T.Terrain.simulation(Pop.Population.fresh(world,seed,now)),schedule,WorldState.fresh(world,seed,now))
