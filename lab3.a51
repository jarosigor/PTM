WR_CMD		EQU	0FF2Ch		; zapis rejestru komend
WR_DATA		EQU	0FF2Dh		; zapis rejestru danych
RD_STAT		EQU	0FF2Eh		; odczyt rejestru statusu
RD_DATA		EQU	0FF2Fh		; odczyt rejestru danych

ORG 0

	lcall	lcd_init		; inicjowanie wyswietlacza

	mov	A, #04h				; x = 4, y = 0
	lcall	lcd_gotoxy		; przejscie do pozycji (4, 0)

	mov	DPTR, #text_hello	; wyswietlenie tekstu
	lcall	lcd_puts

	mov	A, #14h				; x = 4, y = 1
	lcall	lcd_gotoxy		; przejscie do pozycji (4, 1)

	mov	DPTR, #text_number	; wyswietlenie tekstu
	lcall	lcd_puts

	mov	A, #12				; wyswietlenie liczby
	lcall	lcd_dec_2

	sjmp	$

;=====================================================================

;---------------------------------------------------------------------
; Zapis komendy
;
; Wejscie: A - kod komendy
;---------------------------------------------------------------------
lcd_write_cmd:
	push	DPH
	push	DPL
	push	ACC
	mov		DPTR, #RD_STAT

check_stat_loop_1:	
	
	movx	A, @DPTR
	JB		ACC.7, check_stat_loop_1			; sprawdzanie statusu wyswietlacza
	
	mov		DPTR, #WR_CMD
	pop		ACC
	movx	@DPTR, A
	pop		DPL
	pop		DPH
	; ACC oraz DPTR zostaja nienaruszone
	ret

;---------------------------------------------------------------------
; Zapis danych
;
; Wejscie: A - dane do zapisu
;---------------------------------------------------------------------
lcd_write_data:
	push	DPH
	push	DPL
	push	ACC			; chornione sa DPTR oraz ACC
	mov		DPTR, #RD_STAT
	
check_stat_loop_2:	
	movx	A, @DPTR
	JB		ACC.7, check_stat_loop_2			; sprawdzanie statusu wyswietlacza
	
	mov		DPTR, #WR_DATA
	pop		ACC
	movx	@DPTR, A
	
	pop		DPL
	pop		DPH
	; ACC oraz DPTR zostaja nienaruszone
	ret

;---------------------------------------------------------------------
; Inicjowanie wyswietlacza
;---------------------------------------------------------------------
lcd_init:
	mov		A, #00111000b			; ustawienie trybu pracy
	lcall	lcd_write_cmd
	mov		A, #00000110b			; ustawienie trybu wprowadzania
	lcall	lcd_write_cmd
	mov		A, #00001100b			; ustawienie stanu wyswietlacza, display On/Off D=1, C=0, B=0
	lcall	lcd_write_cmd
	mov		A, #00000001b			; wyczyszczenie wyswietlacza
	lcall	lcd_write_cmd
	ret

;---------------------------------------------------------------------
; Ustawienie biezacej pozycji wyswietlania
;
; Wejscie: A - pozycja na wyswietlaczu: ---y | xxxx
;---------------------------------------------------------------------
lcd_gotoxy:
	jnb		ACC.4, lcd_gotoxy_skip			; jesli adres w linii 1 to adres taki jak wspolrzedna x, w przeciwnym wypadku 14 -> 44 czyli 0001 0100 -> 0100 0100
	setb	ACC.6
	clr		ACC.4
lcd_gotoxy_skip:
	setb	ACC.7						; bit komendy
	lcall	lcd_write_cmd
	ret

;---------------------------------------------------------------------
; Wyswietlenie tekstu od biezacej pozycji
;
; Wejscie: DPTR - adres pierwszego znaku tekstu w pamieci kodu
;---------------------------------------------------------------------
lcd_puts:
	clr		A
	movc 	A, @A+DPTR
	jz 		koniec_lcd_puts
	lcall	lcd_write_data
	inc		DPTR
	sjmp	lcd_puts
koniec_lcd_puts:
	ret

;---------------------------------------------------------------------
; Wyswietlenie liczby dziesietnej
;
; Wejscie: A - liczba do wyswietlenia (00 ... 99)
;---------------------------------------------------------------------
lcd_dec_2:
	mov		B, #10
	div 	AB
	add 	A, #'0'
	lcall	lcd_write_data
	
	mov		A, B
	add 	A, #'0'
	lcall	lcd_write_data
	ret

;---------------------------------------------------------------------
; Definiowanie wlasnego znaku
;
; Wejscie: A    - kod znaku (0 ... 7)
;          DPTR	- adres tabeli opisu znaku w pamieci kodu
;---------------------------------------------------------------------
lcd_def_char:

	ret

text_hello:
	db	'Hello word', 0
text_number:
	db	'Number = ', 0

END