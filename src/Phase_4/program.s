; -----------------------------------------------------------------------------
; Constant Definitions
; -----------------------------------------------------------------------------
DRAW_BASE equ    0x00010800   ; Base address of Drawing Engine
REG_R0 equ       0x00         ; Register 0 (X Coord / Clear Colour)
REG_R1 equ       0x04         ; Register 1 (Y Coord)
REG_R4 equ       0x10         ; Register 4 (Radius)
REG_R6 equ       0x18         ; Register 6 (Colour)
REG_CMD equ      0x20         ; Command Register (Write Only)
REG_STATUS equ   0x24         ; Status Register (Read Only)
REG_S_CLR equ    0x28         ; Status Clear Register (Write Only)

UNIT_CLEAR equ   0            ; Unit ID for Clear Screen
UNIT_CIRCLE equ   2            ; Unit ID for Circle Drawer

; -----------------------------------------------------------------------------
; Main Program
; -----------------------------------------------------------------------------
main:
    li s0, DRAW_BASE           ; Load Base Address into s0 (used globally)

    ; -----------------------------------------
    ; 1. Initialization: Clear the Screen
    ; -----------------------------------------
    ; Set Background Colour to Black (0x00)
    li t0, 0x00
    sw t0, REG_R0[s0]          ; Write 0 to R0
    
    ; Trigger Clear Unit
    li t0, UNIT_CLEAR
    sw t0, REG_CMD[s0]         ; Write 0 to Command RegisterUNIT_CIRCLE
    
    ; Wait for Clear to finish
    jal wait_for_done

    ; -----------------------------------------
    ; 2. Draw Concentric Circles
    ; -----------------------------------------
    
    ; --- Circle 1: Big Red ---
    ; Center (320, 240), Radius 150, Colour Red (0xE0)
    li t0, 320
    sw t0, REG_R0[s0]          ; Set X
    li t0, 240
    sw t0, REG_R1[s0]          ; Set Y
    li t0, 150
    sw t0, REG_R4[s0]          ; Set Radius
    li t0, 0xE0
    sw t0, REG_R6[s0]          ; Set Colour (Red)
    
    li t0, UNIT_CIRCLE
    sw t0, REG_CMD[s0]         ; GO
    jal wait_for_done

    ; --- Circle 2: Medium Green ---
    ; Center (320, 240), Radius 100, Colour Green (0x1C)
    li t0, 320
    sw t0, REG_R0[s0]          ; X is unchanged, but safer to rewrite
    li t0, 240
    sw t0, REG_R1[s0]          ; Y is unchanged
    li t0, 100
    sw t0, REG_R4[s0]          ; New Radius
    li t0, 0x1C
    sw t0, REG_R6[s0]          ; New Colour (Green)
    
    li t0, UNIT_CIRCLE
    sw t0, REG_CMD[s0]         ; GO
    jal wait_for_done

    ; --- Circle 3: Small Blue ---
    ; Center (320, 240), Radius 50, Colour Blue (0x03)
    li t0, 320
    sw t0, REG_R0[s0]
    li t0, 240
    sw t0, REG_R1[s0]
    li t0, 50
    sw t0, REG_R4[s0]
    li t0, 0x03
    sw t0, REG_R6[s0]
    
    li t0, UNIT_CIRCLE
    sw t0, REG_CMD[s0]         ; GO
    jal wait_for_done

    ; -----------------------------------------
    ; 3. Corner Test (Verifies Coordinate Limits)
    ; -----------------------------------------
    ; Draw a White Circle at Top-Left (0,0) with Radius 30
    li t0, 0
    sw t0, REG_R0[s0]          ; X = 0
    sw t0, REG_R1[s0]          ; Y = 0
    li t0, 30
    sw t0, REG_R4[s0]          ; Radius = 30
    li t0, 0xFF
    sw t0, REG_R6[s0]          ; Colour = White (0xFF)
    
    li t0, UNIT_CIRCLE
    sw t0, REG_CMD[s0]         ; GO
    jal wait_for_done

    ; -----------------------------------------
    ; 4. End of Program
    ; -----------------------------------------
done:
    j done                     ; Infinite loop to stop processor

; -----------------------------------------------------------------------------
; Subroutine: wait_for_done
; Description: Polls the Status Register until Bit 8 (Done) is set, 
;              then clears the bit.
; -----------------------------------------------------------------------------
wait_for_done:
    ;lw   t1, REG_STATUS[s0]    ; Read Status Register (Offset 0x24)
    li   t1, 0x100
    andi t1, t1, 0x100         ; Mask Bit 8 (0x100 is the 'Done' bit)
    beqz t1, wait_for_done     ; If result is 0, unit is busy -> loop back
    
    ; If we are here, the unit is done. Acknowledge the interrupt.
    li   t1, 0x100
    sw   t1, REG_S_CLR[s0]     ; Write 1 to Bit 8 of Status Clear (Offset 0x28)
    ret