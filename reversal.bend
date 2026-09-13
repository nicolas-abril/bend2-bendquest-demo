# Exact player-roster reversal with full-record permutation evidence.
import Base
import ./players.bend as P
import ./rebuild.bend as R

def Reversal.append(left: List<&2,P.Players.State>,right: List<&2,P.Players.State>) -> List<&2,P.Players.State>:
  match left:
    case Nil{}: right
    case Con{head,rest}: Con{head,Reversal.append(rest,right)}

def Reversal.into(players: List<&2,P.Players.State>,acc: List<&2,P.Players.State>) -> List<&2,P.Players.State>:
  match players:
    case Nil{}: acc
    case Con{head,rest}: Reversal.into(rest,Con{head,acc})

law Reversal.move:
  for +players: List<&2,P.Players.State>
  for +head: P.Players.State
  for +acc: List<&2,P.Players.State>
  P.Players.Perm<Reversal.append(players,Con{head,acc}),Con{head,Reversal.append(players,acc)}>

def Reversal.move(players,head,acc):
  match players:
    case Nil{}: P.Players.Same{{==}}
    case Con{first,rest}: P.Players.Then{Con{first,Con{head,Reversal.append(rest,acc)}},P.Players.Common{first,Reversal.append(rest,Con{head,acc}),Con{head,Reversal.append(rest,acc)},{==},{==},Reversal.move(rest,head,acc)},P.Players.Swap{first,head,Reversal.append(rest,acc),{==},{==}}}

law Reversal.permutation:
  for +players: List<&2,P.Players.State>
  for +acc: List<&2,P.Players.State>
  P.Players.Perm<Reversal.into(players,acc),Reversal.append(players,acc)>

def Reversal.permutation(players,acc):
  match players:
    case Nil{}: P.Players.Same{{==}}
    case Con{head,rest}: P.Players.Then{Reversal.append(rest,Con{head,acc}),Reversal.permutation(rest,Con{head,acc}),Reversal.move(rest,head,acc)}

law Reversal.append_nil:
  for +players: List<&2,P.Players.State>
  {Reversal.append(players,Nil{}) == players : List<&2,P.Players.State>}

def Reversal.append_nil(players):
  match players:
    case Nil{}: {==}
    case Con{head,rest}:
      %Reversal.append_nil(rest) : {Con{head,Reversal.append(rest,Nil{})} == Con{head,_} : List<&2,P.Players.State>}
      {==}

law Reversal.roster:
  for +players: List<&2,P.Players.State>
  P.Players.Perm<Reversal.into(players,Nil{}),players>

def Reversal.roster(players): P.Players.Then{Reversal.append(players,Nil{}),Reversal.permutation(players,Nil{}),P.Players.Same{Reversal.append_nil(players)}}

law Reversal.profiles:
  for +players: List<&2,P.Players.State>
  for +acc: List<&2,P.Players.State>
  {R.Rebuild.profiles(Reversal.into(players,acc)) == R.Rebuild.reverse_into(players,R.Rebuild.profiles(acc)) : List<&2,R.Rebuild.Profile>}

def Reversal.profiles(players,acc):
  match players:
    case Nil{}: {==}
    case Con{head,rest}: Reversal.profiles(rest,Con{head,acc})
