function(setup_build_flags)
  set(ERROR_FLAGS "-Werror=vla -Werror -Wall -Wno-unused-function  -Wno-deprecated-declarations")
  set(OPTIMIZATION_FLAGS "-march=native")
  if(CMAKE_BUILD_TYPE STREQUAL "Release")
    message(STATUS "Build in Release mode")
    add_definitions(-DNDEBUG)
    set(RELEASE_FLAGS "-Ofast -flto")
    set(RELEASE_CHECKS "-Wextra -pedantic -Wno-unused-parameter")
    string(APPEND CMAKE_C_FLAGS " ${ERROR_FLAGS} ${OPTIMIZATION_FLAGS} ${RELEASE_FLAGS} ${RELEASE_CHECKS}")
  elseif(CMAKE_BUILD_TYPE STREQUAL "Debug")
    message(STATUS "Build in Debug mode")
    add_definitions(-DDEBUG=1)
    set(DEBUG_REMOVED_CHECKS "-Wno-unused-function -Wno-unused-but-set-variable -Wno-unused-variable -Wno-unused-parameter -Wno-unused-private-field")
    string(APPEND CMAKE_C_FLAGS " ${ERROR_FLAGS} ${OPTIMIZATION_FLAGS} ${DEBUG_REMOVED_CHECKS}")
    add_compile_options(-Wunused-variable) # Warn on unused variables
    add_compile_options(-Wno-error=unused-variable) # Do not treat unused variable warnings as errors
    add_compile_options(-Wunused-local-typedef) # Warn on unused local typedef
    add_compile_options(-Wno-error=unused-local-typedef) # Do not treat unused local typedef warnings as errors
  endif()
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS}" PARENT_SCOPE)
endfunction()

function(install_lib LIB_NAME SRC_FILES INC_FILES)
  find_package(Curses REQUIRED)
  set(CURSES_USE_NCURSES ON)
  set(LIBRARY_TYPES SHARED STATIC)
  foreach(LIB_TYPE ${LIBRARY_TYPES})
    if(${LIB_TYPE} STREQUAL "STATIC")
      set(LIB_SUFFIX "_static")
    else()
      set(LIB_SUFFIX "_shared")
    endif()
    set(FULL_LIB_NAME ${LIB_NAME}${LIB_SUFFIX})
    add_library(${FULL_LIB_NAME} ${LIB_TYPE} ${SRC_FILES})
    set_target_properties(${FULL_LIB_NAME} PROPERTIES
        OUTPUT_NAME ${LIB_NAME}
        C_STANDARD ${CMAKE_C_STANDARD}
    )
    target_include_directories(${FULL_LIB_NAME} PRIVATE ${CURSES_INCLUDE_DIR})
    target_link_libraries(${FULL_LIB_NAME} ${CURSES_LIBRARIES})
    install(TARGETS ${FULL_LIB_NAME} DESTINATION lib)
  endforeach()
  install(
      FILES ${INC_FILES}
      DESTINATION include
  )
endfunction()

function(create_uninstall_lib_target)
  # Always add uninstall target
  add_custom_target(uninstall
      COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake
      COMMENT "Uninstalling project..."
  )

  # Generate the cmake_uninstall.cmake script from the template
  configure_file(
      "${CMAKE_CURRENT_SOURCE_DIR}/cmake_uninstall.cmake.in"
      "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
      IMMEDIATE @ONLY
  )
endfunction()
