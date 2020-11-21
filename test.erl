-module(test).
-export([test_function/0, bidon/0, test_name/0]).
-import (linkedlist, [add/2,getNeighbors/2, receiver/2, sender/1, node/2, node_create/1]).

test_function()->
  List_node = linkedlist:create_list_node(5),
  [H|T] = linkedlist:node_initialisation(List_node),
  H ! #{message => "time"}.

bidon()->
  receive
    ping-> io:format("Ping received~n", [])
  end,
  bidon().




test_name()->
  register(list_to_atom(integer_to_list(1)), spawn(test, bidon, [])),
  list_to_atom(integer_to_list(1))! ping.
