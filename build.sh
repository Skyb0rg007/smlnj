#!/bin/sh
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#
# Build and installation script for SML/NJ System.
#
# usage: build.sh [ options ]
#
# TODO:
#    add support for fetching the boot files
#    dump output from build process to a log (instead of to the terminal)

cmd=$0
here=$(pwd)

#
# set the SML root directory
#
cd "$(dirname $cmd)" || exit 1
SMLNJ_ROOT="$(pwd)"

# the directory used by CMake to build the runtime system and its LLVM dependency
CMAKE_BUILD_DIR="$SMLNJ_ROOT/build"

# the minimum version of CMake that we require
CMAKE_MIN_VERSION=3.24

complain() {
  echo "$cmd: !!! $*"
  exit 1
}

usage() {
  echo "usage: build.sh [ options ]"
  echo "options:"
  echo "    -h,-help           print this message and exit"
  echo "    -install <dir>     specify installation directory (default $SMLNJ_ROOT)"
  echo "    -nolib             skip building libraries/tools"
  echo "    -runtime           build the runtime system only"
  echo "    -doc               generate documentation"
  echo "    -verbose           emit feedback messages"
  echo "    -clean             remove existing executables and libraries before building"
  echo "    -dev               developer install (includes cross compiler support)"
  echo "    -debug             enable installation debug messages (implies -verbose)"
  echo "developer options:"
  echo "    -debug-llvm        build a debug version of the LLVM libraries"
  echo "    -sanitize-address  sanitize addresses to check for memory bugs"
  echo "    -llvmdir dir       use a local smlnj-llvm source tree instead of downloading it"
  echo "    -build-cfgc        build the cfgc compiler"
  echo "    -make              use makefiles (instead of ninja) to build LLVM"
  exit 1
}

# process options
#
NOLIB=no
QUIET=yes
INSTALLDIR=""
CLEAN_INSTALL=no
INSTALL_DEBUG=no
INSTALL_DEV=no
ONLY_RUNTIME=no
MAKE_DOC=no
SANITIZE_ADDRESS=no
LLVMDIR_OPTION=""
LLVM_BUILD_TYPE=Release
LLVM_TARGETS=host
BUILD_CFGC=no
CMAKE_GENERATOR=""
while [ "$#" != "0" ] ; do
  arg=$1; shift
  case $arg in
    -help|-h) usage ;;
    -install)
      if [ "$#" -gt 0 ] ; then
        INSTALLDIR=$1; shift
      else
        usage
      fi ;;
    -nolib) NOLIB=yes ;;
    -verbose) QUIET=no ;;
    -clean) CLEAN_INSTALL=yes ;;
    -debug) INSTALL_DEBUG=yes ; QUIET=no ;;
    -dev)
      INSTALL_DEV=yes;
      LLVM_TARGETS=all
    ;;
    -runtime) ONLY_RUNTIME=yes ;;
    -doc) MAKE_DOC=yes ;;
    -debug-llvm) LLVM_BUILD_TYPE=Debug ;;
    -sanitize-address) SANITIZE_ADDRESS=yes ;;
    -llvmdir)
      if [ "$#" -gt 0 ] ; then
        LLVMDIR_OPTION=$1; shift
      else
        usage
      fi ;;
    -build-cfgc) BUILD_CFGC=yes ;;
    -make) CMAKE_GENERATOR="Unix Makefiles" ;;
    *) usage ;;
  esac
done

# feedback messages for verbose mode
#
vsay() {
  if [ x${QUIET} = xno ] ; then
    echo "$@"
  fi
}

# feedback messages for debug mode
#
dsay() {
  if [ x${INSTALL_DEBUG} = xyes ] ; then
    echo "$@"
  fi
}

vsay "$cmd: SML root is $SMLNJ_ROOT"

export CM_VERBOSE
if [ x${QUIET} = xyes ] ; then
  CM_VERBOSE=false
else
  CM_VERBOSE=true
fi

