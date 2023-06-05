	Trampolin equ F600h
	CPMLDR equ E000h
	Scroll equ FFEBh
	Neznano1 equ FFD0h
	Neznano2 equ FFD1h
	Neznano3 equ FFD2h
	Neznano4 equ FFD4h
	Neznano5 equ FFD5h
	Neznano6 equ FFD7h
	Neznano7 equ FFD8h

; Partner WF/G ROM disassembly (delo v izdelavi)
; Matej Horvat

; ----------------------------------------

	ORG	$0

; ----------------------------------------

	JP	Zacetek

; ----------------------------------------

; Ukazna vrstica, kjer uporabnik lahko izbere zagon z diskete
; ali s trdega diska.

UkaznaVrstica:
	LD	SP,0xFFC0
	CALL	PrelomVrstice
	LD	A,0x2A	; '*'
	CALL	GDPUkaz
	CALL	BeriInIzpisiZnak
	AND	0xDF	; Pretvori v uppercase
	CP	0x41	; 'A'
	JP	Z,HDBootSkok
	CP	0x46	; 'F'
	JP	Z,FDBootSkok
NeznanUkaz:
	LD	A,0x3F	; '?'
	CALL	GDPUkaz
	JR	UkaznaVrstica

; ----------------------------------------

;;; PROSTOR ;;;

CpStr:
	LD A,23H ; '#'
	CALL GDPUkaz
	RET

;;; KONEC PROSTORA ;;;

	ORG 	$66

; ----------------------------------------

; Nerabljen skok.

	JP	NeznanUkaz

; ----------------------------------------

; Nerabljene procedure za izpis sxestnajstisxkih sxtevil.

IzpisiHex16:
	CALL	PrelomVrstice
	LD	A,H
	CALL	IzpisiHex8
	LD	A,L
	CALL	IzpisiHex8
	LD	A,0x20	; ' '
	JP	GDPUkaz
IzpisiHex8:
	PUSH	BC
	LD	B,A
	SRA	A
	SRA	A
	SRA	A
	SRA	A
	AND	0x0F
	CALL	IzpisiHex4
	LD	A,B
	AND	0x0F
	CALL	IzpisiHex4
	POP	BC
	RET
IzpisiHex4:
	CP	0x0A
	JP	M,0x0099
	ADD	A,0x37
	JR	0x009B
	ADD	A,0x30
	CALL	GDPUkaz
	RET

; ----------------------------------------

; Pocxaka, da uporabnik pritisne tipko na tipkovnici,
; nato izpisxe njen znak na GDP.

BeriInIzpisiZnak:
	IN	A,(0xD9)
	BIT	0,A
	JR	Z,BeriInIzpisiZnak	; Cxakaj, da je znak na voljo.
	IN	A,(0xD8)
	RES	7,A
	CP	0x20
	RET	C	; Cxe je kontrolni znak, koncxamo.

; ----------------------------------------

; Posxlje ukaz na GDP.

GDPUkaz:
	CALL	CakajGDP
	OUT	(0x20),A
	RET

; ----------------------------------------

; Pocxaka, da GDP koncxa izvajanje morebitnega ukaza.

CakajGDP:
	PUSH	AF
	IN	A,(0x20)
	AND	0x04
	JR	Z,0x00B3
	POP	AF
	RET

; ----------------------------------------

; Nerabljena procedura, ki izpisxe presledek na GDP.

IzpisiPresledek:
	LD	A,0x20
	JR	GDPUkaz

; ----------------------------------------

; Izvede prelom vrstice.

; Pomaknemo vsebino zaslona 12 pikslov navzgor.
PrelomVrstice:
	CALL	CakajGDP
	LD	A,(Scroll)
	SUB	0x0C
	LD	(Scroll),A
	OUT	(0x36),A
	PUSH	HL
; Izbrisxemo novo vrstico.
	LD	HL,0x00DE
	CALL	IzpisiNiz
; Premaknemo pero na levo.
	LD	HL,0x00F3
	CALL	IzpisiNiz
	POP	HL
