# CMake configuration for the posix-error C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

add_library(smlnj-clib-posix-error STATIC
  posix-error-lib.c
  posix-name-val.c
  errmsg.c
  geterror.c
  listerrors.c
  tbl-errno.c
)
target_link_libraries(smlnj-clib-posix-error PRIVATE smlnj-clib-common)
