# CMake configuration for the libraries of ML-callable C functions
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#
# Each sub-directory defines a static library of C functions that are
# registered with the runtime by c-libraries.c (see clib-list.h).
#

# the usage requirements of the C function libraries: the libraries include
# files from the runtime's include directory, the generated headers, and this
# directory (e.g., ml-c.h); the functions allocate ML objects, so the libraries
# depend on the GC library.
#
add_library(smlnj-clib-common INTERFACE)
target_include_directories(smlnj-clib-common INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(smlnj-clib-common INTERFACE smlnj-runtime-common smlnj-gc)

# smlnj_gen_posix_names(<prefix> <output>)
#
# generate the table of POSIX names with the given prefix (_SC_ or _PC_)
# into <output> in the calling directory's binary directory.  The script
# appends to its output, so we remove any old copy first.
#
function(smlnj_gen_posix_names prefix output)
  set(out ${CMAKE_CURRENT_BINARY_DIR}/${output})
  add_custom_command(
    OUTPUT ${out}
    COMMAND ${CMAKE_COMMAND} -E rm -f ${out}
    COMMAND ${CMAKE_COMMAND} -E env
      "VERSION=${SMLNJ_RUNTIME_VERSION}"
      "CPP=${CMAKE_C_COMPILER} -E"
      /bin/sh ${SMLNJ_RUNTIME_SOURCE_DIR}/config/gen-posix-names.sh ${prefix} ${output}
    DEPENDS ${SMLNJ_RUNTIME_SOURCE_DIR}/config/gen-posix-names.sh
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMENT "Generating ${output}"
    VERBATIM)
endfunction()

# the C function libraries, in link order
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

# the libraries of the runtime programs: the C function libraries, which
# bring in the GC and memory libraries that they depend on
#
add_library(smlnj-runtime-libs INTERFACE)
foreach(lib IN LISTS SMLNJ_C_LIBRARIES)
  add_subdirectory(${lib})
  target_link_libraries(smlnj-runtime-libs INTERFACE smlnj-clib-${lib})
endforeach()
