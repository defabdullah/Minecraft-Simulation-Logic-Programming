# Minecraft-Simulation-Logic-Programming
CMPE260 Principles of Programming Languages Homework. Implementation of minecreaft simulation with custom and given methods in Prolog(Logic Programming Language).

After compiling main.pro file, predicates can be given.

## Example predicates
?- state(A, O, T), State=[A, O, T], navigate to(State, 6, 5, [go_right, go_up, go_up] , 4).

?- state(A, O, T), State=[A, O, T], find castle location(State, 2, 3, 5, 6).
