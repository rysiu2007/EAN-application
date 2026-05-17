#include "Windows.h"
#include "resource.h"
#include "math_core.h"
#include <string>

extern "C" {
	mode software_mode = float80;
}
bool is_dll_loaded = false;
HMODULE loaded_dll = NULL;
int num = 0, cur_pos = 0;
void (**func)(double_num* ret, double_num* tab);
void (**dfunc)(double_num* ret, double_num* tab);

std::string* left;
std::string* right;
//extern "C" mode software_mode;      // common dialog box structure

std::string OtworzPlikWinAPI(HWND hwndOwner) {
	OPENFILENAMEA ofn;       // Struktura konfiguracyjna okna
	char szFile[260] = { 0 }; // Bufor, do którego system wpisze PE£N¥ œcie¿kê pliku

	// Czyszczenie struktury (bardzo wa¿ne w WinAPI!)
	ZeroMemory(&ofn, sizeof(ofn));

	// Wype³nianie wymaganych pól
	ofn.lStructSize = sizeof(ofn);
	ofn.hwndOwner = hwndOwner;             // Uchwyt okna g³ównego (mo¿e byæ NULL)
	ofn.lpstrFile = szFile;                // WskaŸnik na nasz bufor tekstowy
	ofn.nMaxFile = sizeof(szFile);         // Rozmiar bufora

	// Filtry plików - rozdzielane znakiem '\0' (bajt zerowy), na koñcu podwójne zero!
	ofn.lpstrFilter = "DLL files (*.dll)\0*.dll\0";
	ofn.nFilterIndex = 1;

	ofn.lpstrFileTitle = NULL;
	ofn.nMaxFileTitle = 0;

	// Folder pocz¹tkowy (NULL oznacza bie¿¹cy folder aplikacji)
	ofn.lpstrInitialDir = NULL;

	// Flagi steruj¹ce zachowaniem okna
	// OFN_PATHMUSTEXIST - œcie¿ka musi istnieæ
	// OFN_FILEMUSTEXIST - plik musi fizycznie istnieæ (u¿ytkownik nie wpisze zmyœlonej nazwy)
	ofn.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST;

	// Wywo³anie systemowego okna dialogowego
	if (GetOpenFileNameA(&ofn) == TRUE) {
		// U¿ytkownik klikn¹³ "Otwórz" -> œcie¿ka jest w szFile
		return std::string(szFile);
	}

	// U¿ytkownik klikn¹³ "Anuluj" lub zamkn¹³ okno
	return "";
}

void ZaalokujTabliceFunkcji(int liczbaFunkcji) {
	// Alokacja pamiêci na stercie dla X wskaŸników funkcjonalnych
	func = new (void (*[liczbaFunkcji])(double_num*, double_num*));
	dfunc = new (void (*[liczbaFunkcji])(double_num*, double_num*));

	left = new std::string[liczbaFunkcji];
	right = new std::string[liczbaFunkcji];

	// Teraz mo¿esz dynamicznie przypisywaæ funkcje pod indeksy:
	// func[0] = MojaFunkcja;
}

void ZwolnijPamiec() {
	// Pamiêtaj o zwolnieniu pamiêci w DLL przed zamkniêciem programu!
	delete[] func;
	delete[] dfunc;
	delete[] right;
	delete[] left;
}

void UpdateInputLabel(HWND hwndDlg) {
	if (is_dll_loaded) {
		std::string inputText = "Input " + std::to_string(cur_pos) + "/" + std::to_string(num);
		SetDlgItemTextA(hwndDlg, IDC_GROUP_INPUT, inputText.c_str());
		SetDlgItemTextA(hwndDlg, IDC_EDIT2, left[cur_pos - 1].c_str());
		SetDlgItemTextA(hwndDlg, IDC_EDIT3, right[cur_pos - 1].c_str());
		if (cur_pos > 1) 	EnableWindow(GetDlgItem(hwndDlg, IDC_BUTTON4), TRUE);
		else EnableWindow(GetDlgItem(hwndDlg, IDC_BUTTON4), FALSE);
		if (cur_pos < num) 	EnableWindow(GetDlgItem(hwndDlg, IDC_BUTTON5), TRUE);
		else EnableWindow(GetDlgItem(hwndDlg, IDC_BUTTON5), FALSE);
	}
}

