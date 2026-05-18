
add_subdirectory(llvm21 EXCLUDE_FROM_ALL)

# Common C macro definitions set for the runtime
add_library(runtime-defs INTERFACE)

set(RUNTIME_USE_MMAP ON)

if(LINUX)
    set(RUNTIME_VERSION v-amd64-linux)
    target_compile_definitions(runtime-defs
        INTERFACE
            OPSYS_UNIX
            OPSYS_LINUX
            DLOPEN
            INDIRECT_CFUNC
            ARCH_AMD64
            SIZE_64

            _GNU_SOURCE
            GNU_ASSEMBLER
    )
else()
    message(FATAL_ERROR "only amd64-linux for now")
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
