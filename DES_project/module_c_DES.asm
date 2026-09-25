.386
.model flat, stdcall
.stack 4096
INCLUDE Irvine32.inc

PUBLIC EncryptECB
PUBLIC DecryptECB

.data
    IP_Table BYTE 58,50,42,34,26,18,10,2,60,52,44,36,28,20,12,4
             BYTE 62,54,46,38,30,22,14,6,64,56,48,40,32,24,16,8
             BYTE 57,49,41,33,25,17,9,1,59,51,43,35,27,19,11,3
             BYTE 61,53,45,37,29,21,13,5,63,55,47,39,31,23,15,7
    FP_Table BYTE 40,8,48,16,56,24,64,32,39,7,47,15,55,23,63,31
             BYTE 38,6,46,14,54,22,62,30,37,5,45,13,53,21,61,29
             BYTE 36,4,44,12,52,20,60,28,35,3,43,11,51,19,59,27
             BYTE 34,2,42,10,50,18,58,26,33,1,41,9,49,17,57,25
    E_Table  BYTE 32,1,2,3,4,5,4,5,6,7,8,9,8,9,10,11,12,13
             BYTE 12,13,14,15,16,17,16,17,18,19,20,21
             BYTE 20,21,22,23,24,25,24,25,26,27,28,29,28,29,30,31,32,1
    P_Table  BYTE 16,7,20,21,29,12,28,17,1,15,23,26,5,18,31,10
             BYTE 2,8,24,14,32,27,3,9,19,13,30,6,22,11,4,25
    S_Boxes BYTE 14,4,13,1,2,15,11,8,3,10,6,12,5,9,0,7
            BYTE 0,15,7,4,14,2,13,1,10,6,12,11,9,5,3,8
            BYTE 4,1,14,8,13,6,2,11,15,12,9,7,3,10,5,0
            BYTE 15,12,8,2,4,9,1,7,5,11,3,14,10,0,6,13
            BYTE 15,1,8,14,6,11,3,4,9,7,2,13,12,0,5,10
            BYTE 3,13,4,7,15,2,8,14,12,0,1,10,6,9,11,5
            BYTE 0,14,7,11,10,4,13,1,5,8,12,6,9,3,2,15
            BYTE 13,8,10,1,3,15,4,2,11,6,7,12,0,5,14,9
            BYTE 10,0,9,14,6,3,15,5,1,13,12,7,11,4,2,8
            BYTE 13,7,0,9,3,4,6,10,2,8,5,14,12,11,15,1
            BYTE 13,6,4,9,8,15,3,0,11,1,2,12,5,10,14,7
            BYTE 1,10,13,0,6,9,8,7,4,15,14,3,11,5,2,12
            BYTE 7,13,14,3,0,6,9,10,1,2,8,5,11,12,4,15
            BYTE 13,8,11,5,6,15,0,3,4,7,2,12,1,10,14,9
            BYTE 10,6,9,0,12,11,7,13,15,1,3,14,5,2,8,4
            BYTE 3,15,0,6,10,1,13,8,9,4,5,11,12,7,2,14
            BYTE 2,12,4,1,7,10,11,6,8,5,3,15,13,0,14,9
            BYTE 14,11,2,12,4,7,13,1,5,0,15,10,3,9,8,6
            BYTE 4,2,1,11,10,13,7,8,15,9,12,5,6,3,0,14
            BYTE 11,8,12,7,1,14,2,13,6,15,0,9,10,4,5,3
            BYTE 12,1,10,15,9,2,6,8,0,13,3,4,14,7,5,11
            BYTE 10,15,4,2,7,12,9,5,6,1,13,14,0,11,3,8
            BYTE 9,14,15,5,2,8,12,3,7,0,4,10,1,13,11,6
            BYTE 4,3,2,12,9,5,15,10,11,14,1,7,6,0,8,13
            BYTE 4,11,2,14,15,0,8,13,3,12,9,7,5,10,6,1
            BYTE 13,0,11,7,4,9,1,10,14,3,5,12,2,15,8,6
            BYTE 1,4,11,13,12,3,7,14,10,15,6,8,0,5,9,2
            BYTE 6,11,13,8,1,4,10,7,9,5,0,15,14,2,3,12
            BYTE 13,2,8,4,6,15,11,1,10,9,3,14,5,0,12,7
            BYTE 1,15,13,8,10,3,7,4,12,5,6,11,0,14,9,2
            BYTE 7,11,4,1,9,12,14,2,0,6,10,13,15,3,5,8
            BYTE 2,1,14,7,4,10,8,13,15,12,9,0,3,5,6,11

