.data
	const_10  dt 10.0
.code

PUBLIC ED_NextMachine

SetX87Rounding proc
	sub rsp, 8
	fnstcw [rsp] ;store the control world on stack

	mov ax, [rsp] ;load the control word into rax
	and ax, 0F3FFh ;clear the rounding control bits (bits 10 and 11)
	
	and rcx, 3 ; ensure the desired rounding mode is between 0 and 3
	shl cx, 10 ;shift the desired rounding mode into the correct position
	or ax, cx ;set the new rounding mode bits

	mov [rsp], ax ;store the modified control word back on the stack
	fldcw [rsp] ;load the modified control word into the x87 FPU
	add rsp, 8
	fwait ; wait for the FPU to complete the control word update
	ret
SetX87Rounding endp

SetX87Precision proc
	sub rsp, 8
	fnstcw [rsp] ;store the control world on stack
	mov ax, [rsp] ;load the control word into rax
	and ax, 0FCFFh ;clear the precision control bits (bits 8 and 9)
	
	shl cx, 8 ;shift the desired precision mode into the correct position
	or ax, cx ;set the new precision mode bits
	mov [rsp], ax ;store the modified control word back on the stack
	fldcw [rsp] ;load the modified control word into the x87 FPU
	add rsp, 8
	fwait ; wait for the FPU to complete the control word update
	ret
SetX87Precision endp

GetX87Rounding proc
	sub rsp, 8
	fnstcw [rsp] ;store the control world on stack
	movzx rax, word ptr [rsp]
	and ax, 0C00h ;mask out all bits except the rounding control bits (bits 10 and 11)
	shr ax, 10 ;shift the rounding control bits down to the least significant bits
	add rsp, 8
	ret
GetX87Rounding endp

GetX87Precision proc
	sub rsp, 8
	fnstcw [rsp] ;store the control world on stack
	movzx rax, word ptr [rsp]
	and ax, 0300h ;mask out all bits except the rounding control bits (bits 10 and 11)
	shr ax, 8 ;shift the rounding control bits down to the least significant bits
	add rsp, 8
	ret
GetX87Precision endp

GetX87Errors proc
	fwait
	fnstsw ax
	and rax, 3Fh
	ret

GetX87Errors endp

ClearX87Errors proc
	fnclex
	fwait
	ret
ClearX87Errors endp

ED_FromDouble proc
	movsd qword ptr [rsp+8], xmm0 ; load the double from memory into st(0)
	fld qword ptr [rsp+8] ; load the double into st(0)

	fstp tbyte ptr [rdx] ; store the value from st(0) into memory as an extended double and pop st(0)
	ret
ED_FromDouble endp

ED_ToDouble proc
	fld tbyte ptr [rcx] ; load the extended double from memory into st(0)
	fstp qword ptr [rsp+8] ; store the value from st(0) into memory as a double and pop st(0)
	movsd xmm0, qword ptr [rsp+8] ; load the double from memory into xmm0
	ret
ED_ToDouble endp

ED_ToString proc
	push r13
	push r14
	push r12
	mov r13, [rcx] ; load the extended double from memory into rax
	mov bx, [rcx+8]
	mov r9, 45
	test bx, 8000h ; check the least significant bit of bx to determine if the number is negative
	jz positive
	mov [rdx], r9b ; write the sign of the number to the output string (e.g., ' ' for positive, '-' for negative)
	inc rdx
	dec r8
	;add r9, 13
	positive:
	test r8, r8 ; check if the output buffer is large enough to hold the string representation
	jz end_p

	and bx, 7FFFh ; clear the sign bit of bx to get the exponent
	sub bx, 16382 ; adjust the exponent by subtracting the bias (16383 for extended double)
	mov rax, r13 ; move the significand into rax for manipulation
	xor r13, r13 ; clear r13 to use it as a temporary register for shifting
	cmp bx, 0
	je preloop ; if the exponent is zero, we can skip the shifting and go directly to the loop
	

	cmp bx, -63
	jg sec_check ; if the exponent is greater than -64, we need to shift the significand to get the correct value
	xor rax, rax
	mov r13, rax
	jmp preloop

	sec_check:

	movsx rbx, bx ; sign-extend the exponent to 64 bits for comparison
	cmp bx, 63
	jl bx_calc ; if the exponent is less than 64, we need to shift the significand to get the correct value
	mov r13, 66
	mov [rdx], r13b 
	jmp end_p



	bx_calc:
	cmp bx, 0
	jl negative_exponent
        mov cl, bl
		xor r13, r13

        shld r13, rax, cl    ; Przesuwamy bity w lewo o wyk�adnik
		shl rax, cl
		jmp preloop
    negative_exponent:
        neg bx
        mov cl, bl
		;mov rax, r13
		xor r13, r13 
        shrd rax, r13, cl    ; Przesuwamy bity w prawo (robimy miejsce)
		shr r13, cl
		;mov rax, 0

	preloop:
	push rax;1
	mov rax, r13
	xor r14, r14
	mov r12, 10
	mov r11, rdx

	loop1:
		xor rdx, rdx ; clear rdx to prepare for the division	xor rdx, rdx
		div r12 ; divide rax by 10 to get the next digit
		push rdx ; push the remainder (the next digit) onto the stack 1+r14
		inc r14 ; increment the digit count
		test rax, rax ; check if rax is zero, which means we have processed all digits
		jnz loop1 ; if rax is not zero, continue the loop to process the next digit

	;inc r14

	loop3:
		pop rdx ; pop the next digit from the stack [1+r14 - r14] or [1+r14 - x]
		dec r14 ; decrement the digit count
		add rdx, 48 ; convert the digit to its ASCII character representation
		test r8, r8 ; check if the output buffer is large enough to hold the string representation
		jz endloop1
		mov [r11], dl ; write the digit as a character to the output string
		dec r8
		inc r11
		test r14, r14 ; check if there are more digits to process (if the stack is not empty)
		jnz loop3 ; if there are more digits, continue the loop
	;test r13, r13
	;jnz end_p
	;push rax
	;mov rax, r13

	endloop1:

	loop4:
		test r14,r14 ; check if there are more digits to process (if the stack is not empty)
		jz preloop2 ; if rax is not zero, continue the loop to process the next digit
		pop rdx ; pop the next digit from the stack
		dec r14
		jmp loop4 ; if there are more digits, continue the loop

	preloop2:
	pop rax
	mov r13, 46
	mov [r11], r13 ; write the decimal point character to the output string
	inc r11
	dec r8

	loop2:
		xor rdx, rdx ; clear rdx to prepare for the divisionxo
		mul r12 ; multiply rax by 10 to shift the digits to the left
		;shrd rdx, rax, 3 ; shift the most significant digit into rdx
		test r8, r8 ; check if the output buffer is large enough to hold the string representation
		jz end_p
		
		add rdx, 48 ; convert the least significant digit to a character
		mov [r11], dl ; write the least significant digit as a character to the output string
		dec r8
		inc r11
		jmp loop2 ; repeat the process until all digits have been processed
	
	
	end_p:
	;pop rax
	pop r12
	pop r14
	pop r13
	ret
