.model small
.stack 100h
.8086

.data

CHAR_SPACE         equ        020h
CHAR_MARK          equ        07ch
CHAR_GT            equ        03eh
CHAR_LS            equ        03ch
CHAR_BORDER        equ        03dh
CHAR_REV_SLASH     equ        05ch
CHAR_SLASH         equ        02fh    

CHAR_DOT           equ        02eh

KEY_ESC            equ        011bh
KEY_L_ARROW        equ        4b00h
KEY_R_ARROW        equ        4d00h

VRAM               equ        0b800h

PIXEL_SCALE        equ        2

PLAYFIELD_WIDTH    equ        10
PLAYFIELD_HEIGHT   equ        20

BOTTOM_BORDER_HEIGHT equ      2
HOR_BORDER_WIDTH     equ      2

FIELD_HEIGHT       equ        PLAYFIELD_HEIGHT + BOTTOM_BORDER_HEIGHT
FIELD_WIDTH        equ        (PLAYFIELD_WIDTH + HOR_BORDER_WIDTH) * 2

field              byte       FIELD_HEIGHT * FIELD_WIDTH       DUP(0)

FIGURE_HEIGHT      equ        4
FIGURE_WIDTH       equ        4

CONSOLE_WIDTH      equ        160

cur_figure         dw         offset    square
cur_x              db         6
cur_y              db         15

z_figure           db         0,3,0,0
                   db         3,3,0,0
                   db         3,0,0,0
                   db         0,0,0,0

l_figure           db         3,0,0,0
                   db         3,0,0,0
                   db         3,0,0,0
                   db         3,0,0,0

square             db         4,4,0,0
                   db         4,4,0,0
                   db         0,0,0,0
                   db         0,0,0,0

X                  db         0
Y                  db         0

.code

clear proc
    mov ax, 3
    int 10h 
clear endp

draw_field proc
    ; [SI: DI]
    ; [field: 0]
    mov si, offset field                ; SI -> offset field
    mov di, 0                           ; DI -> 0
    mov bx, FIELD_HEIGHT

    mov ax, VRAM                      ; videoram
    mov es, ax
    @row:
        mov cx, FIELD_WIDTH

        @col:
            ; TODO: - Move to another proc

            jmp @draw_frame

            @skip:

            call @space

            @print:
                call @background
                ; AX -> ES[DI]
                stosw

            loop @col

        ; DI = CONSOLE_WIDTH * Y + X
        add di, CONSOLE_WIDTH - 2 * FIELD_WIDTH

        dec bx
        jnz @row
    ret

    @background:
        mov ah, 0Fh          ; white/black
        ret

    @space:
        cmp bx, 1
        je @@space

        mov al, cl
        and al, 1
        cmp al, 1
        je @dot 

        @@space:
            mov al, CHAR_SPACE         ; empty space
            ret

    @dot:
        mov al, CHAR_DOT
        ret

    @mark_sign:
        cmp bx, 1
        je @skip

        mov al, CHAR_MARK
        jmp @print

    @left_border:
        cmp bx, 1
        je @skip
        mov al, CHAR_LS
        jmp @print

    @right_border:
        cmp bx, 1
        je @skip

        mov al, CHAR_GT
        jmp @print

    @border:
        mov al, CHAR_BORDER
        jmp @print

    @border_frame:
        mov dx, cx
        and dx, 1                         ; mod 2

        cmp dx, 0
        jne @slash

        mov al, CHAR_REV_SLASH
        jmp @bf_print

        @slash:
            mov al, CHAR_SLASH

        @bf_print:
            jmp @print

    ; draw border frame

    @draw_frame:
        cmp cx, 1
        je @right_border

        cmp cx, 2
        je @mark_sign
        
        cmp cx, FIELD_WIDTH - 1
        je @mark_sign

        cmp cx, FIELD_WIDTH
        je @left_border
        
        cmp bx, 2
        je @border

        cmp bx, 1
        je @border_frame

        jmp @skip


draw_field endp

draw_figure proc
    ; BL = cur_x, BH = cur_y
    mov bx, word ptr [cur_x]
    ; cur_y * 160
    mov al, bh                      ; Y -> BH
    mov ah, CONSOLE_WIDTH           
    mul ah
    ; += cur_x * PIXEL_SCALE + 1
    mov bh, 0                       ; erase Y in BH
    shl bx, 1                       ; consists of two pieces []

    add bx, HOR_BORDER_WIDTH        ; add border offset

    shl bx, 1                       ; * 2 ; PIXEL_WIDTH of an element
    add ax, bx                      ; calc all the pos

    mov di, ax                      ; pos on screen into DI

    mov ax, VRAM  
    mov es, ax                      ; VIDEO_RAM -> ES

    mov si, word ptr [cur_figure]   ; is this a pointer to the cur_figure, or that is
    mov bx, 4
    @@row: 
        mov cx, 4
        @@col: 
            mov al, byte ptr ds:[si]
            inc si
            ;lodsb                  ; DS:[SI] -> AL, update SI
            or al, al               ; skip zeros
            jz @@skip

            mov ah, 0Fh             ; white/black
            mov al, 5bh             ; [
            ;mov es:[di], ax
            ;add di, 2
            stosw                   ; AX -> ES:[DI] ; DI += 2

            mov al, 5dh             ; ]
            stosw                   ; AX -> ES:[DI] ; DI += 2

            loop @@col
            jmp @@end
    @@skip:
        ;mov al, 2eh
        ;mov ah, 0Fh
        ;stosw                ; AX -> ES:[DI] ; DI += 2
        
        ;mov al, 2eh
        ;mov ah, 0Fh
        ;stosw                ; AX -> ES:[DI] ; DI += 2

        add di, 4                ; [] consists of 2 elements, each 2 el width
        loop @@col
    @@end:
        add di, CONSOLE_WIDTH - 2 * 4 * 2
        dec bx
        jnz @@row

    ret
