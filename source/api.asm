.data
const_e TBYTE 4000adf85458a2bb4a9ah
.code

EXTERN software_mode:QWORD
; Funkcje przedzia³owe (Interval)
EXTERN Int_Add:PROC, Int_Sub:PROC, Int_Mul:PROC, Int_Div:PROC
EXTERN Int_Log:PROC, Int_Log2:PROC, Int_Log10:PROC, Int_LogN:PROC
EXTERN Int_Exp:PROC, Int_Pow:PROC, Int_PowInt:PROC
EXTERN Int_Sin:PROC, Int_Cos:PROC, Int_Avg:PROC, Int_LoadNum:PROC, Int_PI:PROC, Int_E:PROC

; Funkcje punktowe (Extended Double)
EXTERN ED_Add:PROC, ED_Sub:PROC, ED_Mul:PROC, ED_Div:PROC
EXTERN ED_Log:PROC, ED_Log2:PROC, ED_Log10:PROC, ED_LogN:PROC
EXTERN ED_Exp:PROC, ED_Pow:PROC, ED_PowInt:PROC
EXTERN ED_Sin:PROC, ED_Cos:PROC


; Makro generuj¹ce dispatcher dla operacji matematycznych
; %1 - nazwa publiczna (widoczna w C++)
; %2 - sufiks Twoich funkcji wewnêtrznych (np. Add, Sub, Mul)

GENERATE_MATH_DISPATCHER MACRO pub_name, internal_name
    public pub_name
    pub_name proc
        sub rsp, 40                 ; Shadow space dla x64 ABI
        
        mov rax, software_mode      ; Pobierz tryb (musi byæ EXTERN QWORD)
        test rax, rax
        jz @F                       ; Skok do najbli¿szego @@ (Forward)
        
        ; Tryb przedzia³owy
        call Int_&internal_name     ; Sk³ada nazwê np. Int_Add
        jmp ending
        
    @@:
        ; Tryb punktowy (float80)
        call ED_&internal_name      ; Sk³ada nazwê np. ED_Add
        
    ending:
        add rsp, 40
        ret
    pub_name endp
ENDM

; Podstawowe operacje
GENERATE_MATH_DISPATCHER M_Add, Add
GENERATE_MATH_DISPATCHER M_Sub, Sub
GENERATE_MATH_DISPATCHER M_Mul, Mul
GENERATE_MATH_DISPATCHER M_Div, Div

; Logarytmy i potêgi
GENERATE_MATH_DISPATCHER M_Log, Log
GENERATE_MATH_DISPATCHER M_Log2, Log2
GENERATE_MATH_DISPATCHER M_Log10, Log10
GENERATE_MATH_DISPATCHER M_LogN, LogN
GENERATE_MATH_DISPATCHER M_Exp, Exp
GENERATE_MATH_DISPATCHER M_Pow, Pow
GENERATE_MATH_DISPATCHER M_PowInt, PowInt

; Trygonometria
GENERATE_MATH_DISPATCHER M_Sin, Sin
GENERATE_MATH_DISPATCHER M_Cos, Cos

M_Mid proc
    sub rsp, 40
    mov rax, software_mode
    test rax, rax
    jz @F
    call Int_Avg
    jmp ending

@@:
    fld tbyte ptr [rcx]    ; Za³aduj pierwszy argument (double) na stóg FPU
    fstp tbyte ptr [rdx]

ending:
    add rsp, 40
    ret
M_Mid endp

M_LoadNum proc
    sub rsp, 40
    mov rax, software_mode
    test rax, rax
    jz @F
    call Int_LoadNum
    jmp ending
@@:
    fld tbyte ptr [rcx]    ; Za³aduj argument (double) na stóg FPU
    fstp tbyte ptr [rdx]
ending:
    add rsp, 40
    ret
M_LoadNum endp

Get_PI proc
    sub rsp, 40
    mov rax, software_mode
    test rax, rax
    jz @F
    call Int_PI
    jmp ending
@@:
    fldpi
    fstp tbyte ptr [rcx]
ending:
    add rsp, 40
    ret
Get_PI endp


Get_E proc
    sub rsp, 40
    mov rax, software_mode
    test rax, rax
    jz @F
    call Int_E
    jmp ending
@@:
    fld tbyte ptr [const_e]
    fstp tbyte ptr [rcx]
ending:
    add rsp, 40
    ret
Get_E endp


END
