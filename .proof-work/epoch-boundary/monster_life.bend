# Actual monster lifetime boundaries through tick, AI commit and ordered rosters.
import Base
import ./monsters.bend as M
import ./vitals.bend as V
import ./ai.bend as A
import ./zones.bend as Z
import ./roster.bend as R
import ./combat_targets.bend as Targets
import ./numeric.bend as N
import ./identity.bend as I

def Life.spawn_plan(plan: A.AI.Plan) -> Bool:
  match plan:
    case A.AI.Rest{}: False{}
    case A.AI.Move{x,y,target}: False{}
    case A.AI.Attack{target,damage}: False{}
    case A.AI.Spawn{kind,rare,x,y,maximum}: True{}

# The marker observes the same tick phase and plan that AI.commit executes.
def Life.event(tick: M.Monsters.Tick,plan: A.AI.Plan) -> Bool:
  match tick:
    case M.Monsters.Tick{monster,phase}:
      match phase:
        case M.Monsters.Active{}: False{}
        case M.Monsters.Dormant{}: False{}
        case M.Monsters.Rebirth{}: Life.spawn_plan(plan)

def Life.reborn(+monster: M.Monsters.State,plan: A.AI.Plan) -> Bool: Life.event(M.Monsters.tick(monster),plan)

law Life.wait_dead:
  for +monster: M.Monsters.State
  {V.Vitals.dead(M.Monsters.vitals(M.Monsters.wait(monster))) == V.Vitals.dead(M.Monsters.vitals(monster)) : U32}

def Life.wait_dead(monster):
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}: {==}

law Life.spawn_positive_dead:
  for +value: Nat
  for +mid: U32
  for +kind: U32
  for +rare: U32
  for +zone: U32
  for +x: U32
  for +y: U32
  for +maximum: U32
  {V.Vitals.dead(M.Monsters.vitals(M.Monsters.spawn_positive(value,mid,kind,rare,zone,x,y,maximum))) == 0 : U32}

def Life.spawn_positive_dead(value,mid,kind,rare,zone,x,y,maximum):
  match value:
    case Zero{}: {==}
    case Succ{rest}: {==}

law Life.spawn_dead:
  for +mid: U32
  for +kind: U32
  for +rare: U32
  for +zone: U32
  for +x: U32
  for +y: U32
  for +maximum: U32
  {V.Vitals.dead(M.Monsters.vitals(M.Monsters.spawn(mid,kind,rare,zone,x,y,maximum))) == 0 : U32}

def Life.spawn_dead(mid,kind,rare,zone,x,y,maximum): Life.spawn_positive_dead(U32.to_nat(maximum),mid,kind,rare,zone,x,y,maximum)

law Life.rebirth_dead:
  for +monster: M.Monsters.State
  for +plan: A.AI.Plan
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  {V.Vitals.dead(M.Monsters.vitals(A.AI.monster(A.AI.rebirth(monster,plan)))) == Targets.Targets.pick(Life.spawn_plan(plan),0,1) : U32}

def Life.rebirth_dead(monster,plan,dead):
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,flag,respawn}:
      match plan:
        case A.AI.Rest{}: dead
        case A.AI.Move{nx,ny,next_target}: dead
        case A.AI.Attack{next_target,damage}: dead
        case A.AI.Spawn{new_kind,new_rare,nx,ny,new_maximum}: Life.spawn_dead(mid,new_kind,new_rare,zone,nx,ny,new_maximum)

law Life.dead_tick:
  for +permanent: Bool
  for +ready: Bool
  for +monster: M.Monsters.State
  for +plan: A.AI.Plan
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  {V.Vitals.dead(M.Monsters.vitals(A.AI.monster(A.AI.commit(M.Monsters.dead_tick(permanent,ready,monster),plan)))) == Targets.Targets.pick(Life.event(M.Monsters.dead_tick(permanent,ready,monster),plan),0,1) : U32}

