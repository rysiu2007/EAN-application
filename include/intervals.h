#pragma once
#include "extended_double.h"
#pragma pack(push, 1)
struct interval {
	extended_double low;
	extended_double high;
};  
#pragma pack(pop)

extern "C" {

	// Note: These functions are simple wrappers, which should be used with caution or best not at all. They are designed to simplify the implementation of further functions.
	// They automatically calculate the low and high bounds of the resulting interval based on the provided extended_double function and the input intervals.
	// However, they do not perform any error checking or special handling for edge cases (such as NaN, infinity, or zero-width intervals), so they should be used in a controlled manner where the inputs are known to be valid and well-formed. 
	// Additionally, these functions assume that the provided extended_double function correctly handles rounding and precision according to the x87 FPU settings, so any misuse of those settings could lead to incorrect results.

	typedef void (*ED_Func3)(const extended_double*, const extended_double*, const extended_double*, extended_double*);
	// Placeholder function for performing a three-argument operation on intervals using the provided extended_double function. The func parameter is a pointer to a function that takes three extended_double pointers as input and produces an extended_double result. The Int_op3 function will apply this operation to the low and high bounds of the input intervals a, b, and c, and store the resulting interval in r. This allows for flexible composition of interval operations based on any compatible extended_double function.
	void Int_op3(const interval* a, const interval* b, const interval* c, interval* r, ED_Func3 func);

	typedef void (*ED_Func2)(const extended_double*, const extended_double*, extended_double*);
	// Placeholder function for performing a two-argument operation on intervals using the provided extended_double function. The func parameter is a pointer to a function that takes two extended_double pointers as input and produces an extended_double result. The Int_op2 function will apply this operation to the low and high bounds of the input intervals a and b, and store the resulting interval in r. This allows for flexible composition of interval operations based on any compatible extended_double function.
	void Int_op2(const interval* a, const interval* b, interval* r, ED_Func2 func);

	typedef void (*ED_Func)(const extended_double*, extended_double*);
	// Placeholder function for performing a single-argument operation on intervals using the provided extended_double function. The func parameter is a pointer to a function that takes one extended_double pointer as input and produces an extended_double result. The Int_op1 function will apply this operation to the low and high bounds of the input interval a, and store the resulting interval in r. This allows for flexible composition of interval operations based on any compatible extended_double function.
	void Int_op1(const interval* a, interval* r, ED_Func func);

	// Basic arithmetic operations for intervals.

	void Int_Add(const interval* a, const interval* b, interval* r);
	void Int_Sub(const interval* a, const interval* b, interval* r);
	void Int_Mul(const interval* a, const interval* b, interval* r);
	void Int_Div(const interval* a, const interval* b, interval* r);

}