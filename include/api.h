#pragma once
#include "extended_double.h"
#include "intervals.h"

#pragma pack(push, 1)
union double_num {
	extended_double num;
	interval inter;
};
#pragma pack(pop)

enum mode
{
	float80, interval_float_data, pure_interval
};

static mode software_mode = float80;

// Mathematical constants
void Get_PI(double_num* r);
void Get_E(double_num* r);

void LoadNum(const extended_double* num, double_num* r);

// Basic arithmetic operations for double_nums.

void Add(const double_num* a, const double_num* b, double_num* r);
void Sub(const double_num* a, const double_num* b, double_num* r);
void Mul(const double_num* a, const double_num* b, double_num* r);
void Div(const double_num* a, const double_num* b, double_num* r);

// Some logarithmic operation on double_nums

void Log(const double_num* a, double_num* r);
void Log2(const double_num* a, double_num* r);
void Log10(const double_num* a, double_num* r);
void LogN(const double_num* a, const double_num* n, double_num* r);

// Some exponential functions

void Exp2(const double_num* a, double_num* r);
void Exp(const double_num* a, double_num* r);
void Exp10(const double_num* a, double_num* r);

// It raises b to the e-th power. b must be above 0. Assumes the nonperfect nature of computer representation and assumes the e is not an integer.
void Pow(const double_num* b, const double_num* e, double_num* r);

// It raises b to the e-th power, truncates the exponent, so it is an integer, be vary that it throws the precision of the exponent out of the window, albeit not the precision of the operation itself.
void PowInt(const double_num* b, const extended_double* e, double_num* r);

// Some trigonometric functions

void Sin(const double_num* a, double_num* r);
void Cos(const double_num* a, double_num* r);