def Life.dead_tick(permanent,ready,monster,plan,dead):
  match permanent:
    case True{}: dead
    case False{}:
      match ready:
        case True{}: Life.rebirth_dead(monster,plan,dead)
        case False{}: Equal.trans(U32,V.Vitals.dead(M.Monsters.vitals(M.Monsters.wait(monster))),V.Vitals.dead(M.Monsters.vitals(monster)),1,Life.wait_dead(monster),dead)

law Life.step_dead:
  for +monster: M.Monsters.State
  for +plan: A.AI.Plan
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  {V.Vitals.dead(M.Monsters.vitals(A.AI.monster(A.AI.step(monster,plan)))) == Targets.Targets.pick(Life.reborn(monster,plan),0,1) : U32}

def Life.step_dead(monster,plan,dead):
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,flag,respawn}:
      %Equal.sym(U32,flag,1,dead) : {V.Vitals.dead(M.Monsters.vitals(A.AI.monster(A.AI.step(M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,_,respawn},plan)))) == Targets.Targets.pick(Life.reborn(M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,_,respawn},plan),0,1) : U32}
      Life.dead_tick(U32.is_eq(respawn,4294967295),U32.is_le(respawn,1),M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,1,respawn},plan,{==})

# Rebirth phase alone is insufficient: the committed plan must be Spawn.
def Life.SpawnPlan(plan: A.AI.Plan) -> Data:
  match plan:
    case A.AI.Rest{}: Empty
    case A.AI.Move{x,y,target}: Empty
    case A.AI.Attack{target,damage}: Empty
    case A.AI.Spawn{kind,rare,x,y,maximum}: Unit

law Life.plan_event:
  for +plan: A.AI.Plan
  for +event: {Life.spawn_plan(plan) == True{} : Bool}
  Life.SpawnPlan(plan)

def Life.plan_event(plan,event):
  match plan:
    case A.AI.Rest{}: N.Numeric.true_ne_false(Equal.sym(Bool,False{},True{},event))
    case A.AI.Move{x,y,target}: N.Numeric.true_ne_false(Equal.sym(Bool,False{},True{},event))
    case A.AI.Attack{target,damage}: N.Numeric.true_ne_false(Equal.sym(Bool,False{},True{},event))
    case A.AI.Spawn{kind,rare,x,y,maximum}: Unit{}

law Life.event_spawn:
  for +tick: M.Monsters.Tick
  for +plan: A.AI.Plan
  for +event: {Life.event(tick,plan) == True{} : Bool}
  Life.SpawnPlan(plan)

def Life.event_spawn(tick,plan,event):
  match tick:
    case M.Monsters.Tick{monster,phase}:
      match phase:
        case M.Monsters.Active{}: Empty.absurd(Life.SpawnPlan(plan),N.Numeric.true_ne_false(Equal.sym(Bool,False{},True{},event)))
        case M.Monsters.Dormant{}: Empty.absurd(Life.SpawnPlan(plan),N.Numeric.true_ne_false(Equal.sym(Bool,False{},True{},event)))
        case M.Monsters.Rebirth{}: Life.plan_event(plan,event)

# A certificate refers to the entire actual AI output, not an assumed post-state.
type Life.Certificate<-monster: M.Monsters.State,-plan: A.AI.Plan> is Data:
  Life.Certificate{actual: A.AI.Step,same: {actual == A.AI.step(monster,plan) : A.AI.Step},key: {Z.Zones.key(A.AI.monster(actual)) == Z.Zones.key(monster) : Z.Zones.Key},quiet: {A.AI.hit(actual) == None{} : Maybe<&2,A.AI.Hit>},dead: {V.Vitals.dead(M.Monsters.vitals(A.AI.monster(actual))) == Targets.Targets.pick(Life.reborn(monster,plan),0,1) : U32}}

law Life.classify:
  for +monster: M.Monsters.State
  for +plan: A.AI.Plan
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  Life.Certificate<monster,plan>

