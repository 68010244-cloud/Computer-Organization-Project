โครงงาน Command-Line Shell & File Encryption Engine (Classical DES)
รายวิชา 01476105 Computer Organization and Assembly Language
Computer Engineering and Cyber Security, KMITL


1. สมาชิกในกลุ่ม

1) รหัสนักศึกษา: 68010608
   ชื่อ-นามสกุล: นิธิมา สุเนตร
   ความรับผิดชอบ: พัฒนาโค้ด module_a_FSM และ module_b_keygen

2) รหัสนักศึกษา: 68010244
   ชื่อ-นามสกุล: ชาลิสา เทพยาน
   ความรับผิดชอบ: พัฒนาโค้ด module_c_DES

3) รหัสนักศึกษา: 68010993
   ชื่อ-นามสกุล: วรัณญา บุญทอย
   ความรับผิดชอบ: พัฒนาโค้ด module_d_dumper


2. รายละเอียดโครงงาน

โครงงานนี้เป็นโปรแกรม Command-Line Shell สำหรับเข้ารหัสและถอดรหัสไฟล์ด้วย
Data Encryption Standard (DES) พัฒนาด้วยภาษา x86 Assembly แบบ 32-bit
Protected Mode โดยใช้ MASM และ Irvine32 Library สำหรับการรับ/แสดงผลและ
การจัดการไฟล์บางส่วน

ตัวโปรแกรมทำงานแบบ REPL (Read-Evaluate-Print Loop) โดยรับคำสั่งจากผู้ใช้
ตรวจสอบชื่อคำสั่งและแยก argument ที่จำเป็น ก่อนวนกลับมารับคำสั่งใหม่
จนกว่าผู้ใช้จะใช้คำสั่ง EXIT

ส่วนการเข้ารหัส DES ถูกพัฒนาด้วย x86 Assembly ภายในโครงงาน โดยไม่ใช้
External Encryption Library ในการคำนวณ Key Schedule หรือ DES Cipher


3. คำสั่งที่รองรับ

1) KEYGEN
   รูปแบบ:
      KEYGEN 0x133457799BBCDFF1

   รับ DES key ขนาด 64 bits และสร้าง Key Schedule จำนวน 16 Subkeys
   (K01-K16) สำหรับใช้ในการเข้ารหัสและถอดรหัส


2) ENCRYPT
   รูปแบบ:
      ENCRYPT "secret.txt" 0x133457799BBCDFF1

   อ่านข้อมูลจากไฟล์ plaintext เข้ารหัสด้วย DES ในโหมด ECB
   พร้อม PKCS#7 Padding และสร้างไฟล์ผลลัพธ์โดยต่อท้ายชื่อไฟล์ด้วย .enc


3) DECRYPT
   รูปแบบ:
      DECRYPT "secret.txt.enc" 0x133457799BBCDFF1

   อ่าน ciphertext จากไฟล์ ถอดรหัสด้วย DES โดยใช้ Subkeys ในลำดับย้อนกลับ
   ตรวจสอบและนำ PKCS#7 Padding ออก จากนั้นสร้างไฟล์ผลลัพธ์โดยต่อท้าย .dec


4) DUMP
   รูปแบบ:
      DUMP "secret.txt"

   แสดงข้อมูลของไฟล์ครั้งละ 16 bytes ต่อบรรทัด โดยแสดง Offset,
   ค่า Hexadecimal และ ASCII หากเป็นอักขระที่ไม่สามารถพิมพ์ได้
   (ค่าต่ำกว่า 20h หรือสูงกว่า 7Eh) จะแสดงเป็นจุด (.)


5) STATS
   รูปแบบ:
      STATS "secret.txt"

   แสดงขนาดไฟล์ คำนวณความถี่ของ byte pattern ด้วย Histogram จำนวน
   256 bins และแสดง byte ที่มีความถี่สูงสุด 5 อันดับแรก


6) CLEAR
   รูปแบบ:
      CLEAR

   ล้างหน้าจอและกลับไปรอรับคำสั่งถัดไป


7) EXIT
   รูปแบบ:
      EXIT

   จบการทำงานของโปรแกรม


8) TXT2BIN (Text-to-Binary Utility)
   รูปแบบ:
      TXT2BIN "secret.txt"

   เป็นคำสั่ง Utility สำหรับเตรียมไฟล์ทดสอบที่เก็บข้อมูลในรูปแบบ
   ตัวอักษรเลขฐานสิบหก (Hexadecimal Text) ให้เป็นข้อมูลไบนารีจริง
   (Raw Binary Bytes) ก่อนนำไปใช้กับคำสั่ง ENCRYPT

   โปรแกรมจะอ่านตัวอักษรเลขฐานสิบหกจากไฟล์ข้อความ โดยละเว้นช่องว่าง
   และอักขระขึ้นบรรทัดใหม่ จากนั้นจะแปลงตัวอักษรเลขฐานสิบหกทุก 2 ตัว
   ให้เป็นข้อมูลขนาด 1 byte และบันทึกผลลัพธ์ลงในไฟล์ใหม่โดยต่อท้าย
   ชื่อไฟล์ด้วย .bin

   ตัวอย่าง:
   หากไฟล์ secret.txt มีข้อมูล:

      0123456789ABCDEF

   เมื่อใช้คำสั่ง:

      TXT2BIN "secret.txt"

   โปรแกรมจะสร้างไฟล์:

      secret.txt.bin

   โดยภายในไฟล์จะประกอบด้วย Raw Binary Bytes จำนวน 8 bytes:

      01 23 45 67 89 AB CD EF

   ไฟล์ .bin ที่ได้สามารถนำไปใช้เป็น Plaintext สำหรับทดสอบ DES
   Test Vector ด้วยคำสั่ง ENCRYPT ได้อย่างถูกต้อง


