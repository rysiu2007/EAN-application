#ifndef simp_newton
#define simp_newton

#include "math_core.h"

extern "C" {
	void SimplifiedNewton(int n, double_num* tab, const double_num* (*func)(double_num* ret, ...), const double_num* (*dfunc)(double_num *ret, ...), const extended_double* omega, const int mit, const extended_double* eps);
}










#endif