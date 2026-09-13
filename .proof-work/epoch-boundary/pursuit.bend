# The server's cardinal chase and active monster planning.
import Base
import ./terrain.bend as T
import ./navigation.bend as N
import ./landscape.bend as L
import ./habitat.bend as H
import ./players.bend as P
import ./monsters.bend as M
import ./ai.bend as A
import ./interactions.bend as I

# Selected target coordinates may be arbitrary; collision still uses the map.
type Pursuit.Target is Data:
  Pursuit.Target{pid: U32,x: U32,y: U32,present: Bool}

def Pursuit.pick(flag: Bool,yes: P.Players.Pos,no: P.Players.Pos) -> P.Players.Pos:
  match flag:
    case True{}: yes
    case False{}: no

def Pursuit.walk(maps: T.Terrain.Maps,pos: P.Players.Pos,heading: U32) -> P.Players.Pos:
  N.Navigation.control(T.Terrain.mob_move(maps,N.Navigation.control(pos,heading,1)),0,0)

def Pursuit.same_xy(+a: P.Players.Pos,+b: P.Players.Pos) -> Bool:
  Bool.and(U32.is_eq(N.Navigation.x(a),N.Navigation.x(b)),U32.is_eq(N.Navigation.y(a),N.Navigation.y(b)))

def Pursuit.fallback(+maps: T.Terrain.Maps,+pos: P.Players.Pos,+first: P.Players.Pos,heading: U32,other: Bool) -> P.Players.Pos:
  Pursuit.pick(Bool.and(Pursuit.same_xy(first,pos),other),Pursuit.walk(maps,pos,heading),first)

def Pursuit.axes(horizontal: Bool,vertical: Bool,+maps: T.Terrain.Maps,+pos: P.Players.Pos,+dh: U32,+dv: U32,+dx: U32,+dy: U32) -> P.Players.Pos:
  match horizontal:
    case True{}: Pursuit.fallback(maps,pos,Pursuit.walk(maps,pos,dh),dv,U32.is_gt(dy,0))
    case False{}:
      match vertical:
        case True{}: Pursuit.fallback(maps,pos,Pursuit.walk(maps,pos,dv),dh,U32.is_gt(dx,0))
        case False{}: pos

def Pursuit.toward(+maps: T.Terrain.Maps,+pos: P.Players.Pos,+tx: U32,+ty: U32) -> P.Players.Pos:
  +dx = I.Interaction.distance(N.Navigation.x(pos),tx)
  +dy = I.Interaction.distance(N.Navigation.y(pos),ty)
  +dh = L.Landscape.pick(U32.is_gt(tx,N.Navigation.x(pos)),1,0)
  +dv = L.Landscape.pick(U32.is_gt(ty,N.Navigation.y(pos)),3,2)
  Pursuit.axes(Bool.and(U32.is_ge(dx,dy),U32.is_gt(dx,0)),U32.is_gt(dy,0),maps,pos,dh,dv,dx,dy)

def Pursuit.move(pos: P.Players.Pos,target: U32) -> A.AI.Plan:
  match pos:
    case P.Players.Pos{zone,x,y,dir,moving}: A.AI.Move{x,y,target}

def Pursuit.wander(go: Bool,maps: T.Terrain.Maps,+pos: P.Players.Pos,heading: U32) -> A.AI.Plan:
  match go:
    case False{}: Pursuit.move(pos,0)
    case True{}: Pursuit.move(Pursuit.walk(maps,pos,heading),0)

def Pursuit.chase(go: Bool,maps: T.Terrain.Maps,+pos: P.Players.Pos,target: U32,tx: U32,ty: U32) -> A.AI.Plan:
  match go:
    case False{}: Pursuit.move(pos,target)
    case True{}: Pursuit.move(Pursuit.toward(maps,pos,tx,ty),target)

def Pursuit.attack(ready: Bool,pos: P.Players.Pos,target: U32,damage: U32) -> A.AI.Plan:
  match ready:
    case False{}: Pursuit.move(pos,target)
    case True{}: A.AI.Attack{target,damage}

