assume cs:code,ss:stack,ds:data
data segment
    fmt db '9*9=81  ','$'
    welcome db 'The 9mul9 table:',0dh,0ah,'$'
data ends

stack segment
    dw 32 dup(0)
stack ends


code segment
begin:
    mov  ax,stack
    mov  ss,ax
    mov  sp,64
    mov  ax,data
    mov  ds,ax

    lea  dx,welcome
    mov  ah,9
    int  21h

    mov  cx ,9
loop1:
    push cx         ;存放乘数1

    mov  bx,1
loop2:
    push bx         ;存放乘数2
    mov  al,cl
    mul  bl
    push ax         ;存放乘积
    call fmt_print

    pop  ax
    pop  bx
    inc  bx
    cmp  cx,bx       ;没动过cx
    jae  loop2       ;要用jae,若是使用jnz，会在cx=1的时候死循环

    ;内层循环结束后输出换行
    mov  dl,0dh
    mov  ah,2
    int  21h
    mov  dl,0ah
    mov  ah,2
    int  21h

    pop  cx
    loop loop1

    mov  ax,4c00h
    int  21h

fmt_print:
    push bp         ; 保存旧的 bp
    mov  bp, sp     ; 此时 bp 指向栈顶
    push ax
    push bx
    push dx

    ; 当前栈里的结构:
    ; SS:[bp - 6] = dx
    ; SS:[bp - 4] = bx
    ; SS:[bp - 2] = ax
    ; SS:[bp + 0] = 旧的bp
    ; SS:[bp + 2] = 返回地址(IP)
    ; SS:[bp + 4] = 乘积
    ; SS:[bp + 6] = 乘数2
    ; SS:[bp + 8] = 乘数1

    mov  ax,ss:[bp+8]                ;不能直接从内存拷贝到内存，一定要使用寄存器中转 
    add  al, '0'                     ;转换为数字字符
    mov  ds:[fmt+0], al              ;再把 al 写入 fmt
    mov  ax,ss:[bp+6]
    add  al, '0'        
    mov  ds:[fmt+2], al             

    mov  ax, ss:[bp+4]    ; 直接将完整乘积(字)读入ax，避免尺寸不匹配
    cmp  ax, 10
    jae  greater_10       ;如果乘积有2位，单独处理

    ;乘积只有1位
    mov  ax,ss:[bp+4]
    add  al, '0'      ;先从 table 取字符到 al
    mov  ds:[fmt+4],al
    mov  byte ptr ds:[fmt+5],' '
    jmp  fmt_ok

greater_10:
    mov  ax,ss:[bp+4]
    mov  bl,10
    div  bl
    add  al,'0'
    mov  ds:[fmt+4],al
    add  ah,'0'
    mov  ds:[fmt+5],ah

fmt_ok:
    lea  dx,fmt
    mov  ah,9
    int  21h

    ;还原现场
    pop  dx
    pop  bx 
    pop  ax
    pop  bp
    ret  

code ends 
    end begin