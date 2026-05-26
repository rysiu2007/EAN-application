#include "../include/math_core.h"

extern "C" {
    mode software_mode;
    __declspec(dllexport) void SetMode(mode soft_mode);
    // Zwraca liczbê równañ (u nas 5)
    __declspec(dllexport) unsigned long long GetNum();

    // F1 - F5: Oblicza wartoœci funkcji w punkcie X i zapisuje w out_f
    __declspec(dllexport) void f1(double_num* x, double_num* out_f);
    __declspec(dllexport) void f2(double_num* x, double_num* out_f);
    __declspec(dllexport) void f3(double_num* x, double_num* out_f);

    __declspec(dllexport) void df1(double_num* x, double_num* out_f);
    __declspec(dllexport) void df2(double_num* x, double_num* out_f);
    __declspec(dllexport) void df3(double_num* x, double_num* out_f);
}