#include "dll_main.h"
#include <string.h>

void MakeDoubleNum(double_num* dest, const char* str) {
    extended_double temp_ed;

    // 1. Twój parser robi bezpieczn¹ konwersjê string -> float80
    ED_FromString(&temp_ed, str, static_cast<int>(strlen(str)));

    // 2. £adujemy to do unii (gdzie software_mode ustawi odpowiednio FPU / Interwa³)
    M_LoadNum(&temp_ed, dest);
}
extern "C" {
    __declspec(dllexport) void SetMode(mode soft_mode) {
        software_mode = soft_mode;
    }

    __declspec(dllexport) unsigned long long GetNum() {
        return 3;
    }
    // f1(x,y,z) = 2*x^2 + y + z = 0
    __declspec(dllexport)void f1(double_num* ret, double_num* tab) {
        double_num* x = &tab[0], * y = &tab[1], * z = &tab[2];
        double_num x2, cx2, sum1;
        double_num c2; MakeDoubleNum(&c2, "2.0");

        M_Mul(x, x, &x2);
        M_Mul(&c2, &x2, &cx2); // 2 * x^2
        M_Add(&cx2, y, &sum1); // 2 * x^2 + y
        M_Add(&sum1, z, ret);  // 2 * x^2 + y + z
    }

    // f2(x,y,z) = x*y - z + 2 = 0
    __declspec(dllexport) void f2(double_num* ret, double_num* tab) {
        double_num* x = &tab[0], * y = &tab[1], * z = &tab[2];
        double_num xy, sub1;
        double_num c2; MakeDoubleNum(&c2, "2.0");

        M_Mul(x, y, &xy);     // x * y
        M_Sub(&xy, z, &sub1); // x * y - z
        M_Add(&sub1, &c2, ret); // x * y - z + 2
    }

    // f3(x,y,z) = x*z - y*z = 0
    __declspec(dllexport) void f3(double_num* ret, double_num* tab) {
        double_num* x = &tab[0], * y = &tab[1], * z = &tab[2];
        double_num xz, yz;

        M_Mul(x, z, &xz); // x * z
        M_Mul(y, z, &yz); // y * z
        M_Sub(&xz, &yz, ret); // x * z - y * z
    }

    // dF1/dx = 4x
    __declspec(dllexport) void df1(double_num* ret, double_num* tab) {
        double_num c4; MakeDoubleNum(&c4, "4.0");
        M_Mul(&c4, &tab[0], ret);
    }

    // dF2/dy = x
    __declspec(dllexport) void df2(double_num* ret, double_num* tab) {
        // Bezpieczne przepisanie tab[0] za pomoc¹ LoadNum
        extended_double temp;
        M_Mid(&tab[0], &temp);
        M_LoadNum(&temp, ret);
    }

    // dF3/dz = x - y
    __declspec(dllexport) void df3(double_num* ret, double_num* tab) {
        M_Sub(&tab[0], &tab[1], ret);
    }
}