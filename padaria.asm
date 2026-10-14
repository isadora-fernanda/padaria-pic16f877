;*---------------------------------------------------------------------------------------------*
;Nome: Isadora F. Z. Schmidt
;Codigo: Projeto final      Data: 16/12/2021
;Descricao: Uma simulacao simples de padaria que possui somente 4 opcoes:
;			Coxinha (representado no teclado pelo '+')
;			Esfirra (representado no teclado pelo '-')
;			Pastel	(representado no teclado pelo 'x')
;			Quibe	(representado no teclado pelo ':')
;			Cada opcao possui um preco. Quando a opcao e a qtde sao selecionadas, elas sao
;			multiplicadas e, ao apertar o igual, aparece o valor a ser pago.
;			O valor a ser pago e armazenado na memoria EEPROM, e pode ser obtido atraves do B1.
;			A quantidade de cada opcao e o preco podem ser vistos ao apertar o B2.
;			O 'resistor' da divisor de tensao do B1 e um potenciometro, assim, ao aumentar ou
;			diminuir a resistencia, o brilho do LED atrelado ao B1 muda.
;			O potenciometro esta conectado a um osciloscopio, que recebe a conversao A/D da
;			resistencia.
;*---------------------------------------------------------------------------------------------*


; ARQUIVO PIC16F788 INCLUIDO NO PROJETO
#include <P16F877.INC>

; CONFIGURACOES INICIAIS DO PIC16F788
__config _XT_OSC & _WDT_OFF & _LVP_OFF & _DEBUG_ON & _BODEN_OFF

; CRIACAO DE QUATRO MACROS, SELECIONANDO O BANK 0, BANK 1, BANK 2 E BANK 3
BANK0	macro
				bcf STATUS, RP1 ;
				bcf	STATUS, RP0 ; Seleciona o Bank 0 da memoria de dados
		endm

BANK1	macro
				bcf STATUS, RP1 ;
				bsf	STATUS, RP0 ; Seleciona o Bank 1 da memoria de dados
		endm

BANK2	macro
				bsf STATUS, RP1 ;
				bcf	STATUS, RP0 ; Seleciona o Bank 2 da memoria de dados
		endm

BANK3	macro
				bsf STATUS, RP1 ;
				bsf	STATUS, RP0 ; Seleciona o Bank 3 da memoria de dados
		endm

; CRIACAO DAS VARIAVEIS AUXILIARES A PARTIR DO ENDERECO 0x20
  cblock 0x20
	W_TEMP			;
	STATUS_TEMP		; Interrupcoes
	TEMP			;
	TEMP2			;
	TEMP3			;
	TEMP4			; Delays
	ADDR1			; EEPROM
	FLAG			; Flag
	DIG_AUX			;
	DIGITO			; Auxiliares
	DIG1			; Armazena quantidade
	DIG2			;
	DIG3			;
	DIG4			;
	DIG5			; Armazenam precos
	RESUL			; Armazena pagamento
	RESUL_EEPROM	; Armazena pagamento EEPROM
	R0				;
	R1				; Auxiliares de multiplicacao
  endc

; NOMEANDO ENTRADAS
 #define C1 PORTB, 0
 #define C2 PORTB, 1
 #define C3 PORTB, 2
 #define C4 PORTB, 3
 #define L1 PORTC, 7
 #define L2 PORTC, 6
 #define L3 PORTC, 5
 #define L4 PORTC, 4
 #define B1 PORTB, 7 ; Botao EEPROM
 #define B2 PORTB, 6 ; Botao mensagem de qtd salgados

; CRIACAO DAS CONSTANTES T1, T2 E T3
 T1 EQU .200
 T2 EQU .50
 T3 EQU .20
 T4 EQU .15

; NOMEANDO VARIAVEIS PARA ROTINAS DO LCD
 #define RS PORTE, RE0
 #define E PORTE, RE1
 #define DISPLAY PORTD

; NOMEANDO FLAGS DE SALGADOS
 #define COX FLAG, 0
 #define ESF FLAG, 1
 #define PAS FLAG, 2
 #define QUI FLAG, 3

; FORCA O PROGRAMA A COMECAR A PARTIR DO ENDERECO 0x00
  org 0x00
  goto INICIO

; INICIO DA INTERRUPCAO
  org 0x04						; Endereco inicio interrupcao
 
	MOVWF W_TEMP				; Copia W para W_TEMP
	swapf STATUS, W				; Move o conteudo de STATUS para W com os nibbles invertidos
	MOVWF STATUS_TEMP			; Copia o conteudo de W para STATUS_TEMP (ou seja, o conteudo de STATUS com nibbles trocados)

