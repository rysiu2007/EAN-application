#ifndef simp_newton
#define simp_newton

#include "math_core.h"

extern "C" {
	void SimplifiedNewton(__int64 n, double_num* tab, void (*func[])(double_num* ret, double_num* tab), void (*dfunc[])(double_num* ret, double_num* tab), const double_num* omega, const __int64 mit, const extended_double* eps);
}










#endif