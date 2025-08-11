# CMakeLists.txt
#
# COPYRIGHT (c) 2025 The SML/NJ Fellowship
#
# Exports the 'smlnj-mach-dep' target
# It 
# and compiler flags settings
#

add_library(smlnj-mach-dep OBJECT
    signal-util.c
)

if (UNIX)
    target_sources(smlnj-mach-dep PRIVATE
        unix-signal.c
        unix-prof.c
        unix-fault.c
    )
elseif(WIN32)
    target_sources(smlnj-mach-dep PRIVATE
        win32-fault.c
        win32-util.c
        win32-signal.c
        win32-timers.c
    )
else()
    message(FATAL_ERROR "Unsupported OS")
endif()

if (CMAKE_SYSTEM_PROCESSOR STREQUAL x86_64)
    target_sources(smlnj-mach-dep PRIVATE
        AMD64.prim.asm
    )
elseif (CMAKE_SYSTEM_PROCESSOR STREQUAL ARM64)
    target_sources(smlnj-mach-dep PRIVATE
        ARM64.prim.asm
    )
else()
    message(FATAL_ERROR "Processor ${CMAKE_SYSTEM_PROCESSOR} not implemented")
endif()

target_include_directories(smlnj-mach-dep PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
)
target_link_libraries(smlnj-mach-dep PUBLIC
    smlnj-runtime-config
)