; Rotina de interrupcao, reconhecimento e tratamento das mesmas
; A interrupcao e gerada pelo termino da conversao A/D
 TRAT_INT:
	bcf	INTCON, GIE				; Desabilita a interrupcao global
	btfss PIR1, ADIF			; Testa a flag que indica finalizacao da conversao A/D
	goto SAI_INT				; Se flag ADIF = 0, nao finalizou a conversao A/D
	MOVFW ADRESH				; Move o conteudo (8 bits mais significativos) obtido da conversão A/D para W
	MOVWF CCPR1L				; Move W para CCPR1L que seta o Duty Cicle
	bcf PIR1, ADIF				; Limpa a flag que indica finalizacao da conversao A/D

; Rotina de saida da interrupcao, recuperacao do conteudo de W e STATUS
SAI_INT:
	swapf STATUS_TEMP, W		; Move o conteudo de STATUS_TEMP para W com os nibbles trocados (anterior a interrupcao)
	MOVWF STATUS				; Recupera o conteudo de STATUS anterior a interrupcao
	swapf W_TEMP, F				; Move o conteudo de W_TEMP para ele mesmo com os nibbles trocados
	swapf W_TEMP, W				; Move o conteudo de W_TEMP para W com os nibbles trocados (recupera W anterior a interrupcao)
	bsf INTCON, GIE				; Habilita interrupcao global
retfie

; ROTINAS DE DELAY
DELAY:
	MOVLW	T1										; Inicia a contagem em T1
	MOVWF	TEMP
	decfsz  TEMP									; Se igual a 0, pula uma linha
	goto	$-.1									; Retorna a linha anterior
return

DELAY2:
	MOVLW   T2										; Inicia a contagem em T2
	MOVWF	TEMP2
	call	DELAY
	decfsz	TEMP2									; Se igual a 0, pula uma linha
	goto	$-.2									; Retorna a linha anteanterior
return

DELAY3:
	MOVLW   T3										; Inicia a contagem em T3
	MOVWF	TEMP3
	call	DELAY2
	decfsz	TEMP3									; Se igual a 0, pula uma linha
	goto	$-.2									; Retorna a linha anteanterior
return

DELAY4:
	MOVLW   T4										; Inicia a contagem em T4
	MOVWF	TEMP4
	call	DELAY3
	decfsz	TEMP4									; Se igual a 0, pula uma linha
	goto	$-.2									; Retorna a linha anteanterior
return

; ROTINA PARA ENVIAR INSTRUCAO PARA O LCD
LCD_COMANDO:
	bcf		RS			; Seleciona para instrucao
	MOVWF	DISPLAY		; Move instrucao para o display
	call	ENABLE		; Manda um pulso
	call	DELAY2		; Espera um tempo
return

; ROTINA PARA ENVIAR DADOS PARA O LCD
LCD_CARACTER:
	bsf		RS			; Seleciona para dado
	MOVWF	DISPLAY		; Move caracter para o display
	call	ENABLE		; Manda um pulso
	call	DELAY2		; Espera um tempo
return

; ROTINA PARA MANDAR UM PULSO PARA O LCD
ENABLE:
	bsf E
	call DELAY2
	bcf E
return

; ROTINA PARA INICIALIZAR O LCD
LCD_INICIO:
; Function Set
	MOVLW b'00111100'								; 8 bits, 2 linhas
	call LCD_COMANDO								; Manda comando

; Display On/Off Control
	MOVLW b'00001100'								; Display liga, cursor nao liga e nao pisca
	call LCD_COMANDO								; Manda comando

; Display Clear
	MOVLW b'00000001'								; Limpa o display
	call LCD_COMANDO								; Manda comando

; Entry Mode Set
	MOVLW b'00000110'								; Cursor se move para direita e a mensagem e deslocada
	call LCD_COMANDO								; Manda comando
return

; ROTINA PARA LIMPAR O LCD
LCD_CLEAR:
	MOVLW b'00000001'								; Limpa o display
	call LCD_COMANDO								; Manda comando
return

; ROTINA PARA VERIFICAR QUE TECLA FOI APERTADA DO PINPAD
VERIFICA_OP:
	bcf		L1					; Habilita a linha 1 do teclado
	call	DELAY
	btfss	C2					; Verifica se o dígito 0 foi acionado
	goto	ACIONOU_0
	btfss	C3					; Verifica se o digito = foi acionado
	goto	ACIONOU_IGUAL
	btfss	C4					; Verifica se o digito + foi acionado
	goto	ACIONOU_COX
	bsf		L1					; Desabilita a linha 1 do teclado

	bcf		L2					; Habilita a linha 2 do teclado
	call	DELAY
	btfss	C1					; Verifica se o dígito 1 foi acionado
	goto	ACIONOU_1
	btfss	C2					; Verifica se o dígito 2 foi acionado
	goto	ACIONOU_2
	btfss	C3					; Verifica se o dígito 3 foi acionado
	goto	ACIONOU_3
	btfss	C4					; Verifica se o digito - foi acionado
	goto	ACIONOU_ESF
	bsf		L2					; Desabilita a linha 2 do teclado

	bcf		L3					; Habilita a linha 3 do teclado
	call	DELAY
	btfss	C1					; Verifica se o dígito 4 foi acionado
	goto	ACIONOU_4
	btfss	C2					; Verifica se o dígito 5 foi acionado
	goto	ACIONOU_5
	btfss	C3					; Verifica se o dígito 6 foi acionado
	goto	ACIONOU_6
	btfss	C4					; Verifica se o digito x foi acionado
	goto	ACIONOU_PAS
	bsf		L3					; Desabilita a linha 3 do teclado

	bcf		L4					; Habilita a linha 4 do teclado
	call	DELAY
	btfss	C1					; Verifica se o dígito 7 foi acionado
	goto	ACIONOU_7
	btfss	C2					; Verifica se o dígito 8 foi acionado
	goto	ACIONOU_8
	btfss	C3					; Verifica se o dígito 9 foi acionado
	goto	ACIONOU_9
	btfss	C4					; Verifica se o digito / foi acionado
	goto	ACIONOU_QUI
	bsf		L4					; Desabilita a linha 4 do teclado
