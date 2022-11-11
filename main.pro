% ahmet abdullah susuz
% 2019400186
% compiling: yes
% complete: yes

:- ['cmpecraft.pro'].

:- init_from_map.

% helper for return absolute difference of two number.
absolute_difference(X,Y,R) :- R is X-Y,X>=Y.
absolute_difference(X,Y,R) :- R is Y-X,Y>=X.

%returns manhattan difference of two predicate which is sum of absolute differences of x's and y's.
manhattan_distance([List1_head|List1_tail],[List2_head|List2_tail],R):-absolute_difference(List1_head,List2_head,X),
                                                                       absolute_difference(List1_tail,List2_tail,Y),R is X+Y.

%return minimum element of list.
%recursive call until there exist only 1 element.
minimum_of_list([H,S|T],Min):-H=<S, 
                              minimum_of_list([H|T],Min).
minimum_of_list([H,S|T],Min):-H>=S,
                              minimum_of_list([S|T],Min).
minimum_of_list([Min],Min).

%check given object is type of given ObjectType and manhattan distance between agent and object is same with given distance
check_type_get_distance(Object, ObjectType, MyX, MyY, Distance):-get_dict(type,Object,ObjectType),get_dict(x,Object,ObjX),get_dict(y,Object,ObjY),
                                                                    manhattan_distance([ObjX,ObjY],[MyX,MyY],Distance).

% try_distances predicate tries to find object which has less manhattan distance between agent and object
% it start search from 0 and increase one until find an object or distance become Width+Height 
try_distances(ObjectDict, ObjectType, ObjKey, Object, MyX, MyY, Distance,N):- width(W) ,height(H), Limit is W+H, N=<Limit, 
                                                                        get_dict(ObjKey,ObjectDict,Object),
                                                                        check_type_get_distance(Object, ObjectType, MyX, MyY, Distance), Distance is N.

try_distances(ObjectDict, ObjectType, ObjKey, Object, MyX, MyY, Distance,N) :-width(W) ,height(H), Limit is W+H, N=<Limit,
                                                                        try_distances(ObjectDict, ObjectType, ObjKey, Object,MyX, MyY, Distance,N+1).

%get agent location and try to find nearest object which type is given with predicate try_distances. If type is not given it return nearest object
find_nearest_type(State, ObjectType, ObjKey, Object, Distance):-State=[A,O,_],
                                                                get_dict(x,A,MyX),get_dict(y,A,MyY),
                                                                try_distances(O, ObjectType, ObjKey, Object, MyX, MyY, Distance,0),!.

% this predicate add actions according to x and y difference
% first it controls x difference and add left or right actions until x difference become zero.
% second it controls y difference and add up or down actions until y difference become zero.
% always add one action and call itself until x and y differences become zero.

take_move(0,0,ActionList,ActionList,DepthLimit):-DepthLimit>=0.

take_move(DiffX,DiffY,CurrentList,ActionList,DepthLimit):-DepthLimit>0,NewDepthLimit is DepthLimit-1,DiffX>0,NewDiffX is DiffX-1,
                                                          take_move(NewDiffX,DiffY,[go_right|CurrentList],ActionList,NewDepthLimit).

take_move(DiffX,DiffY,CurrentList,ActionList,DepthLimit):-DepthLimit>0,NewDepthLimit is DepthLimit-1,DiffX<0,NewDiffX is DiffX+1,
                                                          take_move(NewDiffX,DiffY,[go_left|CurrentList],ActionList,NewDepthLimit).

take_move(DiffX,DiffY,CurrentList,ActionList,DepthLimit):-DepthLimit>0,NewDepthLimit is DepthLimit-1,DiffY>0,NewDiffY is DiffY-1,
                                                          take_move(DiffX,NewDiffY,[go_down|CurrentList],ActionList,NewDepthLimit).

