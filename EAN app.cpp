// EAN app.cpp: definiuje punkt wejścia dla aplikacji.
//


#include "EAN app.h"
//#include "Interval.h"
#include "extended_double.h"
#include "intervals.h"

using namespace std;

void Benchmark_Interval_SineSquared() {
    const int iterations = 1000000; // 1 milion operacji
    interval x, temp, res;

    // Ustawiamy x = [pi/7, pi/7] (bardzo wąski przedział)
    extended_double val_pi_7;
    extended_double seven;
    double d_seven = 7.0;
    ED_FromDouble(d_seven, &seven);

    // pi / 7
    SetX87Rounding(RD_TONEAREST);
    ED_Div(&pi, &seven, &val_pi_7);

    x.low = val_pi_7;
    x.high = val_pi_7;

    std::cout << "Rozpoczynam benchmark: sin(x^2) dla " << iterations << " iteracji..." << std::endl;

    auto start = std::chrono::high_resolution_clock::now();

    for (int i = 0; i < iterations; ++i) {
        // Obliczamy x^2 (używając Int_op2 i ED_Mul)
        Int_op2(&x, &x, &temp, ED_Mul);

        // Obliczamy sin(temp) (używając Int_op i ED_Sin)
        Int_op1(&temp, &res, ED_Sin);
    }

    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed = end - start;

    // Wyświetlanie wyników
    char bufL[64]{}, bufH[64]{};
    ED_ToString(&res.low, bufL, 32);
    ED_ToString(&res.high, bufH, 32);

    std::cout << std::fixed << std::setprecision(4);
    std::cout << "------------------------------------------" << std::endl;
    std::cout << "Czas wykonania: " << elapsed.count() << " s" << std::endl;
    std::cout << "Szybkosc:       " << (iterations / elapsed.count()) / 1000.0 << " kops/s" << std::endl;
    std::cout << "------------------------------------------" << std::endl;
    std::cout << "Wynik ostatniej iteracji:" << std::endl;
    std::cout << "LOW:  " << bufL << std::endl;
    std::cout << "HIGH: " << bufH << std::endl;

    // Prosta weryfikacja szerokości
    // (Możesz tu dodać funkcję obliczającą różnicę, jeśli masz ED_Sub)
}


void Benchmark_Sinus_Interval() {
    extended_double pi2=pi,pi_high, x, sin_low, sin_high, temp, two;

	ED_NextMachine(&pi2, &pi_high); // Pi z góry (defensywnie)
    char buf[100]{};
    const int precision = 22;

    // Stała PI (lepiej użyć fldpi w ASM, jeśli masz taką metodę)
  //  ED_FromDouble(3.14159265358979323846, &pi);

    // x = pi / 6
    extended_double six;
    unsigned char raw_data[] = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xE0, // Mantysa (E6 = 1110 0110)
0x01, 0x40 };
    unsigned char raw_data2[] = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, // Mantysa (E6 = 1110 0110)
