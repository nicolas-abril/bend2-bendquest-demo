import Base
import ./compat.bend as C
import ./sessions.bend as S
import ./players.bend as P
import ./players_check.bend as Test

def name(value: String) -> List<&2,Char>: P.Players.share_name(C.Bq.text(value))

def state(cid: U32,phase: U32,pid: U32,text: String) -> S.Sessions.State: S.Sessions.State{cid,phase,pid,name(text)}

def code(reply: S.Sessions.Reply) -> U32:
  match reply:
    case S.Sessions.Locked{}: 0
    case S.Sessions.BadName{}: 1
    case S.Sessions.Taken{}: 2
    case S.Sessions.Welcome{}: 3

def same(left: S.Sessions.State,right: S.Sessions.State) -> Bool:
  match left:
    case S.Sessions.State{a,b,c,d}:
      match right:
        case S.Sessions.State{e,f,g,h}: Bool.and(U32.is_eq(a,e),Bool.and(U32.is_eq(b,f),Bool.and(U32.is_eq(c,g),S.Sessions.name_eq(d,h))))

def result(label: String,result: S.Sessions.Result,expected: S.Sessions.State,reply: U32) -> IO(Unit):
  match result:
    case S.Sessions.Result{after,answer}: Test.verdict(label,Bool.and(same(after,expected),U32.is_eq(code(answer),reply)))

