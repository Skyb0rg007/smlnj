(* stage1-amd64-unix.sml
 *
 * COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
 * All rights reserved.
 *
 * The bootstrap compiler for AMD64/Unix, as used by the stage-1 compiler.  This
 * differs from `AMD64UnixCMB` (see `system/smlnj/cmb/amd64-unix.sml`) only in
 * that it does not load CM tool plugins, which keeps `$smlnj/internal/cm0.cm`
 * -- and with it the interactive system -- out of the stage-1 program.
 *)

structure Stage1CMB = BootstrapCompileFn (
    structure Backend = AMD64CCallBackend
    val useStream = Backend.Interact.useStream
    val os = SMLofNJ.SysInfo.UNIX
    fun load_plugin _ _ = false)
