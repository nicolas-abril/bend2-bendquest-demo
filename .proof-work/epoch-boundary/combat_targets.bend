# Actual ordered combat target selection over complete monster records.
import Base
import ./monsters.bend as M
import ./roster.bend as R
import ./numeric.bend as N
import ./identity.bend as I
import ./zones.bend as Z

type Targets.Point is Data:
  Targets.Point{zone: U32,x: U32,y: U32}

def Targets.pick(flag: Bool,a: U32,b: U32) -> U32:
  match flag:
    case True{}: a
    case False{}: b

def Targets.maximum(+a: U32,+b: U32) -> U32: Targets.pick(U32.is_lt(a,b),b,a)
def Targets.minimum(+a: U32,+b: U32) -> U32: Targets.pick(U32.is_lt(a,b),a,b)
def Targets.delta(+a: U32,+b: U32) -> U32: U32.sub(Targets.maximum(a,b),Targets.minimum(a,b))
def Targets.distance(ax: U32,ay: U32,bx: U32,by: U32) -> U32: Targets.maximum(Targets.delta(ax,bx),Targets.delta(ay,by))

def Targets.zone(point: Targets.Point) -> U32:
  match point:
    case Targets.Point{zone,x,y}: zone

def Targets.dead(monster: M.Monsters.State) -> U32:
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}: dead

def Targets.reach(monster: M.Monsters.State,point: Targets.Point) -> Bool:
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}:
      match point:
        case Targets.Point{pz,px,py}: U32.is_le(Targets.distance(x,y,px,py),1)

def Targets.eligible(+monster: M.Monsters.State,+point: Targets.Point) -> Bool:
  Bool.and(Bool.and(U32.is_eq(R.Roster.zone_of(monster),Targets.zone(point)),U32.is_eq(Targets.dead(monster),0)),Targets.reach(monster,point))

def Targets.gate(flag: Bool,head: M.Monsters.State,tail: List<&2,M.Monsters.State>) -> List<&2,M.Monsters.State>:
  match flag:
    case True{}: Con{head,tail}
    case False{}: tail

def Targets.filter(monsters: List<&2,M.Monsters.State>,+point: Targets.Point) -> List<&2,M.Monsters.State>:
  match monsters:
    case Nil{}: Nil{}
    case Con{head,rest}:
      +head = head
      Targets.gate(Targets.eligible(head,point),head,Targets.filter(rest,point))

def Targets.ids(monsters: List<&2,M.Monsters.State>) -> List<&1,U32>:
  match monsters:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{R.Roster.id(head),Targets.ids(rest)}

def Targets.all_ids(monsters: List<&2,M.Monsters.State>,point: Targets.Point) -> List<&1,U32>: Targets.ids(Targets.filter(monsters,point))

def Targets.head(monsters: List<&2,M.Monsters.State>) -> Maybe<&2,M.Monsters.State>:
  match monsters:
    case Nil{}: None{}
    case Con{head,rest}: Some{head}

# Short circuit as soon as a target is found, without building the full filter.
def Targets.scan(tail: List<&2,M.Monsters.State>,head: M.Monsters.State,flag: Bool,+point: Targets.Point) -> Maybe<&2,M.Monsters.State>:
  match tail:
    case Nil{}:
      match flag:
        case True{}: Some{head}
        case False{}: None{}
    case Con{next,rest}:
      match flag:
        case True{}: Some{head}
        case False{}:
          +next = next
          Targets.scan(rest,next,Targets.eligible(next,point),point)

def Targets.first(monsters: List<&2,M.Monsters.State>,+point: Targets.Point) -> Maybe<&2,M.Monsters.State>:
  match monsters:
    case Nil{}: None{}
    case Con{head,rest}:
      +head = head
      Targets.scan(rest,head,Targets.eligible(head,point),point)

def Targets.found_id(found: Maybe<&2,M.Monsters.State>) -> U32:
  match found:
    case None{}: 0
    case Some{monster}: R.Roster.id(monster)

def Targets.first_id(monsters: List<&2,M.Monsters.State>,point: Targets.Point) -> U32: Targets.found_id(Targets.first(monsters,point))

