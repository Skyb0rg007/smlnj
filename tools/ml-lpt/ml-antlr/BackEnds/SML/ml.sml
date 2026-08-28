(* ml.sml
 *
 * COPYRIGHT (c) 2015 The Fellowship of SML/NJ (https://smlnj.org)
 * All rights reserved.
 *)

structure ML=
  struct
    open MLABS
    open MLPP
  (* the callers interleave direct `TextIO.output` writes on the same
   * underlying stream, so everything queued in the pretty-printer has to
   * reach the stream before we return, or the two writers' output is
   * reordered
   *)
    fun ppML (ppStrm, e) = (ppExp (ppStrm, e); TextIOPP.flushStream ppStrm)
  end
