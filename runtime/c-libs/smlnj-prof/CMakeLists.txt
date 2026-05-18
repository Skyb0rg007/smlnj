
add_library(smlnj-prof STATIC
    smlnj-prof-lib.c
    getpquantum.c
    setpref.c
    setptimer.c
)
target_link_libraries(smlnj-prof PRIVATE runtime-common clibs-common)
