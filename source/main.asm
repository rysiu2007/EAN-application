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
EXTERN CheckDlgButton:PROC
EXTERN GetDlgItem:PROC
EXTERN EnableWindow:PROC
EXTERN MessageBoxA:PROC
EXTERN software_mode:dq
.data
	wndClassName db "IntervalCalcWndClass", 0
	wndName db "IDD_DIALOG1", 0
    msg_ready db "Ready! Hello and welcome for this new text.",13,10," Newline working!",13,10," Newline working!",13,10," Newline working!",13,10," Newline working!",13,10," Newline working!",13,10," Newline working!",13,10," Newline working!",13,10," Newline working!",13,10," Newline working!",13,10," Newline working!",13,10," Newline working!",13,10," Newline working!",13,10," Newline working!",13,10," Newline working!",13,10," Newline working!", 0
	msg_manual db "Welcome in the manual!",13, 10, "It solves nonlinear equations using Simplified Newton Method, which in contrast to normal Newton calculates the needed derivative only once."
    db 13, 10,"How to use?",13,10,"First you need to load the DLL without mangled naming (extern 'C' in cpp)."
    db " The DLL contains a function called GetN which returns the integer N, and f_1, f_2, ..., f_n,"
    db " which implement given functions in this equation, and df_1, df_2, ..., df_n, which calculate the derivatives of given functions.",0
    msg_manual_caption db "Interval Calculator manual", 0

    ;wndClass WNDCLASSA <>
	hInstance dq 0
	hwnd dq 0

.code

DlgProc proc h_wnd:dq, uMsg:dd, wParam:dq, lParam:dq
    push r12
    mov r12, rcx
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
    pop r12
    ret

_init:
   
    and rsp, -16                ; Wymuœ wyrównanie stosu do 16 bajtów
    sub rsp, 30h                ; Zarezerwuj bezpieczne 48 bajtów (Shadow + wyrównanie)
    
    mov rcx, r12       ; Pobierz uchwyt okna (teraz tam jest, bo go zapisa³eœ!)
    mov rdx, 1006               ; ID pola tekstowego
    lea r8, [msg_ready]         ; ADRES tekstu
    
    call SetDlgItemTextA

    mov rcx, r12
    mov rdx, 1002
    mov r8, 1

    call CheckDlgButton ; Set the radio button to interval mode
   ; int 3
    
    add rsp, 30h
    mov rax, 1
    pop r12
    ret
_command:
    ; Tutaj sprawdzasz r8 (wParam), czy klikniêto "Calculate"
    ; Jeœli klikniêto "WyjdŸ" (IDIDCANCEL):
    ; jmp _close
    sub rsp, 40
    and r8, 0FFFFh
    mov rcx, r12
    mov rdx, 1008
    call GetDlgItem
    mov rcx, rax
    cmp r8, 1000
    je _radio1
    cmp r8, 1001
    je _radio2
    cmp r8, 1002
    je _radio3
    cmp r8, 1005
    je _button1

    jmp _command_exit
    _radio1:
    xor rdx, rdx
    mov software_mode, rdx
    call EnableWindow
    jmp _command_exit

    _radio2:
    mov rdx, 0
    call EnableWindow
    inc rdx
    mov software_mode, rdx
    jmp _command_exit

    _radio3:
    mov rdx, 1
    call EnableWindow
    inc rdx
    mov software_mode, rdx
    jmp _command_exit

    _button1:
    mov rcx, r12
    lea rdx, [msg_manual]
    lea r8, [msg_manual_caption]
    mov r9, 0
    call MessageBoxA
    _command_exit:
    mov rax, 1
    add rsp, 40
    pop r12
    ret

_close:
    ; TO JEST KLUCZ: Aby okno modalne siê zamknê³o (i przesta³o trzymaæ):
    sub rsp, 28h
   ; mov rcx, offset [h_wnd]         ; Pierwszy parametr: uchwyt okna
    xor rdx, rdx            ; Drugi parametr: wynik (nResult)
    call EndDialog          ; Musisz wywo³aæ EndDialog, inaczej okno zostanie "zawieszone"
    add rsp, 28h
    pop r12
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