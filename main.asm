
.equ	GAME_SPEED  = 175	; inter-run delay (millisecs)

.dseg
.org SRAM_START
PS: .byte 1 //personal score/current score
SEED: .byte 1 //seed för random äpple
ANOD: .byte 1 //current line
VMEM: .byte 4 * 8 // första B sen G sen R sista tom.
HEAD_DIR: .byte 1 //00=höger, 01=vänster, 10=uppåt, 11=nedåt
HEAD_POSX: .byte 1
HEAD_POSY: .byte 1
.org 0x0400
BODY_COORDS: .byte 64 * 2 //X, Y sen X, Y osv...
APPLE_POSX: .byte 1
APPLE_POSY: .byte 1
 

; --- Macros for inc/dec-rementing
	; --- a byte in SRAM
	.macro INCSRAM	; inc byte in SRAM
		lds	r16,@0
		inc	r16
		sts	@0,r16
	.endmacro

	.macro DECSRAM	; dec byte in SRAM
		lds	r16,@0
		dec	r16
		sts	@0,r16
	.endmacro

.cseg
.org 	$0
rjmp	INIT
.org 0x0012 //overflow flaggan för CTC mode
rjmp MUX


.include "DAMATRIX.asm"
.include "sound.asm"
.include "Joystick.asm"
.include "LCD.asm"


INIT:
	rcall ERASE_VMEM//erase vmem
	rcall SPI_CLOCK_INIT
	rcall JOYSTICK_INNIT
	rcall TWI_INIT
	rcall LCD_HW_INIT
	sbi DDRB, 1 //tagen från sound.asm högtalare till output

	ldi r16, 0
	sts PS, r16

	ldi r16, 0x04
	sts HEAD_POSX, r16

	ldi r16, 0x04
	sts HEAD_POSY, r16

	

	ldi r16, 0x02
	sts APPLE_POSX, r16
	sts APPLE_POSY, r16

	//rcall NEW_APPLE

	//head pekare på bodysegmenten
	ldi XH, HIGH(BODY_COORDS)
	ldi XL, LOW(BODY_COORDS)
	//tail pekare på bodysegmenten
	ldi YH, HIGH(BODY_COORDS)
	ldi YL, LOW(BODY_COORDS)

	// Skapa 2 kroppssegment, skriv dem till BODY_COORDS
	ldi r16, 4
	ldi r17, 3
	st X+, r16
	st X+, r17
	dec r17
	st X+, r16
	st X+, r17
	
	ldi r16, 0x04
	sts HEAD_DIR, r16

	rcall ERASE_VMEM//erase vmem
	rcall UPDATE_VMEM//write info to vmem

	WAIT_FOR_INPUT:
	rcall deleye
	rcall JOYSTICK
	lds r16, HEAD_DIR

	cpi r16, 1
	breq WAIT_FOR_INPUT

	cpi r16, 4
	brsh WAIT_FOR_INPUT




MAIN:
//fulkod. Använd timer istället. Kan vi använda samma timer som för DAMatrix eller LCD?
	rcall deleye
	rcall deleye
	rcall deleye
	rcall deleye
	rcall deleye
	rcall deleye
	rcall deleye
	rcall deleye
	rcall deleye
	rcall deleye
	rcall deleye
	rcall deleye
	rcall deleye
	rcall deleye
	rcall deleye
	rcall deleye
	rcall deleye
	rcall deleye
	rcall deleye
	rcall deleye
	rcall deleye
	rcall deleye
	rcall deleye
	rcall deleye

	
	

	rcall JOYSTICK //Change direction
	rcall MOVE_BODY
	rcall MOVE_HEAD //Move in current direction

	rcall CHECK_COLISION
	rcall CHECK_APPLE_COLISION
	

	rcall ERASE_VMEM//erase vmem
	rcall UPDATE_VMEM//write info to vmem
	

	rjmp MAIN

deleye:

	GAME_DELAY:
		ldi r16, GAME_SPEED
	GAME_delayYttreLoop:
		ldi r17, $FF
	GAME_delayInreLoop:
		dec r17
		brne GAME_delayInreLoop
		dec r16
		brne GAME_delayYttreLoop

ret
    


