:- use_module(bio(bioprolog_util)).


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

allowed(go).
allowed(ec).
allowed(metacyc).
allowed(rhea).
allowed(kegg).


p(go,ec, true, 0.01, 0.01, 0.97, 0.01).
p(go,ec, false, 0.3, 0.15, 0.45, 0.1).
p(go,metacyc, _, 0.1, 0.1, 0.7, 0.1).
p(go,kegg, _, 0.1, 0.1, 0.7, 0.1).
p(go,rhea, _, 0.02, 0.02, 0.95, 0.01).
p(rhea,ec, _, 0.05, 0.05, 0.85, 0.05).
p(rhea,metacyc, _, 0.05, 0.05, 0.85, 0.05).

% from bto
p(ec,metacyc, _, 0.05, 0.05, 0.85, 0.05).
p(ec,kegg, _, 0.05, 0.05, 0.85, 0.05).

% det
p1(C,X,go,ec,false,0.9,0.01,0.05,0.04) :-
        entity_xref(C,X),
        entity_xref(D,X),
        subclassT(C,D),
        !,
        % see for example xrefs for EC:1
        fail.
p1(C,X,go,_,false,0.9,0.01,0.05,0.04) :-
        entity_xref(C,X),
        entity_xref(D,X),
        subclassT(C,D),
        !.
p1(C,X,go,_,false,0.01,0.9,0.05,0.04) :-
        entity_xref(C,X),
        entity_xref(D,X),
        subclassT(D,C),
        !.
p1(_,_,SC,SX,V,P1,P2,P3,P4) :-
        p(SC,SX,V,P1,P2,P3,P4),
        !.

samelabel(X,Y,true) :- class(X,N),class(Y,N),!.
samelabel(_,_,false).


        

ptable(C, X, P1,P2,P3,P4) :-
        entity_xref(C,X),
        id_idspace_lc(C,SC),
        id_idspace_lc(X,SX),
        allowed(SC),
        allowed(SX),
        samelabel(C,X,V),
        p1(C,X,SC,SX,V,P1,P2,P3,P4).

id_idspace_lc(C,S) :-
        id_idspace(C,Z),
        downcase_atom(Z,S).



redundant(S,X,Y,Z) :-
        entity_xref_idspace(X,Z,S),
        subclass(X,Y),
        entity_xref(Y,Z).

report_ec_redundant(V1,V2) :-
        redundant('EC',X,Y,Z),
        (   V1-V2 = Z-''
        ;   V1-V2 = ''-Y
        ;   V1-V2 = ''-X).

redundant_set(S,Z,X,Ys) :-
        entity_xref_idspace(X,Z,S),
        solutions(Y,(subclass(X,Y),
                     entity_xref(Y,Z)),
                  Ys),
        Ys\=[].


report_redundant_set :-
        format('EC\tGO\t~n'),
        fail.
report_redundant_set :-
        entity_xref(X,Z),
        class(Z,ZN),
        solutions(Y,(subclass(Y,X),
                     entity_xref(Y,Z)),
                  Ys),
        class(X,XN),
        Ys\=[],
        length(Ys,Len),
        format('~w\t~w\t~w~n',[Z,Len,ZN]),
        format('\t~w\t~w~n',[X,XN]),
        forall(member(Y,Ys),
               (   class(Y,YN),
                   format('\t-- ~w\t-- ~w~n',[Y,YN]))),
        fail.




big_clique(X,Len,L) :-
        class(X),
        id_idspace(X,'GO'),
        xref_clique(X,['GO','EC','MetaCyc','KEGG','RHEA'],L),
        length(L,Len),
        Len>20.


allowed_id(X) :- id_idspace(X,S),downcase_atom(S,S1),allowed(S1).

sif(X,xref,Y) :-
        entity_xref(X,Y),
        allowed_id(X),
        allowed_id(Y).
sif(X,isa,Y) :-
        subclass(X,Y).


        
