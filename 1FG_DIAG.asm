	Trampolin EQU F600h
	L0099 EQU 060Ah
	L0103 EQU 05ECh
	L0109 EQU 060Dh
	L0029 EQU 02A6h

	JP Zacetek

UkaznaVrstica:  LD SP,0FFC0H
	CALL PrelomVrstice
	LD A,2AH ; '*'
	CALL GDPUkaz
	CALL BeriInIzpisiZnak
	AND 0DFH ; Pretvori v uppercase
	CP 52H ; 'R'
	JP Z,FDBootSkok
	CP 46H ; 'F'
	JP Z,FDBootSkok
NeznanUkaz:  LD A,3FH ; '?'
	CALL GDPUkaz
	JR UkaznaVrstica

;;; PROSTOR ;;;

CpStr:
	PUSH AF
	LD A,23H ; '#'
	CALL GDPUkaz
	POP AF
	RET
Cp1:
	CALL CpStr
	LD I,A
	EI
	RET
Cp2:
	CALL CpStr
	CALL L0051
	RET

;;; KONEC PROSTORA ;;;

	ORG $66

; Nerabljen skok.

	JP NeznanUkaz

; Nerabljene procedure za izpis sxestnajstisxkih sxtevil.

	CALL PrelomVrstice
	LD A,H
	CALL IzpisiHex8
	LD A,L
	CALL IzpisiHex8
	LD A,20H
	JP GDPUkaz
IzpisiHex8:  PUSH BC
	LD B,A
	SRA A
	SRA A
	SRA A
	SRA A
	AND 0FH
	CALL IzpisiHex4
	LD A,B
	AND 0FH
	CALL IzpisiHex4
	POP BC
	RET
IzpisiHex4:  CP 0AH
	JP M,L0010
	ADD A,37H
	JR L0011
L0010:  ADD A,30H
L0011:  CALL GDPUkaz
	RET

; Pocxaka, da uporabnik pritisne tipko na tipkovnici,
; nato izpisxe njen znak na GDP.

BeriInIzpisiZnak:  IN A,(0D9H)
	BIT 0,A
	JR Z,BeriInIzpisiZnak
	IN A,(0D8H)
	RES 7,A

; Posxlje ukaz na GDP.

GDPUkaz:  CALL CakajGDP
	OUT (20H),A
	RET

; Pocxaka, da GDP koncxa izvajanje morebitnega ukaza.

CakajGDP:  PUSH AF
L0013:  IN A,(20H)
	AND 04H
	JR Z,L0013
	POP AF
	RET

; Nerabljena procedura, ki izpisxe presledek na GDP.

	LD A,20H
	JR GDPUkaz

; Izvede prelom vrstice.
; Pomaknemo vsebino zaslona 12 pikslov navzgor.

PrelomVrstice:  CALL CakajGDP
	LD A,(0FFEBH)
	SUB 0CH
	LD (0FFEBH),A
	OUT (36H),A
	PUSH HL
; Izbrisxemo novo vrstico.
	LD HL,00DBH
	CALL IzpisiNiz
; Premaknemo pero na levo.
	LD HL,00F0H
	CALL IzpisiNiz
	POP HL
; Izberemo nacxin risanja.
	XOR A
	JP GDPUkaz

; Niz ukazov za GDP, ki premakne pero v spodnji levi kot in pobrisxe vrstico.
	DB $03, $00, $05, $01, $0B, $0B, $0B, $0B
	DB $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B
	DB $0B, $0B, $0B, $0B, $00

; Niz ukazov za GDP, ki premakne pero na skrajno levo.
	DB $21, $00, $0D, $00

; Vstopna tocxka v memory test.

MemoryTest:  LD HL,0288H
	CALL IzpisiPrelomInNiz
	LD HL,2000H
	LD BC,0FF80H
	LD D,02H
	LD A,00H
L0017:  PUSH DE
	PUSH AF
	CALL L0016
	POP AF
	POP DE
	ADD A,55H
	DEC D
	JR NZ,L0017
	RET

; ----------------------------------------

