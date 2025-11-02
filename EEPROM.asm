
// info fins i ATMega328p infoblad sid 21-25. EEDR


//skriv adress till EEAR, DATA till EEDR, sätt EEMPE=1, sätt EEWE=1
//skriv adress till EEAR, sätt EEPE=1, läs data från EEDR


EEPROM_READ:
	push r18
	push r17

	sbic EECR,EEPE
	
	rjmp EEPROM_read
	
	;cli ;avbrotts hantering


	; Set up address (r18:r17) in address register
	ldi		r18, $00
	ldi		r17, $01


	out EEARH, r18
	out EEARL, r17

; Start eeprom read by writing EERE
	sbi EECR,EERE ;read enabe
; läs data
	in r16,EEDR ;dataregister



	
	pop r17
	pop r18
ret



EEPROM_WRITE:
	push r18
	push r17

	call LCD_DELAY

	; vänta på tidigare skrivning
	sbic	EECR, EEPE
	
	rjmp	EEPROM_write
	
	;cli 

	ldi		r18,  $00 // $20
	ldi		r17, $01 //$21

	out		EEARH, r18
	out		EEARL, r17

	; Write data (r16) to Data Register



	out		EEDR, r16
	; Write logical one to EEMPE
	sbi		EECR, EEMPE
	; Start eeprom write by setting EEPE
	sbi		EECR, EEPE

	
	pop r17
	pop r18
ret





