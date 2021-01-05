# Comments

- congratulations for this great work, your report is very well written and explains clearly the design choices in your implementation; I also appreciate the figures as well as the equations saying how you compute the in-degree
- your erlang sources are compatible **only** with erlang/otp >= 21, after some fixes your code runs smoothly (see my changes in sources)
- it is clear that there is a good understanding of the curves but you do not explain how such behavior impacts the network. Here one example of what was expected: *the observed variance of in-degree when nodes recover reflects that the in-degree is not equally balanced among all nodes in the network (as shown before nodes crash)*
- Given that you decide to keep logs for the cycles required to plot, I cannot see the descriptors of those nodes that restart after crashing, although, one can see that the variance of in-degree decreases in cycle 180 with means that peers point to approximatively the same number of other nodes

# Grade
| Bootstrap network (20%) | PS service implementation (50%) | Experimental scenario (30%) | Grade in % | Points (up to 5) |
|---|---|---|---|---|
|20	|50|	25|	95|	4.75|
