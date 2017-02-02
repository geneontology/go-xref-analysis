
wall :-
        setof(X,c(X),Xs),
        maplist(wterm,Xs),
        fail.

wterm(X) :-
        format('[Term]~n'),
        format('id: ~w~n',[X]),
        atom_concat('EC:',Rest,X),
        concat_atom(Parts,'.',Rest),
        concat_atom(Parts,' ',N),
        format('name: enzyme ~w~n',[N]),
        forall(isa(X,Y),
               format('is_a: ~w~n',[Y])),
        nl.
               



c(X) :-
        ec(X).
c(Y) :-
        ec(X),
        isa(X,Y).



isa(X,Y) :-
        concat_atom(Parts,'.',X),
        reverse(Parts,[_|L]),
        reverse(L,L2),
        concat_atom(L2,'.',Y),
        Y\=''.



ec(X):-
        entity_xref_idspace(_,X,'EC').

p(go,ec, 0.1, 0.1, 0.7, 0.1).
p(go,metacyc, 0.1, 0.1, 0.7, 0.1).
p(go,rhea, 0.02, 0.02, 0.95, 0.01).
p(rhea,ec, 0.05, 0.05, 0.85, 0.05).
p(rhea,metacyc, 0.05, 0.05, 0.85, 0.05).

ptable(C, X, P1,P2,P3,P4) :-
        entity_xref(C,X),
        id_idspace_lc(C,SC),
        id_idspace_lc(X,SX),
        p(SC,SX,P1,P2,P3,P4).

id_idspace_lc(C,S) :-
        id_idspace(C,Z),
        downcase_atom(Z,S).


