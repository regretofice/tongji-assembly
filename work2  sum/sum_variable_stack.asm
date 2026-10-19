assume ds:data,cs:code
data segment 
    welcome db 'please enter a decimal number between 0 and 100',0dh,0ah,'$'
    dec_msg db 'The result of adding numbers from 1 to that is',0dh,0ah,'$'
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

    call get_input_dec
    mov  cx,bx
    mov  bx,0
    push bx     ;向栈中存入累加值的初始值0
sum:
    pop  bx
    add  bx,cx
    push bx
    loop sum    ;直接使用循环进行累加，结果存储到bx寄存器中

    call turnDEC

    mov  ax,4c00h
    int  21h

;===============================
;读入一个十进制的数字，存储至寄存器bx/栈中
;================================
get_input_dec:

    mov  si,0   ;初始化si大小，防止读入太长的数字
    mov  bx,0

input_loop:
    cmp  si, 4         ;防止输入太长(应该设置为3，但是如果这样会有换行问题)
    jae  input_end

    mov  ah,1 
    int  21h
    cmp  al,0dh         ;如果接收到换行则结束输入
    jz   input_end
    cmp  al,' '         ;如果按了空格
    jz   input_end

    ;此时al中存储的是ascii码,根据ascii码进行操作
    ;处理所有非法字符
    cmp  al,'0'
    jb   input_end  ;比0小，非法字符
    cmp  al,'9'
    jbe  al_num ;数字比所有字母的ascii都要小

    jmp  input_end ;非数字的都是非法字符

al_num:
    ;当前是数字
    sub  al,'0' 
    mov  cl,al
    mov  ch,0       ;新的个位传给cx

    mov  ax,bx
    mov  dx,10      ;有点绕，但是逻辑没问题
    mul  dx
    mov  bx,ax
    add  bx,cx       ;将当前得到的数字存到寄存器bx中
    inc  si 
    jmp  input_loop     ;继续读取下一个字符

input_end:
    ;输入结束，返回主函数，并准备运行turnDEC
    ret  

turnDEC:
    lea  dx,dec_msg
    mov  ah,9
    int  21h
    ;输出提示词

    push bp         ; 保存旧的 bp
    mov  bp, sp     ; 此时 bp 指向栈顶

    ; 当前栈里的结构:
    ; SS:[bp + 0] = 旧的bp
    ; SS:[bp + 2] = 返回地址(IP)
    ; SS:[bp + 4] = 累加结果

    mov  ax,ss:[bp+4] ;取出被除数(栈中)
    mov  dx,0
    mov  cx ,10 ;放好除数
    mov  si, sp     
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

    cmp  si,sp
    jnz  print_loop

    ; 输出换行
    mov  dl,0dh
    mov  ah,2
    int  21h
    mov  dl,0ah
    mov  ah,2
    int  21h

    pop  bp

    ret  ;turnDEC函数结束
code ends 

    end start