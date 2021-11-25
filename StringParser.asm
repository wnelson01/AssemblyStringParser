TITLE Proj6_nelsonwa	(Proj6_nelsonwa.asm)
; Author: Wade Nelson
; Last Modified: 12/6/2020
; OSU email address: nelsonwa@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number: 6               Due Date: 12/6/2020
; Description: String Primitives & Macros

INCLUDE Irvine32.inc

; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Gets a string from the user
;
; Preconditions: n/a
;
; Receives:
; promptRef = prompt string offset
; integerStringOffset = offset storage location
;
; returns: integerStringOffset = string stored in memory
; ---------------------------------------------------------------------------------
mGetString MACRO promptRef, integerStringOffset
	push edx
	push ecx
	mov edx, promptRef
	call WriteString
	mov edx, integerStringOffset
	mov ecx, 13
	call ReadString
	call CrlF
	pop ecx
	pop edx
ENDM

; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Display an integer as a string
;
; Preconditions: n/a
;
; Receives:
; integerStringOffset integer in string to be displayed
;
; returns: n/a
; ---------------------------------------------------------------------------------
mDisplayString MACRO integerStringOffset
	mov edx, integerStringOffset
	call WriteString
ENDM

; (insert constant definitions here)

.data
prompt BYTE "Please enter a signed number: ",0
error BYTE "Error: You did not enter a signed number or your number was too big",13,10,13,10,0
intro BYTE "Project 6: String Primitives and Macros",13,10,"Wade Nelson",13,10,"Enter 10 signed decimal integers. Must fit within a 32 bit register.",13,10,0
entered BYTE "You entered:",0
sumLabel BYTE "sum: ",0
avgLabel BYTE "avg: ",0
goodBye BYTE "Goodbye",13,10,0
integerString BYTE 13 DUP(?)
stringInteger BYTE 11 DUP(?)
integerArray SDWORD 10 DUP(?)

.code
main PROC
	; intro
	mDisplayString offset intro
	call crlf
	
	; get 10 integers
	mov edi, offset integerArray
	mov ecx, 10
	_getTen:
	push offset error
	push offset prompt
	push offset integerString
	push edi
	call ReadVal
	add edi, 4
	loop _getTen
	
	; display the 10 integers
	mDisplayString offset entered
	mov esi, offset integerArray
	mov ecx, 10
	_printIntegers:
	push [esi]
	push offset stringInteger
	call WriteVal
	add esi, 4
	mov al, ' '
	call WriteChar
	loop _printIntegers
	call crlf

	; sum
	mov esi, offset integerArray
	mov ecx, 10
	mov eax, 0
	_sumIntegers:
	add eax, [esi]
	add esi, 4
	loop _sumIntegers
	mDisplayString offset sumLabel
	push eax
	push offset stringInteger
	call WriteVal
	call crlf

	; avg
	cdq
	mov ebx, 10
	idiv ebx
	mDisplayString offset avgLabel
	push eax
	push offset stringInteger
	call WriteVal
	call crlf
	call crlf
	mDisplayString offset goodBye

	Invoke ExitProcess,0	; exit to operating system
main ENDP

; ---------------------------------------------------------------------------------
; Name: readVal
;
; reads a string from a user and stores it as a signed sdword integer array
;
; Preconditions: 
; [ebp + 8] = integerArray[i]
; [ebp + 12] = offset integerString
; [ebp + 16] = offset prompt
; [ebp + 20] = offset error
; 
; Postconditions: 
; [ebp + 8] = integerArray[i]
;
; Receives: 
; [ebp + 8] = integerArray[i]
; [ebp + 12] = offset integerString
; [ebp + 16] = offset prompt
; [ebp + 20] = offset error
;
; Returns: [ebp + 8] = integerArray[i]
; ---------------------------------------------------------------------------------
ReadVal PROC
	; stack frame
	push ebp
	mov ebp, esp
	push eax
	push ebx
	push ecx
	push edi
	push edx
	push esi

	; set-up
	_initialize:
	cld
	mGetString [ebp + 16], [ebp + 12]
	cmp eax, 12
	jge _error
	mov ecx, 11
	mov edx, 0
	mov esi, [ebp + 12]
	lodsb
	cmp al, 45
	je _negativePassInitial
	cmp al, 43
	je _positivePass

	; convert ascii to decimal while validating
	_asciiToDecimal:
	cmp al, 0
	je _negativePassFinal
	cmp al, 48
	jl _error
	cmp al, 57
	jg _error
	mov ebx, eax
	mov eax, edx
	mov edx, 10
	mul edx
	jo _error
	sub ebx, 48
	add eax, ebx
	mov edx, eax
	cmp edx, 2147483647
	ja _error
	mov eax, 0
	lodsb
	loop _asciiToDecimal
	
	; first negative pass
	_negativePassInitial:
	lodsb
	cmp al, 0
	je _error
	jmp _asciiToDecimal

	; positive pass
	_positivePass:
	lodsb
	cmp al, 0
	je _error
	jmp _asciiToDecimal

	; final negative pass
	_negativePassFinal:
	mov eax, [ebp + 12]
	mov al, [eax]
	cmp al, 45
	jne _finalize
	neg edx
	jmp _finalize

	; error
	_error:
	mDisplayString [ebp + 20]
	jmp _initialize

	; clean-up
	_finalize:
	mov edi, [ebp + 8]
	mov [edi], edx
	pop esi
	pop edx
	pop edi
	pop ecx
	pop ebx
	pop eax
	pop ebp
	ret 16
ReadVal ENDP

; ---------------------------------------------------------------------------------
; Name: writeVal
;
; Writes an SDWORD integer value as a string
;
; Preconditions:
; [ebp + 12] = integer
; [ebp + 8] = stringInteger
;
; Postconditions:
; [ebp + 8] = stringInteger 
;
; Receives:
; [ebp + 12] = integer
; [ebp + 8] = stringInteger
;
; Returns:
; [ebp + 8] = stringInteger 
; ---------------------------------------------------------------------------------
WriteVal PROC
	; stack frame
	push ebp
	mov ebp, esp
	push eax
	push ebx
	push ecx
	push edi
	push edx
	mov eax, [ebp + 12] ; integer
	mov edi, [ebp + 8] ; stringInteger

	; set-up
	_initialize:
	mov ebx, 10
	mov ecx, 1
	push 0
	cld
	cmp eax, 0
	jl _negativePassInitial
	jmp _divideDown

	; initial negative pass
	_negativePassInitial:
	neg eax
	jmp _divideDown

	; convert decimal to ascii
	_divideDown:
	cdq
	div ebx
	add edx, 48
	push edx
	inc ecx
	cmp eax, 0
	jne _divideDown
	mov eax, [ebp + 12]
	cmp eax, 0
	jl _negativePassFinal
	jmp _popString
	
	; final negative pass
	_negativePassFinal:
	push 45
	inc ecx
	jmp _popString

	; pop remainders
	_popString:
	pop eax
	stosb
	loop _popString
	
	; clean-up
	_finalize:
	mDisplayString [ebp + 8]
	pop edx
	pop edi
	pop ecx
	pop ebx
	pop eax
	pop ebp
	ret 8
WriteVal ENDP
END main
