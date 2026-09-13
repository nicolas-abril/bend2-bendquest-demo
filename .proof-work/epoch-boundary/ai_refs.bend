# Valid monster targets through actual AI execution and selected world ticks.
import Base
import ./references.bend as Ref
import ./membership.bend as Mem
import ./targeting.bend as Sel
import ./players.bend as P
import ./monsters.bend as M
import ./vitals.bend as V
import ./roster.bend as R
import ./ai.bend as A
import ./pursuit.bend as Q
import ./planning.bend as Plan
import ./population.bend as Pop
import ./simulation.bend as S
import ./locomotion.bend as Walk
import ./terrain.bend as T
import ./landscape.bend as L
import ./interactions.bend as Inter
import ./navigation.bend as N
import ./playerids.bend as Id

# Rest retains the current target; Spawn creates the zero sentinel.
def AIRefs.Plan(players: List<&2,P.Players.State>,plan: A.AI.Plan) -> Data:
  match plan:
    case A.AI.Rest{}: Unit
    case A.AI.Move{x,y,target}: {Ref.References.exists(players,target) == True{} : Bool}
    case A.AI.Attack{target,damage}: {Ref.References.exists(players,target) == True{} : Bool}
    case A.AI.Spawn{kind,rare,x,y,maximum}: Unit

def AIRefs.Plans(+players: List<&2,P.Players.State>,plans: List<&2,A.AI.Plan>) -> Data:
  match plans:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,AIRefs.Plan(players,head),(valid => AIRefs.Plans(players,rest))>

law AIRefs.wait_target:
  for +monster: M.Monsters.State
  {Ref.References.target(M.Monsters.wait(monster)) == Ref.References.target(monster) : U32}

def AIRefs.wait_target(monster):
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}: {==}

law AIRefs.vitals_target:
  for +monster: M.Monsters.State
  for +vitals: V.Vitals.State
  {Ref.References.target(M.Monsters.with_vitals(monster,vitals)) == Ref.References.target(monster) : U32}

def AIRefs.vitals_target(monster,vitals):
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}:
      match vitals:
        case V.Vitals.State{hp2,xp2,dead2,respawn2,attack2,spin2}: {==}

law AIRefs.active_target:
  for +monster: M.Monsters.State
  for +amount: U32
  {Ref.References.target(M.Monsters.active(monster,amount)) == Ref.References.target(monster) : U32}

def AIRefs.active_target(monster,amount): AIRefs.vitals_target(monster,V.Vitals.live_tick(M.Monsters.vitals(monster),amount,M.Monsters.maximum(monster)))

law AIRefs.ready_target:
  for +ready: Bool
  for +monster: M.Monsters.State
  {Ref.References.target(M.Monsters.tick_state(M.Monsters.ready_tick(ready,monster))) == Ref.References.target(monster) : U32}

def AIRefs.ready_target(ready,monster):
  match ready:
    case True{}: {==}
    case False{}: AIRefs.wait_target(monster)

law AIRefs.dead_tick_target:
  for +permanent: Bool
  for +ready: Bool
  for +monster: M.Monsters.State
  {Ref.References.target(M.Monsters.tick_state(M.Monsters.dead_tick(permanent,ready,monster))) == Ref.References.target(monster) : U32}

def AIRefs.dead_tick_target(permanent,ready,monster):
  match permanent:
    case True{}: {==}
    case False{}: AIRefs.ready_target(ready,monster)

law AIRefs.tick_gate_target:
  for +dead: Bool
  for +permanent: Bool
  for +ready: Bool
  for +monster: M.Monsters.State
  for +amount: U32
  {Ref.References.target(M.Monsters.tick_state(M.Monsters.tick_gate(dead,permanent,ready,monster,amount))) == Ref.References.target(monster) : U32}

def AIRefs.tick_gate_target(dead,permanent,ready,monster,amount):
  match dead:
    case True{}: AIRefs.dead_tick_target(permanent,ready,monster)
    case False{}: AIRefs.active_target(monster,amount)

law AIRefs.tick_target:
  for +monster: M.Monsters.State
  {Ref.References.target(M.Monsters.tick_state(M.Monsters.tick(monster))) == Ref.References.target(monster) : U32}

def AIRefs.tick_target(monster):
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}:
      AIRefs.tick_gate_target(U32.is_eq(dead,1),U32.is_eq(respawn,4294967295),U32.is_le(respawn,1),M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn},M.Monsters.choose(U32.is_eq(kind,9),30,0))

law AIRefs.tick_valid:
  for +monster: M.Monsters.State
  for +players: List<&2,P.Players.State>
  for +valid: Ref.References.Valid(players,monster)
  Ref.References.Valid(players,M.Monsters.tick_state(M.Monsters.tick(monster)))

def AIRefs.tick_valid(monster,players,valid):
  %Equal.sym(U32,Ref.References.target(M.Monsters.tick_state(M.Monsters.tick(monster))),Ref.References.target(monster),AIRefs.tick_target(monster)) : {Ref.References.exists(players,_) == True{} : Bool}
  valid

