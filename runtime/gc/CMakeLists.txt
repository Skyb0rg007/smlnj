# CMake configuration for the garbage collector and heap I/O library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

set(GC_SRCS
  init-gc.c
  call-gc.c
  minor-gc.c
  major-gc.c
  flip.c
  gc-util.c
  big-objects.c
  ml-objects.c
  obj-info.c
  build-literals-v3.c
  build-literals-v2.c
  old-literals.c
  record-ops.c)

set(HEAP_IO_SRCS
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
  c-globals-tbl.c)

add_library(smlnj-gc STATIC ${GC_SRCS} ${HEAP_IO_SRCS})
smlnj_runtime_c_standard(smlnj-gc)
target_include_directories(smlnj-gc PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(smlnj-gc PRIVATE smlnj-runtime-common smlnj-mem)
