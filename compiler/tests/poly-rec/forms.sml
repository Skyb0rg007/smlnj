(* forms.sml
 *
 * The syntactic forms that enable polymorphic recursion: the type of the
 * function must be completely determined by explicit type annotations before
 * its body is type checked.
 *)

fun check (name, b) = print ((if b then "ok: " else "FAIL: ") ^ name ^ "\n");

datatype 'a seq = Nil | Cons of 'a * ('a * 'a) seq;

val s = Cons ("a", Cons (("b", "c"), Cons ((("d", "e"), ("f", "g")), Nil)));

(* a type constraint on the val rec bound variable *)
val rec depth1 : 'a seq -> int = fn Nil => 0 | Cons (_, s) => 1 + depth1 s;
val _ = check ("val rec constraint", depth1 s = 3);

(* a type constraint on the fn expression *)
val rec depth2 = (fn Nil => 0 | Cons (_, s) => 1 + depth2 s) : 'a seq -> int;
val _ = check ("fn constraint", depth2 s = 3);

(* a fun declaration with a single argument, with the argument and result types
 * both annotated *)
fun depth3 (s : 'a seq) : int = case s of Nil => 0 | Cons (_, s) => 1 + depth3 s;
val _ = check ("fun annotations", depth3 s = 3);

fun depth4 (k : int, s : 'a seq) : int = case s of Nil => k | Cons (_, s) => depth4 (k + 1, s);
val _ = check ("fun tuple annotations", depth4 (0, s) = 3);

(* a type abbreviation that reorders its type variables *)
type ('a, 'b) fn' = 'b -> 'a;
val rec depth5 : (int, 'a seq) fn' = fn Nil => 0 | Cons (_, s) => 1 + depth5 s;
val _ = check ("type abbreviation", depth5 s = 3);

(* equality type variables *)
val rec member : ''a * ''a seq -> bool = fn
    (_, Nil) => false
  | (x, Cons (y, s)) => x = y orelse member ((x, x), s);
val _ = check ("eqtype 1", member ("a", s));
val _ = check ("eqtype 2", member ("b", Cons ("b", Nil)));
val _ = check ("eqtype 3", not (member ("b", s)));

val _ = print "done\n";
