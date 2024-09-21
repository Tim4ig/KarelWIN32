#!/bin/bash

#required: brew

ncurses_path=$(find /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX*.sdk/usr/lib/ -name "libcurses.tbd" 2>/dev/null)

if [ -n "$ncurses_path" ]; then
    echo "ncurses is already part of the macOS SDK."
else
    echo "ncurses not found in macOS SDK."
    echo "Check if ncurses installed via Homebrew."
    if brew list | grep -q "ncurses"; then
        echo "ncurses successfully found."
    else
        echo "Failed to found ncurses."
        echo "Install ncurses via Homebrew"
        brew install ncurses
    fi
fi
