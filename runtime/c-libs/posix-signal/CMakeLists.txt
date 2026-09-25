# CMake configuration for the posix-signal C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

add_library(smlnj-clib-posix-signal STATIC
  posix-signal-lib.c
  osval.c
)
target_link_libraries(smlnj-clib-posix-signal PRIVATE smlnj-clib-common)
