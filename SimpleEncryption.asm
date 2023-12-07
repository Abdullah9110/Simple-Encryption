.data
inputFile: .space 32
outputFile: .space 32
fileWords:  .space 4096
finalString: .space 4096
printShiftAmount: .asciiz "Shift Amount: "
nameOfPlainMessage: .asciiz "Please input the name of the plain text file: "
nameOfCipherMessage: .asciiz "Please input the name of the cipher file: "
encDecMessage: .asciiz "choose between encryption and decryption (e or d): "

# $s0 = max length of a word
# $s1 = input file descriptior
# $s2 = space char
# $s3 = output file descriptior
# $s4 = mode

.text
main:	
        la $a0, encDecMessage
        jal print
         
        li $v0, 12 # read char (d or e)
        syscall
        move $s4, $v0
        jal newLine        # Call newLine procedure.
         
        beq $s4, 'e', enc
        beq $s4, 'E', enc
        beq $s4, 'd', dec
        beq $s4, 'D', dec
        
        b term # invalid input from user
        
enc:    la $a0, nameOfPlainMessage # encription section
        jal print
         
        jal read_inputFile_name
        jal remove_newLine_inputFile
        jal open_inputFile
        jal read_inputFile
          
        li $t0, 0
        li $t1, 0
        jal convert_string
        
        jal strlen        # Call strlen procedure.
        jal printData        # Call printData procedure.
        jal newLine        # Call newLine procedure.
         
        li $t0, 0
        jal shift        # Call shift procedure.
          
        la $a0, nameOfCipherMessage
        jal print
        
        jal read_outputFile_name
       	jal remove_newLine_outputFile
        jal open_outputFile
        jal write_outputFile
         
        b term

dec:    la $a0, nameOfCipherMessage # decription section
        jal print
         
        jal read_inputFile_name
        jal remove_newLine_inputFile
        jal open_inputFile
        jal read_inputFile
        
        li $t0, 0
        li $t1, 0
        jal convert_string
        
        jal strlen        # Call strlen procedure.
        jal newLine        # Call newLine procedure.
        
        li $t0, 0
        mul $s0, $s0, -1 # shift in the dec is in the oposite direction
        jal shift        # Call shift procedure.
            
        jal printData
            
        la $a0, nameOfPlainMessage
        jal print
         
        jal read_outputFile_name
        jal remove_newLine_outputFile
        jal open_outputFile
        jal write_outputFile
         
        b term
          
term:   li $v0, 16        # close output file
        la $a0, outputFile
        syscall
        
        li $v0, 16        # close input file
        la $a0, inputFile
        syscall
        
        li $v0, 10        # exit the program
        syscall

##################### --Producres Starts Here-- ####################

shift:
        lb $a3,finalString($t0)    # Load character at index
        beqz $a3,exit_shift     # Loop until the end of string is reached
        beq $a3, 32, next # skip space char (ASCII = 32)
        beq $a3, 10, next # skip new line char (ASCII = 10)
        addu $t2, $a3, $s0        
        bgt $t2, 'z', case
        blt $t2, 'a', case_2
        
store:  sb $t2, finalString($t0)
        j next
        
next:	addi $t0,$t0,1      # Increment index
        j shift
        
case:   subi $t2, $t2, 26
        j store
        
case_2: addi $t2, $t2, 26
        j store
        
exit_shift:
        jr $ra
        
##########################################################

convert_string:
        lb $a3,fileWords($t0)    # Load character at index
        beqz $a3,exit_convert_string     # Loop until the end of string is reached
        beq $a3, 32, store_convert_string # skip space char (ASCII = 32)
        beq $a3, 10, store_convert_string # skip new line char (ASCII = 10)
        ble $a3, 'z', first
        b next_convert_string
first:  bge $a3, 'a', store_convert_string
        ble $a3, 'Z', second
        b next_convert_string
second: bge $a3, 'A', case_convert_string
        b next_convert_string
store_convert_string: 
        sb $a3, finalString($t1)
        addi $t1,$t1,1
        j next_convert_string
next_convert_string:
        addi $t0,$t0,1      # Increment index
        j convert_string
case_convert_string:        
        addi $a3, $a3, 32
        j store_convert_string
exit_convert_string:
        sb $0, finalString($t1)
        jr $ra
        
##########################################################

strlen:
        li $t0, 0 # initialize the count to zero
        li $s0, 0
	li $t2, 0  
	      
loop:   lb $a3, finalString($t2) # load the next character into t1
        beqz $a3, exit # check for the null character
        beq $a3, 32, initilize 
        beq $a3, 10, initilize
        addi $t2, $t2, 1 # increment the string pointer
        addi $t0, $t0, 1 # increment the count
        j loop # return to the top of the loop
        
initilize:
        addi $t2, $t2, 1
        bgt $t0, $s0, greater
        
cont:   li $t0, 0
        j loop
greater:
        move $s0, $t0
        j cont
exit:
        bgt $t0, $s0, greater
        jr $ra

##########################################################

print:
        li $v0, 4 
        syscall
        jr $ra
        
##########################################################        

read_inputFile_name:
        li $v0, 8
        la $a0, inputFile
        la $a1, 32
        syscall
        jr $ra
         
##########################
         
remove_newLine_inputFile:
         li $t0,0        # Set index to 0
remove:  lb $a3,inputFile($t0)    # Load character at index
         addi $t0,$t0,1      # Increment index
         bnez $a3,remove     # Loop until the end of string is reached
         beq $a1,$s0,end    # Do not remove \n when string = maxlength
         subiu $t0,$t0,2     # If above not true, Backtrack index to '\n'
         sb $0, inputFile($t0)    # Add the terminating character in its place

end:     jr $ra

##########################################################

open_inputFile:
        li $v0, 13        #open file 
        la $a0, inputFile
        li $a1, 0
        syscall
        move $s1, $v0
        jr $ra
        
##########################################################

read_inputFile:
        li $v0, 14        #read file
        move $a0, $s1
        la $a1, fileWords
        la $a2, 4096
        syscall
        la $a0, fileWords
        jr $ra
        
##########################################################

read_outputFile_name:
        li $v0, 8
        la $a0, outputFile
        la $a1, 32
        syscall
        jr $ra

##########################################################

remove_newLine_outputFile:                 
         li $t0,0        # Set index to 0
remove_2: lb $a3,outputFile($t0)    # Load character at index
          addi $t0,$t0,1      # Increment index
          bnez $a3,remove_2     # Loop until the end of string is reached
          beq $a1,$s0,end_2    # Do not remove \n when string = maxlength
          subiu $t0,$t0,2     # If above not true, Backtrack index to '\n'
          sb $0, outputFile($t0)    # Add the terminating character in its place
end_2:    jr $ra

##########################################################

open_outputFile:
        li $v0, 13        #open file  
        la $a0, outputFile
        li $a1, 1
        syscall
        move $s3, $v0
        jr $ra
        
##########################################################

write_outputFile:
        li $v0, 15        #write file
        move $a0, $s3
        la $a1, finalString
        la $a2, 4096
        syscall
        jr $ra

##########################################################

printData:
        li $v0, 4
        la $a0, printShiftAmount
        syscall

        li $v0, 1
        move $a0, $s0
        syscall
        move $t0, $ra
        jal newLine
        move $ra, $t0
        jr $ra
        
##########################################################
        
newLine:
        li $v0 11  # syscall 11: print a character based on its ASCII value
        li $a0 10  # ASCII value of a newline is "10"
        syscall
        jr $ra
