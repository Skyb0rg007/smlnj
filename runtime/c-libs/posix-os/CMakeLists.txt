# CMake configuration for the posix-os C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

add_library(smlnj-clib-posix-os STATIC
  posix-os-lib.c
  poll.c
  tmpname.c
)
target_link_libraries(smlnj-clib-posix-os PRIVATE smlnj-clib-common)