law AIRefs.aim_valid:
  for +monster: M.Monsters.State
  for +x: U32
  for +y: U32
  for +target: U32
  for +attack: U32
  for +players: List<&2,P.Players.State>
  for +valid: {Ref.References.exists(players,target) == True{} : Bool}
  Ref.References.Valid(players,M.Monsters.aim(monster,x,y,target,attack))

def AIRefs.aim_valid(monster,x,y,target,attack,players,valid):
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,ox,oy,hp,maximum,old,oa,dead,respawn}: valid

law AIRefs.attack_valid:
  for +ready: Bool
  for +monster: M.Monsters.State
  for +target: U32
  for +damage: U32
  for +players: List<&2,P.Players.State>
  for +old_valid: Ref.References.Valid(players,monster)
  for +target_valid: {Ref.References.exists(players,target) == True{} : Bool}
  Ref.References.Valid(players,A.AI.monster(A.AI.attack(ready,monster,target,damage)))

def AIRefs.attack_valid(ready,monster,target,damage,players,old_valid,target_valid):
  match ready:
    case False{}: old_valid
    case True{}:
      match monster:
        case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,old,attack,dead,respawn}: target_valid

law AIRefs.active_valid:
  for +monster: M.Monsters.State
  for +plan: A.AI.Plan
  for +players: List<&2,P.Players.State>
  for +old_valid: Ref.References.Valid(players,monster)
  for +plan_valid: AIRefs.Plan(players,plan)
  Ref.References.Valid(players,A.AI.monster(A.AI.active(monster,plan)))

def AIRefs.active_valid(monster,plan,players,old_valid,plan_valid):
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}:
      match plan:
        case A.AI.Rest{}: old_valid
        case A.AI.Move{nx,ny,next_target}: plan_valid
        case A.AI.Attack{next_target,damage}: AIRefs.attack_valid(U32.is_eq(attack,0),M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn},next_target,damage,players,old_valid,plan_valid)
        case A.AI.Spawn{new_kind,new_rare,nx,ny,new_maximum}: old_valid

law AIRefs.rebirth_valid:
  for +monster: M.Monsters.State
  for +plan: A.AI.Plan
  for +players: List<&2,P.Players.State>
  for +old_valid: Ref.References.Valid(players,monster)
  Ref.References.Valid(players,A.AI.monster(A.AI.rebirth(monster,plan)))

def AIRefs.rebirth_valid(monster,plan,players,old_valid):
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}:
      match plan:
        case A.AI.Rest{}: old_valid
        case A.AI.Move{nx,ny,next_target}: old_valid
        case A.AI.Attack{next_target,damage}: old_valid
        case A.AI.Spawn{new_kind,new_rare,nx,ny,new_maximum}: Ref.References.spawn_valid(players,mid,new_kind,new_rare,zone,nx,ny,new_maximum)

law AIRefs.commit_valid:
  for +tick: M.Monsters.Tick
  for +plan: A.AI.Plan
  for +players: List<&2,P.Players.State>
  for +old_valid: Ref.References.Valid(players,M.Monsters.tick_state(tick))
  for +plan_valid: AIRefs.Plan(players,plan)
  Ref.References.Valid(players,A.AI.monster(A.AI.commit(tick,plan)))

def AIRefs.commit_valid(tick,plan,players,old_valid,plan_valid):
  match tick:
    case M.Monsters.Tick{monster,phase}:
      match phase:
        case M.Monsters.Active{}: AIRefs.active_valid(monster,plan,players,old_valid,plan_valid)
        case M.Monsters.Dormant{}: old_valid
        case M.Monsters.Rebirth{}: AIRefs.rebirth_valid(monster,plan,players,old_valid)

law AIRefs.step_valid:
  for +monster: M.Monsters.State
  for +plan: A.AI.Plan
  for +players: List<&2,P.Players.State>
  for +old_valid: Ref.References.Valid(players,monster)
  for +plan_valid: AIRefs.Plan(players,plan)
  Ref.References.Valid(players,A.AI.monster(A.AI.step(monster,plan)))

def AIRefs.step_valid(monster,plan,players,old_valid,plan_valid): AIRefs.commit_valid(M.Monsters.tick(monster),plan,players,AIRefs.tick_valid(monster,players,old_valid),plan_valid)

law AIRefs.prepend_valid:
  for +step: A.AI.Step
  for +result: A.AI.Result
  for +players: List<&2,P.Players.State>
  for +head_valid: Ref.References.Valid(players,A.AI.monster(step))
  for +rest_valid: Ref.References.All(players,A.AI.monsters(result))
  Ref.References.All(players,A.AI.monsters(A.AI.prepend(step,result)))

def AIRefs.prepend_valid(step,result,players,head_valid,rest_valid):
  match step:
    case A.AI.Step{monster,hit}:
      match result:
        case A.AI.Result{monsters,hits}: Tuple{head_valid,rest_valid}

