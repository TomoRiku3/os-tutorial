[bits 32] ; using 32-bit protected mode

; this is how constants are defined
VIDEO_MEMORY equ 0xb8000
WHITE_OB_BLACK equ 0x0f ; the color byte for each character

; given a 0-terminated string starting at memory address ebx 
; function print_string_pm prints the string starting at VIDEO_MEMORY
; CAUTION: if the VIDEO_MEMORY range was used previosuly, the function is going to overwrite it

print_string_pm:
    pusha ; in a 32 bit mode, pusha pushes these 8 registers in this order EAX, ECX, EDX, EBX, ESP, EBP, ESI, EDI
    mov edx, VIDEO_MEMORY ; edx points to the memory address where the display hardware reads the bits from

print_string_pm_loop:
    ; SIDE NOTE: register AX is 16 bits AH is the higher 8 bits and AL is lower 8 bits
    ; in assembly, characters are typically 8 bits
    mov al, [ebx] ; [ebx] is the address of our character 
    mov ah, WHITE_OB_BLACK

    cmp al, 0 ; check if end of string
    je print_string_pm_done

    mov [edx], ax ; store character + attribute in video memory
    add ebx, 1 ; next char
    add edx, 2 ; next video memory position

    jmp print_string_pm_loop

print_string_pm_done:
    popa
    ret
