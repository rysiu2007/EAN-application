extern M_Mid:PROC, M_Add:PROC, M_Sub:PROC, M_Mul:PROC, M_Div:PROC, M_Pow:PROC
extern M_Log:PROC, M_Log2:PROC, M_Log10:PROC, M_LogN:PROC, M_Exp:PROC, M_Sin:PROC, M_Cos:PROC
extern ED_Add:PROC, ED_Sub:PROC, ED_Mul:PROC, ED_Div:PROC, ED_Pow:PROC
extern Int_Add:PROC, Int_Sub:PROC, Int_Mul:PROC, Int_Div:PROC, Int_Pow:PROC, Int_LoadNum:PROC, Int_Avg:PROC, Int_Intersect:PROC
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
	push rbp
	sub rsp, 160
	mov rbx, rcx
	mov r13, rdx
	mov r14, r8
	mov rbp, r9
	;mov r15, r9
	mov r12, [rsp+160+8+8+8+8+8+8+8+32+8+8+48+8] ; mit
	main_loop:
		fldz
		fstp tbyte ptr [rsp+96]
		;int 3
		push rbx

		mov rsi, r14
		mov rdi, rbp
		mov r15, r13
		iter_loop:

			lea rcx, [rsp+48]
			mov rdx, r13
			mov rax, [rsi]
			sub rsp, 32
			call rax
			add rsp, 32
			;int 3
			add rsi, 8
			lea rcx, [rsp+72]
			mov rdx, r13
			mov rax, [rdi]
			sub rsp, 32
			call rax
			add rsp, 32
			add rdi, 8
			lea rcx, [rsp+48]
			lea rdx, [rsp+72]
			lea r8, [rsp+48]
			call M_Div

			lea rcx, [rsp+48]
			mov rdx, [rsp+160+8+8+8+8+8+8+8+32+8+8+48+8]; omega
			lea r8, [rsp+48]
			call M_Mul


			lea rcx, [r15]
			lea rdx, [rsp+48]
			lea r8, [r15]	;Should save it in a different place but for a prototype i think its ok
			call M_Sub
			;int 3

			;lea rcx, [rsp+96+8]
			;lea rdx, [rsp+116+8]
			;call M_Mid

			lea rcx, [rsp+48]
			lea rdx, [rsp+126+8]
			call M_Mid

			fld tbyte ptr [rsp+96+8]
			fld tbyte ptr [rsp+126+8]
			fabs
			fcomi st(0), st(1)
			fcmovb st(0), st(1)
			fstp tbyte ptr [rsp+96+8]
			fstp st(0)

			add r15, 20
			dec rbx
		jnz iter_loop
		pop rbx
		mov rdx, [rsp+160+8+8+8+8+8+8+8+32+8+8+8 + 48+8]
		fld tbyte ptr [rdx] ; eps
	;	int 3
		;int 3
		;lea rcx, [rsp+96]
		;lea rdx, [rsp+116]
		;call M_Mid
		fld tbyte ptr [rsp+96]
		fcomi st(0), st(1)
		fstp st(0)
		fstp st(0)
		;jp error
		jb end_loop
	;Do additional checkings and operations
	dec r12
	jnz main_loop
	;int 3
	;int 3
