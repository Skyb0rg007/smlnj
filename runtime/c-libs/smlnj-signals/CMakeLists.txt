# CMake configuration for the smlnj-signals C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

smlnj_add_c_library(smlnj-clib-smlnj-signals
  smlnj-sig-lib.c
  getsigmask.c
  getsigstate.c
  listsignals.c
  pause.c
  setsigmask.c
  setsigstate.c
)
