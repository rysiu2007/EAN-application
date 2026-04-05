#include "Interval.h"

using namespace interval_arithmetic;

extern "C" {
	void IAdd(const Interval<mpreal>* x, const Interval<mpreal>* y) {
		Interval<double> r;
		SetRounding<double>(FE_DOWNWARD);
		r.a = x.a + y.a;
		SetRounding<double>(FE_UPWARD);
		r.b = x.b + y.b;
		SetRounding<double>(FE_TONEAREST);
		return r;
	}
}