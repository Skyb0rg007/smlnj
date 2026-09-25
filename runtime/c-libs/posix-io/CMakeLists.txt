# CMake configuration for the posix-io C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

smlnj_add_c_library(smlnj-clib-posix-io
  posix-io-lib.c
  osval.c
  pipe.c
  dup.c
  dup2.c
  close.c
  read.c
  readbuf.c
  write.c
  writebuf.c
  fcntl_d.c
  fcntl_gfd.c
  fcntl_sfd.c
  fcntl_gfl.c
  fcntl_sfl.c
  fcntl_l.c
  lseek.c
  fsync.c
)
