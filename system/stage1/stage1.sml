(* stage1.sml
 *
 * COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
 * All rights reserved.
 *
 * The stage-1 bootstrap compiler.
 *
 * This is `CMB` packaged as a standalone program so that it can be built by an
 * older ("seed") version of SML/NJ.  Unlike `cmb-make`, the compiler running
 * here is the *new* one, so the boot files that it produces are elaborated
 * against the new primitive environment and written with the new pickler and
 * the new binfile format.
 *
 * The one thing stage 1 cannot do is generate native code: the code generator
 * lives in the runtime system, and the runtime system that stage 1 runs on
 * belongs to the seed.  It therefore records a CFG pickle in each binfile (see
 * `Control.CG.emitCFGPickle`) and leaves it to the new runtime system to
 * translate those pickles while booting the result.
 *
 * See `system/stage1-make` for how this program is built and
 * `doc/src/dev-notes/bootstrap.adoc` for where it fits in the bootstrap.
 *)

structure Stage1 : sig

    val main : string * string list -> OS.Process.status

  end = struct

    structure CMB = Stage1CMB

    val progName = "stage1"

    fun say msg = TextIO.output (TextIO.stdErr, concat msg)

    (* raised for a malformed command line; the argument is a complete message *)
    exception Usage of string

    fun usage () = say [
            "usage: ", progName, " [ options ] [ <dirbase> ]\n",
            "  options:\n",
            "    -h              -- print this message\n",
            "    -C<ctl>=<v>     -- set the compiler control <ctl> to <v>\n",
            "    -D<sym>[=<v>]   -- define the CM symbol <sym> (default value 1)\n",
            "    -U<sym>         -- undefine the CM symbol <sym>\n",
            "    -native         -- emit native code instead of CFG pickles\n",
            "  <dirbase> defaults to \"sml\"\n"
          ]

    (* split "<name>=<value>" into its two halves; a missing "=" yields an
     * empty value
     *)
    fun split spec = let
          val (name, rest) = Substring.splitl (fn c => c <> #"=") (Substring.full spec)
          in
            (Substring.string name,
             if Substring.size rest > 0
               then Substring.string (Substring.triml 1 rest)
               else "")
          end

    fun setControl spec = let
          val (name, value) = split spec
          in
            if name = ""
              then raise Usage (concat["bad -C option: `", spec, "'"])
              else (case ControlRegistry.control BasicControl.topregistry
                           (String.fields (fn c => c = #".") name)
                 of NONE => raise Usage (concat["no such control: ", name])
                  | SOME ctl => (Controls.set (ctl, value)
                      handle Controls.ValueSyntax vse => raise Usage (concat[
                          "unable to parse value `", #value vse, "' for ",
                          #ctlName vse, " : ", #tyName vse
                        ]))
                (* end case *))
          end

    fun defineSym spec = let
          val (name, value) = split spec
          in
            if name = ""
              then raise Usage (concat["bad -D option: `", spec, "'"])
            else if value = ""
              then #set (CMB.symval name) (SOME 1)
            else (case Int.fromString value
               of SOME i => #set (CMB.symval name) (SOME i)
                | NONE => raise Usage (concat[
                      "value of CM symbol ", name, " must be an integer"
                    ])
              (* end case *))
          end

    fun undefineSym name =
          if name = ""
            then raise Usage "bad -U option: missing symbol name"
            else #set (CMB.symval name) NONE

    fun main (_, args) = let
          val dirbase = ref NONE
          val native = ref false
          fun doArg "-h" = (usage (); OS.Process.exit OS.Process.success)
            | doArg "-native" = native := true
            | doArg arg = if String.isPrefix "-C" arg
                  then setControl (String.extract (arg, 2, NONE))
                else if String.isPrefix "-D" arg
                  then defineSym (String.extract (arg, 2, NONE))
                else if String.isPrefix "-U" arg
                  then undefineSym (String.extract (arg, 2, NONE))
                else if String.isPrefix "-" arg
                  then raise Usage (concat["unknown option: `", arg, "'"])
                else (case !dirbase
                   of NONE => dirbase := SOME arg
                    | SOME db => raise Usage (concat[
                          "dirbase already specified as `", db, "'"
                        ])
                  (* end case *))
          in
            (* controls can also be set from the environment *)
            ControlRegistry.init BasicControl.topregistry;
            (* the seed cannot load CM's tool plugins on our behalf, and the
             * checked-in lexer and parser sources make them unnecessary; the
             * command line can still override this with "-UNO_PLUGINS"
             *)
            #set (CMB.symval "NO_PLUGINS") (SOME 1);
            (List.app doArg args;
             (* the running runtime system is the seed's, so its code generator
              * cannot be trusted to generate code for the new target
              *)
             Control.CG.emitCFGPickle := not (!native);
             if CMB.make' (!dirbase)
               then OS.Process.success
               else OS.Process.failure)
              handle Usage msg => (
                  say [progName, ": ", msg, "\n"];
                  usage ();
                  OS.Process.failure)
          end

  end
