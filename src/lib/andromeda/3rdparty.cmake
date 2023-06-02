
# include/link libhttplib

if (APPLE)
    set(OPENSSL_ROOT_DIR /usr/local/opt/openssl)
endif()

set(HTTPLIB_COMPILE True)
set(HTTPLIB_REQUIRE_OPENSSL True)
set(HTTPLIB_USE_ZLIB_IF_AVAILABLE False)
set(HTTPLIB_USE_BROTLI_IF_AVAILABLE False)

set(DEPS_BASEURL "https://github.com" CACHE STRING "Base URL for git dependencies")
# example to set up a local git repo for testing to avoid cloning from github repeatedly
# git clone https://github.com/nlohmann/json.git --mirror; cd json.git; git --bare update-server-info; mv hooks/post-update.sample hooks/post-update

FetchContent_Declare(cpp-httplib
    GIT_REPOSITORY  ${DEPS_BASEURL}/yhirose/cpp-httplib.git
    GIT_TAG         f977558 # v0.12.3
    GIT_PROGRESS    true)
FetchContent_MakeAvailable(cpp-httplib)

target_compile_options(httplib PRIVATE ${ANDROMEDA_CXX_OPTS}) # hardening

target_link_libraries(libandromeda PUBLIC httplib)

# include/link reproc++

set(REPROC++ ON)
set(REPROC_INSTALL OFF)

FetchContent_Declare(reproc
    GIT_REPOSITORY  ${DEPS_BASEURL}/stingray-11/reproc.git
    #GIT_REPOSITORY ${DEPS_BASEURL}/DaanDeMeyer/reproc.git
    GIT_TAG         57602bf # main
    GIT_PROGRESS    true)
FetchContent_MakeAvailable(reproc)

target_compile_options(reproc PRIVATE ${ANDROMEDA_CXX_OPTS}) # hardening
target_compile_options(reproc++ PRIVATE ${ANDROMEDA_CXX_OPTS}) # hardening

target_link_libraries(libandromeda PRIVATE reproc++)

# include nlohmann (header-only)

set(JSON_ImplicitConversions "OFF")
set(JSON_BuildTests OFF CACHE INTERNAL "")

FetchContent_Declare(nlohmann_json
    GIT_REPOSITORY  ${DEPS_BASEURL}/nlohmann/json.git
    GIT_TAG         bc889af # v3.11.2
    GIT_PROGRESS    true)
FetchContent_MakeAvailable(nlohmann_json)

target_link_libraries(libandromeda PUBLIC nlohmann_json)