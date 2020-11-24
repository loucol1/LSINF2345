-module(linkedlist).
-export([create_list_node/1, node_initialisation/4, getId/1]).






add(ID,[])->[#{id => ID, list_neighbors => []}];
add(ID,[ #{id := IDprev, list_neighbors := List_neigh_prev} |T ])->
  [#{id =>ID, list_neighbors => [#{id_neighbors=>IDprev, age_neighbors=>0}]}, #{id => IDprev, list_neighbors => lists:append([#{id_neighbors=>ID,age_neighbors=>0}],List_neigh_prev)  } |T].


getNeighbors(IDNode,[])-> "error, IDNode is not in the given list";
getNeighbors(IDNode, [#{id := IDNode,list_neighbors:= List_neigh}|T])-> List_neigh;
getNeighbors(IDNode, [H|T])->getNeighbors(IDNode, T).

receiver(View, IDParent, H, S, C)->
  receive
    View_receive -> %le receiver recoit une view d'un autre noeud. Pour le moment, il l'append a sa list de view
      % if pull
      View_select = view_select(H, S, C, View_receive, View),
      New_view = increaseAge(View_select),
      IDParent ! #{message => "view_receiver", view => New_view}
    end,
receiver(New_view, IDParent, H, S, C).

sender(IDParent, H, S, C)->
  receive
    View-> % le sender va devoir envoyer un message a un autre node. Pour le moment, il l'envoie au premier noeud de la list
      #{id_neighbors := Id_Peer, age_neighbors := Age} = select_peer_random(View),
      % if push
      Buffer = [#{id_neighbors=>self(), age_neighbors=>0}],
      View_permute = highest_age_to_end(View, H),
      {First, Second} = lists:split(min(length(View_permute), floor(c/2)-1), View_permute),
      Buffer_append = lists:append(Buffer, First),
      getId(Id_Peer) ! Buffer_append,

      % if pull

      View_increase_Age = increaseAge(View_permute),
      IDParent ! #{message => "view_sender", view => View_increase_Age}

    end,
    sender(IDParent, H, S, C).


node(View, IDsender, H, S, C)->
  receive
    #{message := "time"}->
    IDsender ! View ,  %message recu du main thread => le sender doit envoyer un message a un noeud voisin
    node(View,IDsender, H, S, C);
    #{message := "get_neighbors"} ->
      node(View,IDsender, H, S, C);
    #{message := "view_receiver" , view := New_View}->
      if self() =:= '1' ->
        io:format("neighbors updated : ~p~n", [New_View]),
        node(New_View, IDsender, H, S, C); %message recu de la prt du receiver => mise a jour de la view
      true ->
         node(New_View, IDsender, H, S, C) %message recu de la prt du receiver => mise a jour de la view
      end;
    #{message := "view_sender" , view := New_View}->
      node(New_View, IDsender, H, S, C) %message recu de la prt du sender => mise a jour de la view
  end.



node_create(IDreceiver, View, H, S, C)->
  register(getId(IDreceiver), spawn(linkedlist, receiver, [View,self(), H, S, C])),
  IDsender = spawn(linkedlist, sender, [self(), H, S, C]),
  node(View, IDsender, H, S, C).


create_list_node(NbrNode)->create_list_node(NbrNode,[]).
create_list_node(0,Acc)->lists:reverse(Acc);
create_list_node(NbrNode,List)-> create_list_node(NbrNode-1, add(NbrNode, List)).

% A is a list of node (output of create_list_node)
node_initialisation(A, H, S, C)->node_initialisation(A, [], H, S, C).
node_initialisation([], Acc, H, S, C)-> Acc;
node_initialisation([#{id := ID, list_neighbors := List_neigh} |T], Acc, H, S, C)->
  io:format("ligne 83: ~n", []),
  node_initialisation(T, lists:append([spawn(linkedlist, node_create, [ID, List_neigh, H, S, C])], Acc), H, S, C).


getId(Nbr)->list_to_atom(integer_to_list(Nbr)).


increaseAge(View)->increaseAge(View, []).
increaseAge([], Acc)-> lists:reverse(Acc);
increaseAge([#{id_neighbors := ID, age_neighbors := Nbr}|T], Acc) -> increaseAge(T, lists:append([#{id_neighbors => ID, age_neighbors => Nbr+1}], Acc)).


%input : a vieuw
% output : getHighestAge renvoie le neighbor avec le plus grand age.
%Si deux neighbor ont le meme age, getHighestAge renvoie le premier neighbor qui apparait dans la liste
getHighestAge(View)-> getHighestAge(View, #{id_neighbors=> -1, age_neighbors => -1}).
getHighestAge([], Acc)-> Acc;
getHighestAge([#{id_neighbors := ID, age_neighbors := Nbr}|T], #{id_neighbors := IDMax, age_neighbors := NbrMax}) ->
  if Nbr>NbrMax -> getHighestAge(T, #{id_neighbors => ID, age_neighbors => Nbr});
  true -> getHighestAge(T, #{id_neighbors => IDMax, age_neighbors => NbrMax})
end.


select_peer_random(View) ->
    lists:nth(rand:uniform(length(View)), View).




%do_i_have_to_delete([], Element)->'false'; %return true if there is an other element in the view with a lower age
%do_i_have_to_delete([#{id_neighbors := ID, age_neighbors := Nbr}|T], #{id_neighbors := ID_elem, age_neighbors := Nbr_elem})->
%  if ID =:= ID_elem , Nbr_elem > Nbr -> 'true';
%  true -> do_i_have_to_delete(T, #{id_neighbors => ID_elem, age_neighbors => Nbr_elem})
%end.

%delete_element_in_View(View, Element)->delete_element_in_View(View, Element, []).
%delete_element_in_View([], Element, Acc)->lists:reverse(Acc);
%delete_element_in_View([#{id_neighbors := ID, age_neighbors := Nbr}|T], #{id_neighbors := ID_elem, age_neighbors := Nbr_elem}, Acc)->
%  if


%delete_duplicate(View)-> delete_duplicate(lists:reverse(sets:to_list(sets:from_list(View)), []). %permet d'enlever des elements qui ont le meme ID et le meme age
%delete_duplicate([], Acc)->lists:reverse(Acc);
%delete_duplicate([#{id_neighbors := ID, age_neighbors := Nbr}|T], Acc )->



min_age([], #{id_neighbors := ID_min, age_neighbors := Nbr_min})-> #{id_neighbors => ID_min, age_neighbors => Nbr_min};
min_age([#{id_neighbors := ID, age_neighbors := Nbr}|T], #{id_neighbors := ID_min, age_neighbors := Nbr_min})->
if ID =:= ID_min , Nbr<Nbr_min -> min_age(T, #{id_neighbors => ID_min, age_neighbors => Nbr});
true -> min_age(T, #{id_neighbors => ID_min, age_neighbors => Nbr_min})
end.


remove_older(Tuple_ref, View)-> remove_older(Tuple_ref, View, [], 'false').
remove_older(#{id_neighbors := ID_ref, age_neighbors := Nbr_ref}, [], Acc, Flag )-> lists:reverse(Acc);
remove_older(#{id_neighbors := ID_ref, age_neighbors := Nbr_ref}, [#{id_neighbors := ID, age_neighbors := Nbr}|T], Acc, Flag)->
  if ID_ref =:= ID , Nbr>Nbr_ref -> remove_older(#{id_neighbors => ID_ref, age_neighbors => Nbr_ref}, T, Acc, Flag);
  ID_ref =:= ID, Nbr =:= Nbr_ref , Flag =:= 'false' -> remove_older(#{id_neighbors => ID_ref, age_neighbors => Nbr_ref}, T, [#{id_neighbors => ID, age_neighbors => Nbr}|Acc], 'true');
  ID_ref =:= ID, Nbr =:= Nbr_ref , Flag =:= 'true' -> remove_older (#{id_neighbors => ID_ref, age_neighbors => Nbr_ref}, T, Acc, 'true');
  true -> remove_older(#{id_neighbors => ID_ref, age_neighbors => Nbr_ref}, T, [#{id_neighbors => ID, age_neighbors => Nbr}|Acc], Flag)
end.

remove_duplicate(View) -> remove_duplicate(View, View).
remove_duplicate([], Acc) -> Acc;
remove_duplicate([H|T], Acc) -> remove_duplicate(T, remove_older(H, Acc)).

test_remove_duplicate() ->
  List = [#{id_neighbors => 1, age_neighbors => 8}, #{id_neighbors => 2, age_neighbors => 5}, #{id_neighbors => 1, age_neighbors => 8}, #{id_neighbors => 3, age_neighbors => 0}, #{id_neighbors => 2, age_neighbors => 8} ],
  remove_duplicate(List).


nbr_to_remove(X, Y)->
  if X=<0 -> 0;
  Y=<0->0;
  true-> min(X,Y)
end.

% La fonction place les H plus vieux éléments à la fin de la liste View
highest_age_to_end(View, H) -> highest_age_to_end(View, H, []).
highest_age_to_end(View, 0, Acc) -> lists:append(View, Acc);
highest_age_to_end(View, H, Acc) -> highest_age_to_end(lists:delete(getHighestAge(View), View), H-1, getHighestAge(View)).

% La fonction retire les H plus view élements de la liste View
remove_highest_age(View, 0) -> View;
remove_highest_age(View, H) ->
  remove_highest_age(lists:delete(getHighestAge(View),View),H-1).

% La fonction retire les S premiers éléments de la liste
remove_first_element(View, 0) -> View;
remove_first_element([H|T], S) -> remove_first_element(T, S-1).

view_select(H, S, C, View_receive, View) ->
  View_append = lists:append(View, View_receive),
  View_without_duplicate = remove_duplicate(View_append),
  View_remove_old = remove_highest_age(View_without_duplicate, nbr_to_remove(H, length(View_without_duplicate)-C)),
  View_remove_first = remove_first_element(View_remove_old, nbr_to_remove(S, length(View_remove_old)-C)),
  remove_random(View_remove_first, max(0, length(View_remove_first)-C)).


% N est le nombre d element a enlever
remove_random (View, 0) ->
  View;
remove_random (View, N) ->
  remove_random(lists:delete(select_peer_random(View), View), N-1).