.code
PermuteBits PROC
    push ebp
    mov ebp, esp
    pushad
    mov esi, [ebp+8]
    mov edi, [ebp+16]
    mov ecx, [ebp+20]
    xor ebx, ebx                  
    xor edx, edx                  
L_Permute:
    shld edx, ebx, 1
    shl ebx, 1
    movzx eax, byte ptr [edi]
    neg eax
    add eax, [ebp+12]             
    bt dword ptr [esi], eax       
    adc ebx, 0
    inc edi
    dec ecx
    jnz L_Permute
    mov edi, [ebp+24]
    mov [edi], ebx
    mov [edi+4], edx
    popad
    mov eax, 1
    pop ebp
    ret
PermuteBits ENDP

FeistelFunction PROC
    push ebp
    mov ebp, esp
    sub esp, 20                  
    pushad
    lea eax, [ebp-8]
    push eax
    push 48
    push OFFSET E_Table
    push 32
    lea eax, [ebp+8]
    push eax
    call PermuteBits
    add esp, 20
    mov esi, [ebp+12]
    mov eax, [ebp-8]
    mov edx, [ebp-4]
    xor eax, [esi]
    xor edx, [esi+4]
    xor edi, edi                 
    mov esi, OFFSET S_Boxes
    mov ecx, 8
L_SBox:
    mov ebx, edx
    shr ebx, 10
    and ebx, 3Fh                
    push eax
    mov eax, ebx
    and eax, 20h                
    push ecx
    mov ecx, ebx
    and ecx, 1
    shl ecx, 4                  
    or eax, ecx
    pop ecx
    shr ebx, 1
    and ebx, 0Fh                
    or eax, ebx
    movzx ebx, byte ptr [esi+eax]
    pop eax
    shl edi, 4
    or edi, ebx
    shld edx, eax, 6
    shl eax, 6
    add esi, 64
    dec ecx
    jnz L_SBox
    mov [ebp-12], edi
    lea eax, [ebp-20]
    push eax
    push 32
    push OFFSET P_Table
    push 32
    lea eax, [ebp-12]
    push eax
    call PermuteBits
    add esp, 20
    popad
    mov eax, [ebp-20]
    mov esp, ebp
    pop ebp
    ret
FeistelFunction ENDP

DESBlock PROC
    push ebp
    mov ebp, esp
    sub esp, 24                  
    pushad
    mov esi, [ebp+8]
    mov eax, [esi]
    bswap eax
    mov [ebp-4], eax
    mov eax, [esi+4]
    bswap eax
    mov [ebp-8], eax
    lea eax, [ebp-16]
    push eax
    push 64
    push OFFSET IP_Table
    push 64
    lea eax, [ebp-8]
    push eax
    call PermuteBits
    add esp, 20
    mov esi, [ebp+16]
    mov edi, 8
    cmp dword ptr [ebp+20], 0
    je C_StartRounds
    add esi, 120                 
    mov edi, -8
C_StartRounds:
    mov ecx, 16
L_FeistelRound:
    push esi
    push dword ptr [ebp-16]      
    call FeistelFunction
    add esp, 8
    xor eax, [ebp-12]            
    mov ebx, [ebp-16]
    mov [ebp-12], ebx            
    mov [ebp-16], eax
    add esi, edi
    dec ecx
    jnz L_FeistelRound
    mov eax, [ebp-16]            
    xchg eax, [ebp-12]
    mov [ebp-16], eax
    lea eax, [ebp-24]
    push eax
    push 64
    push OFFSET FP_Table
    push 64
    lea eax, [ebp-16]
    push eax
    call PermuteBits
    add esp, 20
    mov edi, [ebp+12]
    mov eax, [ebp-20]
    bswap eax
    mov [edi], eax
    mov eax, [ebp-24]
    bswap eax
    mov [edi+4], eax
    popad
    mov eax, 1
    mov esp, ebp
    pop ebp
    ret
DESBlock ENDP

