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

    ; [1][0][0][0]
    ; [1][1][0][0]
    ; [0][1][0][0]
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

    add bx, ax

    add di, bx

    ; load current figure
    lea si, z_figure
    ;mov si, word ptr [cur_figure]
    
    ; DI -> LOGIC
    ; SI -> FIGURE
    ; ES -> @DATA

    mov bx, 4
    @cc_row:
    add di, 1

    mov cx, 4
    @cc_col:

    ; check whether we have non zero block
    lodsb
    or al, al
    jz @cc_skip

    ;mov dx, es:[di]
    mov dx, es:[di]
    ;mov dl, 0
    or dl, dl
    jnz @cc_collision

    @cc_skip:
    add di, 1

    loop @cc_col

    add di, FIELD_WIDTH - 4 - 2

    ; -- debug --
    ;mov byte ptr es:[di], 08h

    dec bx
    jnz @cc_row 

    clc
    ret

    @cc_collision:
    ;mov byte ptr ds:[di], 8
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

    add di, bx

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

@render:
    lea si, LOGIC

    mov ax, 0b800h
    mov es, ax
    mov di, 0

    mov dx, 21
    @r_row:

    add di, 16 ; offset

    mov cx, 12

    @r_col:

    mov al, byte ptr ds:[si]
    inc si
    ;lodsb
    or al, al
    jz @r_empty

    cmp al, 9
    je @r_border

    cmp al, 8
    je @r_indicator

    mov al, 24h
    mov ah, 00fh

    @r_ret:

    mov word ptr es:[di], ax
    add di, 2
    mov word ptr es:[di], ax
    add di, 2
    ;stosw
    ;stosw

    ;sub si, 2

    loopnz @r_col

    add di, 160 - FIELD_WIDTH * 4
    sub di, 16 ; offset

    dec dx
    jnz @r_row

    ret

@r_border:
    mov al, 023h ; TODO: replace with dot
    mov ah, 00fh
    jmp @r_ret

@r_empty:
    mov al, 02eh
    mov ah, 00fh
    jmp @r_ret

@r_indicator:
    mov al, 025h
    mov ah, 00fh
    jmp @r_ret

clear proc
    mov ax, 03h
    int 10h
    ret
clear endp

main proc
    mov ax, @data
    mov ds, ax

    call clear

    call @border
    ;call @store_figure

    call @render

    call @collision_check
    jc @indicate

    call @store_figure
    call @render

    @indicate:
    mov ax, 0b800h
    mov es, ax
    mov di, 0

    mov ah, 00fh
    mov al, 025h
    mov word ptr es:[di + 160 - 2], ax

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

    ; -- DEBUG --
    lea si, LOGIC

    mov ah, 4ch
    int 21h
    .exit
main endp
end main

