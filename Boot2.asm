[BITS 16]
[org 0x8000]

section .data
    timer_ticks dd 0

section .bss
    kyeboard_buffer resb 1
    kb_index resb 1

section .text
start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x9000

    mov si, Secand_msg

.Secand_print:;文字出力
    lodsb
    cmp al, 0
    je load_kernel
    mov ah, 0x0e
    int 0x10
    jmp .Secand_print

Secand_msg:
    db "Secando_start",0

enable_a20_fast:
    in   al, 0x92      ; read port 0x92
    or   al, 0x02      ; set bit1 -> enable A20
    out  0x92, al      ; write back
    ret

load_kernel: ;読み込み先のカーネルをロード
    
    call enable_a20_fast
    
    mov ax, 0x1000
    ;mov ax, 0x10
    mov es, ax
    ;xor bx, bx
    mov bx, 0x0000
    mov bx, 0
    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov cl, 7
    mov dh, 0
    mov dl ,0x80
    int 0x13
    jc disk_error

    mov ah, 0x02    ; カーソル位置設定
    mov bh, 0x00    ; ページ番号（通常0）
    mov dh, 0x00    ; 行（Y座標）
    mov dl, 0x00    ; 列（X座標）
    int 0x10        ; BIOSビデオサービス呼び出し

    jmp setup_32bit_mode

disk_error:
    mov si, err_msg

.err_loop:
    lodsb
    cmp al, 0
    je $
    mov ah, 0x0e
    int 0x10
    jmp .err_loop

err_msg:
    db "|Kernel no found|",0


setup_32bit_mode:
    lgdt [gdt_descriptor]

    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp 0x08:protected_mod_start

gdt_start:;GDTの範囲指定
    dq 0x0000000000000000

    dq 0x00cf9a000000ffff

    dq 0x00cf92000000ffff
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start


[BITS 32]
protected_mod_start:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x9fc00
    mov ebp, esp

    ; カーネルを0x10000→0x00100000へコピー
    mov esi, 0x10000      ; コピー元
    ;mov esi, 0x1000      ; コピー元
    mov edi, 0x00100000   ; コピー先
    mov ecx, 1 * 512; セクタ数×512バイト分
    rep movsb
    
;copy_kernel:
;    mov al, [esi]
;    mov [edi], al
;    inc esi
;    inc edi
;    loop copy_kernel

    VGA_ADDR equ 0xB8000 + (10 * 160)
    mov edi,VGA_ADDR      ; VGAメモリ

    jmp msg_out

msg_out:
    
    mov esi, bit32_msg
    mov ah, 0x0f

.msg_out_loop:
    lodsb
    cmp al, 0
    je .msg_out_done
    mov [edi], ax
    add edi, 2
    jmp .msg_out_loop

.msg_out_done:
    jmp init_pic_32

bit32_msg:
    db "32bit_start",0

init_pic_32: ;picの初期化

    ;ICW1
    mov al,0x11
    out 0x20, al
    out 0xa0, al

    ;ICW2
    mov al, 0x20
    out 0x21, al
    mov al, 0x28
    out 0xa1, al

    ;ICW3
    mov al, 0x04
    out 0x21, al
    mov al, 0x02
    out 0xa1, al

    ;ICW4
    mov al, 0x01
    out 0x21, al
    out 0xa1, al


    mov al, 0xfc
    out 0x21, al

    mov al, 0xff
    out 0xa1, al

    call setup_idt
    lidt [idt_descriptor]


    sti
    jmp kernel

idt_start: ;idtの追加
    times 256 dq 0
idt_end:


setup_idt:
    ;isrを登録

    mov eax, isr0 ;isr0のオフセット
    mov word [idt_start + 0*8], ax
    shr eax, 16
    mov word [idt_start + 0*8 + 6], ax
    mov word [idt_start + 0*8 + 2], 0x08
    mov byte [idt_start + 0*8 + 5], 0x8E;セグメントとフラグ設定らしい...

    mov eax, isr_timer ;タイマーオフセット
    mov word [idt_start + 0x20*8], ax
    shr eax, 16
    mov word [idt_start + 0x20*8 + 6], ax
    mov word [idt_start + 0x20*8 + 2], 0x08
    mov byte [idt_start + 0x20*8 + 5], 0x8e

    mov eax, isr_keyboard ;キーボードオフセット
    mov word [idt_start + 0x21*8], ax
    shr eax, 16
    mov word [idt_start + 0x21*8 + 6], ax
    mov word [idt_start + 0x21*8 + 2], 0x08
    mov byte [idt_start + 0x21*8 + 5], 0x8e

    ret

idt_descriptor:
    dw idt_end - idt_start - 1
    dd idt_start


    ;ret

isr0: ;例外処理
    pusha;現在の32bitレジスタを保存
    ;この後に割り込み処理を書く



    popa;レジスタを復元
    iret;割り込み前の実行に戻る

isr_timer: ;タイマー割り込み(作成中)
    pusha

    inc dword[timer_ticks]

    mov al, 0x20
    out 0x20, al

    popa
    iret

isr_keyboard: ;キーボードを読み取る
    pusha
    in al, 0x60

    mov bl, [kb_index]
    mov [kyeboard_buffer + ebx], al
    inc bl
    mov [kb_index],bl

    mov al, 0x20
    out 0x20, al

    popa
    iret

kernel: ;カーネル実装予定の場所
    mov eax, 0x00100000
    
    ;hlt
    ;jmp $
    ;call eax
    jmp eax
    ;jmp 0x00100000
    ;jmp 0x00100000
    ;jmp $
    cli
    hlt
    ;times 2556-($-$$) db 0
    ;times 512*5-($-$$) db 0
    times 512 * 6 - 4 -($-$$) db 0
