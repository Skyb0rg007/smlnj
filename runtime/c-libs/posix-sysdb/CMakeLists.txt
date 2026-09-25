# CMake configuration for the posix-sysdb C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

add_library(smlnj-clib-posix-sysdb STATIC
  posix-sysdb-lib.c
  getgrgid.c
  getgrnam.c
  getpwuid.c
  getpwnam.c
)
target_link_libraries(smlnj-clib-posix-sysdb PRIVATE smlnj-clib-common)
