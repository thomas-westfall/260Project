#CSCI 260 Project 
#Written by Thomas Westfall
	
.data
frameBuffer: .space 0x80000
	
#n and m must be greater than 0
#n + 2m must be less than 257 (so can be a positive int <= 256)
#dont have to check 512 since 256 is smaller boundary and shape is symmetrical
#I set n to 50 and m to 25 here as an example, can be modified
n:	.word 50
m:	.word 25

.text
	lw $a0,n # a0 <- n
	lw $a1,m # a1 <- m


start:	#input validation
	slti $t0, $a0, 1		 #$t0 <- 1 if n is negative
	slti $t1, $a1, 1		 #$t1 <- 1 if m is negative
	bne $t0, $zero, end		 #if n <= 0, return nothing
	bne $t1, $zero, end 		 #if m <= 0, return nothing
	andi $t0, $a0, 1		 #check if n is odd
	andi $t1, $a1, 1		 #check if m is odd
	bne $t0, $zero, isOddn		 #increment n by 1 if odd
	bne $t1, $zero, isOddm		 #increment m by 1 if odd
	add $t0, $a0,$a1                 #$t0 <- n + m
	add $t0, $t0, $a1                #$t0 <- n + 2m
	slti $t1, $t0, 257               #$t1 <- 1 if n + 2m < 257
	beq $t1,$zero, end      	 #if n > 256, return nothing

	#get ready to make the display yellow
	li $t2, 0xFFFF00 		 #$t2 <- yellow
	la $t3, frameBuffer
	addi $t4, $zero, 0		 #t4 <- 0
	addi $t1, $zero, 524288 	 #t1 <- 524288 (256 * 512 * 4)
	
makeYellow: #make the entire display yellow
	add $t5, $t3, $t4		 #t5 <- framebuffer + offset
	sw $t2, 0($t5)
	addi $t4, $t4, 4		 #t5 <- t5 + 1 (iterate)
	bne $t4, $t1, makeYellow	 #if t5 != max pixel pos, loop again

#To make the desired pixels blue, I decided to code a rectangle creator
#and then make three rectangles using it.
#Two rectangles are n by m, and the third is 2m+n by n.
#putting the large rectangle in between the two smaller ones creates the
#desired plus sign shape
	
makeBlue: #start making the shapes
	li $t2, 0x0000ff		#t2 <- blue
	la $t3, frameBuffer
	srl $s2, $a0, 1			#s2 <- n / 2
	srl $s3, $a1, 1			#s3 <- m / 2
	sll $s4, $a0, 2			#s4 <- n * 4
	sll $s5, $a1, 2			#s5 <- m * 4
	sll $t6, $s2, 2			#t6 <- n * 2, which is n / 2 * 4
	sll $t7, $s3, 2			#t7 <- m * 2, which is m / 2 * 4

	#find the location of the first blue pixel (top left of top rect)
	addi $t9, $t3, 261120		#t9 <- center position (fb + 261120)
	sub $t9, $t9, $t6		#t9 <- center pos - col shift
	
	addi $t8, $s2, 0		#t8 <- n / 2
	add $t8, $t8, $a1		#t8 <- (n / 2) + m
	sll $t8, $t8, 11		#t8 <- ((n / 2) + m) * 2048
	sub $t9, $t9, $t8		#t9 <- center pos - row shift

#s7 and s0 check if small/big rects are made already,to prevent infinite jumping
	addi $s7, $zero, 0		#s7 <- 0
	addi $s0, $zero, 0		#s0 <- 0
smallRectParams:	
	addi $t1, $t9, 0		#t1 <- first pixel pos of rectangle
	add $t0, $t9, $s4		#t0 <- rectangle col last pos
	
	addi $t4, $zero, 0		#t4 <- 0
	addi $t5, $zero, 0		#t4 <- 0
	sll $t5, $a1, 11		#t5 <- m * 2048
	add $t4, $t1, $t5		#t4 <- last position of rectangle

#Start by making the top small rectangle
	j xLoop				#make the first row first

#rectangle creator
# $t9 <- top left pixel of rectangle
# $t1 <- row iterator	
# $t0 <- rightmost pixel of current row for rectangle	
# $t4 <- bottom right pixel of rectangle
yLoop:
	addi $t1, $t1, 2048		#t1 <- iterate row (add 2048)
	addi $t9, $t1, 0		#t9 <- t1 
xLoop:	
	sw $t2, 0($t9)			#change pixel color
	addi $t9, $t9, 4		#goto next pixel in row
	bne $t9, $t0, xLoop		#stop when last row pixel reached
	
	addi $t9, $t1, 0		#go back to first pixel of row
	addi $t9, $t9, 2048
	addi $t0, $t0, 2048
	bne $t9, $t4, yLoop		#stop when overall last pixel reached
	
	bne $s0, $zero, end             #all rectangles done, end program
	bne $s7, $zero, bigRectParams   #small rects done, do big rect now
	
#Make the second small rectangle now
secondSmallrect:
	addi $s6, $t9, 0		#s6 <- first col,last row,top small rect
	add $t8, $zero, $a0 		#t8 <- n
	sll $t8, $t8, 11		#t8 <- n * 2048
	add $t9, $t9, $t8		#t9 <- starting pos for new rect
	addi $s7, $s7, 1		#s7 <- 1 (first rect is now done)
	j smallRectParams


#both small rectangles are now done, now draw the middle large rectangle
bigRectParams:
	addi $t1, $s6, 0		#t1 <- fist col,last row,top small rect
	sub $t9, $t1, $s5		#s6 <-  t1 - m * 4 (pos of big rect)
	sub $t1, $t1, $s5		#t1 <- t1 - m * 4 (update row iterator)
	add $a2, $a0,$a1                #a2 <- n + m
	add $a2, $a2, $a1               #a2 <- n + 2m
	sll $a2, $a2, 2			#a2 <- (n + 2m) * 4
	add $t0, $t9, $a2		#t0 <- top rectangle col last pos
	
	addi $t4, $zero, 0		#t4 <- 0
	addi $t5, $zero, 0		#t4 <- 0
	sll $t5, $a0, 11		#t5 <- n * 2048
	add $t4, $t1, $t5		#t4 <- last position
	addi $s0, $s0, 1		#s0 <- 1 (big rect done)
	j xLoop				#making large rectangle

end:	
	li $v0,10 #exit code
	syscall
	
isOddn: #increments n by 1 if n is odd
	addi $a0, $a0, 1
	j start
	
isOddm: #increments m by 1 if m is odd
	addi $a1, $a1, 1
	j start
