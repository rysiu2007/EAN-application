extern M_Mid:PROC, M_Add:PROC, M_Sub:PROC, M_Mul:PROC, M_Div:PROC, M_Pow:PROC
extern M_Log:PROC, M_Log2:PROC, M_Log10:PROC, M_LogN:PROC, M_Exp:PROC, M_Sin:PROC, M_Cos:PROC
extern ED_Add:PROC, ED_Sub:PROC, ED_Mul:PROC, ED_Div:PROC, ED_Pow:PROC
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
	sub rsp, 104
	mov rbx, rcx
	mov r13, rdx
	mov r14, r8
	;mov r15, r9
	mov r12, [rsp+104+8+8+8+8+8+8+8+32+8+8]
	main_loop:
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
			mov rdx, [rsp+104+8+8+8+8+8+8+8+32+8]
			lea r8, [rsp+48]
			call ED_Mul

			lea rcx, [r15]
			lea rdx, [rsp+48]
			lea r8, [r15]	;Should save it in a different place but for a prototype i think its ok
			call ED_Sub
			add r15, 20
			dec rbx
		jnz iter_loop
		pop rbx
	;Do additional checkings and operations
	dec r12
	jnz main_loop
	
	end_loop:
	;mov rax, rdx
	add rsp, 104
	pop rdi
	pop rsi
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	ret

SimplifiedNewton_Point endp