law AIRefs.run_valid:
  for +monsters: List<&2,M.Monsters.State>
  for +plans: List<&2,A.AI.Plan>
  for +players: List<&2,P.Players.State>
  for +old_valid: Ref.References.All(players,monsters)
  for +plans_valid: AIRefs.Plans(players,plans)
  Ref.References.All(players,A.AI.monsters(A.AI.run(monsters,plans)))

def AIRefs.run_valid(monsters,plans,players,old_valid,plans_valid):
  match monsters:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match plans:
        case Nil{}:
          match old_valid:
            case Tuple{head_valid,rest_valid}: AIRefs.prepend_valid(A.AI.step(head,A.AI.Rest{}),A.AI.run(rest,Nil{}),players,AIRefs.step_valid(head,A.AI.Rest{},players,head_valid,Unit{}),AIRefs.run_valid(rest,Nil{},players,rest_valid,Unit{}))
        case Con{plan,later}:
          match old_valid:
            case Tuple{head_valid,rest_valid}:
              match plans_valid:
                case Tuple{plan_valid,remaining}: AIRefs.prepend_valid(A.AI.step(head,plan),A.AI.run(rest,later),players,AIRefs.step_valid(head,plan,players,head_valid,plan_valid),AIRefs.run_valid(rest,later,players,rest_valid,remaining))

law AIRefs.keep_valid:
  for +keep: Bool
  for +head: M.Monsters.State
  for +rest: List<&2,M.Monsters.State>
  for +players: List<&2,P.Players.State>
  for +head_valid: Ref.References.Valid(players,head)
  for +rest_valid: Ref.References.All(players,rest)
  Ref.References.All(players,R.Roster.keep(keep,head,rest))

def AIRefs.keep_valid(keep,head,rest,players,head_valid,rest_valid):
  match keep:
    case True{}: Tuple{head_valid,rest_valid}
    case False{}: rest_valid

law AIRefs.zone_valid:
  for +monsters: List<&2,M.Monsters.State>
  for +zone: U32
  for +players: List<&2,P.Players.State>
  for +valid: Ref.References.All(players,monsters)
  Ref.References.All(players,R.Roster.zone(monsters,zone))

def AIRefs.zone_valid(monsters,zone,players,valid):
  match monsters:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match valid:
        case Tuple{head_valid,rest_valid}: AIRefs.keep_valid(U32.is_eq(R.Roster.zone_of(head),zone),head,R.Roster.zone(rest,zone),players,head_valid,AIRefs.zone_valid(rest,zone,players,rest_valid))

law AIRefs.merge_valid:
  for +left: A.AI.Result
  for +right: A.AI.Result
  for +players: List<&2,P.Players.State>
  for +left_valid: Ref.References.All(players,A.AI.monsters(left))
  for +right_valid: Ref.References.All(players,A.AI.monsters(right))
  Ref.References.All(players,A.AI.monsters(A.AI.merge(left,right)))

def AIRefs.merge_valid(left,right,players,left_valid,right_valid):
  match left:
    case A.AI.Result{lm,lh}:
      match right:
        case A.AI.Result{rm,rh}: Ref.References.concat_valid(lm,rm,players,left_valid,right_valid)

law AIRefs.run_zones_valid:
  for +monsters: List<&2,M.Monsters.State>
  for +p0: List<&2,A.AI.Plan>
  for +p1: List<&2,A.AI.Plan>
  for +p2: List<&2,A.AI.Plan>
  for +p3: List<&2,A.AI.Plan>
  for +players: List<&2,P.Players.State>
  for +valid: Ref.References.All(players,monsters)
  for +v0: AIRefs.Plans(players,p0)
  for +v1: AIRefs.Plans(players,p1)
  for +v2: AIRefs.Plans(players,p2)
  for +v3: AIRefs.Plans(players,p3)
  Ref.References.All(players,A.AI.monsters(A.AI.run_zones(monsters,p0,p1,p2,p3)))

def AIRefs.run_zones_valid(monsters,p0,p1,p2,p3,players,valid,v0,v1,v2,v3):
  +r0 = A.AI.run(R.Roster.zone(monsters,0),p0)
  +r1 = A.AI.run(R.Roster.zone(monsters,1),p1)
  +r2 = A.AI.run(R.Roster.zone(monsters,2),p2)
  +r3 = A.AI.run(R.Roster.zone(monsters,3),p3)
  AIRefs.merge_valid(r0,A.AI.merge(r1,A.AI.merge(r2,r3)),players,AIRefs.run_valid(R.Roster.zone(monsters,0),p0,players,AIRefs.zone_valid(monsters,0,players,valid),v0),AIRefs.merge_valid(r1,A.AI.merge(r2,r3),players,AIRefs.run_valid(R.Roster.zone(monsters,1),p1,players,AIRefs.zone_valid(monsters,1,players,valid),v1),AIRefs.merge_valid(r2,r3,players,AIRefs.run_valid(R.Roster.zone(monsters,2),p2,players,AIRefs.zone_valid(monsters,2,players,valid),v2),AIRefs.run_valid(R.Roster.zone(monsters,3),p3,players,AIRefs.zone_valid(monsters,3,players,valid),v3))))

