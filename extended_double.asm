.code
SetX87Rounding proc
	sub rsp, 8
	fnstcw [rsp] ;store the control world on stack

	mov ax, [rsp] ;load the control word into rax
	and ax, 0F3FFh ;clear the rounding control bits (bits 10 and 11)
	
	shl cx, 10 ;shift the desired rounding mode into the correct position
	or ax, cx ;set the new rounding mode bits

	mov [rsp], ax ;store the modified control word back on the stack
	fldcw [rsp] ;load the modified control word into the x87 FPU
	add rsp, 8
	ret
SetX87Rounding endp

GetX87Rounding proc
	sub rsp, 8
	fnstcw [rsp] ;store the control world on stack
	movzx rax, word ptr [rsp]
	and ax, 0C00h ;mask out all bits except the rounding control bits (bits 10 and 11)
	shr ax, 10 ;shift the rounding control bits down to the least significant bits
	add rsp, 8
	ret
GetX87Rounding endp

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
	mov rax, [rcx] ; load the extended double from memory into rax
	mov bx, [rcx+8]
	mov r9, 32
	test bx, 8000h ; check the least significant bit of bx to determine if the number is negative
	jz positive
	add r9, 13
	positive:
	mov [rdx], r9b ; write the sign of the number to the output string (e.g., ' ' for positive, '-' for negative)
	test r8, r8 ; check if the output buffer is large enough to hold the string representation
	jz end_p

	inc rdx
	dec r8

		; handle negative numbers if necessary (e.g., by setting a flag or adjusting the string
		

	;rol rax, 1 ; rotate the bits of rax to the left by 1 to prepare for conversion
	end_p:
	ret
ED_ToString endp

ED_Add proc
	fld tbyte ptr [rcx] ; load the first double into st(0)
	fld tbyte ptr [rdx] ; load the second double into st(0), pushing the first one to st(1)
	faddp st(1), st(0) ; add st(0) to st(1) and pop the result into st(0)
	fstp tbyte ptr [r8] ; store the result back to memory and pop st(0)
	ret
ED_Add endp



END