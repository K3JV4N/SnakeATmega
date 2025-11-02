 //rgb 1= tänd på y axel (vilken rad) 0= släckt. 0b10000000 ger lägnst ner
 //anod 1= tänd på x axel(vilken kolumn) 0= släckt. 0b00000001 ger lägnst vänster. 
 //Varje rad på damatrix har 4 register i VMEM 1 för respektiva färg samt 1 som inte används. För att skriva till en specifik rad
 //så offsetas anod * 4. t.ex tända rad 4 med en blå på kolumn 0: sts vmem + 3 * 4, 1



SPI_CLOCK_INIT:
	push r16
	push r17
	//SPI grejer
	ldi r17, 0b00101100 //sätter pb5,3,2 som output
	out DDRB, r17

	ldi r17, (1<<SPE) | (1<<MSTR) | (1<<SPR0) | (1 << DORD)
	out SPCR, r17
	//Slut SPI grejer

	//klock grejer timer 2
	ldi r17, 0x03
	sts TCCR2B, r17//sätt prescaler

	ldi r17, 0x02
	sts TCCR2A, r17//sätt ctc mode
	
	ldi r17, 0x01//enable overflow interupt för clockan
	sts TIMSK2, r17

	ldi r17, 0xFF
	sts OCR2A, r17//sätt top/max värde
	//Slut klock grejer timer 2

	sei //enable global interupts

	pop r17
	pop r16
ret

	//Rensa VMEM
ERASE_VMEM:
	push r16
	push r20
	push ZL
	push ZH

	ldi ZH, HIGH(VMEM)
	ldi ZL, LOW(VMEM)

	ldi r16, 0
	ldi r20, 32
	_erase_vmem_loop:
		cpi r20, 0
		breq _erase_vmem_done
		dec r20
		st Z+, r16
		jmp _erase_vmem_loop


	_erase_vmem_done:
	ldi r16, 0
	sts ANOD, r16

	pop ZH
	pop ZL
	pop r20
	pop r16
ret

	

 MUX:
	push r16
	in r16, SREG
	push r16
	push r17
	push r18
	push ZL
	push ZH

	lds r17, ANOD
	cpi r17, 8
	brne _MUX_OK

	ldi r17, 0

	_MUX_OK:
		inc r17
		sts ANOD, r17// spara ANOD + 1 till nästa varv
		dec r17

		ldi ZH, HIGH(VMEM)
		ldi ZL, LOW(VMEM)
		
		mov r18, r17
		lsl r18
		lsl r18
		//ZL = ZL + Anod * 4
		add ZL, r18 

		cbi PORTB, PINB2 //drar ss låg
		sbi PORTB, PINB2 //drar ss hög

		ld r16, Z+ //blå
		call SPI_Transmit
		ld r16, Z+ //grön
		call SPI_Transmit
		ld r16, Z+ //röd
		call SPI_Transmit

		ldi r16, 0x01//start covert anod to correct bit in register

		cpi r17, 0
		breq _MUX_DONE

		_MUX_LOOP:
			lsl r16
			dec r17
			cpi r17, 0
			brne _MUX_LOOP

	
	_MUX_DONE:

	call SPI_SEND_ANOD
	
	INCSRAM SEED

	pop ZH
	pop ZL
	pop r18
	pop r17
	pop r16
	out SREG, r16
	pop r16

reti

 //sätt intern timer på 2,5 ms och se till så att den triggar ett avbrott. kanske CTC-mode?

SPI_SEND_ANOD:
	ldi r17, 0xFF
	eor r16, r17
	call SPI_Transmit
ret

SPI_Transmit:
	out SPDR, r16

	_SPI_transmit_wait:
		in r16, SPSR
		sbrs r16, SPIF
		rjmp _SPI_transmit_wait
ret