goto	VERIFICA_OP				; Aguarda acionar alguma operacao
	
; ROTINA PARA TRATAMENTO DE OPERACOES ACIONADAS
ACIONOU_COX: ; Coxinha, 1 real por unidade
	MOVLW	'C'
	call	LCD_CARACTER
	MOVLW	'O'
	call	LCD_CARACTER
	MOVLW	'X'
	call	LCD_CARACTER
	MOVLW	'I'
	call	LCD_CARACTER
	MOVLW	'N'
	call	LCD_CARACTER
	MOVLW	'H'
	call	LCD_CARACTER
	MOVLW	'A'
	call	LCD_CARACTER
	bsf		COX					; Seta a flag da multiplicacao da coxinha
	call	OP_DIGITOS			; Chama funcao que faz a leitura e escrita no LCD da qtd digitada
	goto	OP_COX				; Faz a multiplicacao
return

ACIONOU_ESF: ; Esfirra, 3 reais por unidade
	MOVLW	'E'
	call	LCD_CARACTER
	MOVLW	'S'
	call	LCD_CARACTER
	MOVLW	'F'
	call	LCD_CARACTER
	MOVLW	'I'
	call	LCD_CARACTER
	MOVLW	'R'
	call	LCD_CARACTER
	MOVLW	'R'
	call	LCD_CARACTER
	MOVLW	'A'
	call	LCD_CARACTER
	bsf		ESF					; Seta a flag da multiplicacao da esfirra
	call	OP_DIGITOS			; Chama funcao que faz a leitura e escrita no LCD da qtd digitada
	goto	OP_ESF				; Faz a multiplicacao
return

ACIONOU_PAS: ; Pastel, 2 reais por unidade
	MOVLW	'P'
	call	LCD_CARACTER
	MOVLW	'A'
	call	LCD_CARACTER
	MOVLW	'S'
	call	LCD_CARACTER
	MOVLW	'T'
	call	LCD_CARACTER
	MOVLW	'E'
	call	LCD_CARACTER
	MOVLW	'L'
	call	LCD_CARACTER
	bsf		PAS					; Seta a flag da multiplicacao do pastel
	call	OP_DIGITOS			; Chama funcao que faz a leitura e escrita no LCD da qtd digitada
	goto	OP_PAS				; Faz a multiplicacao
return

ACIONOU_QUI: ; Quibe, 2 reais por unidade
	MOVLW	'Q'
	call	LCD_CARACTER
	MOVLW	'U'
	call	LCD_CARACTER
	MOVLW	'I'
	call	LCD_CARACTER
	MOVLW	'B'
	call	LCD_CARACTER
	MOVLW	'E'
	call	LCD_CARACTER
	bsf		QUI					; Seta a flag da multiplicacao do quibe
	call	OP_DIGITOS			; Chama funcao que faz a leitura e escrita no LCD da qtd digitada
	goto	OP_QUI				; Faz a multiplicacao
return

ACIONOU_IGUAL: ; Total a pagar
	call	EEPROM_ESCRITA		; Chama a funcao que escreve o pagamento na EEPROM
	call	LCD_CLEAR
	call	LCD_RESUL			; Chama a funcao que escreve o pagamento no DISPLAY
	goto	MAIN
return

; ROTINA PARA TRATAMENTO DE NUMEROS ADICIONADOS
ACIONOU_0:
	btfss	C2					; Verifica novamente a tecla 0
	goto	$-.1				; Aguarda soltar a tecla
	MOVLW	.0
	MOVWF	DIGITO				; Move o valor para DIGITO
	MOVLW	'0'					; Move o literal '0' para W
	call	LCD_CARACTER		; Escreve o literal no LCD
return

ACIONOU_1:
	btfss	C1					; Verifica novamente a tecla 1
	goto	$-.1				; Aguarda soltar a tecla
	MOVLW	.1
	MOVWF	DIGITO				; Move o valor para DIGITO
	MOVLW	'1'					; Move o literal '1' para W
	call	LCD_CARACTER		; Escreve o literal no LCD
