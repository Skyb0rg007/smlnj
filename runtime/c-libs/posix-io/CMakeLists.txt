
add_library(posix-io STATIC
    posix-io-lib.c
    osval.c
    pipe.c
    dup.c
    dup2.c
    close.c
    read.c
    readbuf.c
    write.c
    writebuf.c
    fcntl_d.c
    fcntl_gfd.c
    fcntl_sfd.c
    fcntl_gfl.c
    fcntl_sfl.c
    fcntl_l.c
    lseek.c
    fsync.c
)
target_link_libraries(posix-io PRIVATE runtime-common clibs-common)
