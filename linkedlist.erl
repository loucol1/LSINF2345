-module(linkedlist).
-export([add/2,getNeighbors/2, receiver/2, sender/1, node/2, node_create/1]).




add(ID,[])->[{ID,[]}];
add(ID,[{IDprev,List_neigh_prev}|T])->[{ID,[IDprev]},{IDprev,lists:append([ID],List_neigh_prev)}|T].


getNeighbors(IDNode,[])-> "error, IDNode is not in the given list";
getNeighbors(IDNode, [{IDNode,List_neigh}|T])-> List_neigh;
getNeighbors(IDNode, [{ID,List_neigh}|T])->getNeighbors(IDNode, T).

receiver(View, IDParent)->
  receive
    {IDsender, List_neigh}->
      IDParent ! {"view", lists:append(List_neigh,View)},
      receiver(lists:append(List_neigh,View),IDParent)
    end.

sender(IDParent)->
  receive
    [{ID, Age}|T]->
       ID ! {self(), T},
       sender(IDParent)
     end.

node(View, IDsender)->
  receive
    {"view" , New_View}-> node(New_View);
    {"time"}-> IDsender ! View
  end.




node_create(View)->
  spawn(linkedlist, receiver, [View,self()]),
  IDsender = spawn(linkedlist, sender, [self()]),
  node(View, IDsender).
