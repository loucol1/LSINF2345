-module(test_Sacha).

-import(linkedlist, [getHighestAge/1]).

-export([test/1, select_peer_random/1, test_highest_age_to_end/0, test_remove_highest_age/0, test_remove_first_element/0, test_remove/0]).

test(A) ->
    timer:sleep(10000),
    receive 
      #{message := M}->
        io:format("receive message : ~p~n", [M])
    end.

select_peer_random(View) ->
    lists:nth(rand:uniform(length(View)), View).



% La fonction place les H plus vieux éléments à la fin de la liste View
highest_age_to_end(View, H) -> highest_age_to_end(View, H, []).
highest_age_to_end([], H, Acc) -> Acc;
highest_age_to_end(View, 0, Acc) -> lists:append(View, Acc);
highest_age_to_end(View, H, Acc) -> highest_age_to_end(lists:delete(getHighestAge(View), View), H-1, [getHighestAge(View)|Acc]).


test_highest_age_to_end() ->
  List_test =  [#{age_neighbors => 6,id_neighbors => 3}, #{age_neighbors => 2,id_neighbors => 3}, #{age_neighbors => 5,id_neighbors => 5},#{age_neighbors => 1,id_neighbors => 5},#{age_neighbors => 1,id_neighbors => 6}],
  highest_age_to_end(List_test, 10).


% La fonction retire les H plus view élements de la liste View
remove_highest_age(View, 0) -> View;
remove_highest_age(View, H) -> 
  remove_highest_age(lists:delete(getHighestAge(View),View),H-1).

test_remove_highest_age() ->
  List_test =  [#{age_neighbors => 2,id_neighbors => 3}, #{age_neighbors => 5,id_neighbors => 5},#{age_neighbors => 1,id_neighbors => 5}],
  remove_highest_age(List_test, 2).


% La fonction retire les S premiers éléments de la liste
remove_first_element(View, 0) -> View;
remove_first_element([H|T], S) -> remove_first_element(T, S-1).

test_remove_first_element() ->
  List_test =  [#{age_neighbors => 2,id_neighbors => 3}, #{age_neighbors => 5,id_neighbors => 5},#{age_neighbors => 1,id_neighbors => 5}],
  remove_first_element(List_test, 2).


% N est le nombre d element a enlever
remove_random (View, 0) ->
  View;
remove_random (View, N) ->
  remove_random(lists:delete(select_peer_random(View), View), N-1).

test_remove() ->
  List_test =  [#{age_neighbors => 2,id_neighbors => 3}, #{age_neighbors => 5,id_neighbors => 5},#{age_neighbors => 1,id_neighbors => 5}],
  remove_random(List_test, 1).