L0016:  CALL L0018
	OUT (90H),A
	CALL L0018
	CALL L0019
	OUT (88H),A
	CALL L0019
	RET

; ----------------------------------------

L0018:  PUSH AF
	PUSH HL
	LD D,A
	CPL
	LD E,A
L0020:  LD (HL),D
	INC HL
	LD (HL),E
	INC HL
	PUSH HL
	OR A
	SBC HL,BC
	POP HL
	JR C,L0020
	POP HL
	POP AF
	RET

; ----------------------------------------

L0019:  PUSH HL
	PUSH AF
	LD D,A
	CPL
	LD E,A
L0022:  LD A,(HL)
	CP D
	JR NZ,L0021
	INC HL
	LD A,(HL)
	CP E
	JR NZ,L0021
	INC HL
	PUSH HL
	OR A
	SBC HL,BC
	POP HL
	JR C,L0022
	POP AF
	POP HL
	RET

; ----------------------------------------

L0021:  LD HL,0157H
	CALL IzpisiPrelomInNiz
	JP UkaznaVrstica

; ----------------------------------------

	DB $21, $00
	DB "MEMORY ERROR !!!"
	DB $0

; ----------------------------------------

; Zacxetek

Zacetek:  LD SP,0FFC0H

; Inicializacija PIO

	LD A,07H
	OUT (31H),A
	OUT (33H),A
	LD A,0FH
	OUT (31H),A
	OUT (33H),A
	LD A,18H
	OUT (30H),A
	LD A,6DH
	OUT (32H),A
	XOR A
	OUT (39H),A
	OUT (36H),A
	LD (0FFEBH),A

; (odvecx)

	XOR A
	OUT (21H),A

; Izbira in spust GDP peresa

	LD A,03H
	OUT (21H),A

	LD A,04H ; Pocxistimo GDP sliko...
	CALL GDPUkaz
	LD A,05H ; ... in postavimo pero na levi rob.
	CALL GDPUkaz

	XOR A
	OUT (39H),A
	OUT (30H),A

	CALL AVDCInit1
	CALL AVDCInit2

; Inicializacija SIO "CRT" kanala (za tipkovnico)

	LD C,0D9H
	LD HL,026DH
	LD B,07H
	OTIR

; Inicializacija SIO "LPT" kanala

	LD C,0DBH
	LD HL,026DH
	LD B,07H
	OTIR

; Inicializacija SIO "VAX" kanala

	LD C,0E1H
	LD HL,026DH
	LD B,07H
	OTIR

	LD SP,0FFC0H

; Y koordinata GDP peresa := 100
	LD A,64H
	OUT (2BH),A

	LD HL,0274H
	CALL IzpisiPrelomInNiz

; Spet postavimo pero na levi rob.
	LD A,05H
	CALL GDPUkaz

	LD HL,01E4H
	CALL IzpisiPrelomInNiz

	CALL MemoryTest

	CALL FDCInit

	CALL L0029 ; Poklicxe prazno rutino

	JP FDBootSkok

	DB $21, $00
	DB "[ Boot V 1.0 - 1F ]"
	DB $0

IzpisiPrelomInNiz:  CALL PrelomVrstice
; (se nadaljuje v IzpisiNiz)

; Izpisxe niz na GDP.
; Prvi bajt niza se zapisxe v GDP-jev register za velikost znakov,
; drugi pa v kontrolni register 2. V praksi je drugi bajt vedno 0,
; lahko bi pa bil 4 za lezxecxe besedilo.

; Vhod:
; HL -> niz, zakljucxen z 0

; Unicxi A.

IzpisiNiz:  CALL CakajGDP
	LD A,(HL)
	OUT (23H),A
	INC HL
	LD A,(HL)
	OUT (22H),A
	INC HL
L0035:  LD A,(HL)
	OR A
	RET Z
	CALL GDPUkaz
	INC HL
	JR L0035

; ----------------------------------------

Zakasnitev:  PUSH BC
	LD B,0FFH
L0036:  NOP
	DJNZ L0036
	POP BC
	RET

; ----------------------------------------

