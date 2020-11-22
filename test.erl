-module(test).
-export([test_function/0, bidon/0, test_name/0, test_HighestAge/0]).
-import (linkedlist, [add/2,getNeighbors/2, receiver/2, sender/1, node/2, node_create/1, increaseAge/1, getHighestAge/1]).

test_function()->
  List_node = linkedlist:create_list_node(5),
  [H1,H2|T] = linkedlist:node_initialisation(List_node),
  H2 ! #{message => "time"}.
  %H1 ! #{message => "get_neighbors"}.

test_HighestAge()->
  B = [#{id_neighbors => 1, age_neighbors => 1}, #{id_neighbors => 2, age_neighbors => 5}, #{id_neighbors => 3, age_neighbors => 4}, #{id_neighbors => 4, age_neighbors => 3} ],
  getHighestAge(B).


bidon()->
  receive
    ping-> io:format("Ping received~n", [])
  end,
  bidon().




test_name()->
  register(list_to_atom(integer_to_list(1)), spawn(test, bidon, [])),
  list_to_atom(integer_to_list(1))! ping.
