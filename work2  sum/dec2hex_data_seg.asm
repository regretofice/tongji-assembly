assume cs:code,ds:data,ss:stack

data segment 
    welcome db 'please enter a decimal number between 0 and 65535',0dh,0ah,'$'
    dec_msg db 'This number converted to hexadecimal is',0dh,0ah,'$'
    input_buf db 32 dup(0)  ;理论上能存储很大，但是由于高精度除法实现麻烦，所以暂时不实现
    output_buf db 32 dup(0)
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

    ;输入待转换数字，输入内容存储到数据段中
    call get_input_dec    

    call turnHEX

    mov  ax,4c00h
    int  21h


;===============================
;读入一个十进制的数字，存储至input_buf中，末尾位置为si
;================================
get_input_dec:

    mov  si,0   ;初始化si位置

input_loop:
    cmp  si, 31         ;防止输入太长覆盖掉 output_buf
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
    mov  ds:[input_buf+si],al          ;将当前得到的数字存到input_buf中
    inc  si 
    jmp  input_loop     ;继续读取下一个字符

input_end:
    ;输入结束，返回主函数，并准备运行turnHEX
    ret  

;==============================
;将input_buf中的十进制数字转换为16进制形式进行输出(65535是当前的处理上限)
;===================================
turnHEX:

    lea  dx,dec_msg
    mov  ah,9
    int  21h
    ;输出提示词

    cmp  si, 0          ;如果输入为空，直接输出 0
    je   print_zero

    mov  ax,0
    mov  di,0
    mov  bh,0
store_num:
    mov  bl,ds:[input_buf+di]
    mov  dx,10  ;mul会改变dx的值
    mul  dx
    add  ax,bx

    inc  di
    cmp  di,si
    jnz  store_num

    mov  dx,0
    mov  cx ,16 ;放好除数
    mov  si,0

;循环除法，将结果存至数据段
div_loop:
    div  cx      ;需要设置除数为16位否则当前除法无法处理被除数超过255的情况
    mov  ds:[output_buf+si],dl;dx保留的是余数
    inc  si
    mov  dx, 0   ;清零dx(相当重要),防止上一次运算出的结果被当作新被除数
    cmp  ax,0
    jnz  div_loop

    mov  di,si
    dec  di     ;需要倒转着进行输出，从[si-1]  -> [0]  
print_loop:
    mov  al,ds:[output_buf+di]
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

    dec  di
    cmp  di, 0
    jge  print_loop     ;不能用无符号跳转，否则会死循环

    jmp  print_end      ;如果正常结束则输出换行

print_zero:
    ;输入为空的特殊处理
    mov  dl, '0'
    mov  ah, 2
    int  21h

print_end:
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