def Pursuit.adjacent(near: Bool,+maps: T.Terrain.Maps,+pos: P.Players.Pos,target: U32,tx: U32,ty: U32,tick: U32,mid: U32,attack: U32,damage: U32) -> A.AI.Plan:
  match near:
    case True{}: Pursuit.attack(U32.is_eq(attack,0),pos,target,damage)
    case False{}: Pursuit.chase(U32.is_eq(U32.and(U32.add(tick,mid),1),0),maps,pos,target,tx,ty)

def Pursuit.target(maps: T.Terrain.Maps,+pos: P.Players.Pos,+current: Pursuit.Target,+tick: U32,+mid: U32,attack: U32,damage: U32) -> A.AI.Plan:
  match current:
    case Pursuit.Target{pid,tx,ty,present}:
      match present:
        case False{}: Pursuit.wander(U32.is_eq(U32.and(U32.add(tick,mid),7),0),maps,pos,U32.and(L.Landscape.hash(tick,U32.mul(mid,5)),3))
        case True{}: Pursuit.adjacent(Bool.and(U32.is_le(I.Interaction.distance(N.Navigation.x(pos),tx),1),U32.is_le(I.Interaction.distance(N.Navigation.y(pos),ty),1)),maps,pos,pid,tx,ty,tick,mid,attack,damage)

def Pursuit.plan(maps: T.Terrain.Maps,monster: M.Monsters.State,current: Pursuit.Target,tick: U32,damage: U32) -> A.AI.Plan:
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}:
      Pursuit.target(maps,P.Players.Pos{zone,x,y,0,0},current,tick,mid,attack,damage)

law Pursuit.pick_on:
  for +flag: Bool
  for +maps: T.Terrain.Maps
  for +yes: P.Players.Pos
  for +no: P.Players.Pos
  for +yes_on: T.Terrain.On<maps,yes>
  for +no_on: T.Terrain.On<maps,no>
  T.Terrain.On<maps,Pursuit.pick(flag,yes,no)>

def Pursuit.pick_on(flag,maps,yes,no,yes_on,no_on):
  match flag:
    case True{}: yes_on
    case False{}: no_on

law Pursuit.walk_on:
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  for +heading: U32
  for +valid: T.Terrain.On<maps,pos>
  T.Terrain.On<maps,Pursuit.walk(maps,pos,heading)>

def Pursuit.walk_on(maps,pos,heading,valid):
  L.Landscape.control_on(maps,T.Terrain.mob_move(maps,N.Navigation.control(pos,heading,1)),0,0,T.Terrain.mob_move_on(maps,N.Navigation.control(pos,heading,1),L.Landscape.control_on(maps,pos,heading,1,valid)))

law Pursuit.fallback_on:
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  for +first: P.Players.Pos
  for +heading: U32
  for +other: Bool
  for +valid: T.Terrain.On<maps,pos>
  for +first_on: T.Terrain.On<maps,first>
  T.Terrain.On<maps,Pursuit.fallback(maps,pos,first,heading,other)>

def Pursuit.fallback_on(maps,pos,first,heading,other,valid,first_on):
  Pursuit.pick_on(Bool.and(Pursuit.same_xy(first,pos),other),maps,Pursuit.walk(maps,pos,heading),first,Pursuit.walk_on(maps,pos,heading,valid),first_on)

law Pursuit.axes_on:
  for +horizontal: Bool
  for +vertical: Bool
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  for +dh: U32
  for +dv: U32
  for +dx: U32
  for +dy: U32
  for +valid: T.Terrain.On<maps,pos>
  T.Terrain.On<maps,Pursuit.axes(horizontal,vertical,maps,pos,dh,dv,dx,dy)>