#
# check that we have a recent enough version of CMake
#
check_cmake() {
  if ! command -v cmake >/dev/null 2>&1 ; then
    complain "Installation of SML/NJ requires CMake version $CMAKE_MIN_VERSION or later"
  fi
  CMAKE_VERSION="$(cmake --version | sed -n 's/^cmake version \([0-9][0-9.]*\).*/\1/p')"
  # compare major.minor numerically
  CMAKE_MAJOR=${CMAKE_VERSION%%.*}
  CMAKE_MINOR=${CMAKE_VERSION#*.}; CMAKE_MINOR=${CMAKE_MINOR%%.*}
  MIN_MAJOR=${CMAKE_MIN_VERSION%%.*}
  MIN_MINOR=${CMAKE_MIN_VERSION#*.}
  if [ "$CMAKE_MAJOR" -lt "$MIN_MAJOR" ] || \
     { [ "$CMAKE_MAJOR" -eq "$MIN_MAJOR" ] && [ "$CMAKE_MINOR" -lt "$MIN_MINOR" ]; } ; then
    complain "Installation of SML/NJ requires CMake version $CMAKE_MIN_VERSION or later (found $CMAKE_VERSION)"
  fi
}

#
# determine the number of cores to use when building the runtime system and
# LLVM.  We use the available parallelism, but avoid hyperthreads.
#
NPROCS=2
case $(uname -s) in
  Darwin)
    case $(uname -p) in
      arm) # on arm processors, we only use the performance cores
        NPROCS=$(sysctl -n hw.perflevel0.physicalcpu)
        ;;
      *) # otherwise use the physical core count
        NPROCS=$(sysctl -n hw.physicalcpu)
        ;;
    esac
    ;;
  Linux)
    if command -v nproc >/dev/null 2>&1; then
      # NPROCS reports the number of hardware threads, which is usually twice the
      # number of actual cores, so we will divide by two.
      NPROCS=$(nproc --all)
      if [ "$NPROCS" -gt 4 ] ; then
        NPROCS=$((NPROCS / 2))
      fi
    fi
    ;;
esac

#
# configure, build, and install the runtime system and its LLVM dependency
# (the patched LLVM plus the SML/NJ code-generation libraries) using the
# CMake project in the root directory.  By default, CMake downloads the
# smlnj-llvm sources; the "-llvmdir" option can be used to specify a local
# source tree instead.
#
build_runtime() {
  check_cmake
  if [ x"$CMAKE_GENERATOR" = x ] ; then
    if command -v ninja >/dev/null 2>&1 ; then
      CMAKE_GENERATOR="Ninja"
    else
      CMAKE_GENERATOR="Unix Makefiles"
    fi
  fi
  # we always build the pinned version of smlnj-llvm, even if a copy is installed
  CMAKE_DEFS="\
    -DCMAKE_INSTALL_PREFIX=$INSTALLDIR \
    -DFETCHCONTENT_TRY_FIND_PACKAGE_MODE=NEVER \
    -DCMAKE_BUILD_TYPE=$LLVM_BUILD_TYPE \
    -DLLVM_TARGETS_TO_BUILD=$LLVM_TARGETS \
    -DSMLNJ_CFGC_BUILD=$BUILD_CFGC \
  "
  if [ x"$SANITIZE_ADDRESS" = xyes ] ; then
    CMAKE_DEFS="$CMAKE_DEFS -DLLVM_USE_SANITIZER=Address -DSMLNJ_SANITIZE_ADDRESS=ON"
  fi
  if [ x"$LLVMDIR" != x ] ; then
    CMAKE_DEFS="$CMAKE_DEFS -DFETCHCONTENT_SOURCE_DIR_SMLNJ-LLVM=$LLVMDIR"
  fi
  if [ "$(uname -s)" = "Darwin" ] ; then
    CMAKE_DEFS="$CMAKE_DEFS -DCMAKE_OSX_DEPLOYMENT_TARGET=11"
  fi
  vsay "$cmd: configuring the run-time system and LLVM in $CMAKE_BUILD_DIR"
  dsay cmake -S "$SMLNJ_ROOT" -B "$CMAKE_BUILD_DIR" -G "$CMAKE_GENERATOR" $CMAKE_DEFS
  cmake -S "$SMLNJ_ROOT" -B "$CMAKE_BUILD_DIR" -G "$CMAKE_GENERATOR" $CMAKE_DEFS \
    || complain "Unable to configure the run-time system"
  vsay "$cmd: building the run-time system and LLVM on $NPROCS cores"
  dsay cmake --build "$CMAKE_BUILD_DIR" --parallel "$NPROCS" --target install
  cmake --build "$CMAKE_BUILD_DIR" --parallel "$NPROCS" --target install \
    || complain "Unable to build the run-time system"
}

# pre-flight cleanup
#
cd "$SMLNJ_ROOT" || exit 1
if [ x${CLEAN_INSTALL} = xyes ] ; then
  vsay "$cmd: remove existing executables and libraries"
  rm -rf bin include lib "$CMAKE_BUILD_DIR"
elif [ x${INSTALL_DEV} = xyes ]; then
  # since we are building the development version, we first remove the
  # existing runtime system
  #
  vsay "$cmd: remove existing run-time system"
  rm -rf "bin/.run" "$CMAKE_BUILD_DIR"
fi

