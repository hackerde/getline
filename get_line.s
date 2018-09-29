!!! Program to take in translation code, then take buffered input and translate each line using the given translation code
!!! Exits when user inputs only a newline
!!! by Anway De	12/6/17		

		_EXIT = 1						! symbol definitions
		_GETCHAR = 117
		_WRITE = 4
		_STDIN = 0
		_STDOUT = 1
		_STDERR	= 2

		MAXBUFF = 80

.SECT .TEXT								! start of code segment
	
		PUSH	5						! input translation code using getline
		PUSH	buff
		CALL	getline
		ADD		SP,4

		PUSH	buff 					! store input characters in variables inchar and outchar
		CALL 	gettrans
		ADD		SP,2

		MOV 	DX,1 					! set location to outside a line

4:		PUSH	MAXBUFF					! arg2
		PUSH	buff 					! arg1
		CALL	getline
		ADD		SP,4

		CMP 	DX,1 					! if outside a line, i.e. reading a new line
		JNE		5f 						! else process the line
		CMP 	AX,1 					! and if only one character was read in
		JNE		5f 						! else process the line
		!! assert: only a newline was read
		JMP		7f 						! stop taking input and exit the loop

5:		MOV 	DX,0 					! set location to inside a line

		MOV 	BX,buff
		ADD		BX,AX
		SUB		BX,1 		
		!! BX holds the address for the last character in the input line

		PUSH	buff 					! call function to translate line
		CALL	translate
		ADD		SP,2

		PUSH	AX 						! print translated line
		PUSH	buff
		PUSH	_STDOUT
		PUSH	_WRITE
		SYS
		ADD 	SP,8

		CMPB	(BX),'\n' 				! if last character is a newline
		JNE		6f 						! if not, repeat loop
		MOV 	DX,1 					! if yes, reset DX to make location outside line

6:		JMP 	4b 						! repeat loop

7:		CALL	print_summary 			! print summary analysis of input

		PUSH 	0 						! Exit with normal status
		PUSH	_EXIT
		SYS

getline:
		!! takes buffered input
		PUSH	BP 						! save registers and set up base pointer
		MOV 	BP,SP 
		PUSH	BX
		PUSH	CX
		MOV		BX,4(BP) 				! assign arg1 to BX
		MOV		CX,4(BP)
		ADD		CX,6(BP)
		SUB		CX,1 					! CX holds address of last byte in the buffer arg1

1:		CMP		BX,CX 					! if arg2-1 characters have already been stored in arg1
		JE 		2f 						! leave loop

		PUSH	_GETCHAR 				! input character
		SYS
		ADD	SP,2

		CMPB	AL,-1 					! if no characters were read
		JE 		2f 						! exit loop
		MOVB	(BX),AL 				! store character that was read in
		INC		BX 						! move to next address in arg1
		CMPB	AL,'\n' 				! if character read in was not a newline
		JNE		1b 						! repeat this loop

2:		MOVB	(BX),0x00 				! store nullbyte at the end
		MOV 	AX,BX 					! set up AX with return value
		SUB		AX,4(BP)

		POP		CX 						! restore registers
		POP		BX
		POP		BP
		RET

gettrans:
		!! stores translation code in variables
		PUSH	BP 						! save registers and set up base pointer
		MOV 	BP,SP
		PUSH	BX
		PUSH	CX
		MOV 	BX,4(BP) 				! assign arg1 to BX

		MOVB 	CL,(BX)
		MOVB	(inchar),CL 			! store first character of input in inchar
		ADD		BX,2 					! skip blankspace
		MOVB 	CL,(BX) 				! store second character of input in outchar
		MOVB	(outchar),CL

		MOV 	AX,1 					! return with normal status

		POP		CX 						! restore registers
		POP		BX
		POP		BP
		RET

translate:
		!! translates input and updates variables linect, wordct and charct
		PUSH	BP 						! save registers and set up base pointer
		MOV 	BP,SP
		PUSH	BX
		PUSH	CX
		PUSH	DX

		MOVB 	DL,(inword) 			! inword indicates if we are inside a word or not
		MOV 	BX,4(BP)				! assign arg1 to BX

8:		CMPB	(BX),'A' 				! test if next character is an upper-case
		JL		4f 						! skip to label 4 if not
		CMPB	(BX),'Z'
		JLE		5f 						! go to label 5 if yes
		CMPB	(BX),'z' 				! or a lower-case character
		JG		4f 						! skip to label 4 if not
		CMPB	(BX),'a'
		JGE		5f 						! go to label 5 if yes
		JMP		4f						! skip to label 4 if 'Z'<character<'a'

