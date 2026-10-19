assume cs:code,ds:data,ss:stack

data segment 
    welcome db 'please enter a hex number between 0 and ff',0dh,0ah,'$'
    dec_msg db 'This number converted to decimal is',0dh,0ah,'$'
data ends 

stack segment
    dw 16 dup(0)
stack ends


code segment 
begin:
    mov  ax,data
    mov  ds,ax
    mov  ax,stack
    mov  ss,ax
    mov  sp, 32;需要初始化栈顶指针

    lea  dx,welcome
    mov  ah,9
    int  21h
    ;输出提示词

    ;输入待转换数字，输入内容存储到bx
    call get_input_hex
    ; mov  bx,5050

    call turnDEC


    mov  ax,4c00h
    int  21h

get_input_hex:
    ;读入一个十六进制的数字，存储至bx中，最大为ff
    mov  bx,0

input_loop:
    ;这个循环最多重复三次，第三次必须要离开，不然会导致溢出
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

    mov  ah,11011111b
    and  al, ah   ;全部转换为大写

    cmp  al,'A'
    jb   input_end  ;比A小，非法字符
    cmp  al,'F'
    ja   input_end  ;比F大 ，非法字符


    ;al_alpha:
    ;当前是字母
    sub  al,55          ;A是65，少减去10，直接转换为数字
    jmp  shift

al_num:
    ;当前是数字
    sub  al,'0'         ;顺延到shift

shift:
    ;BX左移4位，为下一个十六进制位腾出空间
    push cx         ;保存外层循环的 cx
    mov  cl,4
    shl  bx,cl      ;移位的次数放在cl寄存器中(8086的限制)
    pop  cx         ;恢复 cx          
    mov  ah,0
    add  bx,ax          ;将转换后的数值加到 BX
    jmp  input_loop     ;继续读取下一个字符

input_end:
    ;输入结束，返回主函数，并准备运行turnDEC
    ret  
turnDEC:

    lea  dx,dec_msg
    mov  ah,9
    int  21h
    ;输出提示词

    mov  ax,bx  ;放好被除数
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
    end begin 