project(DataPlugin LANGUAGES CXX)

# Tworzymy dynamiczn¹ bibliotekê DLL
add_library(DataPlugin SHARED data_provider.cpp)

# Wskazujemy, ¿e ten podprojekt potrzebuje widzieæ struktury danych z g³ównego folderu
target_include_directories(DataPlugin PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/..)