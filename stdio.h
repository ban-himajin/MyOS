#ifndef STDIO_H
#define STDIO_H

#define VGA_MEMORY 0xB8000
static int cursor = 0;

//vk_付き関数はVGAを想定したカーネル専用ライブラリ命令
//sk_付き関数はシリアル用を想定したカーネル専用ライブラリ命令

void clean_screen(){
    volatile char* vga = (char*)0xB8000;
    for(int i = 0; i < 80*25; ++i){
        vga[i * 2] = ' ';
        vga[i * 2 + 1] = 0x07;
    }
    cursor = 0;
}

void vk_putchar(char c){
    volatile char* vga = (volatile char*)VGA_MEMORY;
    if(c == '\n'){
        cursor = ((cursor / 80) + 1) * 80;
    }
    else{
        vga[cursor * 2] = c;
        vga[cursor * 2 + 1] = 0x07;//色指定 0x07は、白文字・黒背景
        cursor++;
        if(cursor >= 80 * 25) cursor = 0;
    }
}

void vk_puts(const char* str){
    while(*str) vk_putchar(*str++);
}

// void vk_printf(const char* fmt, ...){
// }


#endif