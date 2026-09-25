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
# The dependency is fetched as a source archive of a specific commit of
# https://github.com/Skyb0rg007/smlnj-llvm-21.1 (see SMLNJ_LLVM_URL below).
# To use a local checkout of that repository instead (e.g., when working on
# the code generator), set FETCHCONTENT_SOURCE_DIR_SMLNJ-LLVM to its path.
#
# A build type (e.g., -DCMAKE_BUILD_TYPE=Release) must be given when LLVM is
# built as part of this project; LLVM refuses to configure without one.
# build.sh specifies it.
#

cmake_minimum_required(VERSION 3.23.0)

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

# use the timestamps of the extracted files for downloaded archives
#
if (POLICY CMP0135)
  cmake_policy(SET CMP0135 NEW)
endif()

## Options ##

set(SMLNJ_LLVM_TARGETS "host" CACHE STRING
  "LLVM code-generation targets to build: \"host\", \"all\", or a list drawn from X86;AArch64")
option(SMLNJ_BUILD_CFGC
  "Build the cfgc tool (compiles CFG pickles; used to debug the code generator)" OFF)
option(SMLNJ_LLVM_INSTALL
  "Install LLVM and the code-generation libraries and tools into the install prefix (the runtime makefiles need this)"
  ON)
option(SMLNJ_LLVM_FIND_PACKAGE
  "Use an installed smlnj-llvm package (found via find_package) instead of fetching and building it"
  OFF)
option(SMLNJ_BUILD_RUNTIME
  "Build the runtime system (turn off to only build the smlnj-llvm dependency)" ON)
option(SMLNJ_SANITIZE_ADDRESS
  "Compile the runtime system with the address sanitizer" OFF)

## The smlnj-llvm dependency ##

# the source archive for the pinned commit of smlnj-llvm.  Update both the
# URL and the hash together when moving to a new commit.
#
set(SMLNJ_LLVM_COMMIT "b393ae2d86f26ee51a24e22edda24ab5dd79e07f")
set(SMLNJ_LLVM_URL
  "https://github.com/Skyb0rg007/smlnj-llvm-21.1/archive/${SMLNJ_LLVM_COMMIT}.tar.gz")
set(SMLNJ_LLVM_URL_HASH
  "SHA256=9758697271f001294fee5a4183752841498d57d201a457344779e6f6db9e1df8")

# translate SMLNJ_LLVM_TARGETS into the smlnj-llvm setting
#
if (SMLNJ_LLVM_TARGETS STREQUAL "host")
  if (CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|amd64|AMD64)$")
    set(LLVM_TARGETS_TO_BUILD X86)
  elseif (CMAKE_SYSTEM_PROCESSOR MATCHES "^(arm64|aarch64|ARM64)$")
    set(LLVM_TARGETS_TO_BUILD AArch64)
  else()
    message(FATAL_ERROR "unsupported architecture ${CMAKE_SYSTEM_PROCESSOR}")
  endif()
else()
  set(LLVM_TARGETS_TO_BUILD "${SMLNJ_LLVM_TARGETS}")
endif()

set(SMLNJ_CFGC_BUILD ${SMLNJ_BUILD_CFGC})

if (SMLNJ_LLVM_FIND_PACKAGE)
  find_package(smlnj-llvm CONFIG REQUIRED)
  message(STATUS "Using installed smlnj-llvm ${SMLNJ_LLVM_VERSION} (targets: ${SMLNJ_LLVM_TARGETS})")
else()
  include(FetchContent)
  FetchContent_Declare(smlnj-llvm
    URL ${SMLNJ_LLVM_URL}
    URL_HASH ${SMLNJ_LLVM_URL_HASH})
  FetchContent_MakeAvailable(smlnj-llvm)
endif()

## The runtime system ##

if (SMLNJ_BUILD_RUNTIME)
  add_subdirectory(runtime)
endif()