type Targets.In<-monster: M.Monsters.State,-monsters: List<&2,M.Monsters.State>> is Data:
  Targets.Here{rest: List<&2,M.Monsters.State>,shape: {monsters == Con{monster,rest} : List<&2,M.Monsters.State>}}
  Targets.There{head: M.Monsters.State,rest: List<&2,M.Monsters.State>,shape: {monsters == Con{head,rest} : List<&2,M.Monsters.State>},inside: Targets.In<monster,rest>}

type Targets.Source<-monsters: List<&2,M.Monsters.State>,-point: Targets.Point,-monster: M.Monsters.State> is Data:
  Targets.Source{inside: Targets.In<monster,monsters>,eligible: {Targets.eligible(monster,point) == True{} : Bool}}

def Targets.Sources(+monsters: List<&2,M.Monsters.State>,+point: Targets.Point,selected: List<&2,M.Monsters.State>) -> Data:
  match selected:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,Targets.Source<monsters,point,head>,(source => Targets.Sources(monsters,point,rest))>

def Targets.FoundSource(monsters: List<&2,M.Monsters.State>,point: Targets.Point,found: Maybe<&2,M.Monsters.State>) -> Data:
  match found:
    case None{}: Unit
    case Some{monster}: Targets.Source<monsters,point,monster>

law Targets.and_left:
  for +a: Bool
  for +b: Bool
  for +valid: {Bool.and(a,b) == True{} : Bool}
  {a == True{} : Bool}

def Targets.and_left(a,b,valid):
  match a:
    case True{}: {==}
    case False{}: valid

law Targets.and_right:
  for +a: Bool
  for +b: Bool
  for +valid: {Bool.and(a,b) == True{} : Bool}
  {b == True{} : Bool}

def Targets.and_right(a,b,valid):
  match a:
    case True{}: valid
    case False{}: Empty.absurd({b == True{} : Bool},N.Numeric.true_ne_false(Equal.sym(Bool,False{},True{},valid)))

law Targets.eligible_zone:
  for +monster: M.Monsters.State
  for +point: Targets.Point
  for +valid: {Targets.eligible(monster,point) == True{} : Bool}
  {R.Roster.zone_of(monster) == Targets.zone(point) : U32}

def Targets.eligible_zone(monster,point,valid):
  N.Numeric.u32_eq_sound(R.Roster.zone_of(monster),Targets.zone(point),Targets.and_left(U32.is_eq(R.Roster.zone_of(monster),Targets.zone(point)),U32.is_eq(Targets.dead(monster),0),Targets.and_left(Bool.and(U32.is_eq(R.Roster.zone_of(monster),Targets.zone(point)),U32.is_eq(Targets.dead(monster),0)),Targets.reach(monster,point),valid)))

law Targets.eligible_alive:
  for +monster: M.Monsters.State
  for +point: Targets.Point
  for +valid: {Targets.eligible(monster,point) == True{} : Bool}
  {Targets.dead(monster) == 0 : U32}

def Targets.eligible_alive(monster,point,valid):
  N.Numeric.u32_eq_sound(Targets.dead(monster),0,Targets.and_right(U32.is_eq(R.Roster.zone_of(monster),Targets.zone(point)),U32.is_eq(Targets.dead(monster),0),Targets.and_left(Bool.and(U32.is_eq(R.Roster.zone_of(monster),Targets.zone(point)),U32.is_eq(Targets.dead(monster),0)),Targets.reach(monster,point),valid)))

law Targets.eligible_reach:
  for +monster: M.Monsters.State
  for +point: Targets.Point
  for +valid: {Targets.eligible(monster,point) == True{} : Bool}
  {Targets.reach(monster,point) == True{} : Bool}

def Targets.eligible_reach(monster,point,valid): Targets.and_right(Bool.and(U32.is_eq(R.Roster.zone_of(monster),Targets.zone(point)),U32.is_eq(Targets.dead(monster),0)),Targets.reach(monster,point),valid)

law Targets.weaken_source:
  for +head: M.Monsters.State
  for +monsters: List<&2,M.Monsters.State>
  for +point: Targets.Point
  for +monster: M.Monsters.State
  for +source: Targets.Source<monsters,point,monster>
  Targets.Source<Con{head,monsters},point,monster>

def Targets.weaken_source(head,monsters,point,monster,source):
  match source:
    case Targets.Source{inside,eligible}: Targets.Source{Targets.There{head,monsters,{==},inside},eligible}

