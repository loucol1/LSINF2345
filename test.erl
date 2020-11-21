-module(test).
-export([test_function/0]).
-import (linkedlist, [add/2,getNeighbors/2, receiver/2, sender/1, node/2, node_create/1]).

test_function()->
  List_node = linkedlist:create_list_node(5),
  [H|T] = linkedlist:node_initialisation(List_node),
  H ! #{message => "time"}.
