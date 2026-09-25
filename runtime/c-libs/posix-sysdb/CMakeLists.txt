# CMake configuration for the posix-sysdb C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

smlnj_add_c_library(smlnj-clib-posix-sysdb
  posix-sysdb-lib.c
  getgrgid.c
  getgrnam.c
  getpwuid.c
  getpwnam.c
)
