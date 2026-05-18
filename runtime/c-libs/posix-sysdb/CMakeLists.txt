
add_library(posix-sysdb STATIC
    posix-sysdb-lib.c
    getgrgid.c
    getgrnam.c
    getpwuid.c
    getpwnam.c
)
target_link_libraries(posix-sysdb PRIVATE runtime-common clibs-common)
