
add_library(gc STATIC
    # GC
    init-gc.c
    call-gc.c
    minor-gc.c
    major-gc.c
    flip.c
    gc-util.c
    big-objects.c
    ml-objects.c
    obj-info.c
    build-literals.c
    old-literals.c
    record-ops.c
    # TODO: Conditional(?)
    # check-heap.c

    import-heap.c
    export-heap.c
    blast-in.c
    blast-out.c
    blast-gc.c
    heap-in-util.c
    heap-out-util.c
    writer.c
    mem-writer.c
    addr-hash.c
    c-globals-tbl.c
)
target_link_libraries(gc PRIVATE runtime-common)
