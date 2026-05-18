add_library(smlnj-time STATIC
    smlnj-time-lib.c
    gettime.c
    timeofday.c
)
target_link_libraries(smlnj-time PRIVATE runtime-common clibs-common)