return

ACIONOU_2:
	btfss	C2					; Verifica novamente a tecla 2
	goto	$-.1				; Aguarda soltar a tecla
	MOVLW	.2
	MOVWF	DIGITO				; Move o valor para DIGITO
	MOVLW	'2'					; Move o literal '2' para W
	call	LCD_CARACTER		; Escreve o literal no LCD
return

ACIONOU_3:
	btfss	C3					; Verifica novamente a tecla 3
	goto	$-.1				; Aguarda soltar a tecla
	MOVLW	.3
	MOVWF	DIGITO				; Move o valor para DIGITO
	MOVLW	'3'					; Move o literal '3' para W
	call	LCD_CARACTER		; Escreve o literal no LCD
return

ACIONOU_4:
	btfss	C1					; Verifica novamente a tecla 4
	goto	$-.1				; Aguarda soltar a tecla
	MOVLW	.4
	MOVWF	DIGITO				; Move o valor para DIGITO
	MOVLW	'4'					; Move o literal '4' para W
	call	LCD_CARACTER		; Escreve o literal no LCD
return

ACIONOU_5:
	btfss	C2					; Verifica novamente a tecla 5
	goto	$-.1				; Aguarda soltar a tecla
	MOVLW	.5
	MOVWF	DIGITO				; Move o valor para DIGITO
	MOVLW	'5'					; Move o literal '5' para W
	call	LCD_CARACTER		; Escreve o literal no LCD
return

ACIONOU_6:
	btfss	C3					; Verifica novamente a tecla 6
	goto	$-.1				; Aguarda soltar a tecla
	MOVLW	.6
	MOVWF	DIGITO				; Move o valor para DIGITO
	MOVLW	'6'					; Move o literal '6' para W
	call	LCD_CARACTER		; Escreve o literal no LCD
return

ACIONOU_7:
	btfss	C1					; Verifica novamente a tecla 7
	goto	$-.1				; Aguarda soltar a tecla
	MOVLW	.7
	MOVWF	DIGITO				; Move o valor para DIGITO
	MOVLW	'7'					; Move o literal '7' para W
	call	LCD_CARACTER		; Escreve o literal no LCD
return

ACIONOU_8:
	btfss	C2					; Verifica novamente a tecla 8
	goto	$-.1				; Aguarda soltar a tecla
	MOVLW	.8
	MOVWF	DIGITO				; Move o valor para DIGITO
	MOVLW	'8'					; Move o literal '8' para W
	call	LCD_CARACTER		; Escreve o literal no LCD
return

ACIONOU_9:
	btfss	C3					; Verifica novamente a tecla 9
	goto	$-.1				; Aguarda soltar a tecla
	MOVLW	.9
	MOVWF	DIGITO				; Move o valor para DIGITO
	MOVLW	'9'					; Move o literal '9' para W
	call	LCD_CARACTER		; Escreve o literal no LCD
return

; ROTINA DE OPERACOES
OP_DIGITOS: ; Salva a qtd digitada
	call	DELAY3				; Espera um tempo
	MOVLW	.1
	MOVWF	DIG_AUX				; Move W para DIG_AUX
	call	MEN_DIG
	call	VERIFICA_OP			; Obtem a qtde em DIGITO
	MOVFW	DIGITO				; Move DIGITO para W
	MOVWF	DIG1				; Move a qtde para o registrador DIG1
return

OP_COX: ; Multiplica a qtde por 1 (valor da coxinha e 1 real)
	MOVFW	DIG1				; Move para W a qtde
	MOVWF	R0					; Move para o segundo dígito do resultado o valor do DIG1

	CONT_MULT1:
	decf	DIG2, F				; Decrementa o DIG2 (nesse caso, 1) e armazena nele mesmo
	btfsc	STATUS, Z			; Testa flag Z. Se Z = 1, DIG2 = 0
	goto	RESUL_OP			; Vai para o retorno do resultado da operacao
	MOVFW	DIG1				; Move para W a qtde (DIG1)
	addwf	R0, F				; Soma o R0 com o DIG1 e armazena o resultado em R0
	btfsc	STATUS, C			; Testa o carry. Se C = 1, houve transbordo de R0
	incf	R1, F				; Incrementa R1 e armazena nele mesmo
	goto	CONT_MULT1			; Se nao houve transbordo, continua o processo
return

OP_ESF: ; Multiplica a qtde por 3 (valor da esfirra e 3 reais)
	MOVFW	DIG1				; Move para W a qtde
	MOVWF	R0					; Move para o segundo dígito do resultado o valor do DIG1

	CONT_MULT2:
	decf	DIG3, F				; Decrementa o DIG3 (nesse caso, 3) e armazena nele mesmo
	btfsc	STATUS, Z			; Testa flag Z. Se Z = 1, DIG3 = 0
	goto	RESUL_OP			; Vai para o retorno do resultado da operacao
	MOVFW	DIG1				; Move para W a qtde (DIG3)
	addwf	R0, F				; Soma o R0 com o DIG1 e armazena o resultado em R0
	btfsc	STATUS,C			; Testa o carry. Se C = 1, houve transbordo de R0
	incf	R1, F				; Incrementa R1 e armazena nele mesmo
	goto	CONT_MULT2			; Se nao houve transbordo, continua o processo