law AIRefs.move_plan:
  for +pos: P.Players.Pos
  for +target: U32
  for +players: List<&2,P.Players.State>
  for +valid: {Ref.References.exists(players,target) == True{} : Bool}
  AIRefs.Plan(players,Q.Pursuit.move(pos,target))

def AIRefs.move_plan(pos,target,players,valid):
  match pos:
    case P.Players.Pos{zone,x,y,dir,moving}: valid

law AIRefs.wander_plan:
  for +go: Bool
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  for +heading: U32
  for +players: List<&2,P.Players.State>
  AIRefs.Plan(players,Q.Pursuit.wander(go,maps,pos,heading))

def AIRefs.wander_plan(go,maps,pos,heading,players):
  match go:
    case False{}: AIRefs.move_plan(pos,0,players,{==})
    case True{}: AIRefs.move_plan(Q.Pursuit.walk(maps,pos,heading),0,players,{==})

law AIRefs.chase_plan:
  for +go: Bool
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  for +target: U32
  for +x: U32
  for +y: U32
  for +players: List<&2,P.Players.State>
  for +valid: {Ref.References.exists(players,target) == True{} : Bool}
  AIRefs.Plan(players,Q.Pursuit.chase(go,maps,pos,target,x,y))

def AIRefs.chase_plan(go,maps,pos,target,x,y,players,valid):
  match go:
    case False{}: AIRefs.move_plan(pos,target,players,valid)
    case True{}: AIRefs.move_plan(Q.Pursuit.toward(maps,pos,x,y),target,players,valid)

law AIRefs.attack_plan:
  for +ready: Bool
  for +pos: P.Players.Pos
  for +target: U32
  for +damage: U32
  for +players: List<&2,P.Players.State>
  for +valid: {Ref.References.exists(players,target) == True{} : Bool}
  AIRefs.Plan(players,Q.Pursuit.attack(ready,pos,target,damage))

def AIRefs.attack_plan(ready,pos,target,damage,players,valid):
  match ready:
    case False{}: AIRefs.move_plan(pos,target,players,valid)
    case True{}: valid

law AIRefs.adjacent_plan:
  for +near: Bool
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  for +target: U32
  for +x: U32
  for +y: U32
  for +tick: U32
  for +mid: U32
  for +attack: U32
  for +damage: U32
  for +players: List<&2,P.Players.State>
  for +valid: {Ref.References.exists(players,target) == True{} : Bool}
  AIRefs.Plan(players,Q.Pursuit.adjacent(near,maps,pos,target,x,y,tick,mid,attack,damage))

def AIRefs.adjacent_plan(near,maps,pos,target,x,y,tick,mid,attack,damage,players,valid):
  match near:
    case True{}: AIRefs.attack_plan(U32.is_eq(attack,0),pos,target,damage,players,valid)
    case False{}: AIRefs.chase_plan(U32.is_eq(U32.and(U32.add(tick,mid),1),0),maps,pos,target,x,y,players,valid)

law AIRefs.target_plan:
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  for +target: Q.Pursuit.Target
  for +tick: U32
  for +mid: U32
  for +attack: U32
  for +damage: U32
  for +players: List<&2,P.Players.State>
  for +valid: {Ref.References.exists(players,Sel.Targeting.target_id(target)) == True{} : Bool}
  AIRefs.Plan(players,Q.Pursuit.target(maps,pos,target,tick,mid,attack,damage))

def AIRefs.target_plan(maps,pos,target,tick,mid,attack,damage,players,valid):
  match target:
    case Q.Pursuit.Target{pid,x,y,present}:
      match present:
        case False{}: AIRefs.wander_plan(U32.is_eq(U32.and(U32.add(tick,mid),7),0),maps,pos,U32.and(L.Landscape.hash(tick,U32.mul(mid,5)),3),players)
        case True{}: AIRefs.adjacent_plan(Bool.and(U32.is_le(Inter.Interaction.distance(N.Navigation.x(pos),x),1),U32.is_le(Inter.Interaction.distance(N.Navigation.y(pos),y),1)),maps,pos,pid,x,y,tick,mid,attack,damage,players,valid)

law AIRefs.pursuit_plan:
  for +maps: T.Terrain.Maps
  for +monster: M.Monsters.State
  for +target: Q.Pursuit.Target
  for +tick: U32
  for +damage: U32
  for +players: List<&2,P.Players.State>
  for +valid: {Ref.References.exists(players,Sel.Targeting.target_id(target)) == True{} : Bool}
  AIRefs.Plan(players,Q.Pursuit.plan(maps,monster,target,tick,damage))

def AIRefs.pursuit_plan(maps,monster,target,tick,damage,players,valid):
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,old,attack,dead,respawn}: AIRefs.target_plan(maps,P.Players.Pos{zone,x,y,0,0},target,tick,mid,attack,damage,players,valid)

law AIRefs.spawn_plan:
  for +monster: M.Monsters.State
  for +players: List<&2,P.Players.State>
  AIRefs.Plan(players,Pop.Population.spawn_plan(monster))

