[BITS 16]
[org 0x7c00]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7bff 
    sti

    mov si, msg

.print_loop:;文字出力
    lodsb
    cmp al, 0
    je .Load_secando
    mov ah, 0x0e
    int 0x10
    jmp .print_loop

.Load_secando:
    mov bx, 0x8000
    xor ax, ax
    mov ds, ax
    mov es, ax

    mov ah, 0x02
    mov al, 5
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl ,0x80
    int 0x13
    jc disk_error

    jmp 0x0000:0x8000

disk_error:
    mov si,error

.error_print:
    xor ax, ax
    mov ds, ax
    mov es, ax

    lodsb
    cmp al, 0
    je .stop
    mov ah, 0x0e
    int 0x10
    jmp .error_print

.stop:
    jmp $

msg:;出力文字内容
     db 10,"BanHimaBootLoader Ver:a 0.0.1",32,32,0

error:
    db "|SecandoBoot no found|",0

times 510-($-$$) db 0
dw 0xaa55