def Pursuit.axes_on(horizontal,vertical,maps,pos,dh,dv,dx,dy,valid):
  match horizontal:
    case True{}: Pursuit.fallback_on(maps,pos,Pursuit.walk(maps,pos,dh),dv,U32.is_gt(dy,0),valid,Pursuit.walk_on(maps,pos,dh,valid))
    case False{}:
      match vertical:
        case True{}: Pursuit.fallback_on(maps,pos,Pursuit.walk(maps,pos,dv),dh,U32.is_gt(dx,0),valid,Pursuit.walk_on(maps,pos,dv,valid))
        case False{}: valid

law Pursuit.toward_on:
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  for +tx: U32
  for +ty: U32
  for +valid: T.Terrain.On<maps,pos>
  T.Terrain.On<maps,Pursuit.toward(maps,pos,tx,ty)>

def Pursuit.toward_on(maps,pos,tx,ty,valid):
  +dx = I.Interaction.distance(N.Navigation.x(pos),tx)
  +dy = I.Interaction.distance(N.Navigation.y(pos),ty)
  +dh = L.Landscape.pick(U32.is_gt(tx,N.Navigation.x(pos)),1,0)
  +dv = L.Landscape.pick(U32.is_gt(ty,N.Navigation.y(pos)),3,2)
  Pursuit.axes_on(Bool.and(U32.is_ge(dx,dy),U32.is_gt(dx,0)),U32.is_gt(dy,0),maps,pos,dh,dv,dx,dy,valid)

def Pursuit.zone_control(controls: T.Terrain.Controls) -> U32:
  match controls:
    case T.Terrain.Controls{zone,heading,moving}: zone

law Pursuit.zone_controls:
  for +pos: P.Players.Pos
  {N.Navigation.zone(pos) == Pursuit.zone_control(T.Terrain.controls(pos)) : U32}

def Pursuit.zone_controls(pos):
  match pos:
    case P.Players.Pos{zone,x,y,heading,moving}: {==}

law Pursuit.control_zone:
  for +pos: P.Players.Pos
  for +heading: U32
  for +moving: U32
  {N.Navigation.zone(N.Navigation.control(pos,heading,moving)) == N.Navigation.zone(pos) : U32}

def Pursuit.control_zone(pos,heading,moving):
  match pos:
    case P.Players.Pos{zone,x,y,dir,old_moving}: {==}

law Pursuit.mob_zone:
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  {N.Navigation.zone(T.Terrain.mob_move(maps,pos)) == N.Navigation.zone(pos) : U32}

def Pursuit.mob_zone(maps,pos):
  Equal.trans(U32,N.Navigation.zone(T.Terrain.mob_move(maps,pos)),Pursuit.zone_control(T.Terrain.controls(T.Terrain.mob_move(maps,pos))),N.Navigation.zone(pos),Pursuit.zone_controls(T.Terrain.mob_move(maps,pos)),
    Equal.trans(U32,Pursuit.zone_control(T.Terrain.controls(T.Terrain.mob_move(maps,pos))),Pursuit.zone_control(T.Terrain.controls(pos)),N.Navigation.zone(pos),Equal.cong(T.Terrain.Controls,U32,(controls => Pursuit.zone_control(controls)),T.Terrain.controls(T.Terrain.mob_move(maps,pos)),T.Terrain.controls(pos),T.Terrain.mob_move_controls(maps,pos)),Equal.sym(U32,N.Navigation.zone(pos),Pursuit.zone_control(T.Terrain.controls(pos)),Pursuit.zone_controls(pos))))

law Pursuit.walk_zone:
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  for +heading: U32
  {N.Navigation.zone(Pursuit.walk(maps,pos,heading)) == N.Navigation.zone(pos) : U32}

def Pursuit.walk_zone(maps,pos,heading):
  Equal.trans(U32,N.Navigation.zone(Pursuit.walk(maps,pos,heading)),N.Navigation.zone(T.Terrain.mob_move(maps,N.Navigation.control(pos,heading,1))),N.Navigation.zone(pos),Pursuit.control_zone(T.Terrain.mob_move(maps,N.Navigation.control(pos,heading,1)),0,0),Equal.trans(U32,N.Navigation.zone(T.Terrain.mob_move(maps,N.Navigation.control(pos,heading,1))),N.Navigation.zone(N.Navigation.control(pos,heading,1)),N.Navigation.zone(pos),Pursuit.mob_zone(maps,N.Navigation.control(pos,heading,1)),Pursuit.control_zone(pos,heading,1)))

