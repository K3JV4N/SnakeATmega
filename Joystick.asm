JOYSTICK:	
	push r16
	push r17
	push r18

	rcall JOYSTICK_INNIT
X_ADC:
	ldi r16,2 ; kanal 0, 5 V ref
	rcall START_ADC

	lds r18, HEAD_DIR

	


	cpi r17, 3
	brne X_NOT_3
		cpi r18, 1
		breq Y_ADC
		ldi r16, 0
		sts HEAD_DIR, r16
	X_NOT_3:
	cpi r17, 0
	brne Y_ADC
		cpi r18, 0
		breq Y_ADC
		ldi r16, 1
		sts HEAD_DIR, r16


Y_ADC:
	ldi r16,3 ; kanal 1, 5 V ref
	rcall START_ADC

	cpi r17, 3
	brne Y_NOT_3 
		cpi r18, 3
		breq Y_NOT_0
		ldi r16, 2
		sts HEAD_DIR, r16
	Y_NOT_3:
	cpi r17, 0
	brne Y_NOT_0
		cpi r18, 2
		breq Y_NOT_0
		ldi r16, 3
		sts HEAD_DIR, r16

Y_NOT_0:
	pop r18
	pop r17
	pop r16
ret

JOYSTICK_INNIT:
	ldi r18, (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0)
	sts ADCSRA, r18

ret

START_ADC:
	ori r16, (0 << REFS1) | (1 << REFS0)
	sts ADMUX, r16
CONVERT:
	ldi r16, (1 << ADEN) | (1 << ADSC) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0)
	sts ADCSRA, r16 ; starta en omvandling
WAIT:
	lds r16, ADCSRA
	sbrc r16, ADSC  ; om nollställd är vi klara
	brne WAIT ; annars testa busy-biten igen
	lds r17,ADCH 

ret