import Base
import ./creation.bend as K
import ./sessions.bend as S
import ./sessions_check.bend as SS
import ./players.bend as P
import ./players_check.bend as Test
import ./simulation.bend as Sim
import ./simulation_check.bend as ST
import ./terrain.bend as T
import ./landscape.bend as L
import ./admission.bend as J

def same_states(left: List<&2,S.Sessions.State>,right: List<&2,S.Sessions.State>) -> Bool:
  match left:
    case Nil{}:
      match right:
        case Nil{}: True{}
        case Con{head,rest}: False{}
    case Con{head,rest}:
      match right:
        case Nil{}: False{}
        case Con{other,later}: Bool.and(SS.same(head,other),same_states(rest,later))

def same_words(a: List<&2,U32>,b: List<&2,U32>) -> Bool:
  match a:
    case Nil{}:
      match b:
        case Nil{}: True{}
        case Con{head,rest}: False{}
    case Con{head,rest}:
      match b:
        case Nil{}: False{}
        case Con{other,later}: Bool.and(U32.is_eq(head,other),same_words(rest,later))

def same_maps(a: T.Terrain.Maps,b: T.Terrain.Maps) -> Bool:
  match a:
    case Nil{}:
      match b:
        case Nil{}: True{}
        case Con{head,rest}: False{}
    case Con{head,rest}:
      match b:
        case Nil{}: False{}
        case Con{other,later}: Bool.and(same_words(head,other),same_maps(rest,later))

def style() -> P.Players.Style: P.Players.Style{1,2,3,4,0,0}
def other_style() -> P.Players.Style: P.Players.Style{3,1,2,5,0,0}
def player(pid: U32,cid: U32,name: String) -> P.Players.State: P.Players.spawn(pid,cid,style,SS.name(name),4,8)
def world(hint: U32,players: List<&2,P.Players.State>) -> Sim.Simulation.State: Sim.Simulation.State{Sim.Simulation.Meta{1,7,0,99,100,200,3,400,hint,450},players,[ST.monster(1,0,0,0)]}

def same(+left: K.Creation.Result,+right: K.Creation.Result) -> Bool: Bool.and(ST.same_state(K.Creation.world(left),K.Creation.world(right)),same_states(K.Creation.states(left),K.Creation.states(right)))

