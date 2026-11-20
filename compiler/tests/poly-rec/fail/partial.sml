(* partial.sml
 *
 * The result type is not annotated, so the type of size is not completely
 * determined before the body is checked; recursive occurrences are monomorphic.
 *)
datatype 'a seq = Nil | Cons of 'a * ('a * 'a) seq;
fun size (s : 'a seq) = case s of Nil => 0 | Cons (_, s) => 1 + size s;
