// EAN app.cpp: definiuje punkt wejścia dla aplikacji.
//


#include "EAN app.h"
//#include "Interval.h"
#include "extended_double.h"
#include "intervals.h"

using namespace std;

// --- IMPORT WARTOŚCI (80-bit Extended Precision) ---
const extended_double ED_ZERO = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
const extended_double ED_ONE = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xFF, 0x3F };
const extended_double ED_TWO = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x40 };
const extended_double ED_THREE = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xCC, 0xCC, 0x00, 0x40 };
const extended_double ED_FOUR = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x01, 0x40 };
const extended_double ED_FIVE = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAA, 0xAA, 0x01, 0x40 };
const extended_double ED_TEN = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xA0, 0x02, 0x40 };

// Wartości ujemne (bit 7 bajtu 9 ustawiony na 1)
const extended_double ED_NEG_1 = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xFF, 0xBF };
const extended_double ED_NEG_2 = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0xC0 };
const extended_double ED_NEG_3 = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC0, 0x00, 0xC0 };
const extended_double ED_NEG_4 = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x01, 0xC0 };
const extended_double ED_NEG_5 = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xA0, 0x01, 0xC0 };

const extended_double ED_TEN_POW_15 = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x8E, 0x30, 0x40 };
const extended_double ED_NEG_10 = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xA0, 0x02, 0xC0 };

void PrintBinary(const std::string& label, interval& res) {
    char bufL[128]{};
    char bufH[128]{};

    ED_ToString(&res.low, bufL, 40);
    ED_ToString(&res.high, bufH, 40);

    std::cout << "TEST: " << label << "\n";
    std::cout << "  Interval: [ " << bufL << " , " << bufH << " ]\n";

    printf("  HEX Low:  ");
    for (int i = 9; i >= 0; --i) printf("%02X", res.low.bytes[i]);
    printf("\n  HEX High: ");
    for (int i = 9; i >= 0; --i) printf("%02X", res.high.bytes[i]);

    std::cout << "\n" << std::string(60, '-') << std::endl;
}

//void PrintBinary(const std::string& label, const interval& res) {
//    auto dump = [](const extended_double& ed) {
//        for (int i = 9; i >= 0; --i) printf("%02X", ed.bytes[i]);
//        };
//
//    printf("TEST: %s\n", label.c_str());
//    printf("  LOW:  "); dump(res.low);  printf("\n");
//    printf("  HIGH: "); dump(res.high); printf("\n");
//    printf("------------------------------------------------------------\n");
//}

