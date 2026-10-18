assume cs:code
code segment
begin:
    mov bl,'a'
s2:

    mov cx,13
s1:
    mov  dl,bl
    inc  bl
    mov  ah,2
    int  21h
    mov  dl,' '
    mov  ah,2
    int  21h

    ; 本质是自己写一个循环
    dec cx
    cmp cx,0
    jnz  s1  ; 假如z标为0跳转

    ; 内层循环结束后，打印回车和换行
    mov  dl,0dh
    mov  ah,2
    int  21h
    mov  dl,0ah
    mov  ah,2
    int  21h

    ;如果没有结束输出，则进行一次大循环
    cmp bl,'{' ;ascii码中z的下一个是{
    jnz s2


    mov  ax,4c00h
    int  21h

code ends

    end begin