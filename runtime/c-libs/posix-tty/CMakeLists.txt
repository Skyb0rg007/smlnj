# CMake configuration for the posix-tty C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

smlnj_add_c_library(smlnj-clib-posix-tty
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
