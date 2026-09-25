# CMake configuration for the SML/NJ runtime system
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#
# This replaces the makefiles in runtime/objs (mk.<arch>-<opsys> and
# makefile) for Unix systems.  It builds two programs:
#
#   run.<arch>-<opsys>    -- the interactive runtime system, which loads
#                            heap images (bin/.run/run.<arch>-<opsys>)
#   runx.<arch>-<opsys>   -- a relocatable object that contains the runtime
#                            for stand-alone programs; it is linked with a
#                            heap image by the heap2exec script
#
# The libraries are organized as in the makefiles: the C function libraries
# (c-libs), the garbage collector and heap I/O (gc), and the memory system
# (memory).  The kernel (kernel, mach-dep, and the top-level c-libs files)
# is an object library that is linked directly into both programs.
#

enable_language(ASM)

include(CheckCSourceCompiles)
include(CheckPIESupported)

set(SMLNJ_RUNTIME_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})

# the runtime is written in C99 with GNU extensions (the makefiles used
# -std=gnu99).  Newer compilers default to C23, which breaks the code.
#
set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS ON)

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
# the "version" string that the makefiles passed to gen-posix-names.sh
set(SMLNJ_RUNTIME_VERSION v-${SMLNJ_ARCH_OPSYS})

message(STATUS "SML/NJ runtime system: ${SMLNJ_ARCH_OPSYS}")

## Compilation settings (the DEFS variable of the mk.<arch>-<opsys> files) ##

add_library(smlnj-runtime-defs INTERFACE)

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

# check if the C compiler prefixes global symbols with an underscore (this
# replaces the config/chk-global-names.sh script)
#
check_c_source_compiles("
#define STR2(x) #x
#define STR(x) STR2(x)
int main (void) { static char a[(sizeof(STR(__USER_LABEL_PREFIX__)) == 2) ? 1 : -1]; return a[0]; }
" SMLNJ_GLOBALS_HAVE_UNDERSCORE)
if (SMLNJ_GLOBALS_HAVE_UNDERSCORE)
  target_compile_definitions(smlnj-runtime-defs INTERFACE GLOBALS_HAVE_UNDERSCORE)
endif()

if (SMLNJ_SANITIZE_ADDRESS)
  target_compile_options(smlnj-runtime-defs INTERFACE
    $<$<COMPILE_LANGUAGE:C,CXX>:-fsanitize=address>)
  target_link_options(smlnj-runtime-defs INTERFACE -fsanitize=address)
endif()

## Generated headers ##

add_subdirectory(config)

# the include path and definitions that are shared by all of the runtime code
#
add_library(smlnj-runtime-common INTERFACE)
target_include_directories(smlnj-runtime-common INTERFACE
  ${SMLNJ_RUNTIME_GENERATED_DIR}
  ${CMAKE_CURRENT_SOURCE_DIR}/include)
target_link_libraries(smlnj-runtime-common INTERFACE smlnj-runtime-defs)
add_dependencies(smlnj-runtime-common smlnj-runtime-generated)

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

# the libraries in link order (see ALL_LIBS in runtime/objs/makefile)
#
set(RUNTIME_LIBS ${SMLNJ_C_LIBRARY_TARGETS} smlnj-gc smlnj-mem)

# on Linux, the runtime is linked as a non-PIE executable (the makefiles
# used -no-pie); elsewhere we use the platform's default.
#
if (SMLNJ_OPSYS STREQUAL "linux")
  check_pie_supported()
  set(link_as_pie OFF)
endif()

# the interactive runtime system
#
add_executable(smlnj-run kernel/main.c)
target_link_libraries(smlnj-run PRIVATE smlnj-kernel ${RUNTIME_LIBS})
set_target_properties(smlnj-run PROPERTIES OUTPUT_NAME run.${SMLNJ_ARCH_OPSYS})

# the runtime system for stand-alone programs, which is a relocatable
# object (i.e., a partial link) that heap2exec links with a heap image.
#
# The system libraries (libm, libdl, librt, ...) are NOT part of this object;
# heap2exec links them (using `llvm-config --system-libs`) when it builds the
# final executable.  A partial link can only include static libraries, which
# many systems do not provide, and a static libm does not mix with a dynamic
# libc (see the comment in runtime/objs/mk.amd64-linux).  LLVM declares its
# system libraries as link dependencies of its libraries, so rather than
# linking the library targets, we link the archives of their static-library
# closure.
#

# _smlnj_visit_static_libs(<item>)
#
# depth-first traversal of the link dependencies of <item>, recording the
# static libraries in post order in the global property _SMLNJ_STATIC_LIBS.
# Items that are not targets (system libraries and linker flags) are ignored.
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
# (including themselves) in a valid link order.  The given libraries keep
# their relative order.
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

smlnj_static_link_closure(runx_libs ${RUNTIME_LIBS})
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

if (DEFINED link_as_pie)
  set_target_properties(smlnj-run smlnj-runx PROPERTIES
    POSITION_INDEPENDENT_CODE ${link_as_pie})
endif()

# the runtime programs are installed in bin/.run
#
install(TARGETS smlnj-run
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}/.run
  COMPONENT runtime)
install(PROGRAMS $<TARGET_FILE:smlnj-runx>
  DESTINATION ${CMAKE_INSTALL_BINDIR}/.run
  COMPONENT runtime)
