.386
.model flat, stdcall
.stack 4096
INCLUDE Irvine32.inc

GenerateKeySchedule PROTO
EncryptECB PROTO
DecryptECB PROTO
DisplayHexDump PROTO
ComputeBufferStats PROTO
DisplayHistogram PROTO

.data
    promptMsg   BYTE "DES-SHELL> ", 0
    errorMsg    BYTE "Error: Unknown command or syntax error.", 0
    exitMsg     BYTE "Exiting DES Command-Line Shell...", 0
    errFile     BYTE "Error: Cannot open or create file.", 0
    errIO       BYTE "Error: File read/write failed or file exceeds 65536 bytes.", 0
    errCipher   BYTE "Error: Invalid ciphertext/padding or insufficient buffer capacity.", 0
    errInput    BYTE "Error: Cannot read console input.", 0
    keyEquals   BYTE " = ", 0
    hexDigits   BYTE "0123456789ABCDEF"
    
    ; --- ชุดข้อความสำหรับแสดงผลให้เหมือน Sample Run เป๊ะๆ ---
    msgLoad1    BYTE "Loading ", 0
    msgLoad2    BYTE " (", 0
    msgLoad3    BYTE " bytes)...", 0
    msgKeyGen   BYTE "Executing DES 16-round key generation...", 0
    msgProc1    BYTE "Processing ", 0
    msgProc2    BYTE " block(s) in ECB mode...", 0
    msgEncSucc  BYTE "File encrypted successfully -> ", 22h, 0
    msgDecSucc  BYTE "File decrypted successfully -> ", 22h, 0
    msgQuote    BYTE 22h, 0
    msgStat1    BYTE "Total File Size: ", 0
    msgStat2    BYTE " Bytes", 0

    encExt      BYTE ".enc", 0
    decExt      BYTE ".dec", 0

    inputBuf    BYTE 256 DUP(0)
    byteRead    DWORD ?
    inputChar   BYTE ?
    tokenCount  DWORD 0
    tokenPtrs   DWORD 3 DUP(0)
    tokenQuoted DWORD 3 DUP(0)

    fileName    BYTE 256 DUP(0)
    outFileName BYTE 256 DUP(0)
    userKey     BYTE 8 DUP(0)       
    subkeys     QWORD 16 DUP(0)     
    
    fileBuffer  BYTE 65537 DUP(0) ; Extra byte detects files beyond the limit.
    fileSize    DWORD 0
    fileHandle  DWORD ?

    cmdExit     BYTE "EXIT", 0
    cmdClear    BYTE "CLEAR", 0
    cmdKeygen   BYTE "KEYGEN", 0
    cmdEncrypt  BYTE "ENCRYPT", 0
    cmdDecrypt  BYTE "DECRYPT", 0
    cmdDump     BYTE "DUMP", 0
    cmdStats    BYTE "STATS", 0

.code
main PROC
    push ebp
    mov ebp, esp
    pushad
ShellLoop:
    mov edx, OFFSET promptMsg
    call WriteString
    call ReadCommandLine
    cmp eax, -2
    je InputError
    cmp eax, -1
    je ExitShell
    test eax, eax
    jz ParseError
    call TokenizeCommand
    test eax, eax
    jz ParseError
    cmp tokenCount, 0
    je ShellLoop

    push OFFSET cmdExit
    push tokenPtrs[0]
    call CompareCommand
    cmp eax, 1
    je DoExit

    push OFFSET cmdClear
    push tokenPtrs[0]
    call CompareCommand
    cmp eax, 1
    je DoClear

    push OFFSET cmdKeygen
    push tokenPtrs[0]
    call CompareCommand
    cmp eax, 1
    je DoKeygen
    
    push OFFSET cmdEncrypt
    push tokenPtrs[0]
    call CompareCommand
    cmp eax, 1
    je DoEncrypt

    push OFFSET cmdDecrypt
    push tokenPtrs[0]
    call CompareCommand
    cmp eax, 1
    je DoDecrypt

    push OFFSET cmdDump
    push tokenPtrs[0]
    call CompareCommand
    cmp eax, 1
    je DoDump

    push OFFSET cmdStats
    push tokenPtrs[0]
    call CompareCommand
    cmp eax, 1
    je DoStats

    mov edx, OFFSET errorMsg
    call WriteString
    call Crlf
    jmp ShellLoop

DoClear:
    cmp tokenCount, 1
    jne ParseError
    call Clrscr
    jmp ShellLoop