take_move(DiffX,DiffY,CurrentList,ActionList,DepthLimit):-DepthLimit>0,NewDepthLimit is DepthLimit-1,DiffY<0,NewDiffY is DiffY+1,
                                                          take_move(DiffX,NewDiffY,[go_up|CurrentList],ActionList,NewDepthLimit).

%take x and y difference between agent and given location then add suitable actions one by one.
navigate_to(State, X, Y, ActionList, DepthLimit):-State=[A,_,_],get_dict(x,A,MyX),get_dict(y,A,MyY),
                                                  DiffX is X-MyX,DiffY is Y-MyY,
                                                  take_move(DiffX,DiffY,[],ActionList,DepthLimit).

% find nearest tree and get action list to reach there from previous predicates.Then add actions to chop
chop_nearest_tree(State, ActionList) :- find_nearest_type(State,tree,_,Object,Distance),
                                        get_dict(x,Object,X),get_dict(y,Object,Y),
                                        navigate_to(State,X,Y,MoveList,Distance),
                                        append(MoveList,[left_click_c,left_click_c,left_click_c,left_click_c],ActionList).

% find nearest stone and get action list to reach there from previous predicates.Then add actions to mine
mine_nearest_stone(State, ActionList) :-find_nearest_type(State,stone,_,Object,Distance),
                                        get_dict(x,Object,X),get_dict(y,Object,Y),
                                        navigate_to(State,X,Y,MoveList,Distance),
                                        append(MoveList,[left_click_c,left_click_c,left_click_c,left_click_c],ActionList).
                                        
% find nearest food and get action list to reach there from previous predicates.Then add actions to gather
gather_nearest_food(State, ActionList):-find_nearest_type(State,food,_,Object,Distance),
                                        get_dict(x,Object,X),get_dict(y,Object,Y),
                                        navigate_to(State,X,Y,MoveList,Distance),
                                        append(MoveList,[left_click_c],ActionList).


%KB for denote object is either stone_axe or stone_pickaxe
axe_or_pickaxe(stone_axe).
axe_or_pickaxe(stone_pickaxe).

%If ItemType is stick then it controls it is craftable, if it is not add actions to chop nearest tree
collect_requirements(State, stick, []):-craftable(State,stick).
collect_requirements(State, stick, ActionList):-chop_nearest_tree(State,ActionList).

%If ItemType is either stone_axe or stone_pickaxe then it controls it is craftable, if it is not add actions to cget its requirements
%Controls lof,stick and cobblestone requirements and add actions to produce them
collect_requirements(State, ItemType, []):-axe_or_pickaxe(ItemType),craftable(State,ItemType).
collect_requirements(State, ItemType, ActionList):-State=[A,_,_],axe_or_pickaxe(ItemType),get_dict(inventory,A,Inv),item_info(ItemType,Req,_),
                                                   get_dict(log,Req,LogReq),(has(log,LogReq,Inv),NewState=State;chop_nearest_tree(State,ActionList1),execute_actions(State,ActionList1,NewState)),
                                                   get_dict(stick,Req,StickReq),(has(stick,StickReq,Inv),NewState2=NewState;(chop_nearest_tree(NewState,TempActionList2),append(TempActionList2,[craft_stick],ActionList2),execute_actions(NewState,ActionList2,NewState2))),
                                                   get_dict(cobblestone,Req,CobbleStoneReq),(has(cobblestone,CobbleStoneReq,Inv);mine_nearest_stone(NewState2,ActionList3)),
                                                   append(ActionList1,ActionList2,TempList),
                                                   append(TempList,ActionList3,ActionList).

%control location x,y is occupied by an object
my_tile_occupied(X, Y, State) :-
    State = [_, StateDict, _],
    get_dict(_, StateDict, Object),
    get_dict(x, Object, Ox),
    get_dict(y, Object, Oy),
    X = Ox, Y = Oy.