void RunAllTests() {
    interval A, B, R;

    printf("%-25s | %-20s : %-20s\n", "OPERACJA", "HEX LOW (10B)", "HEX HIGH (10B)");
    printf("--------------------------------------------------------------------------------------\n");

    // --- DODAWANIE ---
    printf("[ DODAWANIE ]\n");
    // 1. [1, 1] + [1, 1]
    A.low = ED_ONE; A.high = ED_ONE;
    B.low = ED_ONE; B.high = ED_ONE;
    Int_Add(&A, &B, &R); PrintBinary("1 + 1", R);

    // 2. [-5, -4] + [-2, -1]
    A.low = ED_NEG_5; A.high = ED_NEG_4;
    B.low = ED_NEG_2; B.high = ED_NEG_1;
    Int_Add(&A, &B, &R); PrintBinary("[-5,-4] + [-2,-1]", R);

    // 3. [-1, 1] + [1, 2]
    A.low = ED_NEG_1; A.high = ED_ONE;
    B.low = ED_ONE; B.high = ED_TWO;
    Int_Add(&A, &B, &R); PrintBinary("[-1,1] + [1,2]", R);

    // 4. [10, 10] + [0, 0]
    A.low = ED_TEN; A.high = ED_TEN;
    B.low = ED_ZERO; B.high = ED_ZERO;
    Int_Add(&A, &B, &R); PrintBinary("10 + 0", R);

    // 5. [4, 5] + [-5, -4]
    A.low = ED_FOUR; A.high = ED_FIVE;
    B.low = ED_NEG_5; B.high = ED_NEG_4;
    Int_Add(&A, &B, &R); PrintBinary("[4,5] + [-5,-4]", R);

    printf("\n[ ODEJMOWANIE ]\n");
    // 1. [5, 10] - [5, 10] -> [-5, 5]
    A.low = ED_FIVE; A.high = ED_TEN;
    B.low = ED_FIVE; B.high = ED_TEN;
    Int_Sub(&A, &B, &R); PrintBinary("[5,10] - [5,10]", R);

    // 2. [0, 1] - 10
    A.low = ED_ZERO; A.high = ED_ONE;
    B.low = ED_TEN; B.high = ED_TEN;
    Int_Sub(&A, &B, &R); PrintBinary("[0,1] - 10", R);

    // 3. [-5, -4] - [-2, -1]
    A.low = ED_NEG_5; A.high = ED_NEG_4;
    B.low = ED_NEG_2; B.high = ED_NEG_1;
    Int_Sub(&A, &B, &R); PrintBinary("[-5,-4] - [-2,-1]", R);

    // 4. [1, 1] - [1, 1]
    A.low = ED_ONE; A.high = ED_ONE;
    B.low = ED_ONE; B.high = ED_ONE;
    Int_Sub(&A, &B, &R); PrintBinary("1 - 1", R);

    // 5. [10, 10] - [1, 2]
    A.low = ED_TEN; A.high = ED_TEN;
    B.low = ED_ONE; B.high = ED_TWO;
    Int_Sub(&A, &B, &R); PrintBinary("10 - [1,2]", R);

    printf("\n[ MNOZENIE ]\n");
    // 1. [-3, -2] * [-5, -4]
    A.low = ED_NEG_3; A.high = ED_NEG_2;
    B.low = ED_NEG_5; B.high = ED_NEG_4;
    Int_Mul(&A, &B, &R); PrintBinary("[-3,-2] * [-5,-4]", R);

    // 2. [-2, 3] * [-4, 5]
    A.low = ED_NEG_2; A.high = ED_THREE;
    B.low = ED_NEG_4; B.high = ED_FIVE;
    Int_Mul(&A, &B, &R); PrintBinary("[-2,3] * [-4,5]", R);

    // 3. [-1, 1] * [-1, 1]
    A.low = ED_NEG_1; A.high = ED_ONE;
    B.low = ED_NEG_1; B.high = ED_ONE;
    Int_Mul(&A, &B, &R); PrintBinary("[-1,1] * [-1,1]", R);

    // 4. 2 * 0.5 (Poprawiona inicjalizacja stałej inline)
    A.low = ED_TWO; A.high = ED_TWO;
    extended_double ed_half;
    unsigned char half_bytes[10] = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xFE, 0x3F };
    for (int i = 0; i < 10; i++) ed_half.bytes[i] = half_bytes[i];
    B.low = ed_half; B.high = ed_half;
    Int_Mul(&A, &B, &R); PrintBinary("2 * 0.5", R);

    // 5. 10 * 0
    A.low = ED_TEN; A.high = ED_TEN;
    B.low = ED_ZERO; B.high = ED_ZERO;
    Int_Mul(&A, &B, &R); PrintBinary("10 * 0", R);

    printf("\n[ DZIELENIE ]\n");
    // 1. 1 / 3
    A.low = ED_ONE; A.high = ED_ONE;
    B.low = ED_THREE; B.high = ED_THREE;
    Int_Div(&A, &B, &R); PrintBinary("1 / 3", R);

    // 2. 6 / [-3, -2]
    extended_double ed_six;
    unsigned char six_bytes[10] = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC0, 0x01, 0x40 };
    for (int i = 0; i < 10; i++) ed_six.bytes[i] = six_bytes[i];
    A.low = ed_six; A.high = ed_six;
    B.low = ED_NEG_3; B.high = ED_NEG_2;
    Int_Div(&A, &B, &R); PrintBinary("6 / [-3,-2]", R);

    // 3. -6 / [-3, -2]
    A.low = ed_six; A.low.bytes[9] |= 0x80;
    A.high = A.low;
    B.low = ED_NEG_3; B.high = ED_NEG_2;
    Int_Div(&A, &B, &R); PrintBinary("-6 / [-3,-2]", R);

    // 4. 1 / [0.5, 2.0]
    A.low = ED_ONE; A.high = ED_ONE;
    B.low = ed_half; B.high = ED_TWO;
    Int_Div(&A, &B, &R); PrintBinary("1 / [0.5,2]", R);

    // 5. 1 / 10
    A.low = ED_ONE; A.high = ED_ONE;
    B.low = ED_TEN; B.high = ED_TEN;
    Int_Div(&A, &B, &R); PrintBinary("1 / 10", R);
}
//using namespace interval_arithmetic;