EncryptBlock PROC
    push ebp
    mov ebp, esp
    push 0
    push dword ptr [ebp+16]
    push dword ptr [ebp+12]
    push dword ptr [ebp+8]
    call DESBlock
    add esp, 16
    pop ebp
    ret
EncryptBlock ENDP

DecryptBlock PROC
    push ebp
    mov ebp, esp
    push 1
    push dword ptr [ebp+16]
    push dword ptr [ebp+12]
    push dword ptr [ebp+8]
    call DESBlock
    add esp, 16
    pop ebp
    ret
DecryptBlock ENDP

PKCS7Pad PROC
    push ebp
    mov ebp, esp
    sub esp, 4
    pushad
    mov dword ptr [ebp-4], -1
    mov ecx, [ebp+12]
    cmp ecx, 0FFFFFFF7h
    ja C_PadDone
    mov ebx, ecx
    and ebx, 0FFFFFFF8h
    add ebx, 8
    cmp ebx, [ebp+20]
    ja C_PadDone
    mov esi, [ebp+8]
    mov edi, [ebp+16]
    test ecx, ecx
    jz C_PadTail
L_PadCopy:
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    dec ecx
    jnz L_PadCopy
C_PadTail:
    mov eax, ebx
    sub eax, [ebp+12]
    mov ecx, eax
L_PadBytes:
    mov [edi], al
    inc edi
    dec ecx
    jnz L_PadBytes
    mov [ebp-4], ebx
C_PadDone:
    popad
    mov eax, [ebp-4]
    mov esp, ebp
    pop ebp
    ret
PKCS7Pad ENDP

PKCS7Unpad PROC
    push ebp
    mov ebp, esp
    sub esp, 4
    pushad
    mov dword ptr [ebp-4], -1
    mov ecx, [ebp+12]
    test ecx, ecx
    jz C_UnpadDone
    test ecx, 7
    jnz C_UnpadDone
    mov esi, [ebp+8]
    add esi, ecx
    movzx eax, byte ptr [esi-1]
    cmp eax, 1
    jb C_UnpadDone
    cmp eax, 8
    ja C_UnpadDone
    sub ecx, eax
    mov ebx, ecx
    mov ecx, eax
L_CheckPadding:
    dec esi
    cmp byte ptr [esi], al
    jne C_UnpadDone
    dec ecx
    jnz L_CheckPadding
    mov [ebp-4], ebx
C_UnpadDone:
    popad
    mov eax, [ebp-4]
    mov esp, ebp
    pop ebp
    ret
PKCS7Unpad ENDP

EncryptECB PROC
    push ebp
    mov ebp, esp
    sub esp, 4
    pushad
    push dword ptr [ebp+20]
    push dword ptr [ebp+16]
    push dword ptr [ebp+12]
    push dword ptr [ebp+8]
    call PKCS7Pad
    add esp, 16
    mov [ebp-4], eax
    cmp eax, -1
    je C_EncryptDone
    mov ecx, eax
    shr ecx, 3
    mov esi, [ebp+16]
L_EncryptECB:
    push dword ptr [ebp+24]
    push esi
    push esi
    call EncryptBlock
    add esp, 12
    add esi, 8
    dec ecx
    jnz L_EncryptECB
C_EncryptDone:
    popad
    mov eax, [ebp-4]
    mov esp, ebp
    pop ebp
    ret
EncryptECB ENDP

DecryptECB PROC
    push ebp
    mov ebp, esp
    sub esp, 4
    pushad
    mov dword ptr [ebp-4], -1
    mov ecx, [ebp+12]
    test ecx, ecx
    jz C_DecryptDone
    test ecx, 7
    jnz C_DecryptDone
    cmp ecx, [ebp+20]
    ja C_DecryptDone
    shr ecx, 3
    mov esi, [ebp+8]
    mov edi, [ebp+16]
L_DecryptECB:
    push dword ptr [ebp+24]
    push edi
    push esi
    call DecryptBlock
    add esp, 12
    add esi, 8
    add edi, 8
    dec ecx
    jnz L_DecryptECB
    push dword ptr [ebp+12]
    push dword ptr [ebp+16]
    call PKCS7Unpad
    add esp, 8
    mov [ebp-4], eax
C_DecryptDone:
    popad
    mov eax, [ebp-4]
    mov esp, ebp
    pop ebp
    ret
DecryptECB ENDP
END