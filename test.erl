-module(test).
-export([test_function/0, bidon/0, test_name/0, test_htd/0]).

test_function()->
  List_node = linkedlist:create_list_node(5),
  [H1,H2|T] = linkedlist:node_initialisation(List_node),
  H2 ! #{message => "time"}.
  %H1 ! #{message => "get_neighbors"}.

test_htd()->
    register('1', spawn(test, bidon, [])).





bidon()->
  receive
    ping-> io:format("Ping received~n", [])
  end.





test_name()->
  register(list_to_atom(integer_to_list(1)), spawn(test, bidon, [])),
  list_to_atom(integer_to_list(1))! ping.
