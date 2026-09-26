โครงงาน Command-Line Shell & File Encryption Engine (Classical DES)
รายวิชา 01476105 Computer Organization and Assembly Language
Computer Engineering and Cyber Security, KMITL


สมาชิกในกลุ่ม
1) รหัสนักศึกษา: 68010608
   ชื่อ-นามสกุล: นิธิมา สุเนตร
   ความรับผิดชอบ:พัฒนาโค้ด module_a_FSM และ module_b_keygen

2) รหัสนักศึกษา: 68010244
   ชื่อ-นามสกุล: ชาลิสา เทพยาน
   ความรับผิดชอบ:พัฒนาโค้ด module_b_keygen

3) รหัสนักศึกษา: 68010993
   ชื่อ-นามสกุล: วรัณญา บุญทอย
   ความรับผิดชอบ:พัฒนาโค้ด module_c_DES
   


2. รายละเอียดโครงงาน

โครงงานนี้เป็นโปรแกรม Command-Line Shell สำหรับเข้ารหัสและถอดรหัสไฟล์ด้วย
Data Encryption Standard (DES) พัฒนาด้วยภาษา x86 Assembly แบบ 32-bit
Protected Mode โดยใช้ MASM และ Irvine32 Library สำหรับการรับ/แสดงผลและ
การจัดการไฟล์บางส่วน

ตัวโปรแกรมทำงานแบบ REPL (Read-Evaluate-Print Loop) โดยรับคำสั่งจากผู้ใช้
วิเคราะห์คำสั่งด้วย Finite State Machine (FSM) และวนกลับมารับคำสั่งใหม่
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

   คำนวณความถี่ของ byte pattern ด้วย Histogram จำนวน 256 bins
   และแสดง byte ที่มีความถี่สูงสุด

6) CLEAR
   รูปแบบ:
      CLEAR

   ล้างหน้าจอและกลับไปรอรับคำสั่งถัดไป

7) EXIT
   รูปแบบ:
      EXIT

   จบการทำงานของโปรแกรม


4. โครงสร้างโปรแกรม
Module A: module_a_FSM.asm
- เป็น Shell Core และ FSM Command Parser
- ทำ REPL สำหรับรับคำสั่งจาก Console
- วิเคราะห์คำสั่ง KEYGEN, ENCRYPT, DECRYPT, DUMP, STATS, CLEAR และ EXIT
- FSM ใช้สถานะสำหรับการอ่านช่องว่าง, token, quoted token, หลังปิด quote,
  จุดสิ้นสุด และ input ที่ไม่ถูกต้อง
- ตรวจสอบจำนวน argument และรูปแบบของคำสั่ง
- ตรวจสอบ DES key ในรูปแบบ 0x ตามด้วยเลขฐาน 16 จำนวน 16 หลัก
- เรียกใช้งาน Key Schedule, DES ECB, Hex Dump และ Statistics
- จัดการการอ่านและเขียนไฟล์ รวมถึงแสดงข้อความ Error เมื่อเกิดข้อผิดพลาด

Module B: module_b_keygen.asm
- สร้าง DES Key Schedule จำนวน 16 Subkeys
- รับ key ขนาด 64 bits
- ทำ Permuted Choice 1 (PC-1)
- แยกข้อมูลเป็น C และ D ขนาด 28 bits
- ทำ Left Circular Rotation ตามจำนวนรอบที่ DES กำหนด
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
- DisplayHistogram แสดง byte ที่มีความถี่สูงสุด


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

โปรแกรมตรวจสอบรูปแบบคำสั่งและจำนวน argument ก่อนดำเนินการ รวมถึงตรวจสอบ
DES key ให้มี prefix 0x และมีเลขฐาน 16 จำนวน 16 หลัก โดยรองรับ A-F
ทั้งตัวพิมพ์ใหญ่และตัวพิมพ์เล็ก

โปรแกรมมีการตรวจสอบข้อผิดพลาด เช่น
- คำสั่งหรือรูปแบบคำสั่งไม่ถูกต้อง
- Key ไม่อยู่ในรูปแบบที่กำหนด
- ไม่สามารถเปิดหรือสร้างไฟล์ได้
- การอ่านหรือเขียนไฟล์ล้มเหลว
- ไฟล์มีขนาดเกิน Buffer ที่กำหนด
- Ciphertext หรือ PKCS#7 Padding ไม่ถูกต้อง

ขนาด File Buffer ที่ใช้ในโปรแกรมรองรับข้อมูลสูงสุด 65,536 bytes
และจะปฏิเสธไฟล์ที่มีขนาดเกินขอบเขตแทนการตัดข้อมูลทิ้ง


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
- DES_project.vcxproj
- Irvine32.inc
- Irvine32.lib
- SmallWin.inc
- VirtualKeys.inc


8. Test Vector สำหรับตรวจสอบ DES

ใช้ Test Vector ตามที่กำหนดใน Assignment:

Plaintext:
   0123456789ABCDEF

Key:
   133457799BBCDFF1

Expected Ciphertext:
   85E813540F0AB405

ใช้ Test Vector นี้เพื่อตรวจสอบความถูกต้องของการสร้าง Key Schedule
และกระบวนการ Encryption/Decryption ของ DES


9. ตัวอย่างการใช้งาน

DES-SHELL> KEYGEN 0x133457799BBCDFF1

DES-SHELL> DUMP "secret.txt"

DES-SHELL> ENCRYPT "secret.txt" 0x133457799BBCDFF1

DES-SHELL> DUMP "secret.txt.enc"

DES-SHELL> STATS "secret.txt.enc"

DES-SHELL> DECRYPT "secret.txt.enc" 0x133457799BBCDFF1

DES-SHELL> EXIT