law Pursuit.pick_zone:
  for +flag: Bool
  for +yes: P.Players.Pos
  for +no: P.Players.Pos
  for +zone: U32
  for +yes_zone: {N.Navigation.zone(yes) == zone : U32}
  for +no_zone: {N.Navigation.zone(no) == zone : U32}
  {N.Navigation.zone(Pursuit.pick(flag,yes,no)) == zone : U32}

def Pursuit.pick_zone(flag,yes,no,zone,yes_zone,no_zone):
  match flag:
    case True{}: yes_zone
    case False{}: no_zone

law Pursuit.fallback_zone:
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  for +first: P.Players.Pos
  for +heading: U32
  for +other: Bool
  for +first_zone: {N.Navigation.zone(first) == N.Navigation.zone(pos) : U32}
  {N.Navigation.zone(Pursuit.fallback(maps,pos,first,heading,other)) == N.Navigation.zone(pos) : U32}

def Pursuit.fallback_zone(maps,pos,first,heading,other,first_zone):
  Pursuit.pick_zone(Bool.and(Pursuit.same_xy(first,pos),other),Pursuit.walk(maps,pos,heading),first,N.Navigation.zone(pos),Pursuit.walk_zone(maps,pos,heading),first_zone)

law Pursuit.axes_zone:
  for +horizontal: Bool
  for +vertical: Bool
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  for +dh: U32
  for +dv: U32
  for +dx: U32
  for +dy: U32
  {N.Navigation.zone(Pursuit.axes(horizontal,vertical,maps,pos,dh,dv,dx,dy)) == N.Navigation.zone(pos) : U32}

def Pursuit.axes_zone(horizontal,vertical,maps,pos,dh,dv,dx,dy):
  match horizontal:
    case True{}: Pursuit.fallback_zone(maps,pos,Pursuit.walk(maps,pos,dh),dv,U32.is_gt(dy,0),Pursuit.walk_zone(maps,pos,dh))
    case False{}:
      match vertical:
        case True{}: Pursuit.fallback_zone(maps,pos,Pursuit.walk(maps,pos,dv),dh,U32.is_gt(dx,0),Pursuit.walk_zone(maps,pos,dv))
        case False{}: {==}

law Pursuit.toward_zone:
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  for +tx: U32
  for +ty: U32
  {N.Navigation.zone(Pursuit.toward(maps,pos,tx,ty)) == N.Navigation.zone(pos) : U32}

def Pursuit.toward_zone(maps,pos,tx,ty):
  +dx = I.Interaction.distance(N.Navigation.x(pos),tx)
  +dy = I.Interaction.distance(N.Navigation.y(pos),ty)
  +dh = L.Landscape.pick(U32.is_gt(tx,N.Navigation.x(pos)),1,0)
  +dv = L.Landscape.pick(U32.is_gt(ty,N.Navigation.y(pos)),3,2)
  Pursuit.axes_zone(Bool.and(U32.is_ge(dx,dy),U32.is_gt(dx,0)),U32.is_gt(dy,0),maps,pos,dh,dv,dx,dy)

law Pursuit.move_on:
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  for +next: P.Players.Pos
  for +target: U32
  for +valid: T.Terrain.On<maps,next>
  for +zone: {N.Navigation.zone(next) == N.Navigation.zone(pos) : U32}
  H.Habitat.PlanOn(maps,pos,Pursuit.move(next,target))

def Pursuit.move_on(maps,pos,next,target,valid,zone):
  match next:
    case P.Players.Pos{nz,nx,ny,dir,moving}:
      %zone : T.Terrain.On<maps,P.Players.Pos{_,nx,ny,0,0}>
      L.Landscape.control_on(maps,P.Players.Pos{nz,nx,ny,dir,moving},0,0,valid)