;	error:
;	int 3
	end_loop:
	;int 3
	;mov rax, rdx
	add rsp, 160
	pop rbp
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
	;int 3
	push rbp
	mov rbp, rsp 
	push rbx
	push r12
	push r13
	push r14
	push r15
	push rsi
	push rdi

	; --- DYNAMICZNA ALOKACJA RAMKI NA STOSIE ---
	mov rax, rcx        ; rax = n
	imul rax, 20        ; n * 20 bajtÛw na kopiÍ tablicy przedzia≥Ûw
	add rax, 512        ; bezpieczny zapas na zmienne lokalne (bufory) i strukturÍ pomocniczπ
	add rax, 15         ; do wyrÛwnania
	add rax, 32
	and rax, -16        ; maskowanie do 16 bajtÛw (wymÛg ABI x64)
	sub rsp, rax        ; bezpieczne i sta≥e obniøenie stosu

	; --- PRZEPISANIE PARAMETR”W WEJåCIOWYCH ---
	mov rbx, rcx        ; rbx = n
	mov r13, rdx        ; r13 = oryginalny adres tablicy przedzia≥Ûw z RDX
	mov r14, r8         ; r14 = wskaünik na tablicÍ funkcji z R8
	
	; --- ZAPIS PARAMETR”W DO NOWYCH, ODSEPAROWANYCH STREF PAMI CI ---
	mov [rbp-64], rbx   ; [rbp-64] trzyma n na sta≥e (bezpiecznie, nie dotykajπc rbp-24!)
	mov [rbp-72], r9    ; [rbp-72] trzyma wskaünik na dfuncs
	mov [rbp-80], rdx   ; [rbp-80] trzyma oryginalny adres tablicy z C++
	
	;int 3
	; --- KOPIOWANIE WEKTORA WEJåCIOWEGO NA STOS ---
	mov rsi, r13        ; ürÛd≥o: oryginalna tablica przedzia≥Ûw
	lea rdi, [rsp+32]   ; cel: bezpieczna strefa na naszym stosie
	imul rcx, 20        ; liczba bajtÛw do skopiowania
	rep movsb           ; skopiowanie oryginalnych przedzia≥Ûw
	
	lea r13, [rsp+32]   ; R13 od teraz to sta≥y, nienaruszalny wskaünik do naszej kopii roboczej

	;int 3
	; --- POBRANIE PARAMETRU MIT (OFFSET 104) ---
	mov r12, [rbp + 104] ; r12 = 150 (mit)

	;int 3

	main_loop:
		fldz
		fstp tbyte ptr [rbp-96] ; Gwarantowany, czysty i niezaleøny adres dla max_width
		
		; Przed kaødym obiegiem main_loop przywracamy licznik roboczy n bezpoúrednio ze sta≥ej bazy
		mov rbx, [rbp-64]       ; rbx = n (np. 3)
		
		mov rsi, r14            ; rsi = wskaünik na tablicÍ funkcji
		mov rdi, [rbp-72]       ; rdi = wskaünik na tablicÍ pochodnych
		mov r15, r13            ; r15 = wskaünik na bieøπcy przedzia≥ w pÍtli
		
		iter_loop:
			; =============================================================
			; 1. Wylicz úrodek aktualnego przedzia≥u (r15) -> wynik do [rbp-128]
			; =============================================================
			lea rcx, [r15]
			lea rdx, [rbp-128]
			;sub rsp, 32             ; Shadow Space dla C++
			call Int_Avg
			;add rsp, 32
		;	int 3
			lea rcx, [rbp-128]
			lea rdx, [rbp-128]
			;sub rsp, 32
			call Int_LoadNum
			;add rsp, 32
			; =============================================================
			; Backup grubego przedzia≥u [r15] do [rbp-224]
			; =============================================================
			fld tbyte ptr [r15]
			fstp tbyte ptr [rbp-224]
			fld tbyte ptr [r15+10]
			fstp tbyte ptr [rbp-214]

			; =============================================================
			; WstrzykniÍcie punktu [rbp-128] w miejsce [r15]
			; Prawid≥owe pobieranie danych z 20-bajtowej struktury wyjúciowej

			fld tbyte ptr [rbp-128]
			; Zapisujemy na pozycjÍ INF (bajt 0-9)
			fstp tbyte ptr [r15]
			fld tbyte ptr [rbp-118]
			fstp tbyte ptr [r15+10]

			; =============================================================
			; 2. LICZENIE f_i( [x]_kopia ) -> wynik do [rbp-160]
			; =============================================================
			lea rcx, [rbp-160]      ; Bufor na wynik f_i
			mov rdx, r13            ; Przekazujemy sta≥y wskaünik bazy ca≥ej tablicy
			mov rax, [rsi]          ; Pobranie adresu funkcji
			;sub rsp, 32
			call rax
			;add rsp, 32
			add rsi, 8              ; NastÍpny wskaünik funkcji

			; =============================================================
			; PrzywrÛcenie grubego przedzia≥u z [rbp-224] do [r15]
			; =============================================================
			fld tbyte ptr [rbp-224]
			fstp tbyte ptr [r15]
			fld tbyte ptr [rbp-214]
			fstp tbyte ptr [r15+10]

			; =============================================================
			; 3. LICZENIE df_i([x]) na pe≥nych, grubych przedzia≥ach -> wynik do [rbp-192]
			; =============================================================
			lea rcx, [rbp-192]      ; Bufor na wynik pochodnej czπstkowej
			mov rdx, r13            ; Przekazujemy sta≥y wskaünik ca≥ej tablicy
			mov rax, [rdi]          ; Pobranie adresu pochodnej
			;sub rsp, 32
			call rax
			;add rsp, 32
			add rdi, 8              ; NastÍpny wskaünik pochodnej

			; =============================================================
			; 4. ARYTMETYKA INTERWA£OWA: (f / df) * omega
			; =============================================================
			lea rcx, [rbp-160]      ; f
			lea rdx, [rbp-192]      ; df
			lea r8,  [rbp-160]      ; wynik tymczasowy do f
			;sub rsp, 32
			call Int_Div
			;add rsp, 32

			lea rcx, [rbp-160]
			mov rdx, [rbp + 96]     ; Pobranie wskaünika 'omega' (offset 96)
			lea r8,  [rbp-160]
			;sub rsp, 32
			call Int_Mul
			;add rsp, 32

			; =============================================================
			; 5. NOWY PRZEDZIA£ SEGMENTU: m(x_i) - poprawka
			; =============================================================
			lea rcx, [rbp-128]      ; úrodek m(x_i) (pe≥ny interwa≥ 20-bajtowy)
			lea rdx, [rbp-160]      ; poprawka interwa≥owa
			lea r8,  [rbp-160]      ; wynik segmentu
			;sub rsp, 32
			call Int_Sub
			;add rsp, 32

		;	int 3
			; =============================================================
			; 6. PRZECI CIE (INTERSECT): [x]_new = [x]_old \cap [temp]
			; =============================================================
			;int 3
			lea rcx, [r15]          ; oryginalny, stary przedzia≥
			lea rdx, [rbp-160]      ; nowo wyliczony przedzia≥
			lea r8,  [r15]          ; nadpisujemy wynik bezpoúrednio w kopii
			;sub rsp, 32
			call Int_Intersect
			;add rsp, 32

		;	int 3
			; =============================================================
			; 7. OBLICZANIE SZEROKOåCI NOWEGO INTERWA£U (Kryterium Stopu)
			; =============================================================
			fld tbyte ptr [r15 + 10] ; sup
			fld tbyte ptr [r15]      ; inf
			fsubp st(1), st(0)       ; ST(0) = szerokoúÊ przedzia≥u (sup - inf)
			fabs
			
			fld tbyte ptr [rbp-96]   ; Za≥aduj odseparowany max_width
			fcomi st(0), st(1)
			fcmovb st(0), st(1)      ; Aktualizacja maksimum b≥Ídu
			fstp tbyte ptr [rbp-96]  ; Zapis pod bezpieczny adres
			fstp st(0)

			add r15, 20              ; NastÍpny interwa≥ (wielkoúÊ 20 bajtÛw)
			
			dec rbx                  ; Bezpieczna dekrementacja rejestru roboczego
		jnz iter_loop
		
		; =============================================================
		; --- SPRAWDZANIE KRYTERIUM ZBIEØNOåCI (EPS - OFFSET 112) ---
		; =============================================================
		mov rdx, [rbp + 112]     ; Pobranie wskaünika 'eps' ze stosu C++
		fld tbyte ptr [rdx]      ; ST(1) = wartoúÊ eps
		fld tbyte ptr [rbp-96]   ; ST(0) = wyliczony w iteracji max_width
		fcomi st(0), st(1)
		
		jb @sukces_interval      ; Jeúli max_width < eps -> koniec sukcesem!
		
		fstp st(0)               ; Jeúli brak zbieønoúci, czyúcimy koprocesor
		fstp st(0)
		
	dec r12                      ; Zmniejsz licznik mit (150)
	jnz main_loop
	
	;mov rax, 0               ; ZwrÛÊ 0 (OsiπgniÍto limit iteracji mit)
	jmp @przepisz_i_wyjdz

	@sukces_interval:
		;mov rax, 1           ; ZwrÛÊ 1 (Sukces! Przedzia≥y siÍ zawÍzi≥y)

