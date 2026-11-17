cmake_minimum_required(VERSION 3.20)
project(focuswave-focus-overlay VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

include(GNUInstallDirs)

find_package(Qt6 6.5 REQUIRED COMPONENTS Widgets DBus)
find_package(KF6WindowSystem REQUIRED)
find_package(KF6Config REQUIRED)

add_executable(focuswave-focus-overlay main.cpp)
target_link_libraries(focuswave-focus-overlay PRIVATE
    Qt6::Widgets
    Qt6::DBus
    KF6::WindowSystem
    KF6::ConfigCore
)

install(TARGETS focuswave-focus-overlay RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES org.focuswave.FocusMode.service DESTINATION ${CMAKE_INSTALL_DATADIR}/dbus-1/services)
