(* stage1-arm64-unix.sml
 *
 * COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
 * All rights reserved.
 *
 * The bootstrap compiler for Arm64/Unix, as used by the stage-1 compiler.  See
 * `stage1-amd64-unix.sml` for why this is not just `Arm64UnixCMB`.
 *)

structure Stage1CMB = BootstrapCompileFn (
    structure Backend = Arm64Backend
    val useStream = Backend.Interact.useStream
    val os = SMLofNJ.SysInfo.UNIX
    fun load_plugin _ _ = false)
