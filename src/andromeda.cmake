cmake_minimum_required(VERSION 3.16)

# this common file is to be included for each lib or bin target

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

set(ANDROMEDA_VERSION "0.1-alpha")
set(ANDROMEDA_CXX_DEFS 
    ANDROMEDA_VERSION="${ANDROMEDA_VERSION}"
    SYSTEM_NAME="${CMAKE_SYSTEM_NAME}"
    DEBUG=$<IF:$<CONFIG:Debug>,1,0>)

if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    list(APPEND ANDROMEDA_CXX_DEFS LINUX)
elseif (${CMAKE_SYSTEM_NAME} MATCHES "FreeBSD")
    list(APPEND ANDROMEDA_CXX_DEFS FREEBSD)
elseif (APPLE)
    list(APPEND ANDROMEDA_CXX_DEFS APPLE)
endif()

include(GNUInstallDirs)

# include and setup FetchContent

include(FetchContent)
set(FETCHCONTENT_QUIET FALSE)

option(BUILD_TESTS "Build unit tests" OFF)

if (BUILD_TESTS)
    FetchContent_Declare(Catch2
        GIT_REPOSITORY https://github.com/catchorg/Catch2.git
        GIT_TAG        v3.3.2)
    FetchContent_MakeAvailable(Catch2)
    list(APPEND CMAKE_MODULE_PATH ${catch2_SOURCE_DIR}/extras)
    
    if (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/_tests)
        add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/_tests)
    endif()

    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        target_compile_options(Catch2 PRIVATE -Wno-psabi)
    endif()
endif()

# define compiler warnings

# resource for custom warning codes
# https://github.com/cpp-best-practices/cppbestpractices/blob/master/02-Use_the_Tools_Available.md

option(ALLOW_WARNINGS "Allow building with warnings" OFF)

if (MSVC)
    set(ANDROMEDA_CXX_WARNS /W4 /permissive-
        /wd4100 # NO unreferenced formal parameter
        /wd4101 # NO unreferenced local variable
        /wd4702 # NO unreachable code (Qt)
        /w14242 /w14254 /w14263 /w14265
        /w14287 /we4289 /w14296 /w14311
        /w14545 /w14546 /w14547 /w14549
        /w14555 /w14619 /w14640 /w14826
        /w14905 /w14906 /w14928
    )

    if (NOT ${ALLOW_WARNINGS})
        list(APPEND ANDROMEDA_CXX_WARNS /WX)
    endif()

    # security options
    set(ANDROMEDA_CXX_OPTS)
    set(ANDROMEDA_LINK_OPTS 
        /NXCOMPAT /DYNAMICBASE
    )

else() # NOT MSVC

    ### ADD WARNINGS ###

    set(ANDROMEDA_CXX_WARNS -Wall -Wextra
        -pedantic -Wpedantic
        -Wno-unused-parameter # NO unused parameter
        -Wcast-align
        -Wcast-qual 
        -Wconversion 
        -Wdouble-promotion
        -Wformat=2 
        -Wimplicit-fallthrough
        -Wnon-virtual-dtor 
        -Wold-style-cast
        -Woverloaded-virtual 
        -Wsign-conversion
        -Wshadow
    )
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        list(APPEND ANDROMEDA_CXX_WARNS 
            -Wduplicated-branches
            -Wduplicated-cond
            -Wlogical-op 
            -Wmisleading-indentation
            -Wnull-dereference # effective with -O3
            -Wno-psabi # ignore GCC 7.1 armhf ABI change
        )
    elseif (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        list(APPEND ANDROMEDA_CXX_WARNS 
            -Wnewline-eof
        )
    endif()

    if (NOT ${ALLOW_WARNINGS})
        list(APPEND ANDROMEDA_CXX_WARNS 
            -Werror -pedantic-errors)
    endif()

    ### ADD HARDENING ###

    # https://wiki.ubuntu.com/ToolChain/CompilerFlags
    # https://developers.redhat.com/blog/2018/03/21/compiler-and-linker-flags-gcc

    # security options
    set(ANDROMEDA_CXX_OPTS
        # NOTE FORTIFY_SOURCE works better with optimization
        -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3
        -D_GLIBCXX_ASSERTIONS
        -fstack-protector-strong # stack protection
        --param=ssp-buffer-size=4 # stack protection
    )
    if (NOT APPLE)
        set(ANDROMEDA_LINK_OPTS
            -Wl,-z,relro # relocation read-only
            -Wl,-z,now   # bind symbols at startup
            -Wl,-z,noexecstack # no-exec stack
        )
    endif()

    ### ADD PIC/PIE ###

    option(WITHOUT_PIE "Disable position independent executable" OFF)
    if (NOT ${WITHOUT_PIE})
        list(APPEND ANDROMEDA_CXX_OPTS -fPIE)
        list(APPEND ANDROMEDA_LINK_OPTS -Wl,-pie -pie)
    endif()

    ### ADD SANITIZERS ###

    set(SANITIZE "address,leak,undefined" CACHE STRING "Build with sanitizers")
    if (NOT ${SANITIZE} STREQUAL "" AND NOT ${SANITIZE} STREQUAL "none")
        list(APPEND ANDROMEDA_CXX_OPTS $<$<CONFIG:Debug>:-fsanitize=${SANITIZE}>)
        list(APPEND ANDROMEDA_LINK_OPTS $<$<CONFIG:Debug>:-fsanitize=${SANITIZE}>)
    endif()

endif() # MSVC

function(andromeda_bin bin_name)
    target_compile_options(${bin_name} PRIVATE ${ANDROMEDA_CXX_WARNS} ${ANDROMEDA_CXX_OPTS})
    target_compile_definitions(${bin_name} PRIVATE ${ANDROMEDA_CXX_DEFS})
    target_link_options(${bin_name} PRIVATE ${ANDROMEDA_LINK_OPTS})
endfunction()

function(andromeda_lib lib_name)
    set_target_properties(${lib_name} PROPERTIES PREFIX "")
    target_compile_options(${lib_name} PRIVATE ${ANDROMEDA_CXX_WARNS} ${ANDROMEDA_CXX_OPTS})
    target_compile_definitions(${lib_name} PRIVATE ${ANDROMEDA_CXX_DEFS})
endfunction()

function (andromeda_test test_name)
    target_link_libraries(${test_name} PRIVATE Catch2::Catch2WithMain)
    target_compile_options(Catch2 PRIVATE ${ANDROMEDA_CXX_OPTS}) # hardening
    target_compile_options(Catch2WithMain PRIVATE ${ANDROMEDA_CXX_OPTS}) # hardening
    # Run the test - if it fails and you don't want it deleted, comment this line
    add_custom_command(TARGET ${test_name} POST_BUILD COMMAND ${test_name})
endfunction()