-module(board).
-author('sempetmer@gmail.com').

-export([new/3, swap/3, width/1, height/1, get_element/2, no_groups/2]).

%% Generate a W by H board of elements in 1..N.
new(W, H, N)
  when W > 0, H > 0, N > 1 ->
    {[Board | _Boards], _Points} = no_groups(cols(W, H, N), N),
    Board.
cols(0, _H, _N) -> [];
cols(W, H, N) ->
    [col(H, N) | cols(W - 1, H, N)].
col(0, _N) -> [];
col(W, N) ->
    [random:uniform(N) | col(W - 1, N)].

%% Clear groups in a board and refill from 1..N recursively until
%% there are no groups.
no_groups(Board, N)
  when N > 1 ->
    no_groups(Board, N, [], 0).
no_groups(Board, N, Boards, Points) ->
    Marked = mark(Board),
    case points(Marked) of
        0 -> {[Board | Boards], round(Points * math:pow(1.1, length(Boards)))};
        MorePoints -> no_groups(refill(Marked, N), N,
                                [Marked, Board] ++ Boards,
                                Points + MorePoints)
    end.

%% Transpose a board.
transpose(Columns) -> % add accumulator and token
    transpose([token | Columns], []).
transpose([token,[] | _], Rows) -> % base case, we're done
    lists:reverse([lists:reverse(Row) || Row <- Rows]);
transpose([token, [Head | Tail] | Columns], Rows) -> % create a new column
    transpose(Columns ++ [token | [Tail]], [[Head] | Rows]);
transpose([[Head | Tail] | Columns], [Row | Rows]) -> % keep on truckin'
    transpose(Columns ++ [Tail], [[Head | Row] | Rows]).

%% Returns an element at a given coordinate in a board.
get_element(Board, {X, Y})
  when X > 0, Y > 0 ->
    lists:nth(Y, lists:nth(X, Board)).

%% Apply a function on the Nth element in a list, and replace the
%% element with the result.
apply_nth([Head | Tail], 1, Fun) ->
    [Fun(Head) | Tail];
apply_nth([Head | Tail], N, Fun)
  when N > 1, N =< length(Tail) + 1 ->
    [Head | apply_nth(Tail, N - 1, Fun)].

%% Sets the element at a given coordinate in a board to a new element.
set_element(Board, {X, Y}, Element)
  when X > 0, Y > 0 ->
    ReplaceInCol = fun (C) -> apply_nth(C, Y, fun (_) -> Element end) end,
    apply_nth(Board, X, ReplaceInCol).

%% Swaps two elements in a board.
swap(Board, {X1, Y1}, {X2, Y2})
  when abs(X1 - X2) == 1, Y1 == Y2; abs(Y1 - Y2) == 1, X1 == X2 ->
    A = get_element(Board, {X1, Y1}),
    B = get_element(Board, {X2, Y2}),
    NewBoard = set_element(set_element(Board, {X1, Y1}, B), {X2, Y2}, A),
    case points(mark(NewBoard)) of
        P when P > 0 ->
            {ok, NewBoard};
        _ ->
            {error, "only scoring pairs can be swapped"}
    end;

swap(_, _, _) ->
    {error, "only adjacent elements can be swapped"}.

%% Replace all groups of three or more in the board with x.
mark(Board) ->
    lists:zipwith(fun mask_line/2,
                  transpose(mark_rows(Board)), mark_cols(Board)).

%% Replace all elements in column groups of three or more with x.
mark_cols(Board) ->
    [mark_line(Col) || Col <- Board].

%% Replace all elements in row groups of three or more with x.
mark_rows(Board) ->
    [mark_line(Row) || Row <- transpose(Board)].

%% Replace all elements in groups of three or more with x in a line.
mark_line([]) -> [];
mark_line([E, E, E | Tail]) ->
    {Group, Rest} = lists:splitwith(fun (X) -> X == E end, Tail),
    [x, x, x | [x || _ <- Group]] ++ mark_line(Rest);
mark_line([E | Tail]) ->
    [E | mark_line(Tail)].

%% Mask a line with x.
mask_line([], []) -> [];
mask_line([x | Mask], [_ | Line]) ->
    [x | mask_line(Mask, Line)];
mask_line([_ | Mask], [E | Line]) ->
    [E | mask_line(Mask, Line)].

%% Compute the score for a marked board.
points(Board) ->
    length([ E || E <- lists:flatten(Board), E == x]).

%% Clear all x from a marked board and refill with new elements from 1..N.
refill(Board, N)
  when N > 1 ->
    Height = length(hd(Board)),
    Cleared = [[ E || E <- C, E /= x] || C <- Board],
    [col(Height - length(L), N) ++ L || L <- Cleared].

%% Clear all marked elements on a board
sweep(Board) ->
    lists:map(fun (C) -> [ E || E <- C, E /= x] end, Board).

width(Board) ->
    length(Board).

height(Board) ->
    length(hd(Board)).
