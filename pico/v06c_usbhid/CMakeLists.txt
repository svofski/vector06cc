# Generated Cmake Pico project file

cmake_minimum_required(VERSION 3.13)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# Initialise pico_sdk from installed location
# (note this can come from environment, CMake cache etc)
set(PICO_SDK_PATH "/home/svo/pico/pico-sdk")

set(PICO_BOARD pico CACHE STRING "Board type")

# Pull in Raspberry Pi Pico SDK (must be before project)
include(pico_sdk_import.cmake)

if (PICO_SDK_VERSION_STRING VERSION_LESS "1.4.0")
  message(FATAL_ERROR "Raspberry Pi Pico SDK version 1.4.0 (or later) required. Your version is ${PICO_SDK_VERSION_STRING}")
endif()

project(v06c_usbhid C CXX ASM)

# Initialise the Raspberry Pi Pico SDK
pico_sdk_init()

# Add executable. Default name is the project name, version 0.1

add_executable(v06c_usbhid main.c hid_app.c msc_app.c cdc_app.c matrix.c)

pico_set_program_name(v06c_usbhid "v06c_usbhid")
pico_set_program_version(v06c_usbhid "0.1")

pico_enable_stdio_uart(v06c_usbhid 1)
pico_enable_stdio_usb(v06c_usbhid 0)

# Add the standard library to the build
target_link_libraries(v06c_usbhid
        pico_stdlib)

# Add the standard include files to the build
target_include_directories(v06c_usbhid PRIVATE
  ${CMAKE_CURRENT_LIST_DIR}
  ${CMAKE_CURRENT_LIST_DIR}/.. # for our common lwipopts or any other standard includes, if required
)

# Add any user requested libraries
target_link_libraries(v06c_usbhid 
        hardware_spi
        hardware_pio
        pico_stdlib tinyusb_host tinyusb_board
        )

    target_compile_definitions(v06c_usbhid PRIVATE HID_ADAPTER=1)

pico_add_extra_outputs(v06c_usbhid)

