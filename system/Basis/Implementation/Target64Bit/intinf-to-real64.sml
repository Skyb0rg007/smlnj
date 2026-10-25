(* intinf-to-real64.sml
 *
 * COPYRIGHT (c) 2020 The Fellowship of SML/NJ (https://smlnj.org)
 * All rights reserved.
 *
 * Conversion from IntInf.int to 64-bit reals.  This conversion depends on the target
 * word size, since that determines the number of digits used in the conversion.
 *)

structure IntInfToReal64 : sig

    val cvt : IntInf.int -> Real64.real

  end = struct

    structure W = InlineT.Word
    structure W64 = InlineT.Word64

    val fromInt64 : Int64.int -> real = InlineT.Real64.from_int64
    fun w2r w = fromInt64(InlineT.Int64.fromLarge(InlineT.Word.toLargeInt w))
    val baseBits = InlineT.Word.toIntX CoreIntInf.baseBits

  (* some protection against insanity... *)
    val _ = if baseBits <> 62
	  then raise Fail "unexpected baseBits in intinf implementation"
	  else ()

    fun cvt (x : IntInf.int) = let
	  val CoreIntInf.BI{ negative, digits } = CoreIntInf.concrete x
	  fun dosign (x : real) = if negative then ~x else x
	(* For numbers of more than one "big digit", we take the 63 most significant
	 * bits of the number, with a "sticky" bit or-ed into the least-significant
	 * position that records if any of the discarded bits are nonzero.  Converting
	 * this value to a real rounds it correctly (the rounding position is above
	 * the sticky bit), so we only have to scale the result by the number of
	 * discarded bits.  Note that we cannot convert the digits separately and add
	 * them, since that rounds more than once.
	 *)
	  fun calc (k, sticky, lo, hi, []) = let
		val lo = W.toLarge lo
		val hi = W.toLarge hi
	      (* the number of significant bits in hi (1 <= nb <= baseBits) *)
		val nb = 64 - W64.cntLeadingZeros hi
		val shift = W.fromInt(nb - 1)
		val m = W64.orb(W64.lshift(hi, W.fromInt(63 - nb)), W64.rshiftl(lo, shift))
		val sticky = sticky
		      orelse (W64.andb(lo, W64.lshift(0w1, shift) - 0w1) <> 0w0)
		val m = if sticky then W64.orb(m, 0w1) else m
		val r = fromInt64(InlineT.Int64.fromLarge(W64.toLargeInt m))
		in
		  dosign (Assembly.A.scalb (r, k + (nb - 1)))
		end
	    | calc (k, sticky, d0, d1, d2 :: r) =
		calc (k + baseBits, sticky orelse (d0 <> 0w0), d1, d2, r)
	  in
	    case digits
	     of [] => 0.0
	      | [d] => dosign (w2r d)
	      | d1 :: d2 :: r => calc (0, false, d1, d2, r)
	    (* end case *)
	  end

  end