def Life.classify(monster,plan,dead): Life.Certificate{A.AI.step(monster,plan),{==},Z.Zones.step_key(monster,plan),A.AI.dead_step_no_hit(monster,plan,dead),Life.step_dead(monster,plan,dead)}

law Life.no_event_dead:
  for +monster: M.Monsters.State
  for +plan: A.AI.Plan
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  for +none: {Life.reborn(monster,plan) == False{} : Bool}
  {V.Vitals.dead(M.Monsters.vitals(A.AI.monster(A.AI.step(monster,plan)))) == 1 : U32}

def Life.no_event_dead(monster,plan,dead,none):
  %none : {V.Vitals.dead(M.Monsters.vitals(A.AI.monster(A.AI.step(monster,plan)))) == Targets.Targets.pick(_,0,1) : U32}
  Life.step_dead(monster,plan,dead)

law Life.event_alive:
  for +monster: M.Monsters.State
  for +plan: A.AI.Plan
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  for +event: {Life.reborn(monster,plan) == True{} : Bool}
  {V.Vitals.dead(M.Monsters.vitals(A.AI.monster(A.AI.step(monster,plan)))) == 0 : U32}

def Life.event_alive(monster,plan,dead,event):
  %event : {V.Vitals.dead(M.Monsters.vitals(A.AI.monster(A.AI.step(monster,plan)))) == Targets.Targets.pick(_,0,1) : U32}
  Life.step_dead(monster,plan,dead)

law Life.gate_event:
  for +permanent: Bool
  for +ready: Bool
  for +monster: M.Monsters.State
  for +plan: A.AI.Plan
  {Life.event(M.Monsters.dead_tick(permanent,ready,monster),plan) == Bool.and(Bool.not(permanent),Bool.and(ready,Life.spawn_plan(plan))) : Bool}

def Life.gate_event(permanent,ready,monster,plan):
  match permanent:
    case True{}: {==}
    case False{}:
      match ready:
        case True{}: {==}
        case False{}: {==}

law Life.boundary:
  for +monster: M.Monsters.State
  for +plan: A.AI.Plan
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  {Life.reborn(monster,plan) == Bool.and(Bool.not(U32.is_eq(M.Monsters.timer(monster),4294967295)),Bool.and(U32.is_le(M.Monsters.timer(monster),1),Life.spawn_plan(plan))) : Bool}

def Life.boundary(monster,plan,dead):
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,flag,respawn}:
      %Equal.sym(U32,flag,1,dead) : {Life.reborn(M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,_,respawn},plan) == Bool.and(Bool.not(U32.is_eq(respawn,4294967295)),Bool.and(U32.is_le(respawn,1),Life.spawn_plan(plan))) : Bool}
      Life.gate_event(U32.is_eq(respawn,4294967295),U32.is_le(respawn,1),M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,1,respawn},plan)

law Life.permanent_event:
  for +monster: M.Monsters.State
  for +plan: A.AI.Plan
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  for +permanent: {M.Monsters.timer(monster) == 4294967295 : U32}
  {Life.reborn(monster,plan) == False{} : Bool}

def Life.permanent_event(monster,plan,dead,permanent):
  %Equal.sym(M.Monsters.Tick,M.Monsters.tick(monster),M.Monsters.Tick{monster,M.Monsters.Dormant{}},M.Monsters.permanent_death_stays(monster,dead,permanent)) : {Life.event(_,plan) == False{} : Bool}
  {==}

# Match AI.run's exact plan position, including missing-plan Rest defaults.
def Life.first_plan(plans: List<&2,A.AI.Plan>) -> A.AI.Plan:
  match plans:
    case Nil{}: A.AI.Rest{}
    case Con{head,rest}: head

def Life.later_plans(plans: List<&2,A.AI.Plan>) -> List<&2,A.AI.Plan>:
  match plans:
    case Nil{}: Nil{}
    case Con{head,rest}: rest

