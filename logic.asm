.model small
.stack 100h

.data

PLAYFIELD_WIDTH equ 10
PLAYFIELD_HEIGHT equ 20

FIELD_WIDTH equ PLAYFIELD_WIDTH + 2
FIELD_HEIGHT equ PLAYFIELD_HEIGHT + 1

;LOGIC byte (FIELD_WIDTH * FIELD_HEIGHT) DUP(0)

z_figure           db         1,0,0,0
                   db         1,1,0,0
                   db         0,1,0,0
                   db         0,0,0,0

l_figure           db         4,0,0,0
                   db         4,0,0,0
                   db         4,0,0,0
                   db         4,0,0,0

x db 0
y db 0

cur_figure dw offset l_figure

LOGIC byte 252 DUP (0)

.code

@border:
    lea di, LOGIC

    mov ax, @data
    mov es, ax

    mov bx, 0
    mov dx, FIELD_HEIGHT - 1
    @border_loop:

    mov al, 9
    stosb

    add di, FIELD_WIDTH - 2

    mov al, 9
    stosb

    dec dx
    loopnz @border_loop

    mov cx, FIELD_WIDTH
    mov al, 9
    rep stosb

    ret


@collision_check: 

    ; [0][1][0][0]
    ; [1][1][0][0]
    ; [1][0][0][0]
    ; [0][0][0][0]

    ; calculate index to memory

    lea di, LOGIC
    mov ax, @data
    mov es, ax

    mov bx, word ptr [x]

    mov al, bh
    mov ah, PLAYFIELD_WIDTH
    mul ah

    mov bh, 0
    shl bx, 1

    add bx, ax
    shl bx, 1

    add di, bx

    ; load current figure
    ;lea si, z_figure
    mov si, word ptr [cur_figure]

    @cc_row:
    mov bx, 4

    mov cx, 4

    @cc_col:
    lodsb
    or al, al
    jz @cc_skip

    mov dx, es:[di]
    or dx, dx
    jnz @cc_collision

    @cc_skip:
    add di, 4

    loop @cc_col

    dec bx
    jnz @cc_row 

    clc
    ret

    @cc_collision:
    stc 
    ret

@store_figure:
    ;mov di, offset LOGIC
    lea di, LOGIC
    ; bl = x, bh = y
    mov bx, word ptr [x]

    ; y * FIELD_WIDTH
    mov al, bh
    mov ah, FIELD_WIDTH
    mul ah

    ; clear y from bx
    mov bh, 0
    ; add bx, 1 ; left border
    ; x + y * FIELD_WIDTH
    add bx, ax

    ;add di, bx

    ;mov si, word ptr [cur_figure]
    ;mov si, word ptr [l_figure]
    ;lea si, cur_figure
    lea si, z_figure

    mov bx, 4
    @row:
        add di, 1 ; add left border
        mov cx, 4

        @col:
        lodsb
        or al, al
        jz @skip

        mov al, 0FFh
        stosb

        loop @col
        jmp @end
    @skip:
        add di, 1
        loop @col
    @end:
        add di, FIELD_WIDTH - 4 - 1
        dec bx

        jnz @row

ret


main proc
    mov ax, @data
    mov ds, ax

    call @border

    call @store_figure

    lea si, LOGIC

    mov ah, 4ch
    int 21h
    .exit

    @main_loop:
        call @collision_check
        jc @return

        mov al, byte ptr [y]
        inc al
        mov byte ptr [y], al

    jmp @main_loop

    @return:
    
    call @store_figure
    mov si, offset LOGIC

    mov ah, 4ch
    int 21h
    .exit
main endp
end main

