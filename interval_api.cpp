#include "Interval.h"

using namespace interval_arithmetic;

extern "C" {
	void IAdd(const Interval<long double>* x, const Interval<long double>* y) {
		Interval<double> r;
		SetRounding<double>(FE_DOWNWARD);
		r.a = x.a + y.a;
		SetRounding<double>(FE_UPWARD);
		r.b = x.b + y.b;
		SetRounding<double>(FE_TONEAREST);
		return r;
	}
}