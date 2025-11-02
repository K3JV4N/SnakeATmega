//K:\TSIU51\AvrDude\avrdude.exe "-C" 
//"K:\TSIU51\AvrDude\avrdude.conf" -p atmega328p -c arduino -P COM20 -b 115200 -U flash:w:"$(ProjectDir)Debug\$(TargetName).hex":i use output window
//Adressen till rad 2 ligger på $80 + $40

.include "TWI.asm"

.include "EEPROM.asm"

 LCD_HW_INIT:	//data = r20
	ldi		r23, $00
	ldi		r24, $00

	call LCD_DELAY
	call LCD_DELAY
	call LCD_DELAY

	ldi		r20, $30
	call	SEND_LCD


	call LCD_DELAY
	call LCD_DELAY
	call LCD_DELAY

	ldi		r20, $30
	call	SEND_LCD

	call LCD_DELAY

	ldi		r20, $30
	call	SEND_LCD 

	ldi		r20, $20
	call	SEND_LCD

	ldi		r20, $20
	call	SEND_LCD

	ldi		r20, $80 // N/F
	call	SEND_LCD

	ldi		r20, $00
	call	SEND_LCD

	ldi		r20, $C0 // D / C / B cursor control
	call	SEND_LCD

	ldi		r20, $00
	call	SEND_LCD	

	ldi		r20, $10
	call	SEND_LCD

	ldi		r20, $00
	call	SEND_LCD

	ldi		r20, $60 // I/D & S 
	call	SEND_LCD

	call	LCD_PRINT_INIT

	ldi		r19, $00
ret	

STOP:
	rjmp STOP


LCD_PRINT_INIT: 

	ldi		r20, 'H' //48
	call	LCD_ASCII

	ldi		r20, 'S' //53
	call	LCD_ASCII

	ldi		r20, ':' //3A
	call	LCD_ASCII

	ldi		r20, '0' 
	call	LCD_ASCII

	ldi		r20, '0' 
	call	LCD_ASCII


	call PRINT_HS


	ldi		r20, $C0
	call	LCD_CTRL

	ldi		r20, 'P' //50
	call	LCD_ASCII

	ldi		r20, 'S' //53
	call	LCD_ASCII

	ldi		r20, ':' //3A
	call	LCD_ASCII

	ldi		r20, '0' 
	call	LCD_ASCII

	ldi		r20, '0' 
	call	LCD_ASCII

ret

PRINT_HS: 
		push r17
	
		rcall EEPROM_READ
		ldi r17,$00
_CTRL_HS: 
		;sts PS,r16
		cp r16,r17
		brne _CTRL_HS
		inc r17
		call EEPROM_WRITE
		
		pop r17
ret



CHECK_HS:
		push r17
		push r16

		rcall EEPROM_READ

		sts PS,r17
		cp r16,r17
		brsh _NEW_HS
		
		pop r16
		pop r17
ret			
_NEW_HS:
		rcall EEPROM_WRITE //PRINT HS?
		call PRINT_HS
ret



HS_NUMBER:
	push	ZH
	push	ZL
	push	r17
	
	call	HS_NEW_NUMBER

	pop		r17
	pop		ZL
	pop		ZH
ret


PS_NUMBER:
	push	ZH
	push	ZL
	push	r17

	call	NEW_NUMBER

	pop		r17
	pop		ZL
	pop		ZH
ret


NEW_NUMBER:

	ldi		ZH,	HIGH(LCD_NUMBERS*2) 
	ldi		ZL,	LOW(LCD_NUMBERS*2)
	inc		r23
	cpi		r23, $0A
	breq	_NEW_NUMBER

	call	PS_EN_TAL
	rjmp	END_NUMBER


_NEW_NUMBER: 

	ldi		r23, $00
	call	PS_EN_TAL

	inc		r24
	add		ZL, r24

	ldi		r20, $C3
	call	LCD_CTRL

	lpm		r20, Z
	call	LCD_ASCII




END_NUMBER:

ret

PS_EN_TAL:

	add		ZL, r23
	ldi		r20, $C4
	call	LCD_CTRL
	lpm		r20, Z
	call	LCD_ASCII
ret



HS_NEW_NUMBER:

	ldi		ZH,	HIGH(LCD_NUMBERS*2) 
	ldi		ZL,	LOW(LCD_NUMBERS*2)
	inc		r23
	cpi		r23, $0A
	breq	_HS_NEW_NUMBER

	call	HS_EN_TAL
	rjmp	END_NUMBER


_HS_NEW_NUMBER: 

	ldi		r23, $00
	call	HS_EN_TAL

	inc		r24
	add		ZL, r24

	ldi		r20, $83
	call	LCD_CTRL

	lpm		r20, Z
	call	LCD_ASCII

	call	END_NUMBER


HS_EN_TAL:

	add		ZL, r23
	ldi		r20, $84
	call	LCD_CTRL
	lpm		r20, Z
	call	LCD_ASCII
ret




LCD_CTRL:
	ldi		r22, $FF	//cary is clear
	call LCD_8TO4
ret

LCD_ASCII: 
	ldi		r22, $11 //cary is set 
	call LCD_8TO4
ret

LCD_8TO4: 
	push	r20
	call	_LCD_8TO4
	pop		r20

	swap	r20 
	call	_LCD_8TO4

ret 


_LCD_8TO4:
	andi	r20 , $F0
	cpi		r22, $FF
	breq	_LCD_8TO4CTRL
	ori		r20 , $09
	rjmp	_LCD_8TO4END
_LCD_8TO4CTRL:	
	ori		r20 , $08
_LCD_8TO4END:
	call	SEND_LCD
ret

SEND_LCD:
	call	TWI 
	ldi		r21, 0b00000100 
	eor		r20,r21
	call	TWI 
	eor		r20, r21
	call	TWI
ret


LCD_DELAY:
		ldi r16, $FF
	delayinre:
		ldi r17, $FF
	delayinre2:
		ldi r18, $03
	delayinre3:
		dec r18
		brne delayinre3
		dec r17
		brne delayinre2
		dec r16
		brne delayinre
		ret



LCD_NUMBERS: .db $30, $31, $32, $33, $34, $35, $36, $37, $38, $39