4. โครงสร้างโปรแกรม

Module A: module_a_FSM.asm

- เป็น Shell Core และ Command Parser
- ทำ REPL สำหรับรับคำสั่งจาก Console
- รองรับคำสั่ง KEYGEN, ENCRYPT, DECRYPT, DUMP, STATS, CLEAR,
  EXIT และ TXT2BIN
- ตรวจสอบชื่อคำสั่งและแยก argument ที่จำเป็น เช่น ชื่อไฟล์
  ในเครื่องหมายคำพูดและ DES key
- แปลง DES key จาก Hexadecimal Text ให้เป็น Raw Key ขนาด 8 bytes
  ก่อนส่งให้ Module B
- รองรับ TXT2BIN สำหรับแปลงข้อมูล Hexadecimal Text ในไฟล์ทดสอบ
  ให้เป็น Raw Binary Bytes
- เรียกใช้งาน Key Schedule, DES ECB, Hex Dump และ Statistics
- จัดการการอ่านและเขียนไฟล์ รวมถึงแสดงข้อความ Error เมื่อเกิดข้อผิดพลาด


Module B: module_b_keygen.asm

- สร้าง DES Key Schedule จำนวน 16 Subkeys
- รับ key ขนาด 64 bits
- ทำ Permuted Choice 1 (PC-1)
- แยกข้อมูลเป็น C และ D ขนาด 28 bits
- ทำ Left Circular Rotation ของ C และ D ตามตาราง SHIFTS ในแต่ละรอบ
- ทำ Permuted Choice 2 (PC-2)
- สร้าง Subkey ขนาด 48 bits จำนวน 16 ค่า


Module C: module_c_DES.asm

- เป็น DES 16-Round Feistel Core Engine
- ทำ Initial Permutation (IP)
- ทำ Feistel Function ประกอบด้วย Expansion, XOR กับ Subkey,
  S-Box Lookup และ P Permutation
- ทำ Feistel Network จำนวน 16 รอบ
- ทำ Inverse/Final Permutation
- Encryption ใช้ Subkeys ตามลำดับ K1 ถึง K16
- Decryption ใช้ Subkeys ตามลำดับย้อนกลับ K16 ถึง K1
- ประมวลผลไฟล์ในโหมด ECB
- รองรับ PKCS#7 Padding และตรวจสอบ Padding ขณะถอดรหัส


Module D: module_d_dumper.asm

- DisplayHexDump แสดงข้อมูล 16 bytes ต่อบรรทัดในรูปแบบ Hex และ ASCII
- แสดง non-printable character เป็นจุด (.)
- ComputeBufferStats สร้าง Histogram สำหรับ byte pattern จำนวน 256 bins
- DisplayHistogram แสดง byte ที่มีความถี่สูงสุด 5 อันดับแรก


5. รูปแบบ DES ที่ใช้

- Block Size: 64 bits (8 bytes)
- Key Input: 64 bits
- Effective DES Key: 56 bits และ parity 8 bits
- Number of Feistel Rounds: 16
- Subkey Size: 48 bits
- Number of Subkeys: 16
- Mode of Operation: ECB (Electronic Codebook)
- Padding: PKCS#7

เมื่อ plaintext มีขนาดหารด้วย 8 ลงตัว จะยังเพิ่ม padding block ขนาด 8 bytes
โดยแต่ละ byte มีค่า 08h ตามหลัก PKCS#7


6. การตรวจสอบ Input และ Error Handling

โปรแกรมตรวจสอบชื่อคำสั่ง แยกชื่อไฟล์ที่อยู่ในเครื่องหมายคำพูด
และค้นหา DES key ที่ขึ้นต้นด้วย 0x ก่อนดำเนินการ

โปรแกรมมีการจัดการข้อผิดพลาดพื้นฐาน 
- ไฟล์มีขนาดใหญ่เกินไป ขนาดสูงสุดที่อนุญาตสำหรับ ENCRYPT คือ 65,528 ไบต์
- การถอดรหัสล้มเหลว คีย์ไม่ถูกต้อง ไฟล์เสียหาย หรือไม่ใช่ข้อความเข้ารหัส DES ที่ถูกต้อง