ED_ToString endp

ED_ToStringBCD proc
	push r12
	push r13
	sub rsp, 128

	push rcx
	mov rcx, 3
	call SetX87Rounding
	pop rcx

	fld tbyte ptr [rcx]
	fld st(0)
	fbstp tbyte ptr [rsp+32]

	fbld tbyte ptr [rsp+32]
	fsubp st(1), st(0)
	 ; TODO wypisz znak i część całkowitą
	mov r11b, byte ptr [rcx+9]
	test r11b, 80h
	jz positive2

	mov r10b, 45 ; - sign
	mov [rdx], r10b
	inc rdx
	dec r8
	jz fines2

	positive2:
	xor r12, r12
	xor r13, r13
	write_loop1:
		mov al, byte ptr [rsp+r12+40]	;xxab
		dec r12

		shl ax, 4						;xab0
		shr al, 4						;xa0b
		and ax, 0F0Fh					;0a0b
		or ax, 3030h	

		test r13, r13
		jnz write_ah

		cmp ah, '0'
		je al_
		mov r13, 1				;set registers
		jmp write_ah

		al_:
		cmp al, '0'
		jne point
		cmp r12, -8
		jge write_loop1
		;jmp next_part
		point:
		mov r13, 1
		jmp write_al

		write_ah:
			mov [rdx], ah
			inc rdx
			dec r8
			jz fines2

		write_al:
			mov [rdx], al
			inc rdx
			dec r8
			jz fines2

		cmp r12, -8
		jge write_loop1

	test r13, r13
	jnz next_part

	mov al, '0'
	mov [rdx], al
	inc rdx
	dec r8
	jz fines2
	next_part:
	mov al, '.'
	mov [rdx], al
	inc rdx
	dec r8
	jz fines2



	mov r10, 10
	push r10
	fild qword ptr [rsp]	;mov 10 onto the stack
	pop r10
	fxch st(1)
	mov r10, 18
	loop5:
		fmul st(0), st(1)
		dec r10
		jnz loop5

	fld st(0)
	fbstp tbyte ptr [rsp+32] 
	fbld tbyte ptr [rsp+32]
	fsubp st(1), st(0)
		; TODO wypisz część po przecinku, 18 cyfr

	xor r12, r12
	xor r13, r13
	write_loop2:
		mov al, byte ptr [rsp+r12+40]	;xxab
		dec r12

		shl ax, 4						;xab0
		shr al, 4						;xa0b
		and ax, 0F0Fh					;0a0b
		or ax, 3030h	

		write_ah2:
			mov [rdx], ah
			inc rdx
			dec r8
			jz fines3

		write_al2:
			mov [rdx], al
			inc rdx
			dec r8
			jz fines3

		cmp r12, -8
		jge write_loop2

	mov r10, 18
	loop6:
		fmul st(0), st(1)
		dec r10
		jnz loop6

	fbstp tbyte ptr [rsp+32] 

	xor r12, r12
	xor r13, r13
	write_loop3:
		mov al, byte ptr [rsp+r12+40]	;xxab
		dec r12

		shl ax, 4						;xab0
		shr al, 4						;xa0b
		and ax, 0F0Fh					;0a0b
		or ax, 3030h	

		write_ah3:
			mov [rdx], ah
			inc rdx
			dec r8
			jz fines2

		write_al3:
			mov [rdx], al
			inc rdx
			dec r8
			jz fines2

		cmp r12, -8
		jge write_loop3
	;fstp st(0)
		; TODO wypisz pozostałą część po przecinku

	fines2:
	
	;fstp st(0)
	fstp st(0)
	mov rcx, 0
	call SetX87Rounding
	add rsp,128
	pop r13
	pop r12
	ret

	fines3:
	fstp st(0)
	jmp fines2

