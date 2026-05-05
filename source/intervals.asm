.data
const_e TBYTE 4000adf85458a2bb4a9ah

.code
EXTERN SetX87Rounding : PROC 
EXTERN ED_Add : PROC
EXTERN ED_Sub : PROC
EXTERN ED_Mul : PROC
EXTERN ED_Log : PROC
EXTERN ED_Log2 : PROC
EXTERN ED_Log10 : PROC
EXTERN ED_LogN : PROC
EXTERN ED_Exp2 : PROC
EXTERN ED_Exp10 : PROC
EXTERN ED_Exp : PROC
EXTERN ED_Pow : PROC
EXTERN ED_PowInt : PROC
EXTERN ED_Sin : PROC
EXTERN ED_Cos : PROC
EXTERN ED_NextMachine : PROC
EXTERN ED_PrevMachine : PROC


Int_op3 proc
	sub rsp, 72
	mov [rsp+40], rcx
	mov [rsp+48], rdx
	mov [rsp+56], r8
	mov [rsp+64], r9
	mov rcx, 1
	call SetX87Rounding
	mov rcx, [rsp+40]
	mov rdx, [rsp+48]
	mov r8, [rsp+56]
	mov r9, [rsp+64]
	call qword ptr [rsp+112]
	mov rcx, 2
	call SetX87Rounding
	mov rcx, [rsp+40]
	mov rdx, [rsp+48]
	mov r8, [rsp+56]
	mov r9, [rsp+64]
	add rcx, 10
	add rdx, 10
	add r8, 10
	add r9, 10
	call qword ptr [rsp+112]	;strictly related to rsp offset
	mov rcx, 0
	call SetX87Rounding
	add rsp, 72		
	ret
Int_op3 endp

Int_op2 proc
	sub rsp, 72
	mov [rsp+40], rcx
	mov [rsp+48], rdx
	mov [rsp+56], r8
	mov [rsp+64], r9
	mov rcx, 1
	call SetX87Rounding
	mov rcx, [rsp+40]
	mov rdx, [rsp+48]
	mov r8, [rsp+56]
	call qword ptr [rsp+64]
	mov rcx, 2
	call SetX87Rounding
	mov rcx, [rsp+40]
	mov rdx, [rsp+48]
	mov r8, [rsp+56]
	add rcx, 10
	add rdx, 10
	add r8, 10
	call qword ptr [rsp+64]	;strictly related to rsp offset
	mov rcx, 0
	call SetX87Rounding
	add rsp, 72		
	ret
Int_op2 endp

Int_op1 proc
	sub rsp, 72
	mov [rsp+40], rcx
	mov [rsp+48], rdx
	mov [rsp+56], r8
	mov rcx, 1
	call SetX87Rounding
	mov rcx, [rsp+40]
	mov rdx, [rsp+48]
	call qword ptr [rsp+56]
	mov rcx, 2
	call SetX87Rounding
	mov rcx, [rsp+40]
	mov rdx, [rsp+48]
	add rcx, 10
	add rdx, 10
	call qword ptr [rsp+56]	;strictly related to rsp offset
	mov rcx, 0
	call SetX87Rounding
	add rsp, 72		
	ret
Int_op1 endp

Int_Width proc
	sub rsp, 40
	mov r8, rdx
	mov rdx, rcx
	lea rcx, [rdx+10]
	call ED_Sub
	add rsp, 40
	ret
Int_Width endp

Int_Avg proc
	push r12
	sub rsp, 32
	mov r8, rdx
	mov r12, rdx
	lea rdx, [rcx+10]
	call ED_Add
	
	fld1
	fchs
	fld tbyte ptr [r8]
	fscale
	fstp tbyte ptr [r8]
	fstp st(0)

	add rsp, 32
	pop r12
	ret
Int_Avg endp