#
# create the preloads.standard file
#
if [ ! -r config/preloads ]; then
  complain "File config/preloads is missing"
fi
cp config/preloads preloads.standard

SHELL=/bin/sh
dsay "$cmd: Using shell $SHELL."

#
# check the installation directory (if specified)
#
cd "$here" || exit 1
if [ x"$INSTALLDIR" != x ] ; then
  if [ ! -d "$INSTALLDIR" ] ; then
    vsay "$cmd: creating $INSTALLDIR."
    mkdir -p "$INSTALLDIR"
  fi
  cd "$INSTALLDIR" || exit 1
  INSTALLDIR=$(pwd)
else
  INSTALLDIR="$SMLNJ_ROOT"
fi
vsay "$cmd: Installation directory is $INSTALLDIR."

#
# set the various directory and file pathname variables
#
CONFIGDIR="$SMLNJ_ROOT/config"
if [ x"$LLVMDIR_OPTION" != x ] ; then
  # check the validity of the path specified by the user
  if [ ! -f "$LLVMDIR_OPTION/LLVM-VERSION" ] ; then
    complain "invalid LLVM directory: $LLVMDIR_OPTION is not a smlnj-llvm source tree"
  fi
  LLVMDIR="$(cd "$LLVMDIR_OPTION" && pwd)"
else
  LLVMDIR=""
fi

#
# installation directories
#
BINDIR=$INSTALLDIR/bin		# main dir for binary stuff
HEAPDIR=$BINDIR/.heap		# where heap images live
RUNDIR=$BINDIR/.run		# where executables (i.e., the RTS) live
LIBDIR=$INSTALLDIR/lib		# where libraries live

# export variables used by the installer
export SMLNJ_ROOT INSTALLDIR CONFIGDIR BINDIR LIBDIR

#
# old root environment variable (for compatibility)
#
ROOT=$SMLNJ_ROOT
export ROOT

#
# files to be deleted after we are done...
#
tmpfiles=""
tmpfiles="$tmpfiles preloads.standard"
#
# make sure we always clean up after ourselves...
#
trap 'cd "$SMLNJ_ROOT"; rm -f $tmpfiles' 0 1 2 3 15

#
# set the CM configuration variables (these are environment variables
# that will be queried by the bootstrap code)
# Especially important is CM_PATHCONFIG.
#
export CM_PATHCONFIG
CM_PATHCONFIG=$LIBDIR/pathconfig
#
# the release version that we are installing
#
VERSION=$(cat "$CONFIGDIR/version")
vsay "$cmd: Installing version $VERSION."

#
# the URL for the (usually remote) source archive
#
SRCARCHIVEURL=https://smlnj.cs.uchicago.edu/dist/working/${VERSION}/
vsay "$cmd: URL of source archive is $SRCARCHIVEURL."

######################################################################
## UTILITY SCRIPTS
######################################################################

#
# Function to install a "driver" script...
#   This takes care of patching the source of the script with the SHELL,
#   BINDIR, and VERSION variables to use.
#
installdriver() {
  vsay "$cmd: installing $BINDIR/$2"
  dsrc=$1
  ddst=$2
  rm -f "$BINDIR"/"$ddst"
  cat "$CONFIGDIR"/"$dsrc" | \
  sed -e "s,@SHELL@,$SHELL,g" \
      -e "s,@INSTALLDIR@,$INSTALLDIR," \
      -e "s,@BINDIR@,$BINDIR," \
      -e "s,@LIBDIR@,$LIBDIR," \
      -e "s,@VERSION@,$VERSION," \
      -e "s,@CMDIRARC@,${CM_DIR_ARC:-dummy},"\
    > "$BINDIR"/"$ddst"
  chmod 555 "$BINDIR"/"$ddst"
  if [ ! -x "$BINDIR"/"$ddst" ]; then
    complain "Installation of $BINDIR/${ddst} failed."
  fi
}

#
# Fish out the CM metadata directory name from library files
# and store it in ORIG_CM_DIR_ARC.
# The single argument is the name of the directory containing
# a single subdirectory which is a CM metadata directory:
#
fish() {
  cd "$1" || exit 1
  ORIG_CM_DIR_ARC=unknown
  for i in * .[a-zA-Z0-9]* ; do
    if [ -d "$i" ] ; then
      ORIG_CM_DIR_ARC="$i"
      break
    fi
  done
  if [ $ORIG_CM_DIR_ARC = unknown ] ; then
    complain "Could not determine CM metadata directory name"
  else
    vsay "$cmd: CM metadata directory name is \"${ORIG_CM_DIR_ARC}\""
  fi
}