def AIRefs.spawn_plan(monster,players):
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}: Unit{}

law AIRefs.rebirth_plan:
  for +maps: T.Terrain.Maps
  for +monster: M.Monsters.State
  for +tick: U32
  for +players: List<&2,P.Players.State>
  AIRefs.Plan(players,Pop.Population.rebirth(maps,monster,tick))

def AIRefs.rebirth_plan(maps,monster,tick,players):
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}:
      +new_rare = L.Landscape.pick(U32.is_lt(U32.mod(L.Landscape.hash(tick,U32.add(U32.mul(mid,3),1)),100),Pop.Population.rare_pct),1,0)
      AIRefs.spawn_plan(Pop.Population.monster(maps,mid,zone,L.Landscape.hash(tick,mid),new_rare),players)

def AIRefs.Context(players: List<&2,P.Players.State>,context: Plan.Planning.Context) -> Data:
  {Ref.References.exists(players,Sel.Targeting.target_id(Sel.Targeting.context_target(context))) == True{} : Bool}

def AIRefs.Contexts(+players: List<&2,P.Players.State>,contexts: List<&2,Plan.Planning.Context>) -> Data:
  match contexts:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,AIRefs.Context(players,head),(valid => AIRefs.Contexts(players,rest))>

law AIRefs.selected_contexts:
  for +contexts: List<&2,Plan.Planning.Context>
  for +players: List<&2,P.Players.State>
  for +zone: U32
  for +selected: Sel.Targeting.Contexts(players,zone,contexts)
  AIRefs.Contexts(players,contexts)

def AIRefs.selected_contexts(contexts,players,zone,selected):
  match contexts:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match selected:
        case Tuple{source,remaining}: Tuple{Sel.Targeting.selected_exists(players,zone,Sel.Targeting.context_target(head),source),AIRefs.selected_contexts(rest,players,zone,remaining)}

law AIRefs.tick_plan:
  for +result: M.Monsters.Tick
  for +maps: T.Terrain.Maps
  for +context: Plan.Planning.Context
  for +tick: U32
  for +players: List<&2,P.Players.State>
  for +valid: AIRefs.Context(players,context)
  AIRefs.Plan(players,Plan.Planning.tick_plan(result,maps,context,tick))

def AIRefs.tick_plan(result,maps,context,tick,players,valid):
  match result:
    case M.Monsters.Tick{monster,phase}:
      match phase:
        case M.Monsters.Dormant{}: Unit{}
        case M.Monsters.Rebirth{}: AIRefs.rebirth_plan(maps,monster,tick,players)
        case M.Monsters.Active{}:
          match context:
            case Plan.Planning.Context{target,damage}: AIRefs.pursuit_plan(maps,monster,target,tick,damage,players,valid)

law AIRefs.plan:
  for +monster: M.Monsters.State
  for +maps: T.Terrain.Maps
  for +context: Plan.Planning.Context
  for +tick: U32
  for +players: List<&2,P.Players.State>
  for +valid: AIRefs.Context(players,context)
  AIRefs.Plan(players,Plan.Planning.plan(monster,maps,context,tick))

def AIRefs.plan(monster,maps,context,tick,players,valid): AIRefs.tick_plan(M.Monsters.tick(monster),maps,context,tick,players,valid)

law AIRefs.plans:
  for +monsters: List<&2,M.Monsters.State>
  for +contexts: List<&2,Plan.Planning.Context>
  for +maps: T.Terrain.Maps
  for +tick: U32
  for +players: List<&2,P.Players.State>
  for +valid: AIRefs.Contexts(players,contexts)
  AIRefs.Plans(players,Plan.Planning.plans(monsters,contexts,maps,tick))

def AIRefs.plans(monsters,contexts,maps,tick,players,valid):
  match monsters:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match contexts:
        case Nil{}: Tuple{AIRefs.plan(head,maps,Plan.Planning.idle,tick,players,{==}),AIRefs.plans(rest,Nil{},maps,tick,players,Unit{})}
        case Con{context,later}:
          match valid:
            case Tuple{head_valid,remaining}: Tuple{AIRefs.plan(head,maps,context,tick,players,head_valid),AIRefs.plans(rest,later,maps,tick,players,remaining)}

# References are checked against the post-upkeep roster before AI runs.
def AIRefs.Prepared(+prepared: S.Simulation.Prepared) -> Data:
  Ref.References.All(P.Players.roster(S.Simulation.prepared_upkeep(prepared)),S.Simulation.prepared_monsters(prepared))

law AIRefs.finish_active_valid:
  for +meta: S.Simulation.Meta
  for +upkeep: P.Players.Result
  for +ai: A.AI.Result
  for +timer: U32
  for +valid: Ref.References.All(P.Players.roster(upkeep),A.AI.monsters(ai))
  Mem.Membership.World(S.Simulation.state(S.Simulation.finish_active(meta,upkeep,ai,timer)))

