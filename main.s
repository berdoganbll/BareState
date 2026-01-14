; EE315 Project - Two Button Sequence with LED Feedback

; code by Bilal ERDOGAN

; Hardware:
; PF0 (SW2) and PF4 (SW1) as Inputs
; PB0 and PB1 as Outputs (Connected to External LEDs)

; --- Register Definitions (Datasheet Mappings) ---
SYSCTL_RCGCGPIO_R  EQU 0x400FE608
GPIO_PORTF_DATA_R  EQU 0x400253FC
GPIO_PORTF_DIR_R   EQU 0x40025400
GPIO_PORTF_DEN_R   EQU 0x4002551C
GPIO_PORTF_PUR_R   EQU 0x40025510
GPIO_PORTF_LOCK_R  EQU 0x40025520
GPIO_PORTF_CR_R    EQU 0x40025524

GPIO_PORTB_DATA_R  EQU 0x400053FC
GPIO_PORTB_DIR_R   EQU 0x40005400
GPIO_PORTB_DEN_R   EQU 0x4000551C

; --- Constants ---
LOCK_KEY           EQU 0x4C4F434B  ; Magic Number to unlock PF0

        AREA    |.text|, CODE, READONLY, ALIGN=2
        THUMB
        EXPORT  Start

Start
    ; ---------------------------------------------------------
    ; 1. Clock Initialization
    ; ---------------------------------------------------------
    LDR R0, =SYSCTL_RCGCGPIO_R
    LDR R1, [R0]
    ORR R1, R1, #0x22      ; Turn on Port F (Bit 5) AND Port B (Bit 1) -> 0010 0010 = 0x22
    STR R1, [R0]
    NOP
    NOP

    ; ---------------------------------------------------------
    ; 2. Port F Initialization (INPUTS - SW1 & SW2)
    ; ---------------------------------------------------------
    LDR R0, =GPIO_PORTF_LOCK_R
    LDR R1, =LOCK_KEY
    STR R1, [R0]           ; 1. Unlock Port F (for PF0)
    
    LDR R0, =GPIO_PORTF_CR_R
    MOV R1, #0x01          ; 2. Commit PF0
    STR R1, [R0]

    LDR R0, =GPIO_PORTF_DIR_R
    LDR R1, [R0]
    BIC R1, R1, #0x11      ; 3. PF4 and PF0 are INPUTS (Clear bits 0 and 4)
    STR R1, [R0]

    LDR R0, =GPIO_PORTF_PUR_R
    LDR R1, [R0]
    ORR R1, R1, #0x11      ; 4. Enable Pull-Up for PF0 and PF4
    STR R1, [R0]

    LDR R0, =GPIO_PORTF_DEN_R
    LDR R1, [R0]
    ORR R1, R1, #0x11      ; 5. Digital Enable for PF0 and PF4
    STR R1, [R0]

    ; ---------------------------------------------------------
    ; 3. Port B Initialization (OUTPUTS - LEDs)
    ; ---------------------------------------------------------
    LDR R0, =GPIO_PORTB_DIR_R
    LDR R1, [R0]
    ORR R1, R1, #0x07      ; PB0, PB1 and PB2 are OUTPUTS (Set bits 0 and 1)
    STR R1, [R0]

    LDR R0, =GPIO_PORTB_DEN_R
    LDR R1, [R0]
    ORR R1, R1, #0x07      ; Digital Enable for PB0, PB1 and PB2
    STR R1, [R0]

    ; ---------------------------------------------------------
    ; 4. Main Logic Loop initialization
    ; ---------------------------------------------------------
    MOV R4, #0  ; Flag for SW2 (PF0). 0 = Not Pressed, 1 = Pressed Before
    MOV R5, #0  ; Flag for SW1 (PF4). 0 = Not Pressed, 1 = Pressed Before
    
    ; Register Usage in Loop:
    ; R0 -> Port F Data Address
    ; R1 -> Port F Data Value (Read)
    ; R2 -> Port B Data Address
    ; R3 -> Port B Data Value (Write)
    
    LDR R0, =GPIO_PORTF_DATA_R
    LDR R2, =GPIO_PORTB_DATA_R

Loop
    ; --- Step A: Read Inputs ---
    LDR R1, [R0]           ; Read switches (PF0, PF4)
    LDR R3, [R2]           ; Read current LED status (to toggle)

    ; --- Step B: Check SW2 (PF0) ---
    TST R1, #0x01          ; Check Bit 0
    BNE SW2_Released       ; If Bit 0 is 1 (Not Zero), button is RELEASED (Negative Logic)
    
    ; SW2 IS PRESSED (Logic 0)
    MOV R4, #1             ; Mark flag: It has been pressed!
    EOR R3, R3, #0x01      ; Toggle PB0 (Blink effect)
    B   Check_SW1          ; Done with SW2 for now

SW2_Released
    ; SW2 IS RELEASED (Logic 1)
    CMP R4, #1             ; Was it pressed before?
    BNE TurnOff_LED1       ; If never pressed, keep LED OFF
    ORR R3, R3, #0x01      ; If released but marked, keep LED ON (Steady)
    B   Check_SW1
TurnOff_LED1
    BIC R3, R3, #0x01      ; Ensure LED is OFF

Check_SW1
    ; --- Step C: Check SW1 (PF4) ---
    TST R1, #0x10          ; Check Bit 4
    BNE SW1_Released       ; If Bit 4 is 1 (Not Zero), button is RELEASED
    
    ; SW1 IS PRESSED (Logic 0)
    MOV R5, #1             ; Mark flag
    EOR R3, R3, #0x02      ; Toggle PB1 (Blink effect)
    B   Apply_Output
    
SW1_Released
    ; SW1 IS RELEASED (Logic 1)
    CMP R5, #1             ; Was it pressed before?
    BNE TurnOff_LED2
    ORR R3, R3, #0x02      ; Keep LED ON (Steady)
    B   Apply_Output
TurnOff_LED2
    BIC R3, R3, #0x02      ; Ensure LED is OFF

Apply_Output
    STR R3, [R2]           ; Write new LED states to Port B

    ; --- Step D: Delay ---
    ; We need a delay so the "Blink" is visible to human eye.
    BL  Delay

    ; --- Step E: Check Exit Condition ---
    ; Exit if: (R4==1) AND (R5==1) AND (PF0 Released) AND (PF4 Released)
    
    CMP R4, #1             ; Has SW2 been pressed?
    BNE Loop               ; No, keep looping
    
    CMP R5, #1             ; Has SW1 been pressed?
    BNE Loop               ; No, keep looping
    
    TST R1, #0x01          ; Is SW2 currently Released? (Bit 0 should be 1)
    BEQ Loop               ; No (Zero flag means it's 0, pressed), keep looping
    
    TST R1, #0x10          ; Is SW1 currently Released? (Bit 4 should be 1)
    BEQ Loop               ; No, keep looping

    ; If we are here, ALL conditions met!
    B   Done

; ---------------------------------------------------------
; Subroutine: Delay
; Simple busy-wait delay approx 0.1 sec (at 16MHz)
; ---------------------------------------------------------
Delay
    LDR R6, =800000       ; Large number for delay
Delay_Loop
    SUBS R6, R6, #1
    BNE  Delay_Loop
    BX   LR

; ---------------------------------------------------------
; Program End
; ---------------------------------------------------------
Done
    ; Turn OFF switch LEDs & turn ON end LED on Port B before finishing
    MOV R3, #0x04
    STR R3, [R2]
    
DeadLoop
    B   DeadLoop           ; Infinite loop to stop execution safely

    END