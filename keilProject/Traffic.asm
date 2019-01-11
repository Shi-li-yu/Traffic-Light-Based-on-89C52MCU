//---------Written By Shi Liyu 2018.12.31
//		Connections:
//			Segement Enable:P0.0-P0.7;
//			Segement Control:P2.0-P2.7
//			LED Control:P1.0-P1.5
//			N-S:P1.0-GREEN1,P1.1-YELLOW1,P1.2-RED1
//			E-W:P1.3-GREEN2,P1.4-YELLOW2.P1.5-RED2 

//变量定义
		REDTIME	EQU 30H
		GREENTIME EQU 31H
//程序起点
		ORG 0000H
		LJMP MAIN
		ORG 000BH
		LJMP COUNTTIME ;定时器0中断
		ORG 0003H
		LJMP CHANMODE ;外部中断0
//主程序
		ORG 0100H
MAIN:
;1.启动检查
;2.初始化定时器0、外部中断
		MOV TMOD,#01H	   	;采用方式1
		MOV TH0,#0ECH	   	;定时5ms的定时常数
		MOV TL0,#76H
		SETB TR0		   	;启动定时器
		SETB ET0		   	;允许定时器中断
		SETB EX0			;允许外部中断
		SETB IT0			;下降沿触发方式
		SETB EA			   	;开启CPU中断
;3.定义变量初值
		MOV R0,#0
		MOV REDTIME,#25		;红灯起始25s
		MOV GREENTIME,#20	;绿灯起始20s
		MOV P0,#0FFH		;数码管全不亮
		MOV P2,#00H			;共阴数码管每段都不亮
		MOV P1,#00H			;每个发光二极管都不亮

		MOV R1,GREENTIME		;R1储存实时变化的南北时间
		MOV R2,REDTIME	;R2储存实时变化的东西时间

		SETB P1.0			;初始状态，南北绿灯亮
		SETB P1.5			;初始状态，东西红灯亮
		MOV R3,#1			;记录运行的阶段
		MOV R4,#0			;记录数码管位选信号	
		MOV R5,#0			;记录绿灯闪烁次数
		MOV R7,#0			;记录工作模式0为正常运行，1为设置模式	
;4.开始LED和SEG开始倒计时工作
LOOP:	CJNE R7,#1,WORK		;进行模式判断
		LCALL SETMODE		;R7=1,则进入设置模式
		JMP LOOP			;进行模式判断的循环

WORK:	CJNE R0,#200,LOOP	;工作模式
		MOV R0,#0			;R0=200则为1s进行倒计时时间的变化
		DEC R1
		DEC R2
		LCALL TWINKGREEN	;绿灯闪烁子程序（判断绿灯是否闪烁，是否执行闪烁）
		LCALL  STAGECHAN	;运行的阶段的判断，即一个阶段的倒计时完成之后，重新赋值
		JMP LOOP

//-----定时器0中断用于定时-----
		ORG 0300H
COUNTTIME:
		MOV TH0,#0ECH
		MOV TL0,#76H		;定时器重装	
		CJNE R7,#0,STEPR0	
		INC R0				;R0记录中断执行的次数，每执行一次加1
STEPR0:	INC R4				;R4为片选信号
		CJNE R4,#8,TODISP
		MOV R4,#0
TODISP:	LCALL DISPSEG		;根据数码管的片选信号进行显示
DONTIME:RETI

//-----外部中断0，用于模式改变-----
		ORG 0400H
CHANMODE:
		INC R7
		CJNE R7,#2,REINIT
		MOV R7,#0

REINIT:	MOV R2,#0			 ;标志位清零，一切从头开始
		MOV R3,#1			
		MOV R4,#0				
		MOV R5,#0
		MOV R1,GREENTIME
		MOV R2,REDTIME
		MOV P1,#00H
		SETB P1.0
		SETB P1.5
DONSTOP:RETI

//-----子程序-----------------------------------
;0 设置模式
SETMODE:								
CHECKEY:JB P3.3,CKEYDO
		LCALL DELAY50
		LCALL DELAY50  ;延时，消抖
WTKUP:	JB P3.3,FINUP
		JMP WTKUP	   ;等待按键弹起
FINUP:	LCALL INCTIME  ;完成按键的一次动作之后进行秒数的增加
		JMP DONSET

CKEYDO:	JB P3.4,DONSET
		LCALL DELAY50
		LCALL DELAY50  ;延时消抖
WTKUP2:	JB P3.4,FINDON ;等待按键弹起
		JMP WTKUP2	   ; 完成按键的一次动作之后进行秒数的减少
FINDON:	LCALL DECTIME
DONSET:	
		MOV R1,GREENTIME
		MOV R2,REDTIME 
		RET

;0.1设置模式时间减
INCTIME:MOV A,GREENTIME
		CJNE A,#90,INCON  ;最高绿灯时间为90s(红灯95s)
		JMP DONINC
INCON:	ADD A,#5
		MOV GREENTIME,A
		MOV A,REDTIME
		ADD A,#5
		MOV REDTIME,A
		MOV R1,GREENTIME
		MOV R2,REDTIME
DONINC: 
		MOV R1,GREENTIME
		MOV R2,REDTIME 
		RET
;0.2设置模式时间加			
DECTIME:MOV A,GREENTIME
		CJNE A,#10,DECON  ;最低绿灯时间为10s(红灯15s)
		JMP DONDEC
