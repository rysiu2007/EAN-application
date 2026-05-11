extern M_Mid:PROC, M_Add:PROC, M_Sub:PROC, M_Mul:PROC, M_Div:PROC, M_Pow:PROC
extern M_Log:PROC, M_Log2:PROC, M_Log10:PROC, M_LogN:PROC, M_Exp:PROC, M_Sin:PROC, M_Cos:PROC
extern ED_Add:PROC, ED_Sub:PROC, ED_Mul:PROC, ED_Div:PROC, ED_Pow:PROC
extern Int_Add:PROC, Int_Sub:PROC, Int_Mul:PROC, Int_Div:PROC, Int_Pow:PROC, Int_LoadNum:PROC
extern software_mode:dq
.data

.code

SimplifiedNewton_Point proc
	push rbx
	push r12
	push r13
	push r14
	push r15
	push rsi
	push rdi
	sub rsp, 120
	mov rbx, rcx
	mov r13, rdx
	mov r14, r8
	;mov r15, r9
	mov r12, [rsp+120+8+8+8+8+8+8+8+32+8+8] ; mit
	main_loop:
		fldz
		fstp tbyte ptr [rsp+96]
		push rbx
		mov rsi, r8
		mov rdi, r9
		mov r15, r13
		iter_loop:

			lea rcx, [rsp+48]
			mov rdx, r13
			mov rax, [rsi]
			call rax
			add rsi, 8
			lea rcx, [rsp+72]
			mov rdx, r13
			mov rax, [rdi]
			call rax
			add rdi, 8
			lea rcx, [rsp+48]
			lea rdx, [rsp+72]
			lea r8, [rsp+48]
			call ED_Div

			lea rcx, [rsp+48]
			mov rdx, [rsp+120+8+8+8+8+8+8+8+32+8]; omega
			lea r8, [rsp+48]
			call ED_Mul

			lea rcx, [r15]
			lea rdx, [rsp+48]
			lea r8, [r15]	;Should save it in a different place but for a prototype i think its ok
			call ED_Sub
			fld tbyte ptr [rsp+96]
			fld tbyte ptr [rsp+48]
			fabs
			fcomi st(0), st(1)
			fcmovb st(0), st(1)
			fstp tbyte ptr [rsp+96]
			fstp st(0)

			add r15, 20
			dec rbx
		jnz iter_loop
		pop rbx
		fld tbyte ptr [rsp+120+8+8+8+8+8+8+8+32+8+8+8]
		fld tbyte ptr [rsp+96]
		fcomi st(0), st(1)
		jb end_loop
	;Do additional checkings and operations
	dec r12
	jnz main_loop
	
	end_loop:
	;mov rax, rdx
	add rsp, 120
	pop rdi
	pop rsi
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	ret

SimplifiedNewton_Point endp

