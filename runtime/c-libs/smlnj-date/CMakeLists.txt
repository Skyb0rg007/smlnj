# CMake configuration for the smlnj-date C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

add_library(smlnj-clib-smlnj-date STATIC
  smlnj-date-lib.c
  gmtime.c
  localoffset.c
  localtime.c
  mktime.c
  strftime.c
  unix-date.c
)
target_link_libraries(smlnj-clib-smlnj-date PRIVATE smlnj-clib-common)
