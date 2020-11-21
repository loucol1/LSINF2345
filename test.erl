-module(test).
-export([test_function/1]).
-import (linkedlist, [add/2,getNeighbors/2, receiver/2, sender/1, node/2, node_create/1]).

test_function(Nbr)->
  add(Nbr,[]).