AVDCInit1:  LD A,00H
	OUT (39H),A
	CALL Zakasnitev
	CALL Zakasnitev
	CALL Zakasnitev
	LD HL,0263H
	XOR A

; SS1 := 0
	OUT (3EH),A
	OUT (3FH),A

; SS2 := 0
	OUT (3AH),A
	OUT (3BH),A

	LD A,10H
	OUT (39H),A
	LD B,0AH
	LD C,38H
	OTIR

	RET

; Vkljucxi AVDC kurzor in ???

AVDCInit2:  LD A,3DH
	OUT (39H),A

; Naslov AVDC kurzorja := 0
	XOR A
	OUT (3DH),A
L0031:  OUT (3CH),A

	LD HL,1FFFH
	CALL AVDCNastaviDispAddr

; Zapolni AVDC framebuffer s presledki?
	LD A,20H
	OUT (34H),A
	XOR A
	OUT (35H),A
	LD A,0BBH ; Write from cursor to pointer
	OUT (39H),A
	RET

; Nastavi AVDC inicializacijska registra 10 in 11
; (display address register lower/upper).

; Vhod:
; HL = novi display address

; Unicxi A.

AVDCNastaviDispAddr:  LD A,1AH
	OUT (39H),A
	LD A,L
	OUT (38H),A
	LD A,H
	OUT (38H),A
	RET

; Inicializacijski niz za AVDC.
	DB $D0, $2F, $0D, $05, $99, $4F, $0A, $EA
	DB $00, $30

; Inicializacijski niz za serijska vrata.
	DB $18, $04, $44, $03, $C1, $05, $68

; Zagonsko sporocxilo.
	DB $A8, $00
	DB "Delta Partner GDP"
	DB $0

; Sporocxilo o testiranju spomina.
	DB $21, $00
	DB "TESTING MEMORY ... "
	DB $0

	DB $00, $00

	; IVT, ki kazxe tudi na FDC handler na 4CA???
	DB $82, $04, $8E, $05, $DC, $04

	RET

	DB $00, $00

; Nerabljeni skoki.

	JP L0047
	JP HDBoot
	JP L0049

; FDBootSkok

FDBootSkok:  JP FDBoot

; FDCInit

FDCInit:  DI
	IM 2
	LD HL,02A0H
	LD A,L
	OUT (0E8H),A
	OUT (0C8H),A
	LD A,H
	;LD I,A
	;EI
	CALL Cp1 ; CHECKPOINT
	HALT
	LD A,08H
	;CALL L0051
	CALL Cp2 ; CHECKPOINT
	CALL L0052
	CALL L0052
	LD A,03H
	CALL L0051
	LD A,0DH
	AND 0FH
	RLCA
	RLCA
	RLCA
	RLCA
	LD B,A
	LD A,0EH
L0043:  AND 0FH
	OR B
	CALL L0051
	LD A,04H
	RLCA
	AND 0FEH
	;CALL L0051
	CALL Cp2 ; CHECKPOINT
	RET

; ----------------------------------------

L0051:  PUSH AF
L0053:  IN A,(0F0H)
	AND 0C0H
	CP 80H
	JP NZ,L0053
	POP AF
	OUT (0F1H),A
	RET

; ----------------------------------------

L0052:  IN A,(0F0H)
	AND 0C0H
	CP 0C0H
	JP NZ,L0052
	IN A,(0F1H)
	RET

; ----------------------------------------

L0068:  LD A,07H
	CALL L0051
	LD A,(0FFD0H)
	CALL L0051
	EI
	HALT
	LD A,08H
	CALL L0051
	CALL L0052
	CALL L0052
	XOR A
	LD (0FFD1H),A
	LD (0FFD7H),A
	RET

; ----------------------------------------

L0069:  CALL L0054
	RET NZ
	LD A,0AH
	LD (0FFD5H),A
L0062:  LD A,05H
	OUT (0C0H),A
	LD A,0CFH
	OUT (0C0H),A
	CALL L0055
	LD HL,0426H
	OTIR
	LD A,06H
	OR 40H
	CALL L0056
	CALL L0057
