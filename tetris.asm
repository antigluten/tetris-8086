.model small
.stack 100h
.8086

.data

W_BYTE equ 1
W_WORD equ 2

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


square             db         4,4,0,0
                   db         4,4,0,0
                   db         0,0,0,0
                   db         0,0,0,0

; LOGIC              byte       PLAYFIELD_HEIGHT * PLAYFIELD_WIDTH DUP(0)

.code

@draw_figure:
    lea di, RAM
    mov ax, @data
    mov es, ax

    ;mov bx, 0
    ;mov al, bh
    ;mov ah, 160
    ;mul ah

    ;mov bh, 0
    ;shl bx, 1

    ;add bx, 2

    lea si, square

    mov bx, 4
    @row:
        mov cx, 4
        @col:
            lodsb
            ;mov al, byte ptr ds:[si]
            ;inc si
            or al, al
            jz @skip

            mov ah, 0fh
            mov al, 5bh
            stosw

            mov al, 5dh
            stosw

            loop @col
            jmp @end
    @skip:
        add di, 4
        loop @col
    @end:
        ;add di, 160 - 2 * 4
        dec bx
        jnz @row



ret
        
@border:
    lea di, RAM
    mov ax, @data
    mov es, ax

    mov bx, 0

    mov dx, FIELD_HEIGHT - 1
    @@border_loop:
        mov al, CHAR_DOT
        mov ah, BACKGROUND
        stosw

        add di, FIELD_WIDTH * 2 - 2 * W_WORD

        mov al, CHAR_DOT
        mov ah, BACKGROUND
        stosw

        dec dx 
    loopnz @@border_loop

    mov cx, FIELD_WIDTH
    mov al, CHAR_DOT
    mov ah, BACKGROUND
    rep stosw

    ret

@copyToVRAM:
    call @border
    call @draw_figure

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
main endp
end main