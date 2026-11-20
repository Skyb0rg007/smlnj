(* too-general.sml
 *
 * The annotation is more general than the body.
 *)
datatype 'a seq = Nil | Cons of 'a * ('a * 'a) seq;
val rec bad : 'a seq -> 'b = fn Nil => 0 | Cons (_, s) => bad s;
