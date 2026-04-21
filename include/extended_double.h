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

#define ERR_SUCCESS 0
#define ERR_INVALID_OP 1
#define ERR_ZERO_DIVIDE 2
#define ERR_DENORMAL 4
#define ERR_OVERFLOW 8
#define ERR_UNDERFLOW 16
#define ERR_PRECISION 32


const extended_double pi = { 0x35, 0xC2, 0x68, 0x21, 0xA2, 0xDA, 0x0F, 0xC9, // Mantysa (E6 = 1110 0110)
    0x00, 0x40 };

extern "C" {
	// Sets the x87 FPU rounding mode. The mode parameter should be one of the RD_* constants defined above. Note that this function directly modifies the x87 FPU control word, so it will affect all subsequent floating-point operations performed using the x87 FPU until the rounding mode is changed again. Use with caution, especially in multi-threaded applications, as it may lead to unexpected behavior if other parts of the program rely on a specific rounding mode.
    void SetX87Rounding(unsigned __int64 mode);
	// Sets the x87 FPU precision mode. The precision parameter should be one of the PREC_* constants defined above.
	void SetX87Precision(unsigned __int64 precision);

	// Retrieves the current x87 FPU rounding mode. The return value will be one of the RD_* constants defined above.
	unsigned __int64 GetX87Rounding();

	// Retrieves the current x87 FPU precision mode. The return value will be one of the PREC_* constants defined above.
	unsigned __int64 GetX87Precision();

	// Retrieves the current x87 FPU error flags. The return value will be a combination of the ERR_* constants defined above.
	unsigned __int64 GetX87Errors();

	// Clears the x87 FPU error flags.
	void ClearX87Errors();

	// Sets the extended_double pointed to by result to the value represented by the double value.
	void ED_FromDouble(double value, extended_double* result);
	// Exports the value of the extended_double pointed to by num as a double. Note that this may involve rounding and loss of precision.
	double ED_ToDouble(extended_double* num);
	// NOTE: USE TOSTRINGBCD for better accuracy. Parses the num into a string in buffer, with a size limited by bufferSize. Note that this implementation is limited and may not handle all edge cases correctly, such as very large or very small numbers, or special values like infinity or NaN.
	void ED_ToString(extended_double* num, char* buffer, int bufferSize);

	// Proper method for parsing num into string, this implementation is limited to 18 digits integer part and 36 digits after the decimal point. 
	void ED_ToStringBCD(extended_double* num, char* buffer, int bufferSize);
	// Returns the next machine number after num
	void ED_NextMachine(extended_double* num, extended_double* result);
	// Returns the previous machine number before num
	void ED_PrevMachine(extended_double* num, extended_double* result);
//	void ED_ToBinaryScientificString(extended_double* num, char* buffer, int bufferSize);

	// Basic arithmetic operations

	void ED_Add(const extended_double* a, const extended_double* b, extended_double* result);
	void ED_Sub(const extended_double* a, const extended_double* b, extended_double* result);
	void ED_Mul(const extended_double* a, const extended_double* b, extended_double* result);
	void ED_Div(const extended_double* a, const extended_double* b, extended_double* result);
	void ED_Mod(const extended_double* a, const extended_double* b, extended_double* result);

	// Performs both division and modulus operations simultaneously, storing the quotient in divResult and the remainder in modResult. This can be more efficient than performing the two operations separately, as it may allow for shared calculations.
	void ED_Div_Mod(const extended_double* a, const extended_double* b, extended_double* divResult, extended_double* modResult);

	// Unary operations

	void ED_Sqrt(const extended_double* a, extended_double* result);
	void ED_Abs(const extended_double* a, extended_double* result);

	void ED_Floor(const extended_double* a, extended_double* result);
	void ED_Ceil(const extended_double* a, extended_double* result);

	// Logarithmic and exponential functions, note that there is no error handling for invalid inputs (like negative numbers for logarithms), so the behavior in those cases is undefined and may cause crashes or incorrect results. Use with caution.
	// Should one use GetX87Errors() after calling these functions to check for errors like ERR_INVALID_OP or ERR_ZERO_DIVIDE

	void ED_Log(const extended_double* a, extended_double* result);
	void ED_Log2(const extended_double* a, extended_double* result);
	void ED_Log10(const extended_double* a, extended_double* result);
	void ED_LogN(const extended_double* a, const extended_double* n, extended_double* result);

	void ED_Exp2(const extended_double* a, extended_double* result);
	void ED_Exp(const extended_double* a, extended_double* result);
	void ED_Exp10(const extended_double* a, extended_double* result);

	// Power function. Works only with positive bases
	void ED_Pow(const extended_double* base, const extended_double* exponent, extended_double* result);

	// Exponentiation for the whole numbers, working in Z 
	void ED_Pow_Int(const extended_double* base, const extended_double* exponent, extended_double* result);

	// Trigonometric functions, note that there is no error handling for invalid inputs (like NaN or infinity), so the behavior in those cases is undefined and may cause crashes or incorrect results. Use with caution.

	void ED_Sin(const extended_double* a, extended_double* result);
	void ED_Cos(const extended_double* a, extended_double* result);
	void ED_Tan(const extended_double* a, extended_double* result);
	void ED_SinCos(const extended_double* a, extended_double* s, extended_double* c);
	//void ED_Atan(const extended_double* a, extended_double* result);
}