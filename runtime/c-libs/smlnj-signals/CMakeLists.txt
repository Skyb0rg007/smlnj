# CMake configuration for the smlnj-signals C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

add_library(smlnj-clib-smlnj-signals STATIC
  smlnj-sig-lib.c
  getsigmask.c
  getsigstate.c
  listsignals.c
  pause.c
  setsigmask.c
  setsigstate.c
)
target_link_libraries(smlnj-clib-smlnj-signals PRIVATE smlnj-clib-common)
