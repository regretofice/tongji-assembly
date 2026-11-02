assume ds:data,cs:code,ss:stack

data segment
    table  db 7,2,3,4,5,6,7,8,9             ;9*9表数据
    db 2,4,7,8,10,12,14,16,18
    db 3,6,9,12,15,18,21,24,27
    db 4,8,12,16,7,24,28,32,36
    db 5,10,15,20,25,30,35,40,45
    db 6,12,18,24,30,7,42,48,54
    db 7,14,21,28,35,42,49,56,63
    db 8,16,24,32,40,48,56,7,72
    db 9,18,27,36,45,54,63,72,81

    xy db 'x y',0dh,0ah,'$'
    fmt db '? ?     error',0dh,0ah,'$'
    fin db 'accomplish!',0dh,0ah,'$'
data ends

stack segment 
    dw 32 dup(0)
stack ends 

code segment 
start:
    mov  ax,stack
    mov  ss,ax
    mov  sp,64
    mov  ax,data
    mov  ds,ax

    lea  dx,xy
    mov  ah,9
    int  21h

    mov  ax,0
    push ax

;存放乘数1
loop1:
    pop  bx
    inc  bx
    cmp  bx,9
    ja   finish
    push bx

    mov  ax,0
;存放乘数2
loop2:
    inc  ax
    cmp  ax,9
    ja   loop1
    push ax

    call correction

    pop  ax
    jmp  loop2          ;循环到10之后自动跳转出loop1;

finish:

    lea  dx,fin
    mov  ah,9
    int  21h
    mov  ax,4c00h
    int  21h

correction:
    push bp         ; 保存旧的 bp
    mov  bp, sp     ; 此时 bp 指向栈顶
    push ax
    push bx
    push cx
    push dx

    ; 当前栈里的结构:
    ; SS:[bp - 8] = dx
    ; SS:[bp - 6] = cx
    ; SS:[bp - 4] = bx
    ; SS:[bp - 2] = ax
    ; SS:[bp + 0] = 旧的bp
    ; SS:[bp + 2] = 返回地址(IP)
    ; SS:[bp + 4] = 乘数2
    ; SS:[bp + 6] = 乘数1
    ;cx,dx放乘数，bx放位置
    mov  cx,ss:[bp+6]
    mov  dx,ss:[bp+4]

    ;loc = (i-1)*9+(j-1) -> 9*i + j - 10 
    mov  ax,cx
    mov  bx,9
    mul  bl

    mov  bx,ax
    mov  si,dx

    mov  bx,ds:[bx+si-10]  ;bx=9*i,si=j,10是立即数
    ;取出来的是dw，所以会一直判定有误,需要清空bh
    mov  bh,0

    mov  ax,dx 
    mul  cl         ;调用的是8位的乘法，结果存储在ax

    cmp  ax,bx
    jz   no_error

    ;如果有问题
    mov  al,cl
    mov  bl,dl
    add  al,'0'
    add  bl,'0'

    mov  ds:[fmt],al
    mov  ds:[fmt+2],bl

    lea  dx,fmt
    mov  ah,9
    int  21h
no_error:
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    pop  bp
    ret  

code ends 

    end start