ED_ToStringBCD endp

ED_ToStringScientific proc
    push rbp
    mov rbp, rsp
	cld
    ; Alokujemy 112 bajtów (wielokrotność 16), zapewniając brak nakładania się zmiennych
    sub rsp, 112     
	push rcx
	mov rcx, 3
	call SetX87Rounding
	pop rcx
	
	cmp r8, 9
	jl end_p
    
    cmp r8, 27
	jle continue
	mov r8, 27

	continue:
    ;jl end_p

    ; --- 1. SPRAWDZENIE CZY LICZBA TO ZERO ---
    mov rax, qword ptr [rcx]     ; Dolne 8 bajtów mantysy
    movzx r10d, word ptr [rcx+8] ; 2 bajty wykładnika
    and r10d, 7FFFh              ; Maskujemy bit znaku
    mov r11, rax
    or r11, r10                  ; Jeśli mantysa i wykładnik == 0, liczba to 0.0
    jnz not_zero
    
force_zero:                      ; Awaryjny skok dla liczb zbyt bliskich zeru oraz dla 0.0
    ; Na wejściu:
    ; rdx = aktualny adres w buforze (jeśli liczba była ujemna, '-' już tam jest i rdx jest przesunięty!)
    ; r8  = aktualna wartość limitu znaków/precyzji

    mov rcx, r8
    sub rcx, 6                   ; rcx = łączna liczba znaków przed 'E' (mantysa wraz z kropką)

    ; 1. Wpisujemy początek znormalizowanej mantysy: "0." (zajmuje dokładnie 2 znaki)
    mov byte ptr [rdx], '0'
    mov byte ptr [rdx+1], '.'
    add rdx, 2

    ; 2. Obliczamy ile zer musimy dopisać po kropce
    sub rcx, 2                   ; Odejmujemy 2 znaki, które przed chwilą wpisaliśmy ("0.")
    jle append_exponent          ; Zabezpieczenie, jeśli rcx spadłby do zera (dla bardzo małych r8)

zero_mantissa_loop:
    mov byte ptr [rdx], '0'      ; Dopisujemy kolejne zera po kropce
    inc rdx
    dec rcx
    jnz zero_mantissa_loop

append_exponent:
    ; 3. Dopisujemy idealnie dopasowaną końcówkę wykładnika oraz terminator NULL
    mov byte ptr [rdx], 'E'
    mov byte ptr [rdx+1], '+'
    mov byte ptr [rdx+2], '0'
    mov byte ptr [rdx+3], 0      ; Koniec stringa (\0)
    jmp end_p

not_zero:
    ; --- 2. OBSŁUGA ZNAKU LICZBY ---
    fld tbyte ptr [rcx]          ; Ładujemy liczbę na FPU -> st(0) = liczba
    
    movzx r10d, word ptr [rcx+8] 
    test r10d, 8000h             ; Czy bit znaku jest ustawiony?
    jz positive
    
    ; Liczba ujemna: dopisujemy '-' i robimy wartość bezwzględną
    mov byte ptr [rdx], '-'
    inc rdx
    dec r8
    fabs                         ; st(0) = |liczba|

positive:
    ; Zapisujemy czystą dodatnią liczbę do [rbp-40]
    fstp tbyte ptr [rbp-40]      ; Zdejmujemy z FPU -> STOS JEST PUSTY

    ; --- 3. WYCIĄGNIĘCIE WYKŁADNIKA DZIESIĘTNEGO ---
    fstcw [rbp-8]
    mov ax, [rbp-8]
    or ax, 0400h                 ; Włącz tryb Round Down (floor)
    and ax, 0F7FFh
    mov [rbp-16], ax
    fldcw [rbp-16]

    fldlg2                       ; st(0) = log10(2)
    fld tbyte ptr [rbp-40]      
    fyl2x                        ; st(0) = log10(|liczba|). STOS MA 1 ELEMENT.

    fld st(0)                    ; st(0) = log10, st(1) = log10. STOS MA 2 ELEMENTY.
    fistp qword ptr [rbp-24]     ; Zdejmuje st(0). [rbp-24] = wykładnik. STOS MA 1 ELEMENT.
    
    fldcw [rbp-8]                ; Przywracamy domyślny tryb FPU
    fstp st(0)                   ; Zdejmujemy ostatni element logarytmu. STOS JEST IDEALNIE PUSTY!

    ; --- ZABEZPIECZENIE ANTY-FREEZE ---
    ; Sprawdzamy, czy FPU dla liczby bliskiej zera nie zwróciło błędu -inf (Integer Indefinite)
    mov rax, [rbp-24]
    mov r11, 8000000000000000h   ; Bitowy wzorzec błędu rzutowania dla fistp
    cmp rax, r11
    je force_zero                ; Jeśli to podpróg zera, natychmiast uciekamy do "0.0E+0"

    ; Przygotowujemy stałą 10 w pamięci RAM na stosie
    mov qword ptr [rbp-88], 10

    ; --- 4. FAZA 2: SKALOWANIE ORYGINALNEJ LICZBY ---
    fld tbyte ptr [rbp-40]      ; Ładujemy ORYGINALNĄ dodatnią liczbę -> STOS MA 1 ELEMENT
    
    mov rcx, [rbp-24]           ; RCX = nasz wykładnik dziesiętny E
    test rcx, rcx
    jz scale_validate           ; Jeśli E == 0, liczba jest już w przedziale [1, 10)
    jns scale_down              ; Jeśli E > 0, musimy ją zmniejszyć (dzielić przez 10)

    ; Jeśli E < 0, musimy ją zwiększyć (mnożyć przez 10)
    neg rcx                     ; Zmieniamy znak na dodatni do pętli
