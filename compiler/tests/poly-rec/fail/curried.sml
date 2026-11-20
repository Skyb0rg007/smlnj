(* curried.sml
 *
 * KNOWN LIMITATION: curried fun declarations are desugared into nested fn
 * expressions over a case, so their type is not known before the body is type
 * checked, even when every argument is annotated.  Use
 * "val rec f : ty = fn ..." instead.
 *)
datatype 'a seq = Nil | Cons of 'a * ('a * 'a) seq;
fun size (k : int) (s : 'a seq) : int =
    case s of Nil => k | Cons (_, s) => 1 + size k s;
