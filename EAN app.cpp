// EAN app.cpp: definiuje punkt wejścia dla aplikacji.
//

#include "EAN app.h"
#include "Interval.h"
#include "extended_double.h"

using namespace std;

using namespace interval_arithmetic;

int main() {

    std::cout<<std::fixed<<std::setprecision(20);
    SetX87Rounding(RD_DOWNWARD);
	cout << GetX87Rounding() << endl;
    SetX87Rounding(RD_UPWARD);
    cout << GetX87Rounding() << endl;
	extended_double ed1, ed2, ed_result;
	ED_FromDouble(1.1, &ed1);
	ED_FromDouble(-2.0, &ed2);
	ED_Add(&ed1, &ed2, &ed_result);
    char buffer[64]{};
	cout<<ED_ToDouble(&ed_result)<<endl;
	ED_ToString(&ed_result, buffer, sizeof(buffer));
    
	cout << buffer << endl;
    try {
        // 1. Inicjalizacja (ważne dla MPFR!)
        Interval<double>::Initialize();

        // 2. Tworzenie przedziału
        Interval<double> x(1.0, 2.0);
        Interval<double> y(3.0, 4.0);

        // 3. Operacja (wykorzystuje Twoje przeciążone operatory)
        Interval<double> z = x + y;

        std::cout << "Wynik: [" << z.a << ", " << z.b << "]" << std::endl;
    }
    catch (const std::exception& e) {
        std::cerr << "Blad: " << e.what() << std::endl;
    }
    return 0;
}
