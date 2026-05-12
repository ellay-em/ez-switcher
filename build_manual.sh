#!/bin/bash
set -e

# Define paths
SOURCE_DIR="Sources/EZSwitcher"
OUTPUT_BINARY="EZSwitcher_Binary"

# List all swift files except Tests.swift
FILES=$(ls $SOURCE_DIR/*.swift | grep -v "Tests.swift")

echo "Compiling app binary: $OUTPUT_BINARY"
echo "Files: $FILES"

# Compile App
swiftc -o $OUTPUT_BINARY $FILES \
    -framework Cocoa \
    -framework Carbon \
    -framework NaturalLanguage \
    -framework AppKit \
    -framework CoreGraphics \
    -sdk $(xcrun --show-sdk-path)

echo "App compilation successful: $OUTPUT_BINARY"

# Compile Tests
TEST_SOURCE_FILES=$(ls $SOURCE_DIR/*.swift | grep -v "main.swift")
TEST_LOGIC_FILES=$(find Tests -name "*.swift")
echo "Compiling test binary: EZSwitcher_Tests"
echo "Logic Files: $TEST_LOGIC_FILES"

swiftc -o EZSwitcher_Tests $TEST_SOURCE_FILES $TEST_LOGIC_FILES \
    -framework Cocoa \
    -framework Carbon \
    -framework NaturalLanguage \
    -framework AppKit \
    -framework CoreGraphics \
    -sdk $(xcrun --show-sdk-path)

echo "Test compilation successful: EZSwitcher_Tests"
