# CMake configuration for the smlnj-math C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

smlnj_add_c_library(smlnj-clib-smlnj-math
  smlnj-math-lib.c
  ctlrndmode.c
  atan64.c
  cos64.c
  exp64.c
  log64.c
  sin64.c
  sqrt64.c
)

if (SMLNJ_NEED_LIBM)
  target_link_libraries(smlnj-clib-smlnj-math PRIVATE m)
endif()