DoExit:
    cmp tokenCount, 1
    jne ParseError
ExitShell:
    mov edx, OFFSET exitMsg
    call WriteString
    call Crlf
    popad
    pop ebp
    exit

DoKeygen:
    cmp tokenCount, 2
    jne ParseError
    cmp tokenQuoted[4], 0
    jne ParseError
    push OFFSET userKey
    push tokenPtrs[4]
    call ExtractHexKey
    cmp eax, 0
    je ParseError
    push OFFSET subkeys
    push OFFSET userKey
    call GenerateKeySchedule
    add esp, 8
    call DisplaySubkeys
    jmp ShellLoop

DoEncrypt:
    call ParseFileAndKey
    cmp eax, 0
    je ParseError
    call LoadFileToBuffer
    cmp eax, 0
    je ShellLoop
    
    ; 1. พิมพ์: Loading secret.txt (16 bytes)...
    mov edx, OFFSET msgLoad1
    call WriteString
    mov edx, OFFSET fileName
    call WriteString
    mov edx, OFFSET msgLoad2
    call WriteString
    mov eax, fileSize
    call WriteDec
    mov edx, OFFSET msgLoad3
    call WriteString
    call Crlf
    
    ; 2. พิมพ์: Executing DES 16-round key generation...
    mov edx, OFFSET msgKeyGen
    call WriteString
    call Crlf
    
    ; 3. พิมพ์: Processing X block(s) in ECB mode...
    mov edx, OFFSET msgProc1
    call WriteString
    mov eax, fileSize
    shr eax, 3         ; PKCS#7 always adds a final block.
    inc eax
    call WriteDec
    mov edx, OFFSET msgProc2
    call WriteString
    call Crlf

    push OFFSET subkeys
    push OFFSET userKey
    call GenerateKeySchedule
    add esp, 8
    push OFFSET subkeys
    push 65536          
    push OFFSET fileBuffer
    push fileSize
    push OFFSET fileBuffer
    call EncryptECB
    add esp, 20
    cmp eax, -1
    je CipherError
    mov fileSize, eax   
    
    push OFFSET encExt
    call MakeOutputName
    call SaveBufferToFile
    test eax, eax
    jz ShellLoop
    
    ; 4. พิมพ์: File encrypted successfully -> "secret.txt.enc"
    mov edx, OFFSET msgEncSucc
    call WriteString
    mov edx, OFFSET outFileName
    call WriteString
    mov edx, OFFSET msgQuote
    call WriteString
    call Crlf
    
    jmp ShellLoop

DoDecrypt:
    call ParseFileAndKey
    cmp eax, 0
    je ParseError
    call LoadFileToBuffer
    cmp eax, 0
    je ShellLoop
    
    mov edx, OFFSET msgLoad1
    call WriteString
    mov edx, OFFSET fileName
    call WriteString
    mov edx, OFFSET msgLoad2
    call WriteString
    mov eax, fileSize
    call WriteDec
    mov edx, OFFSET msgLoad3
    call WriteString
    call Crlf
    
    mov edx, OFFSET msgKeyGen
    call WriteString
    call Crlf
    
    mov edx, OFFSET msgProc1
    call WriteString
    mov eax, fileSize
    add eax, 7
    shr eax, 3
    call WriteDec
    mov edx, OFFSET msgProc2
    call WriteString
    call Crlf

    push OFFSET subkeys
    push OFFSET userKey
    call GenerateKeySchedule
    add esp, 8
    push OFFSET subkeys
    push 65536          
    push OFFSET fileBuffer
    push fileSize
    push OFFSET fileBuffer
    call DecryptECB
    add esp, 20
    cmp eax, -1
    je CipherError
    mov fileSize, eax
    
    push OFFSET decExt
    call MakeOutputName
    call SaveBufferToFile
    test eax, eax
    jz ShellLoop
    
    mov edx, OFFSET msgDecSucc
    call WriteString
    mov edx, OFFSET outFileName
    call WriteString
    mov edx, OFFSET msgQuote
    call WriteString
    call Crlf

    jmp ShellLoop

DoDump:
    cmp tokenCount, 2
    jne ParseError
    push OFFSET fileName
    push tokenPtrs[4]
    call ExtractQuotedString
    cmp eax, 0
    je ParseError
    call LoadFileToBuffer
    cmp eax, 0
    je ShellLoop
    
    push fileSize
    push OFFSET fileBuffer
    call DisplayHexDump
    jmp ShellLoop

