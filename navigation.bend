# The actual portal routing rules and bounded-position invariant.
import Base
import ./game.bend as G
import ./players.bend as P
import ./zones.bend as Z

def Navigation.zone(pos: P.Players.Pos) -> U32:
  match pos:
    case P.Players.Pos{zone,x,y,dir,moving}: zone

def Navigation.x(pos: P.Players.Pos) -> U32:
  match pos:
    case P.Players.Pos{zone,x,y,dir,moving}: x

def Navigation.y(pos: P.Players.Pos) -> U32:
  match pos:
    case P.Players.Pos{zone,x,y,dir,moving}: y

def Navigation.pos(player: P.Players.State) -> P.Players.Pos:
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}: pos

def Navigation.width_nat() -> Nat: 30n
def Navigation.height_nat() -> Nat: 17n
def Navigation.width() -> U32: U32.from_nat(Navigation.width_nat)
def Navigation.height() -> U32: U32.from_nat(Navigation.height_nat)

type Navigation.Bounds<-pos: P.Players.Pos> is Data:
  Navigation.Bounds{zone: Z.Zones.Valid<Navigation.zone(pos)>,x: {G.Bq.Nat.lt(U32.to_nat(Navigation.x(pos)),Navigation.width_nat) == True{} : Bool},y: {G.Bq.Nat.lt(U32.to_nat(Navigation.y(pos)),Navigation.height_nat) == True{} : Bool}}

type Navigation.Rules is Data:
  Navigation.Rules{forward_x: U32,forward_y: U32,back_x: U32,back_y: U32}

def Navigation.rules() -> Navigation.Rules: Navigation.Rules{28,8,1,8}

def Navigation.forward_x(rules: Navigation.Rules) -> U32:
  match rules:
    case Navigation.Rules{fx,fy,bx,by}: fx

def Navigation.forward_y(rules: Navigation.Rules) -> U32:
  match rules:
    case Navigation.Rules{fx,fy,bx,by}: fy

def Navigation.back_x(rules: Navigation.Rules) -> U32:
  match rules:
    case Navigation.Rules{fx,fy,bx,by}: bx

def Navigation.back_y(rules: Navigation.Rules) -> U32:
  match rules:
    case Navigation.Rules{fx,fy,bx,by}: by

type Navigation.RulesOK<-rules: Navigation.Rules> is Data:
  Navigation.RulesOK{forward_x: {G.Bq.Nat.lt(U32.to_nat(U32.add(Navigation.back_x(rules),1)),Navigation.width_nat) == True{} : Bool},forward_y: {G.Bq.Nat.lt(U32.to_nat(Navigation.back_y(rules)),Navigation.height_nat) == True{} : Bool},back_x: {G.Bq.Nat.lt(U32.to_nat(U32.sub(Navigation.forward_x(rules),1)),Navigation.width_nat) == True{} : Bool},back_y: {G.Bq.Nat.lt(U32.to_nat(Navigation.forward_y(rules)),Navigation.height_nat) == True{} : Bool}}

law Navigation.rules_ok: Navigation.RulesOK<Navigation.rules>
def Navigation.rules_ok(): Navigation.RulesOK{{==},{==},{==},{==}}

type Navigation.Route is Data:
  Navigation.Stay{}
  Navigation.Sealed{}
  Navigation.Travel{zone: U32,forward: Bool}

def Navigation.pick(condition: Bool, yes: Navigation.Route, no: Navigation.Route) -> Navigation.Route:
  match condition:
    case True{}: yes
    case False{}: no