law Targets.weaken_sources:
  for +selected: List<&2,M.Monsters.State>
  for +head: M.Monsters.State
  for +monsters: List<&2,M.Monsters.State>
  for +point: Targets.Point
  for +sources: Targets.Sources(monsters,point,selected)
  Targets.Sources(Con{head,monsters},point,selected)

def Targets.weaken_sources(selected,head,monsters,point,sources):
  match selected:
    case Nil{}: Unit{}
    case Con{monster,rest}:
      match sources:
        case Tuple{source,remaining}: Tuple{Targets.weaken_source(head,monsters,point,monster,source),Targets.weaken_sources(rest,head,monsters,point,remaining)}

law Targets.gate_sources:
  for +flag: Bool
  for +head: M.Monsters.State
  for +monsters: List<&2,M.Monsters.State>
  for +point: Targets.Point
  for +selected: List<&2,M.Monsters.State>
  for +decision: {Targets.eligible(head,point) == flag : Bool}
  for +sources: Targets.Sources(Con{head,monsters},point,selected)
  Targets.Sources(Con{head,monsters},point,Targets.gate(flag,head,selected))

def Targets.gate_sources(flag,head,monsters,point,selected,decision,sources):
  match flag:
    case True{}: Tuple{Targets.Source{Targets.Here{monsters,{==}},decision},sources}
    case False{}: sources

law Targets.filter_sources:
  for +monsters: List<&2,M.Monsters.State>
  for +point: Targets.Point
  Targets.Sources(monsters,point,Targets.filter(monsters,point))

def Targets.filter_sources(monsters,point):
  match monsters:
    case Nil{}: Unit{}
    case Con{head,rest}: Targets.gate_sources(Targets.eligible(head,point),head,rest,point,Targets.filter(rest,point),{==},Targets.weaken_sources(Targets.filter(rest,point),head,rest,point,Targets.filter_sources(rest,point)))

law Targets.scan_filter:
  for +tail: List<&2,M.Monsters.State>
  for +head: M.Monsters.State
  for +flag: Bool
  for +point: Targets.Point
  {Targets.scan(tail,head,flag,point) == Targets.head(Targets.gate(flag,head,Targets.filter(tail,point))) : Maybe<&2,M.Monsters.State>}

def Targets.scan_filter(tail,head,flag,point):
  match tail:
    case Nil{}:
      match flag:
        case True{}: {==}
        case False{}: {==}
    case Con{next,rest}:
      match flag:
        case True{}: {==}
        case False{}: Targets.scan_filter(rest,next,Targets.eligible(next,point),point)

law Targets.first_filter:
  for +monsters: List<&2,M.Monsters.State>
  for +point: Targets.Point
  {Targets.first(monsters,point) == Targets.head(Targets.filter(monsters,point)) : Maybe<&2,M.Monsters.State>}

def Targets.first_filter(monsters,point):
  match monsters:
    case Nil{}: {==}
    case Con{head,rest}: Targets.scan_filter(rest,head,Targets.eligible(head,point),point)

law Targets.head_source:
  for +selected: List<&2,M.Monsters.State>
  for +monsters: List<&2,M.Monsters.State>
  for +point: Targets.Point
  for +sources: Targets.Sources(monsters,point,selected)
  Targets.FoundSource(monsters,point,Targets.head(selected))

def Targets.head_source(selected,monsters,point,sources):
  match selected:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match sources:
        case Tuple{source,remaining}: source

law Targets.first_source:
  for +monsters: List<&2,M.Monsters.State>
  for +point: Targets.Point
  Targets.FoundSource(monsters,point,Targets.first(monsters,point))

def Targets.first_source(monsters,point):
  %Equal.sym(Maybe<&2,M.Monsters.State>,Targets.first(monsters,point),Targets.head(Targets.filter(monsters,point)),Targets.first_filter(monsters,point)) : Targets.FoundSource(monsters,point,_)
  Targets.head_source(Targets.filter(monsters,point),monsters,point,Targets.filter_sources(monsters,point))

law Targets.gate_contains:
  for +flag: Bool
  for +head: M.Monsters.State
  for +tail: List<&2,M.Monsters.State>
  for +monster: M.Monsters.State
  for +inside: Targets.In<monster,tail>
  Targets.In<monster,Targets.gate(flag,head,tail)>

def Targets.gate_contains(flag,head,tail,monster,inside):
  match flag:
    case True{}: Targets.There{head,tail,{==},inside}
    case False{}: inside

