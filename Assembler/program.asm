; program.asm
; Static sprite test for Basys 3 + VGA
;
; MMIO:
; [16] = SPRITE_X
; [17] = SPRITE_Y
; [18] = SPRITE_TILE
; [19] = SPRITE_EN
;
; This should place one sprite on screen and hold it there.

        ADDI R1, R0, 16      ; R1 = sprite MMIO base address

        ADDI R2, R0, 20      ; sprite_x = 20
        STORE R2, R1, 0

        ADDI R2, R0, 12      ; sprite_y = 12
        STORE R2, R1, 1

        ADDI R2, R0, 0       ; sprite_tile = 0
        STORE R2, R1, 2

        ADDI R2, R0, 1       ; sprite_en = 1
        STORE R2, R1, 3

LOOP:
        JMP LOOP