# The four valid cases use explicit destinations. The final branch retains
# the legacy behavior for invalid source-zone words; validity is not assumed.
def Navigation.route_nat(n: Nat, word: U32, forward: Bool, back: Bool, sigils: U32) -> Navigation.Route:
  match n:
    case Zero{}: Navigation.pick(forward,Navigation.Travel{1,True{}},Navigation.Stay{})
    case Succ{n1}:
      match n1:
        case Zero{}: Navigation.pick(forward,Navigation.Travel{2,True{}},Navigation.pick(back,Navigation.Travel{0,False{}},Navigation.Stay{}))
        case Succ{n2}:
          match n2:
            case Zero{}: Navigation.pick(forward,Navigation.pick(U32.is_eq(sigils,7),Navigation.Travel{3,True{}},Navigation.Sealed{}),Navigation.pick(back,Navigation.Travel{1,False{}},Navigation.Stay{}))
            case Succ{n3}:
              match n3:
                case Zero{}: Navigation.pick(back,Navigation.Travel{2,False{}},Navigation.Stay{})
                case Succ{other}: Navigation.pick(back,Navigation.Travel{U32.sub(word,1),False{}},Navigation.Stay{})

def Navigation.route(+zone: U32, forward: Bool, back: Bool, sigils: U32) -> Navigation.Route:
  Navigation.route_nat(U32.to_nat(zone),zone,forward,back,sigils)

def Navigation.RouteValid(zone: U32, route: Navigation.Route) -> Data:
  match route:
    case Navigation.Stay{}: Z.Zones.Valid<zone>
    case Navigation.Sealed{}: Z.Zones.Valid<zone>
    case Navigation.Travel{dest,forward}: Z.Zones.Valid<dest>

law Navigation.pick_valid:
  for +zone: U32
  for +condition: Bool
  for +yes: Navigation.Route
  for +no: Navigation.Route
  for +yes_ok: Navigation.RouteValid(zone,yes)
  for +no_ok: Navigation.RouteValid(zone,no)
  Navigation.RouteValid(zone,Navigation.pick(condition,yes,no))

def Navigation.pick_valid(zone,condition,yes,no,yes_ok,no_ok):
  match condition:
    case True{}: yes_ok
    case False{}: no_ok

law Navigation.route_valid:
  for +zone: U32
  for +forward: Bool
  for +back: Bool
  for +sigils: U32
  for +valid: Z.Zones.Valid<zone>
  Navigation.RouteValid(zone,Navigation.route(zone,forward,back,sigils))

def Navigation.route_valid(zone,forward,back,sigils,valid):
  match valid:
    case Z.Zones.Hollow{equal}:
      %Equal.sym(U32,zone,0,equal) : Navigation.RouteValid(_,Navigation.route(_,forward,back,sigils))
      Navigation.pick_valid(0,forward,Navigation.Travel{1,True{}},Navigation.Stay{},Z.Zones.Cavern{{==}},Z.Zones.Hollow{{==}})
    case Z.Zones.Cavern{equal}:
      %Equal.sym(U32,zone,1,equal) : Navigation.RouteValid(_,Navigation.route(_,forward,back,sigils))
      Navigation.pick_valid(1,forward,Navigation.Travel{2,True{}},Navigation.pick(back,Navigation.Travel{0,False{}},Navigation.Stay{}),Z.Zones.Frost{{==}},Navigation.pick_valid(1,back,Navigation.Travel{0,False{}},Navigation.Stay{},Z.Zones.Hollow{{==}},Z.Zones.Cavern{{==}}))
    case Z.Zones.Frost{equal}:
      %Equal.sym(U32,zone,2,equal) : Navigation.RouteValid(_,Navigation.route(_,forward,back,sigils))
      Navigation.pick_valid(2,forward,Navigation.pick(U32.is_eq(sigils,7),Navigation.Travel{3,True{}},Navigation.Sealed{}),Navigation.pick(back,Navigation.Travel{1,False{}},Navigation.Stay{}),Navigation.pick_valid(2,U32.is_eq(sigils,7),Navigation.Travel{3,True{}},Navigation.Sealed{},Z.Zones.Rift{{==}},Z.Zones.Frost{{==}}),Navigation.pick_valid(2,back,Navigation.Travel{1,False{}},Navigation.Stay{},Z.Zones.Cavern{{==}},Z.Zones.Frost{{==}}))
    case Z.Zones.Rift{equal}:
      %Equal.sym(U32,zone,3,equal) : Navigation.RouteValid(_,Navigation.route(_,forward,back,sigils))
      Navigation.pick_valid(3,back,Navigation.Travel{2,False{}},Navigation.Stay{},Z.Zones.Frost{{==}},Z.Zones.Rift{{==}})

