assume cs:code,ds:data,ss:stack

data segment 
    welcome db 'please enter a decimal number between 0 and 65535',0dh,0ah,'$'
    dec_msg db 'This number converted to hexadecimal is',0dh,0ah,'$'
data ends 

stack segment
    dw 32 dup(0)
stack ends


code segment 
begin:
    mov  ax,data
    mov  ds,ax
    mov  ax,stack
    mov  ss,ax
    mov  sp, 64;需要初始化栈顶指针

    lea  dx,welcome
    mov  ah,9
    int  21h
    ;输出提示词

    ;输入待转换数字，输入内容存储到栈中
    call get_input_dec

    call turnHEX


    mov  ax,4c00h
    int  21h

get_input_dec:
    ;读入一个十进制的数字，存储至栈中，最大为(65535，受限于turnHEX函数)
    pop  bx             ;先保存返回地址

input_loop:
    ;这个循环最多重复6次，第6次必须要离开，不然会导致溢出
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
    mov  ah,0   
    push ax             ;将当前得到的数字存到栈中
    jmp  input_loop     ;继续读取下一个字符

input_end:
    ;输入结束，返回主函数，并准备运行turnHEX
    push bx             ;恢复返回地址
    ret  
turnHEX:

    lea  dx,dec_msg
    mov  ah,9
    int  21h
    ;输出提示词

    ;从栈中取出被除数(最多65535)
    mov  bp,62   ;从栈顶往下取出
    ;(这个方法不是很好)(由于栈顶存储着当前函数的返回ip，所以不是64)
    ;根本原因是使用栈对被除数进行存储，太反人类了,并且当前函数无法处理空输入的情况
    mov  ax,0

store_num:
    mov  bx,ss:[bp]
    mov  dx,10  ;mul会改变dx的值
    mul  dx
    add  ax,bx

    sub  bp,2   ;当前bp是栈顶，会往低地址移动
    cmp  bp,sp
    jnz  store_num

    mov  dx,0
    mov  cx ,16 ;放好除数

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
    cmp  al, 10
    jb   is_digit
    add  al, 55          ; 10 -> 'A'
    jmp  out_char
is_digit:
    add  al, '0'         ; 0 -> '0'
out_char:
    mov  dl, al
    mov  ah, 2  
    int  21h 

    cmp  sp, bp
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
    end begin 