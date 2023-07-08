set(CMAKE_POLICY_DEFAULT_CMP0077 NEW)
cmake_minimum_required(VERSION 3.5)

# Add LLVMs sanitizers
option(CMAKE_SANITIZER_MOD "Enable AddressSanitizer for sanitized targets." Off)
if (CMAKE_SANITIZER_MOD)
   set(CMAKE_MODULE_PATH "${CMAKE_SANITIZER_MOD}/cmake" ${CMAKE_MODULE_PATH})
   message("CMAKE_SANITIZER_MOD is set to ${CMAKE_SANITIZER_MOD}/cmake")
   # Use clang lld instead of gnu ld
   set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fuse-ld=lld")

elseif(DEFINED ENV{CMAKE_SANITIZER_MOD})
  set(CMAKE_MODULE_PATH "$ENV{CMAKE_SANITIZER_MOD}/cmake" ${CMAKE_MODULE_PATH})
  message("ENV{CMAKE_SANITIZER_MOD} is set to $ENV{CMAKE_SANITIZER_MOD}/cmake")
  # Use clang lld instead of gnu ld
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fuse-ld=lld")

else()
  message(WARNING "Could not find cmake sanitizer module. Use "
  "cmake -DCMAKE_SANITIZER_MOD=path_to_module or set an env variable")
  function(add_sanitizers target)
    message(WARNING "Sanitizers disabled for target ${target}")
    return()
  endfunction(add_sanitizers)
endif()

# Add clang-format target
option(CMAKE_FORMAT_MOD "Enable clang format" Off)
if (CMAKE_FORMAT_MOD)
   list(APPEND CMAKE_MODULE_PATH ${CMAKE_FORMAT_MOD}/cmake)
   message("CMAKE_FORMAT_MOD is set to ${CMAKE_FORMAT_MOD}/cmake")
elseif(DEFINED ENV{CMAKE_FORMAT_MOD})
  list(APPEND CMAKE_MODULE_PATH $ENV{CMAKE_FORMAT_MOD}/cmake)
  message("ENV{CMAKE_FORMAT_MOD} is set to $ENV{CMAKE_FORMAT_MOD}/cmake")
else()
  message(WARNING "Could not find cmake format module. Use "
  "cmake --DCMAKE_FORMAT_MOD=path_to_module or set an env variable")
  function(target_clangformat_setup target)
    message(WARNING "Clang format disabled for target ${target}")
    return()
  endfunction(target_clangformat_setup)
endif()


#Add sanitizer functions
#set(SANITIZE_ADDRESS TRUE)
set(SANITIZE_UNDEFINED TRUE)

# Use ANSI color escape codes for logging
#add_definitions(-DLOG_USE_COLOR)

# Generate compile_commands.json for language server
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)



project (Network-Simulator)
find_package(Sanitizers)

# Adds clang-format
find_package(ClangFormat)

# Enable static c analyzer clang-tidy
set(CMAKE_C_LANG_TIDY "clang-tidy;-checks=*")

# Add system include directories to compile_commands.json
set(CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES ${CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES};${CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES})


# Client
add_executable(client
  src/main.cpp
)

target_link_libraries(client PUBLIC 
ns3.39-core 
ns3.39-applications 
ns3.39-internet 
ns3.39-csma 
ns3.39-network
ns3.39-tap-bridge
ns3.39-virtual-net-device
ns3.39-fd-net-device
)

#add_sanitizers(client) # Add LLVMs sanitizers
target_include_directories(client PRIVATE include)
set_target_properties(client PROPERTIES OUTPUT_NAME "network-simulator")
target_compile_options (client PRIVATE -Og  -Wall -Wextra -Wpedantic -Wno-unused-parameter)
target_compile_options (client PRIVATE -gfull -fno-limit-debug-info) # Needed for better stack traces
set_property(TARGET client PROPERTY CXX_STANDARD 23)
install(TARGETS client
  RUNTIME DESTINATION "."
  DESTINATION ${CMAKE_INSTALL_BINDIR}
)
target_clangformat_setup(client) # Add clang format build target