return

OP_PAS: ; Multiplica a qtde por 2 (valor do pastel e 2 reais)
	MOVFW	DIG1				; Move para W a qtde
	MOVWF	R0					; Move para o segundo dígito do resultado o valor do DIG1

	CONT_MULT3:
	decf	DIG4, F				; Decrementa o DIG4 (nesse caso, 2) e armazena nele mesmo
	btfsc	STATUS, Z			; Testa flag Z. Se Z = 1, DIG4 = 0
	goto	RESUL_OP			; Vai para o retorno do resultado da operacao
	MOVFW	DIG1				; Move para W a qtde (DIG4)
	addwf	R0, F				; Soma o R0 com o DIG1 e armazena o resultado em R0
	btfsc	STATUS, C			; Testa o carry. Se C = 1, houve transbordo de R0
	incf	R1, F				; Incrementa R1 e armazena nele mesmo
	goto	CONT_MULT3			; Se nao houve transbordo, continua o processo
return

OP_QUI: ; Multiplica a qtde por 1 (valor do quibe e 1 reais)
	MOVFW	DIG1				; Move para W a qtde
	MOVWF	R0					; Move para o segundo dígito do resultado o valor do DIG1

	CONT_MULT4:
	decf	DIG5, F				; Decrementa o DIG5 (nesse caso, 1) e armazena nele mesmo
	btfsc	STATUS, Z			; Testa flag Z. Se Z = 1, DIG5 = 0
	goto	RESUL_OP			; Vai para o retorno do resultado da operacao
	MOVFW	DIG1				; Move para W a qtde (DIG5)
	addwf	R0, F				; Soma o R0 com o DIG1 e armazena o resultado em R0
	btfsc	STATUS, C			; Testa o carry. Se C = 1, houve transbordo de R0
	incf	R1, F				; Incrementa R1 e armazena nele mesmo
	goto	CONT_MULT4			; Se nao houve transbordo, continua o processo
return

RESUL_OP: ; Armazena resultado para ser mostrado no LCD
	MOVFW	R0					; Move o resultado (dígito menos significativo) para W
	MOVWF	RESUL				; Move o valor menos significativo operação para W
	goto	VERIFICA_OP			; Chama funcao para clicar na tecla =
return

; ROTINA DE LEITURA DA EEPROM
EEPROM_LEITURA:
	MOVFW	ADDR1									; Move para W o endereco alvo (resultado)

BANK2												; Seleciona o Bank 2 de memoria de dados

	MOVWF	EEADR									; Move para o registrador EEADR o endereco a ser lido

BANK3												; Seleciona o Bank 3 de memoria de dados

	bcf	EECON1, EEPGD								; Seleciona a memoria de dados EEPROM
	bsf	EECON1, RD									; Inicia a operacao de leitura

BANK2												; Seleciona o Bank 2 de memoria de dados

	MOVFW	EEDATA									; Move para W o valor lido no endereco ADDR1 que estava armazenado em EEDATA

BANK0												; Seleciona o Bank 0 de memoria de dados
return

; ROTINA DE ESCRITA NA EEPROM
EEPROM_ESCRITA:
BANK3												; Seleciona o Bank 3 de memoria de dados

	btfsc	EECON1, WR								; Verifica se esta ocorrendo o processo de escrita
	goto	$-.1									; Retorna o teste ate finalizar o processo de escrita

BANK0												; Seleciona o Bank 0 de memoria de dados

	MOVFW	ADDR1									; Move para W o endereco alvo

BANK2												; Seleciona o Bank 2 de memoria de dados

	MOVWF	EEADR									; Move o endereco a ser escrito para o registrador EEADR

BANK0												; Seleciona o Bank 0 de memoria de dados

	MOVFW	RESUL									; Move para W o dado a ser escrito

BANK2												; Seleciona o Bank 2 de memoria de dados

	MOVWF	EEDATA									; Move o dado a ser escrio para o registrador EEDATA

BANK3												; Seleciona o Bank 3 de memoria de dados

	bcf		EECON1, EEPGD							; Seleciona a memoria de dados EEPROM
	bsf		EECON1, WREN							; Habilitando o processo de escrita
	MOVLW	0x55									; Instrucoes necessarias
	MOVWF	EECON2
	MOVLW	0xAA
	MOVWF	EECON2
	bsf		EECON1, WR								; Inicia a operacao de escrita
	btfsc	EECON1, WR								; Aguarda enquanto a operacao esta sendo realizada
	goto	$-.1
	bcf		EECON1,WREN								; Desabilita a escrita

