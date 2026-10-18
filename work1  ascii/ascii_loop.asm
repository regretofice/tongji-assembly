assume cs:code,ss:stack
stack segment 
    dw 16 dup(0)
stack ends

code segment
begin:
    mov  cx,2
    mov  bl,'a' ; 必须得用bl，用al的话每次都会被清空

; 构建一个双层循环
s2:
    push cx

    mov  cx,13
s1:
    mov  dl,bl
    inc  bl
    mov  ah,2
    int  21h
    mov  dl,' '
    mov  ah,2
    int  21h
    loop s1

    ; 内层循环结束后，打印回车和换行
    mov  dl,0dh
    mov  ah,2
    int  21h
    mov  dl,0ah
    mov  ah,2
    int  21h

    pop  cx
    loop s2


    mov  ax,4c00h
    int  21h

code ends
    end begin