SimplifiedNewton_Interval proc
    push rbp
	mov rbp, rsp 
	push rbx
	push r12
	push r13
	push r14
	push r15
	push rsi
	push rdi
	mov rax, rcx        ; rcx = n
    imul rax, 20        ; n * 20 bajtów
    add rax, 256        ; zapas na Twoje zmienne [rsp+48], [rsp+96] itd.
    add rax, 15         ; do wyrównania
    and rax, -16        ; wyrównanie do 16 bajtów
    sub rsp, rax        ; dynamiczna alokacja

	; --- KOPIOWANIE WEKTORA NA STOS ---
    mov rbx, rcx        ; rbx = n (z rcx na wejœciu)
    imul rcx, 20        ; liczba bajtów
    mov rsi, r13        ; r13 to orygina³ (z rdx na wejœciu)
    lea rdi, [rsp+32]      ; nasza nowa tablica na samym dole
    mov r13, rdi        ; PODMIANA: teraz r13 wskazuje na KOPIÊ
    rep movsb
	;mov rbx, rcx
	mov r13, rdx
	mov r14, r8
	;mov r12, r9
	;mov rcx, r
	push r9
	push rbx
	;push rs
	;mov rbx, rcx
	mov r15, 48 ; 32offset + 16 for pushes
	mid_point_loop:
		lea rcx, [rsp+r15]
		lea rdx, [rsp+r15]
		call Int_Avg
		lea rcx, [rsp+r15]
		lea rdx, [rsp+r15]
		call Int_LoadNum
		add r15, 20
		dec rbx
	jnz mid_point_loop
	;loop mid_point_loop
	pop rbx
	pop r9
       ; rbp bêdzie teraz naszym sta³ym punktem odniesienia (Frame Pointer)
	;sub rsp, 168
	;mov r15, r9
	mov r12, [rbp+32+8+8+8] ; mit
	main_loop:
		fldz
		fstp tbyte ptr [rbp-56-96]
		push rbx
		mov rsi, r8
		mov rdi, r9
		mov r15, r13
		iter_loop:

				; 1. Wylicz œrodek aktualnego x_i (r15) -> wynik do [rsp+120] (punkt)
			lea rcx, [r15]
			lea rdx, [rbp-56-120]
			call Int_Avg
			lea rcx, [rbp-56-120]
			lea rdx, [rbp-56-120]
			call Int_LoadNum

			; 2. LICZENIE f_i(..., m(x_i), ...) 
			; UWAGA: r13 to tablica przedzia³ów. 
			; Musisz na chwilê podmieniæ r13[i] na punkt [rsp+120]
			; lub Twoja funkcja f_i musi umieæ to obs³u¿yæ.
			; dynamicznie alokowaæ stos bêdê musia³
			lea rcx, [rbp-56-48]
			lea rdx, [rsp+32]
			mov rax, [rsi]
			call rax
			add rsi, 8

			; 3. LICZENIE df_i([x]) - tu u¿ywasz pe³nych przedzia³ów
			lea rcx, [rbp-56-72]
			mov rdx, r13
			mov rax, [rdi]
			call rax
			add rdi, 8

			; 4. Arytmetyka: (f / df) * omega
			lea rcx, [rbp-56-48]
			lea rdx, [rbp-56-72]
			lea r8,  [rbp-56-48]
			call Int_Div

			lea rcx, [rbp-56-48]
			mov rdx, [rbp+32+8+8]
			lea r8,  [rbp-56-48]
			call Int_Mul

			; 5. NOWY PRZEDZIA£: m(x_i) - poprawka
			lea rcx, [rbp-56-120] ; To jest nasz œrodek (punkt potraktowany jako przedzia³)
			lea rdx, [rbp-56-48]  ; To jest nasza poprawka przedzia³owa
			lea r8,  [rbp-56-48]  ; Wynik tymczasowy
			call Int_Sub

			; 6. INTERSECT: [x]_new = [x]_old \cap [temp]
			lea rcx, [r15]     ; Stary przedzia³
			lea rdx, [rbp-56-48]  ; Wynik z punktu 5
			lea r8,  [r15]     ; Zapisujemy z powrotem do g³ównej tablicy
			call Int_Intersect
			;trzeba warunki od nowa napisaæ i intersecta dodaæ z jego sprawdzeniami

			xor rax, rax
			fldz
			fld tbyte ptr [r15 + 10] ; sup
			fcomi st(0), st(1)
			cmove rax, 1
			fld tbyte ptr [r15]      ; inf
			fcomi st(0), st(2)
			jne .proceed
			cmp rax, 0
			fldz        ; Za³aduj 0
			fldz        ; Za³aduj 0
			fdivp
			fstp st(0)   ; Teraz st(0) = 0/0 = NaN
			
			je end_loop

			.proceed:
			fsubp st(1), st(0)
			fabs
			fld tbyte ptr [rbp-56-96]
		;	fld tbyte ptr [rbp-56-48]
		;	fabs
			fcomi st(0), st(1)
			fcmovb st(0), st(1)
			fstp tbyte ptr [rbp-56-96]
			fstp st(0)

			add r15, 20
			dec rbx
		jnz iter_loop
		pop rbx
		fld tbyte ptr [rbp+32+8+8+8+8];eps
		fld tbyte ptr [rbp-56-96]
		fcomi st(0), st(1)
		jb end_loop
	;Do additional checkings and operations
	dec r12
	jnz main_loop
	
	end_loop:
	;mov rax, rdx
	pop rdi
	pop rsi
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx

	mov rsp, rbp
	pop rbp
	ret

SimplifiedNewton_Interval endp

SimplifiedNewton proc
    sub rsp, 40                 ; Shadow space dla x64 ABI
        
    mov rax, software_mode      ; Pobierz tryb (musi byæ EXTERN QWORD)
    test rax, rax
    jz @F                       ; Skok do najbli¿szego @@ (Forward)
        
        ; Tryb przedzia³owy
    call SimplifiedNewton_Interval     ; Sk³ada nazwê np. Int_Add
        jmp ending
        
    @@:
        ; Tryb punktowy (float80)
        call SimplifiedNewton_Point      ; Sk³ada nazwê np. ED_Add
        
    ending:
        add rsp, 40
        ret
SimplifiedNewton endp