Int_Intersect proc
	fld tbyte ptr [rcx]
	fld tbyte ptr [rdx]
	fcomi st(0), st(1)
	fcmovb st(0), st(1)
	fstp tbyte ptr [r8]
	fstp st(0)

	fld tbyte ptr [rcx+10]
	fld tbyte ptr [rdx+10]
	fcomi st(0), st(1)
	fcmovnb st, st(1)
	fstp tbyte ptr [r8+10]
	fstp st(0)

	fld tbyte ptr [r8]
	fld tbyte ptr [r8+10]
	fcomip st(0), st(1)
	fstp st(0)

	jnb end_p

	pxor xmm0, xmm0
	movups [r8], xmm0
	mov dword ptr [r8+16], 0
	end_p:

	ret

Int_Intersect endp

Int_IsSubset proc
    fld tbyte ptr [rdx]     ; b.low
    fld tbyte ptr [rcx]     ; a.low
    fcomip st(0), st(1)     ; czy a.low <= b.low?
    fstp st(0)              ; czyœcimy
    ja not_subset           ; jeœli a.low > b.low, to b wystaje w dó³

    fld tbyte ptr [rcx+10]  ; a.high
    fld tbyte ptr [rdx+10]  ; b.high
    fcomip st(0), st(1)     ; czy b.high <= a.high?
    fstp st(0)              ; czyœcimy
    ja not_subset           ; jeœli b.high > a.high, to b wystaje w górê

    mov rax, 1              ; Sukces!
    ret

not_subset:
    xor rax, rax            ; Pora¿ka!
    ret
Int_IsSubset endp

Int_Contains proc
    fld tbyte ptr [rdx]     ; b.low
    fld tbyte ptr [rcx]     ; a.low
    fcomip st(0), st(1)     ; czy a.low <= b.low?
    fstp st(0)              ; czyœcimy
    ja not_subset           ; jeœli a.low > b.low, to b wystaje w dó³

    fld tbyte ptr [rcx+10]  ; a.high
    fld tbyte ptr [rdx]  ; b.high
    fcomip st(0), st(1)     ; czy b.high <= a.high?
    fstp st(0)              ; czyœcimy
    ja not_subset           ; jeœli b.high > a.high, to b wystaje w górê

    mov rax, 1              ; Sukces!
    ret

not_subset:
    xor rax, rax            ; Pora¿ka!
    ret
Int_Contains endp

; TBYTE Int_Distance(interval* a, interval* b)
Int_Distance proc
    fld tbyte ptr [rcx]       ; a.low
    fld tbyte ptr [rcx+10]    ; a.high
    faddp st(1), st(0)        ; st(0) = a.low + a.high

    fld tbyte ptr [rdx]       ; b.low
    fld tbyte ptr [rdx+10]    ; b.high
    faddp st(1), st(0)        ; st(0) = b.low + b.high, st(1) = suma_a

    fsubp st(1), st(0)        ; st(0) = suma_a - suma_b
    fabs                      ; st(0) = |suma_a - suma_b|
    
    fld1                      ; ³adujemy 1
    fld1
    faddp st(1), st(0)        ; st(0) = 2.0
    fdivp st(1), st(0)        ; st(0) = dist (wynik koñcowy)
    
    ; Wynik zostaje na st(0) zgodnie z ABI dla typów zmiennoprzecinkowych
    ; lub zapisujesz do [r8] jeœli tak wolisz
    ret
Int_Distance endp

Int_GetLeft proc
	fld tbyte ptr [rcx]
	fstp tbyte ptr [rdx]
	ret
Int_GetLeft endp

Int_GetRight proc
	fld tbyte ptr [rcx+10]
	fstp tbyte ptr [rdx]
	ret
Int_GetRight endp

Int_PI proc
	push r12
	sub rsp, 40
    fldpi                  
    fldpi                  
	mov r12, rcx           ; Za³aduj sta³¹ pi z procesora (najbli¿sze przybli¿enie)
	fstp tbyte ptr [r12]  
	fstp tbyte ptr [r12+10]  
	;mov rcx, r12
	mov rdx, r12
	call ED_PrevMachine

	lea rcx, [r12+10]
	lea rdx, [r12+10]
	call ED_NextMachine
   ; Zapisz jako r.low
	
  ;  fstp tbyte ptr [r12+10] ; Zapisz jako r.high
	add rsp, 40
	pop r12
    ret
