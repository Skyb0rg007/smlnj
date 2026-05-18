
add_library(posix-error STATIC
    posix-error-lib.c
    posix-name-val.c
    errmsg.c
    geterror.c
    listerrors.c
    tbl-errno.c
)
target_link_libraries(posix-error PRIVATE runtime-common clibs-common)
