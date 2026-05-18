
add_library(smlnj-date STATIC
    smlnj-date-lib.c
    gmtime.c
    localoffset.c
    localtime.c
    mktime.c
    strftime.c
    unix-date.c
)
target_link_libraries(smlnj-date PRIVATE runtime-common clibs-common)