Int_PI endp

Int_E proc
	push r12
	sub rsp, 40
    fld tbyte ptr [const_e]      
    fld tbyte ptr [const_e]      
	mov r12, rcx           ; Za³aduj sta³¹ pi z procesora (najbli¿sze przybli¿enie)
	fstp tbyte ptr [r12]  
	fstp tbyte ptr [r12+10]  
	;mov rcx, r12
	mov rdx, r12
	call ED_PrevMachine

	lea rcx, [r12+10]
	lea rdx, [r12+10]
	call ED_NextMachine
   ; Zapisz jako r.low
	
  ;  fstp tbyte ptr [r12+10] ; Zapisz jako r.high
	add rsp, 40
	pop r12
    ret
Int_E endp

Int_LoadNum proc
	push r12
	sub rsp, 40
    fld tbyte ptr [rcx]      
    fld tbyte ptr [rcx]      
	mov r12, rdx           ; Za³aduj sta³¹ pi z procesora (najbli¿sze przybli¿enie)
	fstp tbyte ptr [r12]  
	fstp tbyte ptr [r12+10]  
	;mov rcx, r12
	mov rdx, r12
	call ED_PrevMachine

	lea rcx, [r12+10]
	lea rdx, [r12+10]
	call ED_NextMachine
   ; Zapisz jako r.low
	
  ;  fstp tbyte ptr [r12+10] ; Zapisz jako r.high
	add rsp, 40
	pop r12
    ret
Int_LoadNum endp


Int_Add proc
	sub rsp, 56
	mov r9, ED_Add
	call Int_op2
	add rsp, 56
	ret
Int_Add endp

Int_Sub proc
	sub rsp, 72

	fld tbyte ptr [rdx+10]
	fld tbyte ptr [rdx]
	fstp tbyte ptr [rsp+50]
	fstp tbyte ptr [rsp+40]
	mov [rsp+32], rdx
	lea rdx, [rsp+40] ; rcx and r8 are untouched and used as arguments for ED_Sub

	mov r9, ED_Sub
	call Int_op2

	add rsp, 72
	ret
Int_Sub endp

Int_Mul proc		;multiplies two intervals [a,b] * [c,d]
	push rbx
	sub rsp, 120
	mov [rsp+32], r8
	mov [rsp+40], rdx
	mov [rsp+48], rcx
	
	mov rbx, 0

multiplication:
	inc rbx
	mov rcx, rbx
	call SetX87Rounding

	mov rcx, [rsp+48]
	mov rdx, [rsp+40]
	lea r8, [rsp+66]	; ac
	call ED_Mul

	mov rcx, [rsp+48]
	mov rdx, [rsp+40]
	add rdx, 10
	lea r8, [rsp+76] ;ad
	call ED_Mul

	mov rcx, [rsp+48]
	mov rdx, [rsp+40]
	add rcx, 10
	lea r8, [rsp+86]
	call ED_Mul			;bc

	mov rcx, [rsp+48]
	mov rdx, [rsp+40]
	add rcx, 10
	add rdx, 10
	lea r8, [rsp+96]
	call ED_Mul		;bd

	fld tbyte ptr [rsp+66]
	fld st(0)
	fld tbyte ptr [rsp+76]
	fcomi ST(0), ST(1)
	fxch st(2)
	fcmovnb ST(0), ST(2) ; If ST(0) is greater than ST(1) then we store ST(0) in ST(2)
	fxch st(2)
	fxch st(1)
	fcmovb ST(0), ST(1)
	fxch st(1)
	
	fstp ST(0) ; we dont need the additional value

	fld tbyte ptr [rsp+86]
	fcomi ST(0), ST(1)
	fxch st(1)
	fcmovb ST(0), ST(1)
	fxch st(1)

	fcomi ST(0), ST(2)
	fxch st(2)
	fcmovnb st(0), ST(2)
	fxch st(2)

	fstp ST(0) ; we dont need the additional value

	fld tbyte ptr [rsp+96]
	fcomi ST(0), ST(1)
	fxch st(1)
	fcmovb ST(0), ST(1)
	fxch st(1)

	fcomi ST(0), ST(2)
	fxch st(2)
	fcmovnb st(0), ST(2)
	fxch st(2)

	;we get min in st(1) and max in st(2)
	fstp ST(0)
	mov r8, [rsp+32]
	lea r10, [rbx -1]
	imul r10, r10, 10
	
	cmp rbx, 2				; cmp sets the same bits as fcomi, so yeah
	fcmovnb st(0), st(1)
	fstp tbyte ptr [r8+r10]
	fstp st(0)

	jl multiplication

	;fstp tbyte ptr [r8+10]

	mov rcx, 0
	call SetX87Rounding
	add rsp, 120
	pop rbx
	ret
