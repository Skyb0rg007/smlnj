# CMake configuration for the dl C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

add_library(smlnj-clib-dl STATIC
  unix-dynload-lib.c
  dlopen.c
  dlclose.c
  dlsym.c
  dlerror.c
)
target_link_libraries(smlnj-clib-dl PRIVATE smlnj-clib-common)

target_link_libraries(smlnj-clib-dl PRIVATE ${CMAKE_DL_LIBS})
