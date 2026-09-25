# CMake configuration for the posix-os C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

smlnj_add_c_library(smlnj-clib-posix-os
  posix-os-lib.c
  poll.c
  tmpname.c
)
