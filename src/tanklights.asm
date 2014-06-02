;
; ********************************************
; Tank Light Project
; Drives 6 LEDs in a PWM/charlieplexed setup
; for gentle undulating night light.
; A photoresistor is connected across ANI1,
; so the light effect only runs when it's
; dark in the room.
; (C)2011 by Matthew Potter
; ********************************************

; Included header file for target AVR type
.NOLIST
.INCLUDE "tn13def.inc" ; Header for ATTINY13
.LIST
;
;
; ================================================================================================
;   R E G I S T E R   D E F I N I T I O N S
; ================================================================================================
.DEF	rmp				= r16
.DEF	rtmp			= r17
.DEF	rPWM_POS		= r18
.DEF	rACTIVE_LED		= r19
.DEF	rOFFSET			= r20
.DEF	rDELAY			= r21


; ================================================================================================
;	C O N S T A N T S
; ================================================================================================

; scan code status values
.EQU	PRIMARY_DELAY	= 180
.EQU	FIXED_DELAY		= 0
.EQU    TOTAL_CHANNELS  = 6
.EQU    LIGHT_TABLE_LEN = 252
.EQU    OFFSET_MULTIPLE = 42
.EQU	LED_PORT_MASK	= 0b11100110


; ================================================================================================
;	D A T A  S E G M E N T
; ================================================================================================
.DSEG
	on_values:	.BYTE	TOTAL_CHANNELS


; ================================================================================================
;   R E S E T   A N D   I N T   V E C T O R S
; ================================================================================================
;
.CSEG
.ORG $0000
	rjmp	Main ; Int vector 1 - Reset vector
	reti	; Int vector 2
	reti	; Int vector 3
	reti	; Int vector 4
	reti	; Int vector 5
	rjmp	ISR_AnalogComp_Handler ; Int vector 6
	rjmp	ISR_Timer0_CompareAHandler; Int vector 7
	reti	; Int vector 8
	reti	; Int vector 9
	reti	; Int vector 10


; ================================================================================================
; Timer0, compare A handler
; ================================================================================================
ISR_Timer0_CompareAHandler:
	push	rmp
	in		rmp, SREG
	push	rmp
	ldi		rmp, FIXED_DELAY
	tst		rmp
	breq	PC+0x04
	cpi		rDELAY, FIXED_DELAY					; check delay counter
	brlo	_to_ret1							; branch if we haven't reached our delay
	clr		rDELAY								; delay reached, clear delay
	inc		rOFFSET								; increment offset for next PWM pattern
	cpi		rOFFSET, LIGHT_TABLE_LEN			; check offset to make sure we are in range
	brlo	_to_ret2							; skip to return block if offset is OK
	clr		rOFFSET								; clear offset
	rjmp	_to_ret2							; skip to return block
_to_ret1:
	inc		rDELAY								; add 1 to delay counter
_to_ret2:
	pop		rmp
	out		SREG, rmp
	pop		rmp
	reti


; ================================================================================================
; Analog Comparator interrupt
; This handler is only enabled when the system is put into sleep mode.  The handler has to
; re-enable the main timer and start the lighting effects.
; ================================================================================================
ISR_AnalogComp_Handler:
	push	rmp
	in		rmp, SREG
	push	rmp

	in		rmp, ACSR
	andi	rmp, ~(1<<ACIE)						; disable interrupt handling
	out		ACSR, rmp
	in		rmp, TCCR0B							; enable timer0
	ori		rmp, (1<<CS02)
	ori		rmp, (1<<CS00)
	out		TCCR0B, rmp

	pop		rmp
	out		SREG, rmp
	pop		rmp
	reti


; ================================================================================================
; Main
; ================================================================================================
Main:
	ldi		rmp, LOW(RAMEND)					; Init LSB stack
	out		SPL, rmp
	rcall	Hardware_Init
	sei

Loop:
	wdr											; reset the watchdog timer
	;in		rmp, ACSR							; read ACSR register
	;sbrc	rmp, ACO							; skip if ACO is 0
	;rjmp	Halt								; when AC0 is 1, halt (too much light)
	rcall	PwmChnDrvr_Main						; invoke the channel driver
	ldi		r16, 0
	inc		r16
	cpi		r16, 0x10
	brlo	pc-2
	rjmp	Loop

