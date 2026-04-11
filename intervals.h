#pragma once
#include "extended_double.h"
#pragma pack(push, 1)
struct interval {
	extended_double low;
	extended_double high;
};  
#pragma pack(pop)

extern "C" {
	typedef void (*ED_Func3)(const extended_double*, const extended_double*, const extended_double*, extended_double*);
	void Int_op3(const interval* a, const interval* b, const interval* c, interval* r, ED_Func3 func);

	typedef void (*ED_Func2)(const extended_double*, const extended_double*, extended_double*);
	void Int_op2(const interval* a, const interval* b, interval* r, ED_Func2 func);

	typedef void (*ED_Func)(const extended_double*, extended_double*);
	void Int_op(const interval* a, interval* r, ED_Func func);
}