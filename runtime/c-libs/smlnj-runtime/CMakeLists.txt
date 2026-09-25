# CMake configuration for the smlnj-runtime C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

smlnj_add_c_library(smlnj-clib-smlnj-runtime
  smlnj-runt-lib.c
  argv.c
  raw-argv.c
  shift-argv.c
  cmd-name.c
  blast-in.c
  blast-out.c
  debug.c
  dummy.c
  export-heap.c
  export-fun.c
  gc-counter.c
  gc-ctl.c
  itick.c
  mk-code-obj.c
  mkexec.c
  mkliterals.c
  record1.c
  record-concat.c
  sysinfo.c
  setitimer.c
)

# these functions access the internals of the garbage collector
target_include_directories(smlnj-clib-smlnj-runtime PRIVATE ${SMLNJ_RUNTIME_SOURCE_DIR}/gc)
