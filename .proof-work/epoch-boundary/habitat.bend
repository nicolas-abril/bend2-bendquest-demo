# Bounds and walkability of the actual monster records and AI transitions.
import Base
import ./terrain.bend as T
import ./navigation.bend as N
import ./players.bend as P
import ./monsters.bend as M
import ./vitals.bend as V
import ./ai.bend as A
import ./roster.bend as R

def Habitat.pos(monster: M.Monsters.State) -> P.Players.Pos:
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}: P.Players.Pos{zone,x,y,0,0}

def Habitat.On(maps: T.Terrain.Maps,monster: M.Monsters.State) -> Data:
  T.Terrain.On<maps,Habitat.pos(monster)>

def Habitat.All(+maps: T.Terrain.Maps,monsters: List<&2,M.Monsters.State>) -> Data:
  match monsters:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,Habitat.On(maps,head),(valid => Habitat.All(maps,rest))>

law Habitat.spawn_positive_position:
  for +value: Nat
  for +mid: U32
  for +kind: U32
  for +rare: U32
  for +zone: U32
  for +x: U32
  for +y: U32
  for +maximum: U32
  {Habitat.pos(M.Monsters.spawn_positive(value, mid, kind, rare, zone, x, y, maximum)) == P.Players.Pos{zone,x,y,0,0} : P.Players.Pos}

def Habitat.spawn_positive_position(value, mid, kind, rare, zone, x, y, maximum):
  match value:
    case Zero{}:
      {==}
    case Succ{rest}:
      {==}

law Habitat.spawn_position:
  for +mid: U32
  for +kind: U32
  for +rare: U32
  for +zone: U32
  for +x: U32
  for +y: U32
  for +maximum: U32
  {Habitat.pos(M.Monsters.spawn(mid, kind, rare, zone, x, y, maximum)) == P.Players.Pos{zone,x,y,0,0} : P.Players.Pos}

def Habitat.spawn_position(mid, kind, rare, zone, x, y, maximum):
  Habitat.spawn_positive_position(U32.to_nat(maximum), mid, kind, rare, zone, x, y, maximum)

law Habitat.wait_position:
  for +monster: M.Monsters.State
  {Habitat.pos(M.Monsters.wait(monster)) == Habitat.pos(monster) : P.Players.Pos}

def Habitat.wait_position(monster):
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      {==}

law Habitat.with_vitals_position:
  for +monster: M.Monsters.State
  for +vitals: V.Vitals.State
  {Habitat.pos(M.Monsters.with_vitals(monster, vitals)) == Habitat.pos(monster) : P.Players.Pos}

def Habitat.with_vitals_position(monster, vitals):
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      match vitals:
        case V.Vitals.State{hp2, xp2, dead2, respawn2, attack2, spin2}:
          {==}

law Habitat.upkeep_position:
  for +monster: M.Monsters.State
  for +amount: U32
  {Habitat.pos(M.Monsters.active(monster, amount)) == Habitat.pos(monster) : P.Players.Pos}

def Habitat.upkeep_position(monster, amount):
  Habitat.with_vitals_position(monster, V.Vitals.live_tick(M.Monsters.vitals(monster), amount, M.Monsters.maximum(monster)))

law Habitat.ready_tick_position:
  for +ready: Bool
  for +monster: M.Monsters.State
  {Habitat.pos(M.Monsters.tick_state(M.Monsters.ready_tick(ready, monster))) == Habitat.pos(monster) : P.Players.Pos}

def Habitat.ready_tick_position(ready, monster):
  match ready:
    case True{}:
      {==}
    case False{}:
      Habitat.wait_position(monster)

law Habitat.dead_tick_position:
  for +permanent: Bool
  for +ready: Bool
  for +monster: M.Monsters.State
  {Habitat.pos(M.Monsters.tick_state(M.Monsters.dead_tick(permanent, ready, monster))) == Habitat.pos(monster) : P.Players.Pos}

def Habitat.dead_tick_position(permanent, ready, monster):
  match permanent:
    case True{}:
      {==}
    case False{}:
      Habitat.ready_tick_position(ready, monster)

law Habitat.tick_gate_position:
  for +is_dead: Bool
  for +permanent: Bool
  for +ready: Bool
  for +monster: M.Monsters.State
  for +amount: U32
  {Habitat.pos(M.Monsters.tick_state(M.Monsters.tick_gate(is_dead, permanent, ready, monster, amount))) == Habitat.pos(monster) : P.Players.Pos}

