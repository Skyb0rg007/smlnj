add_library(unix-dynload STATIC
    dlopen.c
    dlclose.c
    dlsym.c
    dlerror.c
    unix-dynload-lib.c
)
target_link_libraries(unix-dynload PRIVATE runtime-common clibs-common)
