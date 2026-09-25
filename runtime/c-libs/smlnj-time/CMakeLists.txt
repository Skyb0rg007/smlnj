# CMake configuration for the smlnj-time C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

smlnj_add_c_library(smlnj-clib-smlnj-time
  smlnj-time-lib.c
  gettime.c
  timeofday.c
)