UPDATE_VMEM:
	push r16
	push r17
	push ZL
	push ZH

	rcall UPDATE_HEAD_VMEM
	rcall UPDATE_APPLE_VMEM
	rcall UPDATE_BODY_VMEM

	pop ZH
	pop ZL
	pop r17
	pop r16
ret



UPDATE_BODY_VMEM:
	mov r22, XL
	push XL
	push XH
	push r20
	mov XH, YH
	mov XL, YL
	
	_BODY_VMEM_YTTRE_LOOP:
		
		ldi ZH, HIGH(VMEM)
		ldi ZL, LOW(VMEM)

		ld r19, X //spara gamla y
		ld r16, X+ //posy
		lsl r16
		lsl r16
		add ZL, r16
		
		//tänd rätt kolumn beroende på head_posx
		ld r18, X+ //posx
		ldi r17, 1

		cpi r18, 0
		breq _BODY_vmem_loop_done
		_BODY_vmem_loop:
			lsl r17
			dec r18
			brne _BODY_vmem_loop

		_BODY_vmem_loop_done:
		lsr r16
		lsr r16
		cp r16, r19
		brne _SAME_LINE

			inc ZL
			ld r20, Z
			or r20, r17
			st Z, r20
			rjmp _VMEM_DONE

		_SAME_LINE:
			inc ZL
			st Z, r17


		_VMEM_DONE:
		andi XL, 0x07F
		cp XL, r22
		brne _BODY_VMEM_YTTRE_LOOP

	pop r20
	pop XH
	pop XL

ret


UPDATE_HEAD_VMEM:
	//peka till rätt rad i vmem beroende på head_posy
	ldi ZH, HIGH(VMEM)
	ldi ZL, LOW(VMEM)

	lds r16, HEAD_POSY
	lsl r16
	lsl r16
	add ZL, r16
	
	//tänd rätt kolumn beroende på head_posx
	lds r16, HEAD_POSX
	ldi r17, 1

	cpi r16, 0
	breq _head_vmem_loop_done
	_head_vmem_loop:
		lsl r17
		dec r16
		brne _head_vmem_loop

	_head_vmem_loop_done:
	st Z, r17
ret


UPDATE_APPLE_VMEM:
	//peka till rätt rad i vmem beroende på APPLE_posy
	ldi ZH, HIGH(VMEM)
	ldi ZL, LOW(VMEM)

	lds r16, APPLE_POSY
	lsl r16
	lsl r16
	add ZL, r16
	
	//tänd rätt kolumn beroende på APPLE_posx
	lds r16, APPLE_POSX
	ldi r17, 1

	cpi r16, 0
	breq _APPLE_vmem_loop_done
	_APPLE_vmem_loop:
		lsl r17
		dec r16
		brne _APPLE_vmem_loop

	_APPLE_vmem_loop_done:
	inc ZL
	inc ZL
	st Z, r17

ret



MOVE_HEAD:
	push r16
	//load direction
	lds r16, HEAD_DIR

	//Check Dir and inc och dec HEAD_POS X/Y
	cpi r16, 0
	brne _DIR_NOT_RIGHT
		INCSRAM HEAD_POSX
		rjmp _MOVE_HEAD_DONE
	_DIR_NOT_RIGHT:
	cpi r16, 1
	brne _CHECK_Y
		DECSRAM HEAD_POSX
		rjmp _MOVE_HEAD_DONE

_CHECK_Y:

	cpi r16, 2
	brne _DIR_NOT_UP 
		INCSRAM HEAD_POSY
		rjmp _MOVE_HEAD_DONE
	_DIR_NOT_UP:
	cpi r16,3
	brne _MOVE_HEAD_DONE
		DECSRAM HEAD_POSY


_MOVE_HEAD_DONE:
	pop r16
ret

MOVE_BODY:
	lds r16, HEAD_POSY
	st X+, r16
	lds r16, HEAD_POSX
	st X+, r16

	//flytta tail pekaren till nästa kroppsegment
	inc YL
	inc YL

	andi XL, 0x07F
	andi YL, 0x07F
	
ret



GROW_SNAKE:
	lds r16, HEAD_POSY
	st X+, r16
	lds r16, HEAD_POSX
	st X+, r16

	andi XL, 0x07F
	andi YL, 0x07F
ret


