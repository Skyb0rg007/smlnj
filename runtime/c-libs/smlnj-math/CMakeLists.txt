
add_library(smlnj-math STATIC
    smlnj-math-lib.c
    ctlrndmode.c
    atan64.c
    cos64.c
    exp64.c
    log64.c
    sin64.c
    sqrt64.c
)
target_link_libraries(smlnj-math PRIVATE runtime-common clibs-common)