def AIRefs.finish_active_valid(meta,upkeep,ai,timer,valid):
  +players = P.Players.roster(upkeep)
  +hits = S.Simulation.attacks(S.Simulation.ai_hits(ai))
  Mem.Membership.related_all(A.AI.monsters(ai),players,P.Players.roster(P.Players.apply_hits(hits,players,timer)),Mem.Membership.apply_hits(hits,players,timer),valid)

law AIRefs.finish_valid:
  for +prepared: S.Simulation.Prepared
  for +p0: List<&2,A.AI.Plan>
  for +p1: List<&2,A.AI.Plan>
  for +p2: List<&2,A.AI.Plan>
  for +p3: List<&2,A.AI.Plan>
  for +rules: S.Simulation.Rules
  for +valid: AIRefs.Prepared(prepared)
  for +v0: AIRefs.Plans(P.Players.roster(S.Simulation.prepared_upkeep(prepared)),p0)
  for +v1: AIRefs.Plans(P.Players.roster(S.Simulation.prepared_upkeep(prepared)),p1)
  for +v2: AIRefs.Plans(P.Players.roster(S.Simulation.prepared_upkeep(prepared)),p2)
  for +v3: AIRefs.Plans(P.Players.roster(S.Simulation.prepared_upkeep(prepared)),p3)
  Mem.Membership.World(S.Simulation.state(S.Simulation.finish(prepared,p0,p1,p2,p3,rules)))

def AIRefs.finish_valid(prepared,p0,p1,p2,p3,rules,valid,v0,v1,v2,v3):
  match prepared:
    case S.Simulation.Prepared{meta,monsters,upkeep,running}:
      match running:
        case False{}: valid
        case True{}:
          match rules:
            case S.Simulation.Rules{spawn_x,spawn_y,timer}: AIRefs.finish_active_valid(meta,upkeep,A.AI.run_zones(monsters,p0,p1,p2,p3),timer,AIRefs.run_zones_valid(monsters,p0,p1,p2,p3,P.Players.roster(upkeep),valid,v0,v1,v2,v3))

law AIRefs.planned_finish_valid:
  for +prepared: S.Simulation.Prepared
  for +maps: T.Terrain.Maps
  for +c0: List<&2,Plan.Planning.Context>
  for +c1: List<&2,Plan.Planning.Context>
  for +c2: List<&2,Plan.Planning.Context>
  for +c3: List<&2,Plan.Planning.Context>
  for +rules: S.Simulation.Rules
  for +valid: AIRefs.Prepared(prepared)
  for +v0: AIRefs.Contexts(P.Players.roster(S.Simulation.prepared_upkeep(prepared)),c0)
  for +v1: AIRefs.Contexts(P.Players.roster(S.Simulation.prepared_upkeep(prepared)),c1)
  for +v2: AIRefs.Contexts(P.Players.roster(S.Simulation.prepared_upkeep(prepared)),c2)
  for +v3: AIRefs.Contexts(P.Players.roster(S.Simulation.prepared_upkeep(prepared)),c3)
  Mem.Membership.World(S.Simulation.state(Plan.Planning.finish(prepared,maps,c0,c1,c2,c3,rules)))

def AIRefs.planned_finish_valid(prepared,maps,c0,c1,c2,c3,rules,valid,v0,v1,v2,v3):
  match prepared:
    case S.Simulation.Prepared{meta,monsters,upkeep,running}:
      match running:
        case False{}: valid
        case True{}:
          +tick = S.Simulation.clock(meta)
          +players = P.Players.roster(upkeep)
          +p0 = Plan.Planning.plans(R.Roster.zone(monsters,0),c0,maps,tick)
          +p1 = Plan.Planning.plans(R.Roster.zone(monsters,1),c1,maps,tick)
          +p2 = Plan.Planning.plans(R.Roster.zone(monsters,2),c2,maps,tick)
          +p3 = Plan.Planning.plans(R.Roster.zone(monsters,3),c3,maps,tick)
          AIRefs.finish_valid(S.Simulation.Prepared{meta,monsters,upkeep,True{}},p0,p1,p2,p3,rules,valid,AIRefs.plans(R.Roster.zone(monsters,0),c0,maps,tick,players,v0),AIRefs.plans(R.Roster.zone(monsters,1),c1,maps,tick,players,v1),AIRefs.plans(R.Roster.zone(monsters,2),c2,maps,tick,players,v2),AIRefs.plans(R.Roster.zone(monsters,3),c3,maps,tick,players,v3))

law AIRefs.begin_gate_valid:
  for +running: Bool
  for +state: S.Simulation.State
  for +plans: List<&2,P.Players.Plan>
  for +rules: S.Simulation.Rules
  for +valid: Mem.Membership.World(state)
  AIRefs.Prepared(S.Simulation.begin_gate(running,state,plans,rules))

def AIRefs.begin_gate_valid(running,state,plans,rules,valid):
  match running:
    case False{}:
      match state:
        case S.Simulation.State{meta,players,monsters}: valid
    case True{}:
      match state:
        case S.Simulation.State{meta,players,monsters}:
          match rules:
            case S.Simulation.Rules{spawn_x,spawn_y,timer}:
              +tick = S.Simulation.clock(meta)
              Mem.Membership.related_all(monsters,players,P.Players.roster(P.Players.upkeep_all(players,plans,tick,spawn_x,spawn_y)),Mem.Membership.upkeep(players,plans,tick,spawn_x,spawn_y),valid)

