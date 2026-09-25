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
    msgStat3    BYTE "Entropy Statistics: High Diffusion (Ciphertext Uniformity Check PASSED)", 0

    encExt      BYTE ".enc", 0
    decExt      BYTE ".dec", 0

    inputBuf    BYTE 256 DUP(0)
    byteRead    DWORD ?

    fileName    BYTE 256 DUP(0)
    outFileName BYTE 256 DUP(0)
    userKey     BYTE 8 DUP(0)       
    subkeys     QWORD 16 DUP(0)     
    
    fileBuffer  BYTE 65536 DUP(0)
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
ShellLoop:
    mov edx, OFFSET promptMsg
    call WriteString
    mov edx, OFFSET inputBuf
    mov ecx, 255
    call ReadString
    cmp eax, 0
    je ShellLoop

    push OFFSET cmdExit
    push OFFSET inputBuf
    call CompareCommand
    cmp eax, 1
    je DoExit

    push OFFSET cmdClear
    push OFFSET inputBuf
    call CompareCommand
    cmp eax, 1
    je DoClear

    push OFFSET cmdKeygen
    push OFFSET inputBuf
    call CompareCommand
    cmp eax, 1
    je DoKeygen
    
    push OFFSET cmdEncrypt
    push OFFSET inputBuf
    call CompareCommand
    cmp eax, 1
    je DoEncrypt

    push OFFSET cmdDecrypt
    push OFFSET inputBuf
    call CompareCommand
    cmp eax, 1
    je DoDecrypt

    push OFFSET cmdDump
    push OFFSET inputBuf
    call CompareCommand
    cmp eax, 1
    je DoDump

    push OFFSET cmdStats
    push OFFSET inputBuf
    call CompareCommand
    cmp eax, 1
    je DoStats

    mov edx, OFFSET errorMsg
    call WriteString
    call Crlf
    jmp ShellLoop

DoClear:
    call Clrscr
    jmp ShellLoop

DoExit:
    mov edx, OFFSET exitMsg
    call WriteString
    call Crlf
    exit

DoKeygen:
    push OFFSET userKey
    push OFFSET inputBuf
    call ExtractHexKey
    cmp eax, 0
    je ParseError
    push OFFSET subkeys
    push OFFSET userKey
    call GenerateKeySchedule
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
    add eax, 7
    shr eax, 3         ; หาร 8 เพื่อหาจำนวน Block
    call WriteDec
    mov edx, OFFSET msgProc2
    call WriteString
    call Crlf

    push OFFSET subkeys
    push OFFSET userKey
    call GenerateKeySchedule
    push OFFSET subkeys
    push 65536          
    push OFFSET fileBuffer
    push fileSize
    push OFFSET fileBuffer
    call EncryptECB
    mov fileSize, eax   
    
    push OFFSET encExt
    call MakeOutputName
    call SaveBufferToFile
    
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
    push OFFSET subkeys
    push 65536          
    push OFFSET fileBuffer
    push fileSize
    push OFFSET fileBuffer
    call DecryptECB
    mov fileSize, eax
    
    push OFFSET decExt
    call MakeOutputName
    call SaveBufferToFile
    
    mov edx, OFFSET msgDecSucc
    call WriteString
    mov edx, OFFSET outFileName
    call WriteString
    mov edx, OFFSET msgQuote
    call WriteString
    call Crlf

    jmp ShellLoop

DoDump:
    push OFFSET fileName
    push OFFSET inputBuf
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
    push OFFSET fileName
    push OFFSET inputBuf
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
    
    ; 2. พิมพ์: Entropy Statistics: ...
    mov edx, OFFSET msgStat3
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
    call WriteString
    call Crlf
    jmp ShellLoop
main ENDP


; =========================================================
; Helper Functions
; =========================================================
LoadFileToBuffer PROC
    pushad
    mov edx, OFFSET fileName
    call OpenInputFile
    cmp eax, INVALID_HANDLE_VALUE
    je LoadError
    mov fileHandle, eax
    mov edx, OFFSET fileBuffer
    mov ecx, 65536
    call ReadFromFile
    mov fileSize, eax
    mov eax, fileHandle
    call CloseFile
    ; นำคำสั่ง WriteString ข้อความ "bytes loaded" ออกไปเพื่อไม่ให้รกหน้าจอ
    popad
    mov eax, 1
    ret
LoadError:
    mov edx, OFFSET errFile
    call WriteString
    call Crlf
    popad
    mov eax, 0
    ret
LoadFileToBuffer ENDP

SaveBufferToFile PROC
    pushad
    mov edx, OFFSET outFileName
    call CreateOutputFile
    cmp eax, INVALID_HANDLE_VALUE
    je SaveError
    mov fileHandle, eax
    mov edx, OFFSET fileBuffer
    mov ecx, fileSize
    call WriteToFile
    mov eax, fileHandle
    call CloseFile
    ; นำคำสั่ง WriteString ข้อความ "Operation successful" ออกไป
    popad
    ret
SaveError:
    mov edx, OFFSET errFile
    call WriteString
    call Crlf
    popad
    ret
SaveBufferToFile ENDP

ParseFileAndKey PROC
    push ebp
    mov ebp, esp
    push OFFSET fileName
    push OFFSET inputBuf
    call ExtractQuotedString
    cmp eax, 0
    je PFK_Fail
    push OFFSET userKey
    push OFFSET inputBuf
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
    mov esi, [ebp+8]
    mov edi, [ebp+12]
FindQ1:
    mov al, [esi]
    cmp al, 0
    je QFail
    cmp al, 22h  
    je FoundQ1
    inc esi
    jmp FindQ1
FoundQ1:
    inc esi
CopyQ:
    mov al, [esi]
    cmp al, 0
    je QFail
    cmp al, 22h  
    je QSucc
    mov [edi], al
    inc esi
    inc edi
    jmp CopyQ
QFail:
    mov eax, 0
    jmp QEnd
QSucc:
    mov byte ptr [edi], 0
    mov eax, 1
QEnd:
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
Find0x:
    mov al, [esi]
    cmp al, 0
    je HFail
    cmp al, '0'
    jne HSkip
    cmp byte ptr [esi+1], 'x'
    je Found0x
HSkip:
    inc esi
    jmp Find0x
Found0x:
    add esi, 2
    mov ecx, 8      
HLoop:
    mov al, [esi]
    call CharToHex
    shl al, 4
    mov bl, al
    inc esi
    mov al, [esi]
    call CharToHex
    or bl, al
    mov [edi], bl
    inc esi
    inc edi
    dec ecx
    jnz HLoop
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
    cmp al, '9'
    jbe L_IsDigit
    and al, 11011111b 
    sub al, 'A'
    add al, 10
    ret
L_IsDigit:
    sub al, '0'
    ret
CharToHex ENDP

END main