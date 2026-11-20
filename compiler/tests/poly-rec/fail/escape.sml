(* escape.sml
 *
 * The explicit type variable 'a is unified with the type of y, which is bound
 * by an enclosing function, so it cannot be generalized.
 *)
datatype 'a seq = Nil | Cons of 'a * ('a * 'a) seq;
fun outer y =
    let val rec g : 'a seq -> 'a = fn Nil => y | Cons (_, s) => #1 (g s)
    in g end;