int main() {

	SetX87Precision(PREC_EXTENDED);
    RunAllTests();
   // RunComprehensiveTests();
  //  BitLevelTest_WithToString();

  // VerifyIntervalPrecision();
  //  std::cout<<std::fixed<<std::setprecision(20);
    SetX87Rounding(RD_DOWNWARD);
	cout << GetX87Rounding() << endl;
    SetX87Rounding(RD_UPWARD);
    char buffer[64]{};
    cout << GetX87Rounding() << endl;
	extended_double ed1, ed2, ed_result, ed_result2;
    unsigned char raw_data[] = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC0, // Mantysa (E6 = 1110 0110)
0x01, 0xC0 };
    std::memcpy(ed1.bytes, raw_data, 10);
    unsigned char raw_data3[] = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC0, // Mantysa (E6 = 1110 0110)
0x00, 0x40 };
    std::memcpy(ed2.bytes, raw_data3, 10);
	//ed1 = pi;
  // ED_PrevMachine(&ed1, &ed1);
   // ED_PrevMachine(&ed1, &ed1);
   // ED_PrevMachine(&ed1, &ed1);
    //ED_FromDouble(5.0, &ed1);
    ED_Pow_Int(&ed1, &ed2, &ed1);
    ED_ToString(&ed1, buffer, 22);
    cout << buffer << endl;
    ed2 = pi;
    //unsigned char raw_data2[] = { 0x67, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0xE6, // Mantysa (E6 = 1110 0110)
  //  0xFE, 0x3F };
	//std::memcpy(ed2.bytes, raw_data2, 10);
    //ED_FromDouble(2.0, &ed2);


    SetX87Rounding(RD_UPWARD);
    ED_Tan(&ed1, &ed1);
	//ED_Mul(&ed2, &ed1, &ed2);
	ED_Pow(&ed2,&ed1,&ed2);
	ED_Mul(&ed2, &pi, &ed2);
    ED_Mul(&ed2, &pi, &ed2);
    ED_Mul(&ed2, &pi, &ed2);
    ED_ToString(&ed2, buffer, 40);
    cout << buffer << endl;
 //   std::memcpy(ed1.bytes, ed2.bytes, 10);

	ED_PrevMachine(&ed2, &ed2);

    ED_ToString(&ed2, buffer, 40);
    cout << buffer << endl;
	//ED_FromDouble(0.3, &ed1);
//	ED_FromDouble(1.5, &ed2);

	ED_Div_Mod(&ed1, &ed2, &ed_result,&ed_result2);
//	cout<<ED_ToDouble(&ed_result)<<endl;
	ED_ToString(&ed_result, buffer, 25);
	cout <<"1: " << buffer << endl;

    ED_ToString(&ed_result2, buffer, 22);
    cout << "2: " << buffer << endl;

    SetX87Rounding(RD_UPWARD);
    ED_Div_Mod(&ed1, &ed2, &ed_result, &ed_result2);
   //ED_Ceil(&ed_result, &ed_result);
    //	cout<<ED_ToDouble(&ed_result)<<endl;
    ED_ToString(&ed_result, buffer, 22);
    cout << "3: " << buffer << endl;

    ED_ToString(&ed_result2, buffer, 22);
    cout << "4: " << buffer << endl;
    // try {
    //     // 1. Inicjalizacja (ważne dla MPFR!)
    //     Interval<double>::Initialize();

    //     // 2. Tworzenie przedziału
    //     Interval<double> x(1.0, 2.0);
    //     Interval<double> y(3.0, 4.0);

    //     // 3. Operacja (wykorzystuje Twoje przeciążone operatory)
    //     Interval<double> z = x + y;

    //     std::cout << "Wynik: [" << z.a << ", " << z.b << "]" << std::endl;
    // }
    // catch (const std::exception& e) {
    //     std::cerr << "Blad: " << e.what() << std::endl;
    // }
    return 0;
}
