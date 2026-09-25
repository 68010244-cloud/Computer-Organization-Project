.386
.model flat, stdcall
.stack 4096
INCLUDE Irvine32.inc

PUBLIC DisplayHexDump
PUBLIC ComputeBufferStats
PUBLIC DisplayHistogram

.data
    DumpHeader    BYTE "[Address]  00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F  | ASCII", 0
    DumpHexDigits BYTE "0123456789ABCDEF"
    DumpHexSpace  BYTE "  ", 0
    DumpAsciiBar  BYTE "  | ", 0
    DumpTitle     BYTE "Top Byte Occurrences:", 0
    DumpByteText1 BYTE " [0x", 0
    DumpByteText2 BYTE "] : ", 0
    DumpCountText BYTE " occurrences [", 0
    DumpStarChar  BYTE "*", 0
    DumpBracket   BYTE "]", 0
    
    HistCount     DWORD 256 DUP(0)
    pBuffer       DWORD 0    ; เก็บตำแหน่งของไฟล์ไว้ใช้หาลำดับ
    szBuffer      DWORD 0    ; เก็บขนาดของไฟล์

.code
DisplayHexDump PROC
    push ebp
    mov ebp, esp
    sub esp, 16
    pushad

    mov edx, OFFSET DumpHeader
    call WriteString
    call Crlf

    mov eax, [ebp + 8]   
    mov [ebp - 4], eax
    mov eax, [ebp + 12]  
    mov [ebp - 8], eax
    mov dword ptr [ebp - 16], 0 

HD_Row:
    cmp dword ptr [ebp - 8], 0
    je HD_Done

    mov eax, [ebp - 16]
    call WriteHex
    mov edx, OFFSET DumpHexSpace
    call WriteString
    mov dword ptr [ebp - 12], 0

HD_HexColumn:
    mov eax, [ebp - 12]
    cmp eax, 16
    jae HD_AsciiStart
    cmp eax, [ebp - 8]
    jae HD_HexPadding

    mov esi, [ebp - 4]
    movzx eax, BYTE PTR [esi + eax]
    mov ebx, eax
    shr eax, 4
    and eax, 0Fh
    mov al, [DumpHexDigits + eax]
    call WriteChar
    mov eax, ebx
    and eax, 0Fh
    mov al, [DumpHexDigits + eax]
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
    inc dword ptr [ebp - 12]
    jmp HD_HexColumn

HD_AsciiStart:
    mov edx, OFFSET DumpAsciiBar
    call WriteString
    mov dword ptr [ebp - 12], 0

HD_AsciiColumn:
    mov eax, [ebp - 12]
    cmp eax, 16
    jae HD_RowEnd
    cmp eax, [ebp - 8]
    jae HD_AsciiPadding
    
    mov esi, [ebp - 4]
    movzx eax, BYTE PTR [esi + eax]
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
    inc dword ptr [ebp - 12]
    jmp HD_AsciiColumn

HD_RowEnd:
    call Crlf
    mov eax, [ebp - 8]
    cmp eax, 16
    jbe HD_LastRow
    sub dword ptr [ebp - 8], 16
    add dword ptr [ebp - 4], 16
    add dword ptr [ebp - 16], 16
    jmp HD_Row

HD_LastRow:
    mov dword ptr [ebp - 8], 0
    jmp HD_Row

HD_Done:
    popad
    mov esp, ebp
    pop ebp
    mov eax, 1
    ret 8
DisplayHexDump ENDP


ComputeBufferStats PROC
    push ebp
    mov ebp, esp
    pushad
    
    mov edi, OFFSET HistCount
    xor eax, eax
    mov ecx, 256
    rep stosd
    
    ; เก็บ Buffer Pointer และ Size ไว้ใช้ในฟังก์ชันถัดไป
    mov esi, [ebp + 8] 
    mov [pBuffer], esi
    mov ecx, [ebp + 12] 
    mov [szBuffer], ecx
    
CBS_Count:
    test ecx, ecx
    jz CBS_Done
    movzx eax, BYTE PTR [esi]
    inc DWORD PTR [HistCount + eax * 4]
    inc esi
    dec ecx
    jmp CBS_Count

CBS_Done:
    popad
    pop ebp
    mov eax, 1
    ret 16
ComputeBufferStats ENDP


DisplayHistogram PROC
    push ebp
    mov ebp, esp
    sub esp, 16          
    pushad
    
    mov edx, OFFSET DumpTitle
    call WriteString
    call Crlf
    mov dword ptr [ebp - 12], 1   

DH_TopLoop:
    mov dword ptr [ebp - 4], 0   ; max_val
    mov dword ptr [ebp - 8], 0   ; max_byte
    
    ; สแกนจากไฟล์จริง เพื่อให้ไบต์ที่ปรากฏก่อนชนะเวลาเสมอ (Tie-breaker)
    mov esi, [pBuffer]
    mov ecx, [szBuffer]
    test ecx, ecx
    jz DH_PrintTop

DH_FindMax:
    movzx eax, BYTE PTR [esi]
    mov ebx, [HistCount + eax * 4]
    cmp ebx, [ebp - 4]
    jbe DH_SkipMax               ; ถ้าจำนวนน้อยกว่าหรือเท่ากับ (<=) ให้ข้าม (ตัวมาก่อนได้เปรียบ)
    mov [ebp - 4], ebx
    mov [ebp - 8], eax
DH_SkipMax:
    inc esi
    dec ecx
    jnz DH_FindMax

DH_PrintTop:
    cmp dword ptr [ebp - 4], 0
    je DH_Done

    mov eax, [ebp - 12]
    call WriteDec
    mov al, '.'
    call WriteChar

    mov edx, OFFSET DumpByteText1
    call WriteString
    mov eax, [ebp - 8]
    shr eax, 4
    and eax, 0Fh
    mov al, [DumpHexDigits + eax]
    call WriteChar
    mov eax, [ebp - 8]
    and eax, 0Fh
    mov al, [DumpHexDigits + eax]
    call WriteChar
    mov edx, OFFSET DumpByteText2
    call WriteString
    
    mov eax, [ebp - 4]
    call WriteDec
    mov edx, OFFSET DumpCountText
    call WriteString
    
    ; วาดกราฟดาวตามจำนวนครั้งที่พบ (Histogram)
    mov ecx, [ebp - 4]
PrintStars:
    mov edx, OFFSET DumpStarChar
    call WriteString
    dec ecx
    jnz PrintStars

    mov edx, OFFSET DumpBracket
    call WriteString            ; ปิดวงเล็บให้สมบูรณ์
    call Crlf

    ; ลบความถี่ของแชมป์รอบนี้ทิ้ง เพื่อหารองแชมป์ในรอบถัดไป
    mov eax, [ebp - 8]
    mov dword ptr [HistCount + eax * 4], 0

    inc dword ptr [ebp - 12]
    cmp dword ptr [ebp - 12], 5
    jbe DH_TopLoop

DH_Done:
    popad
    mov esp, ebp
    pop ebp
    mov eax, 1
    ret
DisplayHistogram ENDP
END