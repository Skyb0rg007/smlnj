# CMake configuration for the smlnj-date C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

smlnj_add_c_library(smlnj-clib-smlnj-date
  smlnj-date-lib.c
  gmtime.c
  localoffset.c
  localtime.c
  mktime.c
  strftime.c
  unix-date.c
)
