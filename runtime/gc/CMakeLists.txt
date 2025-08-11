
add_library(smlnj-gc OBJECT
    big-objects.c
    build-literals.c
    call-gc.c
    flip.c
    gc-util.c
    init-gc.c
    major-gc.c
    minor-gc.c
    ml-objects.c
    obj-info.c
    old-literals.c
    record-ops.c
)
target_include_directories(smlnj-gc PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)
target_link_libraries(smlnj-gc PRIVATE
    smlnj-runtime-config
)