def Life.plan_for(+monster: M.Monsters.State,-monsters: List<&2,M.Monsters.State>,plans: List<&2,A.AI.Plan>,+inside: Targets.Targets.In<monster,monsters>) -> A.AI.Plan:
  match plans:
    case Nil{}: A.AI.Rest{}
    case Con{plan,later}:
      match inside:
        case Targets.Targets.Here{rest,shape}: plan
        case Targets.Targets.There{head,rest,shape,earlier}: Life.plan_for(monster,rest,later,earlier)

law Life.prepend_head:
  for +step: A.AI.Step
  for +result: A.AI.Result
  Targets.Targets.In<A.AI.monster(step),A.AI.monsters(A.AI.prepend(step,result))>

def Life.prepend_head(step,result):
  match step:
    case A.AI.Step{monster,hit}:
      match result:
        case A.AI.Result{monsters,hits}: Targets.Targets.Here{monsters,{==}}

law Life.prepend_member:
  for +monster: M.Monsters.State
  for +step: A.AI.Step
  for +result: A.AI.Result
  for +inside: Targets.Targets.In<monster,A.AI.monsters(result)>
  Targets.Targets.In<monster,A.AI.monsters(A.AI.prepend(step,result))>

def Life.prepend_member(monster,step,result,inside):
  match step:
    case A.AI.Step{head,hit}:
      match result:
        case A.AI.Result{monsters,hits}: Targets.Targets.There{head,monsters,{==},inside}

law Life.run_member:
  for +monster: M.Monsters.State
  for -monsters: List<&2,M.Monsters.State>
  for +plans: List<&2,A.AI.Plan>
  for +inside: Targets.Targets.In<monster,monsters>
  Targets.Targets.In<A.AI.monster(A.AI.step(monster,Life.plan_for(monster,monsters,plans,inside))),A.AI.monsters(A.AI.run(monsters,plans))>

def Life.run_member(monster,monsters,plans,inside):
  match plans:
    case Nil{}:
      match inside:
        case Targets.Targets.Here{rest,shape}:
          %Equal.sym(List<&2,M.Monsters.State>,monsters,Con{monster,rest},shape) : Targets.Targets.In<A.AI.monster(A.AI.step(monster,A.AI.Rest{})),A.AI.monsters(A.AI.run(_,Nil{}))>
          Life.prepend_head(A.AI.step(monster,A.AI.Rest{}),A.AI.run(rest,Nil{}))
        case Targets.Targets.There{head,rest,shape,earlier}:
          %Equal.sym(List<&2,M.Monsters.State>,monsters,Con{head,rest},shape) : Targets.Targets.In<A.AI.monster(A.AI.step(monster,Life.plan_for(monster,rest,Nil{},earlier))),A.AI.monsters(A.AI.run(_,Nil{}))>
          Life.prepend_member(A.AI.monster(A.AI.step(monster,Life.plan_for(monster,rest,Nil{},earlier))),A.AI.step(head,A.AI.Rest{}),A.AI.run(rest,Nil{}),Life.run_member(monster,rest,Nil{},earlier))
    case Con{plan,later}:
      match inside:
        case Targets.Targets.Here{rest,shape}:
          %Equal.sym(List<&2,M.Monsters.State>,monsters,Con{monster,rest},shape) : Targets.Targets.In<A.AI.monster(A.AI.step(monster,plan)),A.AI.monsters(A.AI.run(_,Con{plan,later}))>
          Life.prepend_head(A.AI.step(monster,plan),A.AI.run(rest,later))
        case Targets.Targets.There{head,rest,shape,earlier}:
          %Equal.sym(List<&2,M.Monsters.State>,monsters,Con{head,rest},shape) : Targets.Targets.In<A.AI.monster(A.AI.step(monster,Life.plan_for(monster,rest,later,earlier))),A.AI.monsters(A.AI.run(_,Con{plan,later}))>
          Life.prepend_member(A.AI.monster(A.AI.step(monster,Life.plan_for(monster,rest,later,earlier))),A.AI.step(head,plan),A.AI.run(rest,later),Life.run_member(monster,rest,later,earlier))