def Habitat.tick_gate_position(is_dead, permanent, ready, monster, amount):
  match is_dead:
    case True{}:
      Habitat.dead_tick_position(permanent, ready, monster)
    case False{}:
      Habitat.upkeep_position(monster, amount)

law Habitat.tick_position:
  for +monster: M.Monsters.State
  {Habitat.pos(M.Monsters.tick_state(M.Monsters.tick(monster))) == Habitat.pos(monster) : P.Players.Pos}

def Habitat.tick_position(monster):
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      Habitat.tick_gate_position(U32.is_eq(dead, 1), U32.is_eq(respawn, 4294967295), U32.is_le(respawn, 1), M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}, M.Monsters.choose(U32.is_eq(kind, 9), 30, 0))

law Habitat.attack_position:
  for +ready: Bool
  for +monster: M.Monsters.State
  for +target: U32
  for +damage: U32
  {Habitat.pos(A.AI.monster(A.AI.attack(ready, monster, target, damage))) == Habitat.pos(monster) : P.Players.Pos}

def Habitat.attack_position(ready, monster, target, damage):
  match ready:
    case False{}:
      {==}
    case True{}:
      match monster:
        case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
          {==}

law Habitat.finish_position:
  for +monster: M.Monsters.State
  for +hit: V.Vitals.Hit
  for +damage: U32
  {Habitat.pos(M.Monsters.result(M.Monsters.finish(monster, hit, damage))) == Habitat.pos(monster) : P.Players.Pos}

def Habitat.finish_position(monster, hit, damage):
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      match hit:
        case V.Vitals.Hit{next, fell}:
          match next:
            case V.Vitals.State{hp2, xp2, dead2, respawn2, attack2, spin2}:
              {==}

law Habitat.hit_gate_position:
  for +is_dead: Bool
  for +monster: M.Monsters.State
  for +damage: U32
  for +timer: U32
  {Habitat.pos(M.Monsters.result(M.Monsters.hit_gate(is_dead, monster, damage, timer))) == Habitat.pos(monster) : P.Players.Pos}

def Habitat.hit_gate_position(is_dead, monster, damage, timer):
  match is_dead:
    case True{}:
      {==}
    case False{}:
      Habitat.finish_position(monster, V.Vitals.hit_gate(False{}, M.Monsters.vitals(monster), damage, timer), damage)

law Habitat.hit_position:
  for +monster: M.Monsters.State
  for +damage: U32
  for +timer: U32
  {Habitat.pos(M.Monsters.result(M.Monsters.hit(monster, damage, timer))) == Habitat.pos(monster) : P.Players.Pos}

def Habitat.hit_position(monster, damage, timer):
  Habitat.hit_gate_position(U32.is_eq(V.Vitals.dead(M.Monsters.vitals(monster)), 1), monster, damage, timer)

# Rest/attack do not change coordinates. Move and spawn plans must carry a
# destination on the same map and zone as the original monster.
def Habitat.PlanOn(+maps: T.Terrain.Maps,+pos: P.Players.Pos,plan: A.AI.Plan) -> Data:
  match plan:
    case A.AI.Rest{}: Unit
    case A.AI.Move{x,y,target}: T.Terrain.On<maps,P.Players.Pos{N.Navigation.zone(pos),x,y,0,0}>
    case A.AI.Attack{target,damage}: Unit
    case A.AI.Spawn{kind,rare,x,y,maximum}: T.Terrain.On<maps,P.Players.Pos{N.Navigation.zone(pos),x,y,0,0}>

law Habitat.spawn_on:
  for +maps: T.Terrain.Maps
  for +mid: U32
  for +kind: U32
  for +rare: U32
  for +zone: U32
  for +x: U32
  for +y: U32
  for +maximum: U32
  for +valid: T.Terrain.On<maps,P.Players.Pos{zone,x,y,0,0}>
  Habitat.On(maps,M.Monsters.spawn(mid,kind,rare,zone,x,y,maximum))

def Habitat.spawn_on(maps,mid,kind,rare,zone,x,y,maximum,valid):
  %Equal.sym(P.Players.Pos,Habitat.pos(M.Monsters.spawn(mid,kind,rare,zone,x,y,maximum)),P.Players.Pos{zone,x,y,0,0},Habitat.spawn_position(mid,kind,rare,zone,x,y,maximum)) : T.Terrain.On<maps,_>
  valid

