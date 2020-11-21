-module(linkedlist).
-export([add/2,getNeighbors/2, receiver/2, sender/1, node/2, node_create/1, create_list_node/1, node_initialisation/1]).




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
      ID ! #{idsender=> self(), list_neighbors=> T}, %io:format("time receive in the sender~n", [])
      io:format("time receive in the sender~n", [])
    end,
    sender(IDParent).

node(View, IDsender)->
  receive
    #{message := "view" , view := New_View}-> node(New_View); %message recu de la prt du receiver => mise a jour de la view
    #{message := "time"}-> IDsender ! View  %message recu du main thread => le sender doit envoyer un message a un noeud voisin
  end,
  node(View,IDsender).




node_create(View)->
  spawn(linkedlist, receiver, [View,self()]),
  IDsender = spawn(linkedlist, sender, [self()]),
  node(View, IDsender).


create_list_node(NbrNode)->create_list_node(NbrNode,[]).
create_list_node(0,Acc)->lists:reverse(Acc);
create_list_node(NbrNode,List)-> create_list_node(NbrNode-1, add(NbrNode, List)).


node_initialisation(A)->node_initialisation(A,[]).
node_initialisation([],Acc)-> Acc;
node_initialisation([#{id := ID, list_neighbors := List_neigh} |T], Acc)->
  node_initialisation(T, lists:append( [spawn(linkedlist, node_create, [List_neigh])] , Acc) ).
