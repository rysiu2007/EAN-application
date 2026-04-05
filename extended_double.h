#pragma once
#pragma pack(push, 1)
struct extended_double {
	unsigned char bytes[10];
};
#pragma pack(pop)

#define RD_TONEAREST 0
#define RD_DOWNWARD 1
#define RD_UPWARD 2
#define RD_TOWARDZERO 3

extern "C" {
    // Ta nazwa musi byæ identyczna z nazw¹ w pliku .asm
    void SetX87Rounding(unsigned __int64 mode);

	unsigned __int64 GetX87Rounding();

	void ED_FromDouble(double value, extended_double* result);
	double ED_ToDouble(extended_double* num);
	void ED_ToString(extended_double* num, char* buffer, int bufferSize);

	void ED_Add(const extended_double* a, const extended_double* b, extended_double* result);
}