# A function to move all stable library files to a parallel directory
# hierarchy.
# The first argument must be a simple path (no / inside), and
# the second argument must be an absolute path.
move() {
  if [ -L "$1" ] ; then
    rm -f "$1"	     # remove symbolic link made by diracs (see below)
  elif [ -d "$1" ] ; then
    if [ ! -d "$2" ] ; then
      if [ -f "$2" ] ; then
        complain "$2 exists as a non-directory."
      fi
      mkdir "$2"
    fi
    cd "$1" || exit 1
    for i in * .[a-zA-Z0-9]* ; do
      move "$i" "$2"/"$i"
    done
    cd ..
  elif [ -f "$1" ] ; then
    rm -f "$2"
    mv "$1" "$2"
  fi
}

#
# Traverse the directory tree rooted at $3 (must be single arc!).
# Find all directories named $1, rename them into $2 and make
# and establish $1 as a symbolic link to $2:
#
dirarcs() {
  if [ -d "$3" ] ; then
    if [ "$3" = "$1" ] ; then
      mv "$1" "$2"
      ln -s "$2" "$1"
    else
      cd "$3" || exit 1
      for d in * .[a-zA-Z0-9]* ; do
        dirarcs "$1" "$2" "$d"
      done
      cd ..
    fi
  fi
}

######################################################################

mk_directory() {
  if [ x"$QUIET" = xyes ] ; then
    mkdir -p "$1" || exit 1
  else
    mkdir -p -v "$1" || exit 1
  fi
}

#
# create the various sub directories
#
if [ x"$ONLY_RUNTIME" = xyes ] ; then
  for dir in "$BINDIR" "$RUNDIR" ; do
    mk_directory "$dir"
  done
else
  for dir in "$BINDIR" "$HEAPDIR" "$RUNDIR" "$LIBDIR" ; do
    mk_directory "$dir"
  done
fi

#
# install the script that tests architecture and os...
#
installdriver _arch-n-opsys .arch-n-opsys

#
# run it to figure out what architecture and os we are using, define
# corresponding variables...
#
ARCH_N_OPSYS=`"$BINDIR"/.arch-n-opsys`
if [ "$?" != "0" ]; then
  complain "$BINDIR/.arch-n-opsys fails on this machine; please patch by hand and repeat the installation."
  exit 2
else
  vsay "$cmd: Script $BINDIR/.arch-n-opsys reports $ARCH_N_OPSYS."
fi
eval $ARCH_N_OPSYS

#
# now install most of the other driver scripts
#  (except ml-build, since we don't know $CM_DIR_ARC yet)
#
if [ x"$ONLY_RUNTIME" = xno ] ; then
  installdriver _run-sml .run-sml
  installdriver _link-sml .link-sml
  installdriver _ml-makedepend ml-makedepend
  installdriver _heap2exec heap2exec
  ## TODO: install-sml-wrapper script
fi

#
# set allocation size; for the x86, this gets reset in .run-sml
#
ALLOC=1M

#
# build the run-time system
#
if [ -x "$RUNDIR"/run.$ARCH-$OPSYS ]; then
  vsay $cmd: Run-time system already exists.
else
  #
  # the CMake project builds LLVM, the CFGCodeGen library, and the run-time
  # system, and installs them.  If the "-dev" option was given, then LLVM
  # supports all targets, since we want to assure that the cross compiler
  # is supported.
  #
  if [ x"$INSTALL_DEV" = xyes ] ; then
    vsay $cmd: Building the run-time system with LLVM support for all targets
  else
    vsay $cmd: Building the run-time system
  fi
  build_runtime
  if [ ! -x "$RUNDIR"/run.$ARCH-$OPSYS ]; then
    complain "Run-time system build failed for some reason."
  fi
fi
cd "$SMLNJ_ROOT" || exit 1

#
# remove unused LLVM executables from bin directory
#
for f in llvm-libtool-darwin llvm-tblgen ; do
  rm -f bin/$f
done

vsay $cmd: runtime system built
if [ x"$ONLY_RUNTIME" = xyes ] ; then
  exit 1
fi

#
# the name of the boot files archive and directory
#
# FIXME: should make these file names more consistent!!
#
BOOT_ARCHIVE=boot.$ARCH-unix
BOOT_FILES=sml.boot.$ARCH-unix

