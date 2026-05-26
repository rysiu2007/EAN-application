project(DataPlugin LANGUAGES CXX)

# Tworzymy dynamiczn¹ bibliotekê DLL
add_library(DataPlugin SHARED dll_main.cpp dll_main.h)

# Wskazujemy, ¿e ten podprojekt potrzebuje widzieæ struktury danych z g³ównego folderu
target_include_directories(DataPlugin PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/..)

target_link_libraries(DataPlugin PRIVATE MathCore)