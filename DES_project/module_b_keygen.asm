INCLUDE Irvine32.inc

.data
    PC1_C BYTE 57, 49, 41, 33, 25, 17,  9,  1, 58, 50, 42, 34, 26, 18
          BYTE 10,  2, 59, 51, 43, 35, 27, 19, 11,  3, 60, 52, 44, 36
    PC1_D BYTE 63, 55, 47, 39, 31, 23, 15,  7, 62, 54, 46, 38, 30, 22
          BYTE 14,  6, 61, 53, 45, 37, 29, 21, 13,  5, 28, 20, 12,  4

    SHIFTS BYTE 1, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1

    PC2   BYTE 14, 17, 11, 24,  1,  5,  3, 28, 15,  6, 21, 10
          BYTE 23, 19, 12,  4, 26,  8, 16,  7, 27, 20, 13,  2
          BYTE 41, 52, 31, 37, 47, 55, 30, 40, 51, 45, 33, 48
          BYTE 44, 49, 39, 56, 34, 53, 46, 42, 50, 36, 29, 32

.code
GenerateKeySchedule PROC
    push ebp
    mov ebp, esp
    sub esp, 20

    pushad
    
    mov esi, [ebp+8]     
    mov eax, [esi+4]     
    mov edx, [esi]       
    bswap eax            
    bswap edx
    mov [ebp-12], eax    
    mov [ebp-16], edx    
    mov dword ptr [ebp-4], 0  
    mov dword ptr [ebp-8], 0  


;PC-1   
    mov esi, OFFSET PC1_C
    mov ecx, 28          
L_PC1_C:
    movzx eax, byte ptr [esi]   
    cmp eax, 32
    ja C_LowKey
C_HighKey:
    mov edx, 32
    sub edx, eax         
    mov eax, [ebp-12]
    bt eax, edx          
    jmp C_SetBit
C_LowKey:
    mov edx, 64
    sub edx, eax         
    mov eax, [ebp-16]
    bt eax, edx          
C_SetBit:
    jnc C_Next           
    mov edx, ecx
    dec edx              
    mov eax, [ebp-4]
    bts eax, edx         
    mov [ebp-4], eax
C_Next:
    inc esi
    dec ecx
    jnz L_PC1_C

   
    mov esi, OFFSET PC1_D
    mov ecx, 28
L_PC1_D:
    movzx eax, byte ptr [esi]
    cmp eax, 32
    ja D_LowKey
D_HighKey:
    mov edx, 32
    sub edx, eax
    mov eax, [ebp-12]
    bt eax, edx
    jmp D_SetBit
D_LowKey:
    mov edx, 64
    sub edx, eax
    mov eax, [ebp-16]
    bt eax, edx
D_SetBit:
    jnc D_Next
    mov edx, ecx
    dec edx
    mov eax, [ebp-8]
    bts eax, edx
    mov [ebp-8], eax
D_Next:
    inc esi
    dec ecx
    jnz L_PC1_D



;PC-2    
    mov dword ptr [ebp-20], 0   

L_RoundLoop:
    mov edi, [ebp-20]
    movzx ecx, byte ptr [SHIFTS + edi]  

   
    mov eax, [ebp-4]
L_ShiftC:
    shl eax, 1           
    bt eax, 28           
    jnc C_NoCarry
    bts eax, 0           
    btr eax, 28          
C_NoCarry:
    dec ecx
    jnz L_ShiftC
    mov [ebp-4], eax     

    
    movzx ecx, byte ptr [SHIFTS + edi]  
    mov eax, [ebp-8]
L_ShiftD:
    shl eax, 1
    bt eax, 28
    jnc D_NoCarry
    bts eax, 0
    btr eax, 28
D_NoCarry:
    dec ecx
    jnz L_ShiftD
    mov [ebp-8], eax

    
    xor ebx, ebx         
    xor edx, edx         
    
    mov esi, OFFSET PC2
    mov ecx, 48         
L_PC2:
    movzx eax, byte ptr [esi]  
    
    cmp eax, 28
    ja PC2_FromD         
PC2_FromC:
    push ecx
    mov cl, 28
    sub cl, al           
    mov eax, [ebp-4]
    bt eax, ecx
    pop ecx
    jmp PC2_SetBit
PC2_FromD:
    push ecx
    sub eax, 28
    mov cl, 28
    sub cl, al           
    mov eax, [ebp-8]
    bt eax, ecx
    pop ecx
PC2_SetBit:
    jnc PC2_Next         
    
    mov eax, ecx
    dec eax              
    
    cmp eax, 32
    jae PC2_SetHigh
PC2_SetLow:
    bts edx, eax         
    jmp PC2_Next
PC2_SetHigh:
    push ecx
    mov cl, 32
    sub eax, ecx         
    bts ebx, eax        
    pop ecx
PC2_Next:
    inc esi
    dec ecx
    jnz L_PC2

    
    mov edi, [ebp+12]    
    mov eax, [ebp-20]
    shl eax, 3          
    add edi, eax         
    
    mov [edi+4], ebx    
    mov [edi], edx      

   
    mov eax, [ebp-20]
    inc eax
    mov [ebp-20], eax
    cmp eax, 16
    jl L_RoundLoop      

    
    add esp, 20          
    popad                
    mov eax, 1           
    pop ebp              
    ret
GenerateKeySchedule ENDP


; ==========================================
; ส่วนทดสอบการทำงาน (Test Wrapper)
; ==========================================
.data
    ; เราใช้ Test Vector จากสเปกของอาจารย์: Key = 133457799BBCDFF1[cite: 5]
    ; ประกาศเป็น Array ของ Byte เพื่อเรียงลำดับหน่วยความจำให้ตรงกัน
    TestKey       BYTE 13h, 34h, 57h, 79h, 9Bh, 0BCh, 0DFh, 0F1h
    SubkeysArray  QWORD 16 DUP(0)   ; พื้นที่สำหรับรับ 16 Subkeys
    
    msgK          BYTE "Subkey K", 0
    msgCol        BYTE ": ", 0

.code
main PROC
    ; 1. จำลองพฤติกรรมของ Module A: นำพารามิเตอร์ส่งผ่าน Stack
    push OFFSET SubkeysArray
    push OFFSET TestKey
    call GenerateKeySchedule
    
    ; 2. นำผลลัพธ์ Subkeys ทั้ง 16 ชุด มาปริ้นต์ทางหน้าจอ
    mov ecx, 16                     ; เตรียมวนลูป 16 รอบ
    mov esi, OFFSET SubkeysArray    ; ชี้ไปที่ผลลัพธ์
    mov ebx, 1                      ; ตัวนับหมายเลขรอบ (K1 - K16)
    
PrintKeys:
    ; พิมพ์ข้อความ "Subkey K1: "
    mov edx, OFFSET msgK
    call WriteString
    mov eax, ebx
    call WriteDec
    mov edx, OFFSET msgCol
    call WriteString
    
    ; พิมพ์ค่า Hex 16 บิตบน 
    ; (เนื่องจาก EAX มี 32 บิต ค่าที่ปริ้นต์จะออกมาในรูป 0000XXXX)
    mov eax, [esi+4]     
    call WriteHex
    
    ; พิมพ์ค่า Hex 32 บิตล่าง (YYYYYYYY)
    mov eax, [esi]       
    call WriteHex
    call Crlf            ; ขึ้นบรรทัดใหม่
    
    add esi, 8           ; ขยับ Pointer ไปยัง QWORD ถัดไป (ชุดละ 8 ไบต์)
    inc ebx
    loop PrintKeys
    
    ; จบการทำงาน
    call Crlf
    exit
main ENDP
END main
