# CMake configuration for the posix-error C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

smlnj_add_c_library(smlnj-clib-posix-error
  posix-error-lib.c
  posix-name-val.c
  errmsg.c
  geterror.c
  listerrors.c
  tbl-errno.c
)
