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
    mov eax, [esi]  ; First four key bytes are the high half.     
    mov edx, [esi+4]       
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

    
    popad
    add esp, 20                          
    mov eax, 1           
    pop ebp              
    ret
GenerateKeySchedule ENDP


; Module C - DES 16-Round Feistel Core

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
    ; Each S-box occupies 64 bytes: four rows of sixteen columns.
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
; PermuteBits(source, inputBits, table, outputBits, destination)
PermuteBits PROC
    push ebp
    mov ebp, esp
    pushad
    mov esi, [ebp+8]
    mov edi, [ebp+16]
    mov ecx, [ebp+20]
    xor ebx, ebx                  ; output low DWORD
    xor edx, edx                  ; output high DWORD
L_Permute:
    shld edx, ebx, 1
    shl ebx, 1
    movzx eax, byte ptr [edi]
    neg eax
    add eax, [ebp+12]             ; bit index from least significant bit
    bt dword ptr [esi], eax       ; memory BT also handles indices 32..63
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

; FeistelFunction(rightDWORD, roundKeyPointer) -> EAX = f(R, K)
FeistelFunction PROC
    push ebp
    mov ebp, esp
    sub esp, 20                  ; -8: expansion, -12: S result, -20: P result
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
    xor edi, edi                 ; accumulated S-box output
    mov esi, OFFSET S_Boxes
    mov ecx, 8
L_SBox:
    mov ebx, edx
    shr ebx, 10
    and ebx, 3Fh                ; next six bits, from most significant end
    push eax
    mov eax, ebx
    and eax, 20h                ; first bit becomes row bit 1 (index bit 5)
    push ecx
    mov ecx, ebx
    and ecx, 1
    shl ecx, 4                  ; last bit becomes row bit 0 (index bit 4)
    or eax, ecx
    pop ecx
    shr ebx, 1
    and ebx, 0Fh                ; middle four bits select column
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

; DESBlock(source, destination, subkeys, decryptFlag)
; Exactly eight bytes; supports identical source/destination. Returns 1.
DESBlock PROC
    push ebp
    mov ebp, esp
    sub esp, 24                  ; -8: input, -16: R/L, -24: output
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
    add esi, 120                 ; K16 = subkeys + 15 * 8
    mov edi, -8
C_StartRounds:
    mov ecx, 16
L_FeistelRound:
    push esi
    push dword ptr [ebp-16]      ; R
    call FeistelFunction
    add esp, 8
    xor eax, [ebp-12]            ; new R = L XOR f(R, K)
    mov ebx, [ebp-16]
    mov [ebp-12], ebx            ; new L = old R
    mov [ebp-16], eax
    add esi, edi
    dec ecx
    jnz L_FeistelRound
    mov eax, [ebp-16]            ; preoutput is R16 || L16
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

; EncryptBlock / DecryptBlock(source, destination, subkeys)
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

; PKCS7Pad(source, length, destination, capacity) 
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

; PKCS7Unpad(buffer, paddedLength)
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

; EncryptECB / DecryptECB(source, length, destination, capacity, subkeys)
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

.data
DumpHexDigits BYTE "0123456789ABCDEF"
DumpHexSpace  BYTE "  ",0
DumpAsciiBar  BYTE " |",0
DumpLineEnd   BYTE "|",0
DumpTitle     BYTE "Byte frequency histogram (top occurrences):",0
DumpByteText  BYTE "  0x",0
DumpCountText BYTE " : ",0

.code

; DisplayHexDump(buffer, length) prints 16 bytes per row.
; Non-printable bytes are shown as periods in the ASCII column.
DisplayHexDump PROC
    push ebp
    mov ebp, esp
    sub esp, 16
    pushad

    mov eax, [ebp+8]
    mov [ebp-4], eax             ; Current address
    mov eax, [ebp+12]
    mov [ebp-8], eax             ; Remaining bytes
    mov dword ptr [ebp-16], 0    ; Relative offset

HD_Row:
    cmp dword ptr [ebp-8], 0
    je HD_Done

    mov eax, [ebp-16]
    call WriteHex                ; Relative row offset
    mov edx, OFFSET DumpHexSpace
    call WriteString

    mov dword ptr [ebp-12], 0    ; Column
