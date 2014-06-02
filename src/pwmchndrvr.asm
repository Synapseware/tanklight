; ================================================================================================
; PWM_Channel_Driver
; Runs the PWM channels
; First portion always turns off all LEDs and turns on the active LED
; If we've completed a full LED refresh, then the PWM value data is updated.
; Uses:
;	X, Z, rmp, rtmp
; To invoke:
;	Registers:
;		rACTIVE_LED
;		rPWM_POS
;	Constants:
;		TOTAL_CHANNELS	(8bit)
;	Data:
;		on_values			(8bit value table, SRAM, element count = TOTAL_CHANNELS)
;		BRIGHTNESS_DATA		(8bit value table, PGRM, element count = TOTAL_CHANNELS)
;		LED_PORT_VALUES		(8bit value table, PGRM, element count = TOTAL_CHANNELS)
;		LED_DDRX_VALUES		(8bit value table, PGRM, element count = TOTAL_CHANNELS)
; ================================================================================================
PwmChnDrvr_Main:
	rcall	PwmChnDrvr_Shutdown

	; Check the active LED channel against the total channels
	; and only process PWM data if we've done a full refresh
	cpi		rACTIVE_LED, TOTAL_CHANNELS
	brlo	_pcd_activate_channel
	clr		rACTIVE_LED

	; Since we completed a full LED refresh,
	; decay or reload the PWM values table
	inc		rPWM_POS
	cpi		rPWM_POS, 0							; if 0, then reload PWM table
	breq	_pcd_seed							; rPWM_POS = 0, reload
	rcall	PwmChnDrvr_decay					; rPWM_POS != 0, so decay first
	rjmp	_pcd_activate_channel
_pcd_seed:
	rcall	PwmChnDrvr_Seed						; rPWM_POS is zero, so reload the data

_pcd_activate_channel:
	; First, turn on the active LED
	; If the SRAM segment @ active_led index > 0, then turn on that LED
	ldi		XH, HIGH(on_values)
	ldi		XL, LOW(on_values)
	clr		rtmp
	add		XL, rACTIVE_LED
	adc		XH, rtmp
	ld		rtmp, X								; load current on_value
	tst		rtmp
	breq	_pcd_activate_next
	ldi		ZH, HIGH(2*LED_PORT_VALUES)
	ldi		ZL, LOW(2*LED_PORT_VALUES)			; load PORT pointer
	clr		rtmp
	add		ZL, rACTIVE_LED						; add active LED offset
	adc		ZH, rtmp
	lpm		rtmp, Z								; load port value
	in		rmp, PORTB
	or		rtmp, rmp
	out		PORTB, rtmp
	ldi		ZH, HIGH(2*LED_DDRX_VALUES)
	ldi		ZL, LOW(2*LED_DDRX_VALUES)			; load DDRX pointer
	clr		rtmp
	add		ZL, rACTIVE_LED						; add active LED offset
	adc		ZH, rtmp
	lpm		rtmp, Z								; load ddr value
	in		rmp, DDRB
	or		rtmp, rmp
	out		DDRB, rtmp

_pcd_activate_next:
	; Move to the next active LED.
	; If we are done with all active LEDs, change our PWM counter	
	inc		rACTIVE_LED
	ret


; ================================================================================================
; PwmChnDrvr_Shutdown
;	Shut down all LED output
; ================================================================================================
PwmChnDrvr_Shutdown:
	in		rmp, DDRB
	andi	rmp, LED_PORT_MASK
	out		DDRB, rmp
	in		rmp, PORTB
	andi	rmp, LED_PORT_MASK
	out		PORTB, rmp
	ret


; ================================================================================================
;	Clears the PWM channel data by writing 0's to all the channel values.
;	Uses:
;		rmp, rtmp, X
; ================================================================================================
PwmChnDrvr_Clear:
	ldi		XH, HIGH(on_values)
	ldi		XL, LOW(on_values)
	clr		rmp
	clr		rtmp
_pcd_clr_loop:
	st		X+, rtmp
	inc		rmp
	cpi		rmp, TOTAL_CHANNELS
	brlo	_pcd_clr_loop
	ret


; ================================================================================================
;	Seeds the PWM channel data by copying values from the main brightness table into the channel
;	data buffer.
;	Uses:
;		rmp, rtmp, X, Z, r22, r23
;	Requires:
;		on_values
;		rOFFSET
;		TOTAL_CHANNELS
;		BRIGHTNESS_DATA
; ================================================================================================
PwmChnDrvr_Seed:
	ldi		XH, HIGH(on_values)
	ldi		XL, LOW(on_values)
	clr		rmp
_pcd_seed_loop:
	ldi		ZH, HIGH(2*TABLE_MULT_OFFSET)		; get our offset...
	ldi		ZL, LOW(2*TABLE_MULT_OFFSET)
	add		ZL, rmp								; add loop index to the offset table address
	brcc	PC+2
	inc		ZH									; add 1 to MSB register if overflow from previous addition
	ldi		YH, 0								; load table offset into Y register
	lpm		YL, Z
	add		YL, rOFFSET							; add our offset
	brcc	PC+2
	inc		YH
	ldi		ZH, 0								; load our 16 bit compare value
	ldi		ZL, LIGHT_TABLE_LEN
	cp		YL, ZL								; compare 16 bit registers
	cpc		YH, ZH
	brlo	PC+4
	sub		YL, ZL								; subtract if over limit...
	sbc		YH, ZH
_pcd_seed_1:
	; Copy brightness values from table to SRAM segment
	ldi		ZH, HIGH(2*BRIGHTNESS_DATA)
	ldi		ZL, LOW(2*BRIGHTNESS_DATA)			; Z is pointer to program memory
	add		ZL, YL								; add offset from rtmp to Z
	brcc	PC+2								; skip over the next instruction (careful with the offset!)
	inc		ZH
	lpm		rtmp, Z								; load the brightness table value
	st		X+, rtmp							; store the brightness table value
	inc		rmp									; increment loop value
	cpi		rmp, TOTAL_CHANNELS
	brlo	_pcd_seed_loop						; continue loop if not done
	ret


; ================================================================================================
;	Decays the PWM channel data
;	Uses:
;		rmp, rtmp, X
; ================================================================================================
PwmChnDrvr_decay:
	ldi		XH, HIGH(on_values)
	ldi		XL, LOW(on_values)
	clr		rmp
_pcd_decay_loop:
	ld		rtmp, X
	cpi		rtmp, 0
	breq	PC+2
	dec		rtmp
	st		X+, rtmp
	inc		rmp									; increment loop value
	cpi		rmp, TOTAL_CHANNELS
	brlo	_pcd_decay_loop						; continue loop if not done
	ret
