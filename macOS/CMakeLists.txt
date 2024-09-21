cmake_minimum_required(VERSION 3.26)
project(karel VERSION 2.0.0 LANGUAGES C)
include(func.cmake)

# --------[Configure Build Section]--------
set(CMAKE_C_STANDARD 23)
set(CMAKE_C_STANDARD_REQUIRED ON)
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "$ENV{HOME}/local" CACHE PATH "Install path prefix, prepended onto install directories." FORCE)
endif()
# --------[Configure Build Section]--------

set(SRC
    ./src/internals.c ./src/internals.h
    ./src/karel.c ./src/karel.h
    ./src/superkarel.c ./src/superkarel.h
)
set(INC # internals should be hidden from user
    ./src/karel.h ./src/superkarel.h
)

setup_build_flags()
install_lib(karel "${SRC}" "${INC}")
add_custom_target(build_all DEPENDS karel_static karel_shared)
create_uninstall_lib_target()
