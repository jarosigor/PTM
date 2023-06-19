ORG 0
/*
test_reverse_iram:
	mov	R0, #30h	; adres poczatkowy tablicy
	mov	R2, #8		; dlugosc tablicy
	lcall	fill_iram

	mov	R0, #30h	; adres poczatkowy tablicy
	mov	R2, #8		; dlugosc tablicy
	lcall	reverse_iram
	sjmp	$
*/
test_reverse_xram:
	mov	DPTR, #8000h	; adres poczatkowy tablicy
	mov	R2, #8		; dlugosc tablicy R3|R2
	mov	R3, #0
	lcall	fill_xram

	mov	DPTR, #8000h	; adres poczatkowy tablicy
	mov	R2, #8		; dlugosc tablicy R3|R2
	mov	R3, #0
	lcall	reverse_xram

test_string:
	mov	DPTR, #text	; adres poczatkowy stringu (CODE)
	mov	R0, #30h	; adres poczatkowy stringu (IRAM)
	lcall	copy_string

	mov	R0, #30h	; adres poczatkowy stringu (IRAM)
	lcall	reverse_string

	mov	R0, #30h	; adres poczatkowy stringu (IRAM)
	lcall	count_letters

	sjmp	$

;---------------------------------------------------------------------
; Wypelnianie tablicy ciagiem liczbowym 1,2,3, ... (IRAM)
; Wejscie:  R0 - adres poczatkowy tablicy
;           R2 - dlugosc tablicy
;---------------------------------------------------------------------
fill_iram:
	mov A, R2
	jz	fill_iram_return
	mov	R1,	#1
	
fill_iram_loop:
	mov	A, R1
	mov	@R0, A
	inc	R0
	inc R1
	djnz R2, fill_iram_loop
	
fill_iram_return:
	ret

;---------------------------------------------------------------------
; Wypelnianie tablicy ciagiem liczbowym 1,2,3, ... (XRAM)
; Wejscie:  DPTR  - adres poczatkowy tablicy
;           R3|R2 - dlugosc tablicy
;---------------------------------------------------------------------
fill_xram:
	mov R4,	#1
	
fill_xram_loop:
	mov A,	R2
	orl A,	R3
	jz fill_xram_return

	mov A, R4
	movx @DPTR, A
	inc DPTR
	inc R4
	
	dec R2
	cjne R2, #0FFh, fill_xram_loop
	dec R3
	jmp fill_xram_loop
	
fill_xram_return:
	ret

;---------------------------------------------------------------------
; Odwracanie tablicy w pamieci wewnetrznej (IRAM)
; Wejscie:  R0 - adres poczatkowy tablicy
;           R2 - dlugosc tablicy
;---------------------------------------------------------------------
reverse_iram:
	mov A, R2
	clr C
	rrc	A
	jz reverse_iram_return		; jesli dlugosc tablicy mniejsza od 2 skok do return
	mov R3,	A					; ilosc wykonan petli
	
	mov A, R0
	add A, R2					
	dec A						; indeksujemy od 0 stad dec A
	mov R1,	A					; wyliczenie i zapisanie adresu ostatniej komorki pamieci
	
reverse_iram_loop:
	mov A, @R0					
	xch A, @R1					; zamieniamy liczby z poczatku R0 i konca R1
	mov @R0, A
	inc R0						; przesuwamy R0 do przodu a R1 do tylu
	dec	R1
	djnz R3, reverse_iram_loop
	
reverse_iram_return:
	ret

;---------------------------------------------------------------------
; Odwracanie tablicy w pamieci zewnetrznej (XRAM)
; Wejscie:  DPTR  - adres poczatkowy tablicy
;           R3|R2 - dlugosc tablicy
;---------------------------------------------------------------------
reverse_xram:
	mov A, R3
	clr C
	rrc A
	mov R5,	A 						; dlugosc petli starsze 8 bitow
	mov A,	R2
	rrc A
	mov R4,	A						; dlugosc petli mlodsze 8 bitow
	orl A, R5
	jz reverse_xram_return 			; jesli 0 to skok do return
	
	mov A,	DPL
	add A,	R2						
	mov R0,	A						; R0 adres konca DPL
	mov A,	DPH						
	addc A,	R3
	mov R1,	A
	
	dec R0
	cjne R0,	#0FFh, 	reverse_xram_loop
	dec R1									;wyliczenie adresu ostatniego elementu
	
reverse_xram_loop:
	movx A,	@DPTR
	mov R6,	A
	mov R2,	DPL
	mov R3,	DPH
	mov	DPL,	R0
	mov DPH,	R1
	
	movx A, @DPTR
	xch A, R6
	movx @DPTR, A
	mov DPL, R2
	mov DPH,	R3
	mov A, R6
	movx @DPTR, A
	
	inc DPTR											;zwiekszony adres poczatku tablicy
	
	dec	R0
	cjne R0,	#0FFh,	reverse_xram_loop_counter_dec
	dec R1												;zmniejszony adres konca tablicy
	
reverse_xram_loop_counter_dec:
	dec R4
	cjne R4,	#0FFh, reverse_xram_loop_counter_check
	dec R5												;zmniejszony licznik petli
	
reverse_xram_loop_counter_check:	
	mov A, R4
	orl A, R5
	jnz reverse_xram_loop
	
reverse_xram_return:
	ret

;---------------------------------------------------------------------
; Kopiowanie stringu z pamieci programu (CODE) do pamieci IRAM
; Wejscie:  DPTR - adres poczatkowy stringu (CODE)
;           R0   - adres poczatkowy stringu (IRAM)
;---------------------------------------------------------------------
copy_string:
	clr	A
	movc A,		@A+DPTR
	mov @R0,	A
	inc DPTR
	inc R0
	jnz copy_string
	ret

;---------------------------------------------------------------------
; Odwracanie stringu w pamieci IRAM
; Wejscie:  R0 - adres poczatkowy stringu
;---------------------------------------------------------------------
reverse_string:
	mov R2,	#0
	mov A,	R0
	mov R1,	A
	
reverse_string_loop:
	mov A, @R1
	inc R1
	inc R2
	jnz reverse_string_loop
	
	dec R2
	lcall reverse_iram
	ret

;---------------------------------------------------------------------
; Zliczanie liter w stringu umieszczonym w pamieci IRAM
; Wejscie:  R0 - adres poczatkowy stringu
; Wyjscie:  A  - liczba liter w stringu
;---------------------------------------------------------------------
count_letters:
	mov R1, #0
	
count_letters_loop:
	mov A,	@R0
	jz count_letters_return
	
	mov R2, A
	clr C
	subb A,	#'z'+1
	jnc count_letters_next
	
	mov A, R2
	clr C
	subb A, #'a'
	jnc count_letters_counter_inc

	mov A, R2
	clr C
	subb A,	#'Z'+1
	jnc count_letters_next
	
	mov A, R2
	clr C
	subb A, #'A'
	jc count_letters_next
	
count_letters_counter_inc:
	inc R1
	
count_letters_next:
	inc R0
	jmp count_letters_loop

count_letters_return:
	mov A, R1
	ret
	
text:	DB	'Hello world 012', 0

END
