TITLE Program 6A     (Program06A.asm)

;// Author: David Gluckman
;// Due date: 6/5/16
;// CS 271 Section 400 Spring 2016                 Date: 6/3/16
;// Description: This program demonstrates designing,
;// implementing, and calling low-level I/O procedures; and 
;// implementing and using a macro in a MASM program that displays,
;// sums, and averages integers.

INCLUDE Irvine32.inc

NUM_NUMS = 10	;// Number of integers to be requested

getString MACRO prompt, string, strLen
	;// Save registers
	push	ecx
	push	edx

	;// Move prompt offset into place
	mov		edx, prompt

	;// Call WriteString from Irvine32
	call	WriteString

	;// Move string length and string 
	;// offset into place
	mov		ecx, strLen
	dec		ecx
	mov		edx, string

	;// Call ReadString from Irvine32
	call	ReadString

	;// Restore registers
	pop		edx
	pop		ecx
ENDM

displayString MACRO string
	;// Save registers
	push	edx

	;// Move string offset into place
	mov		edx, string

	;// Call WriteString from Irvine32
	call	WriteString

	;// Restore registers
	pop		edx
ENDM

.data


progTitle	BYTE	"Programming Assignment 6, Option A: Designing Low-Level I/O Procedures", 0
programmer	BYTE	"Written by: David Gluckman", 0
instr1		BYTE	"Please enter 10 unsigned decimal integers.", 0
instr2		BYTE	"Each number must be small enough to fit in a 32-bit register.", 0
instr3		BYTE	"After 10 valid raw numbers have been entered, the program will display them along with their sum and average value.", 0
instr4		BYTE	"Also note that the sum of the integers entered must fit in a 32-bit register.", 0
enterNum	BYTE	"Please enter an unsigned number: ", 0
numError	BYTE	"ERROR: The entry is not an unsigned number or the number is too large.", 0
listText	BYTE	"You entered the following numbers: ", 0
comSpace	BYTE	", ", 0
sumText		BYTE	"The sum of these numbers is: ", 0
aveText		BYTE	"The average of these numbers is: ", 0
goodbye		BYTE	"That's all! Thanks for your participation.", 0

numString	BYTE	20 dup(0)
numArray	DWORD	NUM_NUMS dup(?)

numVal		DWORD	?
charVal		DWORD	?
listSum		DWORD	0
listAve		DWORD	?


.code
main PROC

	;// INTRODUCE PROGRAM

	;// Display program title
	displayString OFFSET progTitle
	call	CrLF

	;// Display programmer's name
	displayString OFFSET programmer
	call	CrLF
	call	CrLF


	;// DISPLAY INSTRUCTIONS
	displayString OFFSET instr1
	call	CrLF
	displayString OFFSET instr2
	call	CrLF
	displayString OFFSET instr3
	call	CrLF
	displayString OFFSET instr4
	call	CrLF
	call	CrLF


	;// GET USER INPUT

	;// Set up loop for user input
	mov		ecx, NUM_NUMS

	;// Move array address to EDI
	mov		edi, OFFSET numArray

inputLoop:				;// Return here to get the next number
	;// Get a new validated value
	push	OFFSET charVal
	push	OFFSET numError
	push	OFFSET enterNum
	push	OFFSET numVal
	push	LENGTHOF numString
	push	OFFSET numString
	call	ReadVal

	;// Save the value to the array
	mov		eax, numVal
	mov		[edi], eax

	;// Move to the next array position
	add		edi, 4

	;// Loop if there are still values to enter
	loop	inputLoop


	;// DISPLAY LIST OF NUMBERS
	call	CrLF
	displayString OFFSET listText
	call	CrLF

	;// Loop through each array element
	mov		ecx, NUM_NUMS
	mov		esi, OFFSET numArray
listLoop:

	;// Reset numString to all 0s
	push	ecx
	mov		ecx, LENGTHOF numString
	mov		edi, OFFSET numString
zeroOut :
	mov		al, 0
	stosb
	loop	zeroOut
	pop		ecx


	mov		eax, [esi]			;// Current array element

	;// Call WriteVal on current array element
	push	OFFSET numString
	push	eax
	call	WriteVal
	
	;// Skip the comma after last element
	cmp		ecx, 1
	je		noComma
	
	;// Display a comma and space
	displayString OFFSET comSpace
		
noComma:		;// Continue here on the last loop to skip the comma
	add		esi, 4
	loop	listLoop

	call	CrLF


	;// CALCULATE SUM
	mov		listSum, 0

	;// Loop through array elements and accumulate in eax
	mov		ecx, NUM_NUMS
	mov		esi, OFFSET numArray
	mov		eax, 0
