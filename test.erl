-module(test).
-import(main_doc, [indegree_element/2, indegree/2]).
-export([test_function/0]).

test_function()->
  View1 = [#{id_neighbors => 2, age_neighbors =>0}, #{id_neighbors => 3, age_neighbors =>0}, #{id_neighbors => 4, age_neighbors =>0}],
  View2 = [#{id_neighbors => 0, age_neighbors =>0}, #{id_neighbors => 3, age_neighbors =>0}, #{id_neighbors => 4, age_neighbors =>0}, #{id_neighbors => 5, age_neighbors =>0}],
  View3 = [#{id_neighbors => 2, age_neighbors =>0}, #{id_neighbors => 1, age_neighbors =>0}, #{id_neighbors => 4, age_neighbors =>0}, #{id_neighbors => 5, age_neighbors =>0}],
  View4 = [#{id_neighbors => 2, age_neighbors =>0}, #{id_neighbors => 2, age_neighbors =>0}, #{id_neighbors => 1, age_neighbors =>0}, #{id_neighbors => 5, age_neighbors =>0}],
  View5 = [#{id_neighbors => 2, age_neighbors =>0}, #{id_neighbors => 3, age_neighbors =>0}, #{id_neighbors => 4, age_neighbors =>0}, #{id_neighbors => 1, age_neighbors =>0}],
  indegree([View1,View2, View3, View4, View5], 5).
