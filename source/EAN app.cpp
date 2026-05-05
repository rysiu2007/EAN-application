// EAN app.cpp: definiuje punkt wejścia dla aplikacji.
//


#include "EAN app.h"
//#include "Interval.h"
#include "extended_double.h"
#include "intervals.h"
#include "api.h"

using namespace std;

// --- IMPORT WARTOŚCI (80-bit Extended Precision) ---
const extended_double ED_ZERO = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
const extended_double ED_ONE = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xFF, 0x3F };
const extended_double ED_TWO = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x40 };
const extended_double ED_THREE = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC0, 0x00, 0x40 };
const extended_double ED_FOUR = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x01, 0x40 };
const extended_double ED_FIVE = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xA0, 0x01, 0x40 };
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

    ED_ToStringBCD(&res.low, bufL, 25);
    ED_ToStringBCD(&res.high, bufH, 25);

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
    Int_Log2(&A, &R); PrintBinary("log(6) / [-3,-2]", R);

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

void Test_IntervalLogN_Extensive() {
    std::cout << "=== ROZSZERZONE TESTY Int_LogN ===\n" << std::endl;

    extended_double ed_1, ed_2, ed_10, ed_tiny, ed_large, ed_01, ed_09;
    ED_FromDouble(1.0, &ed_1);
    ED_FromDouble(2.0, &ed_2);
    ED_FromDouble(10.0, &ed_10);
    ED_FromDouble(0.1, &ed_01);
    ED_FromDouble(0.9, &ed_09);
    ED_FromDouble(1e-10, &ed_tiny);
    ED_FromDouble(1e10, &ed_large);

    interval result;
    char bufL[128]{}, bufH[128]{};

    // --- CASE 5: Obie wartości < 1 (Logarytm ułamka o ułamkowej podstawie) ---
    // log_0.1(0.1) = 1.0. Sprawdza stabilność w obszarze ułamkowym.
    interval i_val5 = { ed_01, ed_01 };
    interval i_base10 = { ed_10, ed_10 };
    interval i_base5 = { ed_01, ed_01 };
    Int_LogN(&i_val5, &i_base5, &result);
    Int_Exp10(&i_base10, & result);
    ED_ToStringBCD(&result.low, bufL, 40); ED_ToStringBCD(&result.high, bufH, 40);
    std::cout << "TEST 5: log_0.1(0.1) [Oczekiwane: 1.0]\n  [ " << bufL << " , " << bufH << " ]\n";

    // --- CASE 6: Bardzo mała podstawa i duży argument ---
    // log_tiny(large) -> wynik powinien być bardzo mały, ujemny.
    interval i_val6 = { ed_large, ed_large };
    interval i_base6 = { ed_tiny, ed_tiny };
    Int_LogN(&i_val6, &i_base6, &result);
    ED_ToStringBCD(&result.low, bufL, 40); ED_ToStringBCD(&result.high, bufH, 40);
    std::cout << "\nTEST 6: log_1e-10(1e10) [Oczekiwane: -1.0]\n  [ " << bufL << " , " << bufH << " ]\n";

    // --- CASE 7: Argument bliski 1.0 (Test precyzji logarytmu) ---
    // log_10(0.9) -> wynik ujemny, bliski zeru.
    interval i_val7 = { ed_09, ed_09 };
    interval i_base7 = { ed_10, ed_10 };
    Int_LogN(&i_val7, &i_base7, &result);
    ED_ToStringBCD(&result.low, bufL, 40); ED_ToStringBCD(&result.high, bufH, 40);
    std::cout << "\nTEST 7: log_10(0.9)\n  [ " << bufL << " , " << bufH << " ]\n";

    // --- CASE 8: Przedziały "stykające się" z jedynką (Test bezpieczeństwa) ---
    // x = [2, 2], n = [1.0000000000000000001, 1.1]
    // Logarytm o podstawie bardzo bliskiej 1 dąży do nieskończoności.
    extended_double ed_near1;
    ED_NextMachine(&ed_1, &ed_near1); // Pobiera następną reprezentowalną liczbę po 1.0
    interval i_base8 = { ed_near1, ed_2 };
    interval i_val8 = { ed_10, ed_10 };
    Int_LogN(&i_val8, &i_base8, &result);
    ED_ToStringBCD(&result.low, bufL, 40); ED_ToStringBCD(&result.high, bufH, 40);
    std::cout << "\nTEST 8: log_[1.0+eps, 2](10.0) - Test stabilności blisko bieguna\n";
    std::cout << "  [ " << bufL << " ,\n    " << bufH << " ]\n";

    ClearX87Errors();
    std::cout << "\n=== KONIEC ROZSZERZONYCH TESTÓW ===\n";
}
void Test_IntervalMul_Logic() {
    std::cout << "=== TEST LOGIKI MNOŻENIA PRZEDZIAŁOWEGO ===\n";

    extended_double a_low, a_high, b_low, b_high;
    ED_FromDouble(-2.0, &a_low);
    ED_FromDouble(3.0, &a_high);
    ED_FromDouble(-4.0, &b_low);
    ED_FromDouble(5.0, &b_high);

    interval A = { a_low, a_high };
    interval B = { b_low, b_high };
    interval result;

    char bufL[128]{}, bufH[128]{};

    // Wywołanie Twojego mnożenia w ASM
    Int_Mul(&A, &B, &result);

    ED_ToStringBCD(&result.low, bufL, 120);
    ED_ToStringBCD(&result.high, bufH, 120);

    std::cout << "A: [-2, 3], B: [-4, 5]\n";
    std::cout << "Wynik oczekiwany: [-12.0, 15.0]\n";
    std::cout << "Wynik Twojego ASM: [ " << bufL << " , " << bufH << " ]\n";

    // Sprawdzenie błędnego odwrócenia (jeśli Low > High)
    // Pamiętaj: -12 jest MNIEJSZE niż 15.
    std::cout << "-------------------------------------------\n";
}