sumLoop:		;// Continue here to sum next element
	add		eax, [esi]
	add		esi, 4
	loop	sumLoop

	;// Save sum
	mov		listSum, eax


	;// CALCULATE AVERAGE
	mov		edx, 0
	mov		eax, listSum
	mov		ebx, NUM_NUMS
	div		ebx

	;// Save average
	mov		listAve, eax


	;// DISPLAY SUM
	displayString OFFSET sumText

	;// Reset numString to all 0s
	push	ecx
	mov		ecx, LENGTHOF numString
	mov		edi, OFFSET numString
zeroAgain:
	mov		al, 0
	stosb
	loop	zeroAgain
	pop		ecx

	;// Display sum
	push	OFFSET numString
	push	listSum
	call	WriteVal	
	call	CrLF


	;// DISPLAY AVERAGE
	displayString OFFSET aveText

	;// Reset numString to all 0s
	push	ecx
	mov		ecx, LENGTHOF numString
	mov		edi, OFFSET numString
zeroLast:
	mov		al, 0
	stosb
	loop	zeroLast
	pop		ecx

	;// Display average
	push	OFFSET numString
	push	listAve
	call	WriteVal
	call	CrLF


	;// DISPLAY GOODBYE MESSAGE
	call	CrLF
	displayString OFFSET goodbye
	call	CrLF
	call	CrLF

	exit	; exit to operating system
main ENDP



;// Procedure to prompt for and accept an unsigned integer as
;//		a string and convert it to a numeric value while
;//		validating that it only contains numeric digits and
;//		fits in a 32-bit register.
;// receives: number string, number value, and character value 
;//		variables by address; prompt and error messages by 
;//		address; and length of number string by value 
;// returns: validated number in number value
;// preconditions: none
;// registers changed: none; all saved and restored

ReadVal PROC 
	;// Save registers
	pushad
	mov		ebp, esp

	jmp		numRequest	;// Skip the error message the first time

valError:		;// Continue here if there is a validation error
	displayString [ebp + 52]
	call	CrLF

numRequest:		;// Continue here when requesting a number
	
	;// Get user entry as string
	getString [ebp + 48], [ebp + 36], [ebp + 40]

	;// Set up to convert string entry to value
	mov		ecx, eax			;// String length to counter
	mov		esi, [ebp + 36]		;// numString address
	mov		edi, [ebp + 44]		;// Move numVal's address to edi
	mov		ebx, 0
	mov		[edi], ebx			;// Set numVal to 0
	cld							;// Clear direction flag
nextChar:	;// Continue here to read next character in string
	;// Get the next char
	lodsb

	;// Check that it is in the numeric range
	cmp		al, 48
	jb		valError
	cmp		al, 57
	ja		valError			;// Jump if value too big

	;// Save the character's value in charVal
	mov		edx, [ebp + 56]
	movzx	eax, al
	mov		[edx], eax			;// Save character value
	
	;// Multiply current numVal by 10
	mov		eax, [edi]
	mov		edx, 0
	mov		ebx, 10
	mul		ebx
	jc		valError			;// Jump if value too big

	;// Add charVal to numVal
	mov		edx, [ebp + 56]
	add		eax, [edx]
	jc		valError			;// Jump if value too big

	;// Subtract 48 from numVal
	sub		eax, 48
	jc		valError			;// Jump if value too big
	mov		[edi], eax
	jc		valError			;// Jump if value too big

	;// Get next character
	loop	nextChar


	;// Restore registers, clean up stack
	popad
	ret 20
ReadVal ENDP



;// Procedure to convert an unsigned integer to a string and display
;//		the string.
;// receives: integer by value, string by address
;// returns: nothing; displays the value
;// preconditions: the string is formatted to all 0s
;// registers changed: none; all saved and restored

WriteVal PROC
	;// Save registers
	pushad
	mov		ebp, esp

	mov		eax, [ebp + 36]		;// array value

	;// Count number of digits in array value
	mov		ecx, 0		;// Counter for digits
	mov		ebx, 10		;// Divide by 10 to check digits
countNext:		;// Continue here to count the next digit
	mov		edx, 0
	div		ebx			;// Divide value by 10
	inc		ecx			;// Increment digit counter
	cmp		eax, 0		;// If no digits left
	jz		countEnd	;// Count is over
	jmp		countNext	;// If not, keep counting

countEnd:		;// Continue here once digit count complete
	mov		edi, [ebp + 40]		;// OFFSET numString
	add		edi, ecx			;// Add number of digits
	dec		edi					;// Start at last digit
	mov		eax, [ebp + 36]		;// array value (reset)


	std							;// Digits added to string in reverse order

nextDig:		;// Continue here to convert next digit to char
	mov		edx, 0
	mov		ebx, 10
	div		ebx					;// Divide value by 10

	add		edx, 48				;// Add 48 to get ASCII representation
	
	push	eax
	mov		eax, edx			;// Move the ASCII code to AL
	stosb						;// Store the char
	pop		eax

	cmp		eax, 0				;// If digits left, continue
	jne		nextDig

	displayString	[ebp + 40]	;// Display the char string

	;// Restore registers, clean up stack
	popad
	ret 8
WriteVal ENDP


END main