draw_figure endp

fallLoop proc
@fallLoop:
    call draw_field
    call draw_figure

    ret

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

    @noKey:
    @return:

    ;jmp @fallLoop

    ;mov al, byte ptr [cur_y]
    ;inc al
    ;mov byte ptr [cur_y], al

    ; check for colision
    ; TODO: doesn't work figures with height less than 4
    ;cmp al, PLAYFIELD_HEIGHT - FIGURE_HEIGHT
    ;jbe @fallLoop

    mov si, offset cur_figure
    ;jnc @fallLoop
    jmp @fallLoop

    ret

@left_arrow:
    mov al, byte ptr [cur_x]
    or al, al
    jz @keyLoop
    dec al
    mov byte ptr [cur_x], al
    jmp @return

@right_arrow:
    mov al, byte ptr [cur_x]
    inc al
    mov byte ptr [cur_x], al
    jnc @return
    dec byte ptr [cur_x]
    jmp @keyLoop

@exit:
    mov ah, 4ch
    int 21h
fallLoop endp

printM macro x, y, char
    push di
    push ax
    push bx
    push cx
    push dx

    ; calculate di
    ; BL = cur_x, BH = cur_y
    mov bl, x
    mov bh, y
    ; cur_y * 160
    mov al, bh                      ; Y -> BH
    mov ah, CONSOLE_WIDTH           
    mul ah
    ; += cur_x * PIXEL_SCALE + 1
    mov bh, 0                       ; erase Y in BH
    shl bx, 1                       ; consists of two pieces []

    add bx, HOR_BORDER_WIDTH        ; add border offset

    shl bx, 1                       ; * 2 ; PIXEL_WIDTH of an element
    add ax, bx                      ; calc all the pos

    mov di, ax                      ; pos on screen into DI

    mov ah, 0fh
    mov al, char
    stosw                        ; AX -> ES:[DI] ; DI += 2
    ;sub di, 2                    ; DI -= 2

    pop dx
    pop cx
    pop bx
    pop ax
    pop di
endm

checkCollision proc
    ; BL = cur_x, BH = cur_y
    mov bx, word ptr [cur_x]
    ; cur_y * PLAYFIELD_WIDTH
    mov al, bh                  ; Y -> BH
    mov ah, FIELD_WIDTH         ; FIELD_WIDTH
    mul ah
    ; += cur_x
    mov ch, 0
    mov cl, bl                  ; X -> CL
    add ax, cx                  ; X -> AX
    ; left border width
    add ax, HOR_BORDER_WIDTH

    add ax, offset field        ; offset + ax   ; address of pixel

    mov di, ax

    ; 4x4
    mov dx, FIGURE_HEIGHT
    @@rowC:
        mov cx, FIGURE_WIDTH
        @@colC:

        mov ah, 0h
        int 16h

        mov byte ptr [X], bl
        mov byte ptr [Y], bh

        lodsb                       ; DS:[SI] -> AL, SI += 1
        or al, al                   ; check if not zero

        jz  @@skipC
        cmp bl, PLAYFIELD_WIDTH     ; x > field_width
        jae @@colW
        cmp bh, PLAYFIELD_HEIGHT    ; y > playfield_height
        jae @@collides

        mov al, byte ptr [di]       ; read from memory?
        or al, al
        jnz @@colM
    @@skipC:
        printM X, Y, 5ah
        inc bl                      ; x++
        inc di                      ; memory_offset++
        loop @@colC

        add di, FIELD_WIDTH-FIGURE_WIDTH
        sub bl, FIGURE_WIDTH        ; x -= width of figure
        inc bh                      ; y++
        dec dx
        jnz @@rowC
        clc
        ret
    @@collides:
        printM X, Y, 043h
        stc
        ret

    @@colW:
        printM X, Y, 057h
        stc
        ret 

    @@colM:
        printM X, Y, 04dh
        stc
        ret

    @sign:
        push di

        mov ah, 0fh
        mov al, 23h
        stosw                        ; AX -> ES:[DI] ; DI += 2
        sub di, 2                    ; DI -= 2

        pop di
        ret
checkCollision endp

main proc
	mov ax,@data
	mov ds,ax

    call fallLoop

    ; exit
    mov ah, 4ch
    int 21h

	.exit
main endp
end main