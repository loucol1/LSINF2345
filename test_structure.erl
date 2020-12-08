-module(test_structure).
-import(linkedlist, [create_list_node/1, add/2]).
-export([test_linked_list/0]).

test_linked_list() ->
    List_before_add = create_list_node(2),
    io:format("list_before_add = ~p ~n", [List_before_add]),
    List_after_add = add(3, List_before_add),
    io:format("list_after_add = ~p ~n", [List_after_add]).