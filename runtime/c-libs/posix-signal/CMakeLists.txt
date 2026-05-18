
add_library(posix-signal STATIC
    posix-signal-lib.c
    osval.c
)
target_link_libraries(posix-signal PRIVATE runtime-common clibs-common)