void Test_IntervalLogN_FullRange() {
    std::cout << "=== TEST LOGIKI: LOGARYTM Z DWOMA PRZEDZIAúAMI ===\n";

    extended_double val_8, val_64, base_2, base_4;
    ED_FromDouble(8.0, &val_8);
    ED_FromDouble(64.0, &val_64);
    ED_FromDouble(2.0, &base_2);
    ED_FromDouble(4.0, &base_4);

    interval X = { val_8, val_64 };   // [8, 64]
    interval N = { base_2, base_4 };  // [2, 4]
    interval result;

    char bufL[128]{}, bufH[128]{};

    // Wywołanie Twojego logarytmu w ASM
    Int_LogN(&X, &N, &result);

    ED_ToStringBCD(&result.low, bufL, 120);
    ED_ToStringBCD(&result.high, bufH, 120);

    std::cout << "x: [8, 64], base: [2, 4]\n";
    std::cout << "Wynik oczekiwany: [ 1.5 , 6.0 ]\n";
    std::cout << "Wynik Twojego ASM: [ " << bufL << " ,\n                    " << bufH << " ]\n";
    std::cout << "--------------------------------------------------\n";
}

void Test_IntervalLogN_NegativeRange() {
    std::cout << "=== TEST KRYTYCZNY: LOGARYTM UJEMNY (PODSTAWA < 1) ===\n";

    extended_double val_8, val_64, base_025, base_05;

    // x = [8, 64]
    ED_FromDouble(9.999999999999999, &val_8);
    ED_FromDouble(10.000000000000001, &val_64);

    // n = [0.25, 0.5]
    ED_FromDouble(10, &base_025);
    ED_FromDouble(10.0, &base_05);

    interval X = { val_8, val_64 };
    Int_PI(&X);

    interval N = { base_025, base_05 };
    Int_E(&N);
    interval result;

    char bufL[128]{}, bufH[128]{};

    // Wywołanie Twojego logarytmu w ASM
    // Spodziewane kombinacje: 
    // log_0.5(8) = -3, log_0.5(64) = -6, log_0.25(8) = -1.5, log_0.25(64) = -3
    Int_Pow(&N, &X, &result);

    PrintBinary("kss", result);
    Int_GetRight(&result, &base_05);
    ED_ToStringBCD(&base_05, bufH, 120);
   // ED_ToStringBCD(&result.low, bufL, 40);
    //ED_ToStringBCD(&result.high, bufH, 40);

    std::cout << "x: [8, 64], base: [0.25, 0.5]\n";
    std::cout << "Wynik oczekiwany: [ -6.0 , -1.5 ]\n";
    std::cout << "Wynik Twojego ASM: [ " << bufL << " ,\n                    " << bufH << " ]\n";

    // Prosta weryfikacja logiczna w C++
    double low_d = ED_ToDouble(&result.low);
    double high_d = ED_ToDouble(&result.high);

    if (low_d > high_d) {
        std::cout << "\n!!! BŁĄD KRYTYCZNY: Dolna granica jest WIĘKSZA niż górna! !!!\n";
        std::cout << "Twoja logika fcmov/fxch nie radzi sobie z liczbami ujemnymi.\n";
    }
    else {
        std::cout << "\nPorządek przedziału poprawny (Low <= High).\n";
    }
    std::cout << "--------------------------------------------------\n";
}