; Izberemo nacxin risanja.
	XOR	A
	JP	GDPUkaz

; ----------------------------------------

; Niz ukazov za GDP, ki premakne pero v spodnji levi kot in pobrisxe vrstico.

	DB	$03, $00, $05, $01, $0B, $0B, $0B, $0B
	DB	$0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B
	DB	$0B, $0B, $0B, $0B, $00

; ----------------------------------------

; Niz ukazov za GDP, ki premakne pero na skrajno levo.

	DB	$21, $00, $0D, $00

; ----------------------------------------

; Vstopna tocxka v memory test.

MemoryTest:
	LD	HL,0x02D1
	CALL	IzpisiPrelomInNiz
	LD	HL,0x2000
	LD	BC,0xFF80
	LD	D,0x02
	LD	A,0x00
	PUSH	DE
	PUSH	AF
	CALL	0x0114
	POP	AF
	POP	DE
	ADD	A,0x55
	DEC	D
	JR	NZ,0x0107
	RET

; ----------------------------------------

	CALL	0x0125
	OUT	(0x90),A
	CALL	0x0125
	CALL	0x0138
	OUT	(0x88),A
	CALL	0x0138
	RET

; ----------------------------------------

	PUSH	AF
	PUSH	HL
	LD	D,A
	CPL
	LD	E,A
	LD	(HL),D
	INC	HL
	LD	(HL),E
	INC	HL
	PUSH	HL
	OR	A
	SBC	HL,BC
	POP	HL
	JR	C,0x012A
	POP	HL
	POP	AF
	RET

; ----------------------------------------

	PUSH	HL
	PUSH	AF
	LD	D,A
	CPL
	LD	E,A
	LD	A,(HL)
	CP	D
	JR	NZ,0x0151
	INC	HL
	LD	A,(HL)
	CP	E
	JR	NZ,0x0151
	INC	HL
	PUSH	HL
	OR	A
	SBC	HL,BC
	POP	HL
	JR	C,0x013D
	POP	AF
	POP	HL
	RET
	LD	HL,0x015A
	CALL	IzpisiPrelomInNiz
	JP	UkaznaVrstica

; ----------------------------------------

; Sporocxilo o neuspelem memory testu.

	DB	$21, $00
	DB	"MEMORY ERROR !!!"
	DB	$00

; ----------------------------------------

Zacetek:
	LD	SP,0xFFC0

; Inicializacija PIO
	LD	A,0x07
	OUT	(0x31),A
	OUT	(0x33),A
	LD	A,0x0F
	OUT	(0x31),A
	OUT	(0x33),A

	LD	A,0x18
	OUT	(0x30),A
	LD	A,0x6D
	OUT	(0x32),A
	XOR	A
	OUT	(0x39),A
	OUT	(0x36),A
	LD	(Scroll),A

; (odvecx)
	XOR	A
	OUT	(0x21),A

; Izbira in spust GDP peresa
	LD	A,0x03
	OUT	(0x21),A

	LD	A,0x04	; Pocxistimo GDP sliko...
	CALL	GDPUkaz
	LD	A,0x05	; ... in postavimo pero na levi rob.
	CALL	GDPUkaz

	XOR	A
	OUT	(0x39),A
	OUT	(0x30),A

	CALL	AVDCInit1
	CALL	AVDCInit2

; Inicializacija SIO "CRT" kanala (za tipkovnico)
	LD	C,0xD9
	LD	HL,0x02B6
	LD	B,0x07
	OTIR

; Inicializacija SIO "LPT" kanala
	LD	C,0xDB
	LD	HL,0x02B6
	LD	B,0x07
	OTIR

; Inicializacija SIO "VAX" kanala
	LD	C,0xE1
	LD	HL,0x02B6
	LD	B,0x07
	OTIR

	LD	SP,0xFFC0

; Y koordinata GDP peresa := 100
	LD	A,0x64
	OUT	(0x2B),A

	LD	HL,0x02BD
	CALL	IzpisiPrelomInNiz

