#!/bin/bash
INSTALL_DIR=/usr/local
LIB_DIR=${INSTALL_DIR}/lib
INCLUDE_DIR=${INSTALL_DIR}/include

rm -f ${LIB_DIR}/libkarel.a
rm -f ${LIB_DIR}/libkarel.dylib
rm -f ${INCLUDE_DIR}/karel.h
rm -f ${INCLUDE_DIR}/superkarel.h

echo "Uninstall complete, humanity restored."
