(* math64-sqrt.sml
 *
 * COPYRIGHT (c) 2019 The Fellowship of SML/NJ (https://smlnj.org)
 * All rights reserved.
 *
 * Math functions for machines that have hardware support for sqrt, but
 * not for sin, cos, etc.
 *
 * The following functions were adapted from the 4.3BSD math library.
 * Eventually, each machine supported should have a hand-coded math
 * functor with more efficient versions of these functions.
 *
 ***************************************************************************
 *                                                                         *
 * Copyright (c) 1985 Regents of the University of California.             *
 *                                                                         *
 * Use and reproduction of this software are granted  in  accordance  with *
 * the terms and conditions specified in  the  Berkeley  Software  License *
 * Agreement (in particular, this entails acknowledgement of the programs' *
 * source, and inclusion of this notice) with the additional understanding *
 * that  all  recipients  should regard themselves as participants  in  an *
 * ongoing  research  project and hence should  feel  obligated  to report *
 * their  experiences (good or bad) with these elementary function  codes, *
 * using "sendbug 4bsd-bugs@BERKELEY", to the authors.                     *
 *                                                                         *
 * K.C. Ng, with Z-S. Alex Liu, S. McDonald, P. Tang, W. Kahan.            *
 * Revised on 5/10/85, 5/13/85, 6/14/85, 8/20/85, 8/27/85, 9/11/85.        *
 *                                                                         *
 ***************************************************************************
 *
 *)

structure Math64 : MATH =
  struct

    structure Word = InlineT.Word
    structure Word64 = InlineT.Word64
    structure Real64 = InlineT.Real64
    structure I = InlineT.Int

    type real = real

    infix 4 ==
    val op +  = Real64.+
    val op -  = Real64.-
    val op *  = Real64.*
    val op /  = Real64./
    val op ~  = Real64.~
    val op <  = Real64.<
    val op <= = Real64.<=
    val op >  = Real64.>
    val op >= = Real64.>=
    val op == = Real64.==

    val lessu : int * int -> bool = I.ltu

    open Math64Common

    val zero = 0.0
    val half = 0.5
    val one = 1.0
    val two = 2.0
    val plusInfinity = 1E300 * 1E300
    val NaN = 0.0 / 0.0

  (* sin/cos *)
    local
      val S0 = ~1.6666666666666463126E~1
      val S1 =  8.3333333332992771264E~3
      val S2 = ~1.9841269816180999116E~4
      val S3 =  2.7557309793219876880E~6
      val S4 = ~2.5050225177523807003E~8
      val S5 =  1.5868926979889205164E~10
    in
    fun sin__S z = (z*(S0+z*(S1+z*(S2+z*(S3+z*(S4+z*S5))))))
    end (* local *)

    local
      val C0 =  4.1666666666666504759E~2
      val C1 = ~1.3888888888865301516E~3
      val C2 =  2.4801587269650015769E~5
      val C3 = ~2.7557304623183959811E~7
      val C4 =  2.0873958177697780076E~9
      val C5 = ~1.1250289076471311557E~11
    in
    fun cos__C z = (z*z*(C0+z*(C1+z*(C2+z*(C3+z*(C4+z*C5))))))
    end (* local *)

    val PIo4   =  7.853981633974483096E~1

    local
      val thresh =  2.6117239648121182150E~1
    in
    fun S y = y + y * sin__S(y*y)
    fun C y = let
	  val yy = y*y
	  val c = cos__C yy
	  val Y = yy/two
	  in
	    if Y < thresh
	      then one - (Y - c)
	      else half - (Y - half - c)
	  end
    end (* local *)

  (* argument reduction for sin, cos, and tan: `reduce x` returns `(n, y)`, where
   * `n` is `k mod 4` for the integer `k` nearest to `x * 2/pi`, and `y` is
   * `x - k * pi/2` (so `|y| <= pi/4`).  The algorithms are from fdlibm's
   * `__ieee754_rem_pio2`: for medium-sized arguments, we subtract `k * pi/2`
   * using pi/2 split into 33-bit pieces, and for large arguments we multiply
   * by 2/pi using exact integer arithmetic and enough of its bits that the
   * fractional part of the product is accurate.
   *)
    local
      structure IntInf = IntInfImp
      val fromBits = Real64.fromBits
      val invpio2 = fromBits 0wx3FE45F306DC9C883	(* 2/pi *)
      val pio2    = fromBits 0wx3FF921FB54442D18	(* pi/2 *)
      val pio2_1  = fromBits 0wx3FF921FB54400000	(* first 33 bits of pi/2 *)
      val pio2_2  = fromBits 0wx3DD0B4611A600000	(* second 33 bits of pi/2 *)
      val pio2_2t = fromBits 0wx3BA3198A2E037073	(* pi/2 - (pio2_1+pio2_2) *)
      val pio2_3  = fromBits 0wx3BA3198A2E000000	(* third 33 bits of pi/2 *)
      val pio2_3t = fromBits 0wx397B839A252049C1	(* pi/2 - (pio2_1+pio2_2+pio2_3) *)
      val mediumLimit = fromBits 0wx413921FB00000000	(* ~ 2^20 * pi/2 *)
    (* the first 1296 bits of the binary expansion of 2/pi as an integer *)
      val twoOverPiBits = 1296
      val twoOverPi : IntInf.int = List.foldl
	    (fn (d, n) => IntInf.+(IntInf.<<(n, 0w24), IntInf.fromInt d))
	      0 [
            0xA2F983, 0x6E4E44, 0x1529FC, 0x2757D1, 0xF534DD, 0xC0DB62,
            0x95993C, 0x439041, 0xFE5163, 0xABDEBB, 0xC561B7, 0x246E3A,
            0x424DD2, 0xE00649, 0x2EEA09, 0xD1921C, 0xFE1DEB, 0x1CB129,
            0xA73EE8, 0x8235F5, 0x2EBB44, 0x84E99C, 0x7026B4, 0x5F7E41,
            0x3991D6, 0x398353, 0x39F49C, 0x845F8B, 0xBDF928, 0x3B1FF8,
            0x97FFDE, 0x05980F, 0xEF2F11, 0x8B5A0A, 0x6D1F6D, 0x367ECF,
            0x27CB09, 0xB74F46, 0x3F669E, 0x5FEA2D, 0x7527BA, 0xC7EBE5,
            0xF17B3D, 0x0739F7, 0x8A5292, 0xEA6BFB, 0x5FB11F, 0x8D5D08,
            0x560330, 0x46FC7B, 0x6BABF0, 0xCFBC20, 0x9AF436, 0x1DA9E3
	      ]
      fun medium x = let (* pi/4 < x < mediumLimit *)
	    val k = floor(x * invpio2 + half)
	    val fk = Real64.from_int k
	  (* x - fk * pio2_1 is exact, and fk * pio2_2 and fk * pio2_3 are exact *)
	    val t = x - fk * pio2_1
	    val w = fk * pio2_2
	    val r = t - w
	    val w = fk * pio2_2t - ((t - r) - w)
	    val t = r
	    val w = fk * pio2_3
	    val r = t - w
	    val w = fk * pio2_3t - ((t - r) - w)
	    in
	      (Word.andb(Word.fromInt k, 0w3), r - w)
	    end
      fun large x = let (* mediumLimit <= x < infinity *)
	  (* x = m * 2^e *)
	    val bits = Real64.toBits x
	    val e = I.-(Word64.toIntX(Word64.rshiftl(bits, 0w52)), 1075)
	    val m = Word64.orb(Word64.andb(bits, 0wxFFFFFFFFFFFFF), 0wx10000000000000)
	  (* x * 2/pi = p * 2^-s, with an error of less than 2^(53-s) *)
	    val s = Word.fromInt(I.-(twoOverPiBits, e))
	    val p = IntInf.*(Word64.toLargeInt m, twoOverPi)
	  (* the nearest integer k and the remainder p - k * 2^s *)
	    val k = IntInf.~>>(IntInf.+(p, IntInf.<<(1, Word.-(s, 0w1))), s)
	    val r = IntInf.-(p, IntInf.<<(k, s))
	  (* convert r * 2^-s to a real using the 62 most significant bits of r *)
	    val nb = if (r = 0) then 0 else I.max(0, I.-(IntInf.log2(IntInf.abs r), 61))
	    val f = Real64.from_int(IntInf.toInt(IntInf.~>>(r, Word.fromInt nb)))
	    val scale = fromBits(Word64.lshift(
		  Word64.fromInt(I.+(I.-(nb, Word.toIntX s), 1023)), 0w52))
	    in
	      (Word.fromInt(IntInf.toInt(IntInf.andb(k, 3))), f * scale * pio2)
	    end
    in
    fun reduce x = if (x < 0.0)
	  then let
	    val (n, y) = reduce (~x)
	    in
	      (Word.andb(Word.-(0w4, n), 0w3), ~y)
	    end
	  else if (x <= PIo4) then (0w0, x)
	  else if (x < mediumLimit) then medium x
	  else if (x < plusInfinity) then large x
	  else (0w0, x - x) (* inf or NaN *)
    end (* local *)

    fun sin x = (case reduce x
	   of (0w0, y) => S y
	    | (0w1, y) => C y
	    | (0w2, y) => ~(S y)
	    | (_, y) => ~(C y)
	  (* end case *))

    fun cos x = (case reduce x
	   of (0w0, y) => C y
	    | (0w1, y) => ~(S y)
	    | (0w2, y) => ~(C y)
	    | (_, y) => S y
	  (* end case *))

    fun tan x = (case reduce x
	   of ((0w0 | 0w2), y) => S y / C y
	    | (_, y) => ~(C y / S y)
	  (* end case *))

    val sqrt = MathInlineT.sqrt

    fun asin x = atan2(x, sqrt(1.0-x*x))
    fun acos x = 2.0 * atan2(sqrt((1.0-x)/(1.0+x)),1.0)

  end
