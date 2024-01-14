.model small
.stack 100h
.8086

.data

VRAM               equ        0b800h
PLAYFIELD_WIDTH    equ        10
PLAYFIELD_HEIGHT   equ        20
BOTTOM_BORDER_HEIGHT equ      2
HOR_BORDER_WIDTH     equ      2

FIELD_HEIGHT       equ        PLAYFIELD_HEIGHT + BOTTOM_BORDER_HEIGHT
FIELD_WIDTH        equ        (PLAYFIELD_WIDTH + HOR_BORDER_WIDTH) * 2

RAM                byte       (FIELD_HEIGHT * FIELD_WIDTH) * 2 DUP(0)

CHAR_DOT           equ         02eh 
BACKGROUND         equ         00fh

; LOGIC              byte       PLAYFIELD_HEIGHT * PLAYFIELD_WIDTH DUP(0)

.code

@border: 
    mov bx, 0

    mov cx, 0

    mov dx, FIELD_HEIGHT - 1
    @border_loop:
        mov ah, bl
        mov al, FIELD_WIDTH
        mul ah
        
        mov byte ptr [RAM + ax], CHAR_DOT
        mov byte ptr [RAM + ax + 1], BACKGROUND

        add cx, 12

        inc bl
        dec dx 
    loopnz @border_loop

    ret

    mov ax, @data
    mov es, ax

    lea di, RAM

    mov ah, bl
    mov al, FIELD_WIDTH
    mul ah

    shl ax, 1

    add di, ax

    ;mov al, CHAR_DOT
    mov al, 03dh
    mov ah, BACKGROUND
    mov cx, FIELD_WIDTH
    rep stosw

    ;mov byte ptr @data:[RAM], 02eh
    ;mov byte ptr @data:[RAM + 1], 00fh

    ;mov byte ptr @data:[RAM + 2], 02eh
    ;mov byte ptr @data:[RAM + 3], 00fh

    ;mov byte ptr @data:[RAM + (FIELD_WIDTH * 2) - 2], 02eh
    ;mov byte ptr @data:[RAM + (FIELD_WIDTH * 2) - 1], 00fh

    ;mov byte ptr @data:[RAM + FIELD_WIDTH * 2], 02eh
    ;mov byte ptr @data:[RAM + FIELD_WIDTH * 2 + 1], 00fh

    ;mov byte ptr @data:[RAM + FIELD_WIDTH * 4], 02eh
    ;mov byte ptr @data:[RAM + FIELD_WIDTH * 4 + 1], 00fh

    ; mov cx, PLAYFIELD_HEIGHT
    ; @border_loop:
    ;     mov byte ptr es:[di], 020h
    ;     mov byte ptr es:[di + 1], 04fh
    ;     add di, 160 - 1
    ; loop @border_loop

    ret

; @mock:
;     mov byte ptr [squareArray], 'R'
;     mov byte ptr [squareArray + 1], 0x0C

;     ; Top-right corner of the square
;     mov byte ptr [squareArray + 2], 'R'
;     mov byte ptr [squareArray + 3], 0x0C

;     ; Bottom-left corner of the square
;     mov byte ptr [squareArray + 160], 'R'
;     mov byte ptr [squareArray + 161], 0x0C

;     ; Bottom-right corner of the square
;     mov byte ptr [squareArray + 162], 'R'
;     mov byte ptr [squareArray + 163], 0x0C

;     ret

@mockk:
    ;mov ax, RAM
    lea di, RAM
    mov ax, @data
    mov es, ax

    ;mov di, 0

    mov bx, 0

    mov dx, FIELD_HEIGHT
    @@border_loop:
        ;mov ah, bl
        ;mov al, FIELD_WIDTH
        ;mul ah

        mov ah, bl
        mov al, 10
        mul ah

        inc bl
        
        ;mov al, 0
        add al, CHAR_DOT 
        mov ah, BACKGROUND
        stosw
        ;mov word ptr [RAM], ax
        ;mov word ptr ES:[DI], ax

        ;mov al, CHAR_DOT
        ;mov ah, BACKGROUND
        ;mov word ptr [RAM + 2], ax
        ;stosw
        
        ;mov cx, FIELD_WIDTH - 2
        ;mov cx, FIELD_WIDTH - 2
        ;rep stosw

        ;mov al, CHAR_DOT
        ;mov ah, BACKGROUND
        ;stosw

        add di, FIELD_WIDTH * 2 - 1 * 2

        ;add di, 160 - 2
        ;add di, FIELD_WIDTH * 2 - 2 * 2
       ; add di, FIELD_WIDTH * 2

;        add di, 160 - FIELD_WIDTH * 2
        ;sub di, 2

        ;inc bl
        dec dx 
    loopnz @@border_loop

    ret

    mov di, 0
    add di, FIELD_WIDTH * (FIELD_HEIGHT) * 2

    mov al, 04fh
    mov ah, BACKGROUND
    stosw

    ret

@copyToVRAM:
    call @mockk

    mov ax, VRAM
    mov es, ax
    mov di, 0
    ; ES:[DI] -> VRAM

    lea si, RAM
    ; DS:[SI] -> RAM

    mov dx, FIELD_HEIGHT
    @@row:
        mov cx, FIELD_WIDTH
        rep movsw ; DS:[SI] -> ES:[DI]
        ; TODO: - by 2 because of stosw
        add di, 160 - FIELD_WIDTH * 2 
         ;sub si, FIELD_WIDTH * 2
        dec dx
    jnz @@row

    ret

main proc
    mov ax, @data
    mov ds, ax

    call @copyToVRAM

    mov ah, 4ch
    int 21h
    .exit

    ret
    jmp @skipp

    mov ax, VRAM
    mov es, ax
    mov di, 0
    ; ES:[DI] -> VRAM

    lea si, RAM
    ; DS:[SI] -> RAM

    mov dx, FIELD_HEIGHT
    @@row_w:
        mov al, 03dh
        mov ah, BACKGROUND
        mov cx, FIELD_WIDTH
        rep stosw ; AX -> ES:[DI]

        ; TODO: - by 2 because of stosw

        add di, 160 - FIELD_WIDTH * 2
        dec dx
    jnz @@row_w

    mov dx, FIELD_HEIGHT - 1
    mov di, 0
    @@border_loop_:
        mov ah, bl
        mov al, FIELD_WIDTH
        mul ah
        
        mov al, CHAR_DOT
        mov ah, BACKGROUND
        stosw

        mov al, 020h
        mov ah, BACKGROUND
        
        mov cx, FIELD_WIDTH - 2
        rep stosw

        mov al, CHAR_DOT
        mov ah, BACKGROUND
        stosw

        add di, 160 - FIELD_WIDTH * 2

        inc bl
        dec dx 
    loopnz @@border_loop_

    ; call @mock
    ;call @border
    ;call @copyToVRAM

    @skipp:

    mov ah, 4ch
    int 21h
    .exit
main endp
end main