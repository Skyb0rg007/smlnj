(* reals.sml
 *
 * Polymorphic recursion where the type variables are instantiated to real
 * (an unboxed type) and to tuples of reals.  This exercises the representation
 * (wrapping/unwrapping) coercions in the FLINT optimizer, which depend on the
 * type arguments passed at each recursive call.
 *)

fun check (name, b) = print ((if b then "ok: " else "FAIL: ") ^ name ^ "\n");

datatype 'a seq = Nil | Cons of 'a * ('a * 'a) seq;

val rec sum : ('a -> real) -> 'a seq -> real = fn f => fn
    Nil => 0.0
  | Cons (x, s) => f x + sum (fn (a, b) => f a + f b) s;

val rec map : ('a -> 'b) -> 'a seq -> 'b seq = fn f => fn
    Nil => Nil
  | Cons (x, s) => Cons (f x, map (fn (a, b) => (f a, f b)) s);

val r = Cons (1.5, Cons ((2.0, 3.0), Cons (((4.0, 5.0), (6.0, 7.25)), Nil)));

val _ = check ("sum real", Real.== (sum (fn x => x) r, 28.75));
val _ = check ("sum map real", Real.== (sum (fn x => x) (map real (Cons (1, Cons ((2, 3), Nil)))), 6.0));

(* constructors whose argument representation depends on the type *)
datatype 'a tree = Leaf of 'a | Node of ('a * 'a) tree | Opt of 'a option;

val rec tsum : ('a -> real) -> 'a tree -> real = fn f => fn
    Leaf x => f x
  | Opt NONE => 0.0
  | Opt (SOME x) => f x
  | Node t => tsum (fn (a, b) => f a + f b) t;

val rec tbuild : int -> 'a -> 'a tree = fn n => fn x =>
    if n = 0 then Opt (SOME x) else Node (tbuild (n - 1) (x, x));

val _ = check ("tsum", Real.== (tsum (fn x => x) (Node (Node (Leaf ((1.0, 2.0), (3.0, 4.5))))), 10.5));
val _ = check ("tbuild", Real.== (tsum real (tbuild 10 1), 1024.0));
val _ = check ("tbuild real", Real.== (tsum (fn x => x) (tbuild 4 0.5), 8.0));

val _ = print "done\n";