L0059:  EI
	HALT
	JP C,L0058
	IN A,(98H)
	AND 01H
	JP NZ,L0059
	LD HL,04E1H
	CALL IzpisiPrelomInNiz
	OUT (98H),A
	JP L0059
L0058:  LD A,03H
	OUT (0CAH),A
	CALL L0052
	CALL L0052
	PUSH AF
	LD B,05H
L0060:  CALL L0052
	DEC B
	JP NZ,L0060
	POP AF
	CP 80H
	RET Z
	LD A,(0FFD5H)
	OR A
	JP Z,L0061
	DEC A
	LD (0FFD5H),A
	LD A,(0FFD1H)
	PUSH AF
	INC A
	LD (0FFD1H),A
	LD A,(0FFD7H)
	PUSH AF
	CALL L0054
	POP AF
	LD (0FFD7H),A
	POP AF
	LD (0FFD1H),A
	CALL L0054
	JP L0062
L0061:  INC A
	RET

; ----------------------------------------

L0054:  CALL L0063
	LD A,0FH
	CALL L0051
	CALL L0064
L0066:  CALL L0051
	LD A,(0FFD1H)
	CALL L0051
	EI
	HALT
L0067:  LD A,08H
	CALL L0051
	CALL L0052
	CALL L0052
	LD B,A
	LD A,(0FFD1H)
	CP B
	JP Z,L0065
	XOR A
	INC A
	RET
L0065:  XOR A
	RET

; ----------------------------------------

L0064:  LD A,(0FFD7H)
	RLCA
	RLCA
	AND 04H
	PUSH BC
	LD B,A
	LD A,(0FFD0H)
	OR B
	POP BC
	RET

; ----------------------------------------

L0056:  CALL L0051
	CALL L0064
	CALL L0051
	LD A,(0FFD1H)
	CALL L0051
	LD A,(0FFD7H)
	CALL L0051
	LD A,(0FFD4H)
	CALL L0051
	RET

; ----------------------------------------

L0057:  LD A,01H
	CALL L0051
	LD A,(0FFD4H)
	CALL L0051
	LD A,0AH
	CALL L0051
	LD A,0FFH
	CALL L0051
	RET

; ----------------------------------------

L0055:  LD A,79H
	OUT (0C0H),A
	LD HL,(0FFD2H)
	LD A,L
	OUT (0C0H),A
	LD A,H
	OUT (0C0H),A
	LD B,0BH
	LD C,0C0H
	RET

; Init string za FDC???
	DB $FF, $00, $14, $28, $85, $F1, $8A, $CF
	DB $01, $CF, $87, $FF, $00, $14, $28, $85
	DB $F1, $8A, $CF, $05, $CF, $87

; FDNaloziCPMLDR

FDNaloziCPMLDR:  LD A,13H
	LD (0FFD8H),A
	XOR A
	LD (0FFD0H),A
	CALL L0068
	LD HL,0E000H
	LD (0FFD2H),HL
L0072:  XOR A
	INC A
	LD (0FFD4H),A
L0071:  CALL L0069
	JP NZ,L0070
	LD DE,0100H
	LD HL,(0FFD2H)
	ADD HL,DE
	LD (0FFD2H),HL
	LD A,(0FFD4H)
	INC A
	LD (0FFD4H),A
	LD HL,0FFD8H
	CP (HL)
	JP NZ,L0071
	LD A,(0FFD7H)
	OR A
	RET NZ
	INC A
	LD (0FFD7H),A
	LD A,0EH
	LD (0FFD8H),A
	JP L0072

; FDCIntHandler

	EI
	SCF
	RETI

; Sem skocxi procedura na 02A9, ki ni nikoli klicana, torej tudi
; to ni nikoli klicano.

L0047:  CALL FDNaloziCPMLDR
	JP UkaznaVrstica

; FDBoot

FDBoot:  CALL FDNaloziCPMLDR
	LD A,(0E000H) ; Prvi bajt prvega sektorja...
	CP 0C3H ; ... mora biti opcode za brezpogojni JP...
	JP Z,L0074
	CP 31H ; ... ali LD SP, nn
	JP Z,L0074
	LD HL,054BH
	JP Napaka