law Pursuit.wander_on:
  for +go: Bool
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  for +heading: U32
  for +valid: T.Terrain.On<maps,pos>
  H.Habitat.PlanOn(maps,pos,Pursuit.wander(go,maps,pos,heading))

def Pursuit.wander_on(go,maps,pos,heading,valid):
  match go:
    case False{}: Pursuit.move_on(maps,pos,pos,0,valid,{==})
    case True{}: Pursuit.move_on(maps,pos,Pursuit.walk(maps,pos,heading),0,Pursuit.walk_on(maps,pos,heading,valid),Pursuit.walk_zone(maps,pos,heading))

law Pursuit.chase_on:
  for +go: Bool
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  for +target: U32
  for +tx: U32
  for +ty: U32
  for +valid: T.Terrain.On<maps,pos>
  H.Habitat.PlanOn(maps,pos,Pursuit.chase(go,maps,pos,target,tx,ty))

def Pursuit.chase_on(go,maps,pos,target,tx,ty,valid):
  match go:
    case False{}: Pursuit.move_on(maps,pos,pos,target,valid,{==})
    case True{}: Pursuit.move_on(maps,pos,Pursuit.toward(maps,pos,tx,ty),target,Pursuit.toward_on(maps,pos,tx,ty,valid),Pursuit.toward_zone(maps,pos,tx,ty))

law Pursuit.attack_on:
  for +ready: Bool
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  for +target: U32
  for +damage: U32
  for +valid: T.Terrain.On<maps,pos>
  H.Habitat.PlanOn(maps,pos,Pursuit.attack(ready,pos,target,damage))

def Pursuit.attack_on(ready,maps,pos,target,damage,valid):
  match ready:
    case False{}: Pursuit.move_on(maps,pos,pos,target,valid,{==})
    case True{}: Unit{}

law Pursuit.adjacent_on:
  for +near: Bool
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  for +target: U32
  for +tx: U32
  for +ty: U32
  for +tick: U32
  for +mid: U32
  for +attack: U32
  for +damage: U32
  for +valid: T.Terrain.On<maps,pos>
  H.Habitat.PlanOn(maps,pos,Pursuit.adjacent(near,maps,pos,target,tx,ty,tick,mid,attack,damage))

def Pursuit.adjacent_on(near,maps,pos,target,tx,ty,tick,mid,attack,damage,valid):
  match near:
    case True{}: Pursuit.attack_on(U32.is_eq(attack,0),maps,pos,target,damage,valid)
    case False{}: Pursuit.chase_on(U32.is_eq(U32.and(U32.add(tick,mid),1),0),maps,pos,target,tx,ty,valid)

law Pursuit.target_on:
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  for +current: Pursuit.Target
  for +tick: U32
  for +mid: U32
  for +attack: U32
  for +damage: U32
  for +valid: T.Terrain.On<maps,pos>
  H.Habitat.PlanOn(maps,pos,Pursuit.target(maps,pos,current,tick,mid,attack,damage))

def Pursuit.target_on(maps,pos,current,tick,mid,attack,damage,valid):
  match current:
    case Pursuit.Target{pid,tx,ty,present}:
      match present:
        case False{}: Pursuit.wander_on(U32.is_eq(U32.and(U32.add(tick,mid),7),0),maps,pos,U32.and(L.Landscape.hash(tick,U32.mul(mid,5)),3),valid)
        case True{}: Pursuit.adjacent_on(Bool.and(U32.is_le(I.Interaction.distance(N.Navigation.x(pos),tx),1),U32.is_le(I.Interaction.distance(N.Navigation.y(pos),ty),1)),maps,pos,pid,tx,ty,tick,mid,attack,damage,valid)

law Pursuit.plan_on:
  for +maps: T.Terrain.Maps
  for +monster: M.Monsters.State
  for +current: Pursuit.Target
  for +tick: U32
  for +damage: U32
  for +valid: H.Habitat.On(maps,monster)
  H.Habitat.PlanOn(maps,H.Habitat.pos(monster),Pursuit.plan(maps,monster,current,tick,damage))