0x00, 0x40 };
    std::memcpy(six.bytes, raw_data, 10);
    std::memcpy(two.bytes, raw_data2, 10);

    extended_double six_low;
	extended_double six_high;

	ED_PrevMachine(&six, &six_low);



    cout << "--- BENCHMARK: SINUS PRZEDZIALOWY (x = pi/6) ---" << endl;
    ED_ToString(&x, buf, precision);
    cout << "Argument x: " << buf << endl << endl;

    // 1. Obliczenie dolnej granicy
    SetX87Rounding(RD_DOWNWARD); // upewnij się, że RD_DOWNWARD odpowiada 0x0400 w Control Word
    ED_Div(&pi2, &six_low, &x);
    ED_Sin(&x, &sin_low);

    // 2. Obliczenie górnej granicy + Twoja poprawka bezpieczeństwa (+1 ULP)
    SetX87Rounding(RD_UPWARD);   // RD_UPWARD odpowiada 0x0800
    ED_Div(&pi_high, &six, &x);
    ED_Sin(&x, &sin_high);
    ED_NextMachine(&sin_high, &temp); // Defensywne popchnięcie góry
    sin_high = temp;

    // 3. Wypisanie wyników
    ED_ToString(&sin_low, buf, precision);
    cout << "SIN(x) DOWN: " << buf << endl;

    ED_ToString(&sin_high, buf, precision);
    cout << "SIN(x) UP:   " << buf << endl;

	SetX87Rounding(RD_TONEAREST); // Przywrócenie domyślnego zaokrąglania
	ED_Add(&sin_low, &sin_high, &temp);
	ED_Div(&temp, &two, &temp);
    ED_ToString(&temp, buf, precision);
    cout << "Średnia przedzialu: " << buf << endl;
    // 4. Obliczenie szerokości przedziału (niepewności maszynowej)
    extended_double diff;
    ED_Sub(&sin_high, &sin_low, &diff);
    ED_ToString(&diff, buf, precision);
    cout << "Szerokosc przedzialu: " << buf << endl;

    // 5. Powrót do domyślnego zaokrąglania (Nearest)
    SetX87Rounding(0x0000);

    cout << "-----------------------------------------------" << endl;
    cout << "Wniosek: Prawdziwy wynik matematyczny (0.5) " << endl;
    cout << "musi znajdowac sie wewnatrz powyzszego przedzialu." << endl;
}


void VerifyIntervalPrecision() {
    cout << "=====================================================" << endl;
    cout << "   DIAGNOSTYKA PRECYZJI I ZAOKRAGLEN (Int_Mul)      " << endl;
    cout << "=====================================================" << endl;

    // 1. Przygotowanie danych (1/3 * 3)
    // 1/3 w formacie 80-bit: FD 3F + AA AA AA AA AA AA AA AA (przybliżone)
    extended_double one_third;
    unsigned char ot_data[] = { 0xAB, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xFD, 0x3F };
    memcpy(one_third.bytes, ot_data, 10);

    // 3.0 w formacie 80-bit: 00 40 + C0 00 00 00 00 00 00 00
    extended_double three;
    unsigned char t_data[] = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC0, 0x00, 0x40 };
    memcpy(three.bytes, t_data, 10);

    interval A = { one_third, one_third };
    interval B = { three, three };
    interval R;

    // 2. Wywołanie Twojego ASM
    Int_Mul(&A, &B, &R);

    // 3. Wyświetlanie wyników
    char buf[100]{};
    const int precision = 22;

    cout << fixed << setprecision(precision);

    // --- Dolna granica ---
    ED_ToString(&R.low, buf, precision);
    cout << "Wynik LOW:  " << buf << endl;
    cout << "  HEX: ";
    for (int i = 9; i >= 0; i--) printf("%02X ", R.low.bytes[i]);
    cout << endl << endl;

    // --- Górna granica ---
    ED_ToString(&R.high, buf, precision);
    cout << "Wynik HIGH: " << buf << endl;
    cout << "  HEX: ";
    for (int i = 9; i >= 0; i--) printf("%02X ", R.high.bytes[i]);
    cout << endl << endl;

    // 4. Analiza bitowa
    bool identical = true;
    for (int i = 0; i < 10; i++) {
        if (R.low.bytes[i] != R.high.bytes[i]) identical = false;
    }

    if (identical) {
        cout << "[!] ALARM: Granice sa identyczne bitowo." << endl;
        cout << "    Sprawdz, czy ED_Mul nie resetuje FPU Control Word (finit/fldcw)." << endl;
    }
    else {
        cout << "[+] SUKCES: Granice roznia sie bitowo." << endl;
        cout << "    Arytmetyka przedzialowa poprawnie rozszerza boki." << endl;
    }
    cout << "=====================================================" << endl;
}
//using namespace interval_arithmetic;

int main() {


	SetX87Precision(PREC_EXTENDED);


    VerifyIntervalPrecision();
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