HD_HexColumn:
    mov eax, [ebp-12]
    cmp eax, 16
    jae HD_AsciiStart
    cmp eax, [ebp-8]
    jae HD_HexPadding

    mov esi, [ebp-4]
    movzx eax, BYTE PTR [esi+eax]
    mov ebx, eax
    shr eax, 4
    and eax, 0Fh
    mov al, [DumpHexDigits+eax]
    call WriteChar
    mov eax, ebx
    and eax, 0Fh
    mov al, [DumpHexDigits+eax]
    call WriteChar
    mov al, ' '
    call WriteChar
    jmp HD_NextHex

HD_HexPadding:
    mov al, ' '
    call WriteChar
    call WriteChar
    call WriteChar
HD_NextHex:
    inc dword ptr [ebp-12]
    jmp HD_HexColumn

HD_AsciiStart:
    mov edx, OFFSET DumpAsciiBar
    call WriteString
    mov dword ptr [ebp-12], 0
HD_AsciiColumn:
    mov eax, [ebp-12]
    cmp eax, 16
    jae HD_RowEnd
    cmp eax, [ebp-8]
    jae HD_AsciiPadding
    mov esi, [ebp-4]
    movzx eax, BYTE PTR [esi+eax]
    cmp eax, 20h
    jb HD_NonPrintable
    cmp eax, 7Eh
    ja HD_NonPrintable
    call WriteChar
    jmp HD_NextAscii
HD_NonPrintable:
    mov al, '.'
    call WriteChar
    jmp HD_NextAscii
HD_AsciiPadding:
    mov al, ' '
    call WriteChar
HD_NextAscii:
    inc dword ptr [ebp-12]
    jmp HD_AsciiColumn

HD_RowEnd:
    mov edx, OFFSET DumpLineEnd
    call WriteString
    call Crlf
    mov eax, [ebp-8]
    cmp eax, 16
    jbe HD_LastRow
    sub dword ptr [ebp-8], 16
    add dword ptr [ebp-4], 16
    add dword ptr [ebp-16], 16
    jmp HD_Row
HD_LastRow:
    mov dword ptr [ebp-8], 0
    jmp HD_Row
HD_Done:
    popad
    mov esp, ebp
    pop ebp
    mov eax, 1
    ret
DisplayHexDump ENDP

; ComputeBufferStats(buffer, length, histogram) fills 256 DWORD counters.
ComputeBufferStats PROC
    push ebp
    mov ebp, esp
    pushad
    mov edi, [ebp+16]
    xor eax, eax
    mov ecx, 256
    rep stosd
    mov edi, [ebp+16]
    mov esi, [ebp+8]
    mov ecx, [ebp+12]
CBS_Count:
    test ecx, ecx
    jz CBS_Done
    movzx eax, BYTE PTR [esi]
    inc DWORD PTR [edi+eax*4]
    inc esi
    dec ecx
    jmp CBS_Count
CBS_Done:
    popad
    pop ebp
    mov eax, 1
    ret
ComputeBufferStats ENDP

; DisplayHistogram(histogram) prints the most frequent byte value and count.
DisplayHistogram PROC
    push ebp
    mov ebp, esp
    sub esp, 12
    pushad
    mov edx, OFFSET DumpTitle
    call WriteString
    call Crlf
    mov dword ptr [ebp-4], 0    ; Current byte value
    mov dword ptr [ebp-8], 0    ; Highest count
    mov dword ptr [ebp-12], 0   ; Most frequent byte
DH_FindTop:
    mov esi, [ebp+8]
    mov eax, [ebp-4]
    mov ebx, [esi+eax*4]
    cmp ebx, [ebp-8]
    jbe DH_NextTop
    mov [ebp-8], ebx
    mov [ebp-12], eax
DH_NextTop:
    inc dword ptr [ebp-4]
    cmp dword ptr [ebp-4], 256
    jb DH_FindTop

    cmp dword ptr [ebp-8], 0
    je DH_Done
    mov edx, OFFSET DumpByteText
    call WriteString
    mov eax, [ebp-12]
    shr eax, 4
    and eax, 0Fh
    mov al, [DumpHexDigits+eax]
    call WriteChar
    mov eax, [ebp-12]
    and eax, 0Fh
    mov al, [DumpHexDigits+eax]
    call WriteChar
    mov edx, OFFSET DumpCountText
    call WriteString
    mov eax, [ebp-8]
    call WriteDec
    call Crlf
DH_Done:
    popad
    mov esp, ebp
    pop ebp
    mov eax, 1
    ret
DisplayHistogram ENDP

END 
