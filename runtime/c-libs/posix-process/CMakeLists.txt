# CMake configuration for the posix-process C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

add_library(smlnj-clib-posix-process STATIC
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
target_link_libraries(smlnj-clib-posix-process PRIVATE smlnj-clib-common)
