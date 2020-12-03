-module(linkedlist).
-export([create_list_node/1, node_initialisation/5, getId/1, node_create/6, receiver/7, sender/6, node/6, select_peer_random/1, getHighestAge/1]).




%The add function create a tuple with the ID given in arguement and a list of neighbors that correspond to the node that are neighbors in the linkedlist
%input: ID of a node that we want to add int the linkedlist
%       The linked list of the form [#{id=xx, list_neighbors=xxx}...]
%output: the linked list with the element #{id=ID, list_neighbors=xxx} added

add(ID,[])->[#{id => ID, list_neighbors => []}];
add(ID,[ #{id := IDprev, list_neighbors := List_neigh_prev} |T ])->
  [#{id =>ID, list_neighbors => [#{id_neighbors=>IDprev, age_neighbors=>0}]}, #{id => IDprev, list_neighbors => lists:append([#{id_neighbors=>ID,age_neighbors=>0}],List_neigh_prev)  } |T].


%The getNeighbors function return the neighbors of a node in the linkedlist
%input: IDNode, the id of the node of which we want to know its neighbors
%       LinkedList, a list of form [#{id=xx, list_neighbors=xxx}...]
%output: the list of neighbors of IDNode (=numbers) of form [Id1, Id2...]
getNeighbors(IDNode,[])-> "error, IDNode is not in the given list";
getNeighbors(IDNode, [#{id := IDNode,list_neighbors:= List_neigh}|T])-> List_neigh;
getNeighbors(IDNode, [H|T])->getNeighbors(IDNode, T).


receiver(View, IDParent, Id_receiver, H, S, C, Pull)->
  receive
    "dead" -> %the node is killed and the receiver thread have to stop
      0;
    #{id_sender_brut := IDsender, view := View_receive}-> %receive a view from a peer node
      % if pull
      if Pull =:= 'true'-> % the node have to response by sharing its internal view
        Buffer = [#{id_neighbors=>Id_receiver, age_neighbors=>0}],
        View_permute = highest_age_to_end(View, H),
        {First, Second} = lists:split(min(length(View_permute), floor(C/2)-1), View_permute),
        Buffer_append = lists:append(Buffer, First),
        IDsender ! #{view_pull =>  Buffer_append}, %send a message to the node thread to update its view
        View_select = view_select(H, S, C, View_receive, View),
        New_view = increaseAge(View_select), %generate the buffer to send
        IDParent ! #{message => "view_receiver", view => New_view}; %response to the node by sharing its view
      true ->%not pull, the node does not response
        View_select = view_select(H, S, C, View_receive, View),
        New_view = increaseAge(View_select),
        IDParent ! #{message => "view_receiver", view => New_view}%send a message to the node thread to update its view
      end,
    receiver(New_view, IDParent, Id_receiver, H, S, C, Pull)
  end.


sender(IDParent,IDReceiver_itself, H, S, C, Pull)->
  receive
    "dead" -> %the node is killed and the sender thread have to stop
      0;

    View-> % the node send a message to a peer node to share its view
      #{id_neighbors := Id_Peer, age_neighbors := Age} = select_peer_random_alive(View), %select a random node in its view
      Buffer = [#{id_neighbors=>IDReceiver_itself, age_neighbors=>0}],
      View_permute = highest_age_to_end(View, H),
      {First, Second} = lists:split(min(length(View_permute), floor(C/2)-1), View_permute),
      Buffer_append = lists:append(Buffer, First), %generate the buffer to send
      ToTest = getId(Id_Peer), %generate the address of the receiver node where the buffer have to be sent
      case whereis(ToTest) =/= undefined of true ->
        getId(Id_Peer) ! #{id_sender_brut => self(), view =>  Buffer_append},

      % if pull
        if Pull =:='true' ->
          receive %the node wait a response of the node with wich it share its view
            #{view_pull := View_receive} -> %receive the view of the peer node
              New_View = view_select(H, S, C, View_receive, View_permute),
              View_increase_Age_Pull = increaseAge(New_View),
              IDParent ! #{message => "view_sender", view => View_increase_Age_Pull} %send its new view to the node thread to update its view

              after 1500 ->%not block if the node is killed, not used because we send the view only to an alive node
                View_increase_Age = increaseAge(View_permute),
                IDParent ! #{message => "view_sender", view => View_increase_Age}

              end; %receive
        true-> % if Pull =:='true'
          View_increase_Age = increaseAge(View_permute),
          IDParent ! #{message => "view_sender", view => View_increase_Age}
        end, % if Pull =:='true'
        sender(IDParent,IDReceiver_itself, H, S, C, Pull);
      false-> %   case whereis(ToTest) =/= undefined of true ->
        sender(IDParent,IDReceiver_itself, H, S, C, Pull)
      end %   if whereis(getId(Id_Peer)) =/= undefined
  end.



node(View, IDsender,IDreceiver, H, S, C)->
  if IDreceiver =:= 1 ->
    0;
  true -> 0
  end,

  receive
    #{message := "time"}->%message received from the main thread, it is the end of a clock cycle, the sender have to send its view with a peer node
    IDsender ! View ,  
    node(View,IDsender,IDreceiver, H, S, C);
    #{message := "get_neighbors"} ->
      node(View,IDsender,IDreceiver, H, S, C);
    #{message := "view_receiver" , view := New_View}->%message received from the receiver, the view of the node have to be updated
      node(New_View, IDsender,IDreceiver, H, S, C); 
    #{message := "view_sender" , view := New_View}->%message received from the sender, the view of the node have to be updated
      node(New_View, IDsender,IDreceiver, H, S, C); 
    #{message := "dead"} ->%message received from the main thread, this node is killed and the thread have to stop
      IDsender ! "dead",
      getId(IDreceiver)! "dead";
    #{message := "ask_id_receiver", addresse_retour := Addr} ->%message received from the main thread, the node have to response with its id
      Addr ! #{message => "response_id_receiver", id_receiver => IDreceiver},
      node(View, IDsender,IDreceiver, H, S, C);
    #{message := "ask_view", addresse_retour := Addresse_retour} ->%message received from the main thread, the node have to response with its id and its view
      Addresse_retour ! #{view => View, id => IDreceiver},
      node(View, IDsender,IDreceiver, H, S, C)
  end.



%node_create create the active(sender) and pasive(receiver) thread of a node
%input: IDreceiver is the address of the passive thread (it correspond to the number of the node in the linkelist)
%       View is the view of the node of the form [#{id_neighbors=xx, age_neighbors=xx}...]
node_create(IDreceiver, View, H, S, C, Pull)->
  register(getId(IDreceiver), spawn(linkedlist, receiver, [View,self(), IDreceiver, H, S, C, Pull])),
  IDsender = spawn(linkedlist, sender, [self(),IDreceiver, H, S, C, Pull]),
  node(View, IDsender,IDreceiver, H, S, C).

%create_list_node create a linked list with NbrNode nodes.
%input : NbrNode, the number of nodes in the linkedlist
%output: A list of the form [#{id=xx, list_neighbors=xxx}...]. List neighbors is a list with the id of the neighbors. 
%           in the case of a double linked list all the node have 2 neighbors except the first.
create_list_node(NbrNode)->create_list_node(NbrNode,[]).
create_list_node(0,Acc)->Acc;
create_list_node(NbrNode,List)-> create_list_node(NbrNode-1, add(NbrNode, List)).



% node initialisation create one thread per node
% input: A, the list of node that we want to create of the form [#{id=xx, list_neigbors=xxx} ...]
% output: a list with the address of the thread of every node.
node_initialisation(A, H, S, C, Pull)->node_initialisation(A, [], H, S, C, Pull).
node_initialisation([], Acc, H, S, C, Pull)-> Acc;
node_initialisation([#{id := ID_receiver_itself, list_neighbors := View} |T], Acc, H, S, C, Pull)->
  node_initialisation(T, lists:append([spawn(linkedlist, node_create, [ID_receiver_itself, View, H, S, C, Pull])], Acc), H, S, C, Pull).

%getId transform a integer into an atom.
%for example, getId(5) = '5'
getId(Nbr)->list_to_atom(integer_to_list(Nbr)).


%increaseAge increment the age of all the element of a list
%input: View: a list of the form [#{id_neigbors=x, age_neigbors=y}...]
%output: a list [#{id_neigbors=x, age_neigbors=y}...] where age_neigbors of all the element is increment of 1.
increaseAge(View)->increaseAge(View, []).
increaseAge([], Acc)-> lists:reverse(Acc);
increaseAge([#{id_neighbors := ID, age_neighbors := Nbr}|T], Acc) -> increaseAge(T, lists:append([#{id_neighbors => ID, age_neighbors => Nbr+1}], Acc)).


%getHighestAge give the element with the highest age
%input : Vieuw, a list of the form [#{id_neigbors=x, age_neigbors=y}...]
% output : the element with the highest age of the form #{id_neigbors=x, age_neigbors=y}
%             (if 2 elements have the same age in View, the function return the first element in the list)
getHighestAge(View)-> getHighestAge(View, #{id_neighbors=> -1, age_neighbors => -1}).
getHighestAge([], Acc)-> Acc;
getHighestAge([#{id_neighbors := ID, age_neighbors := Nbr}|T], #{id_neighbors := IDMax, age_neighbors := NbrMax}) ->
  if Nbr>NbrMax -> getHighestAge(T, #{id_neighbors => ID, age_neighbors => Nbr});
  true -> getHighestAge(T, #{id_neighbors => IDMax, age_neighbors => NbrMax})
end.

%select_peer_random select a random element in a list of node with the condition that this element is an alive node
%input: View, a list of form [#{id_neighbors = x, age_neighbors = y}...]
%output: a element of form #{id_neighbors = x, age_neighbors = y} where id_neigbors correspond to the id of an alive node
select_peer_random_alive(View) ->
  case View =:= [] of true -> io:format("OKKKKKK ~p~n", [whereis(getId(-1))]),
    #{id_neighbors => -1, age_neighbors => 0};
  false ->
    #{id_neighbors := Id_Peer, age_neighbors := Age} = lists:nth(rand:uniform(length(View)), View),
    ToTest = getId(Id_Peer),
    case whereis(ToTest) =/= undefined of true -> #{id_neighbors => Id_Peer, age_neighbors => Age};
    false ->
    select_peer_random_alive(lists:delete(#{id_neighbors => Id_Peer, age_neighbors => Age},View))
  end
end.

%select_peer_random select a random element in a list
%input: View, a list
%output: a random element of the list
select_peer_random(View)->
  lists:nth(rand:uniform(length(View)), View).

%min_age return the element with the lowest age
%input: View a list of form [#{id_neighbors = x, age_neighbors = y}...]
%       Element of form #{id_neighbors = a, age_neighbors = b}
%output: The element in the list View of form #{id_neighbors = a, age_neighbors = b} with le lowest age
%         and an id_neigbors = a
min_age([], #{id_neighbors := ID_min, age_neighbors := Nbr_min})-> #{id_neighbors => ID_min, age_neighbors => Nbr_min};
min_age([#{id_neighbors := ID, age_neighbors := Nbr}|T], #{id_neighbors := ID_min, age_neighbors := Nbr_min})->
if ID =:= ID_min , Nbr<Nbr_min -> min_age(T, #{id_neighbors => ID_min, age_neighbors => Nbr});
true -> min_age(T, #{id_neighbors => ID_min, age_neighbors => Nbr_min})
end.


% remove_older remove all the element that have the same id than the reference element and keep only the element with the lowest age
%input: Tuple_ref, an element of form #{id_neighbors = x, age_neighbors = y}
%       View a list of form [#{id_neighbors = a, age_neighbors = b} ...]
%output: a list of form [#{id_neighbors = a, age_neighbors = b} ...] 
%         where there is at most one element with id_neigbors=x and this element is the one with the lowest age_neigbors
remove_older(Tuple_ref, View)-> remove_older(Tuple_ref, View, [], 'false').
remove_older(#{id_neighbors := ID_ref, age_neighbors := Nbr_ref}, [], Acc, Flag )-> lists:reverse(Acc);
remove_older(#{id_neighbors := ID_ref, age_neighbors := Nbr_ref}, [#{id_neighbors := ID, age_neighbors := Nbr}|T], Acc, Flag)->
  if ID_ref =:= ID , Nbr>Nbr_ref -> remove_older(#{id_neighbors => ID_ref, age_neighbors => Nbr_ref}, T, Acc, Flag);
  ID_ref =:= ID, Nbr =:= Nbr_ref , Flag =:= 'false' -> remove_older(#{id_neighbors => ID_ref, age_neighbors => Nbr_ref}, T, [#{id_neighbors => ID, age_neighbors => Nbr}|Acc], 'true');
  ID_ref =:= ID, Nbr =:= Nbr_ref , Flag =:= 'true' -> remove_older (#{id_neighbors => ID_ref, age_neighbors => Nbr_ref}, T, Acc, 'true');
  true -> remove_older(#{id_neighbors => ID_ref, age_neighbors => Nbr_ref}, T, [#{id_neighbors => ID, age_neighbors => Nbr}|Acc], Flag)
end.

% remove_duplicate remove all the element that have the same id_neigbors, 
%   if 2 elements have the same id, the function keeps the element with the lowest age_neigbors
% input: View, a list of form [#{id_neighbors = a, age_neighbors = b} ...] 
% output: a list of form [#{id_neighbors = a, age_neighbors = b} ...] without duplicate elements
remove_duplicate(View) -> remove_duplicate(View, View).
remove_duplicate([], Acc) -> Acc;
remove_duplicate([H|T], Acc) -> remove_duplicate(T, remove_older(H, Acc)).


nbr_to_remove(X, Y)->
  if X=<0 -> 0;
  Y=<0->0;
  true-> min(X,Y)
end.

%highest_age_to_end place the H older elements at the end of the list
%input: View, a list of form [#{id_neighbors = a, age_neighbors = b} ...] 
%       H the number of element to move at end of the list
%output: a list of form [#{id_neighbors = a, age_neighbors = b} ...] where the H last element have the highest age_neigbors
highest_age_to_end(View, H) -> highest_age_to_end(View, H, []).
highest_age_to_end([], H, Acc) -> Acc;
highest_age_to_end(View, 0, Acc) -> lists:append(View, Acc);
highest_age_to_end(View, H, Acc) -> highest_age_to_end(lists:delete(getHighestAge(View), View), H-1, [getHighestAge(View)|Acc]).


%remove_highest_age remove the H oldest element of the list
%input: View, a list of size N of form [#{id_neighbors = a, age_neighbors = b} ...] 
%       H the number of element to delete
%output: a list of size N-H of form [#{id_neighbors = a, age_neighbors = b} ...] where the H oldest element have been removed
remove_highest_age(View, 0) -> View;
remove_highest_age(View, H) ->
  remove_highest_age(lists:delete(getHighestAge(View),View),H-1).

%remove_first_element remove the S first element of the list
%input: View, a list of size N
%output: a list of size N-S where the S first elemnt have been removed
remove_first_element(View, 0) -> View;
remove_first_element([H|T], S) -> remove_first_element(T, S-1).


%view_select generate the view to send to a peer node
%input: View_receive, the view receive from a peer node of the form [#{id_neighbors = a, age_neighbors = b} ...] 
%       View, the internal view of the node of the form [#{id_neighbors = a, age_neighbors = b} ...] 
%output: a view of form [#{id_neighbors = a, age_neighbors = b} ...] to send to a peer node
view_select(H, S, C, View_receive, View) ->
  View_append = lists:append(View, View_receive),
  View_without_duplicate = remove_duplicate(View_append), %remove the element with the same id_neigbors
  View_remove_old = remove_highest_age(View_without_duplicate, nbr_to_remove(H, length(View_without_duplicate)-C)), %remove the H oldest element
  View_remove_first = remove_first_element(View_remove_old, nbr_to_remove(S, length(View_remove_old)-C)), %remove the S first element of the buffer
  remove_random(View_remove_first, max(0, length(View_remove_first)-C)). %remove random element to have a buffer size of max C


%remove_random remove N element randomly in a list
%input: View, a list of size M
%       N, the number of element to remove
%output: of size M where N element have been randomly removed
remove_random (View, 0) ->
  View;
remove_random (View, N) ->
  remove_random(lists:delete(select_peer_random(View), View), N-1).