Int_Mul endp

Int_Div proc

	fldz					; checks for 0 in the divisor interval
	fld tbyte ptr [rdx]
	fcomip st(0), st(1)
	ja not_zero
	fld tbyte ptr [rdx+10]
	fcomip st(0), st(1)
	jb not_zero

	fstp st(0)
	sub rsp, 28                 
    fnstenv [rsp]               
    or word ptr [rsp+4], 4     
    fldenv [rsp]                
    add rsp, 28
	ret

not_zero:
	fstp st(0)			;calculating the division
	sub rsp, 88
	mov [rsp+52], rcx
	mov [rsp+60], r8
	mov [rsp+68], rdx
	fld1
	fld tbyte ptr [rdx]
	mov rcx, 2
	call SetX87Rounding
	fdivr st(0), st(1)
	mov rdx, [rsp+68]
	fstp tbyte ptr [rsp+42]
	fld tbyte ptr [rdx+10]

	mov rcx, 1
	call SetX87Rounding
	fdivr st(0), st(1)
	fstp tbyte ptr [rsp+32]
	lea rcx, [rsp+32]
	lea rdx, [rsp+32]
	call ED_PrevMachine

	lea rcx, [rsp+42]
	lea rdx, [rsp+42]
	call ED_NextMachine
	fstp st(0)

	mov rcx, [rsp+52]
	lea rdx, [rsp+32] ; we wont need the original rdx
	mov r8, [rsp+60]
	call Int_Mul
	add rsp, 88
	ret

Int_Div endp

Int_Sqrt proc
	fldz					; compares low to 0 for arithmetic exception
	fld tbyte ptr [rcx]
	fcomip st(0), st(1)
	fstp st(0)
	ja not_zero			
	;fstp st(0)
	sub rsp, 28                 
	fnstenv [rsp]               
	or word ptr [rsp+4], 1   
	fldenv [rsp]                
	add rsp, 28
	ret

	not_zero:
	push rbx
	sub rsp, 40
	fld tbyte ptr [rcx]
	fld tbyte ptr [rcx+10]
	mov rbx, rdx
	mov rcx, 2
	call SetX87Rounding
	fsqrt
	mov rdx, rbx
	fstp tbyte ptr [rdx+10]
	mov rcx, 1
	call SetX87Rounding
	fsqrt
	fstp tbyte ptr [rdx]
	mov rcx, 0
	call SetX87Rounding

	add rsp, 40
	pop rbx
	ret

Int_Sqrt endp

Int_Abs proc
	fld tbyte ptr [rcx]
	fabs
	fld tbyte ptr [rcx+10]
	fabs
	fld tbyte ptr [rcx]
	fld tbyte ptr [rcx+10]

	fchs
	fcomi st(0), st(1)
	fcmovnb st(0), st(1)		; If st(0) is greater than st(1) then we store st(0) in st(1)
	fldz
	fcomi st(0), st(1)
	fcmovnb st(0), st(1)		; If st(0) is greater than st(1) then we store st(0) in st(1)
	fstp tbyte ptr [rdx]
	fstp st(0)
	fstp st(0)
	fcomi st(0), st(1)
	fcmovnb st(0), st(1)	
	fstp tbyte ptr [rdx+10]
	fstp st(0)
	ret

