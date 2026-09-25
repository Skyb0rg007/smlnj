# CMake configuration for SML/NJ
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://www.smlnj.org)
# All rights reserved.
#
# At present, this project builds the SML/NJ runtime system (see
# runtime/CMakeLists.txt) and its `smlnj-llvm` dependency, which is the
# patched LLVM together with the SML/NJ code-generation libraries and the
# heap2obj tool.  The build.sh script uses this project to build and install
# them before it builds the compiler and libraries from the boot files.
# Building the rest of the system with CMake is future work.
#
# The dependency is made available with FetchContent, which first tries
# find_package(smlnj-llvm CONFIG) and otherwise fetches a source archive of
# a specific commit of https://github.com/Skyb0rg007/smlnj-llvm-21.1 (see
# SMLNJ_LLVM_URL below).  This is controlled with the standard FetchContent
# variables:
#
#   * To use an installed smlnj-llvm, make it findable (e.g., by adding its
#     installation prefix to CMAKE_PREFIX_PATH).  The install prefix of this
#     project is not searched, since it usually holds the copy of smlnj-llvm
#     that an earlier build of this project installed.
#   * To always build the pinned sources, set
#     FETCHCONTENT_TRY_FIND_PACKAGE_MODE to NEVER (build.sh does this).
#   * To use a local checkout of smlnj-llvm (e.g., when working on the code
#     generator), set FETCHCONTENT_SOURCE_DIR_SMLNJ-LLVM to its path.
#
# A build type (e.g., -DCMAKE_BUILD_TYPE=Release) must be given when LLVM is
# built as part of this project; LLVM refuses to configure without one.
# build.sh specifies it.  The options of smlnj-llvm (e.g., LLVM_TARGETS_TO_BUILD,
# which is "host" by default, and SMLNJ_CFGC_BUILD) can be set directly.
#

cmake_minimum_required(VERSION 3.24.0)

# the numeric part of the version (e.g., "2026.3-beta" -> "2026.3")
#
file(STRINGS "${CMAKE_CURRENT_LIST_DIR}/config/version" SMLNJ_VERSION_STRING LIMIT_COUNT 1)
string(STRIP "${SMLNJ_VERSION_STRING}" SMLNJ_VERSION_STRING)
string(REGEX MATCH "^[0-9]+(\\.[0-9]+)*" SMLNJ_VERSION "${SMLNJ_VERSION_STRING}")

project(smlnj
  VERSION ${SMLNJ_VERSION}
  DESCRIPTION "Standard ML of New Jersey"
  HOMEPAGE_URL https://smlnj.org
  LANGUAGES C CXX)

# Disable builds in the source tree to prevent corruption.
#
if ("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_BINARY_DIR}")
  message(FATAL_ERROR "
  ERROR: builds in the source tree are not allowed.
         Create a separate directory for build files.
")
endif()

include(GNUInstallDirs)

## Options ##

option(SMLNJ_LLVM_INSTALL
  "Install LLVM and the code-generation libraries and tools into the install prefix (heap2exec needs bin/llvm-config)"
  ON)
option(SMLNJ_BUILD_RUNTIME
  "Build the runtime system (turn off to only build the smlnj-llvm dependency)" ON)
option(SMLNJ_SANITIZE_ADDRESS
  "Compile the runtime system with the address sanitizer" OFF)

## The smlnj-llvm dependency ##

# the source archive for the pinned commit of smlnj-llvm.  Update both the
# URL and the hash together when moving to a new commit.
#
set(SMLNJ_LLVM_COMMIT "6143360c92985eb39c6d0201a34e9202fa52d01e")
set(SMLNJ_LLVM_URL
  "https://github.com/Skyb0rg007/smlnj-llvm-21.1/archive/${SMLNJ_LLVM_COMMIT}.tar.gz")
set(SMLNJ_LLVM_URL_HASH
  "SHA256=29d27079b2c6264aa05b846ebc4cf0edb4c0361aa366b80fa6ad951dddfd5085")

include(FetchContent)
FetchContent_Declare(smlnj-llvm
  URL ${SMLNJ_LLVM_URL}
  URL_HASH ${SMLNJ_LLVM_URL_HASH}
  FIND_PACKAGE_ARGS CONFIG NO_CMAKE_INSTALL_PREFIX)
FetchContent_MakeAvailable(smlnj-llvm)

# report which copy of smlnj-llvm is used (its options, such as
# LLVM_TARGETS_TO_BUILD, only affect a copy that is built as part of this
# project)
#
get_target_property(_smlnj_llvm_imported smlnj-llvm::CFGCodeGen IMPORTED)
if (_smlnj_llvm_imported)
  message(STATUS "Using installed smlnj-llvm from ${smlnj-llvm_DIR}")
else()
  message(STATUS "Building smlnj-llvm from ${smlnj-llvm_SOURCE_DIR}")
endif()
unset(_smlnj_llvm_imported)

## The runtime system ##

if (SMLNJ_BUILD_RUNTIME)
  add_subdirectory(runtime)
endif()
