cmake_minimum_required(VERSION 3.24)

project(Hesh
    VERSION 0.2.4
    DESCRIPTION "A lightweight device development and emulation environment"
    LANGUAGES CXX
)

include(GNUInstallDirs)

option(HESH_ENABLE_ANDROID
       "Enable the resource-intensive Android emulator runtime"
       OFF)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui Widgets Quick QuickControls2 Test WebEngineQuick)

qt_policy(SET QTP0001 NEW)
qt_policy(SET QTP0004 NEW)

qt_add_library(hesh_core STATIC
    src/app/Application.cpp
    src/app/Application.hpp
    src/app/FeatureFlags.hpp
    src/app/Settings.cpp
    src/app/Settings.hpp
    src/app/ShortcutManager.cpp
    src/app/ShortcutManager.hpp
    src/devices/Device.cpp
    src/devices/Device.hpp
    src/devices/DeviceManager.cpp
    src/devices/DeviceManager.hpp
    src/devices/DeviceProfile.cpp
    src/devices/DeviceProfile.hpp
    src/android/AndroidDevice.cpp
    src/android/AndroidDevice.hpp
    src/android/AndroidRuntime.cpp
    src/android/AndroidRuntime.hpp
    src/web/WebDevice.cpp
    src/web/WebDevice.hpp
)

target_include_directories(hesh_core
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/src
)

if(HESH_ENABLE_ANDROID)
    target_compile_definitions(hesh_core PUBLIC HESH_ENABLE_ANDROID=1)
else()
    target_compile_definitions(hesh_core PUBLIC HESH_ENABLE_ANDROID=0)
endif()

target_link_libraries(hesh_core
    PUBLIC
        Qt6::Core
        Qt6::Gui
        Qt6::Widgets
        Qt6::WebEngineQuick
)

qt_add_executable(hesh
    src/main.cpp
)

target_link_libraries(hesh
    PRIVATE
        hesh_core
        Qt6::Gui
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::WebEngineQuick
)

target_compile_definitions(hesh PRIVATE HESH_VERSION="${PROJECT_VERSION}")

set_source_files_properties(qml/theme/Theme.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(hesh
    URI Hesh
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/components/AppButton.qml
        qml/components/AndroidFrame.qml
        qml/components/DeviceFrame.qml
        qml/components/DeviceContextMenu.qml
        qml/components/DeviceListItem.qml
        qml/components/DevToolsWindow.qml
        qml/components/EmptyState.qml
        qml/components/IconButton.qml
        qml/components/Sidebar.qml
        qml/components/StatusBadge.qml
        qml/components/StandaloneContextMenu.qml
        qml/components/WebContextMenu.qml
        qml/dialogs/CreateDeviceDialog.qml
        qml/dialogs/EditDeviceDialog.qml
        qml/pages/DeviceWorkspace.qml
        qml/pages/StandaloneDeviceWindow.qml
        qml/pages/ShortcutSettings.qml
        qml/theme/Theme.qml
    RESOURCES
        qml/theme/qmldir
        assets/icons/hesh.png
        assets/icons/web-device.svg
        assets/icons/android-device.svg
)

qt_add_executable(hesh_tests
    tests/device_tests.cpp
)

target_link_libraries(hesh_tests
    PRIVATE
        hesh_core
        Qt6::Test
)

enable_testing()
add_test(NAME hesh_core_tests COMMAND hesh_tests)

install(TARGETS hesh
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

install(FILES assets/hesh.desktop
    DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/applications
)

install(FILES assets/icons/hesh.png
    DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/512x512/apps
)
