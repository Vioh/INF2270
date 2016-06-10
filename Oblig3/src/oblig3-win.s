#########################################################################
# Brukernavn: syhd
# INF2270 - UiO (Vår 2016)
# Assembly kode for x86-CPU (som bruker little-endian rekkefølgen)
# Tab space: 8
# 
# For å gjøre det enklere å gjøre debug og forstår koden, har jeg lagt
# følgende 2 globale hjelpemetoder:
# - utf8_to_unicode() som konverterer fra utf8 til unicode.
# - unicode_to_utf8() som konverterer fra unicode til utf8. Denne metoden
#   beregner også hvor mange bytes dette utf8-tegnet består av, og lagrer
#   dette antallet i en static global variabel: nbytes
#########################################################################

	.extern fread, fwrite
	.extern _fread, _fwrite
	.data
nbytes:	.long	0
		
	.text 
	.globl	writebyte
	.globl	_writebyte
 # Navn:	writebyte
 # Synopsis:	Skriver en byte til en binærfil.
 # C-signatur: 	void writebyte (FILE *f, unsigned char b)
 # Registre:	%EAX: Midlertidig lagring plass

writebyte:
_writebyte:
	pushl	%ebp
	movl	%esp,%ebp
	pushl	8(%ebp)		# param4 i "fwrite"
	pushl 	$1		# param3 i "fwrite"
	pushl 	$1		# param2 i "fwrite"
	leal	12(%ebp),%eax	
	pushl 	%eax		# param1 i "fwrite"
	call	_fwrite
	movl	%ebp,%esp
	popl	%ebp
	ret

	
#########################################################################
# unicode_to_utf8()
#########################################################################
	
	.globl	unicode_to_utf8
	.globl	_unicode_to_utf8
 # Navn:	unicode_to_utf8
 # Synopsis:	Konvertere fra Unicode til UTF-8
 # C-signatur: 	unsigned long unicode_to_utf8(long u)
 # Lokal_var: 	-4(%EBP): Lagrer 4 typer "headers" for UTF-8 tegn
 #       	-8(%EBP): Holder UTF-8 representasjon
 # Registre:	%EAX: Midlertidig lagring plass
 #          	%EDX: Holder Unicode representasjon
 #          	%ECX: Counter variabelen

unicode_to_utf8:
_unicode_to_utf8:
	pushl	%ebp
	movl	%esp,%ebp
	movl	8(%ebp),%eax
	movl	$0,nbytes		# initialiserer med 0
	cmpl	$128,%eax		# 127 er største ASCII tegn
	jb	uu8_x			# ASCII-tegn !!!
	incl	nbytes
	cmpl	$2048,%eax		# 2047 er største 2-byte UTF-8
	jb	build_utf8		# 2-byte UTF-8 !!!
	incl	nbytes
	cmpl	$65536,%eax		# 65535 er største 3-byte UTF-8
	jb	build_utf8		# 3-byte UTF-8 !!!
	incl	nbytes

build_utf8:
	movl	8(%ebp),%edx		# initialiserer %EDX med Unicode tegn
	movl	$0,%ecx			# initialiserer %ECX med 0
	pushl	$0xf0e0c000		# 1st lokale variabelen ("headers")
	pushl	$0			# 2nd lokale variabelen (UTF-8)
  bu8_loop:
	cmpl	nbytes,%ecx
	jge	build_header_byte
	movb	%dl,%al			# //legge '10-header inn i denne
	orb	$0x80,%al		# //byten (med '1' på første plass,
	andb	$0xbf,%al		# //og '0' på andre plass)
	shrl	$6,%edx			# fjerner bort 6 siste bit fra tegnet
	movb	%al,-8(%ebp,%ecx,1)	# lagrer byten på stakken
	incl	%ecx
	jmp	bu8_loop
  build_header_byte:
	orb	-4(%ebp,%ecx,1),%dl	# setter inn riktig "header"
	movb	%dl,-8(%ebp,%ecx,1)	# lagrer byten på stakken
	movl	-8(%ebp),%eax		# lagrer returverdien inn i %EAX
	
uu8_x:	movl	%ebp,%esp
	popl	%ebp
	ret
	
	
#########################################################################
# writeutf8char()
#########################################################################
	
	.globl	writeutf8char
	.globl	_writeutf8char
 # Navn:	writeutf8char
 # Synopsis:	Skriver et tegn kodet som UTF-8 til en binærfil.
 # C-signatur: 	void writeutf8char (FILE *f, unsigned long u)
 # Lokal_var: 	-4(%EBP): Holder UTF-8 representasjonen
 # Registre:	%EAX: Midlertidig lagring plass
 #         	%ECX: Counter variabelen

writeutf8char:
_writeutf8char:
	pushl	%ebp
	movl	%esp,%ebp
	pushl	12(%ebp)
	call	unicode_to_utf8
	movl	%eax,(%esp)		# lokale variabelen (UTF-8)
	movl	nbytes,%ecx		
