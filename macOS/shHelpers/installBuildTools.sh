#!/bin/bash

#required: brew

if ! command -v clang &> /dev/null; then
  echo "Clang not found. Installing \"Command Line Tools for Xcode\"..."
  xcode-select --install
  return 1
else
    echo "clang found - OK"
fi

if ! command -v cmake &> /dev/null; then
  echo "CMake not found. Installing CMake..."
  brew install cmake
  echo "CMake Installed"
else
    echo "CMake found"
fi

if ! command -v ninja &> /dev/null; then
  echo "Ninja not found. Installing Ninja..."
  brew install ninja
  echo "Ninja Installed"
else
    echo "Ninja found"
fi
