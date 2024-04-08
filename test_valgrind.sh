#!/bin/bash

if (( $# < 1 ))
then
  echo "Use: $0 <source_code> [<directory_with_tests>]"
  exit
fi

PROGRAM=$1
TEST_DIR=${2:-.}  # Use the current directory if $2 is not provided

FAIL_LIST=""

echo "== Compilation =="
gcc -Wall -Wextra $PROGRAM
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
for p in $TEST_DIR/*in.txt  # Now looking specifically for files that end with 'in.txt'
do
  # Derive the base name without 'in.txt' extension
  BASE_NAME=$(basename "$p" "in.txt")
  
  # Create names for output and expected output files
  OUTPUT_FILE="${TEST_DIR}/${BASE_NAME}out.txt"
  INPUT_FILE="${TEST_DIR}/${BASE_NAME}in.txt"

  echo "TEST $INPUT_FILE"
  ((COUNT_TESTS++))
  
  VALGRIND_DIR="$(dirname "${PROGRAM}_valgrind_$BASE_NAME.log")"
  mkdir -p "$VALGRIND_DIR"

  # Running the test with Valgrind
  valgrind --leak-check=full -q --error-exitcode=1 --log-file="${VALGRIND_DIR}/${PROGRAM}_valgrind_$BASE_NAME.log" ./a.out <$INPUT_FILE > output.txt
  VALGRIND_EXIT_CODE=$?

  # Compare the output with the expected output
  diff -Z output.txt $OUTPUT_FILE
  DIFF_EXIT_CODE=$?

  # Check if the test passed and if Valgrind found any leaks
  if (( $DIFF_EXIT_CODE == 0 && $VALGRIND_EXIT_CODE == 0 ))
  then
    echo "PASS"
    ((COUNT_PASS++))
  else
    echo "FAIL"
    FAIL_LIST+="${INPUT_FILE}\n"
    if (( $VALGRIND_EXIT_CODE != 0 )); then
      echo "Memory leak detected in $INPUT_FILE!"
      FAIL_LIST+="Memory leak detected in $INPUT_FILE!\n"
    fi
    ((COUNT_FAIL++))
  fi
  echo ""
done

echo "Summary: PASS ($COUNT_PASS / $COUNT_TESTS), FAIL ($COUNT_FAIL / $COUNT_TESTS)"
if [[ -n $FAIL_LIST ]]; then
  echo "Failed Tests List:"
  echo -e "$FAIL_LIST"
fi

