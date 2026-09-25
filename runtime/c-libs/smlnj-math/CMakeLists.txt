# CMake configuration for the smlnj-math C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

add_library(smlnj-clib-smlnj-math STATIC
  smlnj-math-lib.c
  ctlrndmode.c
  atan64.c
  cos64.c
  exp64.c
  log64.c
  sin64.c
  sqrt64.c
)
target_link_libraries(smlnj-clib-smlnj-math PRIVATE smlnj-clib-common)

# libm is a separate library on most Unix systems, but not on macOS
target_link_libraries(smlnj-clib-smlnj-math PRIVATE $<$<NOT:$<PLATFORM_ID:Darwin>>:m>)