DoStats:
    cmp tokenCount, 2
    jne ParseError
    push OFFSET fileName
    push tokenPtrs[4]
    call ExtractQuotedString
    cmp eax, 0
    je ParseError
    call LoadFileToBuffer
    cmp eax, 0
    je ShellLoop
    
    ; 1. พิมพ์: Total File Size: X Bytes
    mov edx, OFFSET msgStat1
    call WriteString
    mov eax, fileSize
    call WriteDec
    mov edx, OFFSET msgStat2
    call WriteString
    call Crlf
    
    push 0
    push OFFSET fileBuffer
    push fileSize
    push OFFSET fileBuffer
    call ComputeBufferStats
    call DisplayHistogram
    jmp ShellLoop

ParseError:
    mov edx, OFFSET errorMsg
    jmp PrintShellError
CipherError:
    mov edx, OFFSET errCipher
PrintShellError:
    call WriteString
    call Crlf
    jmp ShellLoop
InputError:
    mov edx, OFFSET errInput
    call WriteString
    call Crlf
    jmp ExitShell
main ENDP


; =========================================================
; Helper Functions
; =========================================================
; Read a complete line, draining excess input instead of executing a prefix.
; EAX = 1 (line), 0 (invalid/too long), -1 (EOF), -2 (read failure).
ReadCommandLine PROC
    push ebp
    mov ebp, esp
    push ebx
    push ecx
    push edx
    push esi
    push edi
    invoke GetStdHandle, STD_INPUT_HANDLE
    mov ebx, eax
    xor esi, esi
    xor edi, edi             ; Nonzero if the entire line must be rejected.
ReadLineByte:
    invoke ReadFile, ebx, ADDR inputChar, 1, ADDR byteRead, 0
    test eax, eax
    jz ReadLineFailure
    cmp byteRead, 0
    je ReadLineEOF
    mov al, inputChar
    cmp al, 10
    je ReadLineDone
    cmp al, 13
    je ReadLineByte
    test al, al
    jz ReadLineInvalid
    cmp esi, SIZEOF inputBuf-1
    jae ReadLineInvalid
    mov inputBuf[esi], al
    inc esi
    jmp ReadLineByte
ReadLineInvalid:
    mov edi, 1
    jmp ReadLineByte
ReadLineFailure:
    mov eax, -2
    jmp ReadLineReturn
ReadLineEOF:
    mov eax, -1
    test esi, esi
    jnz ReadLineDone
    test edi, edi
    jz ReadLineReturn
ReadLineDone:
    mov inputBuf[esi], 0
    mov eax, 1
    sub eax, edi
ReadLineReturn:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ebp
    ret
ReadCommandLine ENDP

; A label-encoded FSM: SPACE -> TOKEN or QUOTED -> AFTER_QUOTE -> SPACE.
; END accepts; INVALID rejects. Tokens point into inputBuf, terminated in place.
TokenizeCommand PROC
    push ebp
    mov ebp, esp
    push esi
    push ebx
    mov esi, OFFSET inputBuf
    mov tokenCount, 0
STATE_SPACE:
    mov al, [esi]
    test al, al
    jz STATE_END
    cmp al, ' '
    je FSM_SkipSpace
    cmp al, 9
    je FSM_SkipSpace
    mov ebx, tokenCount
    cmp ebx, 3
    jae STATE_INVALID
    mov tokenPtrs[ebx*4], esi
    mov tokenQuoted[ebx*4], 0
    inc tokenCount
    cmp al, 22h
    jne STATE_TOKEN
    test ebx, ebx           ; A command itself cannot be quoted.
    jz STATE_INVALID
    mov tokenQuoted[ebx*4], 1
    inc esi
    mov tokenPtrs[ebx*4], esi
STATE_QUOTED:
    mov al, [esi]
    test al, al
    jz STATE_INVALID
    cmp al, 22h
    je FSM_CloseQuote
    inc esi
    jmp STATE_QUOTED
FSM_CloseQuote:
    cmp esi, tokenPtrs[ebx*4]
    je STATE_INVALID       ; Empty filenames/quoted arguments are invalid.
    mov byte ptr [esi], 0
    inc esi
STATE_AFTER_QUOTE:
    mov al, [esi]
    test al, al
    jz STATE_END
    cmp al, ' '
    je FSM_SkipSpace
    cmp al, 9
    jne STATE_INVALID