law Targets.filter_complete:
  for +monster: M.Monsters.State
  for -monsters: List<&2,M.Monsters.State>
  for +point: Targets.Point
  for +inside: Targets.In<monster,monsters>
  for +eligible: {Targets.eligible(monster,point) == True{} : Bool}
  Targets.In<monster,Targets.filter(monsters,point)>

def Targets.filter_complete(monster,monsters,point,inside,eligible):
  match inside:
    case Targets.Here{rest,shape}:
      %Equal.sym(List<&2,M.Monsters.State>,monsters,Con{monster,rest},shape) : Targets.In<monster,Targets.filter(_,point)>
      %Equal.sym(Bool,Targets.eligible(monster,point),True{},eligible) : Targets.In<monster,Targets.gate(_,monster,Targets.filter(rest,point))>
      Targets.Here{Targets.filter(rest,point),{==}}
    case Targets.There{head,rest,shape,earlier}:
      %Equal.sym(List<&2,M.Monsters.State>,monsters,Con{head,rest},shape) : Targets.In<monster,Targets.filter(_,point)>
      Targets.gate_contains(Targets.eligible(head,point),head,Targets.filter(rest,point),monster,Targets.filter_complete(monster,rest,point,earlier,eligible))

law Targets.gate_absent:
  for +flag: Bool
  for +head: M.Monsters.State
  for +tail: List<&2,M.Monsters.State>
  for +id: U32
  for +different: {U32.is_eq(id,I.Identity.mid(Z.Zones.key(head))) == False{} : Bool}
  for +absent: I.Identity.Absent(id,Z.Zones.keys(tail))
  I.Identity.Absent(id,Z.Zones.keys(Targets.gate(flag,head,tail)))

def Targets.gate_absent(flag,head,tail,id,different,absent):
  match flag:
    case True{}: Tuple{different,absent}
    case False{}: absent

law Targets.filter_absent:
  for +monsters: List<&2,M.Monsters.State>
  for +point: Targets.Point
  for +id: U32
  for +absent: I.Identity.Absent(id,Z.Zones.keys(monsters))
  I.Identity.Absent(id,Z.Zones.keys(Targets.filter(monsters,point)))

def Targets.filter_absent(monsters,point,id,absent):
  match monsters:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match absent:
        case Tuple{different,later}: Targets.gate_absent(Targets.eligible(head,point),head,Targets.filter(rest,point),id,different,Targets.filter_absent(rest,point,id,later))

law Targets.gate_unique:
  for +flag: Bool
  for +head: M.Monsters.State
  for +tail: List<&2,M.Monsters.State>
  for +absent: I.Identity.Absent(I.Identity.mid(Z.Zones.key(head)),Z.Zones.keys(tail))
  for +unique: I.Identity.Monsters(tail)
  I.Identity.Monsters(Targets.gate(flag,head,tail))

def Targets.gate_unique(flag,head,tail,absent,unique):
  match flag:
    case True{}: Tuple{absent,unique}
    case False{}: unique

law Targets.filter_unique:
  for +monsters: List<&2,M.Monsters.State>
  for +point: Targets.Point
  for +unique: I.Identity.Monsters(monsters)
  I.Identity.Monsters(Targets.filter(monsters,point))

def Targets.filter_unique(monsters,point,unique):
  match monsters:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match unique:
        case Tuple{absent,later}: Targets.gate_unique(Targets.eligible(head,point),head,Targets.filter(rest,point),Targets.filter_absent(rest,point,I.Identity.mid(Z.Zones.key(head)),absent),Targets.filter_unique(rest,point,later))

law Targets.key_id:
  for +monster: M.Monsters.State
  {I.Identity.mid(Z.Zones.key(monster)) == R.Roster.id(monster) : U32}

def Targets.key_id(monster):
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}: {==}

law Targets.absent_member:
  for +monster: M.Monsters.State
  for -monsters: List<&2,M.Monsters.State>
  for +id: U32
  for +inside: Targets.In<monster,monsters>
  for +absent: I.Identity.Absent(id,Z.Zones.keys(monsters))
  {U32.is_eq(id,R.Roster.id(monster)) == False{} : Bool}

