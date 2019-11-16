macro setCursor x*, y*{
    push dx
    mov dh,y
    mov dl,x
    call set_cursor
    pop dx
}

macro write_char char*{
    mov dl,char
    call print_char 
}

macro if lhs*, rhs*,function*, label* {
    cmp lhs,rhs
    function label
}

macro call_if lhs*, rhs*,jump*,function*{
    cmp lhs,rhs
    jump @f
    jmp ex#function
@@:
    call function
ex#function = $
}

use16
org 100h
    pusha
    mov ah, 0x00
    mov al, 0x03  ; text mode 80x25 16 colours
    int 0x10
    popa
main:

    call read_key
    call search_array

    call_if bx,0,je, place_array_element
    call_if bx,0,jne,increment_array_element

    setCursor 0,0
    call print_array
    setCursor 0,23
    jmp main

    call wait_exit
.main_exit:
    mov ax,4C00h
    int      21h

.vars:
press db 13,10, 'Press any key ... $'
text  db " - $"
pointer dw 0
array db 128 dup(0,0)
array_end = $


print_array:
    mov bx, array   
    
@@:
    if byte[bx],0,je, @f
    if bx, array_end, je, @f
    ;if byte[bx], 0, jne, .exit

    write_char byte[bx]

    mov ah,0x9
    mov dx, text
    int 0x21

    mov al,byte[bx + 1]
    mov ah, 0
    ;call print_number
    call printw

    write_char 0x9 ; tab
    inc bx
    inc bx
    jmp @b
@@:
    
    mov bx,0

    RET

; Write char to stdout
; <- DL - char to print
print_char:
    mov ah, 0x02
    int 0x21
    RET

; Read char from stdin
; -> AL - char
read_key:         
    mov ah,1
    int 0x21
    RET

; Move cursor to position
; <- DH - row
; <- DL - column
set_cursor:
    push ax         
    push dx
    mov  ah, 2      ; set cursor pos
    mov  bh, 0      ; video page            
    int  10h                
    pop dx
    pop ax    
    RET

; <- AL  - char
; <- *BX - array_pointer   
increment_array_element:
    inc byte[bx+1]
    RET


; <- AL  - char
; <- *CX - first free pointer    
place_array_element:
    push bx
    mov bx,cx
    mov [bx], al
    inc byte[bx+1]
    pop bx
    RET


; <- AL  - char
; -> *BX - first found pointer
; if BX == 0 =>
; -> *CX - first free
search_array:       
    mov bx, array   
.start:
    if byte[bx],0,je, .save_free
    if byte[bx], al, je, .exit
    if bx, array_end, je, .pre_exit
    
    inc bx
    inc bx
    jmp .start
.save_free:
    mov cx,bx
.pre_exit:
    mov bx,0
.exit:
    RET


wait_exit:
    mov ah, 0x9
    mov dx, press
    int 0x21
    mov ah, 0x8
    int 0x21
    RET

; Print HEX number with leading zero's
; <- AX - number to prin
printw:
    push ax
    shr ax, 8
    call .printb
    pop ax
    push ax
    and  ax, 0xff
    call .printb
    pop ax
    RET

    .printb:
        push ax
        shr al, 4
        call .printasc
        pop ax
        and al, 0xf
        call .printasc
    ret

    .printasc:
        add al, 0x30
        cmp al, 0x39
        jle .printasc_e
        add al, 0x7
        .printasc_e:
        mov dl, al
        mov ah, 0x2
        int 0x21
    ret