FSM_SkipSpace:
    inc esi
    jmp STATE_SPACE
STATE_TOKEN:
    mov al, [esi]
    test al, al
    jz STATE_END
    cmp al, 22h
    je STATE_INVALID
    cmp al, ' '
    je FSM_EndToken
    cmp al, 9
    je FSM_EndToken
    inc esi
    jmp STATE_TOKEN
FSM_EndToken:
    mov byte ptr [esi], 0
    inc esi
    jmp STATE_SPACE
STATE_INVALID:
    xor eax, eax
    jmp FSM_Return
STATE_END:
    mov eax, 1
FSM_Return:
    pop ebx
    pop esi
    pop ebp
    ret
TokenizeCommand ENDP

; Each QWORD stores the low 32 bits followed by the high 16 bits of Ki.
DisplaySubkeys PROC
    push ebp
    mov ebp, esp
    pushad
    mov esi, OFFSET subkeys
    mov edi, 1
SubkeyRow:
    mov al, 'K'
    call WriteChar
    cmp edi, 10
    jae SubkeyNumber
    mov al, '0'
    call WriteChar
SubkeyNumber:
    mov eax, edi
    call WriteDec
    mov edx, OFFSET keyEquals
    call WriteString
    mov ecx, 12
    mov ebx, [esi+4]
SubkeyHigh:
    mov eax, ebx
    shr eax, cl
    and eax, 0Fh
    mov al, hexDigits[eax]
    call WriteChar
    sub ecx, 4
    jns SubkeyHigh
    mov eax, [esi]
    call WriteHex
    call Crlf
    add esi, 8
    inc edi
    cmp edi, 16
    jbe SubkeyRow
    popad
    mov eax, 1
    pop ebp
    ret
DisplaySubkeys ENDP

LoadFileToBuffer PROC
    push ebp
    mov ebp, esp
    pushad
    mov edx, OFFSET fileName
    call OpenInputFile
    cmp eax, INVALID_HANDLE_VALUE
    je LoadError
    mov fileHandle, eax
    mov fileSize, 0
LoadRead:
    mov edx, OFFSET fileBuffer
    add edx, fileSize
    mov ecx, 65537
    sub ecx, fileSize
    invoke ReadFile, fileHandle, edx, ecx, ADDR byteRead, 0
    test eax, eax
    jz LoadReadError
    mov eax, byteRead
    add fileSize, eax
    cmp fileSize, 65536
    ja LoadReadError
    test eax, eax
    jnz LoadRead
    mov eax, fileHandle
    call CloseFile
    test eax, eax
    jz LoadCloseError
    ; นำคำสั่ง WriteString ข้อความ "bytes loaded" ออกไปเพื่อไม่ให้รกหน้าจอ
    popad
    mov eax, 1
    pop ebp
    ret
LoadReadError:
    mov eax, fileHandle
    call CloseFile
LoadCloseError:
    mov edx, OFFSET errIO
    jmp LoadReport
LoadError:
    mov edx, OFFSET errFile
LoadReport:
    call WriteString
    call Crlf
    popad
    mov eax, 0
    pop ebp
    ret
LoadFileToBuffer ENDP

SaveBufferToFile PROC
    push ebp
    mov ebp, esp
    pushad
    mov edx, OFFSET outFileName
    call CreateOutputFile
    cmp eax, INVALID_HANDLE_VALUE
    je SaveError
    mov fileHandle, eax
    invoke WriteFile, fileHandle, ADDR fileBuffer, fileSize, ADDR byteRead, 0
    test eax, eax
    jz SaveWriteError
    mov eax, byteRead
    cmp eax, fileSize
    jne SaveWriteError
    mov eax, fileHandle
    call CloseFile
    test eax, eax
    jz SaveCloseError
    ; นำคำสั่ง WriteString ข้อความ "Operation successful" ออกไป
    popad
    mov eax, 1
    pop ebp
    ret
SaveWriteError:
    mov eax, fileHandle
    call CloseFile
SaveCloseError:
    mov edx, OFFSET errIO
    jmp SaveReport
SaveError:
    mov edx, OFFSET errFile
SaveReport:
    call WriteString
    call Crlf
    popad
    xor eax, eax
    pop ebp
    ret
SaveBufferToFile ENDP