CHECK_APPLE_COLISION:
	//Check Apple Colision
	lds r16, HEAD_POSX
	lds r17, APPLE_POSX
	cp r16,r17
	brne NO_HIT
	lds r16, HEAD_POSY
	lds r17, APPLE_POSY
	cp r16,r17
	brne NO_HIT	
	rcall beep 
	rcall PS_NUMBER
	rcall GROW_SNAKE //Ska calla på förläng orm funktion och öka poäng
	INCSRAM PS
	rcall NEW_APPLE
ret


CHECK_COLISION: 

	//Kollar när HEAD_POSX/Y Går utanför range.
	lds r16, HEAD_POSX
	cpi r16, 8
	brne RIGHT_BOUND_OK
	rjmp GAME_OVER // Ersätt med Game_over när den är klar

	RIGHT_BOUND_OK:
	//Kolla vänster, hur göra för att kolla om den gått under noll? gissar att man kanske kollar på carry? testade att dec ett register som var noll det blev $FF men det verkar inte funka här.
	lds r16, HEAD_POSX
	cpi r16, $FF
	brne LEFT_BOUND_OK
	rjmp GAME_OVER // Ersätt med Game_over när den är klar
	//Jämförelse+branch till LEFT_BOUND_OK

	LEFT_BOUND_OK:
	 lds r16, HEAD_POSY
	 cpi r16, 8
	 brne TOP_BOUND_OK
	 rjmp GAME_OVER// Ersätt med Game_over när den är klar

	 TOP_BOUND_OK:
	 lds r16, HEAD_POSY
	 cpi r16, $FF
	 brne LOWER_BOUND_OK
	 rjmp GAME_OVER// Ersätt med Game_over när den är klar
	 LOWER_BOUND_OK:


CHECK_BODY_COLISION:

	mov r22, XL
	push XL
	push XH
	lds r18, HEAD_POSY
	lds r19, HEAD_POSX
	mov XH, YH
	mov XL, YL

	_HEAD_BODY_COLL:

		ld r16, X+ //posy
		ld r17, X+ //posx

		cp r16, r18
		brne _BODY_COLL_DONE
		cp r17, r19
		brne _BODY_COLL_DONE
			rjmp GAME_OVER //Lägg till game over
		
		
		_BODY_COLL_DONE:
			andi XL, 0x07F
			cp XL, r22
			brne _HEAD_BODY_COLL
			
	
	pop XH
	pop XL


ret


NO_HIT:
ret


NEW_APPLE:
	mov r22, XL
	push XL
	push XH
	

	_NEW_SEED:
	mov XH, YH
	mov XL, YL
	lds r18, SEED
	andi r18, 0x07
	rcall deleye
	lds r19, SEED
	andi r19, 0x07

	_APPLE_BODY_COLL:

		ld r16, X+ //posy
		ld r17, X+ //posx

		cp r16, r18
		brne _COLL_DONE
		cp r17, r19
		brne _COLL_DONE
			rjmp _NEW_SEED
		
		
		_COLL_DONE:
			andi XL, 0x07F
			cp XL, r22
			brne _APPLE_BODY_COLL


		_APPLE_POS_OK:
			sts APPLE_POSY, r18
			sts APPLE_POSX, r19
			
	
	pop XH
	pop XL

ret

GAME_OVER:
	call ERASE_VMEM
	push ZH
	push ZL

	ldi ZH, HIGH(VMEM)
	ldi ZL, LOW(VMEM)

	ldi r16, 0xFF
	ldi r17, 4
	inc ZL
	inc ZL
	st Z, r16

	add ZL, r17
	ldi r16, 0xC3
	st Z, r16

	add ZL, r17
	ldi r16, 0xA5
	st Z, r16

	add ZL, r17
	ldi r16, 0x99
	st Z, r16

	add ZL, r17
	ldi r16, 0x99
	st Z, r16

	add ZL, r17
	ldi r16, 0xA5
	st Z, r16

	add ZL, r17
	ldi r16, 0xC3
	st Z, r16

	add ZL, r17
	ldi r16, 0xFF
	st Z, r16

	pop ZL
	pop ZH
	rcall beep
	rcall beep
	rcall beep
	rcall beep
	rcall beep
	rcall beep

	rcall CHECK_HS
	// cp PS,HS
	// OM PS>HS Skriv till EEPROM
	
	rjmp INIT