; Spet postavimo pero na levi rob.
	LD	A,0x05
	CALL	GDPUkaz

	LD	HL,0x022D
	CALL	IzpisiPrelomInNiz

	CALL	MemoryTest

	CALL	FDCInit

	CALL	0x02EE

	IN	A,(0xD9)
	AND	0x01	; Je na voljo znak na tipkovnici?
	JP	Z,HDBootSkok
	CALL	BeriInIzpisiZnak
	CP	0x03	; Je CTL+C?
	JP	NZ,HDBootSkok
	LD	HL,0x01FC
	CALL	IzpisiPrelomInNiz
	JP	UkaznaVrstica

; ----------------------------------------

; Sporocxilo o prekinjenem zagonu.

	DB	$21, $00
	DB	"Interrupted"
	DB	$2C
	DB 	" press A or F to load the system !"
	DB 	$00

; ----------------------------------------

; Niz z verzijo programa.

	DB	$21, $00
	DB	"[ Boot V 1.1 - WF ]"
	DB 	$00

; ----------------------------------------

IzpisiPrelomInNiz:
	CALL	PrelomVrstice
; (se nadaljuje v IzpisiNiz)

; ----------------------------------------

; Izpisxe niz na GDP.
; Prvi bajt niza se zapisxe v GDP-jev register za velikost znakov,
; drugi pa v kontrolni register 2. V praksi je drugi bajt vedno 0,
; lahko bi pa bil 4 za lezxecxe besedilo.

; Vhod:
; HL -> niz, zakljucxen z 0

; Unicxi A.

IzpisiNiz:
	CALL	CakajGDP
	LD	A,(HL)
	OUT	(0x23),A
	INC	HL
	LD	A,(HL)
	OUT	(0x22),A
	INC	HL
	LD	A,(HL)
	OR	A
	RET	Z
	CALL	GDPUkaz
	INC	HL
	JR	0x0251

; ----------------------------------------

Zakasnitev:
	PUSH	BC
	LD	B,0xFF
	NOP
	DJNZ	0x025D
	POP	BC
	RET

; ----------------------------------------

AVDCInit1:
	LD	A,0x00
	OUT	(0x39),A
	CALL	Zakasnitev
	CALL	Zakasnitev
	CALL	Zakasnitev
	LD	HL,0x02AC
	XOR	A

; SS1 := 0
	OUT	(0x3E),A
	OUT	(0x3F),A

; SS2 := 0
	OUT	(0x3A),A
	OUT	(0x3B),A

	LD	A,0x10
	OUT	(0x39),A
	LD	B,0x0A
	LD	C,0x38
	OTIR

	RET

; ----------------------------------------

; Vkljucxi AVDC kurzor in ???
AVDCInit2:
	LD	A,0x3D
	OUT	(0x39),A

; Naslov AVDC kurzorja := 0
	XOR	A
	OUT	(0x3D),A
	OUT	(0x3C),A

	LD	HL,0x1FFF
	CALL	AVDCNastaviDispAddr

; Zapolni AVDC framebuffer s presledki?
	LD	A,0x20
	OUT	(0x34),A
	XOR	A
	OUT	(0x35),A
	LD	A,0xBB	; Write from cursor to pointer
	OUT	(0x39),A

	RET

; ----------------------------------------

; Nastavi AVDC inicializacijska registra 10 in 11
; (display address register lower/upper).

; Vhod:
; HL = novi display address

; Unicxi A.

AVDCNastaviDispAddr:
	LD	A,0x1A
	OUT	(0x39),A
	LD	A,L
	OUT	(0x38),A
	LD	A,H
	OUT	(0x38),A
	RET

; ----------------------------------------

; Inicializacijski niz za AVDC.

	DB	$D0, $2F, $0D, $05, $99, $4F, $0A, $EA
	DB	$00, $30

; ----------------------------------------

; Inicializacijski niz za serijska vrata.

	DB	$18, $04, $44, $03, $C1, $05, $68

; ----------------------------------------

