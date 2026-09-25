# CMake configuration for the posix-filesys C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

# the table of _PC_ names, which is generated from <unistd.h>
smlnj_gen_posix_names(_PC_ ml_pathconf.h)

add_library(smlnj-clib-posix-filesys STATIC
  posix-filesys-lib.c
  osval.c
  chdir.c
  getcwd.c
  openf.c
  umask.c
  link.c
  rename.c
  symlink.c
  mkdir.c
  mkfifo.c
  unlink.c
  rmdir.c
  readlink.c
  stat.c
  access.c
  chmod.c
  fchmod.c
  chown.c
  fchown.c
  ftruncate.c
  utime.c
  opendir.c
  readdir.c
  rewinddir.c
  closedir.c
  pathconf.c
  ${CMAKE_CURRENT_BINARY_DIR}/ml_pathconf.h
)
target_link_libraries(smlnj-clib-posix-filesys PRIVATE smlnj-clib-common)
target_include_directories(smlnj-clib-posix-filesys PRIVATE ${CMAKE_CURRENT_BINARY_DIR})
