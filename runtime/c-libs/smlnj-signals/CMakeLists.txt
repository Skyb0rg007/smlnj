
add_library(smlnj-sig STATIC
    smlnj-sig-lib.c
    getsigmask.c
    getsigstate.c
    listsignals.c
    pause.c
    setsigmask.c
    setsigstate.c
)
target_link_libraries(smlnj-sig PRIVATE runtime-common clibs-common)