def checked(label: String,before: S.Sessions.State,text: String,others: List<&2,S.Sessions.State>,expected: S.Sessions.State,reply: U32) -> IO(Unit): result(label,S.Sessions.hello(before,name(text),others),expected,reply)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- Test.verdict("binding preserves connection and profile",same(S.Sessions.bind(state(1,1,0,"Étoile"),17),state(1,2,17,"Étoile")))
    Unit <- Test.verdict("binding accepts allocated MAX PID",same(S.Sessions.bind(state(4294967295,1,0,"Ada"),4294967295),state(4294967295,2,4294967295,"Ada")))
    Unit <- checked("bound player cannot change profile",S.Sessions.bind(state(1,1,0,"Alice"),17),"Bob",Nil{},state(1,2,17,"Alice"),0)
    Unit <- checked("fresh HELLO enters creation",S.Sessions.fresh(1),"Alice",Nil{},state(1,1,0,"Alice"),3)
    Unit <- checked("pre-create HELLO can change name",state(1,1,0,"Alice"),"Bob",Nil{},state(1,1,0,"Bob"),3)
    Unit <- checked("playing HELLO preserves full descriptor",state(1,2,7,"Alice"),"Bob",Nil{},state(1,2,7,"Alice"),0)
    Unit <- checked("playing same-name HELLO stays playing",state(1,2,7,"Alice"),"Alice",Nil{},state(1,2,7,"Alice"),0)
    Unit <- checked("playing empty HELLO stays playing",state(1,2,7,"Alice"),"",Nil{},state(1,2,7,"Alice"),0)
    Unit <- checked("bound creation state cannot reidentify",state(1,1,7,"Alice"),"Bob",Nil{},state(1,1,7,"Alice"),0)
    Unit <- checked("bound fresh state cannot reidentify",state(1,0,7,"Alice"),"Bob",Nil{},state(1,0,7,"Alice"),0)
    Unit <- checked("playing zero PID cannot reidentify",state(1,2,0,"Alice"),"Bob",Nil{},state(1,2,0,"Alice"),0)
    Unit <- checked("invalid phase cannot identify",state(1,3,0,"Alice"),"Bob",Nil{},state(1,3,0,"Alice"),0)
    Unit <- checked("MAX phase cannot identify",state(1,4294967295,0,"Alice"),"Bob",Nil{},state(1,4294967295,0,"Alice"),0)
    Unit <- checked("MAX binding is preserved",state(4294967295,2,4294967295,"Alice"),"Bob",Nil{},state(4294967295,2,4294967295,"Alice"),0)
    Unit <- checked("empty name rejected without mutation",state(1,1,0,"Alice"),"",Nil{},state(1,1,0,"Alice"),1)
    Unit <- checked("one-character name accepted",S.Sessions.fresh(1),"A",Nil{},state(1,1,0,"A"),3)
    Unit <- checked("twelve-character name accepted",S.Sessions.fresh(1),"abcdefghijkl",Nil{},state(1,1,0,"abcdefghijkl"),3)
    Unit <- checked("thirteen-character name rejected",S.Sessions.fresh(1),"abcdefghijklm",Nil{},S.Sessions.fresh(1),1)
    Unit <- checked("UTF8 name accepted",S.Sessions.fresh(1),"Étoile",Nil{},state(1,1,0,"Étoile"),3)
    Unit <- checked("twelve Unicode characters accepted",S.Sessions.fresh(1),"éééééééééééé",Nil{},state(1,1,0,"éééééééééééé"),3)
    Unit <- checked("thirteen Unicode characters rejected",S.Sessions.fresh(1),"ééééééééééééé",Nil{},S.Sessions.fresh(1),1)
    Unit <- checked("playing name collision rejected",S.Sessions.fresh(1),"Alice",[state(2,2,8,"Alice")],S.Sessions.fresh(1),2)
    Unit <- checked("pre-create name reservation respected",S.Sessions.fresh(1),"Alice",[state(2,1,0,"Alice")],S.Sessions.fresh(1),2)
    Unit <- checked("UTF8 name collision rejected",S.Sessions.fresh(1),"Étoile",[state(2,2,8,"Étoile")],S.Sessions.fresh(1),2)
    Unit <- checked("name lookup checks later connections",S.Sessions.fresh(1),"Alice",[state(2,2,8,"Bob"),state(3,2,9,"Alice")],S.Sessions.fresh(1),2)
    Unit <- checked("case-sensitive names retain existing behavior",S.Sessions.fresh(1),"alice",[state(2,2,8,"Alice")],state(1,1,0,"alice"),3)
    Unit <- checked("rejected rename retains original reservation",state(1,1,0,"Alice"),"Bob",[state(2,2,8,"Bob")],state(1,1,0,"Alice"),2)
    Unit <- Test.verdict("bound HELLO sequence preserves descriptor",same(S.Sessions.trace([name(""),name("Bob"),name("Étoile")],state(1,2,7,"Alice"),Nil{}),state(1,2,7,"Alice")))
    Test.verdict("pre-create HELLO sequence remains usable",same(S.Sessions.trace([name(""),name("Bob"),name("Ada")],S.Sessions.fresh(1),[state(2,2,8,"Bob")]),state(1,1,0,"Ada")))

#| PASS binding preserves connection and profile
#| PASS binding accepts allocated MAX PID
#| PASS bound player cannot change profile
#| PASS fresh HELLO enters creation
#| PASS pre-create HELLO can change name
#| PASS playing HELLO preserves full descriptor
#| PASS playing same-name HELLO stays playing
#| PASS playing empty HELLO stays playing
#| PASS bound creation state cannot reidentify
#| PASS bound fresh state cannot reidentify
#| PASS playing zero PID cannot reidentify
#| PASS invalid phase cannot identify
#| PASS MAX phase cannot identify
#| PASS MAX binding is preserved
#| PASS empty name rejected without mutation
#| PASS one-character name accepted
#| PASS twelve-character name accepted
#| PASS thirteen-character name rejected
#| PASS UTF8 name accepted
#| PASS twelve Unicode characters accepted
#| PASS thirteen Unicode characters rejected
#| PASS playing name collision rejected
#| PASS pre-create name reservation respected
#| PASS UTF8 name collision rejected
#| PASS name lookup checks later connections
#| PASS case-sensitive names retain existing behavior
#| PASS rejected rename retains original reservation
#| PASS bound HELLO sequence preserves descriptor
#| PASS pre-create HELLO sequence remains usable