scale_up_loop:
    fild qword ptr [rbp-88]     ; st(0) = 10.0, st(1) = liczba
    fmulp st(1), st(0)          ; st(0) = liczba * 10
    dec rcx
    jnz scale_up_loop
    jmp scale_validate

scale_down:
scale_down_loop:
    fild qword ptr [rbp-88]     ; st(0) = 10.0, st(1) = liczba
    fdivp st(1), st(0)          ; st(0) = liczba / 10
    dec rcx
    jnz scale_down_loop

scale_validate:
    ; --- PANCERNA WALIDACJA GRANICZNA ---
    ; Sprawdzamy bezpiecznie na FPU za pomocą fcomi, czy mantysa nie uciekła do 10.0
    fild qword ptr [rbp-88]     ; st(0) = 10.0, st(1) = nasza_mantysa
    fcomi st(0), st(1)          ; Porównaj 10.0 z mantysą
    fstp st(0)                  ; Zdejmij 10.0 ze stosu
    ja scale_too_small          ; Jeśli 10.0 > mantysa, to jest ok, sprawdź dół

    ; Jeśli mantysa >= 10.0 (naprawiamy błąd zaokrąglenia logarytmu)
    fild qword ptr [rbp-88]
    fdivp st(1), st(0)          ; Dzielimy mantysę przez 10
    inc qword ptr [rbp-24]      ; Zwiększamy wykładnik o 1
    jmp scale_done

scale_too_small:
    ; Sprawdzamy, czy mantysa nie spadła poniżej 1.0
    fld1                        ; st(0) = 1.0, st(1) = nasza_mantysa
    fcomi st(0), st(1)          ; Porównaj 1.0 z mantysą
    fstp st(0)                  ; Zdejmij 1.0
    jbe scale_done               ; Jeśli 1.0 < mantysa, przedział [1, 10) jest zachowany

    ; Jeśli mantysa < 1.0 (rzadki przypadek graniczny)
    fild qword ptr [rbp-88]
    fmulp st(1), st(0)          ; Mnożymy mantysę przez 10
    dec qword ptr [rbp-24]      ; Zmniejszamy wykładnik o 1

scale_done:
    ; W tym momencie na stosie FPU znajduje się dokładnie JEDEN element (idealna mantysa)
    ; Zapisujemy ją pod [rbp-40], co czyści FPU do zera przed wejściem do BCD
    fstp tbyte ptr [rbp-40]     ; STOS FPU JEST IDEALNIE PUSTY

    ; --- 5. BEZPIECZNE WYWOŁANIE BCD ---
    mov [rbp-48], rdx            
    mov [rbp-56], r8             

    lea rcx, [rbp-40]            
    sub r8, 6                   
    call ED_ToStringBCD     

    ; Odzyskujemy wskaźniki bufora tekstowego
    mov rcx, [rbp-48]
	mov r8, [rbp-56]
	sub r8, 6	
    add rcx, r8                  ; BCD wpisało dokładnie 20 znaków

    ; Dopisujemy 'E'
    mov byte ptr [rcx], 'E' 
    inc rcx

    ; --- 6. WPISYWANIE WYKŁADNIKA DZIESIĘTNEGO ---
    mov rax, [rbp-24]            
    
    test rax, rax
    jns exp_positive
    
    mov byte ptr [rcx], '-'
    inc rcx
    neg rax                      ; Zamieniamy wykładnik na dodatni do wyświetlenia
    jmp prep_div

exp_positive:
    mov byte ptr [rcx], '+'
    inc rcx

prep_div:
    mov r8, rcx                  ; R8 = nasz aktywny wskaźnik w buforze głównym
    lea r9, [rbp-64]             ; R9 = bezpieczny dół bufora na cyfry wykładnika
    mov r10, 10                  
    xor r11, r11                 

div_loop:
    xor rdx, rdx            
    div r10                      
    add dl, '0'              
    dec r9
    mov [r9], dl                 
    inc r11
    test rax, rax
    jnz div_loop            

copy_exp_loop:
    mov al, [r9]
    mov [r8], al                 
    inc r9
    inc r8
    dec r11
    jnz copy_exp_loop

    ; --- 7. ZAMKNIĘCIE STRINGA ---
    mov byte ptr [r8], 0         

end_p:
	mov rcx, 0
	call SetX87Rounding
    mov rsp, rbp
    pop rbp
    ret
ED_ToStringScientific endp

ED_FromString proc
	sub rsp, 102
	push rbx
	push rsi
	push rdi