BANK0												; Seleciona o Bank 0 de memoria de dados
return

; ROTINAS DE CONVERSAO A/D
TESTE:						; Verifica se ja foi feita a conversao
	btfsc ADCON0, 2			; Se ADCON0, 2 for 0 pula uma linha
	goto TESTE				; Volta para teste
return

CONVERSAO:					; Realiza a conversao
BANK0						; Seleciona o Bank 0 de memoria de dados

	MOVF ADRESH, W			; Move valor lido na conversao para o W
	MOVWF CCPR1L			; Coloca o valor da conversao em CCPR1L
return

; ROTINA PARA TRATAMENTO DO BOTAO DA EEPROM
BOTAO_EEPROM:
	btfsc	B1										; Verifica se o botao B1 foi acionado
return
	btfss	B1										; Aguarda soltar o botao
	goto	$-.1
	call	EEPROM_LEITURA							; Chama subrotina que faz a leitura do resultado
	MOVWF	RESUL_EEPROM							; Move o resultado para o registrador auxiliar
	call	LCD_EEPROM								; Apresenta no display
	call	DELAY3
	goto	MAIN
return

; INICIO DO PROGRAMA
INICIO:
	clrf PORTA ;
	clrf PORTB ;
	clrf PORTC ;
	clrf PORTD ;
	clrf PORTE ; Limpando as portas	

BANK1 ; Seleciona o Bank 1 de memoria de dados

	clrf TRISC ;
	clrf TRISD ;
	clrf TRISE ; Selecionando as saidas

	MOVLW b'11111111'	;
	MOVWF TRISA			;
	MOVLW b'11111111'	;
	MOVWF TRISB			; Selecionando as entradas

	MOVLW b'11000000'	;
	MOVWF INTCON		; Interrupcao global por perifericos habilitada

	MOVLW b'00000111'	;
	MOVWF OPTION_REG	; Prescaler atribuído ao TMR0 (1:256)

	bsf ADCON1, 2 ; Configura portas analogicas e digitais

	MOVLW D'255'		;
	MOVWF PR2			; Configura o periodo de PWM

BANK0 ; Seleciona o Bank 0 de memoria de dados

 	MOVLW b'10000001'	;
 	MOVWF ADCON0		; Configura para Fosc/32, e ADON 1

 	clrf CCPR1L	; Configuracao inicial de CCPR1L como 0 (lampada apagada)

	MOVLW b'00001100'	;
	MOVWF CCP1CON		; Configura CCP1CON para PWM	

	MOVLW b'00000110'	;
	MOVWF T2CON			; Configura TMR2 (ligado) prescaler 1:16

; LIMPEZA DA RAM
	MOVLW 0x20					; Limpeza de toda a RAM do BANK0, indo de 0x20 a 0x7F
	MOVWF FSR					; Aponta o enderecamento indireto para a primeira posicao da RAM
LIMPA_RAM:
	clrf INDF					; Limpa a posicao atual
	incf FSR, F					; Incrementa ponteiro para a proxima posicao
	MOVF FSR, W
	xorlw 0x80					; Compara ponteiro com a ultima posicao +1
	btfss STATUS, Z				; Verifica se limpou todas as posicoes
	goto LIMPA_RAM				; Se nao, limpa a proxima posicao
								; Se sim, continua o programa

; INICIALIZA AS VARIAVEIS
	MOVLW b'11110000'			; Move literal para W
	MOVWF PORTC					; Inicia com linhas do teclado desabilitadas

BANK3 ; Seleciona o Bank 3 de memoria de dados
	bcf EECON1, WRERR			; Bit WRERR deve ser limpo apo o RESET
BANK0 ; Seleciona o Bank 0 de memoria de dados

	MOVLW 0X01					; Move literal para W
	MOVWF ADDR1					;Determina o endereço ADDR1 = 0x00 que armazena a qtde

	clrf FLAG			;
	clrf DIGITO			;
	clrf DIG_AUX		;
	clrf DIG1			;
	clrf DIG2			;
	clrf DIG3			;
	clrf DIG4			;
	clrf DIG5			;
	clrf RESUL			;
	clrf RESUL_EEPROM	;
	clrf R0				;
	clrf R1				; Inicializa com os registradores definidos limpos

	MOVLW .1					; Move literal para W
	MOVWF DIG2					; DIG2 recebe 1
	MOVLW .3					; Move literal para W
	MOVWF DIG3					; DIG3 recebe 3
	MOVLW .2					; Move literal para W
	MOVWF DIG4					; DIG4 recebe 2
	MOVLW .1					; Move literal para W
	MOVWF DIG5					; DIG5 recebe 1

call	LCD_INICIO