law Habitat.hit_on:
  for +maps: T.Terrain.Maps
  for +monster: M.Monsters.State
  for +damage: U32
  for +timer: U32
  for +valid: Habitat.On(maps,monster)
  Habitat.On(maps,M.Monsters.result(M.Monsters.hit(monster,damage,timer)))

def Habitat.hit_on(maps,monster,damage,timer,valid):
  %Equal.sym(P.Players.Pos,Habitat.pos(M.Monsters.result(M.Monsters.hit(monster,damage,timer))),Habitat.pos(monster),Habitat.hit_position(monster,damage,timer)) : T.Terrain.On<maps,_>
  valid

law Habitat.tick_on:
  for +maps: T.Terrain.Maps
  for +monster: M.Monsters.State
  for +valid: Habitat.On(maps,monster)
  Habitat.On(maps,M.Monsters.tick_state(M.Monsters.tick(monster)))

def Habitat.tick_on(maps,monster,valid):
  %Equal.sym(P.Players.Pos,Habitat.pos(M.Monsters.tick_state(M.Monsters.tick(monster))),Habitat.pos(monster),Habitat.tick_position(monster)) : T.Terrain.On<maps,_>
  valid

law Habitat.attack_on:
  for +maps: T.Terrain.Maps
  for +ready: Bool
  for +monster: M.Monsters.State
  for +target: U32
  for +damage: U32
  for +valid: Habitat.On(maps,monster)
  Habitat.On(maps,A.AI.monster(A.AI.attack(ready,monster,target,damage)))

def Habitat.attack_on(maps,ready,monster,target,damage,valid):
  %Equal.sym(P.Players.Pos,Habitat.pos(A.AI.monster(A.AI.attack(ready,monster,target,damage))),Habitat.pos(monster),Habitat.attack_position(ready,monster,target,damage)) : T.Terrain.On<maps,_>
  valid

law Habitat.active_on:
  for +maps: T.Terrain.Maps
  for +monster: M.Monsters.State
  for +plan: A.AI.Plan
  for +valid: Habitat.On(maps,monster)
  for +planned: Habitat.PlanOn(maps,Habitat.pos(monster),plan)
  Habitat.On(maps,A.AI.monster(A.AI.active(monster,plan)))

def Habitat.active_on(maps,monster,plan,valid,planned):
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}:
      match plan:
        case A.AI.Rest{}: valid
        case A.AI.Move{nx,ny,next_target}: planned
        case A.AI.Attack{next_target,damage}: Habitat.attack_on(maps,U32.is_eq(attack,0),M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn},next_target,damage,valid)
        case A.AI.Spawn{new_kind,new_rare,nx,ny,new_maximum}: valid

law Habitat.rebirth_on:
  for +maps: T.Terrain.Maps
  for +monster: M.Monsters.State
  for +plan: A.AI.Plan
  for +valid: Habitat.On(maps,monster)
  for +planned: Habitat.PlanOn(maps,Habitat.pos(monster),plan)
  Habitat.On(maps,A.AI.monster(A.AI.rebirth(monster,plan)))

def Habitat.rebirth_on(maps,monster,plan,valid,planned):
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}:
      match plan:
        case A.AI.Rest{}: valid
        case A.AI.Move{nx,ny,next_target}: valid
        case A.AI.Attack{next_target,damage}: valid
        case A.AI.Spawn{new_kind,new_rare,nx,ny,new_maximum}: Habitat.spawn_on(maps,mid,new_kind,new_rare,zone,nx,ny,new_maximum,planned)

law Habitat.commit_on:
  for +maps: T.Terrain.Maps
  for +tick: M.Monsters.Tick
  for +plan: A.AI.Plan
  for +valid: Habitat.On(maps,M.Monsters.tick_state(tick))
  for +planned: Habitat.PlanOn(maps,Habitat.pos(M.Monsters.tick_state(tick)),plan)
  Habitat.On(maps,A.AI.monster(A.AI.commit(tick,plan)))

def Habitat.commit_on(maps,tick,plan,valid,planned):
  match tick:
    case M.Monsters.Tick{monster,phase}:
      match phase:
        case M.Monsters.Active{}: Habitat.active_on(maps,monster,plan,valid,planned)
        case M.Monsters.Dormant{}: valid
        case M.Monsters.Rebirth{}: Habitat.rebirth_on(maps,monster,plan,valid,planned)

law Habitat.step_on:
  for +maps: T.Terrain.Maps
  for +monster: M.Monsters.State
  for +plan: A.AI.Plan
  for +valid: Habitat.On(maps,monster)
  for +planned: Habitat.PlanOn(maps,Habitat.pos(monster),plan)
  Habitat.On(maps,A.AI.monster(A.AI.step(monster,plan)))