wloop:  movl	$0,%eax
	movb	-4(%ebp,%ecx,1),%al 	# flytte en spesifikk byte til %al
	pushl	%ecx			# lagre %ECX verdien
	pushl	%eax			# param2 i 'writebyte'
	pushl	8(%ebp)			# param1 i 'writebyte'
	call	writebyte		# skrive denne byten til fil
	addl	$8,%esp			# fjerner bort begge parametrene
	popl	%ecx			# få tilbake %ECX verdien
	decl	%ecx
	jns	wloop
wu8_x:	movl	%ebp,%esp
	popl	%ebp
	ret
	

#########################################################################
# readbyte()
#########################################################################	

	.globl	readbyte
	.globl	_readbyte
 # Navn:	readbyte
 # Synopsis:	Leser en byte fra en binærfil.
 # C-signatur: 	int readbyte (FILE *f)

readbyte:
_readbyte:
	pushl	%ebp	
	movl	%esp,%ebp
	pushl	$0		# plass for character 'c'
	movl	%esp,%eax	# adressen til character 'c'
	pushl	8(%ebp)		# param4 i "fread"
	pushl 	$1		# param3 i "fread"
	pushl 	$1		# param2 i "fread"
	pushl 	%eax		# param1 i "fread"
	call 	_fread		# leser byten
	addl	$16,%esp	# fjerner alle param fra stakken
	cmpl	$0,%eax
	jg	rb_x
	movl 	$-1,-4(%ebp)
rb_x:	movl	-4(%ebp),%eax
	movl	%ebp,%esp
	popl	%ebp
	ret
	
	
#########################################################################
# utf8_to_unicode()
#########################################################################
		
	.globl	utf8_to_unicode
	.globl	_utf8_to_unicode
 # Navn:	utf8_to_unicode
 # Synopsis:	Konverterer fra UTF-8 til Unicode
 # C-signatur: 	long utf8_to_unicode (unsigned long utf8, long nbytes)
 # Lokal_var:	-4(EBP): Lagrer 4 typer "headers" for UTF-8 tegn
 # Registre:	%EAX: Holder unicode representasjon
 #        	%ECX: Counter variabelen

utf8_to_unicode:
_utf8_to_unicode:
	pushl	%ebp
	movl	%esp,%ebp

convert_header_byte:
	pushl	$0xf0e0c000		# lokal variabel for å lagre "headers"
	movl	12(%ebp),%ecx		# initialiserer counteren.
	movb	-4(%ebp,%ecx,1),%al	# får tak til riktig header.
	notb	%al			# 
	andb	8(%ebp,%ecx,1),%al	# fjerne bort header
convert_next_byte:
	decl	%ecx
	js	u8u_x
	andb	$0x3f,8(%ebp,%ecx,1)	# fjerner '10-header fra denne byten.
	sall	$6,%eax			# reserverer plass for neste 6 bytes.
	orb	8(%ebp,%ecx,1),%al	# append neste 6 bytes
	jmp	convert_next_byte

u8u_x:	movl	%ebp,%esp
	popl	%ebp
	ret	
	

#########################################################################
# readutf8char()
#########################################################################
			
	.globl	readutf8char
	.globl	_readutf8char
 # Navn:	readutf8char
 # Synopsis:	Leser et Unicode-tegn fra en binærfil.
 # C-signatur: 	long readutf8char (FILE *f)
 # Registre:	%EAX: Holder returverdien fra "readbyte"
 #         	%ECX: Counter variabelen
 #         	%EDX: Holder hele UTF-8 tegnet som var lest fra filen

readutf8char:
_readutf8char:
	pushl	%ebp
	movl	%esp,%ebp
	
read_header_byte:
	pushl	8(%ebp)
	call	readbyte
	addl	$4,%esp
	cmpl	$-1,%eax
	je	ru8_x
  rhb_switch:
	movl	$0,nbytes	# initialiserer med 0
	testb	$0x80,%al	# test første bit (fra venstre)
	jz	ru8_x		# ASCII-char !!!
	incl	nbytes
	testb	$0x20,%al	# test tredje bit (fra venstre)
	jz	read_next_byte	# 2-byte utf8 !!!
	incl	nbytes
	testb	$0x10,%al	# test fjerde bit (fra venstre)
	jz	read_next_byte	# 3-byte utf8 !!!
	incl	nbytes
	
read_next_byte:
	movl	nbytes,%ecx
  rnb_loop:
	movb	%al,%dl
	decl	%ecx
	js	convert_u8u	# jump når hele utf8 tegnet er ferdig lest
	pushl	%edx		# lagre %edx nåværende verdien 
	pushl	%ecx		# lagre %ecx nåværende verdien
	pushl	8(%ebp)		# param1 i "readbyte"
	call	readbyte	# leser neste byte fra filen
	addl	$4,%esp		# fjerner param1 fra stakken
	popl	%ecx		# setter tilbake opprinnelige verdien til %ECX
	popl	%edx		# setter tilbake opprinnelige verdien til %EDX
	sall	$8,%edx		# reserverer plass for neste byten
	jmp	rnb_loop

convert_u8u:
	pushl	nbytes		# param2 i "utf8_to_unicode"
	pushl	%edx		# param1 i "utf8_to_unicode"
	call 	utf8_to_unicode	# konverterer tegnet til unicode
	addl	$8,%esp		# fjerner begge parametrene fra stakken
	
ru8_x:	popl	%ebp
	ret
	