;	int 3
	xor r9,r9
	mov r11b, byte ptr [rdx]
	cmp r11b, '-' ; check the sign of the number
	jnz @F
	dec r8
	inc rdx
	inc r9
	@@:

	mov rsi, 36
	cmp r8, rsi
	cmova r8, rsi
	mov rbx, rcx


	cld
	lea rdi, [rsp+32+24]
	xor rax, rax
	mov rcx, 8
	rep stosq

	lea rdi, [rdx+r8-1]	; get the dot position in the string
	mov r10, rdi
	mov al, '.'
	mov rcx, r8
	std
	repne scasb
	cld
	;mov r11, rcx
	je found
	mov rcx, r8
	dec rcx
	;inc r8
	found:
	mov r11, r8
	sub r11, rcx
	dec r11
	dec r11



	mov rcx, r8
	dec rcx
	lea rsi, [rdx+r8-2]	; get the last character of the string]
	lea rdi, [rsp+32+24]
copy_loop:
	test rcx, rcx
	je end_copy
	mov al, byte ptr [rsi]
	dec rsi
	cmp al, '.'
	je skip_char

	stosb
	dec rcx
	jnz copy_loop
	jmp end_copy
	
	skip_char:
		dec rcx
		jnz copy_loop

	end_copy:
;	int 3
	lea rsi, [rsp+32+24]
	mov rdi, rsi
	mov rcx, 9
modify_loop:
	lodsw
	;test al, al
	;je end_modify
	and ax, 0F0Fh
	shl ah, 4
	or al, ah
	stosb
	loop modify_loop

	end_modify:
	;fbld tbyte ptr [rsp+32+24+10]
	fbld tbyte ptr [rsp+32+24]
	fld tbyte ptr [const_10]

	mov rcx, r11
	loop1:
		test rcx, rcx
		je end_loop1
		fdiv st(1), st(0)
		dec rcx
		jnz loop1
	end_loop1:
	fstp st(0)

	lea rsi, [rsp+32+24+18]
	mov rdi, rsi
	mov rcx, 9
modify_loop2:
	lodsw
;	test al, al
;	je end_modify2
	and ax, 0F0Fh
	shl ah, 4
	or al, ah
	stosb
	loop modify_loop2
	end_modify2:
	;fbld tbyte ptr [rsp+32+24+10]
	fbld tbyte ptr [rsp+32+24+18]
	fld tbyte ptr [const_10]

	mov rcx, r11
	sub rcx, 18
	
	test rcx, rcx
	js pre_loop2_neg
	loop2:
		test rcx, rcx
		je end_loop3
		fdiv st(1), st(0)
		dec rcx
		jnz loop2
	;end_loop2:
	jmp end_loop3

	pre_loop2_neg:
	neg rcx
	loop2_neg:
		test rcx, rcx
		je end_loop3
		fmul st(1), st(0)
		dec rcx
		jnz loop2_neg
	end_loop3:
	fstp st(0)
    faddp
	cmp r9, 1
	jnz positive2
	fchs
	positive2:
	fstp tbyte ptr [rbx] ; store the result back to memory and pop st(0)
	pop rdi
	pop rsi
	pop rbx
	add rsp, 102
	ret


ED_FromString endp

ED_ToBinaryScientificString proc
	mov r13, [rcx] ; load the extended double from memory into rax
	mov bx, [rcx+8]
	mov r9, 45
	test bx, 8000h ; check the least significant bit of bx to determine if the number is negative
	jz positive
	mov [rdx], r9b ; write the sign of the number to the output string (e.g., ' ' for positive, '-' for negative)
	inc rdx
	dec r8
	;add r9, 13
	positive:
	test r8, r8 ; check if the output buffer is large enough to hold the string representation
	jz end_p

	and bx, 7FFFh ; clear the sign bit of bx to get the exponent
	sub bx, 16382 ; adjust the exponent by subtracting the bias (16383 for extended double)
	mov rax, r13 ; move the significand into rax for manipulation
	mov r14, rbx
	xor bx,bx
	xor r13, r13 ; clear r13 to use it as a temporary register for shifting
	cmp bx, 0
	je preloop ; if the exponent is zero, we can skip the shifting and go directly to the loop
	





	bx_calc:
	cmp bx, 0
	jl negative_exponent
        mov cl, bl
		xor r13, r13

        shld r13, rax, cl    ; Przesuwamy bity w lewo o wyk�adnik
		shl rax, cl
		jmp preloop
    negative_exponent:
        neg bx
        mov cl, bl
		;mov rax, r13
		xor r13, r13 
        shrd rax, r13, cl    ; Przesuwamy bity w prawo (robimy miejsce)
		shr r13, cl
		;mov rax, 0

	preloop:

	push rax;1
	mov rax, r13
	xor r14, r14
	mov r12, 10
	mov r11, rdx

	loop1:
		xor rdx, rdx ; clear rdx to prepare for the division	xor rdx, rdx
		div r12 ; divide rax by 10 to get the next digit
		push rdx ; push the remainder (the next digit) onto the stack 1+r14
		inc r14 ; increment the digit count
		test rax, rax ; check if rax is zero, which means we have processed all digits
		jnz loop1 ; if rax is not zero, continue the loop to process the next digit

	;inc r14

	loop3:
		pop rdx ; pop the next digit from the stack [1+r14 - r14] or [1+r14 - x]
		dec r14 ; decrement the digit count
		add rdx, 48 ; convert the digit to its ASCII character representation
		test r8, r8 ; check if the output buffer is large enough to hold the string representation
		jz endloop1
		mov [r11], dl ; write the digit as a character to the output string
		dec r8
		inc r11
		test r14, r14 ; check if there are more digits to process (if the stack is not empty)
		jnz loop3 ; if there are more digits, continue the loop
	;test r13, r13
	;jnz end_p
	;push rax
	;mov rax, r13

	endloop1:

	loop4:
		test r14,r14 ; check if there are more digits to process (if the stack is not empty)
		jz preloop2 ; if rax is not zero, continue the loop to process the next digit
		pop rdx ; pop the next digit from the stack
		dec r14
		jmp loop4 ; if there are more digits, continue the loop

	preloop2:
    pop rax
    mov r13, 46
    mov [r11], r13 ; zapisz kropkę '.'
    inc r11
    dec r8

    ; --- NASZA APTECZNA POPRAWKA: LICZNIK BEZPIECZEŃSTWA ---
    mov r13, 25    ; Maksymalna liczba cyfr po przecinku. Zapobiegnie nieskończonej pętli!

    loop2:
        dec r13    ; Zmniejsz licznik cyfr w każdej iteracji
        jz end_p   ; Jeśli zrobiliśmy już 25 cyfr, uciekaj z pętli – uratowało nas przed zawieszeniem!

        xor rdx, rdx 
        mul r12    ; rax * 10
        test r8, r8 
        jz end_p
        
        add rdx, 48 
        mov [r11], dl 
        dec r8
        inc r11
        jmp loop2
	
	end_p:

	;mov [r11]

	;pop rax
	ret