def Targets.absent_member(monster,monsters,id,inside,absent):
  match inside:
    case Targets.Here{rest,shape}:
      %Targets.key_id(monster) : {U32.is_eq(id,_) == False{} : Bool}
      I.Identity.absent_head(id,Z.Zones.key(monster),Z.Zones.keys(rest),(%shape : I.Identity.Absent(id,Z.Zones.keys(_)); absent))
    case Targets.There{head,rest,shape,earlier}:
      Targets.absent_member(monster,rest,id,earlier,I.Identity.absent_tail(id,Z.Zones.key(head),Z.Zones.keys(rest),(%shape : I.Identity.Absent(id,Z.Zones.keys(_)); absent)))

law Targets.scan_skip:
  for +tail: List<&2,M.Monsters.State>
  for +head: M.Monsters.State
  for +id: U32
  {R.Roster.found(R.Roster.scan(tail,head,False{},id)) == R.Roster.found(R.Roster.take(tail,id)) : Maybe<&2,M.Monsters.State>}

def Targets.scan_skip(tail,head,id):
  match tail:
    case Nil{}: {==}
    case Con{next,rest}: R.Roster.prepend_found(head,R.Roster.scan(rest,next,U32.is_eq(R.Roster.id(next),id),id))

# A selected full record is the record later found by its ID, given the
# authoritative unique-MID invariant. Duplicate IDs need this explicit premise.
law Targets.lookup_member:
  for +monster: M.Monsters.State
  for -monsters: List<&2,M.Monsters.State>
  for +inside: Targets.In<monster,monsters>
  for +unique: I.Identity.Monsters(monsters)
  {R.Roster.found(R.Roster.take(monsters,R.Roster.id(monster))) == Some{monster} : Maybe<&2,M.Monsters.State>}

def Targets.lookup_member(monster,monsters,inside,unique):
  match inside:
    case Targets.Here{rest,shape}:
      %Equal.sym(List<&2,M.Monsters.State>,monsters,Con{monster,rest},shape) : {R.Roster.found(R.Roster.take(_,R.Roster.id(monster))) == Some{monster} : Maybe<&2,M.Monsters.State>}
      Equal.cong(R.Roster.Take,Maybe<&2,M.Monsters.State>,(taken => R.Roster.found(taken)),R.Roster.take(Con{monster,rest},R.Roster.id(monster)),R.Roster.Take{rest,Some{monster}},R.Roster.take_head(monster,rest))
    case Targets.There{head,rest,shape,earlier}:
      +valid = {(%shape : I.Identity.Monsters(_); unique) : I.Identity.Monsters(Con{head,rest})}
      +different = {(%Targets.key_id(head) : {U32.is_eq(_,R.Roster.id(monster)) == False{} : Bool}; Targets.absent_member(monster,rest,I.Identity.mid(Z.Zones.key(head)),earlier,I.Identity.unique_head(Z.Zones.key(head),Z.Zones.keys(rest),valid))) : {U32.is_eq(R.Roster.id(head),R.Roster.id(monster)) == False{} : Bool}}
      %Equal.sym(List<&2,M.Monsters.State>,monsters,Con{head,rest},shape) : {R.Roster.found(R.Roster.take(_,R.Roster.id(monster))) == Some{monster} : Maybe<&2,M.Monsters.State>}
      %Equal.sym(Bool,U32.is_eq(R.Roster.id(head),R.Roster.id(monster)),False{},different) : {R.Roster.found(R.Roster.scan(rest,head,_,R.Roster.id(monster))) == Some{monster} : Maybe<&2,M.Monsters.State>}
      Equal.trans(Maybe<&2,M.Monsters.State>,R.Roster.found(R.Roster.scan(rest,head,False{},R.Roster.id(monster))),R.Roster.found(R.Roster.take(rest,R.Roster.id(monster))),Some{monster},Targets.scan_skip(rest,head,R.Roster.id(monster)),Targets.lookup_member(monster,rest,earlier,I.Identity.unique_tail(Z.Zones.key(head),Z.Zones.keys(rest),valid)))

type Targets.IDSource<-monsters: List<&2,M.Monsters.State>,-point: Targets.Point,-id: U32> is Data:
  Targets.IDSource{monster: M.Monsters.State,exact: {R.Roster.id(monster) == id : U32},source: Targets.Source<monsters,point,monster>,lookup: {R.Roster.found(R.Roster.take(monsters,id)) == Some{monster} : Maybe<&2,M.Monsters.State>}}