@przepisz_i_wyjdz:
	; --- ODKLEJENIE WYNIK”W I PRZEKAZANIE DO C++ ---
	;push rax                 ; Zachowaj kod powrotu (0 lub 1)
	;int 3
	mov rdi, [rbp-80]        ; Cel: Oryginalny, czysty adres docelowy odzyskany z [rbp-80]
	mov rsi, r13             ; èrÛd≥o: Poczπtek naszej uaktualnionej kopii na stosie
	mov rcx, [rbp-64]        ; Pobierz n ze sta≥ej bazy [rbp-64]
	imul rcx, 20             ; Liczba bajtÛw do skopiowania (n * 20)
	
	jrcxz @puste_wyjscie
	rep movsb                ; Bezpieczny sprzÍtowy transfer danych do pamiÍci C++
	
@puste_wyjscie:
	;pop rax                  ; PrzywrÛÊ kod powrotu (RAX = 0 lub 1)

	end_loop:
		pop rdi
		pop rsi
		pop r15
		pop r14
		pop r13
		pop r12
		pop rbx
		mov rsp, rbp             ; Bezpieczne i ca≥kowite zniszczenie ramki stosu
		pop rbp
		ret
SimplifiedNewton_Interval endp


SimplifiedNewton proc
    sub rsp, 40                 ; Shadow space dla x64 ABI
        
    mov rax, software_mode      ; Pobierz tryb (musi byÊ EXTERN QWORD)
    test rax, rax
    jz @F                       ; Skok do najbliøszego @@ (Forward)
        
        ; Tryb przedzia≥owy
    call SimplifiedNewton_Point     ; Sk≥ada nazwÍ np. Int_Add
        jmp ending
        
    @@:
        ; Tryb punktowy (float80)
        call SimplifiedNewton_Point      ; Sk≥ada nazwÍ np. ED_Add
        
    ending:
        add rsp, 40
        ret
SimplifiedNewton endp
END