Int_Abs endp

Int_Log proc
	
	fldz					; compares low to 0 for arithmetic exception
	fld tbyte ptr [rcx]
	fcomip st(0), st(1)
	ja not_zero			

	fstp st(0)
	sub rsp, 28                 
    fnstenv [rsp]               ;Set the error
    or word ptr [rsp+4], 1   
    fldenv [rsp]                
    add rsp, 28
	ret

not_zero:
	
	sub rsp, 56
	mov r8, ED_Log
	call Int_op1
	add rsp, 56
	ret
Int_Log endp

Int_Log2 proc
	
	fldz					; compares low to 0 for arithmetic exception
	fld tbyte ptr [rcx]
	fcomip st(0), st(1)
	ja not_zero			

	fstp st(0)
	sub rsp, 28                 
    fnstenv [rsp]               
    or word ptr [rsp+4], 1   
    fldenv [rsp]                
    add rsp, 28
	ret

not_zero:
	
	sub rsp, 56
	mov r8, ED_Log2
	call Int_op1
	add rsp, 56
	ret
Int_Log2 endp

Int_Log10 proc
	
	fldz					; compares low to 0 for arithmetic exception
	fld tbyte ptr [rcx]
	fcomip st(0), st(1)
	ja not_zero			

	fstp st(0)
	sub rsp, 28                 
    fnstenv [rsp]               
    or word ptr [rsp+4], 1   
    fldenv [rsp]                
    add rsp, 28
	ret

not_zero:
	
	sub rsp, 56
	mov r8, ED_Log10
	call Int_op1
	add rsp, 56
	ret
Int_Log10 endp

Int_LogN proc
	sub rsp, 152

	fldz					; compares low to 0 for arithmetic exception
	fld tbyte ptr [rcx]		; value test
	fcomip st(0), st(1)
	ja not_zero_value		

	fstp st(0)
	sub rsp, 28                 
    fnstenv [rsp]               
    or word ptr [rsp+4], 1   
    fldenv [rsp]                
    add rsp, 28
	add rsp, 152
	ret

not_zero_value:
	
	fld1  ; compares low to 0 for arithmetic exception
	fld tbyte ptr [rdx]		; base test
	fcomi st(0), st(2)		;low with zero
	jna error
	fcomi st(0), st(1)
	ja good
	fld tbyte ptr [rdx+10]	;high with one
	fcomip st(0), st(2)
	jb good



	error:
	fstp st(0)
	fstp st(0)
	fstp st(0)
	sub rsp, 28                 
    fnstenv [rsp]               
    or word ptr [rsp+4], 1   
    fldenv [rsp]                
    add rsp, 28
	add rsp, 152
	ret

	good:
	fstp st(0)
	fstp st(0)
	fstp st(0)

	push rbx
	mov [rsp+32], r8
	mov [rsp+40], rdx
	mov [rsp+48], rcx
	

	mov rbx, 0