ED_ToBinaryScientificString endp

ED_NextMachine proc
	push rbx
	mov rax, qword ptr [rcx]
	mov bx, word ptr [rcx+8]
	test bx, 8000h
	jnz neg2

	inc rax
	jnc store
	mov rax, 8000000000000000h
	inc bx
	store:
	mov qword ptr [rdx], rax
	mov word ptr [rdx+8], bx
	pop rbx
	ret

	neg2:
		
	dec rax
	mov r8, 8000000000000000h
	test rax, r8
    jnz store2
	mov rax, 0FFFFFFFFFFFFFFFFh
	dec bx
	store2:
	mov qword ptr [rdx], rax
	mov word ptr [rdx+8], bx
	pop rbx
	ret


ED_NextMachine endp

ED_PrevMachine proc
	push rbx
	mov rax, qword ptr [rcx]
	mov bx, word ptr [rcx+8]

	; --- PRZYPADEK SZCZEGÓLNY: TEST NA CZYSTE ZERO (20 ZER W HEX) ---
	or rax, rax                 ; Sprawdź czy mantysa to 0
	jnz oryginalny_kod          ; Jeśli mantysa != 0, leć normalnie
	cmp bx, 0000h               ; Sprawdź czy wykładnik i znak to 0
	jnz oryginalny_kod          ; Jeśli wykładnik != 0, leć normalnie

	; Jeśli tu dotarliśmy, na wejściu było dokładnie 0.0
	mov rax, 1                  ; Ustaw najniższy bit mantysy
	mov bx, 8000h               ; Ustaw bit znaku na minus
	jmp store                   ; Skocz prosto do zapisu, omijając operacje dec/inc
	; ----------------------------------------------------------------
oryginalny_kod:

	test bx, 8000h
	jnz neg2
	
	dec rax
	mov r8, 8000000000000000h
	test rax, r8
    jnz store
	mov rax, 0FFFFFFFFFFFFFFFFh
	dec bx
	store:
	mov qword ptr [rdx], rax
	mov word ptr [rdx+8], bx
	pop rbx
	ret

	neg2:
	inc rax
	jnc store2
	mov rax, 8000000000000000h
	inc bx
	store2:
	mov qword ptr [rdx], rax
	mov word ptr [rdx+8], bx
	pop rbx
	ret


ED_PrevMachine endp

ED_Add proc
	fld tbyte ptr [rcx] ; load the first double into st(0)
	fld tbyte ptr [rdx] ; load the second double into st(0), pushing the first one to st(1)
	faddp st(1), st(0) ; add st(0) to st(1) and pop the result into st(0)
	fstp tbyte ptr [r8] ; store the result back to memory and pop st(0)
	ret
ED_Add endp

ED_Sub proc
	fld tbyte ptr [rcx] ; load the first double into st(0)
	fld tbyte ptr [rdx] ; load the second double into st(0), pushing the first one to st(1)
	fsubp st(1), st(0) ; add st(0) to st(1) and pop the result into st(0)
	fstp tbyte ptr [r8] ; store the result back to memory and pop st(0)
	ret
ED_Sub endp

ED_Mul proc
	fld tbyte ptr [rcx] ; load the first double into st(0)
	fld tbyte ptr [rdx] ; load the second double into st(0), pushing the first one to st(1)
	fmulp st(1), st(0) ; multiply st(0) by st(1) and pop the result into st(0)
	fstp tbyte ptr [r8] ; store the result back to memory and pop st(0)
	ret
ED_Mul endp

ED_Div proc
	fld tbyte ptr [rcx] ; load the first double into st(0)
	fld tbyte ptr [rdx] ; load the second double into st(0), pushing the first one to st(1)
