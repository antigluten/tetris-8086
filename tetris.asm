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

@clear_cur_figure:
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
    ; shl bx, 1 ; * 2

    ; x + y * FIELD_WIDTH
    add bx, ax

    shl bx, 1

    ;add bx, HOR_BORDER_WIDTH    

    add di, bx

    lea si, z_figure

    mov bx, 4
    @row_c:
        add di, HOR_BORDER_WIDTH
        mov cx, 4
        @col_c:
            lodsb
            or al, al
            jz @skip_c

            ; mov ah, 0fh
            mov ah, 09h
            ; mov al, 5bh
            mov al, 20h
            stosw

            ; mov al, 5dh
            mov al, 20h
            stosw

            loop @col_c
            jmp @end_c
    @skip_c:
        add di, 4
        loop @col_c
    @end_c:
        add di, FIELD_WIDTH + FIGURE_WIDTH + HOR_BORDER_WIDTH
        dec bx
        jnz @row_c

    ret

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
    ; shl bx, 1 ; * 2

    ; x + y * FIELD_WIDTH
    add bx, ax

    shl bx, 1

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

    ; i need to check whether there is a collission for the current figure
    ; to do so i need to go over the 4x4 square where my piece is located
    ; and overlay the figure position on the memory bitmap to get same entries
    ; for square[i] in memory[coordinate] where value is not zero we get collision 
    ; and return the value to the present state and doesn't do anything and create
    ; new figure
    ;
    ; steps:
    ; loop through non zero values of piece and compare its future location with 
    ; memory, if all the pieces zero we can place the figure, if there is a non 
    ; zero value we doesn't do anything and return everything in place as it was.
@collision_check: 

    ; [0][1][0][0]
    ; [1][1][0][0]
    ; [1][0][0][0]
    ; [0][0][0][0]

    ; calculate index to memory

    lea di, RAM
    mov ax, @data
    mov es, ax

    mov bx, word ptr [x]

    mov al, bh
    mov ah, FIELD_WIDTH
    mul ah

    mov bh, 0
    shl bx, 1

    add bx, ax
    shl bx, 1

    add di, bx

    ; load current figure

    lea si, z_figure

    @cc_row:
    mov bx, 4
    add di, HOR_BORDER_WIDTH

    mov cx, 4

    @cc_col:
    lodsb
    or al, al
    jz @cc_skip

    mov dx, es:[di]
    ;or dx, dx
    cmp dh, BACKGROUND
    jne @cc_collision

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

@main_loop:
    call @border
    call @draw_figure
    call @copyToVRAM

    call @clear_cur_figure
    ; mov ah, 08h
    ; int 21h
    ; jz @return

    ; wait for a keypress
    ;mov ah, 0h
    ;int 16h

    cmp ax, KEY_ESC
    je @exit

    cmp ax, KEY_L_ARROW
    je @left_arrow

    cmp ax, KEY_R_ARROW
    je @right_arrow

    @return:

    call @clear_cur_figure

    mov al, byte ptr [y]
    inc al
    mov byte ptr [y], al

    call @collision_check
    jc @exit

    mov ah, 86h
    mov cx, 0fh
    mov dx, 4240h
    int 15h

    jmp @main_loop

    @left_arrow:
        mov al, byte ptr [x]
        or al, al
        jz @return
        dec al
        mov byte ptr [x], al
        jmp @return

    @right_arrow:
        mov al, byte ptr [x]
        inc al
        mov byte ptr [x], al
        jmp @return

    @exit:
        call exit_program

    ret

exit_program proc
    mov ah, 4ch
    int 21h
exit_program endp

main proc
    mov ax, @data
    mov ds, ax

    ; set timer interval 18.2 per sec
    ; mov ah, 86h
    ; xor cx, cx
    ; mov dx, 500 ; 500 mills
    ; int 21h

    ;call @fallLoop
    call @main_loop

    call exit_program

    .exit
main endp
end main