logs:
	inc rbx
	mov rcx, rbx
	call SetX87Rounding

	mov rcx, [rsp+48]
	mov rdx, [rsp+40]
	lea r8, [rsp+66]	; ac
	call ED_LogN

	mov rcx, [rsp+48]
	mov rdx, [rsp+40]
	add rdx, 10
	lea r8, [rsp+76] ;ad
	call ED_LogN

	mov rcx, [rsp+48]
	mov rdx, [rsp+40]
	add rcx, 10
	lea r8, [rsp+86]
	call ED_LogN			;bc

	mov rcx, [rsp+48]
	mov rdx, [rsp+40]
	add rcx, 10
	add rdx, 10
	lea r8, [rsp+96]
	call ED_LogN		;bd

	fld tbyte ptr [rsp+66]
	fld st(0)
	fld tbyte ptr [rsp+76]
	fcomi ST(0), ST(1)
	fxch st(2)
	fcmovnb ST(0), ST(2) ; If ST(0) is greater than ST(1) then we store ST(0) in ST(2)
	fxch st(2)
	fxch st(1)
	fcmovb ST(0), ST(1)
	fxch st(1)
	
	fstp ST(0) ; we dont need the additional value

	fld tbyte ptr [rsp+86]
	fcomi ST(0), ST(1)
	fxch st(1)
	fcmovb ST(0), ST(1)
	fxch st(1)

	fcomi ST(0), ST(2)
	fxch st(2)
	fcmovnb st(0), ST(2)
	fxch st(2)

	fstp ST(0) ; we dont need the additional value

	fld tbyte ptr [rsp+96]
	fcomi ST(0), ST(1)
	fxch st(1)
	fcmovb ST(0), ST(1)
	fxch st(1)

	fcomi ST(0), ST(2)
	fxch st(2)
	fcmovnb st(0), ST(2)
	fxch st(2)

	;we get min in st(1) and max in st(2)
	fstp ST(0)
	mov r8, [rsp+32]
	lea r10, [rbx -1]
	imul r10, r10, 10
	
	cmp rbx, 2				; cmp sets the same bits as fcomi, so yeah
	fcmovnb st(0), st(1)
	fstp tbyte ptr [r8+r10]
	fstp st(0)

	jl logs

	pop rbx
	;fstp tbyte ptr [r8+10]

	mov rcx, 0
	call SetX87Rounding
	add rsp, 152
	ret
Int_LogN endp

Int_Exp2 proc
	sub rsp, 40
	mov r8, ED_Exp2
	call Int_op1
	add rsp, 40
	ret
Int_Exp2 endp

Int_Exp10 proc
	sub rsp, 40
	mov r8, ED_Exp10
	call Int_op1
	add rsp, 40
	ret
Int_Exp10 endp

Int_Exp proc
	sub rsp, 40
	mov r8, ED_Exp
	call Int_op1
	add rsp, 40
	ret
Int_Exp endp

Int_Pow proc		

	fldz					; compares low to 0 for arithmetic exception
	fld tbyte ptr [rcx]
	fcomip st(0), st(1)
	ja not_zero			

	fstp st(0)
	sub rsp, 28                 
    fnstenv [rsp]               
    or word ptr [rsp+4], 1   
    fldenv [rsp]                
    add rsp, 28
	ret

not_zero:	

	push rbx
	sub rsp, 120
	mov [rsp+32], r8
	mov [rsp+40], rdx
	mov [rsp+48], rcx
	
	mov rbx, 0

power:
	inc rbx
	mov rcx, rbx
	call SetX87Rounding

	mov rcx, [rsp+48]
	mov rdx, [rsp+40]
	lea r8, [rsp+66]	; ac
	call ED_Pow

	mov rcx, [rsp+48]
	mov rdx, [rsp+40]
	add rdx, 10
	lea r8, [rsp+76] ;ad
	call ED_Pow

	mov rcx, [rsp+48]
	mov rdx, [rsp+40]
	add rcx, 10
	lea r8, [rsp+86]
	call ED_Pow			;bc

	mov rcx, [rsp+48]
	mov rdx, [rsp+40]
	add rcx, 10
	add rdx, 10
	lea r8, [rsp+96]
	call ED_Pow		;bd

	fld tbyte ptr [rsp+66]
	fld st(0)
	fld tbyte ptr [rsp+76]
	fcomi ST(0), ST(1)
	fxch st(2)
	fcmovnb ST(0), ST(2) ; If ST(0) is greater than ST(1) then we store ST(0) in ST(2)
	fxch st(2)
	fxch st(1)
	fcmovb ST(0), ST(1)
	fxch st(1)
	
	fstp ST(0) ; we dont need the additional value

	fld tbyte ptr [rsp+86]
	fcomi ST(0), ST(1)
	fxch st(1)
	fcmovb ST(0), ST(1)
	fxch st(1)

	fcomi ST(0), ST(2)
	fxch st(2)
	fcmovnb st(0), ST(2)
	fxch st(2)

	fstp ST(0) ; we dont need the additional value

	fld tbyte ptr [rsp+96]
	fcomi ST(0), ST(1)
	fxch st(1)
	fcmovb ST(0), ST(1)
	fxch st(1)

	fcomi ST(0), ST(2)
	fxch st(2)
	fcmovnb st(0), ST(2)
	fxch st(2)

	;we get min in st(1) and max in st(2)
	fstp ST(0)
	mov r8, [rsp+32]
	lea r10, [rbx -1]
	imul r10, r10, 10
	
	cmp rbx, 2				; cmp sets the same bits as fcomi, so yeah
	fcmovnb st(0), st(1)
	fstp tbyte ptr [r8+r10]
	fstp st(0)

	jl power

	;fstp tbyte ptr [r8+10]

	mov rcx, 0
	call SetX87Rounding
	add rsp, 120
	pop rbx
	ret
