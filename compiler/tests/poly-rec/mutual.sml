(* mutual.sml
 *
 * Mutually recursive functions that call each other at different types.
 * Also checks that an unannotated function in the same declaration may use an
 * annotated one at several different types.
 *)

fun check (name, b) = print ((if b then "ok: " else "FAIL: ") ^ name ^ "\n");

datatype 'a seq = Nil | Cons of 'a * ('a * 'a) seq;

(* evens calls odds with 'b = 'a * 'a; odds calls evens at ('b * 'b) *)
val rec evens : 'a seq -> 'a list = fn
    Nil => []
  | Cons (x, s) => x :: odds (fn (a, b) => [a, b]) s
and odds : ('b -> 'a list) -> 'b seq -> 'a list = fn f => fn
    Nil => []
  | Cons (p, s) => f p @ List.concat (List.map (fn (q, r) => f q @ f r) (evens s));

val _ = check ("evens", evens (Cons (1, Cons ((2, 3), Cons (((4, 5), (6, 7)), Nil)))) = [1,2,3,4,5,6,7]);

val rec len : 'a seq -> int = fn
    Nil => 0
  | Cons (_, s) => 1 + len s
and both = fn () => len (Cons (1, Nil)) + len (Cons ("a", Cons (("b", "c"), Nil)));

val _ = check ("both", both () = 3);

val _ = print "done\n";
