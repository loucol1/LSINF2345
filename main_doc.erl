-module(main_doc).
-export([main/5, indegree/2, indegree_element/2]).
-import(linkedlist, [create_list_node/1, node_initialisation/5, getId/1, select_peer_random/1, node_create/6]).

% N = total number of nodes in the network
% Id_max = valeur maximale de l'id déjà créé, utile pour le calcul de indegree
main(N, H, S, C, Pull) ->
    {ok, Output} = file:open("swapper_true.txt", [write]),
    Linked_list = create_list_node(N),
    {First, Second} = lists:split(floor(0.4*N), Linked_list),
    List_id_node = node_initialisation(First, H, S, C, Pull),
    compteur(List_id_node, N, H, S, C, Pull, Second, Output).

compteur(List_id_node, N, H, S, C, Pull, Second, Output) -> compteur(List_id_node, N, H, S, C, Pull, 0, Second, length(List_id_node), Output).

compteur(List_id_node, N, H, S, C, Pull, Count, Second, Id_max, Output) ->
    timer:sleep(3000),
    if    (Count rem 20) =:= 0 -> % indegree computation phase
        io:format("Count = ~p~n", [Count]),
        List_view = broadcast_ask_view(List_id_node),
        Indegree_return = indegree(List_view, Id_max),
        Average = lists:sum(Indegree_return)/length(Indegree_return),
        STD = math:sqrt(sum_of_square(Indegree_return, Average)/length(Indegree_return)),
        io:format(Output, "~p ~p ~p ~n",[Count, Average, STD]);
        %io:format(Output, "~p ~n",[Indegree_return]);
        
    true ->
        0
    end,

    if (Count=:=30) or (Count=:=60) -> % growing phase
        io:format("Count = ~p~n", [Count]),
        {Node_to_add, Node_not_to_add} = lists:split(floor(0.2*N), Second),
        List_id_node_new = node_initialisation(Node_to_add, H, S, C, Pull),
        compteur(lists:append(List_id_node, List_id_node_new), N, H, S, C, Pull, Count+1, Node_not_to_add, Id_max+length(List_id_node_new), Output);

    Count =:= 90 -> % growing phase
        io:format("Count = ~p~n", [Count]),
        List_id_node_new = node_initialisation(Second, H, S, C, Pull),
        compteur(lists:append(List_id_node, List_id_node_new), N, H, S, C, Pull, Count+1, [], N, Output);

    Count =:= 120 -> % kill node phase
        io:format("Count = ~p~n", [Count]),
        List_alive = node_to_kill(List_id_node, floor(0.6*N)),
        compteur(List_alive, N, H, S, C, Pull, Count +1, Second, Id_max, Output);

    Count =:= 150 -> % recovery phase
        io:format("Count = ~p~n", [Count]),
        Peer = select_peer_random(List_id_node),
        io:format("Peer recovery: ~p~n", [Peer]),
        Peer ! #{message => "ask_id_receiver", addresse_retour => self()},
        receive
            #{message := "response_id_receiver", id_receiver := Id_receiver} ->
            0,
            io:format("receive peer id: ~p~n", [Id_receiver])
        end,
        View = [#{id_neighbors => Id_receiver, age_neighbors => 0}],
        io:format("View recovery: ~p~n", [View]),
        List_recovery = create_list_recovery(N, floor(0.6*floor(0.6*N)), View),
        List_address_recovery = node_initialisation(List_recovery, H, S, C, Pull),
        compteur(lists:append(List_id_node, List_address_recovery), N, H, S, C, Pull, Count+1, Second, Id_max, Output);

    Count =:= 180 -> % end of the scenario
        io:format("Count = ~p~n", [Count]),
        List_alive_end = node_to_kill(List_id_node, length(List_id_node)),
        io:format("End List alive end = ~p~n", [List_alive_end]),
        file:close(Output);
    true ->
        broadcast_timeout(List_id_node),
        compteur(List_id_node, N, H, S, C, Pull, Count + 1, Second, Id_max, Output)
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

broadcast_ask_view(List_id_node) -> broadcast_ask_view(List_id_node, []).
broadcast_ask_view([], Acc) -> Acc;
broadcast_ask_view([U|T], Acc) ->
    U ! #{message => "ask_view", addresse_retour => self()},
    receive
        View -> broadcast_ask_view(T, [View|Acc])
    end.




% return a list with the indegree of every node
indegree(List_view, Id_max) -> indegree(List_view, List_view, Id_max,0, []).
indegree(List_parcours, List_view, 0, Acc_in, Acc_out) -> Acc_out;
indegree([], List_view, Id_max, Acc_in, Acc_out) -> indegree(List_view,List_view, Id_max-1, 0, [Acc_in|Acc_out]);
indegree([H|T], List_view, Id_max, Acc_in, Acc_out)-> indegree(T, List_view, Id_max, Acc_in+indegree_element(H,Id_max), Acc_out).



indegree_element(View, ID_to_check)-> indegree_element(View, ID_to_check,0).
indegree_element([],ID_to_check,Nbr)->Nbr;
indegree_element([#{id_neighbors := ID_neighbors, age_neighbors := Age}|T], ID_to_check, Nbr)->
  if(ID_neighbors =:= ID_to_check)->
    indegree_element(T,ID_to_check, Nbr+1);
  true-> indegree_element(T,ID_to_check,Nbr)
end.

sum_of_square(List, Mean)->sum_of_square(List,Mean,0).
sum_of_square([],Mean,Acc)->Acc;
sum_of_square([H|T],Mean, Acc)-> sum_of_square(T, Mean, Acc+(H-Mean)*(H-Mean)).