def Pursuit.plan_on(maps,monster,current,tick,damage,valid):
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}:
      Pursuit.target_on(maps,P.Players.Pos{zone,x,y,0,0},current,tick,mid,attack,damage,valid)

law Pursuit.step_on:
  for +maps: T.Terrain.Maps
  for +monster: M.Monsters.State
  for +current: Pursuit.Target
  for +tick: U32
  for +damage: U32
  for +valid: H.Habitat.On(maps,monster)
  H.Habitat.On(maps,A.AI.monster(A.AI.step(monster,Pursuit.plan(maps,monster,current,tick,damage))))

def Pursuit.step_on(maps,monster,current,tick,damage,valid):
  H.Habitat.step_on(maps,monster,Pursuit.plan(maps,monster,current,tick,damage),valid,Pursuit.plan_on(maps,monster,current,tick,damage,valid))

law Pursuit.control_left:
  for +before: P.Players.Pos
  for +after: P.Players.Pos
  for +heading: U32
  for +moving: U32
  for +step: T.Terrain.Cardinal<N.Navigation.control(before,heading,moving),after>
  T.Terrain.Cardinal<before,after>

def Pursuit.control_left(before,after,heading,moving,step):
  match before:
    case P.Players.Pos{zone,x,y,dir,old_moving}:
      match step:
        case T.Terrain.Horizontal{z,sy,nx}: T.Terrain.Horizontal{z,sy,nx}
        case T.Terrain.Vertical{z,sx,ny}: T.Terrain.Vertical{z,sx,ny}

law Pursuit.control_right:
  for +before: P.Players.Pos
  for +after: P.Players.Pos
  for +heading: U32
  for +moving: U32
  for +step: T.Terrain.Cardinal<before,after>
  T.Terrain.Cardinal<before,N.Navigation.control(after,heading,moving)>

def Pursuit.control_right(before,after,heading,moving,step):
  match after:
    case P.Players.Pos{zone,x,y,dir,old_moving}:
      match step:
        case T.Terrain.Horizontal{z,sy,nx}: T.Terrain.Horizontal{z,sy,nx}
        case T.Terrain.Vertical{z,sx,ny}: T.Terrain.Vertical{z,sx,ny}

law Pursuit.walk_cardinal:
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  for +heading: U32
  for +valid: N.Navigation.Bounds<pos>
  T.Terrain.Cardinal<pos,Pursuit.walk(maps,pos,heading)>

def Pursuit.walk_cardinal(maps,pos,heading,valid):
  Pursuit.control_left(pos,Pursuit.walk(maps,pos,heading),heading,1,Pursuit.control_right(N.Navigation.control(pos,heading,1),T.Terrain.mob_move(maps,N.Navigation.control(pos,heading,1)),0,0,T.Terrain.mob_move_cardinal(maps,N.Navigation.control(pos,heading,1),N.Navigation.control_bounds(pos,heading,1,valid))))

law Pursuit.pick_cardinal:
  for +flag: Bool
  for +pos: P.Players.Pos
  for +yes: P.Players.Pos
  for +no: P.Players.Pos
  for +ys: T.Terrain.Cardinal<pos,yes>
  for +ns: T.Terrain.Cardinal<pos,no>
  T.Terrain.Cardinal<pos,Pursuit.pick(flag,yes,no)>

def Pursuit.pick_cardinal(flag,pos,yes,no,ys,ns):
  match flag:
    case True{}: ys
    case False{}: ns

law Pursuit.fallback_cardinal:
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  for +first: P.Players.Pos
  for +heading: U32
  for +other: Bool
  for +valid: N.Navigation.Bounds<pos>
  for +step: T.Terrain.Cardinal<pos,first>
  T.Terrain.Cardinal<pos,Pursuit.fallback(maps,pos,first,heading,other)>

def Pursuit.fallback_cardinal(maps,pos,first,heading,other,valid,step):
  Pursuit.pick_cardinal(Bool.and(Pursuit.same_xy(first,pos),other),pos,Pursuit.walk(maps,pos,heading),first,Pursuit.walk_cardinal(maps,pos,heading,valid),step)

