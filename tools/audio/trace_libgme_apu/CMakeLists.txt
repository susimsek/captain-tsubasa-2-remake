cmake_minimum_required(VERSION 3.16)
project(ct2_libgme_apu_trace LANGUAGES CXX)

if(NOT DEFINED CT2_GME_SOURCE)
	message(FATAL_ERROR "Set CT2_GME_SOURCE to the extracted Game_Music_Emu 0.6.5 source tree")
endif()

set(GME_BUILD_SHARED OFF CACHE BOOL "" FORCE)
set(GME_BUILD_STATIC ON CACHE BOOL "" FORCE)
set(GME_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(GME_BUILD_TESTING OFF CACHE BOOL "" FORCE)
set(GME_ZLIB OFF CACHE BOOL "" FORCE)
set(USE_GME_AY OFF CACHE BOOL "" FORCE)
set(USE_GME_GBS OFF CACHE BOOL "" FORCE)
set(USE_GME_GYM OFF CACHE BOOL "" FORCE)
set(USE_GME_HES OFF CACHE BOOL "" FORCE)
set(USE_GME_KSS OFF CACHE BOOL "" FORCE)
set(USE_GME_NSF ON CACHE BOOL "" FORCE)
set(USE_GME_NSFE OFF CACHE BOOL "" FORCE)
set(USE_GME_SAP OFF CACHE BOOL "" FORCE)
set(USE_GME_SPC OFF CACHE BOOL "" FORCE)
set(USE_GME_VGM OFF CACHE BOOL "" FORCE)

add_subdirectory("${CT2_GME_SOURCE}" gme)

add_executable(ct2_libgme_apu_trace
	trace_main.cpp
	trace_hooks.cpp
)
target_include_directories(ct2_libgme_apu_trace PRIVATE
	"${CT2_GME_SOURCE}/gme"
	"${CMAKE_CURRENT_LIST_DIR}"
)
target_link_libraries(ct2_libgme_apu_trace PRIVATE gme_static)
target_compile_features(ct2_libgme_apu_trace PRIVATE cxx_std_11)
