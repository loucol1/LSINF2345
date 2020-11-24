-module(main_doc).
-export([main/4]).
-import(linkedlist, [create_list_node/1, node_initialisation/4, getId/1]).

main(H, C, S, Pull) ->
    N = 5, % number of node
    Linked_list = create_list_node(N),
    io:format("Linked_list ligne 7: ~p~n", [Linked_list]),
    List_id_node = node_initialisation(Linked_list, H, S, C),
    compteur(List_id_node).


compteur(List_node) ->
    timer:sleep(1000),
    broadcast_timeout(List_node),
    compteur(List_node).


broadcast_timeout([]) -> 0;
broadcast_timeout([U|T]) ->
    U ! #{message => "time"},
    broadcast_timeout(T).