def Navigation.at(+pos: P.Players.Pos, x: U32, y: U32) -> Bool:
  Bool.and(U32.is_eq(Navigation.x(pos),x),U32.is_eq(Navigation.y(pos),y))

def Navigation.route_for(+pos: P.Players.Pos, sigils: U32, +rules: Navigation.Rules) -> Navigation.Route:
  Navigation.route(Navigation.zone(pos),Navigation.at(pos,Navigation.forward_x(rules),Navigation.forward_y(rules)),Navigation.at(pos,Navigation.back_x(rules),Navigation.back_y(rules)),sigils)

def Navigation.land(route: Navigation.Route, pos: P.Players.Pos, rules: Navigation.Rules) -> P.Players.Pos:
  match route:
    case Navigation.Stay{}: pos
    case Navigation.Sealed{}: pos
    case Navigation.Travel{zone,forward}:
      match forward:
        case True{}:
          match pos:
            case P.Players.Pos{old,x,y,dir,moving}:
              match rules:
                case Navigation.Rules{fx,fy,bx,by}: P.Players.Pos{zone,U32.add(bx,1),by,dir,0}
        case False{}:
          match pos:
            case P.Players.Pos{old,x,y,dir,moving}:
              match rules:
                case Navigation.Rules{fx,fy,bx,by}: P.Players.Pos{zone,U32.sub(fx,1),fy,dir,0}

law Navigation.land_bounds:
  for +route: Navigation.Route
  for +pos: P.Players.Pos
  for +rules: Navigation.Rules
  for +route_ok: Navigation.RouteValid(Navigation.zone(pos),route)
  for +position_ok: Navigation.Bounds<pos>
  for +rules_ok: Navigation.RulesOK<rules>
  Navigation.Bounds<Navigation.land(route,pos,rules)>

def Navigation.land_bounds(route,pos,rules,route_ok,position_ok,rules_ok):
  match route:
    case Navigation.Stay{}: position_ok
    case Navigation.Sealed{}: position_ok
    case Navigation.Travel{zone,forward}:
      match forward:
        case True{}:
          match pos:
            case P.Players.Pos{old,x,y,dir,moving}:
              match rules:
                case Navigation.Rules{fx,fy,bx,by}:
                  match rules_ok:
                    case Navigation.RulesOK{fx_ok,fy_ok,bx_ok,by_ok}: Navigation.Bounds{route_ok,fx_ok,fy_ok}
        case False{}:
          match pos:
            case P.Players.Pos{old,x,y,dir,moving}:
              match rules:
                case Navigation.Rules{fx,fy,bx,by}:
                  match rules_ok:
                    case Navigation.RulesOK{fx_ok,fy_ok,bx_ok,by_ok}: Navigation.Bounds{route_ok,bx_ok,by_ok}

def Navigation.zone_bound(+pos: P.Players.Pos, valid: Navigation.Bounds<pos>) -> Z.Zones.Valid<Navigation.zone(pos)>:
  match valid:
    case Navigation.Bounds{zone,x,y}: zone

law Navigation.cross_bounds:
  for +pos: P.Players.Pos
  for +sigils: U32
  for +valid: Navigation.Bounds<pos>
  Navigation.Bounds<Navigation.land(Navigation.route_for(pos,sigils,Navigation.rules),pos,Navigation.rules)>