; Zagonsko sporocxilo.

	DB	$A8, $00
	DB	"Delta Partner GDP"
	DB 	$00

; ----------------------------------------

; Sporocxilo o testiranju spomina.

	DB	$21, $00
	DB	"TESTING MEMORY ... "
	DB 	$00

; ----------------------------------------

; Nerabljen bajt?

	DB	$00

; ----------------------------------------

; ???
; To je v resnici IVT, ki kazxe tudi na FDC handler na 4CA

	DW	$04CA, $05D6, $0524

; ----------------------------------------

; Prazna funkcija; verjetno se je pogojno uporabljala med razvojem.

	RET

; ----------------------------------------

; Nerabljeno.

	NOP
	NOP

; ----------------------------------------

; Nerabljen skok.

	JP	0x04CE

; ----------------------------------------

HDBootSkok:
	JP	HDBoot

; ----------------------------------------

; Nerabljen skok.

	JP	0x05A7

; ----------------------------------------

FDBootSkok:
	JP	FDBoot

; ----------------------------------------

FDCInit:
	DI
	IM	2
	LD	HL,0x02E8
	LD	A,L
	OUT	(0xE8),A
	OUT	(0xC8),A
	LD	A,H
	LD	I,A
	EI
	HALT
	LD	A,0x08
	CALL	0x0337
	CALL	0x0345
	CALL	0x0345
	LD	A,0x03
	CALL	0x0337
	LD	A,0x0D
	AND	0x0F
	RLCA
	RLCA
	RLCA
	RLCA
	LD	B,A
	LD	A,0x0E
	AND	0x0F
	OR	B
	CALL	0x0337
	LD	A,0x04
	RLCA
	AND	0xFE
	CALL	0x0337
	RET

; ----------------------------------------

	PUSH	AF
	IN	A,(0xF0)
	AND	0xC0
	CP	0x80
	JP	NZ,0x0338
	POP	AF
	OUT	(0xF1),A
	RET

; ----------------------------------------

	IN	A,(0xF0)
	AND	0xC0
	CP	0xC0
	JP	NZ,0x0345
	IN	A,(0xF1)
	RET

; ----------------------------------------

	LD	A,0x07
	CALL	0x0337
	LD	A,(Neznano1)
	CALL	0x0337
	EI
	HALT
	LD	A,0x08
	CALL	0x0337
	CALL	0x0345
	CALL	0x0345
	XOR	A
	LD	(Neznano2),A
	LD	(Neznano6),A
	RET

; ----------------------------------------

	CALL	0x03ED
	RET	NZ
	LD	A,0x0A
	LD	(Neznano5),A
	LD	A,0x05
	OUT	(0xC0),A
	LD	A,0xCF
	OUT	(0xC0),A
	CALL	0x045C
	LD	HL,0x046E
	OTIR
	LD	A,0x06
	OR	0x40
	CALL	0x042A
	CALL	0x0446
	EI
	HALT
	JP	C,0x03AB
	IN	A,(0x98)
	AND	0x01
	JP	NZ,0x0394
	LD	HL,0x0529
	CALL	IzpisiPrelomInNiz
	OUT	(0x98),A
	JP	0x0394
	LD	A,0x03
	OUT	(0xCA),A
	CALL	0x0345
	CALL	0x0345
	PUSH	AF
	LD	B,0x05
	CALL	0x0345
	DEC	B
	JP	NZ,0x03B8
	POP	AF
	CP	0x80
	RET	Z
	LD	A,(Neznano5)
	OR	A
	JP	Z,0x03EB
	DEC	A
	LD	(Neznano5),A
	LD	A,(Neznano2)
	PUSH	AF
	INC	A
	LD	(Neznano2),A
	LD	A,(Neznano6)
	PUSH	AF
	CALL	0x03ED
	POP	AF
	LD	(Neznano6),A
	POP	AF
	LD	(Neznano2),A
	CALL	0x03ED
	JP	0x037A
	INC	A
	RET