law AIRefs.begin_valid:
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  for +valid: Mem.Membership.World(state)
  AIRefs.Prepared(Walk.Locomotion.begin(state,maps,rules))

def AIRefs.begin_valid(state,maps,rules,valid):
  +running = U32.is_eq(S.Simulation.phase(S.Simulation.meta(state)),1)
  AIRefs.begin_gate_valid(running,state,Walk.Locomotion.tick_plans(running,S.Simulation.players(state),maps),rules,valid)

# The authoritative finish computes its own contexts from the current roster.
# Catalog damage is supplied independently, as in the existing server.
def AIRefs.contexts(monsters: List<&2,M.Monsters.State>,players: List<&2,P.Players.State>,+zone: U32,damages: List<&2,U32>) -> List<&2,Plan.Planning.Context>:
  Sel.Targeting.contexts(R.Roster.zone(monsters,zone),Sel.Targeting.filter(players,zone),damages)

law AIRefs.contexts_valid:
  for +monsters: List<&2,M.Monsters.State>
  for +players: List<&2,P.Players.State>
  for +zone: U32
  for +damages: List<&2,U32>
  AIRefs.Contexts(players,AIRefs.contexts(monsters,players,zone,damages))

def AIRefs.contexts_valid(monsters,players,zone,damages): AIRefs.selected_contexts(AIRefs.contexts(monsters,players,zone,damages),players,zone,Sel.Targeting.filtered_contexts(R.Roster.zone(monsters,zone),players,zone,damages))

def AIRefs.finish(prepared: S.Simulation.Prepared,+maps: T.Terrain.Maps,d0: List<&2,U32>,d1: List<&2,U32>,d2: List<&2,U32>,d3: List<&2,U32>,rules: S.Simulation.Rules) -> S.Simulation.Result:
  match prepared:
    case S.Simulation.Prepared{meta,monsters,upkeep,running}:
      match running:
        case False{}: Plan.Planning.finish(S.Simulation.Prepared{meta,monsters,upkeep,False{}},maps,Nil{},Nil{},Nil{},Nil{},rules)
        case True{}:
          +meta = meta
          +monsters = monsters
          +upkeep = upkeep
          +players = P.Players.roster(upkeep)
          c0 c1 c2 c3 = AIRefs.contexts(monsters,players,0,d0) AIRefs.contexts(monsters,players,1,d1) AIRefs.contexts(monsters,players,2,d2) AIRefs.contexts(monsters,players,3,d3)
          Plan.Planning.finish(S.Simulation.Prepared{meta,monsters,upkeep,True{}},maps,c0,c1,c2,c3,rules)

law AIRefs.selected_finish_valid:
  for +prepared: S.Simulation.Prepared
  for +maps: T.Terrain.Maps
  for +d0: List<&2,U32>
  for +d1: List<&2,U32>
  for +d2: List<&2,U32>
  for +d3: List<&2,U32>
  for +rules: S.Simulation.Rules
  for +valid: AIRefs.Prepared(prepared)
  Mem.Membership.World(S.Simulation.state(AIRefs.finish(prepared,maps,d0,d1,d2,d3,rules)))

def AIRefs.selected_finish_valid(prepared,maps,d0,d1,d2,d3,rules,valid):
  match prepared:
    case S.Simulation.Prepared{meta,monsters,upkeep,running}:
      match running:
        case False{}: valid
        case True{}:
          +players = P.Players.roster(upkeep)
          AIRefs.planned_finish_valid(S.Simulation.Prepared{meta,monsters,upkeep,True{}},maps,AIRefs.contexts(monsters,players,0,d0),AIRefs.contexts(monsters,players,1,d1),AIRefs.contexts(monsters,players,2,d2),AIRefs.contexts(monsters,players,3,d3),rules,valid,AIRefs.contexts_valid(monsters,players,0,d0),AIRefs.contexts_valid(monsters,players,1,d1),AIRefs.contexts_valid(monsters,players,2,d2),AIRefs.contexts_valid(monsters,players,3,d3))

def AIRefs.tick(state: S.Simulation.State,+maps: T.Terrain.Maps,d0: List<&2,U32>,d1: List<&2,U32>,d2: List<&2,U32>,d3: List<&2,U32>,+rules: S.Simulation.Rules) -> S.Simulation.Result:
  AIRefs.finish(Walk.Locomotion.begin(state,maps,rules),maps,d0,d1,d2,d3,rules)

law AIRefs.tick_valid_world:
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +d0: List<&2,U32>
  for +d1: List<&2,U32>
  for +d2: List<&2,U32>
  for +d3: List<&2,U32>
  for +rules: S.Simulation.Rules
  for +valid: Mem.Membership.World(state)
  Mem.Membership.World(S.Simulation.state(AIRefs.tick(state,maps,d0,d1,d2,d3,rules)))