7. สภาพแวดล้อมและการ Build

Target Architecture:
- x86 Assembly
- 32-bit Protected Mode
- MASM Standard

เครื่องมือ:
- Visual Studio / Visual Studio Build Tools
- MASM
- Irvine32 Library
- Windows SDK

ให้ Build โดยเลือก Platform เป็น Win32 (x86) ไม่ใช่ x64

โปรเจกต์ประกอบด้วยไฟล์หลัก:
- module_a_FSM.asm
- module_b_keygen.asm
- module_c_DES.asm
- module_d_dumper.asm
- Irvine32 library 


8. Test Vector สำหรับตรวจสอบ DES

ใช้ DES Test Vector:

Plaintext (Hexadecimal, 64-bit):
   0123456789ABCDEF

Key (Hexadecimal, 64-bit):
   133457799BBCDFF1

Expected Ciphertext (Hexadecimal, 64-bit):
   85E813540F0AB405


ค่า Plaintext ที่แสดงด้านบนเป็นข้อมูลเลขฐานสิบหกขนาด 64 bits
ซึ่งหมายถึง Raw Binary Bytes จำนวน 8 bytes ดังนี้:

   01 23 45 67 89 AB CD EF

ไม่ได้หมายถึง ASCII String "0123456789ABCDEF" ซึ่งมีขนาด 16 bytes


การเตรียมไฟล์สำหรับทดสอบ

สร้างไฟล์ secret.txt ที่มีข้อมูล:

   0123456789ABCDEF

จากนั้นใช้คำสั่ง:

   TXT2BIN "secret.txt"

โปรแกรมจะสร้าง:

   secret.txt.bin

ซึ่งมี Raw Binary Bytes:

   01 23 45 67 89 AB CD EF


จากนั้นทดสอบ DES ด้วย:

   ENCRYPT "secret.txt.bin" 0x133457799BBCDFF1

Ciphertext Block แรกที่ได้:

   85 E8 13 54 0F 0A B4 05

ซึ่งตรงกับ Expected DES Test Vector:

   85E813540F0AB405


จากการทดสอบโปรแกรม ได้ Ciphertext ทั้งไฟล์เป็น:

   85 E8 13 54 0F 0A B4 05 FD F2 E1 74 49 29 22 F8

Ciphertext มีขนาด 16 bytes เนื่องจาก plaintext เดิมมีขนาด 8 bytes
ซึ่งหารด้วย DES Block Size ลงตัว จึงมีการเพิ่ม PKCS#7 Padding
อีกหนึ่ง Block:

   08 08 08 08 08 08 08 08


เมื่อทดสอบการถอดรหัสด้วย:

   DECRYPT "secret.txt.bin.enc" 0x133457799BBCDFF1

โปรแกรมสร้างไฟล์:

   secret.txt.bin.enc.dec

เมื่อใช้:

   DUMP "secret.txt.bin.enc.dec"

ได้ผลลัพธ์:

   01 23 45 67 89 AB CD EF

ซึ่งตรงกับ Plaintext ก่อนการเข้ารหัส


ดังนั้น Test Vector นี้ใช้ตรวจสอบการทำงานร่วมกันของ
Key Schedule, DES Encryption, DES Decryption, ECB Mode
และ PKCS#7 Padding/Unpadding


9. ตัวอย่างการใช้งาน

เริ่มโปรแกรม:

   .\Debug\DES_project.exe


เตรียม Test Vector:

   DES-SHELL> TXT2BIN "secret.txt"


ตรวจสอบ Raw Binary:

   DES-SHELL> DUMP "secret.txt.bin"


สร้าง DES Key Schedule:

   DES-SHELL> KEYGEN 0x133457799BBCDFF1


เข้ารหัส:

   DES-SHELL> ENCRYPT "secret.txt.bin" 0x133457799BBCDFF1


ตรวจสอบ Ciphertext:

   DES-SHELL> DUMP "secret.txt.bin.enc"


ผลลัพธ์:

   85 E8 13 54 0F 0A B4 05 FD F2 E1 74 49 29 22 F8


ตรวจสอบสถิติของ Ciphertext:

   DES-SHELL> STATS "secret.txt.bin.enc"


ตัวอย่างผลลัพธ์:

   Total File Size: 16 Bytes
   Top Byte Occurrences:
   1. [0x85] : 1 occurrences [*]
   2. [0xE8] : 1 occurrences [*]
   3. [0x13] : 1 occurrences [*]
   4. [0x54] : 1 occurrences [*]
   5. [0x0F] : 1 occurrences [*]


ถอดรหัส:

   DES-SHELL> DECRYPT "secret.txt.bin.enc" 0x133457799BBCDFF1


ตรวจสอบ Plaintext หลังถอดรหัส:

   DES-SHELL> DUMP "secret.txt.bin.enc.dec"


ผลลัพธ์:

   01 23 45 67 89 AB CD EF


ออกจากโปรแกรม:

   DES-SHELL> EXIT
