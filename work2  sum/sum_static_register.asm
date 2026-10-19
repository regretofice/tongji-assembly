assume ds:data,cs:code
data segment 
    welcome db 'The result of adding numbers from 1 to 100 is',0dh,0ah,'$'
data ends 

stack segment
    dw 16 dup(0)
stack ends

code segment 
start:
    mov  ax,data
    mov  ds,ax
    mov  ax,stack
    mov  ss,ax
    mov  sp,32;需要初始化栈顶指针


    lea  dx,welcome
    mov  ah,9
    int  21h
    ;输出提示词

    mov  cx,100
    mov  bx,0
sum:
    add  bx,cx
    loop sum    ;直接使用循环进行累加，结果存储到bx寄存器中

    call turnDEC

    mov  ax,4c00h
    int  21h

turnDEC:

    mov  ax,bx  ;放好被除数(寄存器中)
    mov  dx,0
    mov  cx ,10 ;放好除数

    mov  bp,sp ;保存当前的栈顶位置
;循环除法，将结果存至栈中
div_loop:
    div  cx      ;需要设置除数为16位否则当前除法无法处理被除数超过255的情况
    push dx      ;dx保留的是余数
    mov  dx, 0   ;清零dx(相当重要),防止上一次运算出的结果被当作新被除数
    cmp  ax,0
    jnz  div_loop

print_loop:
    pop  ax
    mov  dl,al
    add  dl,'0'
    mov  ah,2  ;输出当前的数字
    int  21h 

    cmp  bp,sp
    jnz  print_loop

    ; 输出换行
    mov  dl,0dh
    mov  ah,2
    int  21h
    mov  dl,0ah
    mov  ah,2
    int  21h

    ret  ;turnDEC函数结束
code ends 

    end start