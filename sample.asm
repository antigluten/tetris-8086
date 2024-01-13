.model small
.data
    ; Define an array to store red square data (ASCII code and color attribute)
    squareArray db 'R', 4 dup(0Ch) ; 'R' is the red character, 0Ch is the color attribute

.code
main:
    ; Initialize DS register with the segment address of the data segment
    mov ax, @data
    mov ds, ax

    ; Call function to draw red square on the array
    call DrawRedSquare

    ; Call function to copy array data to video memory
    call CopyToVideoMemory

    mov ah, 00
    int 16h

    ; Terminate program
    mov ah, 4Ch       ; DOS function for program termination
    int 21h           ; Call DOS interrupt

DrawRedSquare PROC
    ; Drawing a 2x2 red square in the array
    ; Each character takes 2 bytes (ASCII code and color attribute)
    
    ; Top-left corner of the square
    mov byte ptr [squareArray], 020h
    mov byte ptr [squareArray + 1], 04fh

    ; Top-right corner of the square
    mov byte ptr [squareArray + 2], 020h
    mov byte ptr [squareArray + 3], 04fh
    ; Bottom-left corner of the square
    mov byte ptr [squareArray + 4], 020h
    mov byte ptr [squareArray + 5], 04fh

    ; Bottom-right corner of the square
    mov byte ptr [squareArray + 6], 020h
    mov byte ptr [squareArray + 7], 04fh

    ret
DrawRedSquare ENDP

CopyToVideoMemory PROC
    ; Copy the content of the array to video memory (0xB8000)
    ; lea si, squareArray ; Source index (address of the array)
    mov ax, 0b800h
    mov es, ax

    ; mov ah, 0fh
    ; mov al, 5ah
    lea si, squareArray
    mov di, 0 ; Destination index (start of video memory)

    ; Copy 8 bytes (4 characters) from the array to video memory
    mov dx, 2
    @row:
    mov cx, 8
    ; @loop:

    rep movsb

    ; loopnz @loop
    add di, 160 - 8
    sub si, 8
    dec dx
    jnz @row


    ; rep stosw

    ret
CopyToVideoMemory ENDP

end main
