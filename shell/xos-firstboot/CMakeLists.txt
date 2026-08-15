cmake_minimum_required(VERSION 3.16)
project(xos-firstboot VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC OFF)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Gui Qml Quick)

add_executable(xos-firstboot
    src/main.cpp
    src/firstbootcontroller.h
    src/firstbootcontroller.cpp
)

target_link_libraries(xos-firstboot PRIVATE
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
)

# 安装二进制与 QML 资源
install(TARGETS xos-firstboot RUNTIME DESTINATION bin)
install(DIRECTORY qml/ DESTINATION share/xos-firstboot)
