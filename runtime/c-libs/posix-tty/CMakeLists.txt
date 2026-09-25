# CMake configuration for the posix-tty C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

add_library(smlnj-clib-posix-tty STATIC
  posix-tty-lib.c
  osval.c
  tcdrain.c
  tcflow.c
  tcflush.c
  tcgetattr.c
  tcgetpgrp.c
  tcsendbreak.c
  tcsetattr.c
  tcsetpgrp.c
  getwinsz.c
)
target_link_libraries(smlnj-clib-posix-tty PRIVATE smlnj-clib-common)
