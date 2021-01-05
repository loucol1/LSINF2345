-module(main_doc).
-export([main/5, indegree/2, main/0]).
-import(linkedlist, [create_list_node/1, node_initialisation/5, getId/1, select_peer_random/1, node_create/6]).

main()-> main(128,4,3,7,'true').
% Main function to launch the scenario
% N = total number of nodes in the network = 128
% H, S and C are the parameter of the peer sampling. (3,4,7) for the healer and (4,3,7) for the swapper
% Pull = 'true' for a Push-Pull scenario, Pull = 'false' for a Push scenario
% output: Write in a file boxplot.txt the data to plot the boxplot. Format : Count Indegree_average Standard_deviation
%         Write in a file output.txt the data relative to the network. Format: Count NodeId [View]
main(N, H, S, C, Pull) ->
    {ok, Output} = file:open("boxplot.txt", [write]),
    Linked_list = linkedlist:create_list_node(N),
    {First, Second} = lists:split(trunc(0.4*N), Linked_list),
    List_id_node = node_initialisation(First, H, S, C, Pull),
    compteur(List_id_node, N, H, S, C, Pull, Second, Output).

%This function manages the scenario. By using the clock (timer:sleep) this function manages the clock cycle.
%This function interacts with the nodes by sending messages when an event happens : end of a cycle, the death of a node...
%input: List_id_node; a list with the address of the node threads of form [<add1>, <add2>...]
%       Second; a linkedlist of the form [#{id=xx, list_neighbors=xxx}...] with the node that are not yet added to the network
%       Output; the identification of the file to write the boxplot data.
compteur(List_id_node, N, H, S, C, Pull, Second, Output) -> compteur(List_id_node, N, H, S, C, Pull, 0, Second, length(List_id_node), Output).

compteur(List_id_node, N, H, S, C, Pull, Count, Second, Id_max, Output) ->
    timer:sleep(3000), %wait the duration of a clock cycle

    if (Count=:=30) or (Count=:=60) -> % growing phase - add 20% of the nodes
        io:format("Count = ~p~n", [Count]),
        {Node_to_add, Node_not_to_add} = lists:split(trunc(0.2*N), Second), %select the node to add in the network from the linkedList Second
        List_id_node_new = node_initialisation(Node_to_add, H, S, C, Pull), %create the node
        List_Big = lists:append(List_id_node, List_id_node_new), %update the list_id_node with the new addresses
        if (Count =:=60)-> % indegree computation
          List_tuple = broadcast_ask_view(lists:append(List_id_node, List_id_node_new)),
          print_graph(List_tuple, Count), %print network data in output.txt
          List_view = return_listView(List_tuple),
          List_id_alive = list_id_alive(List_tuple), %recover the id of the alive nodes
          Indegree_return = indegree(List_view, List_id_alive), %compute the indegree with the alive node
          Average = lists:sum(Indegree_return)/length(Indegree_return), %compute the average indegree
          STD = math:sqrt(sum_of_square(Indegree_return, Average)/length(Indegree_return)), %compute the standard deviation of the indegree
          io:format(Output, "~p ~p ~p ~n",[Count, Average, STD]), %write indegree information in boxplot.txt
          broadcast_timeout(lists:append(List_id_node, List_id_node_new)), %send a message to all the node because it is the end of a clock cycle
          compteur(lists:append(List_id_node, List_id_node_new), N, H, S, C, Pull, Count+1, Node_not_to_add, Id_max+length(List_id_node_new), Output);
        true -> %if count =:=60
          broadcast_timeout(lists:append(List_id_node, List_id_node_new)), %send a message to all the node because it is the end of a clock cycle
          compteur(lists:append(List_id_node, List_id_node_new), N, H, S, C, Pull, Count+1, Node_not_to_add, Id_max+length(List_id_node_new), Output)
        end; %if count =:= 60

    Count =:= 90 -> % growing phase - last growing phase, add all the element of Second
        io:format("Count = ~p~n", [Count]),
        List_id_node_new = node_initialisation(Second, H, S, C, Pull), %add the new node in the network
        broadcast_timeout(lists:append(List_id_node, List_id_node_new)), %send a message to all the nodes because it is the end of a clock cycle
        compteur(lists:append(List_id_node, List_id_node_new), N, H, S, C, Pull, Count+1, [], N, Output);

    Count =:= 120 -> % kill node phase
        io:format("Count = ~p~n", [Count]),
        List_alive = node_to_kill(List_id_node, trunc(0.6*N)), %kill 60% of the alive node
        List_tuple = broadcast_ask_view(List_alive),
        print_graph(List_tuple, Count), %print network information in output.txt
        List_view = return_listView(List_tuple),
        List_id_alive = list_id_alive(List_tuple), %recover the list of the alive nodes
        Indegree_return = indegree(List_view, List_id_alive), %compute the indegree of the alive nodes
        Average = lists:sum(Indegree_return)/length(Indegree_return), %compute the average indegree
        STD = math:sqrt(sum_of_square(Indegree_return, Average)/length(Indegree_return)), %compute the standard deviation of the indegree
        io:format(Output, "~p ~p ~p ~n",[Count, Average, STD]), %write the indegree information in boxplot.txt
        broadcast_timeout(List_alive), %send a message to all the node because it is the end of a clock cycle
        compteur(List_alive, N, H, S, C, Pull, Count +1, Second, Id_max, Output);

    Count =:= 150 -> % recovery phase
        io:format("Count = ~p~n", [Count]),
        Peer = select_peer_random(List_id_node), % select an alive node, all the recovered nodes will have this node as only neigbor
        io:format("Peer recovery: ~p~n", [Peer]),
        Peer ! #{message => "ask_id_receiver", addresse_retour => self()}, %ask the id of the node to the node thread
        receive
            #{message := "response_id_receiver", id_receiver := Id_receiver} -> %recover the id of the node
            0,
            io:format("receive peer id: ~p~n", [Id_receiver])
        end,
        View = [#{id_neighbors => Id_receiver, age_neighbors => 0}], %create the same view for all the recovered nodes
        io:format("View recovery: ~p~n", [View]),
        List_recovery = create_list_recovery(N, trunc(0.6*trunc(0.6*N)), View), % recover 60% of the node
        List_address_recovery = node_initialisation(List_recovery, H, S, C, Pull),
        broadcast_timeout(lists:append(List_id_node, List_address_recovery)), %send a message to all the nodes because it is the end of the clock cycle
        compteur(lists:append(List_id_node, List_address_recovery), N, H, S, C, Pull, Count+1, Second, Id_max+trunc(0.6*trunc(0.6*N)), Output);

    Count =:= 180 -> % end of the scenario - all the threads have to stop
        io:format("Count = ~p~n", [Count]),
        List_tuple = broadcast_ask_view(List_id_node),
        print_graph(List_tuple, Count), %write network information in output.txt

        List_view = return_listView(List_tuple),
        List_id_alive = list_id_alive(List_tuple), %recover the list of alive nodes
        Indegree_return = indegree(List_view, List_id_alive), %compute the indegree of the alive nodes
        Average = lists:sum(Indegree_return)/length(Indegree_return), %compute the average indegree
        STD = math:sqrt(sum_of_square(Indegree_return, Average)/length(Indegree_return)), %compute the standard deviation of the indegree
        io:format(Output, "~p ~p ~p ~n",[Count, Average, STD]), %write the indegree information in boxplot.txt

        List_alive_end = node_to_kill(List_id_node, length(List_id_node)),%kill all the node
        file:close(Output); % close the file boxplot.txt

      (Count rem 20) =:= 0 -> %indegree computation when the cycle is a multiple of 20
        io:format("Count = ~p~n", [Count]),
        List_tuple = broadcast_ask_view(List_id_node),
        print_graph(List_tuple, Count), %write network information in output.txt

        List_view = return_listView(List_tuple),
        List_id_alive = list_id_alive(List_tuple), %recover the list of alive node
        Indegree_return = indegree(List_view, List_id_alive), %compute the indegree of alive node
        Average = lists:sum(Indegree_return)/length(Indegree_return), %compute the avergage indegree
        STD = math:sqrt(sum_of_square(Indegree_return, Average)/length(Indegree_return)), %compute the standard deviation of the indegree
        io:format(Output, "~p ~p ~p ~n",[Count, Average, STD]),
        broadcast_timeout(List_id_node), %send a message to all the nodes because it is the end of a clock cycle
        compteur(List_id_node, N, H, S, C, Pull, Count+1, Second, Id_max, Output);
    true ->
        broadcast_timeout(List_id_node), %send a message to all the nodes because it is the end of a clock cycle
        compteur(List_id_node, N, H, S, C, Pull, Count + 1, Second, Id_max, Output)
    end.


%creates a list with new nodes for the recovery phase
%input: N; the number of nodes already present in the network (with the dead nodes)
%       Nbr_to_recover; the number of nodes to add in the network
%       View; the view that all the recovery nodes will have. Of form [#{id_neigbors=x, age_neigbors=y}, ...]
%output: a list with all the recovery node of form [#{id = a, list_neighbors = b}, ...]

create_list_recovery(N, Nbr_to_recover, View) -> create_list_recovery(N, Nbr_to_recover, View, []).
create_list_recovery(N, 0, View, Acc) -> lists:reverse(Acc);
create_list_recovery(N, Nbr_to_recover, View, Acc) ->
    create_list_recovery(N, Nbr_to_recover-1, View, [#{id => N+1+Nbr_to_recover, list_neighbors => View}|Acc]).



%Sends a message time to all the node thread
%This function is used to indicate to all the nodes that it is the end of a clock cycle
broadcast_timeout([]) -> 0;
broadcast_timeout([U|T]) ->
    U ! #{message => "time"},
    broadcast_timeout(T).


% Returns a list of the alive nodes
% send a message "dead" to the node
%input: List; a list of form [#{id = a, list_neighbors = b}, ...]
%       Number; the number of nodes to kill in List
%output: A list where N node have been killed
node_to_kill(List, 0) -> List;
node_to_kill(List, Number) ->
    To_kill = select_peer_random(List),
    To_kill ! #{message => "dead"},
    node_to_kill(lists:delete(To_kill, List), Number - 1).

%sends a message to all the nodes to ask the view of the nodes
%input: List_id_node; the list id of all the nodes of form [<add1>, <add2>...]
%output: A list with the view of all the nodes of form [#{id = a, list_neighbors = b}, ...]
broadcast_ask_view(List_id_node) -> broadcast_ask_view(List_id_node, []).
broadcast_ask_view([], Acc) -> Acc;
broadcast_ask_view([U|T], Acc) ->
    U ! #{message => "ask_view", addresse_retour => self()},
    receive
        Tuple_id_view -> broadcast_ask_view(T, [Tuple_id_view|Acc])
    end.

%input: Tuple_id_view; a list of form [#{view=xxx, id=xxx}...]
%output: a list with all the view of Tuple_id_view
return_listView(Tuple_id_view) -> return_listView(Tuple_id_view, []).
return_listView([], Acc) -> Acc;
return_listView([#{view:= View, id:=ID}|T], Acc) ->
    return_listView(T, [View|Acc]).


% writes the information concerning the newtork in output.txt
% input: List; the list of all the alive nodes of form [#{view:=View, id:=ID}...]
%        Count; the number of the clock cycles
% output: write in the file output.txt
print_graph(List, Count) ->
    if Count =:= 0 ->
        print_graph(List, Count, 1);
    true ->
        print_graph(List, Count, 0)
    end.
print_graph([], Count, Is_first) -> 0;
print_graph([#{view:=View, id:=ID}|T], Count, Is_first) ->
    if Is_first =:= 1 ->
        List = view_to_list(View),
        file:write_file("output.txt", io_lib:fwrite("~w ~w ~w~n",[Count,ID,List])),
        print_graph(T, Count, 0);
    true ->
        List = view_to_list(View),
        file:write_file("output.txt", io_lib:fwrite("~w ~w ~w~n",[Count,ID,List]),[append]),
        print_graph(T, Count, 0)
    end.



%input: View; a list of form #{age_neighbors=xxx, id_neighbors=xxx}
%return a list with all the id of the id_neigbors
view_to_list(View) -> view_to_list(View, []).
view_to_list([], Acc) -> Acc;
view_to_list([#{age_neighbors:=A, id_neighbors:=ID}|T], Acc) ->
    view_to_list(T, [ID|Acc]).


% input: ListTuple; a list of form [#{id=xxx, view=xxx}...]
% outpu: A list of the alive id of form [id1, id2, id3....]
list_id_alive(ListTuple) -> list_id_alive(ListTuple, []).
list_id_alive([], Acc) -> Acc;
list_id_alive([#{id:=ID, view:=View}|T], Acc) ->
    list_id_alive(T, [ID|Acc]).


%computes the indegree of every node
%input:List_view; a list of all views of the alive nodes of form [[{id_neighbors=x, age_neighbors=y}...], ...]
%       List_id; a list of all the id of the alive nodes of form [id1, id2...]
%output: a list with the indegree of every node
indegree(List_view, List_id) -> indegree(List_view, List_view, List_id, 0, []).
indegree(List_parcours, List_view, [], Acc_in, Acc_out) -> Acc_out;
indegree([], List_view, [H|T], Acc_in, Acc_out) ->
    indegree(List_view, List_view, T, 0, [Acc_in|Acc_out]);
indegree([H_view|T_view], List_view, [H_id|T_id], Acc_in, Acc_out) ->
    indegree(T_view, List_view, [H_id|T_id], Acc_in+indegree_element(H_view,H_id), Acc_out).


indegree_element(View, ID_to_check)-> indegree_element(View, ID_to_check,0).
indegree_element([],ID_to_check,Nbr)->Nbr;
indegree_element([#{id_neighbors := ID_neighbors, age_neighbors := Age}|T], ID_to_check, Nbr)->
  if(ID_neighbors =:= ID_to_check)->
    indegree_element(T,ID_to_check, Nbr+1);
  true-> indegree_element(T,ID_to_check,Nbr)
end.

%compute sum((List-Mean)^2)
%used for the indegree computation
sum_of_square(List, Mean)->sum_of_square(List,Mean,0).
sum_of_square([],Mean,Acc)->Acc;
sum_of_square([H|T],Mean, Acc)-> sum_of_square(T, Mean, Acc+(H-Mean)*(H-Mean)).
