-module(main_doc).
-export([main/4]).
-import(linkedlist, [create_list_node/1, node_initialisation/5, getId/1, select_peer_random/1]).

main(H, C, S, Pull) ->
    N = 7, % number of node
    Linked_list = create_list_node(N),
    List_id_node = node_initialisation(Linked_list, H, S, C, Pull),
    compteur(List_id_node).

compteur(List_node) -> compteur(List_node, 0).

compteur(List_node, Count) ->
    if Count =:= 5 -> % when kill node
        List_alive = node_to_kill(List_node, 1),
        io:format("List node: ~p~n", [List_node]),
        io:format("List alive: ~p~n", [List_alive]),
        timer:sleep(3000),
        compteur(List_alive, Count +1);
    
    %Count =:= 15 -> % recovery phase


    true ->
        timer:sleep(1000),
        broadcast_timeout(List_node),
        compteur(List_node, Count + 1)
    end.


broadcast_timeout([]) -> 0;
broadcast_timeout([U|T]) ->
    U ! #{message => "time"},
    broadcast_timeout(T).

% return a the list of dead and alive nodes
% send a message kill to the node

node_to_kill(List, 0) -> List;
node_to_kill(List, Number) -> 
    To_kill = select_peer_random(List),
    To_kill ! #{message => "dead"},
    node_to_kill(lists:delete(To_kill, List), Number - 1).