
add_library(posix-os STATIC
    posix-os-lib.c
    poll.c
    tmpname.c
)
target_link_libraries(posix-os PRIVATE runtime-common clibs-common)

