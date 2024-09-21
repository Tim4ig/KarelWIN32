#!/bin/bash

# bare minimum for clone
echo "Checking if git installed"
if ! command -v git &> /dev/null; then
  echo "Git not found. You must install it from https://git-scm.com/downloads" >&2
  exit 1
else
    echo "Git found - OK"
fi

# clone
#echo "Download karel core src"
#git clone git@github.com:Tim4ig/karel-install.git
#if ! cd ./karel-install/macOS; then
#    echo "Error: Failed to change directory to ./karel-install/macOS" >&2
#    exit 1
#fi

echo "Checking if all tools for build install"
/bin/bash ./shHelpers/installBrew.sh
/bin/bash ./shHelpers/installBuildTools.sh
/bin/bash ./shHelpers/installNcurses.sh
echo "Configure Cmake"
cmake -S . -B build-release -G Ninja -DCMAKE_BUILD_TYPE=Release
echo "Build"
cmake --build build-release
echo "Install"
cmake --install build-release
echo "Configure PATH"
/bin/bash ./shHelpers/configurePATH.sh
echo "Terminal window can be closed, dir can be removed."
echo "System should be rebooted to detect changes."