def checked(label: String,before: K.Creation.Result,cid: U32,permitted: Bool,expected: K.Creation.Result) -> IO(Unit):
  match before:
    case K.Creation.Result{before_world,states}: Test.verdict(label,same(K.Creation.create(before_world,states,cid,style,permitted),expected))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- checked("CREATE empty roster",K.Creation.Result{world(1,Nil{}),Nil{}},1,True{},K.Creation.Result{world(1,Nil{}),Nil{}})
    Unit <- checked("CREATE before HELLO",K.Creation.Result{world(1,Nil{}),[SS.state(1,0,0,"")]},1,True{},K.Creation.Result{world(1,Nil{}),[SS.state(1,0,0,"")]})
    Unit <- checked("CREATE create player and binding",K.Creation.Result{world(1,Nil{}),[SS.state(1,1,0,"Ada")]},1,True{},K.Creation.Result{world(2,[player(1,1,"Ada")]),[SS.state(1,2,1,"Ada")]})
    Unit <- checked("CREATE zero hint normalized",K.Creation.Result{world(0,Nil{}),[SS.state(1,1,0,"Ada")]},1,True{},K.Creation.Result{world(2,[player(1,1,"Ada")]),[SS.state(1,2,1,"Ada")]})
    Unit <- checked("CREATE MAX player ID wraps cursor",K.Creation.Result{world(4294967295,Nil{}),[SS.state(1,1,0,"Ada")]},1,True{},K.Creation.Result{world(1,[player(4294967295,1,"Ada")]),[SS.state(1,2,4294967295,"Ada")]})
    Unit <- checked("CREATE MAX connection ID",K.Creation.Result{world(1,Nil{}),[SS.state(4294967295,1,0,"Ada")]},4294967295,True{},K.Creation.Result{world(2,[player(1,4294967295,"Ada")]),[SS.state(4294967295,2,1,"Ada")]})
    Unit <- checked("CREATE existing players retained",K.Creation.Result{world(1,[player(7,3,"Cy")]),[SS.state(3,2,7,"Cy"),SS.state(1,1,0,"Ada")]},1,True{},K.Creation.Result{world(2,[player(1,1,"Ada"),player(7,3,"Cy")]),[SS.state(1,2,1,"Ada"),SS.state(3,2,7,"Cy")]})
    Unit <- checked("CREATE selection after waiting connection",K.Creation.Result{world(1,Nil{}),[SS.state(2,1,0,"Bob"),SS.state(1,1,0,"Ada")]},1,True{},K.Creation.Result{world(2,[player(1,1,"Ada")]),[SS.state(1,2,1,"Ada"),SS.state(2,1,0,"Bob")]})
    Unit <- checked("CREATE selection among waiting and playing",K.Creation.Result{world(1,[player(7,3,"Cy")]),[SS.state(2,1,0,"Bob"),SS.state(3,2,7,"Cy"),SS.state(1,1,0,"Ada")]},1,True{},K.Creation.Result{world(2,[player(1,1,"Ada"),player(7,3,"Cy")]),[SS.state(1,2,1,"Ada"),SS.state(2,1,0,"Bob"),SS.state(3,2,7,"Cy")]})
    Unit <- checked("CREATE repeated CREATE rejected",K.Creation.Result{world(2,[player(1,1,"Ada")]),[SS.state(1,2,1,"Ada")]},1,True{},K.Creation.Result{world(2,[player(1,1,"Ada")]),[SS.state(1,2,1,"Ada")]})
    Unit <- checked("CREATE repeated CREATE moves selected only",K.Creation.Result{world(2,[player(1,1,"Ada")]),[SS.state(2,1,0,"Bob"),SS.state(1,2,1,"Ada")]},1,True{},K.Creation.Result{world(2,[player(1,1,"Ada")]),[SS.state(1,2,1,"Ada"),SS.state(2,1,0,"Bob")]})
    Unit <- checked("CREATE missing CID unchanged",K.Creation.Result{world(1,[player(7,3,"Cy")]),[SS.state(2,1,0,"Bob"),SS.state(3,2,7,"Cy"),SS.state(1,1,0,"Ada")]},99,True{},K.Creation.Result{world(1,[player(7,3,"Cy")]),[SS.state(2,1,0,"Bob"),SS.state(3,2,7,"Cy"),SS.state(1,1,0,"Ada")]})
    Unit <- checked("CREATE cosmetic denial unchanged",K.Creation.Result{world(1,Nil{}),[SS.state(1,1,0,"Ada")]},1,False{},K.Creation.Result{world(1,Nil{}),[SS.state(1,1,0,"Ada")]})
    Unit <- checked("CREATE denial retains selection order",K.Creation.Result{world(1,[player(7,3,"Cy")]),[SS.state(2,1,0,"Bob"),SS.state(3,2,7,"Cy"),SS.state(1,1,0,"Ada")]},1,False{},K.Creation.Result{world(1,[player(7,3,"Cy")]),[SS.state(1,1,0,"Ada"),SS.state(2,1,0,"Bob"),SS.state(3,2,7,"Cy")]})
    Unit <- checked("CREATE zero connection rejected",K.Creation.Result{world(1,Nil{}),[SS.state(0,1,0,"Ada")]},0,True{},K.Creation.Result{world(1,Nil{}),[SS.state(0,1,0,"Ada")]})
    Unit <- checked("CREATE CID already in world rejected",K.Creation.Result{world(2,[player(1,1,"Ada")]),[SS.state(1,1,0,"Ada")]},1,True{},K.Creation.Result{world(2,[player(1,1,"Ada")]),[SS.state(1,1,0,"Ada")]})
    Unit <- checked("CREATE invalid phase rejected",K.Creation.Result{world(1,Nil{}),[SS.state(1,3,0,"Ada")]},1,True{},K.Creation.Result{world(1,Nil{}),[SS.state(1,3,0,"Ada")]})
    Unit <- checked("CREATE MAX phase rejected",K.Creation.Result{world(1,Nil{}),[SS.state(1,4294967295,0,"Ada")]},1,True{},K.Creation.Result{world(1,Nil{}),[SS.state(1,4294967295,0,"Ada")]})
    Unit <- checked("CREATE UTF8 identity retained",K.Creation.Result{world(1,Nil{}),[SS.state(1,1,0,"Étoile")]},1,True{},K.Creation.Result{world(2,[player(1,1,"Étoile")]),[SS.state(1,2,1,"Étoile")]})
    Unit <- checked("CREATE occupied PID skipped",K.Creation.Result{world(1,[player(1,1,"Ada")]),[SS.state(1,2,1,"Ada"),SS.state(2,1,0,"Bob")]},2,True{},K.Creation.Result{world(3,[player(2,2,"Bob"),player(1,1,"Ada")]),[SS.state(2,2,2,"Bob"),SS.state(1,2,1,"Ada")]})
    Unit <- Test.verdict("CREATE trace double CREATE",same(K.Creation.trace([K.Creation.Connect{1},K.Creation.Hello{1,SS.name("Ada")},K.Creation.Create{1,style,True{}},K.Creation.Create{1,style,True{}}],K.Creation.Result{world(1,Nil{}),Nil{}}),K.Creation.Result{world(2,[player(1,1,"Ada")]),[SS.state(1,2,1,"Ada")]}))
    Unit <- Test.verdict("CREATE trace bound rename and CREATE",same(K.Creation.trace([K.Creation.Connect{1},K.Creation.Hello{1,SS.name("Ada")},K.Creation.Create{1,style,True{}},K.Creation.Hello{1,SS.name("Bob")},K.Creation.Create{1,style,True{}}],K.Creation.Result{world(1,Nil{}),Nil{}}),K.Creation.Result{world(2,[player(1,1,"Ada")]),[SS.state(1,2,1,"Ada")]}))
    Unit <- Test.verdict("CREATE trace two players interleaved",same(K.Creation.trace([K.Creation.Connect{1},K.Creation.Connect{2},K.Creation.Hello{1,SS.name("Ada")},K.Creation.Hello{2,SS.name("Bob")},K.Creation.Create{1,style,True{}},K.Creation.Create{2,style,True{}}],K.Creation.Result{world(1,Nil{}),Nil{}}),K.Creation.Result{world(3,[player(2,2,"Bob"),player(1,1,"Ada")]),[SS.state(2,2,2,"Bob"),SS.state(1,2,1,"Ada")]}))
    Unit <- Test.verdict("CREATE trace CREATE before HELLO recovery",same(K.Creation.trace([K.Creation.Connect{1},K.Creation.Create{1,style,True{}},K.Creation.Hello{1,SS.name("Ada")},K.Creation.Create{1,style,True{}}],K.Creation.Result{world(1,Nil{}),Nil{}}),K.Creation.Result{world(2,[player(1,1,"Ada")]),[SS.state(1,2,1,"Ada")]}))
    Unit <- Test.verdict("CREATE trace denied then permitted",same(K.Creation.trace([K.Creation.Connect{1},K.Creation.Hello{1,SS.name("Ada")},K.Creation.Create{1,style,False{}},K.Creation.Create{1,style,True{}}],K.Creation.Result{world(1,Nil{}),Nil{}}),K.Creation.Result{world(2,[player(1,1,"Ada")]),[SS.state(1,2,1,"Ada")]}))
    Unit <- Test.verdict("CREATE trace name collision then correction",same(K.Creation.trace([K.Creation.Connect{1},K.Creation.Hello{1,SS.name("Ada")},K.Creation.Create{1,style,True{}},K.Creation.Connect{2},K.Creation.Hello{2,SS.name("Ada")},K.Creation.Create{2,style,True{}},K.Creation.Hello{2,SS.name("Bob")},K.Creation.Create{2,style,True{}}],K.Creation.Result{world(1,Nil{}),Nil{}}),K.Creation.Result{world(3,[player(2,2,"Bob"),player(1,1,"Ada")]),[SS.state(2,2,2,"Bob"),SS.state(1,2,1,"Ada")]}))
    Test.verdict("CREATE zero-PID finish restores previous world",same(K.Creation.finish(J.Admission.Result{world(99,[player(7,3,"Cy")]),0},world(1,Nil{}),SS.state(1,1,0,"Ada"),[SS.state(2,1,0,"Bob")]),K.Creation.Result{world(1,Nil{}),[SS.state(1,1,0,"Ada"),SS.state(2,1,0,"Bob")]}))

#| PASS CREATE empty roster
#| PASS CREATE before HELLO
#| PASS CREATE create player and binding
#| PASS CREATE zero hint normalized
#| PASS CREATE MAX player ID wraps cursor
#| PASS CREATE MAX connection ID
#| PASS CREATE existing players retained
#| PASS CREATE selection after waiting connection
#| PASS CREATE selection among waiting and playing
#| PASS CREATE repeated CREATE rejected
#| PASS CREATE repeated CREATE moves selected only
#| PASS CREATE missing CID unchanged
#| PASS CREATE cosmetic denial unchanged
#| PASS CREATE denial retains selection order
#| PASS CREATE zero connection rejected
#| PASS CREATE CID already in world rejected
#| PASS CREATE invalid phase rejected
#| PASS CREATE MAX phase rejected
#| PASS CREATE UTF8 identity retained
#| PASS CREATE occupied PID skipped
#| PASS CREATE trace double CREATE
#| PASS CREATE trace bound rename and CREATE
#| PASS CREATE trace two players interleaved
#| PASS CREATE trace CREATE before HELLO recovery
#| PASS CREATE trace denied then permitted
#| PASS CREATE trace name collision then correction
#| PASS CREATE zero-PID finish restores previous world
