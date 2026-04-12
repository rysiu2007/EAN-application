.code
EXTERN SetX87Rounding : PROC 
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
	add rsp, 72		
	ret
Int_op1 endp
END