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

#define PREC_SINGLE 0
#define PREC_DOUBLE 2
#define PREC_EXTENDED 3

const extended_double pi = { 0x35, 0xC2, 0x68, 0x21, 0xA2, 0xDA, 0x0F, 0xC9, // Mantysa (E6 = 1110 0110)
    0x00, 0x40 };

extern "C" {
    // Ta nazwa musi by� identyczna z nazw� w pliku .asm
    void SetX87Rounding(unsigned __int64 mode);
	void SetX87Precision(unsigned __int64 precision);

	unsigned __int64 GetX87Rounding();

	void ED_FromDouble(double value, extended_double* result);
	double ED_ToDouble(extended_double* num);
	void ED_ToString(extended_double* num, char* buffer, int bufferSize);
	void ED_ToBinaryScientificString(extended_double* num, char* buffer, int bufferSize);

	void ED_Add(const extended_double* a, const extended_double* b, extended_double* result);
	void ED_Sub(const extended_double* a, const extended_double* b, extended_double* result);
	void ED_Mul(const extended_double* a, const extended_double* b, extended_double* result);
	void ED_Div(const extended_double* a, const extended_double* b, extended_double* result);
	void ED_Mod(const extended_double* a, const extended_double* b, extended_double* result);
	void ED_Div_Mod(const extended_double* a, const extended_double* b, extended_double* divResult, extended_double* modResult);

	void ED_Sqrt(const extended_double* a, extended_double* result);

	void ED_Abs(const extended_double* a, extended_double* result);

	void ED_Floor(const extended_double* a, extended_double* result);
	void ED_Ceil(const extended_double* a, extended_double* result);

	void ED_Log(const extended_double* a, extended_double* result);
	void ED_Log2(const extended_double* a, extended_double* result);
	void ED_Log10(const extended_double* a, extended_double* result);
	void ED_LogN(const extended_double* a, const extended_double* n, extended_double* result);

}