Halt:
	cli
	rcall	PwmChnDrvr_Shutdown
	sbi		ACSR, ACI
	sbi		ACSR, ACIE
	in		rmp, TCCR0B							; disable timer
	andi	rmp, ~(1<<CS02)
	andi	rmp, ~(1<<CS00)
	out		TCCR0B, rmp
	sei
	sleep										; go to sleep
	rjmp	Loop


; ================================================================================================
; Initialize hardware (timers, ports, etc)
; ================================================================================================
Hardware_Init:
	; setup special registers
	clr		rPWM_POS
	clr		rACTIVE_LED

	; setup timer0
	ldi 	rmp, 0								; Normal mode
	out 	TCCR0A, rmp
	ldi 	rmp, (1<<CS02) | (1<<CS00)			; CLK/1024
	out 	TCCR0B, rmp
	ldi		rmp, PRIMARY_DELAY
	out		OCR0A, rmp
	in		rmp, TIMSK0							; enable compare-A interrupt
	ori		rmp, (1<<OCIE0A)
	out		TIMSK0, rmp

	; setup analog comparator
	cbi		ADCSRA, ADEN						; disable a/d converter
	cbi		ACSR, ACD							; enable analog comparator
	sbi		ACSR, ACBG							; use band-gap (1.1v ref)
	cbi		DDRB, PORTB1						; set compare input pin as input
	sbi		DIDR0, AIN1D						; disable digital input on AIN1

	; setup sleep mode (idle only)
	in		rmp, MCUCR
	andi	rmp, ~(1<<SM1)						; set SM1 to 0
	andi	rmp, ~(1<<SM0)						; set SM0 to 0
	ori		rmp, (1<<SE)						; set SE to 1
	out		MCUCR, rmp

	; clear the PWM channel data
	rcall	PwmChnDrvr_Clear

	ret


; ================================================================================================
;	B E G I N  A L L  T A B L E  S T O R A G E
; ================================================================================================
;								001          010          010          100          100          001
LED_PORT_VALUES:		.db		0b00000001,  0b00001000,  0b00001000,  0b00010000,  0b00010000,  0b00000001
;								011          110          011          110			101          101
LED_DDRX_VALUES:		.db		0b00001001,  0b00011000,  0b00001001,  0b00011000,  0b00010001,  0b00010001

;1		2		3		4		5		6		7		8		9		10		11		12		13		14		15		16
BRIGHTNESS_DATA:                .db             \
10,     10,     10,     10,     10,     10,     10,     10,     10,     11,     13,     14,     15,     17,     18,     19,\
21,     22,     23,     25,     26,     27,     29,     30,     31,     33,     34,     35,     37,     38,     40,     41,\
42,     44,     45,     47,     48,     49,     51,     52,     54,     55,     57,     58,     60,     61,     63,     64,\
66,     67,     69,     70,     72,     73,     75,     76,     78,     80,     81,     83,     85,     86,     88,     90,\
91,     93,     95,     97,     98,     100,    102,    104,    106,    107,    109,    111,    113,    115,    117,    119,\
121,    123,    125,    127,    129,    131,    134,    136,    138,    140,    143,    145,    147,    150,    152,    154,\
157,    159,    162,    165,    167,    170,    173,    175,    178,    181,    184,    187,    190,    193,    196,    199,\
203,    206,    209,    213,    216,    220,    224,    228,    231,    235,    239,    243,    248,    252,    252,    248,\
243,    239,    235,    231,    228,    224,    220,    216,    213,    209,    206,    203,    199,    196,    193,    190,\
187,    184,    181,    178,    175,    173,    170,    167,    165,    162,    159,    157,    154,    152,    150,    147,\
145,    143,    140,    138,    136,    134,    131,    129,    127,    125,    123,    121,    119,    117,    115,    113,\
111,    109,    107,    106,    104,    102,    100,    98,     97,     95,     93,     91,     90,     88,     86,     85,\
83,     81,     80,     78,     76,     75,     73,     72,     70,     69,     67,     66,     64,     63,     61,     60,\
58,     57,     55,     54,     52,     51,     49,     48,     47,     45,     44,     42,     41,     40,     38,     37,\
35,     34,     33,     31,     30,     29,     27,     26,     25,     23,     22,     21,     19,     18,     17,     15,\
14,     13,     11,     10,     10,     10,     10,     10,     10,     10,     10,     10

TABLE_MULT_OFFSET:      .db     0,      42,     84,     126,    168,    210


.INCLUDE "pwmchndrvr.asm"
