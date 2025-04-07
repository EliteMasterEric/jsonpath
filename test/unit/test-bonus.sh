#!/bin/bash

# Fail on error
set -e

#haxe test-cpp.hxml --define jsonpath_bonus
#./bin/cpp/TestMain-debug.exe

haxe test-hl.hxml --define jsonpath_bonus
hl ./bin/hl/TestMain