def Targets.IDSources(+monsters: List<&2,M.Monsters.State>,+point: Targets.Point,ids: List<&1,U32>) -> Data:
  match ids:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,Targets.IDSource<monsters,point,head>,(source => Targets.IDSources(monsters,point,rest))>

law Targets.ids_sources:
  for +selected: List<&2,M.Monsters.State>
  for +monsters: List<&2,M.Monsters.State>
  for +point: Targets.Point
  for +sources: Targets.Sources(monsters,point,selected)
  for +unique: I.Identity.Monsters(monsters)
  Targets.IDSources(monsters,point,Targets.ids(selected))

def Targets.ids_sources(selected,monsters,point,sources,unique):
  match selected:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match sources:
        case Tuple{source,remaining}:
          match source:
            case Targets.Source{inside,eligible}: Tuple{Targets.IDSource{head,{==},Targets.Source{inside,eligible},Targets.lookup_member(head,monsters,inside,unique)},Targets.ids_sources(rest,monsters,point,remaining,unique)}

law Targets.all_ids_sources:
  for +monsters: List<&2,M.Monsters.State>
  for +point: Targets.Point
  for +unique: I.Identity.Monsters(monsters)
  Targets.IDSources(monsters,point,Targets.all_ids(monsters,point))

def Targets.all_ids_sources(monsters,point,unique): Targets.ids_sources(Targets.filter(monsters,point),monsters,point,Targets.filter_sources(monsters,point),unique)

def Targets.FirstLookup(monsters: List<&2,M.Monsters.State>,point: Targets.Point,found: Maybe<&2,M.Monsters.State>) -> Data:
  match found:
    case None{}: Unit
    case Some{monster}: Targets.IDSource<monsters,point,R.Roster.id(monster)>

law Targets.found_lookup:
  for +found: Maybe<&2,M.Monsters.State>
  for +monsters: List<&2,M.Monsters.State>
  for +point: Targets.Point
  for +source: Targets.FoundSource(monsters,point,found)
  for +unique: I.Identity.Monsters(monsters)
  Targets.FirstLookup(monsters,point,found)

def Targets.found_lookup(found,monsters,point,source,unique):
  match found:
    case None{}: Unit{}
    case Some{monster}:
      match source:
        case Targets.Source{inside,eligible}: Targets.IDSource{monster,{==},Targets.Source{inside,eligible},Targets.lookup_member(monster,monsters,inside,unique)}

law Targets.first_lookup:
  for +monsters: List<&2,M.Monsters.State>
  for +point: Targets.Point
  for +unique: I.Identity.Monsters(monsters)
  Targets.FirstLookup(monsters,point,Targets.first(monsters,point))

def Targets.first_lookup(monsters,point,unique): Targets.found_lookup(Targets.first(monsters,point),monsters,point,Targets.first_source(monsters,point),unique)

# Order-preserving subsequence, independent of eligibility.
type Targets.Subsequence<-selected: List<&2,M.Monsters.State>,-original: List<&2,M.Monsters.State>> is Data:
  Targets.End{empty: {selected == Nil{} : List<&2,M.Monsters.State>}}
  Targets.Keep{head: M.Monsters.State,chosen: List<&2,M.Monsters.State>,tail: List<&2,M.Monsters.State>,left: {selected == Con{head,chosen} : List<&2,M.Monsters.State>},right: {original == Con{head,tail} : List<&2,M.Monsters.State>},rest: Targets.Subsequence<chosen,tail>}
  Targets.Skip{head: M.Monsters.State,tail: List<&2,M.Monsters.State>,right: {original == Con{head,tail} : List<&2,M.Monsters.State>},rest: Targets.Subsequence<selected,tail>}

law Targets.gate_subsequence:
  for +flag: Bool
  for +head: M.Monsters.State
  for +selected: List<&2,M.Monsters.State>
  for +tail: List<&2,M.Monsters.State>
  for +rest: Targets.Subsequence<selected,tail>
  Targets.Subsequence<Targets.gate(flag,head,selected),Con{head,tail}>

def Targets.gate_subsequence(flag,head,selected,tail,rest):
  match flag:
    case True{}: Targets.Keep{head,selected,tail,{==},{==},rest}
    case False{}: Targets.Skip{head,tail,{==},rest}

