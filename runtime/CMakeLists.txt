# CMake configuration for the SML/NJ runtime system
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#
# This builds the runtime system for Unix systems (Linux, macOS, FreeBSD, and
# Cygwin).  It builds two programs:
#
#   run.<arch>-<opsys>    -- the interactive runtime system, which loads
#                            heap images (bin/.run/run.<arch>-<opsys>)
#   runx.<arch>-<opsys>   -- a relocatable object that contains the runtime
#                            for stand-alone programs; it is linked with a
#                            heap image by the heap2exec script
#
# The runtime is organized as a set of static libraries: the C function
# libraries (c-libs), the garbage collector and heap I/O (gc), and the memory
# system (memory).  The kernel (kernel, mach-dep, and the top-level c-libs files)
# is an object library that is linked directly into both programs.
#

enable_language(ASM)

set(SMLNJ_RUNTIME_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})


## Target architecture and operating system ##

if (CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|amd64|AMD64)$")
  set(SMLNJ_ARCH AMD64)
elseif (CMAKE_SYSTEM_PROCESSOR MATCHES "^(arm64|aarch64|ARM64)$")
  set(SMLNJ_ARCH ARM64)
else()
  message(FATAL_ERROR "unsupported architecture ${CMAKE_SYSTEM_PROCESSOR}")
endif()
string(TOLOWER ${SMLNJ_ARCH} arch)

if (CMAKE_SYSTEM_NAME STREQUAL "Linux")
  set(SMLNJ_OPSYS linux)
elseif (CMAKE_SYSTEM_NAME STREQUAL "Darwin")
  set(SMLNJ_OPSYS darwin)