law Pursuit.axes_cardinal:
  for +horizontal: Bool
  for +vertical: Bool
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  for +dh: U32
  for +dv: U32
  for +dx: U32
  for +dy: U32
  for +valid: N.Navigation.Bounds<pos>
  T.Terrain.Cardinal<pos,Pursuit.axes(horizontal,vertical,maps,pos,dh,dv,dx,dy)>

def Pursuit.axes_cardinal(horizontal,vertical,maps,pos,dh,dv,dx,dy,valid):
  match horizontal:
    case True{}: Pursuit.fallback_cardinal(maps,pos,Pursuit.walk(maps,pos,dh),dv,U32.is_gt(dy,0),valid,Pursuit.walk_cardinal(maps,pos,dh,valid))
    case False{}:
      match vertical:
        case True{}: Pursuit.fallback_cardinal(maps,pos,Pursuit.walk(maps,pos,dv),dh,U32.is_gt(dx,0),valid,Pursuit.walk_cardinal(maps,pos,dv,valid))
        case False{}: T.Terrain.self_cardinal(pos)

law Pursuit.toward_cardinal:
  for +maps: T.Terrain.Maps
  for +pos: P.Players.Pos
  for +tx: U32
  for +ty: U32
  for +valid: N.Navigation.Bounds<pos>
  T.Terrain.Cardinal<pos,Pursuit.toward(maps,pos,tx,ty)>

def Pursuit.toward_cardinal(maps,pos,tx,ty,valid):
  +dx = I.Interaction.distance(N.Navigation.x(pos),tx)
  +dy = I.Interaction.distance(N.Navigation.y(pos),ty)
  +dh = L.Landscape.pick(U32.is_gt(tx,N.Navigation.x(pos)),1,0)
  +dv = L.Landscape.pick(U32.is_gt(ty,N.Navigation.y(pos)),3,2)
  Pursuit.axes_cardinal(Bool.and(U32.is_ge(dx,dy),U32.is_gt(dx,0)),U32.is_gt(dy,0),maps,pos,dh,dv,dx,dy,valid)

# The server plans after lifecycle upkeep; upkeep keeps the position exactly.
law Pursuit.ticked_plan_on:
  for +maps: T.Terrain.Maps
  for +monster: M.Monsters.State
  for +current: Pursuit.Target
  for +tick: U32
  for +damage: U32
  for +valid: H.Habitat.On(maps,monster)
  H.Habitat.PlanOn(maps,H.Habitat.pos(monster),Pursuit.plan(maps,M.Monsters.tick_state(M.Monsters.tick(monster)),current,tick,damage))

def Pursuit.ticked_plan_on(maps,monster,current,tick,damage,valid):
  %H.Habitat.tick_position(monster) : H.Habitat.PlanOn(maps,_,Pursuit.plan(maps,M.Monsters.tick_state(M.Monsters.tick(monster)),current,tick,damage))
  Pursuit.plan_on(maps,M.Monsters.tick_state(M.Monsters.tick(monster)),current,tick,damage,H.Habitat.tick_on(maps,monster,valid))

law Pursuit.ticked_step_on:
  for +maps: T.Terrain.Maps
  for +monster: M.Monsters.State
  for +current: Pursuit.Target
  for +tick: U32
  for +damage: U32
  for +valid: H.Habitat.On(maps,monster)
  H.Habitat.On(maps,A.AI.monster(A.AI.step(monster,Pursuit.plan(maps,M.Monsters.tick_state(M.Monsters.tick(monster)),current,tick,damage))))

def Pursuit.ticked_step_on(maps,monster,current,tick,damage,valid):
  H.Habitat.step_on(maps,monster,Pursuit.plan(maps,M.Monsters.tick_state(M.Monsters.tick(monster)),current,tick,damage),valid,Pursuit.ticked_plan_on(maps,monster,current,tick,damage,valid))
