-module(main_doc).
-export([main/4]).
-import(linkedlist, [create_list_node/1, node_initialisation/5, getId/1, select_peer_random/1, node_create/6]).

main(H, C, S, Pull) ->
    N = 7, % number of node
    Linked_list = create_list_node(N),
    List_id_node = node_initialisation(Linked_list, H, S, C, Pull),
    compteur(List_id_node, N, H, S, C, Pull).

compteur(List_node, N, H, S, C, Pull) -> compteur(List_node, N, H, S, C, Pull, 0).

compteur(List_node, N, H, S, C, Pull, Count) ->
    if Count =:= 5 -> % when kill node
        List_alive = node_to_kill(List_node, 1),
        io:format("List node: ~p~n", [List_node]),
        io:format("List alive: ~p~n", [List_alive]),
        timer:sleep(3000),
        compteur(List_alive, N, H, S, C, Pull, Count +1);
    
    Count =:= 10 -> % recovery phase
        Peer = select_peer_random(List_node),
        Peer ! #{message => "ask_id_receiver", addresse_retour => self()},
        receive 
            #{message := "response_id_receiver", id_receiver := Id_receiver} ->
            0
        end,
        View = [#{id_neighbors => Id_receiver, age_neighbors => 0}],
        List_recovery = create_list_recovery(N, 5, View),
        List_address_recovery = node_initialisation(List_recovery, H, S, C, Pull),
        compteur(lists:append(List_node, List_address_recovery), N, H, S, C, Pull, Count+1);
        
    true ->
        timer:sleep(1000),
        broadcast_timeout(List_node),
        compteur(List_node, N, H, S, C, Pull, Count + 1)
    end.


create_list_recovery(N, Nbr_to_recover, View) -> create_list_recovery(N, Nbr_to_recover, View, []).
create_list_recovery(N, 0, View, Acc) -> lists:reverse(Acc);
create_list_recovery(N, Nbr_to_recover, View, Acc) ->
    create_list_recovery(N, Nbr_to_recover-1, View, [#{id => N+1+Nbr_to_recover, list_neighbors => View}|Acc]).

    


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