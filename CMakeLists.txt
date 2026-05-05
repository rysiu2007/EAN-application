# CMakeList.txt: projekt CMake dla elementu EAN app, dołącz źródło i zdefiniuj
# tutaj logikę specyficzną dla projektu.
#
cmake_minimum_required (VERSION 3.8)

# Włącz przeładowywanie kodu XAML na gorąco dla kompilatorów MSVC, jeśli jest to obsługiwane.
if (POLICY CMP0141)
  cmake_policy(SET CMP0141 NEW)
  set(CMAKE_MSVC_DEBUG_INFORMATION_FORMAT "$<IF:$<AND:$<C_COMPILER_ID:MSVC>,$<CXX_COMPILER_ID:MSVC>>,$<$<CONFIG:Debug,RelWithDebInfo>:EditAndContinue>,$<$<CONFIG:Debug,RelWithDebInfo>:ProgramDatabase>>")
endif()

project ("EAN app" LANGUAGES CXX C ASM_MASM)

add_definitions(-DMPFR_USE_NO_MACRO)
add_definitions(-DMPFR_USE_INTMAX_T)
# 1. Znajdź biblioteki w systemie (vcpkg je dostarczy)
#find_package(Boost REQUIRED)

find_path(MPFR_INCLUDE_DIR NAMES mpfr.h)
find_library(MPFR_LIBRARY NAMES mpfr libmpfr)

#if(MPFR_INCLUDE_DIR AND MPFR_LIBRARY)
#    set(MPFR_FOUND TRUE)
    # Tworzymy "udawany" cel (target), żeby reszta Twojego kodu działała bez zmian
#    add_library(MPFR::MPFR UNKNOWN IMPORTED)
#    set_target_properties(MPFR::MPFR PROPERTIES
#        INTERFACE_INCLUDE_DIRECTORIES "${MPFR_INCLUDE_DIR}"
#        IMPORTED_LOCATION "${MPFR_LIBRARY}"
#    )
#    message(STATUS "Znaleziono MPFR: ${MPFR_LIBRARY}")
#else()
#    message(FATAL_ERROR "Nie znaleziono MPFR! Sprawdz czy zainstalowales: vcpkg install mpfr:x64-windows")
#endif()

set(SOURCES
    "source/EAN app.cpp"
    "source/extended_double.asm"
    "source/intervals.asm"
    "source/api.asm"
)


# 2. Dodaj pliki źródłowe
add_executable (CMakeTarget ${SOURCES} "include/api.h")

# 3. Ustaw standard C++ (skoro planujesz Interval i MPFR, C++20 to dobry wybór)
set_target_properties(CMakeTarget PROPERTIES 
    CXX_STANDARD 20
    CXX_STANDARD_REQUIRED ON
)
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_compile_options(-g -O0 -Wall)
endif()

target_include_directories(CMakeTarget PUBLIC include)
# 4. KLUCZOWE: Połącz biblioteki z Twoim programem
# To sprawi, że kompilator "zobaczy" nagłówki Boost i MPFR
target_link_libraries(CMakeTarget PRIVATE 
#    Boost::boost 
#    MPFR::MPFR
)