def Navigation.cross_bounds(pos,sigils,valid):
  Navigation.land_bounds(Navigation.route_for(pos,sigils,Navigation.rules),pos,Navigation.rules,Navigation.route_valid(Navigation.zone(pos),Navigation.at(pos,28,8),Navigation.at(pos,1,8),sigils,Navigation.zone_bound(pos,valid)),valid,Navigation.rules_ok)

law Navigation.rift_sealed:
  for +back: Bool
  for +sigils: U32
  for +sealed: {U32.is_eq(sigils,7) == False{} : Bool}
  {Navigation.route(2,True{},back,sigils) == Navigation.Sealed{} : Navigation.Route}

def Navigation.rift_sealed(back,sigils,sealed):
  %Equal.sym(Bool,U32.is_eq(sigils,7),False{},sealed) : {Navigation.pick(_,Navigation.Travel{3,True{}},Navigation.Sealed{}) == Navigation.Sealed{} : Navigation.Route}
  {==}

law Navigation.rift_open:
  for +back: Bool
  {Navigation.route(2,True{},back,7) == Navigation.Travel{3,True{}} : Navigation.Route}

def Navigation.rift_open(back): {==}

def Navigation.control(pos: P.Players.Pos, dir: U32, moving: U32) -> P.Players.Pos:
  match pos:
    case P.Players.Pos{zone,x,y,old_dir,old_moving}: P.Players.Pos{zone,x,y,dir,moving}

def Navigation.direction(pos: P.Players.Pos) -> U32:
  match pos:
    case P.Players.Pos{zone,x,y,dir,moving}: dir

law Navigation.control_bounds:
  for +pos: P.Players.Pos
  for +dir: U32
  for +moving: U32
  for +valid: Navigation.Bounds<pos>
  Navigation.Bounds<Navigation.control(pos,dir,moving)>

def Navigation.control_bounds(pos,dir,moving,valid):
  match pos:
    case P.Players.Pos{zone,x,y,old_dir,old_moving}:
      match valid:
        case Navigation.Bounds{zone_ok,x_ok,y_ok}: Navigation.Bounds{zone_ok,x_ok,y_ok}

def Navigation.All(players: List<&2,P.Players.State>) -> Data:
  match players:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,Navigation.Bounds<Navigation.pos(head)>,(bound => Navigation.All(rest))>

law Navigation.swap_bounds:
  for +first: P.Players.State
  for +second: P.Players.State
  for +rest: List<&2,P.Players.State>
  for +valid: Navigation.All(Con{second,Con{first,rest}})
  Navigation.All(Con{first,Con{second,rest}})

def Navigation.swap_bounds(first,second,rest,valid):
  match valid:
    case Tuple{second_ok,tail_ok}:
      match tail_ok:
        case Tuple{first_ok,rest_ok}: Tuple{first_ok,Tuple{second_ok,rest_ok}}

def Navigation.head_bound(+head: P.Players.State, +rest: List<&2,P.Players.State>, valid: Navigation.All(Con{head,rest})) -> Navigation.Bounds<Navigation.pos(head)>:
  match valid:
    case Tuple{head_ok,rest_ok}: head_ok

def Navigation.tail_bounds(+head: P.Players.State, +rest: List<&2,P.Players.State>, valid: Navigation.All(Con{head,rest})) -> Navigation.All(rest):
  match valid:
    case Tuple{head_ok,rest_ok}: rest_ok

law Navigation.perm_bounds:
  for -left: List<&2,P.Players.State>
  for -right: List<&2,P.Players.State>
  for +permutation: P.Players.Perm<left,right>
  for +valid: Navigation.All(right)
  Navigation.All(left)

