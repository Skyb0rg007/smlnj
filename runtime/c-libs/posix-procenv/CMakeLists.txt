# CMake configuration for the posix-procenv C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

# the table of _SC_ names, which is generated from <unistd.h>
smlnj_gen_posix_names(_SC_ ml_sysconf.h)

add_library(smlnj-clib-posix-procenv STATIC
  posix-procenv-lib.c
  getpid.c
  getppid.c
  getuid.c
  geteuid.c
  getgid.c
  getegid.c
  setuid.c
  setgid.c
  getgroups.c
  getlogin.c
  getpgrp.c
  setsid.c
  setpgid.c
  uname.c
  time.c
  times.c
  getenv.c
  environ.c
  ctermid.c
  ttyname.c
  sysconf.c
  isatty.c
  ${CMAKE_CURRENT_BINARY_DIR}/ml_sysconf.h
)
target_link_libraries(smlnj-clib-posix-procenv PRIVATE smlnj-clib-common)
target_include_directories(smlnj-clib-posix-procenv PRIVATE ${CMAKE_CURRENT_BINARY_DIR})
