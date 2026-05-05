EXTERN GetModuleHandleA:PROC
EXTERN RegisterClassA:PROC
EXTERN LoadCursorA:PROC
EXTERN CreateWindowExA:PROC
EXTERN ShowWindow:PROC
EXTERN DialogBoxParamA:PROC
EXTERN EndDialog:PROC
EXTERN DefWindowProcA:PROC
EXTERN PostQuitMessage:PROC
EXTERN GetMessageA:PROC
EXTERN ExitProcess:PROC
EXTERN SetDlgItemTextA:PROC
.data
	wndClassName db "IntervalCalcWndClass", 0
	wndName db "IDD_DIALOG1", 0
    msg_ready db "Ready! Hello and welcome for this new text.",13,10," Newline working!",13,10," Newline working!",13,10," Newline working!",13,10," Newline working!",13,10," Newline working!",13,10," Newline working!",13,10," Newline working!",13,10," Newline working!",13,10," Newline working!",13,10," Newline working!",13,10," Newline working!",13,10," Newline working!",13,10," Newline working!",13,10," Newline working!",13,10," Newline working!", 0
	;wndClass WNDCLASSA <>
	hInstance dq 0
	hwnd dq 0

.code

DlgProc proc h_wnd:dq, uMsg:dd, wParam:dq, lParam:dq

    mov r11, rcx
  ;  mov [rsp + 8],  rcx    ; h_wnd -> [rbp+10h] (po stworzeniu ramki)
   ; mov [rsp + 16], edx    ; uMsg
    ;mov [rsp + 24], r8     ; wParam
   ; mov [rsp + 32], r9     ; lParam
    ; W x64 parametry i tak przychodz¹ w rcx, rdx, r8, r9
  ;  int 3
    cmp edx, 0110h          ; WM_INITDIALOG
    je _init
    
    cmp edx, 0111h          ; WM_COMMAND
    je _command
    
    cmp edx, 0010h          ; WM_CLOSE
    je _close

    xor rax, rax            ; Dla nieobs³u¿onych: zwróæ FALSE (0)
    ret

_init:
   
    and rsp, -16                ; Wymuœ wyrównanie stosu do 16 bajtów
    sub rsp, 30h                ; Zarezerwuj bezpieczne 48 bajtów (Shadow + wyrównanie)
    
    mov rcx, r11       ; Pobierz uchwyt okna (teraz tam jest, bo go zapisa³eœ!)
    mov rdx, 1006               ; ID pola tekstowego
    lea r8, [msg_ready]         ; ADRES tekstu
    
    call SetDlgItemTextA
    
    add rsp, 30h
    mov rax, 1

_command:
    ; Tutaj sprawdzasz r8 (wParam), czy klikniêto "Calculate"
    ; Jeœli klikniêto "WyjdŸ" (IDIDCANCEL):
    ; jmp _close
    xor rax, rax
    ret

_close:
    ; TO JEST KLUCZ: Aby okno modalne siê zamknê³o (i przesta³o trzymaæ):
    sub rsp, 28h
   ; mov rcx, offset [h_wnd]         ; Pierwszy parametr: uchwyt okna
    xor rdx, rdx            ; Drugi parametr: wynik (nResult)
    call EndDialog          ; Musisz wywo³aæ EndDialog, inaczej okno zostanie "zawieszone"
    add rsp, 28h
    mov rax, 1              ; Zwróæ TRUE
    ret
DlgProc endp

start proc
	sub rsp, 120 ; Shadow space dla x64 ABI
	xor rcx, rcx ; hInstance = NULL
	call GetModuleHandleA
	mov hInstance, rax

	mov rcx, [hInstance]        ; 1. Parametr: hInstance Twojej aplikacji
    mov rdx, 101          ; 2. Parametr: Nazwa szablonu w .rc (np. "IDD_DIALOG1")
    xor r8, r8                  ; 3. Parametr: hWndParent (NULL - okno g³ówne)
    mov r9, offset DlgProc       ; 4. Parametr: Adres Twojej procedury obs³ugi okna
    mov qword ptr [rsp+32], 0   ; 5. Parametr: dwInitParam (LPARAM przes³any do WM_INITDIALOG)

    call DialogBoxParamA
    xor rcx, rcx                ; Kod wyjœcia 0
    call ExitProcess
	add rsp, 120
	ret
start endp
END