# The certificate and membership use the same actual positional plan.
type Life.Follow<-monster: M.Monsters.State,-monsters: List<&2,M.Monsters.State>,-plans: List<&2,A.AI.Plan>,-inside: Targets.Targets.In<monster,monsters>> is Data:
  Life.Follow{certificate: Life.Certificate<monster,Life.plan_for(monster,monsters,plans,inside)>,member: Targets.Targets.In<A.AI.monster(A.AI.step(monster,Life.plan_for(monster,monsters,plans,inside))),A.AI.monsters(A.AI.run(monsters,plans))>}

law Life.follow:
  for +monster: M.Monsters.State
  for -monsters: List<&2,M.Monsters.State>
  for +plans: List<&2,A.AI.Plan>
  for +inside: Targets.Targets.In<monster,monsters>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  Life.Follow<monster,monsters,plans,inside>

def Life.follow(monster,monsters,plans,inside,dead): Life.Follow{Life.classify(monster,Life.plan_for(monster,monsters,plans,inside),dead),Life.run_member(monster,monsters,plans,inside)}

law Life.step_id:
  for +monster: M.Monsters.State
  for +plan: A.AI.Plan
  {R.Roster.id(A.AI.monster(A.AI.step(monster,plan))) == R.Roster.id(monster) : U32}

def Life.step_id(monster,plan):
  %Targets.Targets.key_id(A.AI.monster(A.AI.step(monster,plan))) : {_ == R.Roster.id(monster) : U32}
  %Targets.Targets.key_id(monster) : {I.Identity.mid(Z.Zones.key(A.AI.monster(A.AI.step(monster,plan)))) == _ : U32}
  Equal.cong(Z.Zones.Key,U32,I.Identity.mid,Z.Zones.key(A.AI.monster(A.AI.step(monster,plan))),Z.Zones.key(monster),Z.Zones.step_key(monster,plan))

law Life.run_unique:
  for +monsters: List<&2,M.Monsters.State>
  for +plans: List<&2,A.AI.Plan>
  for +unique: I.Identity.Monsters(monsters)
  I.Identity.Monsters(A.AI.monsters(A.AI.run(monsters,plans)))

def Life.run_unique(monsters,plans,unique):
  %Equal.sym(List<&2,Z.Zones.Key>,Z.Zones.keys(A.AI.monsters(A.AI.run(monsters,plans))),Z.Zones.keys(monsters),Z.Zones.run_keys(monsters,plans)) : I.Identity.Unique(_)
  unique

law Life.final_lookup:
  for +monster: M.Monsters.State
  for +monsters: List<&2,M.Monsters.State>
  for +plans: List<&2,A.AI.Plan>
  for +inside: Targets.Targets.In<monster,monsters>
  for +unique: I.Identity.Monsters(monsters)
  {R.Roster.found(R.Roster.take(A.AI.monsters(A.AI.run(monsters,plans)),R.Roster.id(monster))) == Some{A.AI.monster(A.AI.step(monster,Life.plan_for(monster,monsters,plans,inside)))} : Maybe<&2,M.Monsters.State>}

def Life.final_lookup(monster,monsters,plans,inside,unique):
  %Life.step_id(monster,Life.plan_for(monster,monsters,plans,inside)) : {R.Roster.found(R.Roster.take(A.AI.monsters(A.AI.run(monsters,plans)),_)) == Some{A.AI.monster(A.AI.step(monster,Life.plan_for(monster,monsters,plans,inside)))} : Maybe<&2,M.Monsters.State>}
  Targets.Targets.lookup_member(A.AI.monster(A.AI.step(monster,Life.plan_for(monster,monsters,plans,inside))),A.AI.monsters(A.AI.run(monsters,plans)),Life.run_member(monster,monsters,plans,inside),Life.run_unique(monsters,plans,unique))
