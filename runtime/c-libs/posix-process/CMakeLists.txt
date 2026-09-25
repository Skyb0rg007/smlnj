# CMake configuration for the posix-process C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

smlnj_add_c_library(smlnj-clib-posix-process
  posix-process-lib.c
  osval.c
  fork.c
  exec.c
  execp.c
  exece.c
  waitpid.c
  exit.c
  kill.c
  alarm.c
  pause.c
  sleep.c
)
