# CMake configuration for the dl C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

smlnj_add_c_library(smlnj-clib-dl
  unix-dynload-lib.c
  dlopen.c
  dlclose.c
  dlsym.c
  dlerror.c
)

target_link_libraries(smlnj-clib-dl PRIVATE ${CMAKE_DL_LIBS})
