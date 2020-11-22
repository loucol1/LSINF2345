-module(linkedlist).
-export([add/2,getNeighbors/2, receiver/2, sender/1, node/2, node_create/2, create_list_node/1, node_initialisation/1, getId/1, increaseAge/1, getHighestAge/1, select_peer_random/1]).




add(ID,[])->[#{id => ID, list_neighbors => []}];
add(ID,[ #{id := IDprev, list_neighbors := List_neigh_prev} |T ])->
  [#{id =>ID, list_neighbors => [#{id_neighbors=>IDprev, age_neighbors=>0}]}, #{id => IDprev, list_neighbors => lists:append([#{id_neighbors=>ID,age_neighbors=>0}],List_neigh_prev)  } |T].


getNeighbors(IDNode,[])-> "error, IDNode is not in the given list";
getNeighbors(IDNode, [#{id := IDNode,list_neighbors:= List_neigh}|T])-> List_neigh;
getNeighbors(IDNode, [H|T])->getNeighbors(IDNode, T).

receiver(View, IDParent)->
  receive
    #{idsender := IDsender, list_neighbors := List_neigh}-> %le receiver recoit une view d'un autre noeud. Pour le moment, il l'append a sa list de view
      io:format("time receive in the receiver~n", []),
      IDParent ! #{message =>"view", view => lists:append(List_neigh,View)}, %mise a jour de la view chez le noeud parent
      receiver(lists:append(List_neigh,View), IDParent)
    end.

sender(IDParent)->
  receive
    [#{id_neighbors := ID, age_neighbors:= Age}|T]-> % le sender va devoir envoyer un message a un autre node. Pour le moment, il l'envoie au premier noeud de la list
      getId(ID) ! #{idsender => self(), list_neighbors=> T}, %io:format("time receive in the sender~n", [])
      io:format("time receive in the sender 22222~n", [])
    end,
    sender(IDParent).

node(View, IDsender)->
  receive
    #{message := "time"}->
    IDsender ! View ,  %message recu du main thread => le sender doit envoyer un message a un noeud voisin
    node(View,IDsender);
    #{message := "get_neighbors"} -> io:format("neighbors updated : ~p~n", [View]),
    node(View,IDsender);
    #{message := "view" , view := New_View}-> io:format("neighbors updated : ~p~n", [New_View]),
       node(New_View, IDsender) %message recu de la prt du receiver => mise a jour de la view
  end.



node_create(IDreceiver, View)->
  io:format("IDreceiver = ~w~n", [IDreceiver]),
  register(getId(IDreceiver), spawn(linkedlist, receiver, [View,self()])),
  IDsender = spawn(linkedlist, sender, [self()]),
  node(View, IDsender).


create_list_node(NbrNode)->create_list_node(NbrNode,[]).
create_list_node(0,Acc)->lists:reverse(Acc);
create_list_node(NbrNode,List)-> create_list_node(NbrNode-1, add(NbrNode, List)).


node_initialisation(A)->node_initialisation(A,[]).
node_initialisation([],Acc)-> Acc;
node_initialisation([#{id := ID, list_neighbors := List_neigh} |T], Acc)->
  node_initialisation(T, lists:append( [spawn(linkedlist, node_create, [ID, List_neigh])] , Acc) ).


getId(Nbr)->list_to_atom(integer_to_list(Nbr)).


increaseAge(View)->increaseAge(View, []).
increaseAge([], Acc)-> lists:reverse(Acc);
increaseAge([#{id_neighbors := ID, age_neighbors := Nbr}|T], Acc) -> increaseAge(T, lists:append([#{id_neighbors => ID, age_neighbors => Nbr+1}], Acc)).


%input : a vieuw
% output : getHighestAge renvoie le neighbor avec le plus grand age.
%Si deux neighbor ont le meme age, getHighestAge renvoie le premier neighbor qui apparait dans la liste
getHighestAge(View)-> getHighestAge(View, #{id_neighbors=> -1, age_neighbors => -1}).
getHighestAge([], Acc)-> Acc;
getHighestAge([#{id_neighbors := ID, age_neighbors := Nbr}|T], #{id_neighbors := IDMax, age_neighbors := NbrMax}) ->
  if Nbr>NbrMax -> getHighestAge(T, #{id_neighbors => ID, age_neighbors => Nbr});
  true -> getHighestAge(T, #{id_neighbors => IDMax, age_neighbors => NbrMax})
end.


select_peer_random(View) ->
    lists:nth(rand:uniform(length(View)), View).
