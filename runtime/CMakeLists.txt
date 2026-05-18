
# Common C macro definitions set for the runtime
add_library(runtime-defs INTERFACE)

# The mmap-based memory system is the only supported one
set(RUNTIME_USE_MMAP ON)

# --- Architecture ---
target_compile_definitions(runtime-defs INTERFACE ARCH_${SMLNJ_ARCH})

# --- Pointer size ---
if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    target_compile_definitions(runtime-defs INTERFACE SIZE_64)
else()
    message(FATAL_ERROR "Only 64-bit targets are supported")
endif()

# --- OS ---
# Note: under Cygwin both CYGWIN and WIN32 are set; check CYGWIN first so it
# takes the Unix path rather than the native-Windows path.
if(LINUX)
    target_compile_definitions(runtime-defs INTERFACE
        OPSYS_UNIX OPSYS_LINUX _GNU_SOURCE DLOPEN INDIRECT_CFUNC)
    set(SMLNJ_OPSYS "linux")
elseif(APPLE)
    target_compile_definitions(runtime-defs INTERFACE
        OPSYS_UNIX OPSYS_DARWIN DLOPEN INDIRECT_CFUNC)
    set(SMLNJ_OPSYS "darwin")
elseif(CYGWIN)
    target_compile_definitions(runtime-defs INTERFACE
        OPSYS_UNIX OPSYS_CYGWIN DLOPEN INDIRECT_CFUNC)
    set(SMLNJ_OPSYS "cygwin")
elseif(WIN32)
    target_compile_definitions(runtime-defs INTERFACE
        OPSYS_WIN32)
    set(SMLNJ_OPSYS "win32")
else()
    message(FATAL_ERROR "Unsupported OS: ${CMAKE_SYSTEM_NAME}")
endif()
string(TOLOWER "${SMLNJ_ARCH}" smlnj_arch_lc)
set(RUNTIME_VERSION "v-${smlnj_arch_lc}-${SMLNJ_OPSYS}")

# --- Assembler syntax ---
# x86-syntax.h requires exactly one of GNU_ASSEMBLER or MASM_ASSEMBLER.
# arm64-darwin uses Apple's arm64 assembly syntax, so neither applies there.
# Native Windows uses MASM; everything else (all Unix platforms) uses GNU.
if(WIN32 AND NOT CYGWIN)
    target_compile_definitions(runtime-defs INTERFACE MASM_ASSEMBLER)
elseif(NOT (APPLE AND SMLNJ_ARCH STREQUAL "ARM64"))
    target_compile_definitions(runtime-defs INTERFACE GNU_ASSEMBLER)
endif()

# Targets used for configuration
# runtime-gen - common target including all generated files
add_subdirectory(config)

# Common macros, headers, and generated files
add_library(runtime-common INTERFACE)
target_link_libraries(runtime-common INTERFACE runtime-defs runtime-gen)
target_include_directories(runtime-common INTERFACE include)

# The C libraries
add_subdirectory(c-libs)
# The GC and heap management
add_subdirectory(gc)
# Virtual memory mapping
add_subdirectory(memory)
# The runtime kernel
add_subdirectory(kernel)
