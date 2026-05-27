#include "resource.h"
#include "main.h"
#include "math_core.h"
#include "simp_newton.h"
#include <string>
#include <crtdbg.h>
#include <commctrl.h>
#pragma comment(lib, "comctl32.lib")
#pragma comment(linker,"\"/manifestdependency:type='win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'\"")

extern "C" {
	mode software_mode = pure_interval;
}
bool is_dll_loaded = false;
HMODULE loaded_dll = NULL;
std::string dllPath;
int num = 0, cur_pos = 0;
void (**func)(double_num* ret, double_num* tab);
void (**dfunc)(double_num* ret, double_num* tab);
int mit = 0;
extended_double eps;
double_num omega;

bool is_eps = false;
bool is_omega = false;
bool is_mit = false;

std::string* left;
std::string* right;

double_num* left_ed;

FARPROC setMode;
//double_num* right_ed;

HWND hwndDLG;

std::string textBoxContent = "";

bool IsFormatXX_Strict(const char* text) {
	if (!text || text[0] == L'\0') return false;

	int i = 0;

	// 1. Opcjonalny znak minus
	if (text[i] == L'-') {
		i++;
	}

	// 2. Musi byæ przynajmniej jedna cyfra przed kropk¹
	if (!iswdigit(text[i])) return false;
	while (iswdigit(text[i])) {
		i++;
	}

	// 3. W tym miejscu MUSI byæ kropka
	if (text[i] != L'.') return false;
	i++; // pomiñ kropkê

	// 4. Musi byæ przynajmniej jedna cyfra po kropce
	if (!iswdigit(text[i])) return false;
	while (iswdigit(text[i])) {
		i++;
	}

	// 5. Jeœli tu nie ma koñca stringa (\0), to znaczy, ¿e s¹ jakieœ œmieci na koñcu
	return (text[i] == L'\0');
}

bool IsFormat00_Strict(const char* text) {
	if (!text || text[0] == L'\0') return false;

	int i = 0;

	// 1. Opcjonalny znak minus
	if (text[i] == L'-') {
		i++;
	}

	// 2. Musi byæ przynajmniej jedna cyfra przed kropk¹
	if (text[i]!='0') return false;
	while (text[i]=='0') {
		i++;
	}

	// 3. W tym miejscu MUSI byæ kropka
	if (text[i] != L'.') return false;
	i++; // pomiñ kropkê

	// 4. Musi byæ przynajmniej jedna cyfra po kropce
	if (text[i]!='0') return false;
	while (text[i]=='0') {
		i++;
	}

	// 5. Jeœli tu nie ma koñca stringa (\0), to znaczy, ¿e s¹ jakieœ œmieci na koñcu
	return (text[i] == L'\0');
}

void OutputLog(const char* newText) {
	HWND hEdit = GetDlgItem(hwndDLG, IDC_EDIT1);
	if (!hEdit) return;

	// 1. ZnajdŸ koniec tekstu
	int len = GetWindowTextLengthA(hEdit);

	// 2. Ustaw zaznaczenie na sam koniec (pusta selekcja)
	SendMessageA(hEdit, EM_SETSEL, len, len);

	// 3. Wklej nowy tekst w miejsce zaznaczenia (czyli na koniec)
	SendMessageA(hEdit, EM_REPLACESEL, FALSE, (LPARAM)newText);

	// 4. Teraz kursor fizycznie przemieœci³ siê w dó³, wiêc rozkaz przewiniêcia zadzia³a natychmiast!
	SendMessageA(hEdit, EM_SCROLLCARET, 0, 0);
}
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
	left_ed = new double_num[liczbaFunkcji];
	// right_ed = new double_num[liczbaFunkcji];

	// Teraz mo¿esz dynamicznie przypisywaæ funkcje pod indeksy:
	// func[0] = MojaFunkcja;
}

