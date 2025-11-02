TWI_INIT:	    
	
	ldi		r16, $FF
	sts		TWBR, r16
	
	ret 



.equ	SCL	= PC5  
.equ	SDA = PC4
.equ	LCD = $20  
.equ	start = $08  
.equ	MT_SLA_ACK = $18  
.equ	MT_DATA_ACK = $28  
.equ	SLA_W = $40
ERROR:
	jmp ERROR
	
TWI:
	
		push	r16	

	TWI_START:  
		ldi		r16, (1<<TWINT) | (1<<TWSTA) | (1<<TWEN)   
		sts		TWCR, r16  
	wait1:  
		lds		r16, TWCR  
		sbrs	r16, TWINT  
		rjmp	wait1  
	TWI_ADRESS:
		ldi r16, SLA_W  
		sts TWDR, r16   
		ldi r16, (1<<TWINT) | (1<<TWEN)  
		sts TWCR, r16  
	wait2:  
		lds r16,TWCR  
		sbrs r16,TWINT  
		rjmp wait2
		lds r16,TWSR  
		andi r16, 0xF8  
		cpi r16, MT_SLA_ACK  
		brne ERROR
	TWI_DATA:
		mov r16, r20  
		sts TWDR, r16   
		ldi r16, (1<<TWINT) | (1<<TWEN)  
		sts TWCR, r16  
	wait3:  
		lds r16,TWCR  
		sbrs r16,TWINT  
		rjmp wait3  
 
		lds r16,TWSR  
		andi r16, 0xF8 
		cpi r16, MT_DATA_ACK  
		brne ERROR  
	TWI_STOPP:  
		ldi r16, (1<<TWINT)|(1<<TWEN)|(1<<TWSTO)  
		sts TWCR, r16 

		pop		r16
		ret



