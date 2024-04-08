#!/bin/bash

if (( $# != 2 ))
then
  echo "Use: $0 <source_code without extension> <directory_with_tests>"
  exit
fi

PROGRAM=$1
TEST_DIR=$2
TIMEOUT=5

REPORT=""
FAIL_LIST=""

echo "== Compilation =="
gcc -o $PROGRAM lpromain.c lpro_scheme.c
if (( $? != 0 ))
then
  exit
fi
echo "OK"
echo ""

echo "== Testing =="
COUNT_PASS=0
COUNT_FAIL=0
COUNT_TESTS=0
for p in $TEST_DIR/*.in
do
  echo "TEST $p"
  ((COUNT_TESTS++))
  timeout $TIMEOUT ./$PROGRAM <$p | diff -Z - ${p%.in}.out
  if (( $? == 0 ))
  then
    echo "PASS"
    ((COUNT_PASS++))
  else
    echo "FAIL"
    ((COUNT_FAIL++))
    FAIL_LIST+="$(basename "$p")\n"
  fi
  echo ""
done

echo "Summary: PASS ($COUNT_PASS / $COUNT_TESTS), FAIL ($COUNT_FAIL / $COUNT_TESTS)"
if [[ -n $FAIL_LIST ]]; then
  echo "List of failed tests:"
  echo -e $FAIL_LIST
fi

