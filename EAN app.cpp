// EAN app.cpp: definiuje punkt wejścia dla aplikacji.
//

#include "EAN app.h"
//#include "Interval.h"
#include "extended_double.h"

using namespace std;

//using namespace interval_arithmetic;

int main() {

	SetX87Precision(PREC_EXTENDED);
  //  std::cout<<std::fixed<<std::setprecision(20);
    SetX87Rounding(RD_DOWNWARD);
	cout << GetX87Rounding() << endl;
    SetX87Rounding(RD_UPWARD);
    char buffer[64]{};
    cout << GetX87Rounding() << endl;
	extended_double ed1, ed2, ed_result, ed_result2;
    unsigned char raw_data[] = { 0x35, 0xC2, 0x68, 0x21, 0xB2, 0xDA, 0x0F, 0xD0, // Mantysa (E6 = 1110 0110)
    0x01, 0x40 };
    std::memcpy(ed1.bytes, raw_data, 10);
    //ED_FromDouble(5.0, &ed1);
    ED_ToString(&ed1, buffer, 22);
    cout << buffer << endl;
    ed2 = pi;
    //unsigned char raw_data2[] = { 0x67, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0xE6, // Mantysa (E6 = 1110 0110)
  //  0xFE, 0x3F };
	//std::memcpy(ed2.bytes, raw_data2, 10);
    //ED_FromDouble(2.0, &ed2);
	ED_Log10(&ed2, &ed2);
    ED_ToString(&ed2, buffer, 23);
    cout << buffer << endl;
	//ED_FromDouble(0.3, &ed1);
//	ED_FromDouble(1.5, &ed2);
    SetX87Rounding(RD_DOWNWARD);
	ED_Div_Mod(&ed1, &ed2, &ed_result,&ed_result2);
//	cout<<ED_ToDouble(&ed_result)<<endl;
	ED_ToString(&ed_result, buffer, 22);
	cout << buffer << endl;

    ED_ToString(&ed_result2, buffer, 22);
    cout << buffer << endl;

    SetX87Rounding(RD_UPWARD);
    ED_Div_Mod(&ed1, &ed2, &ed_result, &ed_result2);
    ED_Floor(&ed_result, &ed_result);
    //	cout<<ED_ToDouble(&ed_result)<<endl;
    ED_ToString(&ed_result, buffer, 22);
    cout << buffer << endl;

    ED_ToString(&ed_result2, buffer, 22);
    cout << buffer << endl;
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