; ----------------------------------------

	CALL	0x0501
	LD	A,0x0F
	CALL	0x0337
	CALL	0x041B
	CALL	0x0337
	LD	A,(Neznano2)
	CALL	0x0337
	EI
	HALT
	LD	A,0x08
	CALL	0x0337
	CALL	0x0345
	CALL	0x0345
	LD	B,A
	LD	A,(Neznano2)
	CP	B
	JP	Z,0x0419
	XOR	A
	INC	A
	RET
	XOR	A
	RET

; ----------------------------------------

	LD	A,(Neznano6)
	RLCA
	RLCA
	AND	0x04
	PUSH	BC
	LD	B,A
	LD	A,(Neznano1)
	OR	B
	POP	BC
	RET

; ----------------------------------------

	CALL	0x0337
	CALL	0x041B
	CALL	0x0337
	LD	A,(Neznano2)
	CALL	0x0337
	LD	A,(Neznano6)
	CALL	0x0337
	LD	A,(Neznano4)
	CALL	0x0337
	RET

; ----------------------------------------

	LD	A,0x01
	CALL	0x0337
	LD	A,(Neznano4)
	CALL	0x0337
	LD	A,0x0A
	CALL	0x0337
	LD	A,0xFF
	CALL	0x0337
	RET

; ----------------------------------------

	LD	A,0x79
	OUT	(0xC0),A
	LD	HL,(Neznano3)
	LD	A,L
	OUT	(0xC0),A
	LD	A,H
	OUT	(0xC0),A
	LD	B,0x0B
	LD	C,0xC0
	RET

; ----------------------------------------

; Init string za FDC???

	DB	$FF, $00, $14, $28, $85, $F1, $8A, $CF
	DB	$01, $CF, $87, $FF, $00, $14, $28, $85
	DB	$F1, $8A, $CF, $05, $CF, $87

; ----------------------------------------

FDNaloziCPMLDR:
	LD	A,0x13
	LD	(Neznano7),A
	XOR	A
	LD	(Neznano1),A
	CALL	0x0351
	LD	HL,0xE000
	LD	(Neznano3),HL
	XOR	A
	INC	A
	LD	(Neznano4),A
	CALL	0x0371
	JP	NZ,0x06D1
	LD	DE,0x0100
	LD	HL,(Neznano3)
	ADD	HL,DE
	LD	(Neznano3),HL
	LD	A,(Neznano4)
	INC	A
	LD	(Neznano4),A
	LD	HL,0xFFD8
	CP	(HL)
	JP	NZ,0x049B
	LD	A,(Neznano6)
	OR	A
	RET	NZ
	INC	A
	LD	(Neznano6),A
	LD	A,0x0E
	LD	(Neznano7),A
	JP	0x0496

; ----------------------------------------

FDCIntHandler:
	EI
	SCF
	RETI

; ----------------------------------------

; Sem skocxi procedura na 02F1, ki ni nikoli klicana, torej tudi
; to ni nikoli klicano.

	CALL	FDNaloziCPMLDR
	JP	UkaznaVrstica

; ----------------------------------------

FDBoot:
	CALL	FDNaloziCPMLDR
	LD	A,(CPMLDR)	; Prvi bajt prvega sektorja...
	CP	0xC3	; ... mora biti opcode za brezpogojni JP...
	JP	Z,0x04EA
	CP	0x31	; ... ali LD SP, nn
	JP	Z,0x04EA
	LD	HL,0x0593
	JP	Napaka

; Nalagalnik OSa je nalozxen; skocximo vanj
	JP	Trampolin

; ----------------------------------------

	IN	A,(0x98)
	AND	0x01
	RET

; ----------------------------------------

	LD	A,0xFF
	PUSH	BC
	LD	B,0xFF
	DEC	B
	JP	NZ,0x04F7
	DEC	A
	JP	NZ,0x04F5
	POP	BC
	RET

