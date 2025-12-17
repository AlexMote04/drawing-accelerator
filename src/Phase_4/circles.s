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
UNIT_CIRCLE equ   2           ; Unit ID for Circle Drawer

; -----------------------------------------------------------------------------
; Main Program
; -----------------------------------------------------------------------------
main:
    li s0, DRAW_BASE           ; Load Base Address into s0

    ; -----------------------------------------
    ; 1. Initial Cleanup
    ; -----------------------------------------
    li t0, 0x00
    sw t0, REG_R0[s0]          ; Black Background
    li t0, UNIT_CLEAR
    sw t0, REG_CMD[s0]         ; Clear Screen
    jal wait_for_done

    ; -----------------------------------------
    ; 2. Loop: Draw Increasing Circles (1 to 320)
    ; -----------------------------------------
    li s1, 1                   ; s1 = Current Radius (Start at 1)
    li s2, 320                 ; s2 = Max Radius
    li t5, 0x01

draw_loop:
    bgt s1, s2, done  ; If Current Radius > 320, exit loop

    ; Set Coordinates (Center of 640x480 screen)
    li t0, 320
    sw t0, REG_R0[s0]          ; Set X = 320
    li t0, 240
    sw t0, REG_R1[s0]          ; Set Y = 240

    ; Set Radius (from loop counter s1)
    sw s1, REG_R4[s0]

    ; Set Colour 
    ; Change colour
    addi t5, t5, 1                
    sw t5, REG_R6[s0]

    ; Trigger Circle Draw
    li t0, UNIT_CIRCLE
    sw t0, REG_CMD[s0]
    
    ; Wait for GPU
    jal wait_for_done

    ; Increment Radius and repeat
    addi s1, s1, 1
    j draw_loop

done:
    j done                     ; Infinite loop

; -----------------------------------------------------------------------------
; Subroutine: wait_for_done
; -----------------------------------------------------------------------------
wait_for_done:
    lw   t1, REG_STATUS[s0]    ; Read Status Register
    andi t1, t1, 0x100         ; Mask Bit 8
    beqz t1, wait_for_done     ; Loop if 0
    
    li   t1, 0x100
    sw   t1, REG_S_CLR[s0]     ; Acknowledge interrupt
    ret