; ROTINA PRINCIPAL
MAIN
	bsf ADCON0, 2				; Ativa a conversao A/D
	call TESTE					; Verifica se ja ativou a conversao A/D
	call CONVERSAO				; Converte
	call BOTAO_EEPROM			; Verifica se o botao da EEPROM foi acionado
	call BOTAO_MENSAGEM			; Verifica se o botao da qtde de salgados foi acionado

	VERIFICA_ON:						; Label de verificacao do botao de ligar
		bcf		L1						; Habilita linha 1
		call	DELAY
		btfsc	C1						; Verifica se o botao de ligar foi acionado
		goto 	MAIN
		btfss	C1						; Espera soltar o botao
		goto	$-.1
		bsf		L1						; Desabilita a linha 1
		ACIONOU_ON:
			call	MEN_ON				; Mensagem inicial
			goto	VERIFICA_OP			; Espera comando
goto	MAIN

; ROTINAS PARA MANDAR MENSAGENS PARA O LCD
MEN_ON:							; Escreve no LCD mensagem pedindo o tipo de 'SALGADO'
	call	LCD_CLEAR			; Limpa o display

	MOVLW	'S'
	call	LCD_CARACTER
	MOVLW	'A'
	call	LCD_CARACTER
	MOVLW	'L'
	call	LCD_CARACTER
	MOVLW	'G'
	call	LCD_CARACTER
	MOVLW	'A'
	call	LCD_CARACTER
	MOVLW	'D'
	call	LCD_CARACTER
	MOVLW	'O'
	call	LCD_CARACTER
	MOVLW	':'
	call	LCD_CARACTER
	MOVLW	' '
	call	LCD_CARACTER
return

MEN_DIG:						; Escreve no LCD mensagem pedindo 'QUANTIDADE' do salgado
	MOVLW 	b'11000000'			; Seleciona a segunda linha
	call	LCD_COMANDO

	MOVLW	'Q'
	call	LCD_CARACTER
	MOVLW	'U'
	call	LCD_CARACTER
	MOVLW	'A'
	call	LCD_CARACTER
	MOVLW	'N'
	call	LCD_CARACTER
	MOVLW	'T'
	call	LCD_CARACTER
	MOVLW	'O'
	call	LCD_CARACTER
	MOVLW	'S'
	call	LCD_CARACTER
	MOVLW	':'
	call	LCD_CARACTER
	MOVLW	' '
	call	LCD_CARACTER
return

LCD_RESUL:						; Escreve no LCD mensagem mostrando o 'PAGAMENTO' a ser feito
	call	LCD_CLEAR			; Limpar o display

	MOVLW	'P'
	call	LCD_CARACTER
	MOVLW	'A'
	call	LCD_CARACTER
	MOVLW	'G'
	call	LCD_CARACTER
	MOVLW	'A'
	call	LCD_CARACTER
	MOVLW	'M'
	call	LCD_CARACTER
	MOVLW	'E'
	call	LCD_CARACTER
	MOVLW	'N'
	call	LCD_CARACTER
	MOVLW	'T'
	call	LCD_CARACTER
	MOVLW	'O'
	call	LCD_CARACTER
	MOVLW	':'
	call	LCD_CARACTER
	MOVLW	' '
	call	LCD_CARACTER
	MOVFW	RESUL
	addlw	.48
	call	LCD_CARACTER
return

LCD_EEPROM:						; Escreve no LCD mensagem mostrando o 'PAGAMENTO' a ser feito armazenado na EEPROM
	call	LCD_CLEAR			; Limpar o display

	MOVLW	'P'
	call	LCD_CARACTER
	MOVLW	'A'
	call	LCD_CARACTER
	MOVLW	'G'
	call	LCD_CARACTER
	MOVLW	'A'
	call	LCD_CARACTER
	MOVLW	'M'
	call	LCD_CARACTER
	MOVLW	'E'
	call	LCD_CARACTER
	MOVLW	'N'
	call	LCD_CARACTER
	MOVLW	'T'
	call	LCD_CARACTER
	MOVLW	'O'
	call	LCD_CARACTER
	MOVLW	':'
	call	LCD_CARACTER
	MOVLW	' '
	call	LCD_CARACTER
	MOVFW	RESUL_EEPROM
	addlw	.48
	call	LCD_CARACTER
return

