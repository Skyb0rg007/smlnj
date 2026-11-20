(* local.sml
 *
 * Polymorphic recursion in local declarations: with free variables, with type
 * variables bound by an enclosing declaration, and with the recursive call
 * occurring inside an inner polymorphic function.
 *)

fun check (name, b) = print ((if b then "ok: " else "FAIL: ") ^ name ^ "\n");

datatype 'a seq = Nil | Cons of 'a * ('a * 'a) seq;

fun outer (k : int) (z : 'z) =
    let val rec len : 'b seq -> int = fn
            Nil => k
          | Cons (_, s) => 1 + len s
        (* 'z is bound by outer, so it is fixed within pairUp; 'b is generalized *)
        val rec pairUp : int * 'b * 'z -> ('b * 'z) list = fn
            (0, b, z') => [(b, z')]
          | (n, b, z') => List.map (fn ((_, b'), z'') => (b, z'')) (pairUp (n - 1, (b, b), z'))
    in (len (Cons (z, Cons ((z, z), Nil))), pairUp (3, 1, z))
    end;

val _ = check ("outer", outer 100 "x" = (102, [(1, "x")]));

fun f (x : int) =
    let fun g (y : 'c) =
            let val rec h : 'a seq -> 'c -> int = fn
                    Nil => (fn _ => x)
                  | Cons (_, s) =>
                      let fun poly w = (h s y; w)   (* polymorphic in w *)
                      in fn c => 1 + poly (h s c) end
            in h (Cons (y, Cons ((y, y), Nil))) y end
    in (g "s", g 1.5) end;

val _ = check ("nested", f 10 = (12, 12));

val _ = print "done\n";
