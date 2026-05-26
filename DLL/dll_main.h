#include "../include/math_core.h"

extern "C" {
    // Zwraca liczbê równañ (u nas 5)
    __declspec(dllexport) int GetNum();

    // F1 - F5: Oblicza wartoœci funkcji w punkcie X i zapisuje w out_f
    __declspec(dllexport) void f1(double_num* x, double_num* out_f);
    __declspec(dllexport) void f2(double_num* x, double_num* out_f);
    __declspec(dllexport) void f3(double_num* x, double_num* out_f);

    __declspec(dllexport) void df1(double_num* x, double_num* out_f);
    __declspec(dllexport) void df2(double_num* x, double_num* out_f);
    __declspec(dllexport) void df3(double_num* x, double_num* out_f);
}