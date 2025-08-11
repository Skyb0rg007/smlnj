
## SML/NJ's runtime kernel
add_library(smlnj-kernel OBJECT
    ml-options.c
    error.c
    boot.c
    load-ml.c
    run-ml.c
    globals.c
    ml-state.c
    timers.c
    qualify-name.c
    swap-bytes.c
)
target_link_libraries(smlnj-kernel PRIVATE
    smlnj-runtime-config
)

if(UNIX)
    target_sources(smlnj-kernel PRIVATE
        unix-timers.c
    )
endif()

## The runtime executable
add_executable(smlnj-runtime
    main.c
)
target_link_libraries(smlnj-runtime PRIVATE
    smlnj-runtime-config
    smlnj-kernel
)
