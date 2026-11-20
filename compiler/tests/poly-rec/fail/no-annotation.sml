(* no-annotation.sml
 *
 * Without a type annotation, recursive occurrences are monomorphic, so this
 * must be rejected (circularity).
 *)
datatype 'a seq = Nil | Cons of 'a * ('a * 'a) seq;
fun size Nil = 0
  | size (Cons (_, s)) = 1 + size s;