def Habitat.step_on(maps,monster,plan,valid,planned):
  Habitat.commit_on(maps,M.Monsters.tick(monster),plan,Habitat.tick_on(maps,monster,valid),
    (%Equal.sym(P.Players.Pos,Habitat.pos(M.Monsters.tick_state(M.Monsters.tick(monster))),Habitat.pos(monster),Habitat.tick_position(monster)) : Habitat.PlanOn(maps,_,plan); planned))

def Habitat.Plans(+maps: T.Terrain.Maps,monsters: List<&2,M.Monsters.State>,plans: List<&2,A.AI.Plan>) -> Data:
  match monsters:
    case Nil{}: Unit
    case Con{head,rest}:
      match plans:
        case Nil{}: Unit
        case Con{plan,later}: Sigma<&2,&2,Habitat.PlanOn(maps,Habitat.pos(head),plan),(valid => Habitat.Plans(maps,rest,later))>

law Habitat.plans_nil:
  for +maps: T.Terrain.Maps
  for +monsters: List<&2,M.Monsters.State>
  Habitat.Plans(maps,monsters,Nil{})

def Habitat.plans_nil(maps,monsters):
  match monsters:
    case Nil{}: Unit{}
    case Con{head,rest}: Unit{}

law Habitat.prepend_on:
  for +maps: T.Terrain.Maps
  for +step: A.AI.Step
  for +result: A.AI.Result
  for +head: Habitat.On(maps,A.AI.monster(step))
  for +rest: Habitat.All(maps,A.AI.monsters(result))
  Habitat.All(maps,A.AI.monsters(A.AI.prepend(step,result)))

def Habitat.prepend_on(maps,step,result,head,rest):
  match step:
    case A.AI.Step{monster,hit}:
      match result:
        case A.AI.Result{monsters,hits}: Tuple{head,rest}

law Habitat.run_on:
  for +maps: T.Terrain.Maps
  for +monsters: List<&2,M.Monsters.State>
  for +plans: List<&2,A.AI.Plan>
  for +valid: Habitat.All(maps,monsters)
  for +planned: Habitat.Plans(maps,monsters,plans)
  Habitat.All(maps,A.AI.monsters(A.AI.run(monsters,plans)))

def Habitat.run_on(maps,monsters,plans,valid,planned):
  match monsters:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match plans:
        case Nil{}:
          match valid:
            case Tuple{head_ok,rest_ok}:
              Habitat.prepend_on(maps,A.AI.step(head,A.AI.Rest{}),A.AI.run(rest,Nil{}),Habitat.step_on(maps,head,A.AI.Rest{},head_ok,Unit{}),Habitat.run_on(maps,rest,Nil{},rest_ok,Habitat.plans_nil(maps,rest)))
        case Con{plan,later}:
          match valid:
            case Tuple{head_ok,rest_ok}:
              match planned:
                case Tuple{plan_ok,later_ok}:
                  Habitat.prepend_on(maps,A.AI.step(head,plan),A.AI.run(rest,later),Habitat.step_on(maps,head,plan,head_ok,plan_ok),Habitat.run_on(maps,rest,later,rest_ok,later_ok))

law Habitat.keep_on:
  for +maps: T.Terrain.Maps
  for +keep: Bool
  for +head: M.Monsters.State
  for +tail: List<&2, M.Monsters.State>
  for +head_ok: Habitat.On(maps,head)
  for +tail_ok: Habitat.All(maps,tail)
  Habitat.All(maps,R.Roster.keep(keep, head, tail))

def Habitat.keep_on(maps,keep, head, tail, head_ok, tail_ok):
  match keep:
    case True{}:
      Tuple{head_ok, tail_ok}
    case False{}:
      tail_ok

law Habitat.zone_on:
  for +maps: T.Terrain.Maps
  for +monsters: List<&2, M.Monsters.State>
  for +zone: U32
  for +valid: Habitat.All(maps,monsters)
  Habitat.All(maps,R.Roster.zone(monsters, zone))

def Habitat.zone_on(maps,monsters, zone, valid):
  match monsters:
    case Nil{}:
      Unit{}
    case Con{head, rest}:
      match valid:
        case Tuple{head_ok, rest_ok}:
          Habitat.keep_on(maps,U32.is_eq(R.Roster.zone_of(head), zone), head, R.Roster.zone(rest, zone), head_ok, Habitat.zone_on(maps,rest, zone, rest_ok))

