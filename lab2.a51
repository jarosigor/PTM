ORG 0

;	sjmp	test_copy_iram_xram_z	; przyklad testu wybranej procedury
/*
test_sum_xram:
	mov DPTR, #8000h
	
	mov A, #01h
	movx @DPTR, A
	
	inc DPTR
	
	mov A, #02h
	movx @DPTR, A
	
	inc DPTR
	
	mov A, #03h
	movx @DPTR, A
	
	inc DPTR
	
	mov A, #04h
	movx @DPTR, A

	mov	DPTR, #8000h	; adres poczatkowy obszaru
	mov	R2, #4		; dlugosc obszaru
	lcall	sum_xram
	sjmp	$

test_copy_xram_iram_inv:
	mov	R0, #30h	; adres poczatkowy obszaru docelowego
	mov DPTR, #8000h
	
	mov A, #01h
	movx @DPTR, A
	inc DPTR
	mov A, #02h
	movx @DPTR, A
	inc DPTR
	mov A, #03h
	movx @DPTR, A
	inc DPTR
	mov A, #04h
	movx @DPTR, A
	
	mov DPTR, #8000h
	mov	R2, #4		; dlugosc obszaru
	lcall	copy_xram_iram_inv
	sjmp	$

test_copy_iram_xram_z:
	mov	R0, #30h	; adres poczatkowy obszaru zrodlowego
	
	mov @R0, #01
	inc R0
	mov @R0, #00
	inc R0
	mov @R0, #00
	inc R0
	mov @R0, #04
	
	mov	R0, #30h	; adres poczatkowy obszaru zrodlowego
	mov	DPTR, #8000h	; adres poczatkowy obszaru docelowego
	mov	R2, #4		; dlugosc obszaru
	lcall	copy_iram_xram_z
	sjmp	$

test_copy_xram_xram_2:
	mov DPTR, #8000h
	mov A, #01h
	movx @DPTR, A
	inc DPTR
	mov A, #02h
	movx @DPTR, A
	inc DPTR
	mov A, #03h
	movx @DPTR, A
	inc DPTR
	mov A, #04h
	movx @DPTR, A

	mov	DPTR, #8000h	; adres poczatkowy obszaru zrodlowego
	mov	R0, #LOW(8010h)	; adres poczatkowy obszaru docelowego
	mov	R1, #HIGH(8010h)
	mov	R2, #4		; dlugosc obszaru
	lcall	copy_xram_xram_2
	sjmp	$
*/
test_count_range:
	mov	R0, #30h	; adres poczatkowy obszaru
	
	mov @R0, #01h
	inc R0
	mov @R0, #12h
	inc R0
	mov @R0, #13h
	inc R0
	mov @R0, #69h
	inc R0
	
	mov R0, #30h
	mov	R2, #4		; dlugosc obszaru
	lcall	count_range
	sjmp	$

;---------------------------------------------------------------------
; Sumowanie bloku danych w pamieci zewnetrznej (XRAM)
;
; Wejscie: DPTR  - adres poczatkowy bloku danych
;          R2    - dlugosc bloku danych
; Wyjscie: R7|R6 - 16-bit suma elementow bloku (Hi|Lo)
;---------------------------------------------------------------------
sum_xram:
	clr C
	clr A
	mov R6, A
	mov R7, A
	mov A, R2
	jz end_sum
	
loop_1:
	movx A, @DPTR ; pobranie bajtu danych
	inc DPTR
	add A, R6 ; dodanie wartosci z akumulatora do mlodszego bajtu sumy
	mov R6, A ; zapis mlodszego bajtu sumy
	jc carry
	djnz R2, loop_1
	ret
	
carry:
	mov A, R7
	inc A
	mov R7, A
	clr C
	djnz R2, loop_1
	
end_sum:
	ret
;---------------------------------------------------------------------
; Kopiowanie bloku z pamieci zewnetrznej (XRAM) do wewnetrznej (IRAM)
; Przy kopiowaniu powinna byc odwrocona kolejnosc elementow
;
; Wejscie: DPTR - adres poczatkowy obszaru zrodlowego
;          R0   - adres poczatkowy obszaru docelowego
;          R2   - dlugosc kopiowanego obszaru
;---------------------------------------------------------------------
copy_xram_iram_inv:
	mov A, R2
	mov R3, A ; rejestr 3 - licznik do ustawienia r0 na pozycje
	jnz move_r0_to_end
	
move_r0_to_end:
	inc R0
	djnz R3, move_r0_to_end
	dec R0
	
loop_2:
	movx A, @DPTR
	mov @R0, A
	inc DPTR
	dec R0
	djnz R2, loop_2
	ret
	

;---------------------------------------------------------------------
; Kopiowanie bloku z pamieci wewnetrznej (IRAM) do zewnetrznej (XRAM)
; Przy kopiowaniu powinny byc pominiete elementy zerowe
;
; Wejscie: R0   - adres poczatkowy obszaru zrodlowego
;          DPTR - adres poczatkowy obszaru docelowego
;          R2   - dlugosc kopiowanego obszaru
;---------------------------------------------------------------------
copy_iram_xram_z:
	mov A, R2	; sprawdzenie czy blok sie nie skonczyl 
	jz end_ir_xr
	mov A, @R0	; pobieramy bajt z pamieci wewnetrznej iram
	inc R0	;
	jz zero_case
	movx @DPTR, A	; kopiujemy wartosc z aku
	inc DPTR
	djnz R2, copy_iram_xram_z
	ret

zero_case:
	dec R2
	sjmp copy_iram_xram_z
	
end_ir_xr:
	ret
	
;---------------------------------------------------------------------
; Kopiowanie bloku danych w pamieci zewnetrznej (XRAM -> XRAM)
; Przy kopiowaniu elementy niezerowe powinny byc podwojone
;
; Wejscie: DPTR  - adres poczatkowy obszaru zrodlowego
;          R1|R0 - adres poczatkowy obszaru docelowego
;          R2    - dlugosc kopiowanego obszaru
;---------------------------------------------------------------------
copy_xram_xram_2:
	mov A, R2
	jz end_xr_xr

copy_twice:
	movx A, @DPTR
	inc DPTR
	
	xch A, R1
	xch A, DPH
	xch A, R1
	xch A, R0
	xch A, DPL
	xch A, R0
	jz zero_case_2
	
	movx @DPTR, A
	inc DPTR

zero_case_2:
	movx @DPTR, A
	inc DPTR

	xch A, R1
	xch A, DPH
	xch A, R1
	xch A, R0
	xch A, DPL
	xch A, R0
	
	djnz R2, copy_twice

end_xr_xr:
	ret
	
;---------------------------------------------------------------------
; Zliczanie w bloku danych w pamieci wewnetrznej (IRAM)
; liczb mieszczacych sie w przedziale domknietym <10,100>
;
; Wejscie: R0 - adres poczatkowy bloku danych
;          R2 - dlugosc bloku danych
; Wyjscie: A  - liczba elementow spelniajacych warunek
;---------------------------------------------------------------------
count_range:
	mov A, R2
	jz end_count
	mov R1, #0

loop_count:
	clr C
	mov A, @R0
	subb A, #10
	jc not_in
	subb A, #91
	jnc not_in
	inc R1
	
not_in:
	inc R0
	djnz R2, loop_count

end_count:
	mov A, R1
	ret

END