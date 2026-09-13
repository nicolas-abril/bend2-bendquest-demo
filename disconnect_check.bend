import Base
import ./disconnect.bend as D
import ./creation.bend as K
import ./creation_check.bend as F
import ./sessions_check.bend as SS
import ./players_check.bend as Test
import ./players.bend as P
import ./monsters.bend as M
import ./simulation.bend as Sim

def mob(mid: U32,target: U32) -> M.Monsters.State: M.Monsters.State{mid,2,1,0,4,8,10,10,target,7,0,17}
def sample(players: List<&2,P.Players.State>,monsters: List<&2,M.Monsters.State>) -> Sim.Simulation.State: Sim.Simulation.State{Sim.Simulation.Meta{1,7,0,99,100,200,3,400,99,450},players,monsters}

def checked(label: String,before: K.Creation.Result,cid: U32,expected: K.Creation.Result) -> IO(Unit):
  match before:
    case K.Creation.Result{world,states}: Test.verdict(label,F.same(D.Disconnect.run(world,states,cid),expected))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- checked("disconnect empty",K.Creation.Result{sample(Nil{},Nil{}),Nil{}},1,K.Creation.Result{sample(Nil{},Nil{}),Nil{}})
    Unit <- checked("disconnect missing CID exact no-op",K.Creation.Result{sample([F.player(7,1,"Ada")],[mob(1,7)]),[SS.state(1,2,7,"Ada")]},99,K.Creation.Result{sample([F.player(7,1,"Ada")],[mob(1,7)]),[SS.state(1,2,7,"Ada")]})
    Unit <- checked("disconnect fresh connection only",K.Creation.Result{sample(Nil{},[mob(1,0)]),[SS.state(4,0,0,"")]},4,K.Creation.Result{sample(Nil{},[mob(1,0)]),Nil{}})
    Unit <- checked("disconnect identified connection only",K.Creation.Result{sample(Nil{},[mob(1,0)]),[SS.state(4,1,0,"Dee")]},4,K.Creation.Result{sample(Nil{},[mob(1,0)]),Nil{}})
    Unit <- checked("disconnect waiting retains existing player",K.Creation.Result{sample([F.player(7,1,"Ada")],[mob(1,7)]),[SS.state(1,2,7,"Ada"),SS.state(4,1,0,"Dee")]},4,K.Creation.Result{sample([F.player(7,1,"Ada")],[mob(1,7)]),[SS.state(1,2,7,"Ada")]})
    Unit <- checked("disconnect fresh retains existing player",K.Creation.Result{sample([F.player(7,1,"Ada")],[mob(1,7)]),[SS.state(4,0,0,""),SS.state(1,2,7,"Ada")]},4,K.Creation.Result{sample([F.player(7,1,"Ada")],[mob(1,7)]),[SS.state(1,2,7,"Ada")]})
    Unit <- checked("disconnect only bound player",K.Creation.Result{sample([F.player(7,1,"Ada")],[mob(1,7)]),[SS.state(1,2,7,"Ada")]},1,K.Creation.Result{sample(Nil{},[mob(1,0)]),Nil{}})
    Unit <- checked("disconnect first player",K.Creation.Result{sample([F.player(7,1,"Ada"),F.player(8,2,"Bob"),F.player(9,3,"Cy")],[mob(1,7),mob(2,8),mob(3,9)]),[SS.state(1,2,7,"Ada"),SS.state(2,2,8,"Bob"),SS.state(3,2,9,"Cy")]},1,K.Creation.Result{sample([F.player(8,2,"Bob"),F.player(9,3,"Cy")],[mob(1,0),mob(2,8),mob(3,9)]),[SS.state(2,2,8,"Bob"),SS.state(3,2,9,"Cy")]})
    Unit <- checked("disconnect middle player",K.Creation.Result{sample([F.player(7,1,"Ada"),F.player(8,2,"Bob"),F.player(9,3,"Cy")],[mob(1,7),mob(2,8),mob(3,9)]),[SS.state(1,2,7,"Ada"),SS.state(2,2,8,"Bob"),SS.state(3,2,9,"Cy")]},2,K.Creation.Result{sample([F.player(7,1,"Ada"),F.player(9,3,"Cy")],[mob(1,7),mob(2,0),mob(3,9)]),[SS.state(1,2,7,"Ada"),SS.state(3,2,9,"Cy")]})
    Unit <- checked("disconnect last player",K.Creation.Result{sample([F.player(7,1,"Ada"),F.player(8,2,"Bob"),F.player(9,3,"Cy")],[mob(1,7),mob(2,8),mob(3,9)]),[SS.state(1,2,7,"Ada"),SS.state(2,2,8,"Bob"),SS.state(3,2,9,"Cy")]},3,K.Creation.Result{sample([F.player(7,1,"Ada"),F.player(8,2,"Bob")],[mob(1,7),mob(2,8),mob(3,0)]),[SS.state(1,2,7,"Ada"),SS.state(2,2,8,"Bob")]})
    Unit <- checked("disconnect independent roster order",K.Creation.Result{sample([F.player(7,1,"Ada"),F.player(8,2,"Bob"),F.player(9,3,"Cy")],[mob(1,8)]),[SS.state(3,2,9,"Cy"),SS.state(2,2,8,"Bob"),SS.state(1,2,7,"Ada")]},2,K.Creation.Result{sample([F.player(7,1,"Ada"),F.player(9,3,"Cy")],[mob(1,0)]),[SS.state(3,2,9,"Cy"),SS.state(1,2,7,"Ada")]})
    Unit <- checked("disconnect mixed waiting and bound",K.Creation.Result{sample([F.player(7,1,"Ada"),F.player(8,2,"Bob")],[mob(1,7),mob(2,8)]),[SS.state(4,1,0,"Dee"),SS.state(2,2,8,"Bob"),SS.state(5,0,0,""),SS.state(1,2,7,"Ada")]},1,K.Creation.Result{sample([F.player(8,2,"Bob")],[mob(1,0),mob(2,8)]),[SS.state(4,1,0,"Dee"),SS.state(2,2,8,"Bob"),SS.state(5,0,0,"")]})
    Unit <- checked("disconnect multiple monster targets cleared",K.Creation.Result{sample([F.player(7,1,"Ada"),F.player(8,2,"Bob")],[mob(1,7),mob(2,7),mob(3,8),mob(4,0)]),[SS.state(1,2,7,"Ada"),SS.state(2,2,8,"Bob")]},1,K.Creation.Result{sample([F.player(8,2,"Bob")],[mob(1,0),mob(2,0),mob(3,8),mob(4,0)]),[SS.state(2,2,8,"Bob")]})
    Unit <- checked("disconnect zero CID missing",K.Creation.Result{sample([F.player(7,1,"Ada")],[mob(1,7)]),[SS.state(1,2,7,"Ada")]},0,K.Creation.Result{sample([F.player(7,1,"Ada")],[mob(1,7)]),[SS.state(1,2,7,"Ada")]})
    Unit <- checked("disconnect MAX PID and CID",K.Creation.Result{sample([F.player(4294967295,4294967295,"Max")],[mob(1,4294967295)]),[SS.state(4294967295,2,4294967295,"Max")]},4294967295,K.Creation.Result{sample(Nil{},[mob(1,0)]),Nil{}})
    Unit <- checked("disconnect UTF8 identity",K.Creation.Result{sample([F.player(7,1,"Étoile"),F.player(8,2,"Bob")],[mob(1,7),mob(2,8)]),[SS.state(1,2,7,"Étoile"),SS.state(2,2,8,"Bob")]},1,K.Creation.Result{sample([F.player(8,2,"Bob")],[mob(1,0),mob(2,8)]),[SS.state(2,2,8,"Bob")]})
    Unit <- checked("disconnect other target and counters unchanged",K.Creation.Result{sample([F.player(7,1,"Ada"),F.player(8,2,"Bob")],[mob(1,8)]),[SS.state(1,2,7,"Ada"),SS.state(2,2,8,"Bob")]},1,K.Creation.Result{sample([F.player(8,2,"Bob")],[mob(1,8)]),[SS.state(2,2,8,"Bob")]})
    Unit <- Test.verdict("disconnect trace repeated gone",F.same(D.Disconnect.trace([D.Disconnect.Connection{K.Creation.Connect{1}},D.Disconnect.Connection{K.Creation.Hello{1,SS.name("Ada")}},D.Disconnect.Connection{K.Creation.Create{1,F.style,True{}}},D.Disconnect.Gone{1},D.Disconnect.Gone{1}],K.Creation.Result{F.world(1,Nil{}),Nil{}}),K.Creation.Result{F.world(2,Nil{}),Nil{}}))
    Unit <- Test.verdict("disconnect trace one of two players",F.same(D.Disconnect.trace([D.Disconnect.Connection{K.Creation.Connect{1}},D.Disconnect.Connection{K.Creation.Hello{1,SS.name("Ada")}},D.Disconnect.Connection{K.Creation.Create{1,F.style,True{}}},D.Disconnect.Connection{K.Creation.Connect{2}},D.Disconnect.Connection{K.Creation.Hello{2,SS.name("Bob")}},D.Disconnect.Connection{K.Creation.Create{2,F.style,True{}}},D.Disconnect.Gone{1}],K.Creation.Result{F.world(1,Nil{}),Nil{}}),K.Creation.Result{F.world(3,[F.player(2,2,"Bob")]),[SS.state(2,2,2,"Bob")]}))
    Unit <- Test.verdict("disconnect trace CID reuse with new PID",F.same(D.Disconnect.trace([D.Disconnect.Connection{K.Creation.Connect{1}},D.Disconnect.Connection{K.Creation.Hello{1,SS.name("Ada")}},D.Disconnect.Connection{K.Creation.Create{1,F.style,True{}}},D.Disconnect.Gone{1},D.Disconnect.Connection{K.Creation.Connect{1}},D.Disconnect.Connection{K.Creation.Hello{1,SS.name("Bob")}},D.Disconnect.Connection{K.Creation.Create{1,F.style,True{}}}],K.Creation.Result{F.world(1,Nil{}),Nil{}}),K.Creation.Result{F.world(3,[F.player(2,1,"Bob")]),[SS.state(1,2,2,"Bob")]}))
    Unit <- Test.verdict("disconnect trace waiting disconnect then reuse",F.same(D.Disconnect.trace([D.Disconnect.Connection{K.Creation.Connect{1}},D.Disconnect.Connection{K.Creation.Hello{1,SS.name("Ada")}},D.Disconnect.Gone{1},D.Disconnect.Connection{K.Creation.Connect{1}},D.Disconnect.Connection{K.Creation.Hello{1,SS.name("Bob")}},D.Disconnect.Connection{K.Creation.Create{1,F.style,True{}}}],K.Creation.Result{F.world(1,Nil{}),Nil{}}),K.Creation.Result{F.world(2,[F.player(1,1,"Bob")]),[SS.state(1,2,1,"Bob")]}))
    Unit <- Test.verdict("disconnect trace fresh disconnect",F.same(D.Disconnect.trace([D.Disconnect.Connection{K.Creation.Connect{1}},D.Disconnect.Gone{1},D.Disconnect.Gone{1}],K.Creation.Result{F.world(1,Nil{}),Nil{}}),K.Creation.Result{F.world(1,Nil{}),Nil{}}))
    Test.verdict("disconnect trace two players disconnect all",F.same(D.Disconnect.trace([D.Disconnect.Connection{K.Creation.Connect{1}},D.Disconnect.Connection{K.Creation.Hello{1,SS.name("Ada")}},D.Disconnect.Connection{K.Creation.Create{1,F.style,True{}}},D.Disconnect.Connection{K.Creation.Connect{2}},D.Disconnect.Connection{K.Creation.Hello{2,SS.name("Bob")}},D.Disconnect.Connection{K.Creation.Create{2,F.style,True{}}},D.Disconnect.Gone{2},D.Disconnect.Gone{1}],K.Creation.Result{F.world(1,Nil{}),Nil{}}),K.Creation.Result{F.world(3,Nil{}),Nil{}}))

#| PASS disconnect empty
#| PASS disconnect missing CID exact no-op
#| PASS disconnect fresh connection only
#| PASS disconnect identified connection only
#| PASS disconnect waiting retains existing player
#| PASS disconnect fresh retains existing player
#| PASS disconnect only bound player
#| PASS disconnect first player
#| PASS disconnect middle player
#| PASS disconnect last player
#| PASS disconnect independent roster order
#| PASS disconnect mixed waiting and bound
#| PASS disconnect multiple monster targets cleared
#| PASS disconnect zero CID missing
#| PASS disconnect MAX PID and CID
#| PASS disconnect UTF8 identity
#| PASS disconnect other target and counters unchanged
#| PASS disconnect trace repeated gone
#| PASS disconnect trace one of two players
#| PASS disconnect trace CID reuse with new PID
#| PASS disconnect trace waiting disconnect then reuse
#| PASS disconnect trace fresh disconnect
#| PASS disconnect trace two players disconnect all