law Habitat.concat_on:
  for +maps: T.Terrain.Maps
  for +left: List<&2, M.Monsters.State>
  for +right: List<&2, M.Monsters.State>
  for +left_ok: Habitat.All(maps,left)
  for +right_ok: Habitat.All(maps,right)
  Habitat.All(maps,R.Roster.concat(left, right))

def Habitat.concat_on(maps,left, right, left_ok, right_ok):
  match left:
    case Nil{}:
      right_ok
    case Con{head, rest}:
      match left_ok:
        case Tuple{head_ok, rest_ok}:
          Tuple{head_ok, Habitat.concat_on(maps,rest, right, rest_ok, right_ok)}

law Habitat.merge_on:
  for +maps: T.Terrain.Maps
  for +left: A.AI.Result
  for +right: A.AI.Result
  for +left_ok: Habitat.All(maps,A.AI.monsters(left))
  for +right_ok: Habitat.All(maps,A.AI.monsters(right))
  Habitat.All(maps,A.AI.monsters(A.AI.merge(left, right)))

def Habitat.merge_on(maps,left, right, left_ok, right_ok):
  match left:
    case A.AI.Result{lm, lh}:
      match right:
        case A.AI.Result{rm, rh}:
          Habitat.concat_on(maps,lm, rm, left_ok, right_ok)

law Habitat.run_zones_on:
  for +maps: T.Terrain.Maps
  for +monsters: List<&2,M.Monsters.State>
  for +p0: List<&2,A.AI.Plan>
  for +p1: List<&2,A.AI.Plan>
  for +p2: List<&2,A.AI.Plan>
  for +p3: List<&2,A.AI.Plan>
  for +valid: Habitat.All(maps,monsters)
  for +v0: Habitat.Plans(maps,R.Roster.zone(monsters,0),p0)
  for +v1: Habitat.Plans(maps,R.Roster.zone(monsters,1),p1)
  for +v2: Habitat.Plans(maps,R.Roster.zone(monsters,2),p2)
  for +v3: Habitat.Plans(maps,R.Roster.zone(monsters,3),p3)
  Habitat.All(maps,A.AI.monsters(A.AI.run_zones(monsters,p0,p1,p2,p3)))

def Habitat.run_zones_on(maps,monsters,p0,p1,p2,p3,valid,v0,v1,v2,v3):
  Habitat.merge_on(maps,A.AI.run(R.Roster.zone(monsters,0),p0),A.AI.merge(A.AI.run(R.Roster.zone(monsters,1),p1),A.AI.merge(A.AI.run(R.Roster.zone(monsters,2),p2),A.AI.run(R.Roster.zone(monsters,3),p3))),Habitat.run_on(maps,R.Roster.zone(monsters,0),p0,Habitat.zone_on(maps,monsters,0,valid),v0),Habitat.merge_on(maps,A.AI.run(R.Roster.zone(monsters,1),p1),A.AI.merge(A.AI.run(R.Roster.zone(monsters,2),p2),A.AI.run(R.Roster.zone(monsters,3),p3)),Habitat.run_on(maps,R.Roster.zone(monsters,1),p1,Habitat.zone_on(maps,monsters,1,valid),v1),Habitat.merge_on(maps,A.AI.run(R.Roster.zone(monsters,2),p2),A.AI.run(R.Roster.zone(monsters,3),p3),Habitat.run_on(maps,R.Roster.zone(monsters,2),p2,Habitat.zone_on(maps,monsters,2,valid),v2),Habitat.run_on(maps,R.Roster.zone(monsters,3),p3,Habitat.zone_on(maps,monsters,3,valid),v3))))

law Habitat.swap_on:
  for +maps: T.Terrain.Maps
  for +first: M.Monsters.State
  for +second: M.Monsters.State
  for +rest: List<&2,M.Monsters.State>
  for +valid: Habitat.All(maps,Con{second,Con{first,rest}})
  Habitat.All(maps,Con{first,Con{second,rest}})

def Habitat.swap_on(maps,first,second,rest,valid):
  match valid:
    case Tuple{second_ok,tail_ok}:
      match tail_ok:
        case Tuple{first_ok,rest_ok}: Tuple{first_ok,Tuple{second_ok,rest_ok}}

def Habitat.head_on(+maps: T.Terrain.Maps,+head: M.Monsters.State, +rest: List<&2,M.Monsters.State>, valid: Habitat.All(maps,Con{head,rest})) -> Habitat.On(maps,head):
  match valid:
    case Tuple{head_ok,rest_ok}: head_ok