void ZwolnijPamiec() {
	// Pamiêtaj o zwolnieniu pamiêci w DLL przed zamkniêciem programu!
	delete[] func;
	delete[] dfunc;
	delete[] right;
	delete[] left;
	delete[] left_ed;
	//delete[] right_ed;
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
	hwndDLG = hwndDlg;
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

			// 4. KROK KRYTYCZNY: Przesuwasz kursor na sam koniec (od len do len)
			//SendMessageA(hEdit, EM_SETSEL, len, len);
			//SendMessageA(hEdit, EM_SCROLLCARET, 0, 0);
			//OutputLog("Pisze\r\n");
			switch (LOWORD(wParam))
			{
			case IDC_RADIO1: {
				if (HIWORD(wParam) == BN_CLICKED) {
					software_mode = float80;
					extended_double num;
					M_Mid(&omega, &num);
					M_LoadNum(&num, &omega);
					EnableWindow(GetDlgItem(hwndDlg, IDC_EDIT3), FALSE);
					OutputLog("Mode set to flat floating point mode.\r\n");

				}
				break;
			}

			case IDC_RADIO2: {
				if (HIWORD(wParam) == BN_CLICKED) {
					software_mode = interval_float_data;
					extended_double num;
					M_Mid(&omega, &num);
					M_LoadNum(&num, &omega);
					EnableWindow(GetDlgItem(hwndDlg, IDC_EDIT3), FALSE);
					OutputLog("Mode set to interval mode, with singular inputs\r\n");
				}
				break;
			}
			case IDC_RADIO3: {
				if (HIWORD(wParam) == BN_CLICKED) {
					software_mode = pure_interval;
					extended_double num;
					M_Mid(&omega, &num);
					M_LoadNum(&num, &omega);
					EnableWindow(GetDlgItem(hwndDlg, IDC_EDIT3), TRUE);
					OutputLog("Mode set to interval mode, with interval inputs\r\n");
				}
				break;
			}

			case IDC_BUTTON1: {
				ClearX87Errors();
				// _fpreset();
				if (!is_dll_loaded) {
					MessageBox(hwndDlg, "No proper DLL is loaded.", "Error", MB_OK | MB_ICONERROR);
					break;
				}
				if (!is_eps) {
					MessageBox(hwndDlg, "No EPS is given.", "Error", MB_OK | MB_ICONERROR);
					break;
				}
				if (!is_mit) {
					MessageBox(hwndDlg, "No MIT is given.", "Error", MB_OK | MB_ICONERROR);
					break;
				}
				if (!is_omega) {
					MessageBox(hwndDlg, "No omega is given.", "Error", MB_OK | MB_ICONERROR);
					break;
				}
				for (int i = 0; i < num; i++)
				{
					if (!IsFormatXX_Strict(left[i].c_str())) {
						MessageBox(hwndDlg, "No proper xn value is given.", "Error", MB_OK | MB_ICONERROR);
						goto end_switch;
					}
					else
					{
						extended_double temp;
						ED_FromString(&temp, left[i].c_str(), left[i].size() + 1);
						M_LoadNum(&temp, &left_ed[i]);
					}
				}
				if (software_mode == pure_interval) {
					for (int i = 0; i < num; i++)
					{
						if (!IsFormatXX_Strict(right[i].c_str())) {
							MessageBox(hwndDlg, "No proper xn value is given.", "Error", MB_OK | MB_ICONERROR);
							goto end_switch;
						}
						else
						{
							extended_double temp;
							ED_FromString(&temp, right[i].c_str(), right[i].size() + 1);
							left_ed[i].inter.high = temp;
						}
					}
				}
				OutputLog("Loaded values:\r\n");
				for (int i = 0; i < num; i++)
				{
					CHAR text[35];
					_itoa_s(i, text, 10, 10);
					OutputLog("x[");
					OutputLog(text);
					OutputLog("]: ");
					extended_double temp;
					if (software_mode == float80) {
						ED_ToStringScientific(&left_ed[i].num, text, 35);
						OutputLog(text);
						OutputLog("\r\n");
					}
					else {
						M_Mid(&left_ed[i], &temp);
						ED_ToStringScientific(&temp, text, 35);
						OutputLog(text);
						OutputLog(", [");
						ED_ToStringScientific(&left_ed[i].inter.low, text, 35);
						OutputLog(text);
						OutputLog(";");
						ED_ToStringScientific(&left_ed[i].inter.high, text, 35);
						OutputLog(text);
						OutputLog("]\r\n");
					}
				}
				//loaded_dll = LoadLibraryExA(dllPath.c_str(), NULL, 0);
				//{
				//	if (!loaded_dll) {
				//		MessageBox(hwndDlg, "Failed to load DLL!", "Error", MB_OK | MB_ICONERROR);
				//		throw;
				//	}
				//	setMode = GetProcAddress(loaded_dll, "SetMode"); // Przyk³adowa funkcja, któr¹ chcemy za³adowaæ
				//	if (!setMode) {
				//		MessageBox(hwndDlg, "Failed to find SetMode in DLL!", "Error", MB_OK | MB_ICONERROR);
				//		FreeLibrary(loaded_dll);
				//		loaded_dll = NULL;
				//		throw;
				//	}

				//	FARPROC getNum = GetProcAddress(loaded_dll, "GetNum"); // Przyk³adowa funkcja, któr¹ chcemy za³adowaæ
				//	if (!getNum) {
				//		MessageBox(hwndDlg, "Failed to find GetNum in DLL!", "Error", MB_OK | MB_ICONERROR);
				//		FreeLibrary(loaded_dll);
				//		loaded_dll = NULL;
				//		throw;
				//	}
				//}

//				FARPROC setMode = GetProcAddress(loaded_dll, "SetMode");
				((void(*)(int))setMode)(software_mode);
				CHAR text[50];

				

			/*	for (int i = 1; i <= num; ++i) {
					std::string funcName = "f" + std::to_string(i);
					FARPROC funcPtr = GetProcAddress(loaded_dll, funcName.c_str());
					if (!funcPtr) {
						MessageBox(hwndDlg, ("Failed to find " + funcName + " in DLL!").c_str(), "Error", MB_OK | MB_ICONERROR);
						is_dll_loaded = false;
						FreeLibrary(loaded_dll);
						loaded_dll = NULL;
						throw;
					}
					func[i - 1] = (void (*)(double_num*, double_num*))funcPtr;
					std::string dfuncName = "df" + std::to_string(i);
					FARPROC dfuncPtr = GetProcAddress(loaded_dll, dfuncName.c_str());
					if (!dfuncPtr) {
						MessageBox(hwndDlg, ("Failed to find " + dfuncName + " in DLL!").c_str(), "Error", MB_OK | MB_ICONERROR);
						is_dll_loaded = false;
						FreeLibrary(loaded_dll);
						loaded_dll = NULL;
						throw;
					}
					dfunc[i - 1] = (void (*)(double_num*, double_num*))dfuncPtr;
				}*/
				
				OutputLog("Running SimplifiedNewton in ");
				switch (software_mode)
				{
				case float80:
					OutputLog("float80");
					break;
				case interval_float_data:
					OutputLog("interval float data");
					break;
				case pure_interval:
					OutputLog("pure interval");
					break;
				default:
					break;
				}
				OutputLog(" mode. With variables: mit=");
				_itoa_s(mit, text, 50, 10);
				OutputLog(text);
				OutputLog(", eps=");
				ED_ToStringScientific(&eps, text, 50);
				OutputLog(text);
				OutputLog(", omega=");
				extended_double temp;
				M_Mid(&omega, &temp);
				ED_ToStringScientific(&temp, text, 50);
				OutputLog(text);
				OutputLog(".\r\n");
				SimplifiedNewton(num, left_ed, func, dfunc, &omega, mit, &eps);
				UpdateInputLabel(hwndDlg);
				FreeModule(loaded_dll);
				is_dll_loaded = false;
				if (GetX87Errors() & (ERR_ZERO_DIVIDE | ERR_INVALID_OP)) {
					OutputLog("There were some critical errors, or Newton was not convergent. Try with different data.\r\n");
					break;
				}
				OutputLog("Results:\r\n");
				for (int i = 0; i < num; i++)
				{
					CHAR text[35];
					_itoa_s(i, text, 10, 10);
					OutputLog("x[");
					OutputLog(text);
					OutputLog("]: ");
					extended_double temp;
					if (software_mode == float80) {
						ED_ToStringScientific(&left_ed[i].num, text, 35);
						OutputLog(text);
						OutputLog("\r\n");
					}
					else {
						M_Mid(&left_ed[i], &temp);
						ED_ToStringScientific(&temp, text, 35);
						OutputLog(text);
						OutputLog(", [");
						ED_ToStringScientific(&left_ed[i].inter.low, text, 35);
						OutputLog(text);
						OutputLog(";");
						ED_ToStringScientific(&left_ed[i].inter.high, text, 35);
						OutputLog(text);
						OutputLog("]\r\n");
					}
				}
				//MessageBoxA(hwndDlg, "Hello. Trying to calculate", "", 0);
				
				end_switch:
				break;
			}
				case IDC_BUTTON2: {
					//GetOpenFileNameA()
					dllPath = OtworzPlikWinAPI(hwndDlg);
					loaded_dll = LoadLibraryExA(dllPath.c_str(), NULL, 0);
					if (!loaded_dll) {
						MessageBox(hwndDlg, "Failed to load DLL!", "Error", MB_OK | MB_ICONERROR);
						break;
					}
					setMode = GetProcAddress(loaded_dll, "SetMode"); // Przyk³adowa funkcja, któr¹ chcemy za³adowaæ
					if (!setMode) {
						MessageBox(hwndDlg, "Failed to find SetMode in DLL!", "Error", MB_OK | MB_ICONERROR);
						FreeLibrary(loaded_dll);
						loaded_dll = NULL;
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

					if (num <= 0) {
						MessageBox(hwndDlg, "Invalid number of functions returned by DLL!", "Error", MB_OK | MB_ICONERROR);
						FreeLibrary(loaded_dll);
						loaded_dll = NULL;
						break;
					}
					if (dfunc) {
						ZwolnijPamiec();
					}
					ZaalokujTabliceFunkcji(num);
					is_dll_loaded = true;
					for (int i = 1; i <= num; ++i) {
						std::string funcName = "f" + std::to_string(i);
						FARPROC funcPtr = GetProcAddress(loaded_dll, funcName.c_str());
						if (!funcPtr) {
							MessageBox(hwndDlg, ("Failed to find " + funcName + " in DLL!").c_str(), "Error", MB_OK | MB_ICONERROR);
							is_dll_loaded = false;
							FreeLibrary(loaded_dll);
							loaded_dll = NULL;
							return TRUE;
						}
						func[i-1] = (void (*)(double_num*, double_num*))funcPtr;
						std::string dfuncName = "df" + std::to_string(i);
						FARPROC dfuncPtr = GetProcAddress(loaded_dll, dfuncName.c_str());
						if (!dfuncPtr) {
							MessageBox(hwndDlg, ("Failed to find " + dfuncName + " in DLL!").c_str(), "Error", MB_OK | MB_ICONERROR);
							is_dll_loaded = false;
							FreeLibrary(loaded_dll);
							loaded_dll = NULL;
							return TRUE;
						}
						dfunc[i-1] = (void (*)(double_num*, double_num*))dfuncPtr;
					}
					UpdateInputLabel(hwndDlg);
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
				case IDC_EDIT_MIT:
				{
					if (HIWORD(wParam)==EN_KILLFOCUS) {
						CHAR text[50];
						GetDlgItemTextA(hwndDlg, IDC_EDIT_MIT, text, 50);
						mit = atoi(text);
						if (mit <= 0) {
							MessageBox(hwndDlg, "MIT should be an integer number", "Error", MB_ICONERROR);
						}
						else {
							_itoa_s(mit, text, 50, 10);
							OutputLog("Loaded value ");
							OutputLog(text);
							OutputLog(" as MIT\r\n");
							is_mit = true;
						}
						//right[cur_pos - 1] = text;
					}
					break;
				}
				case IDC_EDIT_EPS:
				{
					if (HIWORD(wParam) == EN_KILLFOCUS) {
						CHAR text[50];
						GetDlgItemTextA(hwndDlg, IDC_EDIT_EPS, text, 50);
						//mit = atoi(text);
						if (!IsFormatXX_Strict(text) || text[0]=='-' || IsFormat00_Strict(text)) {
							MessageBox(hwndDlg, "EPS should be a positive float number. Like 1.0 or 0.00001.", "Error", MB_ICONERROR);
						}
						else {
							ED_FromString(&eps, text, strlen(text)+1);
							OutputLog("Loaded value ");
							// M_Mid(&omega, &num);
							ED_ToStringScientific(&eps, text, 50);
							OutputLog(text);
							OutputLog(" as EPS.\r\n");
							is_eps = true;
						}
						//right[cur_pos - 1] = text;
					}
					break;
				}
				case IDC_EDIT_OMEGA:
				{
					if (HIWORD(wParam) == EN_KILLFOCUS) {
						CHAR text[50];
						GetDlgItemTextA(hwndDlg, IDC_EDIT_OMEGA, text, 50);
						//mit = atoi(text);
						if (!IsFormatXX_Strict(text)) {
							MessageBox(hwndDlg, "Omega should be a float number between 0 and 2.", "Error", MB_ICONERROR);
						}
						else {
							double val = atof(text);
							// Bezwzglêdna kontrola granic zbie¿noœci Newtona-Gaussa-Seidela
							if (val <= 0.0 || val >= 2.0) {
								MessageBoxA(hwndDlg, "Omega must be strictly between 0 and 2 (0 < omega < 2)!", "Convergence Error", MB_ICONERROR);
							}
							else {
								extended_double num1;
								ED_FromString(&num1, text, strlen(text) + 1);
								M_LoadNum(&num1, &omega);
								OutputLog("Loaded value ");
								// M_Mid(&omega, &num);
								ED_ToStringScientific(&num1, text, 50);
								OutputLog(text);
								OutputLog(" as omega.\r\n");
								is_omega = true;
							}
						}
						//right[cur_pos - 1] = text;
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

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	SetX87Precision(PREC_EXTENDED);
	int tmpFlag = _CrtSetDbgFlag(_CRTDBG_REPORT_FLAG);
	_CrtSetDbgFlag(tmpFlag | _CRTDBG_ALLOC_MEM_DF | _CRTDBG_CHECK_ALWAYS_DF);
	//HINSTANCE hInstance = GetModuleHandleA(NULL);
	INITCOMMONCONTROLSEX icex;
	icex.dwSize = sizeof(INITCOMMONCONTROLSEX);
	icex.dwICC = ICC_WIN95_CLASSES;
	InitCommonControlsEx(&icex);

	DialogBoxParamA(hInstance, MAKEINTRESOURCEA(IDD_DIALOG1), NULL, DialogProc, 0);
	if (dfunc) {
		ZwolnijPamiec();
	}
	if (loaded_dll) {
		FreeLibrary(loaded_dll);
	}
	//MessageBox(NULL, "lest", "", 0);
	ExitProcess(0);
}