def Navigation.perm_bounds(left,right,permutation,valid):
  match permutation:
    case P.Players.Same{equal}:
      %Equal.sym(List<&2,P.Players.State>,left,right,equal) : Navigation.All(_)
      valid
    case P.Players.Common{head,lt,rt,ls,rs,tails}:
      %Equal.sym(List<&2,P.Players.State>,left,Con{head,lt},ls) : Navigation.All(_)
      +right_ok = {(%rs : Navigation.All(_); valid) : Navigation.All(Con{head,rt})}
      Tuple{Navigation.head_bound(head,rt,right_ok),Navigation.perm_bounds(lt,rt,tails,Navigation.tail_bounds(head,rt,right_ok))}
    case P.Players.Swap{first,second,rest,ls,rs}:
      %Equal.sym(List<&2,P.Players.State>,left,Con{first,Con{second,rest}},ls) : Navigation.All(_)
      Navigation.swap_bounds(first,second,rest,(%rs : Navigation.All(_); valid))
    case P.Players.Then{middle,before,after}:
      Navigation.perm_bounds(left,middle,before,Navigation.perm_bounds(middle,right,after,valid))

law Navigation.take_bounds:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +valid: Navigation.All(players)
  Navigation.All(P.Players.restore(P.Players.take(players,target)))

def Navigation.take_bounds(players,target,valid):
  Navigation.perm_bounds(P.Players.restore(P.Players.take(players,target)),players,P.Players.take_restores(players,target),valid)

law Navigation.and_zero:
  for +n: Nat
  for +word: Word(n)
  {Word.and(n,word,Word.zero(n)) == Word.zero(n) : Word(n)}

def Navigation.and_zero(n,word):
  match n:
    case Zero{}: {==}
    case Succ{rest}:
      match word:
        case WCon{False{},tail}:
          %Navigation.and_zero(rest,tail) : {WCon{False{},Word.and(rest,tail,Word.zero(rest))} == WCon{False{},_} : Word(Succ{rest})}
          {==}
        case WCon{True{},tail}:
          %Navigation.and_zero(rest,tail) : {WCon{False{},Word.and(rest,tail,Word.zero(rest))} == WCon{False{},_} : Word(Succ{rest})}
          {==}

law Navigation.mask_direction:
  for +direction: U32
  {G.Bq.Nat.lt(U32.to_nat(U32.and(direction,3)),4n) == True{} : Bool}

def Navigation.mask_direction(direction):
  match direction:
    case U32{word}:
      match word:
        case WCon{False{},next}:
          match next:
            case WCon{False{},rest}:
              %Equal.sym(Word(30n),Word.and(30n,rest,Word.zero(30n)),Word.zero(30n),Navigation.and_zero(30n,rest)) : {G.Bq.Nat.lt(U32.to_nat(U32{WCon{False{},WCon{False{},_}}}),4n) == True{} : Bool}
              {==}
            case WCon{True{},rest}:
              %Equal.sym(Word(30n),Word.and(30n,rest,Word.zero(30n)),Word.zero(30n),Navigation.and_zero(30n,rest)) : {G.Bq.Nat.lt(U32.to_nat(U32{WCon{False{},WCon{True{},_}}}),4n) == True{} : Bool}
              {==}
        case WCon{True{},next}:
          match next:
            case WCon{False{},rest}:
              %Equal.sym(Word(30n),Word.and(30n,rest,Word.zero(30n)),Word.zero(30n),Navigation.and_zero(30n,rest)) : {G.Bq.Nat.lt(U32.to_nat(U32{WCon{True{},WCon{False{},_}}}),4n) == True{} : Bool}
              {==}
            case WCon{True{},rest}:
              %Equal.sym(Word(30n),Word.and(30n,rest,Word.zero(30n)),Word.zero(30n),Navigation.and_zero(30n,rest)) : {G.Bq.Nat.lt(U32.to_nat(U32{WCon{True{},WCon{True{},_}}}),4n) == True{} : Bool}
              {==}

law Navigation.control_direction:
  for +pos: P.Players.Pos
  for +direction: U32
  for +moving: U32
  {Navigation.direction(Navigation.control(pos,direction,moving)) == direction : U32}

def Navigation.control_direction(pos,direction,moving):
  match pos:
    case P.Players.Pos{zone,x,y,old_dir,old_moving}: {==}
