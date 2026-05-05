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
	fnstsw ax
	and ax, 3Fh
	ret

GetX87Errors endp

ClearX87Errors proc
	fnclex
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
	sub rsp, 56

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
			jz fines2

		write_al2:
			mov [rdx], al
			inc rdx
			dec r8
			jz fines2

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
	add rsp,56
	pop r13
	pop r12
	ret

ED_ToStringBCD endp

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

	;mov [r11]

	;pop rax
	ret


ED_ToBinaryScientificString endp

ED_NextMachine proc
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
	ret


ED_NextMachine endp

ED_PrevMachine proc
	mov rax, qword ptr [rcx]
	mov bx, word ptr [rcx+8]
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
	ret

	neg2:
	inc rax
	jnc store2
	mov rax, 8000000000000000h
	inc bx
	store2:
	mov qword ptr [rdx], rax
	mov word ptr [rdx+8], bx
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