#!/bin/sh
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#
# Tests for polymorphic recursion.
#
# usage: run-tests.sh [ <sml-cmd> [ <sml-args> ... ] ]
#
# Each *.sml file in this directory must compile and run, printing only "ok:"
# lines followed by "done".  Each file in fail/ must be rejected with an
# ordinary type error (not a compiler bug).  All tests are run with the FLINT
# type checker enabled after every optimization phase.
#

HERE=$(CDPATH='' cd "$(dirname "$0")" && pwd)

if [ "$#" = "0" ] ; then
  set -- sml
fi

TMP=${TMPDIR:-/tmp}/poly-rec-test.$$
trap 'rm -f "$TMP"' 0 1 2 3 15

status=0


for f in "$HERE"/*.sml ; do
  name=$(basename "$f")
  (echo 'Control.FLINT.check := true;'; cat "$f") | "$@" > "$TMP" 2>&1
  if grep -q "FAIL:\|Error\|uncaught exception\|Compiler bug" "$TMP" \
  || ! grep -q "^\(- \)*done$" "$TMP" ; then
    echo "FAIL $name"
    grep "FAIL:\|Error\|uncaught exception\|Compiler bug" "$TMP"
    status=1
  else
    echo "ok   $name ($(grep -o "ok: " "$TMP" | wc -l) checks)"
  fi
done

for f in "$HERE"/fail/*.sml ; do
  name=fail/$(basename "$f")
  (echo 'Control.FLINT.check := true;'; cat "$f") | "$@" > "$TMP" 2>&1
  if grep -q "Compiler bug\|uncaught exception" "$TMP" \
  || ! grep -q "Error:" "$TMP" ; then
    echo "FAIL $name (expected a type error)"
    cat "$TMP"
    status=1
  else
    echo "ok   $name (rejected)"
  fi
done

exit $status
