; Module D: Memory Dump and Buffer Analytics
; Assemble with the project module that defines Irvine32 procedures.

INCLUDE Irvine32.inc

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