law Targets.filter_subsequence:
  for +monsters: List<&2,M.Monsters.State>
  for +point: Targets.Point
  Targets.Subsequence<Targets.filter(monsters,point),monsters>

def Targets.filter_subsequence(monsters,point):
  match monsters:
    case Nil{}: Targets.End{{==}}
    case Con{head,rest}: Targets.gate_subsequence(Targets.eligible(head,point),head,Targets.filter(rest,point),rest,Targets.filter_subsequence(rest,point))

def Targets.empty(monsters: List<&2,M.Monsters.State>) -> Bool:
  match monsters:
    case Nil{}: True{}
    case Con{head,rest}: False{}

def Targets.Rejected(monsters: List<&2,M.Monsters.State>,+point: Targets.Point) -> Data:
  match monsters:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,{Targets.eligible(head,point) == False{} : Bool},(rejected => Targets.Rejected(rest,point))>

law Targets.gate_empty:
  for +flag: Bool
  for +head: M.Monsters.State
  for +tail: List<&2,M.Monsters.State>
  for +empty: {Targets.empty(Targets.gate(flag,head,tail)) == True{} : Bool}
  {flag == False{} : Bool} & {Targets.empty(tail) == True{} : Bool}

def Targets.gate_empty(flag,head,tail,empty):
  match flag:
    case False{}: Tuple{{==},empty}
    case True{}: Empty.absurd({True{} == False{} : Bool} & {Targets.empty(tail) == True{} : Bool},N.Numeric.true_ne_false(Equal.sym(Bool,False{},True{},empty)))

def Targets.empty_flag(-flag: Bool,-tail: List<&2,M.Monsters.State>,both: {flag == False{} : Bool} & {Targets.empty(tail) == True{} : Bool}) -> {flag == False{} : Bool}:
  match both:
    case Tuple{rejected,remaining}: rejected

def Targets.empty_tail(-flag: Bool,-tail: List<&2,M.Monsters.State>,both: {flag == False{} : Bool} & {Targets.empty(tail) == True{} : Bool}) -> {Targets.empty(tail) == True{} : Bool}:
  match both:
    case Tuple{rejected,remaining}: remaining

law Targets.filter_empty:
  for +monsters: List<&2,M.Monsters.State>
  for +point: Targets.Point
  for +empty: {Targets.empty(Targets.filter(monsters,point)) == True{} : Bool}
  Targets.Rejected(monsters,point)

def Targets.filter_empty(monsters,point,empty):
  match monsters:
    case Nil{}: Unit{}
    case Con{head,rest}: Tuple{Targets.empty_flag(Targets.eligible(head,point),Targets.filter(rest,point),Targets.gate_empty(Targets.eligible(head,point),head,Targets.filter(rest,point),empty)),Targets.filter_empty(rest,point,Targets.empty_tail(Targets.eligible(head,point),Targets.filter(rest,point),Targets.gate_empty(Targets.eligible(head,point),head,Targets.filter(rest,point),empty)))}

law Targets.head_none:
  for +monsters: List<&2,M.Monsters.State>
  for +none: {Targets.head(monsters) == None{} : Maybe<&2,M.Monsters.State>}
  {Targets.empty(monsters) == True{} : Bool}

def Targets.head_none(monsters,none):
  match monsters:
    case Nil{}: {==}
    case Con{head,rest}: Empty.absurd({False{} == True{} : Bool},N.Numeric.true_ne_false(Equal.cong(Maybe<&2,M.Monsters.State>,Bool,(found => R.Roster.has(found)),Some{head},None{},none)))

law Targets.first_none_rejected:
  for +monsters: List<&2,M.Monsters.State>
  for +point: Targets.Point
  for +none: {Targets.first(monsters,point) == None{} : Maybe<&2,M.Monsters.State>}
  Targets.Rejected(monsters,point)

def Targets.first_none_rejected(monsters,point,none):
  Targets.filter_empty(monsters,point,Targets.head_none(Targets.filter(monsters,point),Equal.trans(Maybe<&2,M.Monsters.State>,Targets.head(Targets.filter(monsters,point)),Targets.first(monsters,point),None{},Equal.sym(Maybe<&2,M.Monsters.State>,Targets.first(monsters,point),Targets.head(Targets.filter(monsters,point)),Targets.first_filter(monsters,point)),none)))