;	fwait
	fdivp st(1), st(0) ; divide st(1) by st(0) and pop the result into st(0)
	fstp tbyte ptr [r8] ; store the result back to memory and pop st(0)
	ret
ED_Div endp

ED_Mod proc
	fld tbyte ptr [rdx] ; load the first double into st(0)
	fld tbyte ptr [rcx] ; load the second double into st(0), pushing the first one to st(1)

	loop_mod:
		fprem1
		fstsw ax
		sahf
		jp loop_mod ; if the result is not yet the correct remainder, repeat the process

	fstp tbyte ptr [r8] ; store the result back to memory and pop st(0)
	fstp st(0)
	ret

ED_Mod endp


ED_Div_Mod proc
	fld tbyte ptr [rdx] ; load the first double into st(0)
	fld tbyte ptr [rcx] ; load the second double into st(0), pushing the first one to st(1)
	

	sub rsp,8
	loop_mod:
		fprem1
		fstsw ax
		fwait
		sahf
		jp loop_mod ; if the result is not yet the correct remainder, repeat the process

	fstp tbyte ptr [r9] ; store the result back to memory and pop st(0)
	fld tbyte ptr [rcx] 
	;fld st(0)
	fdivrp; divide st(1) by st(0) and pop the result into st(0)
	fstp tbyte ptr [r8] ; store the result back to memory and pop st(0)
	add rsp,8
	ret

ED_Div_Mod endp

ED_Sqrt proc
	fld tbyte ptr [rcx] ; load the double into st(
	fsqrt ; compute the square root of st(0) and store the result back in st(0)
	fstp tbyte ptr [rdx] ; store the result back to memory and pop st(0)
	ret
ED_Sqrt endp

ED_Abs proc
	fld tbyte ptr [rcx] ; load the double into st(0)
	fabs ; compute the absolute value of st(0) and store the result back in st(0)
	fstp tbyte ptr [rdx] ; store the result back to memory and pop st(0)
	ret
ED_Abs endp

ED_Floor proc
	sub rsp,8
	fstcw [rsp]		
	fld tbyte ptr [rcx]
	mov rcx, 1
	call SetX87Rounding

	frndint

	fstp tbyte ptr [rdx]
	fldcw [rsp]
	add rsp,8
	ret
ED_Floor endp

ED_Ceil proc
	sub rsp,8
	fstcw [rsp]		
	fld tbyte ptr [rcx]
	mov rcx, 2
	call SetX87Rounding

	frndint

	fstp tbyte ptr [rdx]
	fldcw [rsp]
	add rsp,8
	ret
ED_Ceil endp

ED_Log proc
	fldln2 ; load the constant log(2) into st(0)
	fld tbyte ptr [rcx] ; load the double into st(0)
	fyl2x ; compute the logarithm base 2 of st(0) and store the result back in st(0)
	fstp tbyte ptr [rdx] ; store the result back to memory and pop st(0)
	ret
ED_Log endp

ED_Log2 proc
	fld1 ; load the constant log(2) into st(0)
	fld tbyte ptr [rcx] ; load the double into st(0)
	fyl2x ; compute the logarithm base 2 of st(0) and store the result back in st(0)
	fstp tbyte ptr [rdx] ; store the result back to memory and pop st(0)
	ret
ED_Log2 endp

ED_Log10 proc
	fldlg2 ; load the constant log(2) into st(0)
	fld tbyte ptr [rcx] ; load the double into st(0)
	fyl2x ; compute the logarithm base 2 of st(0) and store the result back in st(0)
	fstp tbyte ptr [rdx] ; store the result back to memory and pop st(0)
	ret
ED_Log10 endp

ED_LogN proc
	sub rsp, 24

	fnstcw word ptr [rsp]
	mov ax, word ptr [rsp]
	and ax, 0F3FFh
	mov [rsp+2], ax
	fldcw word ptr [rsp+2]		;temporarily set the rounding to the nearest
	fwait

	fld1												; 1
	fld tbyte ptr [rcx] ; load second number into st(1)	; [rdx], 1
	fyl2x ; compute the logarithm of the base 2 of n	; log2[rdx]			
	fld1; 1/log2[rdx]
	fld tbyte ptr [rdx] ; load the double into st(0)	;
	fyl2x ; compute the logarithm base 2 of st(0) and store the result back in st(0)

	fldcw word ptr [rsp]		;return the rounding mode before division
	fwait
	fdivp st(1), st(0)
	fstp tbyte ptr [r8] ; store the result back to memory and pop st(0)
	add rsp, 24
	ret
ED_LogN endp

ED_Exp2 proc
	fld tbyte ptr [rcx] ; load the double into st(0)
	fld st(0) ; duplicate the value in st(0) to st(1) for later use
	frndint
	fsub st(1), st(0) ; compute the fractional part of the original value and store it in st(0)
	fxch
	f2xm1 ; compute 2^(st(0)) - 1 and store the result back in st(0)
	fld1 ; load the constant 1 into st(0), pushing the result of f2xm1 to st(1)
	faddp st(1), st(0) ; add st(0) to st(1) to get 2^(original value) and pop the result into st(0)
	fscale ; scale st(0) by 2^(integer part of original value) to get the final result
	fstp tbyte ptr [rdx] ; store the result back to memory and pop st(0)
	fstp st(0)
	ret
ED_Exp2 endp

ED_Exp proc
	fld tbyte ptr [rcx] ; load the double into st(0)
	fldl2e ; load the constant log(2) into st(0), pushing the original value to st(1)
	fmulp
	fld st(0) ; duplicate the value in st(0) to st(1) for later use
	frndint
	fsub st(1), st(0) ; compute the fractional part of the original value and store it in st(0)
	fxch
	f2xm1 ; compute 2^(st(0)) - 1 and store the result back in st(0)
	fld1 ; load the constant 1 into st(0), pushing the result of f2xm1 to st(1)
	faddp st(1), st(0) ; add st(0) to st(1) to get 2^(original value) and pop the result into st(0)
	fscale ; scale st(0) by 2^(integer part of original value) to get the final result
	fstp tbyte ptr [rdx] ; store the result back to memory and pop st(0)
	fstp st(0)
	ret
ED_Exp endp

ED_Exp10 proc
	fld tbyte ptr [rcx] ; load the double into st(0)
	fldl2t ; load the constant log(2) into st(0), pushing the original value to st(1)
	fmulp
	fld st(0) ; duplicate the value in st(0) to st(1) for later use
	frndint
	fsub st(1), st(0) ; compute the fractional part of the original value and store it in st(0)
	fxch
	f2xm1 ; compute 2^(st(0)) - 1 and store the result back in st(0)
	fld1 ; load the constant 1 into st(0), pushing the result of f2xm1 to st(1)
	faddp st(1), st(0) ; add st(0) to st(1) to get 2^(original value) and pop the result into st(0)
	fscale ; scale st(0) by 2^(integer part of original value) to get the final result
	fstp tbyte ptr [rdx] ; store the result back to memory and pop st(0)
	fstp st(0)
	ret
ED_Exp10 endp

ED_Pow proc
	push r12
	sub rsp, 72
	mov [rsp+56], rdx
	mov [rsp+48], r8
	lea rdx, [rsp+32] ; reserve space on the stack for the result of the logarithm calculation

	call ED_Log2 ; compute the logarithm base 2 of the base and store the result in r8
	mov r10, [rsp+48] ; move the result of the logarithm calculation into r8 for later use
	mov r11, [rsp+56] ; move the exponent into r9 for later use
	lea r12, [rsp+32] ; move the result of the logarithm calculation into r12 for later use]
	fld tbyte ptr [r11] ; load the exponent into st(0)] ; take the absolute value of the exponent to handle negative powers
	fld tbyte ptr [r12] ; load the result of the logarithm calculation into st(0)
	fmulp
	fld st(0) ; duplicate the value in st(0) to st(1) for later use
	frndint
	fsub st(1), st(0) ; compute the fractional part of the original value and store it in st(0)
	fxch
	f2xm1 ; compute 2^(st(0)) - 1 and store the result back in st(0)
	fld1 ; load the constant 1 into st(0), pushing the result of f2xm1 to st(1)
	faddp st(1), st(0) ; add st(0) to st(1) to get 2^(original value) and pop the result into st(0)
	fscale ; scale st(0) by 2^(integer part of original value) to get the final result
	fstp tbyte ptr [r10] ; store the result back to memory and pop st(0)
	fstp st(0)

	add rsp, 72
	
	pop r12
	ret
