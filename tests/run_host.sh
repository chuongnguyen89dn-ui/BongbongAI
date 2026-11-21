#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
clang -std=c11 -Wall -Wextra -Werror -fsanitize=undefined,address -fno-omit-frame-pointer \
  -Ioverlay overlay/BBPCMCore.c tests/wav_core_test.c -o /tmp/bongbongai-wav-core-test
/tmp/bongbongai-wav-core-test
python3 tests/check_isolation.py
