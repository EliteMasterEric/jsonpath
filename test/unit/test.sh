#!/bin/bash

# Fail on error
set -e

# Build test
haxe test-cpp.hxml
# Run test
./bin/cpp/TestMain-debug.exe