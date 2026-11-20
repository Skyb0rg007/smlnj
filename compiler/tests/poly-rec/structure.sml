(* structure.sml
 *
 * Polymorphic recursion inside a structure that is opaquely matched against a
 * signature, and inside a functor body.
 *)

fun check (name, b) = print ((if b then "ok: " else "FAIL: ") ^ name ^ "\n");

signature RA_LIST =
  sig
    type 'a t
    val empty : 'a t
    val cons : 'a * 'a t -> 'a t
    val toList : 'a t -> 'a list
    val length : 'a t -> int
  end;

(* binary random-access lists *)
structure RAList :> RA_LIST =
  struct
    datatype 'a t = Nil | Zero of ('a * 'a) t | One of 'a * ('a * 'a) t
    val empty = Nil
    val rec cons : 'a * 'a t -> 'a t = fn
        (x, Nil) => One (x, Nil)
      | (x, Zero ps) => One (x, ps)
      | (x, One (y, ps)) => Zero (cons ((x, y), ps))
    fun unpair [] = [] | unpair ((a, b) :: r) = a :: b :: unpair r
    val rec toList : 'a t -> 'a list = fn
        Nil => []
      | Zero ps => unpair (toList ps)
      | One (x, ps) => x :: unpair (toList ps)
    val rec length : 'a t -> int = fn
        Nil => 0
      | Zero ps => 2 * length ps
      | One (_, ps) => 1 + 2 * length ps
  end;

fun fromList l = List.foldr RAList.cons RAList.empty l;

val _ = check ("RAList ints", RAList.toList (fromList [1,2,3,4,5,6,7,8,9,10]) = [1,2,3,4,5,6,7,8,9,10]);
val _ = check ("RAList length", RAList.length (fromList (List.tabulate (1000, fn i => i))) = 1000);
val _ = check ("RAList reals",
               ListPair.allEq Real.== (RAList.toList (fromList [1.0, 2.0, 3.0]), [1.0, 2.0, 3.0]));

functor Count (type t val weight : t -> int) =
  struct
    datatype 'a seq = Nil | Cons of 'a * ('a * 'a) seq
    val rec total : ('a -> int) -> 'a seq -> int = fn f => fn
        Nil => 0
      | Cons (x, s) => f x + total (fn (a, b) => f a + f b) s
    fun totalT s = total weight s
  end;

structure C = Count (type t = string val weight = size);

val _ = check ("functor", C.totalT (C.Cons ("a", C.Cons (("bb", "ccc"), C.Nil))) = 6);

val _ = print "done\n";