ParseFileAndKey PROC
    push ebp
    mov ebp, esp
    cmp tokenCount, 3
    jne PFK_Fail
    cmp tokenQuoted[8], 0
    jne PFK_Fail
    push OFFSET fileName
    push tokenPtrs[4]
    call ExtractQuotedString
    cmp eax, 0
    je PFK_Fail
    push OFFSET userKey
    push tokenPtrs[8]
    call ExtractHexKey
    cmp eax, 0
    je PFK_Fail
    mov eax, 1
    jmp PFK_Done
PFK_Fail:
    mov eax, 0
PFK_Done:
    mov esp, ebp
    pop ebp
    ret
ParseFileAndKey ENDP

MakeOutputName PROC
    push ebp
    mov ebp, esp
    pushad
    mov esi, OFFSET fileName
    mov edi, OFFSET outFileName
CopyName:
    mov al, [esi]
    cmp al, 0
    je AppendExt
    mov [edi], al
    inc esi
    inc edi
    jmp CopyName
AppendExt:
    mov esi, [ebp+8] 
CopyExt:
    mov al, [esi]
    mov [edi], al
    cmp al, 0
    je DoneMake
    inc esi
    inc edi
    jmp CopyExt
DoneMake:
    popad
    pop ebp
    ret 4
MakeOutputName ENDP

CompareCommand PROC
    push ebp
    mov ebp, esp
    push esi
    push edi
    push edx
    mov esi, [ebp+8]    
    mov edi, [ebp+12]   
CompLoop:
    mov al, [edi]
    cmp al, 0           
    je CompMatch
    mov dl, [esi]
    cmp dl, 0           
    je CompFail
    cmp al, dl          
    jne CompFail         
    inc esi
    inc edi
    jmp CompLoop
CompMatch:
    mov dl, [esi]
    cmp dl, 20h
    je CompSucc
    cmp dl, 0
    je CompSucc
CompFail:
    mov eax, 0
    jmp CompEnd
CompSucc:
    mov eax, 1
CompEnd:
    pop edx
    pop edi
    pop esi
    mov esp, ebp
    pop ebp
    ret 8               
CompareCommand ENDP

ExtractQuotedString PROC
    push ebp
    mov ebp, esp
    push esi
    push edi
    push ecx
    mov esi, [ebp+8]
    mov edi, [ebp+12]
    ; The FSM has already removed quotes and terminated the filename token.
    xor ecx, ecx
    cmp byte ptr [esi], 0
    je QFail
CopyQ:
    mov al, [esi]
    cmp al, 0
    je QSucc
    cmp ecx, 251       ; Leave room for .enc/.dec and the terminator.
    jae QFail
    mov [edi], al
    inc esi
    inc edi
    inc ecx
    jmp CopyQ
QFail:
    mov eax, 0
    jmp QEnd
QSucc:
    mov byte ptr [edi], 0
    mov eax, 1
QEnd:
    pop ecx
    pop edi
    pop esi
    mov esp, ebp
    pop ebp
    ret 8
ExtractQuotedString ENDP

ExtractHexKey PROC
    push ebp
    mov ebp, esp
    push esi
    push edi
    push ebx
    push ecx
    mov esi, [ebp+8]
    mov edi, [ebp+12]
    cmp byte ptr [esi], '0'
    jne HFail
    cmp byte ptr [esi+1], 'x'
    jne HFail
Found0x:
    add esi, 2
    mov ecx, 8      
HLoop:
    mov al, [esi]
    call CharToHex
    cmp eax, -1
    je HFail
    shl al, 4
    mov bl, al
    inc esi
    mov al, [esi]
    call CharToHex
    cmp eax, -1
    je HFail
    or bl, al
    mov [edi], bl
    inc esi
    inc edi
    dec ecx
    jnz HLoop
    cmp byte ptr [esi], 0
    jne HFail
    mov eax, 1
    jmp HEnd
HFail:
    mov eax, 0
HEnd:
    pop ecx
    pop ebx
    pop edi
    pop esi
    mov esp, ebp
    pop ebp
    ret 8
ExtractHexKey ENDP

CharToHex PROC
    push ebp
    mov ebp, esp
    movzx eax, al
    cmp al, '0'
    jb HexInvalid
    cmp al, '9'
    jbe L_IsDigit
    and al, 11011111b
    cmp al, 'A'
    jb HexInvalid
    cmp al, 'F'
    ja HexInvalid
    sub eax, 'A'-10
    jmp HexDone
L_IsDigit:
    sub eax, '0'
    jmp HexDone
HexInvalid:
    mov eax, -1
HexDone:
    pop ebp
    ret
CharToHex ENDP

END main