void print_tbyte_hex(const extended_double* ed) {
    const unsigned char* p = ed->bytes;
    // TBYTE ma 10 bajtów. Drukujemy od końca (Little Endian), aby widzieć znak i wykładnik na początku.
    std::cout << "0x";
    for (int i = 9; i >= 0; --i) {
        std::cout << std::hex << std::setw(2) << std::setfill('0') << (int)p[i];
    }
    std::cout << std::dec; // Powrót do systemu dziesiętnego
}

// Poprawny HEX: 0x4020 9502F90000000000 (Zauważ: tu akurat 10^10 dzieli się przez 2^n, 
// ale precyzja TBYTE pozwala uniknąć błędów zaokrągleń pośrednich)
// 10^10 dokładnie (10 000 000 000.0)
const extended_double ED_10P10 = { 0x00, 0x00, 0x00, 0x00, 0x00, 0xF9, 0x02, 0x95, 0x20, 0x40 };

// 10^-10 (0.0000000001) - TO JEST KLUCZ DO TESTU 6!
// Ta stała NIE MOŻE mieć zer na końcu, jeśli ma być dokładna.
// 10^-10 dokładnie w 80-bitach:
// Mantysa: 0xDB22D0E560418937 (z jawnym bitem 0x80...)
// Wykładnik: 0x3FDD (16349 - 16383 = -34)
// 10^-10 (0.0000000001) - Skorygowana precyzja dla x87
extended_double ED_10M10 = { 0xC7, 0xD5, 0xED, 0xBD, 0xCE, 0xFE, 0xE6, 0xDB, 0xDD, 0x3F };

void Test_LogN_Hex_Analysis() {
    std::cout << "=== ANALIZA BINARNA (HEX) - TEST 6 ===\n";

    extended_double val_large, base_tiny;
    // x = 1e10, base = 1e-10
  // // ED_FromDouble(1e10, &val_large);
    ED_FromDouble(1e-10, &base_tiny);

    interval X = { ED_10P10,  { 0x01, 0x00, 0x00, 0x00, 0x00, 0xF9, 0x02, 0x95, 0x20, 0x40 } };
    interval N = { ED_10M10,  ED_10M10 };
    interval result;

    char bufL[128]{}, bufH[128]{};

    // Wywołanie Twojego ASM
    Int_LogN(&X, &N, &result);

    ED_ToStringBCD(&result.low, bufL, 120);
    ED_ToStringBCD(&result.high, bufH, 120);

    std::cout << "Wynik BCD Low:  " << bufL << "\n";
    std::cout << "Wynik HEX Low:  "; print_tbyte_hex(&ED_10M10);
    std::cout << "\n\n";

    std::cout << "Wynik BCD High: " << bufH << "\n";
    std::cout << "Wynik HEX High: "; print_tbyte_hex(&result.high);
    std::cout << "\n";

    // Weryfikacja bitowa
    bool identical = true;
    for (int i = 0; i < 10; ++i) if (result.low.bytes[i] != result.high.bytes[i]) identical = false;

    if (identical) {
        std::cout << "\nUWAGA: Granice są identyczne bitowo.\n";
    }
    else {
        std::cout << "\nSukces: Granice różnią się na poziomie binarnym.\n";
    }
    std::cout << "-------------------------------------------\n";
}
//using namespace interval_arithmetic;

extern "C" {
    void start();
}
int main() {
    start();
	SetX87Precision(PREC_EXTENDED);
   // Test_IntervalMul_Logic();
  //  Test_LogN_Hex_Analysis();
//
    Test_IntervalLogN_NegativeRange();
    //RunAllTests();
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
    ED_PowInt(&ed1, &ed2, &ed1);
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
