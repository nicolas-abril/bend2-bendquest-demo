import Base
import ./allocation.bend as A
import ./admission.bend as J
import ./players.bend as P
import ./terrain.bend as T
import ./simulation.bend as S
import ./world.bend as W
import ./compat.bend as C
import ./players_check.bend as Test
import ./simulation_check.bend as ST

def choice(label: String,result: Maybe<&2,A.Allocation.Choice>,id: U32,next: U32) -> IO(Unit):
  match result:
    case None{}: Test.verdict(label,False{})
    case Some{found}:
      match found:
        case A.Allocation.Choice{actual,cursor}: Test.verdict(label,Bool.and(U32.is_eq(actual,id),U32.is_eq(cursor,next)))

def exhausted(result: Maybe<&2,A.Allocation.Choice>) -> Bool:
  match result:
    case None{}: True{}
    case Some{found}: False{}

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

def same_world(+a: T.Terrain.World,+b: T.Terrain.World) -> Bool:
  Bool.and(ST.same_state(T.Terrain.simulation(a),T.Terrain.simulation(b)),same_maps(T.Terrain.maps(a),T.Terrain.maps(b)))

def style() -> P.Players.Style: P.Players.Style{1,2,3,4,5,6}

def player(pid: U32,cid: U32) -> P.Players.State: P.Players.spawn(pid,cid,style,Test.name,4,8)

def world(hint: U32,players: List<&2,P.Players.State>) -> T.Terrain.World:
  T.Terrain.World{S.Simulation.Meta{1,7,41,99,100,200,3,400,hint,450},players,[ST.monster(1,0,0,0)],[[9,8],[7]]}

@unsafe
def added(input: T.Terrain.World,cid: U32) -> T.Terrain.World & U32:
  W.Bq.add_plr(input,cid,1,2,3,4,5,6,P.Players.text_name(Test.name))

@unsafe
def checked(label: String,result: T.Terrain.World & U32,expected: T.Terrain.World,pid: U32) -> IO(Unit):
  match result:
    case Tuple{actual,found}: Test.verdict(label,Bool.and(U32.is_eq(found,pid),same_world(actual,expected)))

@unsafe
def again(result: T.Terrain.World & U32,cid: U32) -> T.Terrain.World & U32:
  match result:
    case Tuple{world,pid}: added(world,cid)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- choice("allocator normal hint",A.Allocation.find(Nil{},7),7,8)
    Unit <- choice("allocator skips zero",A.Allocation.find(Nil{},0),1,2)
    Unit <- choice("allocator maximum hint wraps cursor",A.Allocation.find(Nil{},4294967295),4294967295,1)
    Unit <- choice("allocator skips occupied IDs",A.Allocation.find([1,2,3],1),4,5)
    Unit <- choice("allocator wraps and skips live IDs",A.Allocation.find([4294967295,1,2],4294967295),3,4)
    Unit <- choice("allocator finds wrapped gap",A.Allocation.find([4294967295,1,3],4294967295),2,3)
    Unit <- choice("allocator tolerates duplicate input IDs",A.Allocation.find([1,1,2,2],1),3,4)
    Unit <- choice("allocator ignores occupied zero",A.Allocation.find([0,1,2],0),3,4)
    Unit <- choice("allocator retains free hint below occupied IDs",A.Allocation.find([8,9,10],7),7,8)
    Unit <- choice("allocator crosses maximum boundary",A.Allocation.find([4294967294,4294967295],4294967294),1,2)
    Unit <- choice("allocator checks all candidates within budget",A.Allocation.find([3,2,1],1),4,5)
    Unit <- Test.verdict("allocator bounded search reports failure",exhausted(A.Allocation.scan(2n,[1,2],1,True{})))
    Unit <- Test.verdict("allocator zero budget reports failure",exhausted(A.Allocation.scan(0n,Nil{},1,False{})))
    Unit <- checked("server player allocation preserves full world",added(world(7,Nil{}),20),world(8,[player(7,20)]),7)
    Unit <- checked("server player allocation normalizes zero",added(world(0,Nil{}),20),world(2,[player(1,20)]),1)
    Unit <- checked("server player allocation wraps cursor",added(world(4294967295,Nil{}),20),world(1,[player(4294967295,20)]),4294967295)
    Unit <- checked("server allocation skips occupied player ID",added(world(7,[player(7,17)]),20),world(9,[player(8,20),player(7,17)]),8)
    Unit <- checked("server allocation wraps past active players",added(world(4294967295,[player(4294967295,17),player(1,18),player(2,19)]),20),world(4,[player(3,20),player(4294967295,17),player(1,18),player(2,19)]),3)
    Unit <- checked("server rejects sentinel connection ID",added(world(7,[player(1,17)]),0),world(7,[player(1,17)]),0)
    Unit <- checked("server rejects occupied connection ID",added(world(7,[player(1,17)]),17),world(7,[player(1,17)]),0)
    Unit <- checked("server repeated creation is exact no-op",again(added(world(7,Nil{}),20),20),world(8,[player(7,20)]),0)
    Unit <- checked("server sequential allocation survives wrap",again(added(world(4294967295,Nil{}),20),21),world(2,[player(1,21),player(4294967295,20)]),1)
    Unit <- Test.verdict("exhausted admission preserves full state",ST.same_state(J.Admission.state(J.Admission.choose(None{},T.Terrain.simulation(world(7,[player(1,17)])),20,style,Test.name)),T.Terrain.simulation(world(7,[player(1,17)]))))
    Unit <- Test.verdict("exhausted admission returns no player",U32.is_eq(J.Admission.pid(J.Admission.choose(None{},T.Terrain.simulation(world(7,Nil{})),20,style,Test.name)),0))
    IO.pure(Unit,Unit{})

#| PASS allocator normal hint
#| PASS allocator skips zero
#| PASS allocator maximum hint wraps cursor
#| PASS allocator skips occupied IDs
#| PASS allocator wraps and skips live IDs
#| PASS allocator finds wrapped gap
#| PASS allocator tolerates duplicate input IDs
#| PASS allocator ignores occupied zero
#| PASS allocator retains free hint below occupied IDs
#| PASS allocator crosses maximum boundary
#| PASS allocator checks all candidates within budget
#| PASS allocator bounded search reports failure
#| PASS allocator zero budget reports failure
#| PASS server player allocation preserves full world
#| PASS server player allocation normalizes zero
#| PASS server player allocation wraps cursor
#| PASS server allocation skips occupied player ID
#| PASS server allocation wraps past active players
#| PASS server rejects sentinel connection ID
#| PASS server rejects occupied connection ID
#| PASS server repeated creation is exact no-op
#| PASS server sequential allocation survives wrap
#| PASS exhausted admission preserves full state
#| PASS exhausted admission returns no player
