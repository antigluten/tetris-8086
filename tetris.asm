.model small
.stack 100h
.8086

.data

KEY_ESC            equ        011bh
KEY_L_ARROW        equ        4b00h
KEY_R_ARROW        equ        4d00h

W_BYTE equ 1
W_WORD equ 2

VRAM               equ        0b800h
PLAYFIELD_WIDTH    equ        10
PLAYFIELD_HEIGHT   equ        20
BOTTOM_BORDER_HEIGHT equ      2
HOR_BORDER_WIDTH     equ      2

FIGURE_WIDTH       equ        4

FIELD_HEIGHT       equ        PLAYFIELD_HEIGHT + BOTTOM_BORDER_HEIGHT
FIELD_WIDTH        equ        (PLAYFIELD_WIDTH + HOR_BORDER_WIDTH) * 2

RAM                byte       (FIELD_HEIGHT * FIELD_WIDTH) * 2 DUP(0)

CHAR_DOT           equ         02eh 
BACKGROUND         equ         00fh


square             db         4,4,0,0
                   db         4,4,0,0
                   db         0,0,0,0
                   db         0,0,0,0

l_figure           db         4,0,0,0
                   db         4,0,0,0
                   db         4,0,0,0
                   db         4,0,0,0

z_figure           db         4,0,0,0
                   db         4,4,0,0
                   db         0,4,0,0
                   db         0,0,0,0

x                  db         5
y                  db         2

; LOGIC              byte       PLAYFIELD_HEIGHT * PLAYFIELD_WIDTH DUP(0)

.code

@draw_figure:
    lea di, RAM
    mov ax, @data
    mov es, ax

    ; bl = x, bh = y
    mov bx, word ptr [x]

    ; y * FIELD_WIDTH
    mov al, bh
    mov ah, FIELD_WIDTH
    mul ah

    ; clear y from bx
    mov bh, 0
    shl bx, 1 ; * 2
    shl bx, 1 ; * 2

    ; x + y * FIELD_WIDTH
    add bx, ax

    ;add bx, HOR_BORDER_WIDTH    

    add di, bx

    lea si, z_figure

    mov bx, 4
    @row:
        add di, HOR_BORDER_WIDTH
        mov cx, 4
        @col:
            lodsb
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
        add di, FIELD_WIDTH + FIGURE_WIDTH + HOR_BORDER_WIDTH
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

@fallLoop:
    call @border
    call @draw_figure
    call @copyToVRAM

    @keyLoop:

    mov ah, 01
    int 16h
    jz @noKey

    cmp ax, KEY_ESC
    je @exit

    cmp ax, KEY_L_ARROW
    je @left_arrow

    cmp ax, KEY_R_ARROW
    je @right_arrow

    @return: 
    @noKey:

    jmp @fallLoop

    @left_arrow:
        mov al, byte ptr [x]
        or al, al
        jz @keyLoop
        dec al
        mov byte ptr [x], al
        jmp @return

    @right_arrow:
        mov al, byte ptr [x]
        inc al
        mov byte ptr [x], al
        jmp @keyLoop

    @exit:
        mov ah, 4ch
        int 21h

    ret

main proc
    mov ax, @data
    mov ds, ax

    ;call @fallLoop
    call @fallLoop

    mov ah, 4ch
    int 21h
    .exit
main endp
end main