ED_Pow endp

ED_PowInt proc
	sub rsp, 16	

	fld tbyte ptr [rdx]
	fabs
	fisttp qword ptr [rsp]
	fld tbyte ptr [rcx]
	fld1
	mov r11, [rsp]
	loop5:
		test r11, r11
		jz fines
		fmul st(0), st(1)
		dec r11
		jmp loop5

	fines:
	mov r10b, byte ptr [rdx+9]
	test r10b, 80h
	jz fines2
	fld1
	fdivrp st(1), st(0)

	fines2:
	fstp tbyte ptr [r8]
	fstp st(0)

	add rsp, 16
	ret
ED_PowInt endp

ED_Sin proc
	fld tbyte ptr [rcx] ; load the double into st(0)
	fsin ; compute the sine of st(0) and store the result back in st(0)
	fstp tbyte ptr [rdx] ; store the result back to memory and pop st(0)
	ret
ED_Sin endp

ED_Cos proc
	fld tbyte ptr [rcx] ; load the double into st(0)
	fcos ; compute the cosine of st(0) and store the result back in st(0)
	fstp tbyte ptr [rdx] ; store the result back to memory and pop st(0)
	ret
ED_Cos endp

ED_Tan proc
	fld tbyte ptr [rcx] ; load the double into st(0)
	fptan ; compute the tangent of st(0) and store the result back in st(0)
	fstp st(0)
	fstp tbyte ptr [rdx] ; store the result back to memory and pop st(0)
 ; pop the extra value left by fptan
	ret
ED_Tan endp

ED_SinCos proc
    fld tbyte ptr [rcx]  ; załaduj kąt (radiany)
    fsincos              ; st(0) = cos, st(1) = sin
    fstp tbyte ptr [r8]  ; zapisz cos (r8 to trzeci argument w x64)
    fstp tbyte ptr [rdx] ; zapisz sin (rdx to drugi argument)
    ret
ED_SinCos endp
END