;*****************************************************************************
;
; Project name	XM2016 (Foam HotWire & Timer)
; Author	Xavier @ XavTroniC
; Website	www.xavtronic.ch
; Date		Octobre 2016
; Release SW	1.1
; Version HW	1.0
; Author	Xavier @ XavTroniC
; Licence	GNU GPLv3
;
;*****************************************************************************
;*****************
;** Description **
;*****************
;
; This software generates a fix frequency TIMER. It can control one PWM output
; for the hot wire in auto (from PC) or manual mode.
; The fixe frequency can be choose from six different and
; a PWM output maximum value can be set betwen 0 and 99% (99% default).
; Frequency and maximum PWM power are store in EEPROM.
;
;*****************************************************************************
;*********************
;** Functionalities **
;*********************
; SW 1.1
; -------
;
; Initialization / reset hot wire PWM to maximum value
; --------------------------------------------------
; Press both button + AND -
; ON RESET (power ON)
; Release button +
; Hot wire value is set automatic to maximum 99%
; Release button -
; Do a reset (power OFF - ON)
; HW ready
;
;
; Initialization frequency TIMER
; -------------------------------
; Press both button + AND -
; ON RESET (power ON)
; Release both button + and - at the same time
; Start progamm on your PC to show the frequency
; Press button + to increase frequancy value
; Press button - to decrease frequency value
; Default value 4kHz (periode 250ms)
; Possible frequencies :
;	 4kHz (periode 250us)
;	 5kHz (periode 200us)
;	 8kHz (periode 125us)
;	10kHz (periode 100us)
;	16kHz (periode  60us) (f_real 16.6666kHz)
;	20kHz (periode  50us)
;	25kHz (periode  40us)
;
; To save the frequency value press both button + and - at the same time
; and release them.
; Do a reset (power OFF - ON)
; HW ready enjoy it!
;
;
; Save new maximum PWM hot wire value
; -----------------------------------
; !!! Only in manual mode available
; !!! No effect in auto mode
;
; HW runing mode (no press button on start)
; Press button + to increase hot wire value value
; (!!! Warning !!! Maximum value allow is the maximum already set)
; To reset to 99% do the "Initialization / Reset) description
; Press button - to decrease hot wire value value
; To save the maximum hot wire value press both button + and - at the same time
; and release them.
; The maximum value allow now in manual and auto mode is set and save to EEPROM
;
;
; Switch Manual / Auto mode
; -------------------------
; Auto mode:
;	Wait a valid PWM from PC
;	If no PWM valid or no PC connected, the auto output is set to "0"
;	If PWM from PC is higher as the maximum hot wire allow, the PWM output
;	is protect with the limiter
;
; Manual mode:
;	Press button - to decrease hot wire value value
; 	Press button - to decrease hot wire value value
;	If you try to increase higher as the maximum hot wire allow, the PWM output
;	is protect with the limiter (default 100%)
;	The minumum value allow is 1%
;
;*******************************
;** Input / Output definition **
;*******************************
; HW 1.0
; -------
;		              _________   __________
;	                     |         \_/          |
;	                   __|      _               |__
;	                  |  | Vdd (_)          Vss |  |
;	              +5V |1 |                      | 8|- Masse
;	                  |__|                      |__|
;	                     |                      |
;	                   __|                      |__
;	                  |  |              ICSPDAT |  |
;	      Output PWM  |  | GPIO 5       GPIO 0  | 7| Input Button +
;	      to FET & PC |__|                      |__|
;	                     |                      |
;	                   __|                      |__
;	                  |  |              ICSPCLK |  |
;	     Output TIMER |3 | GPIO 4       GPIO 1  | 6| Input Button -
;	                  |__|                      |__|
;	                     |                      |
;	                   __| ____                 |__
;	                  |  | MCLR/Vpp             |  |
;	        Input PWM |4 | GPIO 3       GPIO 2  | 5| Input Button
;	        from PC   |__|                      |__| Manual(HIGH) / Auto (LOW)
;	                     |                      |
;	                     |______________________|
;
;
;
; Definition PIN IO DB25 and PIC
; ------------------------------
;
;		DB25 PIN    PIC PIN
;		--------    -------
; TIMER		10	    3 (GPIO 4)
; PWM PC	16	    4 (GPIO 3)
; Man/Auto	12	    5 (GPIO 2)
; PWM Out (PIC)	11	    2 (GPIO 5) (R=10K)	
;	
;
;*****************************************************************************
;******************************
;** Sources - Documentations **
;******************************
;
; Concept carte MM2001 de Michel Maury
;  (http://www.teaser.fr/~abrea/cncnet/elec/mm2001/mmx.phtml)
; Template de base 12F683 de Gilles Chevalerias
;  (http://gedonet.free.fr/aide_pic/aide_pic.htm)
; Carte MM2001-HL de Pascal Langer
;  (http://5xproject.dyndns.org/5XProject/tiki-index.php?page=La%20MM2001-HL)
;
;*****************************************************************************
;*************
;** History **
;*************
; SW
; Version	Date		Note
; --------	-----		-----
; 1.0	 	Mars 2016	Initial version
; 1.1		Juin 2016	Interrupt with TIMER1-CCP 
;
; HW
; Version	Date		Note
; --------	-----		-----
; 1.0	 	Mars 2016	Initial version
; 
;*****************************************************************************
;
;*****************************************************************************

	ERRORLEVEL -302			; suppression du message bank select 
	LIST      p=12f683              ; Définition de processeur
	#include <p12f683.inc>          ; fichier include

	__CONFIG   _FCMEN_ON & _IESO_OFF & _CP_OFF & _CPD_OFF & _BOD_ON & _MCLRE_OFF & _WDT_OFF & _PWRTE_ON & _INTRC_OSC_NOCLKOUT 

; '__CONFIG' précise les paramètres encodés dans le processeur au moment de
; la programmation du processeur. Les définitions sont dans le fichier include.
; Choisir une valeur par groupe.
; Voici les valeurs et leurs définitions :


; FCMEN: Fail-Safe Clock Monitor Enable bit
;------------------------------------------  
;_FCMEN_ON   	
;_FCMEN_OFF		; Désactive le flag de stabilité pour les changements de frequence avec 
                	; l'oscillateur interne

; IESO: Internal External Switch Over bit
;----------------------------------------
;_IESO_ON                    
;_IESO_OFF     		; Désactive la possibilité de changer d'oscillateur depuis le programme
                        ; entre oscillateur externe (LP, XT, HS) et oscillateur interne

; Protection du programme
; -----------------------
;_CP_ALL		protection totale
;_CP_OFF		Pas de protection

; Protection de l'EEprom
; -----------------------
;_CPD_ON		Mémoire EEprom protégée
;_CPD_OFF               Mémoire EEprom déprotégée


; Reset de la PIC si tension <4V
; ------------------------------
; _BOD_ON		Reset tension en service
;			Valide PWRTE_ON automatiquement
; _BOD_OFF		Reset tension hors service

;Utilisation de la pin MCLR
; -------------------------
;_MCLRE_ON		GP3/MCLR est utilisé pour le reset
;_MCLRE_OFF		GP3/MCLR est utilisé comme une entree/sortie

; Retard à la mise sous tension
; -----------------------------
;_PWRTE_OFF		Démarrage rapide
;_PWRTE_ON		Démarrage temporisé

; Watchdog
; --------
;_WDT_ON		Watchdog en service
;_WDT_OFF		Watchdog hors service (on peut activer le watchdog dans le programme)

; Oscillateur
; -----------
;_EXTRC_OSC_CLKOUT	(RC) RC externe sur GP5 avec Fosc/4 sur GP4	    
;_EXTRC_OSC_NOCLKOUT	(RCIO) RC externe sur GP5 avec GP4 en I/O	    
;_INTRC_CLKOUT   	(INTIO1) oscillateur interne avec Fosc/4 sur GP4 et I/O sur GP5            
;_INTRC_OSC_NOCLKOUT	(INTIO2) oscillateur interne avec GP4 et GP5 en I/O	    
;_EC_OSC		(ECIO) oscillateur externe sur GP5 avec GP4 en I/O	        
;_LP_OSC 		Oscillateur basse vitesse (?<F<200Khz)        
;_XT_OSC                Oscilateur moyenne vitesse (0,1MHz<F<4Mhz)     
;_HS_OSC 		Oscillateur haute vitesse (4Mhz<F<20Mhz)


;*****************************************************************************
;                               ASSIGNATIONS SYSTEME                         *
;*****************************************************************************

; REGISTRE OPTION_REG (configuration)
; -----------------------------------
OPTIONVAL	EQU	B'00000000'
			; GPPU      b7 : 1= Résistance rappel +5V hors service
			; INTEDG    b6 : 1= Interrupt sur front montant de RB0
			;                0= Interrupt sur front descendant de RB0
			; TOCS      b5 : 1= source clock = transition sur RA4
			;                0= horloge interne
			; TOSE      b4 : 1= Sélection front descendant RA4(si B5=1)
			;                0= Sélection front montant RA4
			; PSA       b3 : 1= Assignation prédiviseur sur Watchdog
			;                0= Assignation prédiviseur sur Tmr0
			; PS2/PS0   b2/b0 valeur du prédiviseur
                        ;           000 =  1/1 (watchdog) ou 1/2 (tmr0)
			;           001 =  1/2               1/4
			;           010 =  1/4		     1/8
			;           011 =  1/8		     1/16
			;           100 =  1/16		     1/32
			;           101 =  1/32		     1/64
			;           110 =  1/64		     1/128
			;           111 =  1/128	     1/256


; REGISTRE INTCON (contrôle interruptions standard)
; -------------------------------------------------
; INTCONVAL	EQU	B'01100000'	; TMR0
INTCONVAL	EQU	B'01000000'	; TMR1
			; GIE       b7 : masque autorisation générale interrupt
                        ;                ne pas mettre ce bit à 1 ici
                        ;                sera mis en temps utile
			; PEIE      b6 : masque autorisation générale périphériques
			; T0IE      b5 : masque interruption tmr0
			; INTE      b4 : masque interuption GP2/Int
			; GPIE      b3 : masque interruption "on change" GPIO
			; T0IF      b2 : flag tmr0
			; INTF      b1 : flag GP2/Int
			; RBIF      b0 : flag interruption "on change" GPIO

; REGISTRE PIE1 (contrôle interruptions périphériques)
; ----------------------------------------------------
; PIE1VAL		EQU	B'00000000'	; TRM0
PIE1VAL		EQU	B'00100000'	; TMR1		
			; EEIE      b7 : masque interrupt écriture EEPROM 
			; ADIE      b6 : masque interrupt convertisseur A/D
			; CCP1IE    b5 : masque interrupt CCP1
			; RESERVED  b4 : réservé, laisser à 0
			; CMIE      b3 : masque interrupt comparateur
			; OSFIE     b2 : masque de detection de defaut de l'oscillateur
			; TMR2IE    b1 : masque interrupt TMR2 = PR2
			; TMR1IE    b0 : masque interrupt débordement tmr1


; REGISTRE OSCCON (contrôle de la vitesse de l'oscillateur interne)
; -----------------------------------------------------------------
OSCCONVAL	EQU	B'01110001'	; exemple 8 MHz
			; RESERVED  b7 : réservé, laisser à 0
			; IRCF<2:0>  b6-4 : selection de la vitesse oscillateur inerne
				; 000 = 31.25 kHz 	(LFINTOSC)
				; 001 = 125 kHz   	(HFINTOSC)
				; 010 = 250 kHz		(HFINTOSC)
				; 011 = 500 kHz		(HFINTOSC)
				; 100 = 1 MHz		(HFINTOSC)
				; 101 = 2 MHz		(HFINTOSC)
				; 110 = 4 MHz		(HFINTOSC)
				; 111 = 8 MHz		(HFINTOSC)
			; OSTS     b3 : STATUS de l'oscillateur en cours
				; 1 = l'oscillateur est externe, LP,HS ou XT
				; 0 = l'oscillateur est interne 
			; HTS	   b2 : flag de stabilisation de l'oscillateur interne haute frequence, 8MHz à 125KHz (HFINTOSC)
				; 1 = l'oscillateur est stable
				; 0 = l'oscillateur n'est pas stable
			; LTS     b1 :flag de stabilisation de l'oscillateur interne basse frequence, 31KHz (LFINTOSC)
				; 1 = l'oscillateur est stable
				; 0 = l'oscillateur n'est pas stable
			; SCS     b0 : selection du mode de l'oscillateur
				; 0 = le mode d'oscillateur est defini par FOSC<2:0> (LP, XT, HS, EC) 
				; 1 = l'oscillateur interne est utilisé pour l'horloge
; Pour utiliser l'oscillateur interne en plus de l'oscillateur externe, on doit utiliser _IESO_ON dans __CONFIG 
; avec _IESO_OFF c'est soit un oscillateur interne soit un externe mais pas les deux.

; REGISTRE ANSEL (contrôle du convertisseur A/D)
; ----------------------------------------------
ANSELVAL	EQU	B'00000000'
			; RESERVED  b7 : réservé, laisser à 0
			; ADCS<2;0> b6-4 selection de la vitesse du convertisseur
				; 000 = Fosc/2
				; 001 = Fosc/8
				; 010 = Fosc/32
				; X11 = Frc l'horloge vient de loscillateur dédié 500kHzmax
				; 100 = Fosc/4
				; 101 = Fosc/16
				; 110 = Fosc/64
			; ANS<3-0>  b3-0  selection des pins du convertisseur AN<3-0>
				; 1 = entrée convertisseur
				; 0 = I/O normale ou fonction spéciale
			


; REGISTRE CMCON (COMPARATEURS)
; -----------------------------
CMCONVAL	EQU	B'00000111' 
			; RESERVED  b7 : réservé, laisser à 0
			; COUT      b6 :sortie comparateur
			; RESERVED  b5 : réservé, laisser à 0
			; CINV      b4 :inverseur comparateur
			; CIS       b3 :selection entree des comparateurs
			; CM2-CM0   b2-0 :mode des comparateurs
			;configurer le mode 111 pour utiliser GP0-1-2 en I/O

; REGISTRE VRCON (voltage reference module)
; ------------------------------------
VRCONVAL	EQU	B'00000000'
			; VREN       b7 :Validation du module
			; RESERVED   b6 : réservé, laisser à 0
			; VRR        b5 :Choix de la plage 
			; RESERVED   b4 : réservé, laisser à 0
			; VR3-VR0    b3-0 :Choix de la valeur dans la plage 
					; si VRR=1 Vref=(VR[3:0]/24)*Vdd
					; si VRR=0 Vref=Vdd/4+(VR[3:0]/32)*Vdd

; REGISTRE WDTCON (prediviseur et activation du watchdog)
; -------------------------------------------------------
; la valeur proposée n'est pas chargée pendant l'init, à vous de le faire si vous en avez besoin
;WDTCONVAL	EQU	B'00010111'	; pour le calcul du débordement faire 32µS*prediviseur(WDTPS<3-0>)*postdiviseur(PS<2-0>)
					; on peut aller jusqu'à 268 secondes 
			; RESERVED   b7-5 : réservé, laisser à 0
			; WDTPS<3-0> b4-1 : prediviseur du watchdog qui oscille à 31.25 kHz (32µS)
			 	; 0000 = 1:32
				; 0001 = 1:64
				; 0010 = 1:128
				; 0011 = 1:256
				; 0100 = 1:512  valeur au reset
				; 0101 = 1:1024
				; 0110 = 1:2048
				; 0111 = 1:4096
				; 1000 = 1:8192
				; 1001 = 1:16394
				; 1010 = 1:32768
				; 1011 = 1:65536
			; SWDTEN     b0  : à 1 ce bit met en route le watchdog
					 ; si ce n'est déja fait dans le CONFIG

					 
; REGISTRE CCP1CON (capture / compare / PWM module)
; -------------------------------------------------
; CCP1CONVAL	EQU	B'0000000'	; TMR0
CCP1CONVAL	EQU	B'0001011'	; TMR1
			; RESERVED   b7-6 : réservé, laisser à 0
			; DC1B	   b5-4 : LSb rapport cycle PWM (MSb -> CCPR1L)
			; CCP1M    b3-0 : Selecton mode CCP 
					; 0000 = Capture/Compare/PWM off (resets CCP module)
					; 0001 = Unused (reserved)
					; 0010 = Unused (reserved)
					; 0011 = Unused (reserved)
					; 0100 = Capture mode, every falling edge
					; 0101 = Capture mode, every rising edge
					; 0110 = Capture mode, every 4th rising edge
					; 0111 = Capture mode, every 16th rising edge
					; 1000 = Compare mode, set output on match (CCP1IF bit is set)
					; 1001 = Compare mode, clear output on match (CCP1IF bit is set)
					; 1010 = Compare mode, generate software interrupt on match (CCP1IF bit is set, CCP1 pin is unaffected)
					; 1011 = Compare mode, trigger special event (CCP1IF bit is set, TMR1 is reset and A/D conversion is started if the ADC module is enabled. CCP1 pin is unaffected.)
					; 110x = PWM mode active-high
					; 111x = PWM mode active-low
					

; REGISTRE T1CON ( Registre control Timer 1 )
; -------------------------------------------------
; T1CONVAL	EQU	B'0000000'	; TMR0 - ALL disable -(TIMER1 enabled, internal clock, no prescale (Datasheet P.47))
T1CONVAL	EQU	B'0000001'	; TRM1 - TIMER1 enabled, internal clock, no prescale (Datasheet P.47)
	
	
					
; DIRECTION DES PORTS I/O
; -----------------------

DIRPORT		EQU	B'00001111'	; Direction PORT 6 I/O (1=entrée)

					; GPIO 0 Input Bouton plus
					; GPIO 1 Input Bouton moins
					; GPIO 2 Input Switch Man / Auto
					; GPIO 3 Input Valeur PC chauffe auto

					; GPIO 4 Output PWM fil chaud
					; GPIO 5 Output Timer pour PC

;*****************************************************************************
;                           ASSIGNATIONS PROGRAMME                           *
;*****************************************************************************

; exemple
; -------
;MASQUE		EQU	H'00FF'


;*****************************************************************************
;                                  DEFINE                                    *
;*****************************************************************************

#DEFINE inBPPos		GPIO,0			; BP+
#DEFINE inBPNeg		GPIO,1			; BP-
#DEFINE inManuAuto	GPIO,2			; Man / Auto
#DEFINE inPWM		GPIO,3			; PWM PC fil chaud

#DEFINE outTimer	GPIO,4			; TIMER
#DEFINE outPWM		GPIO,5			; PWM fil chaud

#DEFINE varOutTimer	outSignal,4		; TIMER	output generation
#DEFINE varOutPWM	outSignal,5		; PWM output hot wire


; EEPROM address to save frequency and maximum hot wire allow value
#define	eeaddrFreq	0x1
#define	eeaddrValHWMax	0x2


; Number to select the right frequency value
#define	maxNbrFreq	0x6

#define	confFreq04	0x0
#define	confFreq05	0x1
#define	confFreq08	0x2
#define	confFreq10	0x3
#define	confFreq16	0x4
#define	confFreq20	0x5
#define	confFreq25	0x6

; Maximum PWM value allowed
#DEFINE	valPWM_MAX	d'99'	; H'0063'

; Value to set frequency TIMER 0
; #DEFINE valFreqTIMER_04	d'137'
; #DEFINE valFreqTIMER_05	d'164'
; #DEFINE valFreqTIMER_08	d'200'
; #DEFINE valFreqTIMER_10	d'212'
; #DEFINE valFreqTIMER_16	d'232'
; #DEFINE valFreqTIMER_20	d'237'
; #DEFINE valFreqTIMER_25	d'242'

; TMR0 (x = 4)
; @ 8MHz prescaler 1/2
	; TMR0 25kHz = 238
	; TMR0 20kHz = 233
	; TMR0 16kHz = 228 (-> 16,6667kHz)
	; TMR0 10kHz = 208
	; TMR0  8kHz = 195.5
	; TMR0  5kHz = 158
	; TMR0  4kHz = 133 + x -> varie fonction interruption et programme


; Value to set frequency TIMER 1 
#DEFINE valFreqTIMER_04	d'250'
#DEFINE valFreqTIMER_05	d'200'
#DEFINE valFreqTIMER_08	d'125'
#DEFINE valFreqTIMER_10	d'100'
#DEFINE valFreqTIMER_16	d'62'
#DEFINE valFreqTIMER_20	d'50'
#DEFINE valFreqTIMER_25	d'40'
	
; @ 8MHz prescaler 1/1
; CCPR1H and CCPR1L
	; Moins -1 compensation 
	
	; TMR1 50kHz =  20 " T =  20us "
	; TMR1 40kHz =  25 " T =  25us "
	; TMR1 25kHz =  40 " T =  40us "
	; TMR1 20kHz =  50 " T =  50us "
	; TMR1 10kHz = 100 " T = 100us "
	; TMR1  8kHz = 125 " T = 125us "
	; TMR1  5kHz = 200 " T = 200us "
	; TMR1  4kHz = 250 " T = 250us "	
	
; Value to set the deboucing filter / slow PWM hot wire increase / decrease
#DEFINE valBPFilter_04	d'12'
#DEFINE valBPFilter_05	d'15'	
#DEFINE valBPFilter_08	d'24'
#DEFINE valBPFilter_10	d'30'
#DEFINE valBPFilter_16	d'50'		
#DEFINE valBPFilter_20	d'60'	
#DEFINE valBPFilter_25	d'75'


; TMR0 - TMR1
; varBPFilter 25kHz =  40 * 100 * T = 300ms " T = 75
; varBPFilter 20kHz =  50 * 100 * T = 300ms " T = 60
; varBPFilter 16kHz =  60 * 100 * T = 300ms " T = 50
; varBPFilter 10kHz = 100 * 100 * T = 300ms " T = 30
; varBPFilter  8kHz = 125 * 100 * T = 300ms " T = 24
; varBPFilter  5kHz = 200 * 100 * T = 300ms " T = 15
; varBPFilter  4kHz = 250 * 100 * T = 300ms " T = 12

;*****************************************************************************
;                             MACRO                                          *
;*****************************************************************************

; Changement de banques
; ----------------------

BANK0	macro				; passer en banque0
		bcf	STATUS,RP0
		bcf	STATUS,RP1
	endm

BANK1	macro				; passer en banque1
		bsf	STATUS,RP0
		bcf	STATUS,RP1
	endm

	
; opérations en mémoire eeprom
; -----------------------------

REEPROM macro	adeeprom		; lire eeprom (adresse dans adeeprom & résultat en w)
	clrwdt				; reset watchdog
	BANK1				; passer en banque1

	movlw	adeeprom		; charger adresse eeprom (passage de la valeur en litteral)
	;movf	adeeprom,w		; charger adresse eeprom (passage de la valeur par une variable)
	movwf	EEADR			; pointer sur adresse eeprom
	bsf	EECON1,RD		; ordre de lecture
	movf	EEDATA,w		; charger valeur lue
	BANK0				; passer en banque0
	endm

WEEPROM	macro	addwrite	  	; la donnée se trouve dans W, l'adresse dans addwrite
	LOCAL	loop
	LOCAL   loop1
	BANK1				; passer en banque1
	movwf	EEDAT			; placer data dans registre
	movlw	addwrite		; charger adresse d'écriture (passage de la valeur en litteral)
	;movf	addwrite,w		; charger adresse d'écriture (passage de la valeur par une variable)
	movwf	EEADR			; placer dans registre
	bsf	EECON1,WREN		; autoriser accès écriture
loop
	bcf	INTCON,GIE		; interdire interruptions
	BTFSC 	INTCON,GIE 		;See AN576
	goto	loop			; non, attendre
	movlw	0x55			; charger 0x55
	movwf	EECON2			; envoyer commande
	movlw	0xAA			; charger 0xAA
	movwf	EECON2			; envoyer commande
	bsf	EECON1,WR		; lancer cycle d'écriture
	bsf	INTCON,GIE		; réautoriser interruptions
loop1
	btfsc	EECON1,WR		; tester si écriture terminée
	goto	loop1			; non, attendre
	bcf	EECON1,WREN		; verrouiller prochaine écriture
	BANK0				; passer en banque0
	endm


; EXEMPLE

; Soit valeur directe d'adresse (ou un #define)
; Soit valeur d'adresse contenu dans une variable
; REEPROM d'5'		; => movlw	adeeprom
; REEPROM adresse_5	; => ;movf	adeeprom,w
; movwf	valeur_lu
	
; movlw	12 		; Valeur a écrire
; movfw	varibale_val
; WEEPROM d'5'		; => movlw	adeeprom
; WEEPROM adresse_5	; => ;movf	adeeprom,w
	
;*****************************************************************************
;                      VARIABLES ZONE COMMUNE                                *
;*****************************************************************************

; Zone de 16 bytes
; ----------------

	CBLOCK	0x70			; Début de la zone (0x70 à 0x7F)
	W_TEMP : 1			; Sauvegarde registre W
	STATUS_TEMP : 1			; sauvegarde registre STATUS
	;FSR_temp : 1			; sauvegarde FSR (si indirect en interrupt)
	ENDC

;*****************************************************************************
;                        VARIABLES BANQUE 0                                  *
;*****************************************************************************

; Zone de 80 bytes
; ----------------

	CBLOCK	0x20			; Début de la zone (0x20 à 0x6F)

	ENDC				; Fin de la zone


varValReqPWM	EQU 0x30	; Current value PWM required (high level)
varValManPWM	EQU 0x32	; Current value PWM running manual mode (high level)
varValAutoPWM	EQU 0x33	; Current value PWM running auto mode (high level)
varBPFilter	EQU 0x34


valMaxPWM	EQU 0x35	; Value maximum PWM allow
valFreqTIMER	EQU 0x36	; Timer value 
valBPFilter	EQU 0x37	; Deboucing button value
	
outSignal	EQU 0x40	; Ouput variable memory mask
	
tmp		EQU 0x60	; Work temporary variable

	CBLOCK	0x65		; Delay variables
	d1
	d2
	d3
	ENDC


;*****************************************************************************
;                        VARIABLES BANQUE 1                                  *
;*****************************************************************************

; Zone de 32 bytes
; ----------------

	CBLOCK	0xA0			; Début de la zone (0xA0 à 0xBF)

	ENDC				; Fin de la zone                        

;
;*****************************************************************************
;                      DEMARRAGE SUR RESET                                   *
;*****************************************************************************

	org	0x000 			; Adresse de départ après reset
  	goto    init			; Initialiser

; ////////////////////////////////////////////////////////////////////////////

;                         I N T E R R U P T I O N S

; ////////////////////////////////////////////////////////////////////////////

;*****************************************************************************
;                     ROUTINE INTERRUPTION                                   *
;*****************************************************************************
;-----------------------------------------------------------------------------
; Si on n'utilise pas l'adressage indirect dans les interrupts, on se passera
; de sauvegarder FSR ainsi que la restauration dans restorereg
; Si le programme ne fait pas plus de 2K, on se passera de la gestion de 
; PCLATH ainsi que la restauration dans restorereg
;-----------------------------------------------------------------------------
	
	;sauvegarder registres	
	;---------------------
	org	0x004			; adresse d'interruption
	movwf   W_TEMP  		; sauver registre W
	swapf	STATUS,w		; swap STATUS avec résultat dans w
	bcf	STATUS,RP0       ;change to bank 0 regardless of current bank
	movwf	STATUS_TEMP		; sauver STATUS swappé
	;movf	FSR , w			; charger FSR
	;movwf	FSR_temp		; sauvegarder FSR
	;BANK0				; passer en banque0
	;clrf	STATUS			; bank 0, regardless of current bank, Clears IRP,RP1,RP0
	
	bcf	PIR1,CCP1IF		; TMR1 effacer flag interupt 


	;btfss	INTCON,T0IF		; ?TIMER interrupt
	;GOTO	restorereg
	
	movfw	outSignal		; Write TIER and PWM
	movwf	GPIO
	;movlw	0x10			; Toggel TIMER Output
	;xorwf	GPIO,f
		
	;NOP				; Compensation TIMER 500us
	;movfw	valFreqTIMER		; TMR0 
	;movwf	TMR0			; TMR0 Reset value Timer
	;bcf	INTCON,T0IF		; TMR0 effacer flag interupt 
	
	;restaurer registres
	;-------------------
restorereg
	;movf	FSR_temp , w		; charger FSR sauvé
	;movwf	FSR			; restaurer FSR
	swapf	STATUS_TEMP,w		; swap ancien STATUS, résultat dans w
	movwf   STATUS			; restaurer STATUS
	swapf   W_TEMP,f		; Inversion L et H de l'ancien W
                       			; sans modifier Z
	swapf   W_TEMP,w  		; Réinversion de L et H dans W
				; W restauré sans modifier STATUS
	retfie  			; return from interrupt


; ////////////////////////////////////////////////////////////////////////////

;                           P R O G R A M M E

; ////////////////////////////////////////////////////////////////////////////

;*****************************************************************************
;                          INITIALISATIONS                                   *
;*****************************************************************************
init

	; initialisation PORTS (banque 0 et 1)
	; ------------------------------------
	BANK0				; sélectionner banque0
	clrf	GPIO			; Sorties I/O à 0
	BANK1				; passer en banque1
	movlw	DIRPORT			; Direction des I/O
	movwf	TRISIO			; écriture dans registre direction

	
	; Registre de l'oscillateur
	; -------------------------
	movlw	OSCCONVAL		; charger le masque
	movwf	OSCCON			; initialiser registre


	; Registre d'options (banque 1)
	; -----------------------------
	movlw	OPTIONVAL		; charger masque
	movwf	OPTION_REG		; initialiser registre option

	
	; registres interruptions (banque 1)
	; ----------------------------------
	movlw	INTCONVAL		; charger valeur registre interruption
	movwf	INTCON			; initialiser interruptions
	movlw	PIE1VAL			; Initialiser registre 
	movwf	PIE1			; interruptions périphériques 1
	movlw	VRCONVAL		; charger masque
	movwf	VRCON			; initialiser le registre tension de reference
	movlw	ANSELVAL		; charger masque
	movwf	ANSEL			; initialiser le registre du convertisseur
	BANK0				; sélectionner banque 0
	movlw	CMCONVAL		; charger masque
	movwf	CMCON0			; initialiser le registre du comparateur
	movlw	CCP1CONVAL
	movwf	CCP1CON			; initialiser le registre du CCP comparateur
	movlw	T1CONVAL		; initialiser le registre du Timer 1
	movwf	T1CON
	
	
	; initialisation Output Timer
	; ------------------------------------
	clrf	varValManPWM
	clrf	varValReqPWM
	movlw	0x02
	movwf	varValReqPWM		; Set PWM enable with 2%
	clrf	outSignal
	bcf	outTimer		; GP4 LOW level (Timer generated)
	bcf	varOutTimer

	
	; initialisation TIMER - Chauffe / Lecture EEPROM
	; ------------------------------------	

	; Hot wire
	; If not initialized set to 99% and save to EEPROM
	; -------------------------------------------------
readValHWMax
	REEPROM	eeaddrValHWMax
	movwf	tmp
	sublw	0xFF			; Première initialisation
	btfsc	STATUS,Z
	goto	initValHWMax
	movfw	tmp
	movwf	valMaxPWM
	goto	readTimer

	; Initilized maximum hot wire value
initValHWMax
	movlw	valPWM_MAX
	WEEPROM eeaddrValHWMax
	movlw	valPWM_MAX
	movwf	valMaxPWM
	goto	readTimer	
	
	
	; Timer	read
readTimer
	REEPROM	eeaddrFreq
	movwf	tmp

	;Frequence 25kHz
initFreq25
	movfw	tmp
	sublw	confFreq25
	btfss	STATUS,Z
	goto	initFreq20

	movlw	valFreqTIMER_25
	movwf	valFreqTIMER

	movlw	valBPFilter_25
	movwf	valBPFilter

	goto	endReadFreq

	; Frequence 20kHz
initFreq20
	movfw	tmp
	sublw	confFreq20
	btfss	STATUS,Z
	goto	initFreq16

	movlw	valFreqTIMER_20
	movwf	valFreqTIMER

	movlw	valBPFilter_20
	movwf	valBPFilter

	goto	endReadFreq

	; Frequence 16kHz
initFreq16
	movfw	tmp
	sublw	confFreq16
	btfss	STATUS,Z
	goto	initFreq10

	movlw	valFreqTIMER_16
	movwf	valFreqTIMER

	movlw	valBPFilter_16
	movwf	valBPFilter

	goto	endReadFreq	
	
	; Frequence 10kHz
initFreq10
	movfw	tmp
	sublw	confFreq10
	btfss	STATUS,Z
	goto	initFreq08

	movlw	valFreqTIMER_10
	movwf	valFreqTIMER

	movlw	valBPFilter_10
	movwf	valBPFilter

	goto	endReadFreq

	; Frequence 8kHz
initFreq08
	movfw	tmp
	sublw	confFreq08
	btfss	STATUS,Z
	goto	initFreq05

	movlw	valFreqTIMER_08
	movwf	valFreqTIMER

	movlw	valBPFilter_08
	movwf	valBPFilter

	goto	endReadFreq

	; Frequence 5kHz
initFreq05
	movfw	tmp
	sublw	confFreq05
	btfss	STATUS,Z
	goto	initFreq04

	movlw	valFreqTIMER_05
	movwf	valFreqTIMER

	movlw	valBPFilter_05
	movwf	valBPFilter

	goto	endReadFreq	
	
	; Frequence 4kHz
initFreq04
	movfw	tmp
	sublw	confFreq04
	btfss	STATUS,Z
	goto	initFreqDefault

	movlw	valFreqTIMER_04
	movwf	valFreqTIMER

	movlw	valBPFilter_04
	movwf	valBPFilter

	goto	endReadFreq


; Default Frequency = 4kHz
initFreqDefault
	movlw	valFreqTIMER_04
	movwf	valFreqTIMER

	movlw	valBPFilter_04
	movwf	valBPFilter

endReadFreq

	; initialisation Frequence TIMER
	; ------------------------------------
	movfw	valFreqTIMER
	; movwf	TMR0			;TMR0
	clrf	CCPR1H			; TMR1
	movfw	valFreqTIMER		; TMR1
	movwf	CCPR1L			; TMR1

	; autoriser interruptions (banque 0)
	; ----------------------------------
	; bcf	INTCON,T0IF		; TMR0 effacer flags 1 TMR0
	clrf	PIR1			; TMR1 effacer flags 1
	clrf	TMR1L			; TMR1 effacer compteur Timer 1
	clrf	TMR1H
	
	bsf	INTCON,GIE		; TMR0 & TMR1 valider interruptions
	goto	BPDetection		; Detection to start programm or settings


;*****************************************************************************
;                      PROGRAMME PRINCIPAL                                   *
;*****************************************************************************

BPDetection
	movfw	GPIO
	andlw	0x3			; Test button value
	xorlw	0x3			; Pressed button = 1 (logicial stats inverted)
	movwf	tmp
	
	movfw	tmp			; No button pressed
	sublw	0x00
	btfsc	STATUS,Z
	goto	ProgStart		; Start main programm
	
	movfw	tmp			; Both buttons pressed
	sublw	0x03
	btfsc	STATUS,Z
	goto	detectSettingBP
	
	movfw	tmp			; Button - (neg) pressed NOT Used
	sublw	0x02
	btfsc	STATUS,Z
	goto	BPMoins
	
	movfw	tmp			; Button + (pos) pressed NOT Used
	sublw	0x01
	btfsc	STATUS,Z
	goto	BPPlus
	
	; Error wait a RESET
	bcf	INTCON,GIE		; Disable interruptions -> protection
	nop
	goto	$-1

	
	; Detection relachement bouton ou les 2 
	;*************************************
	
detectSettingBP				; Detect both buttons release
	btfss	inBPPos
	goto	$+5
	call	delay200ms
	btfss	inBPNeg
	goto	settingValHWMax		; If button + (pos) release
	goto	settingFreq		; If BOTH buttons release at same time

	btfss	inBPNeg
	goto	detectSettingBP
	call	delay200ms
	btfss	inBPPos		
	goto	settingRes		; If button - (neg) release NOT Used
	goto	settingFreq		; If BOTH buttons release at same time


settingValHWMax				; Reset hot wire value
	movlw	valPWM_MAX
	WEEPROM eeaddrValHWMax
	btfss	inBPNeg
	goto	$-1
	bcf	INTCON,GIE		; Disable interruptions -> protection
	nop				; Wait PIC Reset
	goto	$-1
	
	;*************************************	
	
	; Modification TIMER
	;*************************************
settingFreq
	REEPROM	eeaddrFreq		
	movwf	tmp
	
detectFreqBP
	btfss	outTimer
	goto	$+2
	goto	$+3
	bsf	varOutTimer
	goto	$+2
	bcf	varOutTimer
	
	btfsc	inBPPos			; Test IF button + (pos) OR IF button - (neg) OR IF button + AND -
	goto	$+5
	call	delay200ms
	btfsc	inBPNeg
	goto	incFreq			; IF button + pressed, increase TIMER (limit max allow 50kHz)
	goto	saveFreq

	btfsc	inBPNeg
	goto	detectFreqBP
	call	delay200ms
	btfsc	inBPPos
	goto	decFreq			; IF button - pressed, decrease TIMER (limit min allow 4kHz)
	goto	saveFreq


incFreq
	bcf	INTCON,GIE		; Disable interruptions
	btfss	inBPPos			; Waiting that button pressed will be released
	goto	$-1
	movfw	tmp
	sublw	maxNbrFreq
	btfss	STATUS,Z
	goto	$+3
	bsf	INTCON,GIE		; Enable interruptions
	goto	detectFreqBP
	incf	tmp,W
	goto	modFreq

decFreq
	bcf	INTCON,GIE		; Disable interruptions
	btfss	inBPNeg			; Waiting that button pressed will be released
	goto	$-1
	movfw	tmp
	sublw	d'0'
	btfss	STATUS,Z
	goto	$+3
	bsf	INTCON,GIE		; Enable interruptions
	goto	detectFreqBP
	decf	tmp,W
	goto	modFreq

	
modFreq						
	movwf	tmp			; Store new frequency to test it

	
; Frequence 25kHz
settingFreq25
	movfw	tmp
	sublw	confFreq25
	btfss	STATUS,Z
	goto	settingFreq20

	movlw	valFreqTIMER_25
	movwf	valFreqTIMER

	movlw	valBPFilter_25
	movwf	valBPFilter

	movfw	valFreqTIMER
	; movwf	TMR0			; TMR0
	movwf	CCPR1L			; TMR1
	bsf	INTCON,GIE		; Enable interruptions
	goto	detectFreqBP

; Frequence 20kHz
settingFreq20
	movfw	tmp
	sublw	confFreq20
	btfss	STATUS,Z
	goto	settingFreq16

	movlw	valFreqTIMER_20
	movwf	valFreqTIMER

	movlw	valBPFilter_20
	movwf	valBPFilter
	
	movfw	valFreqTIMER
	; movwf	TMR0			; TMR0
	movwf	CCPR1L			; TMR1
	bsf	INTCON,GIE		; Enable interruptions
	goto	detectFreqBP

	; Frequence 16kHz
settingFreq16
	movfw	tmp
	sublw	confFreq16
	btfss	STATUS,Z
	goto	settingFreq10

	movlw	valFreqTIMER_16
	movwf	valFreqTIMER

	movlw	valBPFilter_16
	movwf	valBPFilter
	
	movfw	valFreqTIMER
	; movwf	TMR0			; TMR0
	movwf	CCPR1L			; TMR1
	bsf	INTCON,GIE		; Enable interruptions
	goto	detectFreqBP

; Frequence 10kHz
settingFreq10
	movfw	tmp
	sublw	confFreq10
	btfss	STATUS,Z
	goto	settingFreq8

	movlw	valFreqTIMER_10
	movwf	valFreqTIMER

	movlw	valBPFilter_10
	movwf	valBPFilter
	
	movfw	valFreqTIMER
	; movwf	TMR0			; TMR0
	movwf	CCPR1L			; TMR1
	bsf	INTCON,GIE		; Enable interruptions
	goto	detectFreqBP

; Frequence 8kHz
settingFreq8
	movfw	tmp
	sublw	confFreq08
	btfss	STATUS,Z
	goto	settingFreq5

	movlw	valFreqTIMER_08
	movwf	valFreqTIMER

	movlw	valBPFilter_08
	movwf	valBPFilter
	
	movfw	valFreqTIMER
	; movwf	TMR0			; TMR0
	movwf	CCPR1L			; TMR1
	bsf	INTCON,GIE		; Enable interruptions
	goto	detectFreqBP


; Frequence 5kHz
settingFreq5
	movfw	tmp
	sublw	confFreq05
	btfss	STATUS,Z
	goto	settingFreq4

	movlw	valFreqTIMER_05
	movwf	valFreqTIMER

	movlw	valBPFilter_05
	movwf	valBPFilter
	
	movfw	valFreqTIMER
	; movwf	TMR0			; TMR0
	movwf	CCPR1L			; TMR1
	bsf	INTCON,GIE		; Enable interruptions
	goto	detectFreqBP
	
; Frequence 4kHz
settingFreq4
	movfw	tmp
	sublw	confFreq04
	btfss	STATUS,Z
	goto	settingFreqDefault

	movlw	valFreqTIMER_04
	movwf	valFreqTIMER

	movlw	valBPFilter_04
	movwf	valBPFilter
	
	movfw	valFreqTIMER
	; movwf	TMR0			; TMR0
	movwf	CCPR1L			; TMR1
	bsf	INTCON,GIE		; Enable interruptions
	goto	detectFreqBP

; Default Frequency = 4kHz
settingFreqDefault
	movlw	0x00
	movwf	tmp

	movlw	valFreqTIMER_04
	movwf	valFreqTIMER

	movlw	valBPFilter_04
	movwf	valBPFilter
	
	movfw	valFreqTIMER
	; movwf	TMR0			; TMR0
	movwf	CCPR1L			; TMR1
	bsf	INTCON,GIE		; Enable interruptions
	goto	detectFreqBP


saveFreq
	bcf	INTCON,GIE		; Disable interruptions
	movfw	tmp
	WEEPROM eeaddrFreq

	movfw	GPIO			; Test IF BOTH buttons release
	andlw	0x03
	sublw	0x03
	btfss	STATUS,Z
	goto	$-4
	
	bcf	INTCON,GIE		; Disable interruptions -> protection
	nop				; Wait PIC Reset
	goto	$-1
	
	;******************************
	
;  Reserved - No function implanted
BPPlus:
	bcf	INTCON,GIE		; Disable interruptions -> protection
	nop				; Wait PIC Reset
	goto	$-1
	
BPMoins:
	bcf	INTCON,GIE		; Disable interruptions -> protection
	nop				; Wait PIC Reset
	goto	$-1

settingRes:
	bcf	INTCON,GIE		; Disable interruptions -> protection
	nop				; Wait PIC Reset
	goto	$-1

	
	
;*****************************************************************************	
;********************************
; ** TIMER and PWM generation  **
;********************************
ProgStart
;LoopMainProg
	nop

EndPWM					; Loop PWM generation
LoopWait	
	;btfss	outTimer		; TMR0 Waiting interruption output TIMER
	btfsc	outTimer		; TMR1 Waiting interruption output TIMER
	GOTO	LoopWait
	;bcf	varOutTimer		; TMR0	
	bsf	varOutTimer		; TMR1
	
GenPWM
	btfss	inManuAuto		; Stat switch in manual OR auto mode
	GOTO	AutoPWM
	
;Manual mode PWM control
	incf	varValManPWM,f		; Increment the current PWM value (high level)
	movf	varValManPWM,w
	subwf	varValReqPWM,w		; Test with the value request
	btfss	STATUS,C
	;bcf	outPWM			; IF value request reached RESET PWM output
	bcf	varOutPWM		; Indirect output set/reset
	btfsc	STATUS,C
	;bsf	outPWM			; IF value request NOT reached SET PWM output
	bsf	varOutPWM		; Indirect output set/reset

	movf	varValManPWM,w		; End cycle (100 time)
	sublw	D'100'
	btfsc	STATUS,Z
	;GOTO	$+4
	GOTO	$+5
	;btfsc	outTimer		; TMR0 Waiting interruption output TIMER
	btfss	outTimer		; TMR1 Waiting interruption output TIMER
	GOTO	$-1
	;bsf	varOutTimer		; TMR0	
	bcf	varOutTimer		; TMR1
	GOTO	EndPWM	
	
	clrf	varValManPWM		; Reset counter to allow to generat the next output signal PWM
	;btfsc	outTimer		; TMR0 Waiting interruption output TIMER
	btfss	outTimer		; TMR1 Waiting interruption output TIMER
	GOTO	$-1
	;bsf	varOutTimer		; TMR0	
	bcf	varOutTimer		; TMR1
	decfsz	varBPFilter,f
	GOTO	EndPWM
	incf	varBPFilter,f
	btfsc	inBPPos			; Test Button + pressed
	GOTO	StatDecPWM
	btfsc	inBPNeg			; Test Button - pressed
	GOTO	StatIncPWM
	movfw	varValReqPWM		; Both buttons pressed 
	WEEPROM	eeaddrValHWMax		; Save new PWM value to maximum allow
	movf	valBPFilter,w
	movwf	varBPFilter
	GOTO	EndPWM	
	
; Increase PWM signal manual mode
StatIncPWM				; Button + pressed
	incf	varValReqPWM,w
	subwf	valMaxPWM,w		; Test IF maximum allow 
	btfss	STATUS,C
	GOTO	$+2
	incf	varValReqPWM,f		; IF NOT reached increase PWM value +1%
	movf	valBPFilter,w
	movwf	varBPFilter
	GOTO	EndPWM
	
; Decrease PWM signal manual mode
StatDecPWM
	btfsc	inBPNeg			; IF button - NOT pressed
	GOTO	EndPWM			; Exit
	movf	valBPFilter,w
	movwf	varBPFilter
	decfsz	varValReqPWM,f		; Test IF PWM value minimum reachead
	GOTO	EndPWM
	incf	varValReqPWM,f		; Reset PWM value to 1%
	GOTO	EndPWM


;Auto-PC mode PWM control
AutoPWM:
	;btfsc	outTimer		; TMR0 Waiting interruption output TIMER
	btfss	outTimer		; TMR1 Waiting interruption output TIMER 1
	GOTO	$-1
	;bsf	varOutTimer		; TMR0	
	bcf	varOutTimer		; TMR1
	btfss	inPWM			; IF no input PWM from PC (LOW level)
	GOTO	StatPCOFF		; reset counter
	incf	varValAutoPWM,w		; IF input HIGH level
	subwf	valMaxPWM,w		; Test maximum PWM allow
	btfss	STATUS,C		; IF reached 
	GOTO	StatPCOver		; RESET PWM output
	incf	varValAutoPWM,f		; Increase counter
	;bsf	outPWM			; Set/reset PWM output (direct)
	bsf	varOutPWM		; Indirect output set/reset
	GOTO	EndPWM

StatPCOFF
	movf	varValAutoPWM,w		; *Save current value to avoid a PWM step
	movwf	varValReqPWM		; *Can be deactivated
	clrf	varValAutoPWM		; Clear the counter to prepare next PWM generation

StatPCOver
	;bcf	outPWM			; Set/reset PWM output (direct)
	bcf	varOutPWM		; Indirect output set/reset
	movf	valMaxPWM,w		; *Save maximum value to requested PWM value
	movwf	varValReqPWM		; *Can be deactivated
	GOTO	EndPWM
	
;EndPWM
	;GOTO	LoopMainProg		; Goto main programm and wait interrupt

; Fin programme principal


;*******************************************************
;*******************************************************
; Subprogramm
;*******************************************************	
;*******************************************************
; Delay
;*******************************************************
	
; Calcul temporisation
; http://www.piclist.com/cgi-bin/delay.exe

;*******************************************************
delay200ms
			;399992 cycles
	movlw	0x35
	movwf	d1
	movlw	0xE0
	movwf	d2
	movlw	0x01
	movwf	d3
delay200ms_0
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	$+2
	decfsz	d3, f
	goto	delay200ms_0

			;4 cycles
	goto	$+1
	goto	$+1

			;4 cycles (including call)
	return
;*******************************************************
;*******************************************************	
	
	END 				; directive fin de programme