; Nalagalnik OSa je nalozxen; skocximo vanj
L0074:  JP Trampolin ; JP F600H

; ----------------------------------------

L0079:  IN A,(98H)
	AND 01H
	RET

; ----------------------------------------

L0081:  LD A,0FFH
	PUSH BC
L0078:  LD B,0FFH
L0077:  DEC B
	JP NZ,L0077
	DEC A
	JP NZ,L0078
	POP BC
	RET

; ----------------------------------------

L0063:  CALL L0079
	JP NZ,L0080
	OUT (98H),A
	CALL L0081
L0080:  XOR A
	OUT (98H),A
	LD A,47H
	OUT (0C8H),A
	OUT (0C9H),A
	LD A,82H
	OUT (0C8H),A
	OUT (0C9H),A
	LD A,0A7H
	OUT (0CAH),A
	LD A,0FFH
	OUT (0CAH),A
	RET

; NeznanIntHandler

	EI
	SCF
	CCF
	RETI

; Sporocxilo, da disketni pogon ni pripravljen.
	DB $21, $00
	DB "FLOPPY DISK NOT READY !!!!"
	DB $0

; HDBoot

HDBoot:  CALL HDNaloziCPMLDR
	LD A,(0E000H) ; Prvi bajt prvega sektorja...
	CP 31H ; ... mora biti opcode za LD SP, nn
	JP Z,L0087
	LD HL,054BH
	JP Napaka

; Kopiramo ROM na 2000h

L0087:  LD HL,0000H
	LD DE,2000H
	LD BC,0800H
	LDIR

; Kopiramo interrupt handler(?)

	LD HL,071CH
	LD DE,0C000H
	LD BC,006CH
	LDIR

	DI
	LD A,03H
	OUT (0C8H),A
	OUT (0C9H),A
	LD HL,0C000H
L0082:  LD A,H
	LD I,A
	LD A,L
	OUT (0E8H),A
	OUT (0C8H),A
	LD A,47H
	OUT (0C8H),A
	LD A,0FFH
	OUT (0C8H),A
	LD A,0C7H
	OUT (0C9H),A
	LD A,64H
	OUT (0C9H),A
	EI

; Nalagalnik OSa je nalozxen; skocximo vanj

	JP Trampolin

; ----------------------------------------

	DB $21, $00
	DB "NO SYSTEM ON DISK"
	DB $0

; ----------------------------------------
; To ni nikoli klicano (?)

L0049:  CALL HDNaloziCPMLDR
	JP UkaznaVrstica

; ----------------------------------------

L0101:  XOR A
	OUT (12H),A
	DI
	LD A,47H
	OUT (0C8H),A
	LD A,0FFH
	OUT (0C8H),A
	LD A,0C7H
	OUT (0C9H),A
	LD A,50H
	OUT (0C9H),A
	EI
	CALL L0091
L0094:  LD HL,0710H
	CALL L0092
	CALL L0093
	JP NZ,L0094
	LD A,03H
	OUT (0C9H),A
	RET

; ----------------------------------------
; CTCIntHandler

	LD A,03H
	OUT (0C9H),A
	CALL IzvediRETI
	EI
	LD HL,059EH
	JP Napaka

; ----------------------------------------
; IzvediRETI

IzvediRETI:  RETI

; ----------------------------------------
; Sporocxilo, da trdi disk ni pripravljen.
	DB $21, $00
	DB "HARD DISK NOT READY"
	DB $0

; ----------------------------------------

L0091:  LD HL,0702H
	CALL L0099
	CALL L0093
	RET Z
	LD A,34H
	JP L0100

; ----------------------------------------
; HDNaloziCPMLDR

HDNaloziCPMLDR:  CALL L0101
	LD A,0C3H
	OUT (0C0H),A
	LD HL,0716H
	CALL L0092
L0102:  IN A,(10H)
	AND 40H
	JP Z,L0102
	IN A,(10H)
	AND 10H
	JP NZ,L0103
	LD A,22H
	OUT (10H),A
	CALL L0104
L0105:  IN A,(10H)
	AND 10H
	JP Z,L0105
	CALL L0093
	RET Z
	LD A,32H
	JP L0100