; ----------------------------------------

	CALL	0x04ED
	JP	NZ,0x050C
	OUT	(0x98),A
	CALL	0x04F2
	XOR	A
	OUT	(0x98),A
	LD	A,0x47
	OUT	(0xC8),A
	OUT	(0xC9),A
	LD	A,0x82
	OUT	(0xC8),A
	OUT	(0xC9),A
	LD	A,0xA7
	OUT	(0xCA),A
	LD	A,0xFF
	OUT	(0xCA),A
	RET

; ----------------------------------------

NeznanIntHandler:
	EI
	SCF
	CCF
	RETI

; ----------------------------------------

; Sporocxilo, da disketni pogon ni pripravljen.

	DB	$21, $00
	DB	"FLOPPY DISK NOT READY !!!!"
	DB	$00

; ----------------------------------------

HDBoot:
	CALL	HDNaloziCPMLDR
	LD	A,(CPMLDR)	; Prvi bajt prvega sektorja...
	CP	0x31	; ... mora biti opcode za LD SP, nn
	JP	Z,0x0557
	LD	HL,0x0593
	JP	Napaka

; Kopiramo ROM na 2000h
	LD	HL,0x0000
	LD	DE,0x2000
	LD	BC,0x0800
	LDIR

; Kopiramo interrupt handler(?)
	LD	HL,0x0761
	LD	DE,0xC000
	LD	BC,0x006C
	LDIR

	DI
	LD	A,0x03
	OUT	(0xC8),A
	OUT	(0xC9),A
	LD	HL,0xC000
	LD	A,H
	LD	I,A
	LD	A,L
	OUT	(0xE8),A
	OUT	(0xC8),A
	LD	A,0x47
	OUT	(0xC8),A
	LD	A,0xFF
	OUT	(0xC8),A
	LD	A,0xC7
	OUT	(0xC9),A
	LD	A,0x64
	OUT	(0xC9),A
	EI

; Nalagalnik OSa je nalozxen; skocximo vanj
	JP	Trampolin

; ----------------------------------------

; Sporocxilo, da trdi disk ni zagonski.

	DB	$21, $00
	DB	"NO SYSTEM ON DISK"
	DB	$00

; ----------------------------------------

; Sem skocxi procedura na 02F7, ki ni nikoli klicana, torej tudi
; to ni nikoli klicano.

	CALL	HDNaloziCPMLDR
	JP	UkaznaVrstica

; ----------------------------------------

	XOR	A
	OUT	(0x12),A
	DI
	LD	A,0x47
	OUT	(0xC8),A
	LD	A,0xFF
	OUT	(0xC8),A
	LD	A,0xC7
	OUT	(0xC9),A
	LD	A,0x50
	OUT	(0xC9),A
	EI
	CALL	0x05FC
	LD	HL,0x0755
	CALL	0x063D
	CALL	0x0662
	JP	NZ,0x05C5
	LD	A,0x03
	OUT	(0xC9),A
	RET

; ----------------------------------------

CTCIntHandler:
	LD	A,0x03
	OUT	(0xC9),A
	CALL	IzvediRETI
	EI
	LD	HL,0x05E6
	JP	Napaka

; ----------------------------------------

IzvediRETI:
	RETI

; ----------------------------------------

; Sporocxilo, da trdi disk ni pripravljen.

	DB	$21, $00
	DB	"HARD DISK NOT READY"
	DB	$00

; ----------------------------------------

	LD	HL,0x0747
	CALL	0x0652
	CALL	0x0662
	RET	Z
	LD	A,0x34
	JP	0x06D7

; ----------------------------------------

HDNaloziCPMLDR:
	CALL	0x05AD
	LD	A,0xC3
	OUT	(0xC0),A
	LD	HL,0x075B
	CALL	0x063D
	IN	A,(0x10)
	AND	0x40
	JP	Z,0x0618
	IN	A,(0x10)
	AND	0x10
	JP	NZ,0x0634
	LD	A,0x22
	OUT	(0x10),A
	CALL	0x06A9
	IN	A,(0x10)
	AND	0x10
	JP	Z,0x062D
	CALL	0x0662
	RET	Z
	LD	A,0x32
	JP	0x06D7

