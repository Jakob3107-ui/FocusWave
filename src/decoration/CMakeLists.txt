cmake_minimum_required(VERSION 3.20)
project(focuswave-decoration VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

find_package(ECM REQUIRED NO_MODULE)
list(APPEND CMAKE_MODULE_PATH ${ECM_MODULE_PATH})
include(KDEInstallDirs6)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui)
find_package(KDecoration3 REQUIRED)
find_package(KF6CoreAddons REQUIRED)

# KDecoration3 switched paint() from QRect to QRectF at some point; detect which one we have.
include(CheckCXXSourceCompiles)
set(CMAKE_REQUIRED_LIBRARIES KDecoration3::KDecoration Qt6::Gui)
set(CMAKE_REQUIRED_FLAGS "-fPIC -std=c++20")
check_cxx_source_compiles([=[
#include <KDecoration3/Decoration>
#include <QPainter>
class Probe : public KDecoration3::Decoration {
public:
    Probe() : KDecoration3::Decoration(nullptr, QVariantList()) {}
    bool init() override { return true; }
    void paint(QPainter *, const QRectF &) override {}
};
int main() { return 0; }
]=] FW_KDECO_FLOAT_PROBE)
check_cxx_source_compiles([=[
#include <KDecoration3/Decoration>
#include <QPainter>
class Probe : public KDecoration3::Decoration {
public:
    Probe() : KDecoration3::Decoration(nullptr, QVariantList()) {}
    bool init() override { return true; }
    void paint(QPainter *, const QRect &) override {}
};
int main() { return 0; }
]=] FW_KDECO_INT_PROBE)
unset(CMAKE_REQUIRED_LIBRARIES)
unset(CMAKE_REQUIRED_FLAGS)

# Prefer QRectF (current KDecoration3); use QRect only if that is clearly what this version wants.
if(FW_KDECO_INT_PROBE AND NOT FW_KDECO_FLOAT_PROBE)
    set(FW_KDECO_FLOAT OFF)
else()
    set(FW_KDECO_FLOAT ON)
endif()
message(STATUS "FocusWave decoration: paint() uses QRectF = ${FW_KDECO_FLOAT}")

if(NOT KDECORATION_PLUGIN_DIR)
    set(KDECORATION_PLUGIN_DIR "org.kde.kdecoration3")
endif()

add_library(org.focuswave.decoration MODULE decoration.cpp)
if(FW_KDECO_FLOAT)
    target_compile_definitions(org.focuswave.decoration PRIVATE FW_KDECO_FLOAT)
endif()
target_link_libraries(org.focuswave.decoration PRIVATE
    KDecoration3::KDecoration
    KF6::CoreAddons
    Qt6::Gui
)
set_target_properties(org.focuswave.decoration PROPERTIES PREFIX "")

install(TARGETS org.focuswave.decoration DESTINATION ${KDE_INSTALL_PLUGINDIR}/${KDECORATION_PLUGIN_DIR})