def Habitat.tail_on(+maps: T.Terrain.Maps,+head: M.Monsters.State, +rest: List<&2,M.Monsters.State>, valid: Habitat.All(maps,Con{head,rest})) -> Habitat.All(maps,rest):
  match valid:
    case Tuple{head_ok,rest_ok}: rest_ok

law Habitat.perm_on:
  for +maps: T.Terrain.Maps
  for -left: List<&2,M.Monsters.State>
  for -right: List<&2,M.Monsters.State>
  for +permutation: R.Roster.Perm<left,right>
  for +valid: Habitat.All(maps,right)
  Habitat.All(maps,left)

def Habitat.perm_on(maps,left,right,permutation,valid):
  match permutation:
    case R.Roster.Same{equal}:
      %Equal.sym(List<&2,M.Monsters.State>,left,right,equal) : Habitat.All(maps,_)
      valid
    case R.Roster.Common{head,lt,rt,ls,rs,tails}:
      %Equal.sym(List<&2,M.Monsters.State>,left,Con{head,lt},ls) : Habitat.All(maps,_)
      +right_ok = {(%rs : Habitat.All(maps,_); valid) : Habitat.All(maps,Con{head,rt})}
      Tuple{Habitat.head_on(maps,head,rt,right_ok),Habitat.perm_on(maps,lt,rt,tails,Habitat.tail_on(maps,head,rt,right_ok))}
    case R.Roster.Swap{first,second,rest,ls,rs}:
      %Equal.sym(List<&2,M.Monsters.State>,left,Con{first,Con{second,rest}},ls) : Habitat.All(maps,_)
      Habitat.swap_on(maps,first,second,rest,(%rs : Habitat.All(maps,_); valid))
    case R.Roster.Then{middle,before,after}:
      Habitat.perm_on(maps,left,middle,before,Habitat.perm_on(maps,middle,right,after,valid))

law Habitat.take_on:
  for +maps: T.Terrain.Maps
  for +players: List<&2,M.Monsters.State>
  for +target: U32
  for +valid: Habitat.All(maps,players)
  Habitat.All(maps,R.Roster.restore(R.Roster.take(players,target)))

def Habitat.take_on(maps,players,target,valid):
  Habitat.perm_on(maps,R.Roster.restore(R.Roster.take(players,target)),players,R.Roster.take_restores(players,target),valid)

law Habitat.strike_result_on:
  for +maps: T.Terrain.Maps
  for +hit: M.Monsters.Hit
  for +others: List<&2,M.Monsters.State>
  for +hit_ok: Habitat.On(maps,M.Monsters.result(hit))
  for +others_ok: Habitat.All(maps,others)
  Habitat.All(maps,R.Roster.struck(R.Roster.strike_result(hit,others)))

def Habitat.strike_result_on(maps,hit,others,hit_ok,others_ok):
  match hit:
    case M.Monsters.Hit{monster,killed,dealt}:
      match monster:
        case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}:
          match killed:
            case False{}: Tuple{hit_ok,others_ok}
            case True{}: Tuple{hit_ok,others_ok}

law Habitat.strike_taken_on:
  for +maps: T.Terrain.Maps
  for +taken: R.Roster.Take
  for +damage: U32
  for +valid: Habitat.All(maps,R.Roster.restore(taken))
  Habitat.All(maps,R.Roster.struck(R.Roster.strike_taken(taken,damage)))

def Habitat.strike_taken_on(maps,taken,damage,valid):
  match taken:
    case R.Roster.Take{others,found}:
      match found:
        case None{}: valid
        case Some{monster}:
          match valid:
            case Tuple{monster_ok,others_ok}:
              Habitat.strike_result_on(maps,M.Monsters.hit(monster,damage,R.Roster.respawn_time(M.Monsters.kind(monster))),others,Habitat.hit_on(maps,monster,damage,R.Roster.respawn_time(M.Monsters.kind(monster)),monster_ok),others_ok)

law Habitat.strike_on:
  for +maps: T.Terrain.Maps
  for +monsters: List<&2,M.Monsters.State>
  for +target: U32
  for +damage: U32
  for +valid: Habitat.All(maps,monsters)
  Habitat.All(maps,R.Roster.struck(R.Roster.strike(monsters,target,damage)))

def Habitat.strike_on(maps,monsters,target,damage,valid):
  Habitat.strike_taken_on(maps,R.Roster.take(monsters,target),damage,Habitat.take_on(maps,monsters,target,valid))
