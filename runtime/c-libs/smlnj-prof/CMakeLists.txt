# CMake configuration for the smlnj-prof C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

smlnj_add_c_library(smlnj-clib-smlnj-prof
  smlnj-prof-lib.c
  getpquantum.c
  setpref.c
  setptimer.c
)

# these functions access the internals of the garbage collector
target_include_directories(smlnj-clib-smlnj-prof PRIVATE ${SMLNJ_RUNTIME_SOURCE_DIR}/gc)