DECON:	SUBB A,#5
		MOV GREENTIME,A
		MOV A,REDTIME
		SUBB A,#5
		MOV REDTIME,A
		MOV R1,GREENTIME
		MOV R2,REDTIME
DONDEC:	RET
;DELAY50MS子程序（50ms）
DELAY50:MOV R6,#200
H2:		MOV R0,#125
H1:		DJNZ R0,H1
		DJNZ R6,H2
		RET
;1.绿灯闪烁子程序
TWINKGREEN:
		CJNE R3,#1,TOTAG3
		CJNE R1,#3,DONTWINK
WT1:	CJNE R0,#100,WT1
		MOV R0,#0
		CPL P1.0
		INC R5
		CJNE R5,#2,WT1
		MOV R5,#0
		DEC R1
		DEC R2
		CJNE R1,#0,WT1
		JMP DONTWINK		

TOTAG3:	CJNE R3,#3,DONTWINK
		CJNE R2,#3,DONTWINK
WT2:	CJNE R0,#100,WT2
		MOV R0,#0
		CPL P1.3
		INC R5
		CJNE R5,#2,WT2
		MOV R5,#0
		DEC R1
		DEC R2
		CJNE R2,#0,WT2
DONTWINK:RET
;2.运行阶段的判断与倒计时重新赋值子程序
STAGECHAN:		
		CJNE R1,#0,COMR2	;检查东西南北的倒计时是否为0，计数运行阶段
		JMP INCR3
COMR2:	CJNE R2,#0,DONESTAGE;都不为0，没有阶段的变化
INCR3:	INC R3

		CJNE R3,#5,STAGE1
		MOV R3,#1

STAGE1:	CJNE R3,#2,STAGE2
		MOV R1,#5
		CPL P1.0		   	;南北绿灯灭，黄灯亮
		CPL P1.1

STAGE2:	CJNE R3,#3,STAGE3
		MOV R1,REDTIME
		MOV R2,GREENTIME
		CPL P1.1
		CPL P1.2			;南北黄灯灭红灯亮
		CPL P1.5			;东西红灯灭，绿灯亮
		CPL P1.3
STAGE3:	CJNE R3,#4,STAGE4
		MOV R2,#5
		CPL P1.3
		CPL P1.4			;东西绿灯灭，黄灯亮
STAGE4:	CJNE R3,#1,DONESTAGE
		MOV R1,GREENTIME
		MOV R2,REDTIME
		CPL P1.4
		CPL P1.5			;东西黄灯灭，绿灯亮
		CPL P1.0   			;南北红灯灭，绿灯亮
		CPL P1.2
		CPL P
DONESTAGE:RET	
;3.数码管显示子程序
DISPSEG:
		MOV A,R4
		MOV DPTR,#SEGCON
		MOVC A,@A+DPTR
		MOV P0,A			;数码管使能		

		CJNE R4,#0,SEG1		;判断是哪一位数码管亮
		MOV A,R1			;如果是第一个数码管亮，则为南北显示
		MOV B,#10			
		DIV AB
		MOV DPTR,#NUM;*********************************
		MOVC A,@A+DPTR
		MOV P2,A			;显示北十位

SEG1: 	CJNE R4,#1,SEG2
		MOV A,R1
		MOV B,#10
		DIV AB
		MOV A,B
		MOV DPTR,#NUM
		MOVC A,@A+DPTR
		MOV P2,A			;显示北个位

SEG2:	CJNE R4,#2,SEG3
		MOV A,R2
		MOV B,#10
		DIV AB
		MOV DPTR,#NUM
		MOVC A,@A+DPTR
		MOV P2,A			;显示东十位

SEG3:	CJNE R4,#3,SEG4
		MOV A,R2
		MOV B,#10
		DIV AB
		MOV A,B
		MOV DPTR,#NUM
		MOVC A,@A+DPTR
		MOV P2,A			;显示东个位

SEG4:	CJNE R4,#4,SEG5
		MOV A,R1
		MOV B,#10
		DIV AB
		MOV DPTR,#NUM
		MOVC A,@A+DPTR
		MOV P2,A			;显示南十位

SEG5: 	CJNE R4,#5,SEG6
		MOV A,R1
		MOV B,#10
		DIV AB
		MOV A,B
		MOV DPTR,#NUM
		MOVC A,@A+DPTR
		MOV P2,A			;显示南个位

SEG6:	CJNE R4,#6,SEG7
		MOV A,R2
		MOV B,#10
		DIV AB
		MOV DPTR,#NUM
		MOVC A,@A+DPTR
		MOV P2,A			 ;显示西十位

SEG7:	CJNE R4,#7,FINDISP
		MOV A,R2
		MOV B,#10
		DIV AB
		MOV A,B
		MOV DPTR,#NUM
		MOVC A,@A+DPTR
		MOV P2,A			 ;显示西个位
FINDISP:RET					 ;结束显示，程序返回
	;数组：NUM控制数码管显示数字，SEGCON控制数码管使能信号（数码管低电平亮）
NUM: DB 3FH,06H,5BH,4FH,66H,6DH,7DH,07H,7FH,6FH
SEGCON: DB 0FEH,0FDH,0FBH,0F7H,0EFH,0DFH,0BFH,07FH
		END
