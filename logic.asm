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

x db 4
y db 0

cur_figure dw offset l_figure

LOGIC byte 252 DUP (0)

KEY_ESC            equ        011bh
KEY_L_ARROW        equ        4b00h
KEY_R_ARROW        equ        4d00h

KEY_L        equ        4bh
KEY_R        equ        4dh
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

    mov ax, @data
    mov es, ax

    ; calculate index to memory

    lea di, LOGIC
    mov ax, @data
    mov es, ax

    ; y, x
    mov bx, word ptr [x]

    ; y * width
    mov al, bh
    mov ah, FIELD_WIDTH
    mul ah

    ; remove y from bh
    mov bh, 0

    ; add x to (y * width)
    add bx, ax

    ; add offset to pointer of the array
    add di, bx

    ; load current figure
    lea si, z_figure
    ;mov si, word ptr [cur_figure]
    
    ; DI -> LOGIC
    ; SI -> FIGURE
    ; ES -> @DATA

    mov bx, 4
    @cc_row:
    ; add border width
    add di, 1

    mov cx, 4
    @cc_col:

    ; check whether we have non zero block
    lodsb
    or al, al
    jz @cc_skip

    mov dl, es:[di]
    or dl, dl
    jnz @cc_collision

    @cc_skip:
    add di, 1

    loop @cc_col

    add di, FIELD_WIDTH - 4 - 1

    dec bx
    jnz @cc_row 

    clc
    ret

    @cc_collision:
    ;mov byte ptr ds:[di], 8
    stc 
    ret

@store_figure:
    mov ax, @data
    mov es, ax
    
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

@clear_figure:
    mov ax, 0b800h
    mov es, ax
    
    mov di, 0

    ; bl = x, bh = y
    mov bx, word ptr [x]

    ; y * FIELD_WIDTH
    mov al, bh
    mov ah, 160
    mul ah

    ; clear y from bx
    mov bh, 0
    shl bx, 1 ; 1 figure takes 2 block
    shl bx, 1 ; each block is 2 byte width
    ; add bx, 1 ; left border
    ; x + y * FIELD_WIDTH
    add bx, ax

    add di, bx

    ;mov si, word ptr [cur_figure]
    ;mov si, word ptr [l_figure]
    ;lea si, cur_figure
    lea si, z_figure

    mov bx, 4
    @cf_row:
        add di, 4 ; add left border
        add di, 16

        mov cx, 4

        @cf_col:
        lodsb
        or al, al
        jz @cf_skip

        mov al, 02eh
        mov ah, 00fh

        mov word ptr es:[di], ax
        add di, 2
        mov word ptr es:[di], ax
        add di, 2

        loop @cf_col
        jmp @cf_end
    @cf_skip:
        add di, 4
        loop @cf_col
    @cf_end:
        add di, 160 - 4 * 2 * 2 - 4
        sub di, 16
        dec bx

        jnz @cf_row

    ret

@render_figure:
    mov ax, 0b800h
    mov es, ax
    
    mov di, 0

    ; bl = x, bh = y
    mov bx, word ptr [x]

    ; y * FIELD_WIDTH
    mov al, bh
    mov ah, 160
    mul ah

    ; clear y from bx
    mov bh, 0
    shl bx, 1 ; 1 figure takes 2 block
    shl bx, 1 ; each block is 2 byte width
    ; add bx, 1 ; left border
    ; x + y * FIELD_WIDTH
    add bx, ax

    add di, bx

    ;mov si, word ptr [cur_figure]
    ;mov si, word ptr [l_figure]
    ;lea si, cur_figure
    lea si, z_figure

    mov bx, 4
    @rf_row:
        add di, 4 ; add left border
        add di, 16

        mov cx, 4

        @rf_col:
        lodsb
        or al, al
        jz @rf_skip

        mov al, 24h
        mov ah, 00fh

        mov word ptr es:[di], ax
        add di, 2
        mov word ptr es:[di], ax
        add di, 2

        loop @rf_col
        jmp @rf_end
    @rf_skip:
        add di, 4
        loop @rf_col
    @rf_end:
        add di, 160 - 4 * 2 * 2 - 4
        sub di, 16
        dec bx

        jnz @rf_row

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

    cmp al, 0f8h
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

indicate proc

    mov ax, 0b800h
    mov es, ax
    mov di, 0

    mov ah, 00fh
    mov al, 025h
    mov word ptr es:[di + 160 - 2], ax

    ret
indicate endp

main proc
    mov ax, @data
    mov ds, ax

    ;call clear
    call @border

    ;call @collision_check
    ;jc @indicate

    jmp @ex

    @indicate:
    mov ax, 0b800h
    mov es, ax
    mov di, 0

    mov ah, 00fh
    mov al, 025h
    mov word ptr es:[di + 160 - 2], ax

    @ex:

    call @render

    ;mov ah, 4ch
    ;int 21h
    ;.exit

    @main_loop:
        call @render_figure
        call @collision_check
        jc @return

        jmp @handle_keyboard

        @no_key_pressed:
        ; timer
        mov ah, 86h
        ;mov cx, 0fh
        ;mov dx, 4240h

        mov cx, 03h
        mov dx, 0d090h
        
        int 15h

        mov al, byte ptr [y]
        inc al
        mov byte ptr [y], al

        call @render
        call @render_figure

    jmp @main_loop

    @return:

    mov al, byte ptr [y]
    dec al
    mov byte ptr [y], al
    
    call @store_figure
    call @render

    jmp @spawn_new_figure

    ; -- DEBUG --
    lea si, LOGIC

    @exit:
    mov ah, 4ch
    int 21h
    .exit

    @handle_keyboard:
        mov ah, 01h
        int 16h 
        jz @no_key_pressed
        mov ah, 00h
        int 16h
        cmp al, 27
        je @exit

        cmp ah, KEY_L
        je @handle_move_left

        cmp ah, KEY_R
        je @handle_move_right

        jmp @no_key_pressed

    @handle_move_left:
        mov al, byte ptr [x]
        dec al
        mov byte ptr [x], al

        call @collision_check
        jnc @ml_skip

        mov al, byte ptr [x]
        inc al
        mov byte ptr [x], al

        @ml_skip:
        jmp @no_key_pressed

    @handle_move_right:
        mov al, byte ptr [x]
        inc al
        mov byte ptr [x], al

        call @collision_check
        jnc @mr_skip

        mov al, byte ptr [x]
        dec al
        mov byte ptr [x], al

        @mr_skip:
        jmp @no_key_pressed

    @spawn_new_figure:
    mov byte ptr [y], 0
    mov byte ptr [x], 4

    jmp @main_loop
main endp
end main