%this predicate take left corner candidate and controls its right side (3X3) to be not occupied.
%it moves from left to right until it reaches and of the line then it jumps beginning of next line.
control_all_empty(X,Y,LeftCornerX,LeftCornerY,State,LeftCornerX,LeftCornerY):- X is LeftCornerX+2,Y is LeftCornerY+2,not(my_tile_occupied(X,Y,State)),!.

control_all_empty(X,Y,LeftCornerX,LeftCornerY,State,XMin,YMin):-LeftCornerX+2>X,not(my_tile_occupied(X,Y,State)),
                                                                NewX is X+1, control_all_empty(NewX,Y,LeftCornerX,LeftCornerY,State,XMin,YMin).

control_all_empty(X,Y,LeftCornerX,LeftCornerY,State,XMin,YMin):-LeftCornerX+2=<X,Y<LeftCornerY+2,not(my_tile_occupied(X,Y,State)),
                                                                NewY is Y+1, control_all_empty(LeftCornerX,NewY,LeftCornerX,LeftCornerY,State,XMin,YMin).


% in its recursive algorithm it tries all candidate location for X=<Width-2,Y=<Height-2 as left corner of 3X3 grid
% it runs to the right until it reaches right limit then it jumps to left edge of next line.
% first one sends to control_all_empty predicate to control can this X,Y candidates be left corner of correct location
% second and third send to recursive according to control of end of line or not. 
try_all_centers(_,_,X,Y,State,XMin,YMin):-control_all_empty(X,Y,X,Y,State,XMin,YMin).

try_all_centers(Width,Height,X,Y,State,XMin,YMin):-X<Width-2,Y=<Height-2,
                                                   NewX is X+1,try_all_centers(Width,Height,NewX,Y,State,XMin,YMin).

try_all_centers(Width,Height,X,Y,State,XMin,YMin):-X>=Width-2,Y=<Height-2,NewY is Y+1,
                                                   try_all_centers(Width,Height,1,NewY,State,XMin,YMin).

% this predicate try to find 3X3 grid which is free and in map.
% it begins the recursion with sending 1,1 to try_all_centers predicate 
find_castle_location(State, XMin, YMin, XMax, YMax):-width(Width),height(Height),
                                                     try_all_centers(Width,Height,1,1,State,XMin,YMin),
                                                     XMin=<Width-2,YMin=<Height-2,
                                                     XMax is XMin+2,YMax is YMin+2.

% mine 3 stone to get 9 cobblestone which are required for castle.
% then find castle location from previous predicate.
% lastly add actions to go there and place cobblestone to make castle
make_castle(State, ActionList):-State=[A,_,_],get_dict(inventory,A,Inv),
                                ((has(cobblestone,9,Inv),TempState1=State,ActionList1=[]);(mine_nearest_stone(State, ActionList1),execute_actions(State,ActionList1,TempState1))),
                                TempState1=[TA1,_,_],get_dict(inventory,TA1,TInv1),
                                ((has(cobblestone,9,TInv1),TempState2=TempState1,ActionList2=[]);(mine_nearest_stone(TempState1, ActionList2),execute_actions(TempState1,ActionList2,TempState2))),
                                TempState2=[TA2,_,_],get_dict(inventory,TA2,TInv2),
                                ((has(cobblestone,9,TInv2),TempState3=TempState2,ActionList3=[]);(mine_nearest_stone(TempState2, ActionList3),execute_actions(TempState2,ActionList3,TempState3))),
                                width(Width),height(Height),DepthLimit is Width+Height,
                                find_castle_location(TempState3, XMin, YMin, _, _),MiddleX is XMin+1,MiddleY is YMin+1,
                                navigate_to(TempState3, MiddleX , MiddleY , ActionList4, DepthLimit),
                                append(ActionList1,ActionList2,TempList1),append(ActionList3,ActionList4,TempList2),append(TempList1,TempList2,TempList3),append(TempList3,[place_c,place_e,place_n,place_w,place_s,place_ne,place_nw,place_sw,place_se],ActionList).
