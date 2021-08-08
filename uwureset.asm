;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; UWURESET 1.0 by OERG866
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	list      p=12F508            ; list directive to define processor
	#include <p12F508.inc>        ; processor specific variable definitions

	__CONFIG   _MCLRE_OFF & _CP_OFF & _WDT_OFF & _IntRC_OSC

RESET_VECTOR	CODE   0x1FF      ; processor reset vector

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GPIO DEFINITIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IN_ATXPSON = b'000001'
BIT_IN_ATXPSON = 0

IN_CPURESET = b'000010'
BIT_IN_CPURESET = 1

OUT_ATXPSON = b'000100'
BIT_OUT_ATXPSON = 2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SHUTDOWN CHECK MACRO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CHECK_SHUTDOWN MACRO
	btfsc GPIO, BIT_IN_ATXPSON
	goto SHUTDOWN_DETECTED
	ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MEM VARS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	UDATA

WaitCounter		res	1
WaitCounter2	res	1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; CODE START
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INIT:
	CODE	0x000
	movwf	OSCCAL

START:
; We need to set TOCS bit in OPTION to 0
; so that we can use GP2 as a GPIO
	movlw b'10011111'
	option		

	movlw b'000000'
	movwf GPIO

; GP0 = input PS_ON, GP1 = input PCI_RST, GP2 = output PS_ON
	movlw b'111011'	
	tris GPIO

	bsf GPIO, BIT_OUT_ATXPSON

POWER_SUPPLY_IS_OFF:

; ****** Wait for PS_ON from power supply

WAIT_FOR_PS_ON:
	btfsc GPIO, BIT_IN_ATXPSON
	goto WAIT_FOR_PS_ON

; Turn on the power supply

	bcf GPIO, BIT_OUT_ATXPSON

	call Wait1MS
	call Wait1MS
	call Wait1MS
	call Wait1MS

; Power supply is now on!

POWER_SUPPLY_IS_ON:

; Wait for initial power-on reset to occur
; If we get stuck here for some reason, a manual reset button
; will clear the problem

WAIT_FOR_INITIAL_RESET_HIGH:
;;;;;;;;;;;;; Check for shutdown first
	CHECK_SHUTDOWN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	btfss GPIO, BIT_IN_CPURESET
	goto WAIT_FOR_INITIAL_RESET_HIGH

	call Wait1MS

WAIT_FOR_INITIAL_RESET_LOW:
;;;;;;;;;;;;; Check for shutdown first
	CHECK_SHUTDOWN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	btfsc GPIO, BIT_IN_CPURESET
	goto WAIT_FOR_INITIAL_RESET_LOW
	
	call Wait250MS	
	call Wait250MS	
	call Wait250MS	
	call Wait250MS	

; CPU is now running and we begin our regular loop

LOOP_START:

; Check for RESET or SHUTDOWN

LOOP_WAIT_FOR_RESET_HIGH:
;;;;;;;;;;;;; Check for shutdown first
	CHECK_SHUTDOWN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; We're still turned on, check if we have a reset
	btfss GPIO, BIT_IN_CPURESET
	goto LOOP_WAIT_FOR_RESET_HIGH	; if not, we go back to the loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RESET DETECTED
; CPU is in reset, we now switch off the PSU and wait for a bit. 
	bsf GPIO, BIT_OUT_ATXPSON

; Wait for 2.5 seconds
	call Wait250MS
	call Wait250MS
	call Wait250MS
	call Wait250MS

	call Wait250MS
	call Wait250MS
	call Wait250MS
	call Wait250MS

	call Wait250MS
	call Wait250MS

; Turn PSU back on
	bcf GPIO, BIT_OUT_ATXPSON

; Go back to initial turn-on loop
	goto POWER_SUPPLY_IS_ON


; We detected a shutdown. Shut down ATX PSU 
; and wait for it to turn back on again
SHUTDOWN_DETECTED:
	bsf GPIO, BIT_OUT_ATXPSON
	goto POWER_SUPPLY_IS_OFF


Wait250MS:
; Wait 250MS
; Call Wait1MS 250 times xD
	movlw .250
	movwf WaitCounter2
_wait250:
	call Wait1MS
	decfsz WaitCounter2, f
	goto _wait250
	retlw 0
	

Wait1MS:
; Wait 1MS
; BURN 1000+6-4-1 CYCLES
	movlw .249
	movwf WaitCounter
_wait1:
	nop
	decfsz WaitCounter, f
	goto _wait1
	retlw 0


	END



	