Int_Pow endp

Int_PowInt proc
	push r12
    xor r12, r12
	fldz					; checks for 0 in the divisor interval
	fld tbyte ptr [rcx]
	fcomip st(0), st(1)
	ja not_zero
	fld tbyte ptr [rcx+10]
	fcomip st(0), st(1)
	jb not_zero

	mov r10b, byte ptr [rdx+9]
	test r10b, 80h
	jz good

	fstp st(0)
	sub rsp, 28                 
    fnstenv [rsp]               
    or word ptr [rsp+4], 4     
    fldenv [rsp]                
    add rsp, 28
	pop r12
	ret


not_zero:	
	or r12, 1
good:
	fstp st(0)
	push rbx
	sub rsp, 120
	mov [rsp+32], r8
	mov [rsp+40], rdx
	mov [rsp+48], rcx
	
	mov rbx, 0

power:
	inc rbx
	mov rcx, rbx
	call SetX87Rounding

	mov rcx, [rsp+48]
	mov rdx, [rsp+40]
	lea r8, [rsp+66]	; ac
	call ED_PowInt

	mov rcx, [rsp+48]
	mov rdx, [rsp+40]
	add rcx, 10
	lea r8, [rsp+86]
	call ED_PowInt	;bc

	fld tbyte ptr [rsp+66]
	fld st(0)
	fld tbyte ptr [rsp+86]
	fcomi ST(0), ST(1)
	fxch st(2)
	fcmovnb ST(0), ST(2) ; If ST(0) is greater than ST(1) then we store ST(0) in ST(2)
	fxch st(2)
	fxch st(1)
	fcmovb ST(0), ST(1)
	fxch st(1)
	
	fstp ST(0) ; we dont need the additional value

	mov r8, [rsp+32]
	lea r10, [rbx -1]
	imul r10, r10, 10
	
	cmp rbx, 2				; cmp sets the same bits as fcomi, so yeah
	fcmovnb st(0), st(1)
	fstp tbyte ptr [r8+r10]
	fstp st(0)

	jl power

	test r12b, 01h
	jnz fines

	fld tbyte ptr [rdx]
	fisttp qword ptr [rsp+110]
	mov r10b, [rsp+110]
	test r10b, 01h
	jnz fines
	
	fldz
	fstp tbyte ptr [r8]


	;fstp tbyte ptr [r8+10]
	fines:

	mov rcx, 0
	call SetX87Rounding
	add rsp, 120
	pop rbx
	pop r12
	ret
Int_PowInt endp

Int_Sin proc
	sub rsp, 40
	mov r8, ED_Sin
	call Int_op1
	add rsp, 40
	ret
Int_Sin endp

Int_Cos proc
	sub rsp, 40
	mov r8, ED_Cos
	call Int_op1
	add rsp, 40
	ret
Int_Cos endp



END