LRESULT CALLBACK DialogProc(HWND hwndDlg, UINT uMsg, WPARAM wParam, LPARAM lParam) {
	switch (uMsg) {
		case WM_INITDIALOG:
		{
			EnableWindow(GetDlgItem(hwndDlg, IDC_BUTTON5), FALSE);
			EnableWindow(GetDlgItem(hwndDlg, IDC_BUTTON4), FALSE);
			//; LPCWSTR title = L"Input 0/0";
			CheckDlgButton(hwndDlg, IDC_RADIO3, BST_CHECKED); // Ustawienie pocz¹tkowego stanu przycisku radiowego
			//SetDlgItemInt(hwndDlg,IDC_GROUP_INPUT, L"Input 0/0", TRUE); // Ustawienie pocz¹tkowej wartoœci w polu edycji
			// --- Inicjalizacja dialogu (opcjonalna) ---
			return TRUE; // Zwracamy TRUE, jeœli chcemy ustawiæ fokus na kontrolce
		}
		case WM_COMMAND:
		{
			switch (LOWORD(wParam))
			{
				case IDC_RADIO1:
					software_mode = float80;
					EnableWindow(GetDlgItem(hwndDlg, IDC_EDIT3), FALSE);
					break;

				case IDC_RADIO2:
					software_mode = interval_float_data;
					EnableWindow(GetDlgItem(hwndDlg, IDC_EDIT3), FALSE);
					break;
				case IDC_RADIO3:
					software_mode = pure_interval;
					EnableWindow(GetDlgItem(hwndDlg, IDC_EDIT3), TRUE);
					break;

				case IDC_BUTTON1:
					MessageBox(hwndDlg, "Calculate button clicked!", "Info", MB_OK);
					break;
				case IDC_BUTTON2: {
					//GetOpenFileNameA()
					std::string dllPath = OtworzPlikWinAPI(hwndDlg);
					loaded_dll = LoadLibraryExA(dllPath.c_str(), NULL, 0);
					if (!loaded_dll) {
						MessageBox(hwndDlg, "Failed to load DLL!", "Error", MB_OK | MB_ICONERROR);
						break;
					}

					FARPROC getNum = GetProcAddress(loaded_dll, "GetNum"); // Przyk³adowa funkcja, któr¹ chcemy za³adowaæ
					if (!getNum) {
						MessageBox(hwndDlg, "Failed to find GetNum in DLL!", "Error", MB_OK | MB_ICONERROR);
						FreeLibrary(loaded_dll);
						loaded_dll = NULL;
						break;
					}
					
					num = ((int(*)())getNum)();
					cur_pos = 1;
					UpdateInputLabel(hwndDlg);

					if (num <= 0) {
						MessageBox(hwndDlg, "Invalid number of functions returned by DLL!", "Error", MB_OK | MB_ICONERROR);
						FreeLibrary(loaded_dll);
						loaded_dll = NULL;
						break;
					}

					ZaalokujTabliceFunkcji(num);
					is_dll_loaded = true;
					for (int i = 1; i <= num; ++i) {
						std::string funcName = "f" + std::to_string(i);
						FARPROC funcPtr = GetProcAddress(loaded_dll, funcName.c_str());
						if (!funcPtr) {
							MessageBox(hwndDlg, ("Failed to find " + funcName + " in DLL!").c_str(), "Error", MB_OK | MB_ICONERROR);
							FreeLibrary(loaded_dll);
							loaded_dll = NULL;
							return TRUE;
						}
						func[i] = (void (*)(double_num*, double_num*))funcPtr;
						std::string dfuncName = "df" + std::to_string(i);
						FARPROC dfuncPtr = GetProcAddress(loaded_dll, dfuncName.c_str());
						if (!dfuncPtr) {
							MessageBox(hwndDlg, ("Failed to find " + dfuncName + " in DLL!").c_str(), "Error", MB_OK | MB_ICONERROR);
							FreeLibrary(loaded_dll);
							loaded_dll = NULL;
							return TRUE;
						}
						dfunc[i] = (void (*)(double_num*, double_num*))dfuncPtr;
					}
					break;
				}
				case IDC_BUTTON3:
					MessageBox(hwndDlg, "Manual button clicked!", "Info", MB_OK);
					break;
				case IDC_BUTTON4:
					if (cur_pos > 1) {
						cur_pos--;
					}
					UpdateInputLabel(hwndDlg);
					break;
				case IDC_BUTTON5:
					if (cur_pos < num) {
						cur_pos++;
					}
					UpdateInputLabel(hwndDlg);
					break;
				case IDC_EDIT2: 
				{
					if (cur_pos > 0) {
						CHAR text[50];
						GetDlgItemTextA(hwndDlg, IDC_EDIT2, text, 50);
						left[cur_pos - 1] = text;
					}
					break;
				}
				case IDC_EDIT3:
				{
					if (cur_pos > 0) {
						CHAR text[50];
						GetDlgItemTextA(hwndDlg, IDC_EDIT3, text, 50);
						right[cur_pos - 1] = text;
					}
					break;
				}
				default:
					return FALSE; // Nieobs³ugiwane polecenie
			}
			return TRUE;
		}
	case WM_CLOSE:
		EndDialog(hwndDlg, 0);
		return TRUE;
	}
	return FALSE;
}

int main() {

	HINSTANCE hInstance = GetModuleHandleA(NULL);
	DialogBoxParamA(hInstance, MAKEINTRESOURCEA(IDD_DIALOG1), NULL, DialogProc, 0);
	if (loaded_dll) {
		FreeLibrary(loaded_dll);
	}
	if (dfunc) {
		ZwolnijPamiec();
	}
	ExitProcess(0);
}