5:		CMPB	DL,0 					! if location was outside a word
		JNE		6f
		ADDB	(wordct),1 				! then increase word count
6:		MOVB 	DL,1 					! set location to inside a word
		JMP 	7f

4:		MOVB 	DL,0					! if not an upper-case or lower-case, set location to outside a word

7:		CMPB	(BX),'\n' 				! if next character is a newline
		JNE		1f
		ADDB	(linect),1 				! increase line count

		!! translate character
1:		CMPB	(BX),0x00				! if character is nullbyte
		JE 		3f 						! exit this loop
		MOVB	CL,(inchar)
		CMPB	(BX),CL 				! if character is same as inchar
		JNE		2f
		MOVB	CL,(outchar)
		MOVB	(BX),CL 				! replace it with outchar
		ADDB	(tranct),1 				! increase translated character count

2:		ADDB	(charct),1 				! increase character count
		INC 	BX 						! move to next character
		JMP		8b 						! repeat loop

3:		MOVB	(inword),DL 			! save location for use in next translate call
		POP		DX
		POP		CX
		POP		BX
		POP		BP
		RET

print_summary:
		!! prints summary of input
		PUSH	characters-summary 		! print label 'Summary'
		PUSH	summary
		PUSH	_STDERR
		PUSH	_WRITE
		SYS
		ADD 	SP,8

		!! print character count
		PUSH	(charct) 				! arg1
		PUSH	_STDERR					! arg2
		CALL	printdec
		ADD 	SP,4

		PUSH	words-characters 		! print label 'characters'
		PUSH	characters
		PUSH	_STDERR
		PUSH	_WRITE
		SYS
		ADD 	SP,8

		PUSH	(wordct) 				! print word count
		PUSH	_STDERR
		CALL	printdec
		ADD 	SP,4

		PUSH	lines-words 			! print label 'words'
		PUSH	words
		PUSH	_STDERR
		PUSH	_WRITE
		SYS
		ADD 	SP,8

		PUSH	(linect) 				! print line count
		PUSH	_STDERR
		CALL	printdec
		ADD 	SP,4

		PUSH	translations-lines 		! print label 'line'
		PUSH	lines
		PUSH	_STDERR
		PUSH	_WRITE
		SYS
		ADD 	SP,8

		PUSH	(tranct) 				! print translated character count
		PUSH	_STDERR
		CALL	printdec
		ADD 	SP,4

		PUSH	outchar-translations 	! print label 'translations'
		PUSH	translations
		PUSH	_STDERR
		PUSH	_WRITE
		SYS
		ADD 	SP,8

		RET

printdec:
	!! print decimal numbers
	PUSH	BP 							! save registers and set up base pointer
	MOV 	BP,SP
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX

	MOV		BX,digits 					! BX stores the address of the first empty memory location to store the digits
	MOV		CX,10						! algorithm: divide by 10 and store the remainder in memory (store digits from right to left)
	MOV		AX,6(BP)					! AX stores arg2 (the number)
1:	MOV		DX,0						! setting DX to 0 at the beginning of loop to store remainder
	DIV 	CX							! divide AX by CX --> AX has quotient and DX has remainder
	MOV		(BX),DX						! store remainder (which is the right-most digit of the number in AX) in memory
	ADD		(BX),48						! convert digit to its ASCII value
	CMP		AX,0						!! assert: if AX=0, then we have gone through all the digits
	JE		2f							! exit loop in that case
	INC		BX							! else make BX point to next empty location to store next digit (from the right)
	JMP		1b							! repeat loop

2:	PUSH	1 							
	PUSH	BX							!! assert: BX points to memory location which stores left most digit of arg2
	PUSH	4(BP)						! arg1 provides destination for writing
	PUSH	_WRITE						! print the digit
	SYS			
	ADD	SP,8

	CMP		BX,digits 					! if BX points to first memory location storing the digits, then we have printed all digits 
	JE		3f							! exit loop in that case
	SUB		BX,1						! otherwise point to previous memory location (since digits are stored in reverse order)
	JMP		2b							! repeat loop to print next digit

3:	POP		DX
	POP		CX
	POP		BX
	POP		AX
	POP		BP
	RET

.SECT .DATA
charct:		.WORD	0
wordct:		.WORD	0
linect:		.WORD	0
tranct: 	.WORD 	0
summary:	.ASCII	"Summary:\n "
characters:	.ASCII	" characters\n "
words:		.ASCII	" words\n "
lines:		.ASCII	" lines\n "
translations: .ASCII " translations\n"
outchar:	.BYTE	0
inchar:		.BYTE	0
inword:		.WORD	0
.SECT .BSS
buff:	.SPACE MAXBUFF
digits:	.SPACE	50

