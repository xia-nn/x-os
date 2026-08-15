cmake_minimum_required(VERSION 3.16)
project(xos-shell VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC OFF)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Gui Qml Quick)

add_executable(xos-shell
    src/main.cpp
    src/shellcontroller.h
    src/shellcontroller.cpp
)

target_link_libraries(xos-shell PRIVATE
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
)

# 安装二进制与 QML 资源
install(TARGETS xos-shell RUNTIME DESTINATION bin)
install(DIRECTORY qml/ DESTINATION share/xos-shell)
