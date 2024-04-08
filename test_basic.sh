#!/bin/bash

if (( $# < 1 ))
then
  echo "Use: $0 <source code> [<directory_with_test_filesC>]"
  exit
fi

PROGRAM=$1
TEST_DIR=${2:-.}  # Use the current directory if $2 is not provided

FAIL_LIST=""

echo "== Compilation =="
gcc -Wall -Wextra $PROGRAM -o "$PROGRAM.out"
if (( $? != 0 ))
then
  exit
fi
echo "OK"
echo ""

echo "== Testing with Valgrind =="
COUNT_PASS=0
COUNT_FAIL=0
COUNT_TESTS=0
for p in $TEST_DIR/*.in
do
  echo "TEST $p"
  ((COUNT_TESTS++))
  
  VALGRIND_DIR="$(dirname "${PROGRAM}_valgrind_$p.log")"
  mkdir -p "$VALGRIND_DIR"

  # Running the test with Valgrind
  valgrind --leak-check=full -q --error-exitcode=1 --log-file="${VALGRIND_DIR}/${PROGRAM}_valgrind_$p.log" ./"$PROGRAM.out" <$p > output.txt
  VALGRIND_EXIT_CODE=$?

  # Compare the output with the expected output
  diff -Z output.txt ${p%.in}.out
  DIFF_EXIT_CODE=$?

  # Check if the test passed and if Valgrind found any leaks
  if (( $DIFF_EXIT_CODE == 0 && $VALGRIND_EXIT_CODE == 0 ))
  then
    echo "PASS"
    ((COUNT_PASS++))
  else
    echo "FAIL"
    FAIL_LIST+="$p\n"
    if (( $VALGRIND_EXIT_CODE != 0 )); then
      echo "Memory leak detected in $p!"
      FAIL_LIST+="Memory leak detected in $p!\n"
    fi
    ((COUNT_FAIL++))
  fi
  echo ""
done

echo "Summary: PASS ($COUNT_PASS / $COUNT_TESTS), FAIL ($COUNT_FAIL / $COUNT_TESTS)"
if [[ -n $FAIL_LIST ]]; then
  echo "Failed tests list:"
  echo -e "$FAIL_LIST"
fi