def AIRefs.tick_valid_world(state,maps,d0,d1,d2,d3,rules,valid): AIRefs.selected_finish_valid(Walk.Locomotion.begin(state,maps,rules),maps,d0,d1,d2,d3,rules,AIRefs.begin_valid(state,maps,rules,valid))

# Tick inputs contain damage amounts, never unchecked target IDs or coordinates.
type AIRefs.Damages is Data:
  AIRefs.Damages{zone0: List<&2,U32>,zone1: List<&2,U32>,zone2: List<&2,U32>,zone3: List<&2,U32>}

def AIRefs.run_tick(damages: AIRefs.Damages,state: S.Simulation.State,maps: T.Terrain.Maps,rules: S.Simulation.Rules) -> S.Simulation.State:
  match damages:
    case AIRefs.Damages{d0,d1,d2,d3}: S.Simulation.state(AIRefs.tick(state,maps,d0,d1,d2,d3,rules))

law AIRefs.run_tick_valid:
  for +damages: AIRefs.Damages
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  for +valid: Mem.Membership.World(state)
  Mem.Membership.World(AIRefs.run_tick(damages,state,maps,rules))

def AIRefs.run_tick_valid(damages,state,maps,rules,valid):
  match damages:
    case AIRefs.Damages{d0,d1,d2,d3}: AIRefs.tick_valid_world(state,maps,d0,d1,d2,d3,rules,valid)

def AIRefs.tick_trace(inputs: List<&2,AIRefs.Damages>,state: S.Simulation.State,+maps: T.Terrain.Maps,+rules: S.Simulation.Rules) -> S.Simulation.State:
  match inputs:
    case Nil{}: state
    case Con{head,rest}: AIRefs.tick_trace(rest,AIRefs.run_tick(head,state,maps,rules),maps,rules)

law AIRefs.tick_trace_valid:
  for +inputs: List<&2,AIRefs.Damages>
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  for +valid: Mem.Membership.World(state)
  Mem.Membership.World(AIRefs.tick_trace(inputs,state,maps,rules))

def AIRefs.tick_trace_valid(inputs,state,maps,rules,valid):
  match inputs:
    case Nil{}: valid
    case Con{head,rest}: AIRefs.tick_trace_valid(rest,AIRefs.run_tick(head,state,maps,rules),maps,rules,AIRefs.run_tick_valid(head,state,maps,rules,valid))

# This trace admits all command cases and the actual selected tick. The witness
# classifies commands; it is not authentication or player-action authorization.
type AIRefs.Transition is Data:
  AIRefs.Command{change: Id.PlayerIds.Change,command_only: Mem.Membership.Command(change)}
  AIRefs.Ticking{damages: AIRefs.Damages,rules: S.Simulation.Rules}

def AIRefs.transition(transition: AIRefs.Transition,state: S.Simulation.State,maps: T.Terrain.Maps) -> S.Simulation.State:
  match transition:
    case AIRefs.Command{change,command_only}: Id.PlayerIds.run_change(change,state,maps)
    case AIRefs.Ticking{damages,rules}: AIRefs.run_tick(damages,state,maps,rules)

law AIRefs.transition_valid:
  for +transition: AIRefs.Transition
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +valid: Mem.Membership.World(state)
  Mem.Membership.World(AIRefs.transition(transition,state,maps))

def AIRefs.transition_valid(transition,state,maps,valid):
  match transition:
    case AIRefs.Command{change,command_only}: Mem.Membership.change_world(change,state,maps,command_only,valid)
    case AIRefs.Ticking{damages,rules}: AIRefs.run_tick_valid(damages,state,maps,rules,valid)

def AIRefs.trace(transitions: List<&2,AIRefs.Transition>,state: S.Simulation.State,+maps: T.Terrain.Maps) -> S.Simulation.State:
  match transitions:
    case Nil{}: state
    case Con{head,rest}: AIRefs.trace(rest,AIRefs.transition(head,state,maps),maps)

law AIRefs.trace_valid:
  for +transitions: List<&2,AIRefs.Transition>
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +valid: Mem.Membership.World(state)
  Mem.Membership.World(AIRefs.trace(transitions,state,maps))

def AIRefs.trace_valid(transitions,state,maps,valid):
  match transitions:
    case Nil{}: valid
    case Con{head,rest}: AIRefs.trace_valid(rest,AIRefs.transition(head,state,maps),maps,AIRefs.transition_valid(head,state,maps,valid))

law AIRefs.fresh_trace_valid:
  for +transitions: List<&2,AIRefs.Transition>
  for +world: U32
  for +seed: U32
  for +now: U32
  Mem.Membership.World(AIRefs.trace(transitions,T.Terrain.simulation(Pop.Population.fresh(world,seed,now)),L.Landscape.maps(seed)))

def AIRefs.fresh_trace_valid(transitions,world,seed,now): AIRefs.trace_valid(transitions,T.Terrain.simulation(Pop.Population.fresh(world,seed,now)),L.Landscape.maps(seed),Ref.References.fresh_valid(world,seed,now))
