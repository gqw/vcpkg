vcpkg_fail_port_install(ON_TARGET "uwp")

if(VCPKG_TARGET_IS_WINDOWS)
    # Building python bindings is currently broken on Windows
    if("python" IN_LIST FEATURES)
        message(FATAL_ERROR "The python feature is currently broken on Windows")
    endif()

    if(NOT "iconv" IN_LIST FEATURES)
        # prevent picking up libiconv if it happens to already be installed
        set(ICONV_PATCH "no_use_iconv.patch")
    endif()

    if(VCPKG_CRT_LINKAGE STREQUAL "static")
        set(_static_runtime ON)
		set(_BUILD_SHARED_LIBS OFF)
	else()
		set(_static_runtime OFF)
		set(_BUILD_SHARED_LIBS ON)
    endif()
endif()

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
	FEATURES
		deprfun     deprecated-functions
		examples    build_examples
		python      python-bindings
		test        build_tests
		tools       build_tools
)

# Note: the python feature currently requires `python3-dev` and `python3-setuptools` installed on the system
if("python" IN_LIST FEATURES)
    vcpkg_find_acquire_program(PYTHON3)
    get_filename_component(PYTHON3_PATH ${PYTHON3} DIRECTORY)
    vcpkg_add_to_path(${PYTHON3_PATH})

    file(GLOB BOOST_PYTHON_LIB "${CURRENT_INSTALLED_DIR}/lib/*boost_python*")
    string(REGEX REPLACE ".*(python)([0-9])([0-9]+).*" "\\1\\2\\3" _boost-python-module-name "${BOOST_PYTHON_LIB}")
endif()

message("clone begin...***************************************")
# get_cmake_property(_variableNames VARIABLES)
# list (SORT _variableNames)
# foreach (_variableName ${_variableNames})
    # message(STATUS "${_variableName}=${${_variableName}}")
# endforeach()

set(GIT_URL "https://github.com/gqw/libtorrent.git")
set(GIT_REV "9b7846ddda32256f197a506eccd5e319c44b2d3d")

set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/${PORT})


if(NOT EXISTS "${SOURCE_PATH}/.git")
	file(MAKE_DIRECTORY ${SOURCE_PATH})
	message(STATUS ${GIT} clone --recurse-submodules ${GIT_URL} ${SOURCE_PATH})
	vcpkg_execute_required_process(
	  COMMAND ${GIT} clone --recurse-submodules ${GIT_URL} ${SOURCE_PATH}
	  WORKING_DIRECTORY ${SOURCE_PATH}
	  LOGNAME clone
	)

	message(STATUS "Checkout revision ${GIT_REV}")
	vcpkg_execute_required_process(
	  COMMAND ${GIT} checkout ${GIT_REV}
	  WORKING_DIRECTORY ${SOURCE_PATH}
	  LOGNAME checkout
	)
else()
	message(STATUS "${GIT} pull")
	vcpkg_execute_required_process(
	  COMMAND ${GIT} checkout gqw 
	  WORKING_DIRECTORY ${SOURCE_PATH}
	  LOGNAME pull
	)
	vcpkg_execute_required_process(
	  COMMAND ${GIT} pull
	  WORKING_DIRECTORY ${SOURCE_PATH}
	  LOGNAME pull
	)
	vcpkg_execute_required_process(
	  COMMAND ${GIT} reset --hard ${GIT_REV}
	  WORKING_DIRECTORY ${SOURCE_PATH}
	  LOGNAME checkout
	)
	vcpkg_execute_required_process(
	  COMMAND ${GIT} submodule init
	  WORKING_DIRECTORY ${SOURCE_PATH}
	  LOGNAME checkout
	)
	vcpkg_execute_required_process(
	  COMMAND ${GIT} submodule update
	  WORKING_DIRECTORY ${SOURCE_PATH}
	  LOGNAME checkout
	)
endif()



# vcpkg_from_github(
    # OUT_SOURCE_PATH SOURCE_PATH
    # REPO arvidn/libtorrent
    # REF af7a96c1df47fcc8fbe0d791c223b0ab8a7d2125 #v1.2.12
    # SHA512 1c1a73f065e6c726ef6b87f6be139abb96bdb2d924e4c6eb3ed736ded3762b9f250c44bd4fc7b703975463bcca18d7518e0588703616e686021b575b8f1193f0
    # HEAD_REF RC_2_0
# )

# vcpkg_from_git(
	# URL git@git.ot.netease.com:Components/libtorrent.git
	# OUT_SOURCE_PATH SOURCE_PATH
	# REPO Components/libtorrent.git
	# REF 453b81ab6d9a9b0ae4cb47d8c38dd381074b5caa
# )

message("clone end!!!***************************************")

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA # Disable this option if project cannot be built with Ninja
    OPTIONS
        ${FEATURE_OPTIONS}
        -Dboost-python-module-name=${_boost-python-module-name}
        -Dstatic_runtime=${_static_runtime}
		-DBUILD_SHARED_LIBS=${_BUILD_SHARED_LIBS}
        -DPython3_USE_STATIC_LIBS=ON
		-DOPENSSL_ROOT_DIR="${CURRENT_INSTALLED_DIR}" 
		-DBoost_INCLUDE_DIR="${CURRENT_INSTALLED_DIR}/include" 
)

vcpkg_install_cmake()

vcpkg_fixup_cmake_targets(CONFIG_PATH lib/cmake/LibtorrentRasterbar TARGET_PATH share/LibtorrentRasterbar)

# Handle copyright
file(INSTALL ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)

# Do not duplicate include files
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include ${CURRENT_PACKAGES_DIR}/debug/share ${CURRENT_PACKAGES_DIR}/share/cmake)
