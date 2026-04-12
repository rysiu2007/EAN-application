.code
EXTERN SetX87Rounding : PROC 
EXTERN ED_Add : PROC
EXTERN ED_Sub : PROC
EXTERN ED_Mul : PROC
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

	call ED_Sub

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
END