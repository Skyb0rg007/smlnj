(* debruijn.sml
 *
 * The classic example of polymorphic recursion: lambda terms with de Bruijn
 * indices represented by a nested datatype, where the body of a lambda has one
 * more free variable (represented by NONE) than the lambda itself.
 *)

fun check (name, b) = print ((if b then "ok: " else "FAIL: ") ^ name ^ "\n");

datatype 'a term
  = Var of 'a
  | App of 'a term * 'a term
  | Lam of 'a option term;

val rec mapT : ('a -> 'b) -> 'a term -> 'b term = fn f => fn
    Var x => Var (f x)
  | App (t1, t2) => App (mapT f t1, mapT f t2)
  | Lam t => Lam (mapT (Option.map f) t);

(* substitution (monadic bind) *)
val rec bindT : 'a term * ('a -> 'b term) -> 'b term = fn
    (Var x, s) => s x
  | (App (t1, t2), s) => App (bindT (t1, s), bindT (t2, s))
  | (Lam t, s) =>
      Lam (bindT (t, fn NONE => Var NONE | SOME x => mapT SOME (s x)));

val rec size : 'a term -> int = fn
    Var _ => 1
  | App (t1, t2) => size t1 + size t2
  | Lam t => 1 + size t;

(* convert a closed term to a string using the depth for variable names *)
val rec show : ('a -> string) -> int -> 'a term -> string = fn name => fn d => fn
    Var x => name x
  | App (t1, t2) => "(" ^ show name d t1 ^ " " ^ show name d t2 ^ ")"
  | Lam t =>
      let val v = "x" ^ Int.toString d
      in "(fn " ^ v ^ " => " ^ show (fn NONE => v | SOME x => name x) (d + 1) t ^ ")" end;

(* K = fn x => fn y => x *)
val k : string term = Lam (Lam (Var (SOME NONE)));
(* the free variable "f" applied to "a" *)
val fa : string term = App (Var "f", Var "a");

val _ = check ("size", size k = 3);
val _ = check ("show", show (fn s => s) 0 k = "(fn x0 => (fn x1 => x0))");
val _ = check ("mapT", show (fn s => s) 0 (mapT (fn s => s ^ "!") fa) = "(f! a!)");
(* substitute fa for "a" under binders *)
val t = Lam (App (Var NONE, Var (SOME "a")));
val _ = check ("bindT",
               show (fn s => s) 0 (bindT (t, fn "a" => fa | v => Var v))
               = "(fn x0 => (x0 (f a)))");

val _ = print "done\n";