#
# boot the base SML system
#
if [ -r "$HEAPDIR"/sml.$HEAP_SUFFIX ]; then
  vsay "$cmd: Heap image $HEAPDIR/sml.$HEAP_SUFFIX already exists."
  fish "$LIBDIR"/smlnj/basis
  # ignore requested arc name since we have to live with what is there:
  export CM_DIR_ARC
  CM_DIR_ARC=$ORIG_CM_DIR_ARC
  # now re-dump the heap image:
  vsay "$cmd: Re-creating a (customized) heap image..."
  "$BINDIR"/sml @CMredump "$SMLNJ_ROOT"/sml
  cd "$SMLNJ_ROOT" || exit 1
  if [ -r sml.$HEAP_SUFFIX ]; then
    mv sml.$HEAP_SUFFIX "$HEAPDIR"
  else
    complain "Unable to re-create heap image (sml.$HEAP_SUFFIX)."
  fi
else
  cd "$SMLNJ_ROOT" || exit 1
  vsay "$cmd: unpack boot files ($BOOT_ARCHIVE)"
  "$CONFIGDIR"/unpack "$SMLNJ_ROOT" "$BOOT_ARCHIVE"
  vsay "$cmd: extract $SMLNJ_ROOT/$BOOT_FILES/smlnj/basis"
  fish "$SMLNJ_ROOT"/"$BOOT_FILES"/smlnj/basis

  # Target arc:
  export CM_DIR_ARC
  CM_DIR_ARC=${CM_DIR_ARC:-".cm"}

  if [ $CM_DIR_ARC != $ORIG_CM_DIR_ARC ] ; then
    # now we have to make a symbolic link for each occurrence of
    # $ORIG_CM_DIR_ARC to $CM_DIR_ARC
    dirarcs "$ORIG_CM_DIR_ARC" "$CM_DIR_ARC" "$BOOT_FILES"
  fi

  cd "$SMLNJ_ROOT"/"$BOOT_FILES" || exit 1

  # now link (boot) the system and let it initialize itself...
  dsay "$BINDIR"/.link-sml @SMLheap="$SMLNJ_ROOT"/sml @SMLboot=BOOTLIST @SMLalloc=$ALLOC
  if "$BINDIR"/.link-sml @SMLheap="$SMLNJ_ROOT"/sml @SMLboot=BOOTLIST @SMLalloc=$ALLOC ; then
    cd "$SMLNJ_ROOT" || exit 1
    if [ -r sml.$HEAP_SUFFIX ]; then
      mv sml.$HEAP_SUFFIX "$HEAPDIR"
      cd "$BINDIR" || exit 1
      ln -s .run-sml sml
      #
      # Now move all stable libraries to $LIBDIR and generate
      # the pathconfig file.
      #
      cd "$SMLNJ_ROOT"/"$BOOT_FILES" || exit 1
      for anchor in * ; do
        if [ -d $anchor ] ; then
          dsay "move $anchor to $LIBDIR"
          echo $anchor $anchor >> $CM_PATHCONFIG
          move $anchor "$LIBDIR"/$anchor
        fi
      done
      cd "$SMLNJ_ROOT" || exit 1
      # $BOOT_FILES is now only an empty skeleton, let's get rid of it.
      rm -rf "$BOOT_FILES"
    else
      complain "No heap image generated (sml.$HEAP_SUFFIX)."
    fi
  else
    complain "Boot code failed, no heap image (sml.$HEAP_SUFFIX)."
  fi
fi

#
# now that we know CM_DIR_ARC we can install the ml-build driver...
#
installdriver _ml-build ml-build

cd "$SMLNJ_ROOT" || exit 1

#
# Now do all the rest using the precompiled installer
# (see system/smlnj/installer for details)
#
if [ x"$NOLIB" = xno ] ; then
  vsay "$cmd: Installing other libraries and programs:"
  CM_TOLERATE_TOOL_FAILURES=true
  export CM_TOLERATE_TOOL_FAILURES
  if "$BINDIR"/sml -m \$smlnj/installer.cm ; then
    vsay $cmd: Installation complete.
  else
    complain "Installation of libraries and programs failed."
  fi
fi

#
# generate the documentation and manual pages (if requested)
#
if [ x"$MAKE_DOC" = xyes ] ; then
  vsay "$cmd: Generating documentation."
  #
  # first we clear CM related shell variables so that the documentation tool
  # builds are not confused.
  #
  unset CM_PATHCONFIG CM_DIR_ARC CM_TOLERATE_TOOL_FAILURES
  export SMLNJ_HOME SML_CMD
  SMLNJ_HOME=$here      # gives access to the version of SML/NJ that we are building
  SML_CMD=$here/bin/sml
  cd doc || exit 1
  if autoconf -Iconfig ; then
    :
  else
    complain "Error configuring documentation."
  fi

  ./configure

  if make doc && make distclean ; then
    vsay $cmd: Documentation generation complete.
  else
    complain "Error generating documentation."
  fi
fi

exit 0
