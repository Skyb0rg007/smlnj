# CMake configuration for the libraries of ML-callable C functions
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#
# Each sub-directory defines a static library of C functions that are
# registered with the runtime by c-libraries.c (see clib-list.h).
#

# smlnj_add_c_library(<name> <source>...)
#
# define a C function library; the library can include files from
# the runtime's include directory, the generated headers, this directory
# (e.g., ml-c.h), and its own directory (e.g., cfun-list.h).  The functions
# allocate ML objects, so the libraries depend on the GC library.
#
function(smlnj_add_c_library name)
  add_library(${name} STATIC ${ARGN})
  smlnj_runtime_c_standard(${name})
  target_include_directories(${name} PRIVATE ${CMAKE_CURRENT_FUNCTION_LIST_DIR})
  target_link_libraries(${name} PRIVATE smlnj-runtime-common smlnj-gc)
endfunction()

# libm is a separate library on most Unix systems, but not on macOS
#
if (UNIX AND NOT APPLE)
  set(SMLNJ_NEED_LIBM ON)
endif()

# the order of these libraries matches the link order of runtime/objs/makefile
#
set(SMLNJ_C_LIBRARIES
  posix-os
  smlnj-runtime
  smlnj-signals
  smlnj-prof
  smlnj-sockets
  smlnj-time
  smlnj-date
  smlnj-math
  posix-process
  posix-procenv
  posix-filesys
  posix-io
  posix-sysdb
  posix-signal
  posix-tty
  posix-error
  codegen
  dl)

set(targets)
foreach(lib IN LISTS SMLNJ_C_LIBRARIES)
  add_subdirectory(${lib})
  list(APPEND targets smlnj-clib-${lib})
endforeach()

# the list of library targets, for linking the runtime executables
#
set(SMLNJ_C_LIBRARY_TARGETS ${targets} PARENT_SCOPE)