elseif (CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")
  set(SMLNJ_OPSYS freebsd)
elseif (CMAKE_SYSTEM_NAME MATCHES "^CYGWIN")
  set(SMLNJ_OPSYS cygwin)
else()
  message(FATAL_ERROR "unsupported operating system ${CMAKE_SYSTEM_NAME}")
endif()

# the suffix used for the runtime programs and heap images (e.g., "amd64-linux")
set(SMLNJ_ARCH_OPSYS ${arch}-${SMLNJ_OPSYS})
# the "version" string that gen-posix-names.sh uses to select the system
set(SMLNJ_RUNTIME_VERSION v-${SMLNJ_ARCH_OPSYS})

message(STATUS "SML/NJ runtime system: ${SMLNJ_ARCH_OPSYS}")

## Compilation settings ##

# the language standard for the runtime's C code, which requires C99 (it
# also compiles as C23, which is the default of newer compilers)
#
add_library(smlnj-runtime-c-standard INTERFACE)
target_compile_features(smlnj-runtime-c-standard INTERFACE c_std_99)

add_library(smlnj-runtime-defs INTERFACE)
target_link_libraries(smlnj-runtime-defs INTERFACE smlnj-runtime-c-standard)

target_compile_definitions(smlnj-runtime-defs INTERFACE
  ARCH_${SMLNJ_ARCH} SIZE_64 OPSYS_UNIX DLOPEN INDIRECT_CFUNC)

if (SMLNJ_OPSYS STREQUAL "linux")
  target_compile_definitions(smlnj-runtime-defs INTERFACE OPSYS_LINUX _GNU_SOURCE)
elseif (SMLNJ_OPSYS STREQUAL "darwin")
  target_compile_definitions(smlnj-runtime-defs INTERFACE OPSYS_DARWIN _DARWIN_C_SOURCE)
elseif (SMLNJ_OPSYS STREQUAL "freebsd")
  target_compile_definitions(smlnj-runtime-defs INTERFACE OPSYS_FREEBSD _GNU_SOURCE)
elseif (SMLNJ_OPSYS STREQUAL "cygwin")
  target_compile_definitions(smlnj-runtime-defs INTERFACE OPSYS_CYGWIN)
endif()

# every configuration uses the GNU assembler syntax, except for Arm on macOS,
# which uses Apple's syntax
#
if (NOT (SMLNJ_OPSYS STREQUAL "darwin" AND SMLNJ_ARCH STREQUAL "ARM64"))
  target_compile_definitions(smlnj-runtime-defs INTERFACE GNU_ASSEMBLER)
endif()

if (SMLNJ_SANITIZE_ADDRESS)
  target_compile_options(smlnj-runtime-defs INTERFACE
    $<$<COMPILE_LANGUAGE:C,CXX>:-fsanitize=address>)
  target_link_options(smlnj-runtime-defs INTERFACE -fsanitize=address)
endif()

## Generated headers and the common include path ##

add_subdirectory(config)

## Libraries ##

add_subdirectory(memory)
add_subdirectory(gc)
add_subdirectory(c-libs)

## The kernel ##

set(KERNEL_SRCS
  c-libs/c-libraries.c
  c-libs/unix-raise-syserr.c
  kernel/ml-options.c
  kernel/boot.c
  kernel/load-ml.c
  kernel/run-ml.c
  kernel/globals.c
  kernel/ml-state.c
  kernel/error.c
  kernel/timers.c
  kernel/unix-timers.c
  kernel/qualify-name.c
  kernel/swap-bytes.c
  mach-dep/unix-fault.c
  mach-dep/signal-util.c
  mach-dep/unix-signal.c
  mach-dep/unix-prof.c
  mach-dep/${SMLNJ_ARCH}.prim.asm)

# the assembly code must be run through the C preprocessor
#
set_source_files_properties(mach-dep/${SMLNJ_ARCH}.prim.asm PROPERTIES
  LANGUAGE ASM
  COMPILE_OPTIONS "-x;assembler-with-cpp"
  COMPILE_DEFINITIONS _ASM_)

add_library(smlnj-kernel OBJECT ${KERNEL_SRCS})
target_include_directories(smlnj-kernel PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/c-libs)
target_link_libraries(smlnj-kernel PUBLIC smlnj-runtime-common)

## The runtime programs ##

# the interactive runtime system
#
add_executable(smlnj-run kernel/main.c)
target_link_libraries(smlnj-run PRIVATE smlnj-kernel smlnj-runtime-libs)
set_target_properties(smlnj-run PROPERTIES OUTPUT_NAME run.${SMLNJ_ARCH_OPSYS})

# the runtime system for stand-alone programs, which is a relocatable
# object (i.e., a partial link) that heap2exec links with a heap image.
#
# The system libraries (libm, libdl, librt, ...) are NOT part of this object;
# heap2exec links them (using `llvm-config --system-libs`) when it builds the
# final executable.  A partial link can only include static libraries, which
# many systems do not provide.  Moreover, a static libm requires a static
# libc (on Linux, libm depends on internal symbols of glibc), and a static
# libc breaks functions that must be dynamically linked, such as getaddrinfo
# (used by the sockets library).  LLVM declares its system libraries as link
# dependencies of its libraries, so rather than linking the library targets,
# we link the archives of their static-library closure.
#

# _smlnj_visit_static_libs(<item>)
#
# depth-first traversal of the link dependencies of <item>, recording the
# static libraries in post order in the global property _SMLNJ_STATIC_LIBS.
# The dependencies are visited in reverse, so that reversing the result keeps
# them in their original order.  Items that are not targets (system libraries
# and linker flags) are ignored.
#
function(_smlnj_visit_static_libs item)
  if (item MATCHES "^\\$<LINK_ONLY:(.+)>$")
    set(item "${CMAKE_MATCH_1}")
  endif()
  if (NOT TARGET "${item}")
    return()
  endif()
  get_target_property(aliased "${item}" ALIASED_TARGET)
  if (aliased)
    set(item "${aliased}")
  endif()
  get_property(visited GLOBAL PROPERTY _SMLNJ_VISITED)
  if ("${item}" IN_LIST visited)
    return()
  endif()
  set_property(GLOBAL APPEND PROPERTY _SMLNJ_VISITED "${item}")
  get_target_property(deps "${item}" INTERFACE_LINK_LIBRARIES)
  if (deps)
    list(REVERSE deps)
    foreach(dep IN LISTS deps)
      _smlnj_visit_static_libs("${dep}")
    endforeach()
  endif()
  get_target_property(type "${item}" TYPE)
  if (type STREQUAL "STATIC_LIBRARY")
    set_property(GLOBAL APPEND PROPERTY _SMLNJ_STATIC_LIBS "${item}")
  endif()
endfunction()

# smlnj_static_link_closure(<out-var> <library>...)
#
# set <out-var> to the static libraries that the given libraries depend on
# (including themselves) in a valid link order.  Libraries keep the order in
# which they are given and listed as dependencies, unless a dependency
# requires otherwise.
#
function(smlnj_static_link_closure out)
  set_property(GLOBAL PROPERTY _SMLNJ_VISITED)
  set_property(GLOBAL PROPERTY _SMLNJ_STATIC_LIBS)
  set(roots ${ARGN})
  list(REVERSE roots)
  foreach(lib IN LISTS roots)
    _smlnj_visit_static_libs("${lib}")
  endforeach()
  get_property(libs GLOBAL PROPERTY _SMLNJ_STATIC_LIBS)
  list(REVERSE libs)
  set(${out} ${libs} PARENT_SCOPE)
endfunction()

smlnj_static_link_closure(runx_libs smlnj-runtime-libs)
set(runx_archives)
set(runx_deps)
foreach(lib IN LISTS runx_libs)
  list(APPEND runx_archives "$<TARGET_FILE:${lib}>")
  get_target_property(imported ${lib} IMPORTED)
  if (NOT imported)
    list(APPEND runx_deps ${lib})
  endif()
endforeach()

add_executable(smlnj-runx kernel/standalone.c)
target_link_libraries(smlnj-runx PRIVATE smlnj-kernel ${runx_archives})
add_dependencies(smlnj-runx ${runx_deps})
target_link_options(smlnj-runx PRIVATE -r)
set_target_properties(smlnj-runx PROPERTIES OUTPUT_NAME runx.${SMLNJ_ARCH_OPSYS})

# the runtime programs are installed in bin/.run
#
install(TARGETS smlnj-run
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}/.run
  COMPONENT runtime)
install(PROGRAMS $<TARGET_FILE:smlnj-runx>
  DESTINATION ${CMAKE_INSTALL_BINDIR}/.run
  COMPONENT runtime)