; ----------------------------------------

L0092:  CALL L0106
L0108:  CALL L0107
	LD B,A
	AND 10H
	RET Z
	LD A,B
	AND 40H
	RET NZ
	LD A,(HL)
	OUT (11H),A
	INC HL
	JP L0108

; ----------------------------------------

	CALL L0106
	CALL L0107
	AND 40H
	RET NZ
	LD A,(HL)
	OUT (11H),A
	INC HL
L0115:  JP L0109

; ----------------------------------------

L0093:  CALL L0107
	AND 10H
	JP NZ,L0110
	LD A,42H
	JP L0100
L0110:  IN A,(11H)
	LD B,A
	INC HL
	CALL L0107
	IN A,(11H)
	XOR A
	OUT (10H),A
	LD A,B
	AND 03H
	RET

; ----------------------------------------

L0106:  IN A,(10H)
	AND 08H
	JP Z,L0111
	LD A,41H
	JP L0100
L0111:  LD A,01H
	OUT (10H),A
L0112:  IN A,(10H)
	AND 08H
	JP Z,L0112
	LD A,02H
	OUT (10H),A
	RET

; ----------------------------------------

L0107:  IN A,(10H)
	RLA
	JP NC,L0107
	RRA
	RET

; ----------------------------------------

	LD HL,067AH
	JP L0113

; ----------------------------------------

L0104:  LD HL,066BH
L0113:  LD C,0C0H
	LD B,0FH
	OTIR
	RET

; ----------------------------------------
; ??? init string za DMA
	DB $79, $00, $E0, $FF, $1E, $14, $28, $95
	DB $11, $00, $8A, $CF, $01, $CF, $87

; ----------------------------------------
; ??? init string za DMA
	DB $79, $00, $E0, $FF, $1E, $14, $28, $95
	DB $11, $00, $8A, $CF, $05, $CF, $87

; ----------------------------------------

L0070:  LD HL,0698H
	JP Napaka
L0100:  LD HL,06CFH
Napaka:  CALL IzpisiPrelomInNiz
	JP UkaznaVrstica

; ----------------------------------------
; Sporocxilo, da je nekaj narobe z disketnim pogonom.
	DB $21, $00
	DB "FLOPPY DISK MALFUNCTION !!!Retry with command R or F"
	DB $0

; ----------------------------------------
; Sporocxilo, da je nekaj narobe s trdim diskom.
	DB $21, $00
	DB "HARD DISK MALFUNCTION >>> RETRY WITH COMMAND  A "
	DB $0

; ----------------------------------------
; ???

L0129:  INC C
	NOP
	NOP
	NOP
	NOP
	NOP
	LD BC,0432H
	NOP
	ADD A,B
	NOP
	LD B,B
	DEC BC
	LD BC,0000H
	NOP
L0123:  NOP
	NOP
	EX AF,AF'
	NOP
	NOP
	NOP
	RRA
L0121:  NOP

; ----------------------------------------
; IVT z 2 vnosoma za ???, ki kazxeta na rutino spodaj, ko je prekopirana.
; $C004, $C004

	DB $04, $C0, $04, $C0

; ----------------------------------------
; Rutina za ???, ki se prekopira na C000 skupaj z zgornjim IVT.

	DI
	LD A,03H
	OUT (0C8H),A
	OUT (0C9H),A
	OUT (88H),A
L0124:  LD HL,2000H
	LD DE,0000H
	LD BC,0800H
	LDIR
	LD HL,02A0H
	LD A,L
	OUT (0E8H),A
L0122:  OUT (0C8H),A
	LD A,H
	LD I,A
	EI
	CALL IzvediRETI
	LD HL,0749H
	JP IzpisiPrelomInNiz

; ----------------------------------------
; Sporocxilo o napaki pri nalaganju s trdega diska, ki se nikoli ne izpisxe?
	DB $11, $00
	DB "LOADING ERROR FROM HARD DISK TRY TO LOAD SYSTEM FROM FLOPPY "
	DB $0

	;;; PROSTOR ;;;

	ORG 2047
	NOP