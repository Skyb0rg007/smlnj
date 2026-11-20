(* swap.sml
 *
 * Polymorphic recursion in its simplest form: each recursive call swaps the
 * instantiation of the type variables, so it is at type 'b * 'a rather than
 * 'a * 'b.
 *)

fun check (name, b) = print ((if b then "ok: " else "FAIL: ") ^ name ^ "\n");

val rec swapN : int * ('a * 'b) -> 'a * 'b = fn
    (0, p) => p
  | (n, (x, y)) => let val (y', x') = swapN (n - 1, (y, x)) in (x', y') end;

val _ = check ("swapN 0", swapN (0, (1, "a")) = (1, "a"));
val _ = check ("swapN 5", swapN (5, (true, "b")) = (true, "b"));

(* counting the swaps: the recursive call is at ('b, 'a) *)
val rec countSwaps : int * ('a * 'b) -> int = fn
    (0, _) => 0
  | (n, (x, y)) => 1 + countSwaps (n - 1, (y, x));

val _ = check ("countSwaps", countSwaps (7, ("x", 3)) = 7);

val _ = print "done\n";
