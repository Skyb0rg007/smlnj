(* nested.sml
 *
 * Polymorphic recursion over a nested (non-regular) datatype: the tail of an
 * 'a seq is an ('a * 'a) seq, so every function that recurses over a seq must
 * call itself at a different type.
 *)

fun check (name, b) = print ((if b then "ok: " else "FAIL: ") ^ name ^ "\n");

datatype 'a seq = Nil | Cons of 'a * ('a * 'a) seq;

val rec size : 'a seq -> int = fn
    Nil => 0
  | Cons (_, s) => 1 + 2 * size s;

val rec map : ('a -> 'b) -> 'a seq -> 'b seq = fn f => fn
    Nil => Nil
  | Cons (x, s) => Cons (f x, map (fn (a, b) => (f a, f b)) s);

val rec toList : 'a seq -> 'a list = fn
    Nil => []
  | Cons (x, s) => x :: List.concat (List.map (fn (a, b) => [a, b]) (toList s));

(* build a seq with n levels holding the elements 1 .. 2^n - 1 *)
val rec build : int * int * int -> 'a -> ('a -> int -> 'a) -> 'a seq =
  fn (n, i, w) => fn x => fn next =>
    if n = 0 then Nil
    else Cons (next x i,
               build (n - 1, i + w, 2 * w) (x, x)
                 (fn (a, b) => fn j => (next a j, next b (j + w))));

val s3 = Cons (1, Cons ((2, 3), Cons (((4, 5), (6, 7)), Nil)));

val _ = check ("size", size s3 = 7);
val _ = check ("toList", toList s3 = [1,2,3,4,5,6,7]);
val _ = check ("map", toList (map Int.toString s3) = ["1","2","3","4","5","6","7"]);
val _ = check ("build", toList (build (3, 1, 1) 0 (fn _ => fn i => i)) = [1,2,3,4,5,6,7]);

(* a deep seq: 2^20 - 1 elements *)
val big = build (20, 1, 1) 0 (fn _ => fn i => i);
val _ = check ("size big", size big = 1048575);

val _ = print "done\n";