; ----------------------------------------

	CALL	0x067F
	CALL	0x069B
	LD	B,A
	AND	0x10
	RET	Z
	LD	A,B
	AND	0x40
	RET	NZ
	LD	A,(HL)
	OUT	(0x11),A
	INC	HL
	JP	0x0640

; ----------------------------------------

	CALL	0x067F
	CALL	0x069B
	AND	0x40
	RET	NZ
	LD	A,(HL)
	OUT	(0x11),A
	INC	HL
	JP	0x0655

; ----------------------------------------

	CALL	0x069B
	AND	0x10
	JP	NZ,0x066F
	LD	A,0x42
	JP	0x06D7
	IN	A,(0x11)
	LD	B,A
	INC	HL
	CALL	0x069B
	IN	A,(0x11)
	XOR	A
	OUT	(0x10),A
	LD	A,B
	AND	0x03
	RET

; ----------------------------------------

	IN	A,(0x10)
	AND	0x08
	JP	Z,0x068B
	LD	A,0x41
	JP	0x06D7
	LD	A,0x01
	OUT	(0x10),A
	IN	A,(0x10)
	AND	0x08
	JP	Z,0x068F
	LD	A,0x02
	OUT	(0x10),A
	RET

; ----------------------------------------

	IN	A,(0x10)
	RLA
	JP	NC,0x069B
	RRA
	RET

; ----------------------------------------

	LD	HL,0x06C2
	JP	0x06AC

; ----------------------------------------

	LD	HL,0x06B3
	LD	C,0xC0
	LD	B,0x0F
	OTIR
	RET

; ----------------------------------------

; ??? init string za DMA

	DB	$79, $00, $E0, $FF, $1E, $14, $28, $95
	DB	$11, $00, $8A, $CF, $01, $CF, $87

; ----------------------------------------

; ??? init string za DMA

	DB	$79, $00, $E0, $FF, $1E, $14, $28, $95
	DB	$11, $00, $8A, $CF, $05, $CF, $87

; ----------------------------------------

	LD	HL,0x06E0
	JP	Napaka
	LD	HL,0x0714
Napaka:
	CALL	IzpisiPrelomInNiz
	JP	UkaznaVrstica

; ----------------------------------------

; Sporocxilo, da je nekaj narobe z disketnim pogonom.

	DB	$21, $00
	DB	"FLOPPY DISK MALFUNCTION !!!RETRY WITH COMMAND  F "
	DB 	$00

; ----------------------------------------

; Sporocxilo, da je nekaj narobe s trdim diskom.

	DB	$21, $00
	DB	"HARD DISK MALFUNCTION >>> RETRY WITH COMMAND  A "
	DB	$00

; ----------------------------------------

; ???

	DB	$0C, $00, $00, $00, $00, $00, $01, $32
	DB	$04, $00, $80, $00, $40, $0B, $01, $00
	DB	$00, $00, $00, $00, $08, $00, $00, $00
	DB	$1F, $00

; ----------------------------------------

; IVT z 2 vnosoma za ???, ki kazxeta na rutino spodaj, ko je prekopirana.

	DW	$C004, $C004

; ----------------------------------------

; Rutina za ???, ki se prekopira na C000 skupaj z zgornjim IVT.

	DI
	LD	A,0x03
	OUT	(0xC8),A
	OUT	(0xC9),A
	OUT	(0x88),A
	LD	HL,0x2000
	LD	DE,0x0000
	LD	BC,0x0800
	LDIR
	LD	HL,0x02E8
	LD	A,L
	OUT	(0xE8),A
	OUT	(0xC8),A
	LD	A,H
	LD	I,A
	EI
	CALL	IzvediRETI
	LD	HL,0x078E
	JP	IzpisiPrelomInNiz

; ----------------------------------------

; Sporocxilo o napaki pri nalaganju s trdega diska, ki se nikoli ne izpisxe?

	DB	$11, $00
	DB	"LOADING ERROR FROM HARD DISK TRY TO LOAD SYSTEM FROM FLOPPY "
	DB	$00

	ORG 2047
	NOP