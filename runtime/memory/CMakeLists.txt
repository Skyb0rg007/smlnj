
add_library(memory STATIC)

if (RUNTIME_USE_MMAP)
    target_sources(memory
        PRIVATE
        mem-mmap.c
    )
else()
    message(FATAL_ERROR "Unrecognized memory implementation")
endif()

target_link_libraries(memory PRIVATE runtime-common)