BOTAO_MENSAGEM:					; Escreve no LCD a qtd disponivel de salgados quando o botao B2 for pressionado
	btfsc	B2					; Verifica se o botao B2 foi acionado
	return
	btfss	B2					; Aguarda soltar o botao
	goto	$-.1

	call	LCD_CLEAR			; Limpa o display

	MOVLW	'C'
	call	LCD_CARACTER
	MOVLW	'O'
	call	LCD_CARACTER
	MOVLW	'X'
	call	LCD_CARACTER
	MOVLW	' '
	call	LCD_CARACTER
	MOVLW	'9'
	call	LCD_CARACTER
	MOVLW	'U'
	call	LCD_CARACTER
	MOVLW	' '
	call	LCD_CARACTER
	MOVLW	'E'
	call	LCD_CARACTER
	MOVLW	'S'
	call	LCD_CARACTER
	MOVLW	'F'
	call	LCD_CARACTER
	MOVLW	' '
	call	LCD_CARACTER
	MOVLW	'3'
	call	LCD_CARACTER
	MOVLW	'U'
	call	LCD_CARACTER

	MOVLW 	b'11000000'			; Seleciona a segunda linha
	call	LCD_COMANDO

	MOVLW	'P'
	call	LCD_CARACTER
	MOVLW	'A'
	call	LCD_CARACTER
	MOVLW	'S'
	call	LCD_CARACTER
	MOVLW	' '
	call	LCD_CARACTER
	MOVLW	'4'
	call	LCD_CARACTER
	MOVLW	'U'
	call	LCD_CARACTER
	MOVLW	' '
	call	LCD_CARACTER
	MOVLW	'Q'
	call	LCD_CARACTER
	MOVLW	'U'
	call	LCD_CARACTER
	MOVLW	'I'
	call	LCD_CARACTER
	MOVLW	' '
	call	LCD_CARACTER
	MOVLW	'9'
	call	LCD_CARACTER
	MOVLW	'U'
	call	LCD_CARACTER
	
	call	DELAY4

	call	LCD_CLEAR			; Limpa o display

	MOVLW	'C'
	call	LCD_CARACTER
	MOVLW	'O'
	call	LCD_CARACTER
	MOVLW	'X'
	call	LCD_CARACTER
	MOVLW	' '
	call	LCD_CARACTER
	MOVLW	'1'
	call	LCD_CARACTER
	MOVLW	'R'
	call	LCD_CARACTER
	MOVLW	'$'
	call	LCD_CARACTER
	MOVLW	' '
	call	LCD_CARACTER
	MOVLW	'E'
	call	LCD_CARACTER
	MOVLW	'S'
	call	LCD_CARACTER
	MOVLW	'F'
	call	LCD_CARACTER
	MOVLW	' '
	call	LCD_CARACTER
	MOVLW	'3'
	call	LCD_CARACTER
	MOVLW	'R'
	call	LCD_CARACTER
	MOVLW	'$'
	call	LCD_CARACTER

	MOVLW 	b'11000000'			; Seleciona a segunda linha
	call	LCD_COMANDO

	MOVLW	'P'
	call	LCD_CARACTER
	MOVLW	'A'
	call	LCD_CARACTER
	MOVLW	'S'
	call	LCD_CARACTER
	MOVLW	' '
	call	LCD_CARACTER
	MOVLW	'2'
	call	LCD_CARACTER
	MOVLW	'R'
	call	LCD_CARACTER
	MOVLW	'$'
	call	LCD_CARACTER
	MOVLW	' '
	call	LCD_CARACTER
	MOVLW	'Q'
	call	LCD_CARACTER
	MOVLW	'U'
	call	LCD_CARACTER
	MOVLW	'I'
	call	LCD_CARACTER
	MOVLW	' '
	call	LCD_CARACTER
	MOVLW	'1'
	call	LCD_CARACTER
	MOVLW	'R'
	call	LCD_CARACTER
	MOVLW	'$'
	call	LCD_CARACTER

	goto MAIN
return

END

; COMENTARIOS SOBRE O TRABALHO
; Nesse trabalho foi utilizado um PIC16f877, um LCD, um teclado, um potenciometro, um osciloscopio dois LEDS e dois botoes
; O objetivo e mostrar no LCD a qtde de lanche disponiveis, seu preco, e, apos a escolha de algum, mostrar o pagamento
; O pagamento e armazenado na EEPROM, e, apos apertar o B1, ele e mostrado no LCD
; Tambem, ao apertar o botao, um LED e aceso. O limitador de corrente do LED e um potenciometro, e, ao mudar a resistencia do
; potenciometro, o objetivo era mudar o brilho do LED, porem, nao foi possivel com o simulador, mas seria possivel em testes reais
; Tambem, a leitura do potenciometro e convertido em A/D, que pode ser visto em um osciloscopio
; Para isso foram utilizados LOOPs, que esperam as operacoes desejadas
; Tambem foram utilizadas configuracoes do proprio LCD para liga-lo, limpa-lo e enviar um pulso
; Foram utilizados DELAYs com tempos diferentes
; Tambem configurou-se o PIC, que recebeu RA0 como entrada analogica e depois passou-se a configurar as saidas digitais, com ADCON0 e 1
; As principais configuracoes foram as do CCP
; Tambem verificou-se se a conversao ja fora feita
; A conversao e chamada na rotina 'MAIN', onde os valores altos e baixos sao lidos
; Tambem foram utilizadas as configuracoes EEPROM do PIC, para isso alternou-se entre os quatro bancos de memoria
; Para verificar qual numero foi pressionado do pinpad, utilizou-se niveis altos e baixos entre as PORTS 'C' e 'B'
; Tambem foram utilizadas flags e interrupcoes
; As flags foram para verificar a operacao escolhida
; Nas operacoes utilizou-se a multiplicacao somente
; A simulacao atendeu ao especificado do projeto