.model small
.stack 100h
.8086

.data
message    db  "Hello, world!", 13, 10, '$'

.code
main proc
	mov ax,@data
	mov ds,ax

    mov ah, 09h
    ;lea dx, message
    mov dx, offset message ; OR - lea dx, message
    int 21h
    ; exit
    mov ah, 4ch
    int 21h

	.exit
main endp
end main
