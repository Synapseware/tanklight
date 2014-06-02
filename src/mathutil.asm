; ================================================================================================
;	Multiplies two 8 bit values with a 16 bit result.
;	Takes two operands:
;		r22, r24
;	Result is in:
;		r24, r25
;	Uses:
;		r21, r22, r23, r24, r25, r0
; ================================================================================================
;---------------------------------------------------------------------------------------------------------
; Multiplication 8x8=>16 (~110 cycles)
;	Operands should be in r16, r17
;	Result will be placed back into r16, r17
;	All other registers preserved
; r16 = A
; r17 = B
; r18 = Temp
; r19 = Count
; X   = Result (temporary, moved back to r16,r17)
; r20 = working register
;---------------------------------------------------------------------------------------------------------
Mult8x8_16:
	push	XH
	push	XL
	push	r18
	in		r18, SREG
	push	r18
	push	r19
	push	r20

_mult8_setup:
	ldi		XH, 0					; result = 0
	ldi		XL, 0
	mov		r18, r16				; temp = A
	ldi		r19, 0
	ldi		r20, 8					; count = 8

_mult8_loop:
	ror		r17						; shift B right through carry
	brcc	_mult8_2				; if (carry = 1) then result = result + temp

	add		XL, r18					; result = result + temp
	adc		XH, r19
_mult8_2:
	lsl		r18						; multiply temp * 2
	rol		r19

	dec		r20
	brne	_mult8_loop

	mov		r16, XL
	mov		r17, XH

_mult8_done:
	pop		r20
	pop		r19
	pop		r18
	out		SREG, r18
	pop		r18
	pop		XL
	pop		XH
	ret
