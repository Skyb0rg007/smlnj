# CMake configuration for the smlnj-time C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

add_library(smlnj-clib-smlnj-time STATIC
  smlnj-time-lib.c
  gettime.c
  timeofday.c
)
target_link_libraries(smlnj-clib-smlnj-time PRIVATE smlnj-clib-common)
