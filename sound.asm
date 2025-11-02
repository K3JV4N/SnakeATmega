.equ	BEEP_PITCH  = 20	; Victory beep pitch
.equ	BEEP_LENGTH = 40	; Victory beep length

BEEP:	
	//sbi DDRB, 1 //lägg i innit i main. Lagt till i main
	ldi r19, Beep_Length
	BEEPIGEN:
		sbi PORTB, 1 
		ldi r16,  BEEP_Pitch
		rcall DELAY
		cbi PORTB, 1
		ldi r16,  BEEP_Pitch
		rcall DELAY
		dec r19
		brne BEEPIGEN

	ret

	DELAY:
		
		ldi r18, 0xF1
		delayInreLoop:
			dec r18
			brne delayInreLoop

		dec r16
		brne  DELAY	
	DELAY_DONE:
	ret
