#include "diploma.h"

uint8_t telemetria_enable;
uint16_t aramkorlat;
uint16_t sebessegkorlat;
uint16_t targytavolsag;
uint8_t cameraLight;

void UART_PC_Init(void)
{
	for(uint8_t i=0;i<60;i++)
	{
		telemetria[i] = 'x';
	}

	telemetria[0] = '#';
	telemetria[34] = 0xFF;		// encoder
	telemetria[35] = 0xFF;		// encoder
	telemetria[58] = 13;
	telemetria[59] = 10;

	/*----------USART1 INIT----------*/								// LAPTOP
    USART_InitTypeDef usart1_init_struct;
    GPIO_InitTypeDef gpioa_uart1_init_struct;

    RCC_APB2PeriphClockCmd(RCC_APB2Periph_USART1 | RCC_APB2Periph_AFIO | RCC_APB2Periph_GPIOA | RCC_APB2Periph_GPIOB, ENABLE);
    RCC_AHBPeriphClockCmd(RCC_AHBPeriph_DMA1, ENABLE);

    /* GPIOA PIN9 alternative function Tx */
    gpioa_uart1_init_struct.GPIO_Pin = GPIO_Pin_9;
    gpioa_uart1_init_struct.GPIO_Speed = GPIO_Speed_50MHz;
    gpioa_uart1_init_struct.GPIO_Mode = GPIO_Mode_AF_PP;
    GPIO_Init(GPIOA, &gpioa_uart1_init_struct);
    /* GPIOA PIN9 alternative function Rx */
    gpioa_uart1_init_struct.GPIO_Pin = GPIO_Pin_10;
    gpioa_uart1_init_struct.GPIO_Speed = GPIO_Speed_50MHz;
    gpioa_uart1_init_struct.GPIO_Mode = GPIO_Mode_IN_FLOATING;
    GPIO_Init(GPIOA, &gpioa_uart1_init_struct);

    USART_Cmd(USART1, ENABLE);
    /* Baud rate 115200, 8-bit data, One stop bit, No parity, both Rx and Tx, No HW flow control*/
    usart1_init_struct.USART_BaudRate = 115200;
    usart1_init_struct.USART_WordLength = USART_WordLength_8b;
    usart1_init_struct.USART_StopBits = USART_StopBits_1;
    usart1_init_struct.USART_Parity = USART_Parity_No;
    usart1_init_struct.USART_Mode = USART_Mode_Rx | USART_Mode_Tx;
    usart1_init_struct.USART_HardwareFlowControl = USART_HardwareFlowControl_None;
    USART_Init(USART1, &usart1_init_struct);
    USART_DMACmd(USART1, USART_DMAReq_Rx, ENABLE);
    USART_ITConfig(USART1, USART_IT_RXNE, ENABLE);


    /*-----DMA_CHANNEL4 = UART1_TX (PC) -----*/
    /*DMA_InitTypeDef DMA_UART1;

    DMA_DeInit(DMA1_Channel4);

    DMA_UART1.DMA_PeripheralBaseAddr = (uint32_t)&USART1->DR; // UART1 cime (uint32_t)&USART1->DR USART1_BASE + 0x04;
    DMA_UART1.DMA_MemoryBaseAddr = (uint32_t)&telemetria; // telemetria tomb eleje
    DMA_UART1.DMA_DIR = DMA_DIR_PeripheralDST; // receive from Memory to UART1
    DMA_UART1.DMA_BufferSize = 56;
    DMA_UART1.DMA_PeripheralInc = DMA_PeripheralInc_Disable;
    DMA_UART1.DMA_MemoryInc = DMA_MemoryInc_Enable;
    DMA_UART1.DMA_PeripheralDataSize = DMA_PeripheralDataSize_Byte;
    DMA_UART1.DMA_MemoryDataSize = DMA_MemoryDataSize_Byte;
    DMA_UART1.DMA_Mode = DMA_Mode_Circular;
    DMA_UART1.DMA_Priority = DMA_Priority_VeryHigh;
    DMA_UART1.DMA_M2M = DMA_M2M_Disable;
    DMA_Init(DMA1_Channel4, &DMA_UART1);
    //DMA_Cmd(DMA1_Channel4, ENABLE);
    DMA_ITConfig(DMA1_Channel4, DMA_IT_TC, ENABLE);

    NVIC_InitTypeDef NVIC_DMA_CH4;
   	NVIC_DMA_CH4.NVIC_IRQChannel = DMA1_Channel4_IRQn;
   	NVIC_DMA_CH4.NVIC_IRQChannelPreemptionPriority = 0;
   	NVIC_DMA_CH4.NVIC_IRQChannelSubPriority = 0;
   	NVIC_DMA_CH4.NVIC_IRQChannelCmd = ENABLE;
   	NVIC_Init(&NVIC_DMA_CH4);*/


   	/*-----DMA_CHANNEL5 = UART1_RX (PC) -----*/
   	DMA_InitTypeDef DMA_UART1_RX;

   	DMA_DeInit(DMA1_Channel5);

   	DMA_UART1_RX.DMA_PeripheralBaseAddr = (uint32_t)&USART1->DR; // UART1 cime (uint32_t)&USART1->DR USART1_BASE + 0x04;
   	DMA_UART1_RX.DMA_MemoryBaseAddr = (uint32_t)&command; // command tomb eleje
   	DMA_UART1_RX.DMA_DIR = DMA_DIR_PeripheralSRC; // receive from UART1 to Memory
   	DMA_UART1_RX.DMA_BufferSize = 8;
   	DMA_UART1_RX.DMA_PeripheralInc = DMA_PeripheralInc_Disable;
   	DMA_UART1_RX.DMA_MemoryInc = DMA_MemoryInc_Enable;
   	DMA_UART1_RX.DMA_PeripheralDataSize = DMA_PeripheralDataSize_Byte;
   	DMA_UART1_RX.DMA_MemoryDataSize = DMA_MemoryDataSize_Byte;
   	DMA_UART1_RX.DMA_Mode = DMA_Mode_Circular;
   	DMA_UART1_RX.DMA_Priority = DMA_Priority_Low;
   	DMA_UART1_RX.DMA_M2M = DMA_M2M_Disable;
   	DMA_Init(DMA1_Channel5, &DMA_UART1_RX);
   	DMA_Cmd(DMA1_Channel5, ENABLE);
   	DMA_ITConfig(DMA1_Channel5, DMA_IT_TC, ENABLE);

   	NVIC_InitTypeDef NVIC_DMA_CH5;
   	NVIC_DMA_CH5.NVIC_IRQChannel = DMA1_Channel5_IRQn;
   	NVIC_DMA_CH5.NVIC_IRQChannelPreemptionPriority = 0;
   	NVIC_DMA_CH5.NVIC_IRQChannelSubPriority = 0;
   	NVIC_DMA_CH5.NVIC_IRQChannelCmd = ENABLE;
   	NVIC_Init(&NVIC_DMA_CH5);
}

void UART_PC_Send(const unsigned char *array, uint8_t length)
{
    while(length--)
    {
    	while( !(USART1->SR & 0x00000040));
        USART_SendData(USART1, *array++);
    }
}

void commandReceived(void)
{
	uint8_t betukod;
	uint16_t code;
	float temp = 0;
	if(command[0] == '#' && command[6] == 13 && command[7] == 10)	// #...\r\n
	{
		betukod = command[1] + command[2];
		if(command[4] == 46)
		{
			code = ascii2number(command[3])*10 + ascii2number(command[5]);
		}
		else
		{
			code = ascii2number(command[3])*100 + ascii2number(command[4])*10 + ascii2number(command[5]);
		}
		switch (betukod)	// 134,138,140,142,143,145,149,150,151,154,157,158,159,160,161,162,165,166,167
		{
			case 150:	// L+J (76+74)
			{	//flaget bebillenteni, foprogramban nezni
				if(leptetoENBL == 0)
				{
					leptetoENBL = 1;
					actualStep = lepteto_stepNumber(code,1);		// 1 = jobbra
				}
				break;
			}
			case 142:	// L+B (76+66)
			{
				if(leptetoENBL == 0)
				{
					leptetoENBL = 1;
					actualStep = lepteto_stepNumber(code,0);		// 0 = balra
				}
				break;
			}
			case 143:	// L+C (76+67)
			{
				lepteto_config(code);		// lepteto motor config
				break;
			}
			case 160:	// S+M (83+77)
			{
				SZERVO_PWM = code;
				szervoPWM(SZERVO_PWM);		// 105-175, Szervo Motor szogfordulas
				break;
			}
			case 149:	// S+B (83+66)		// szervo balra
			{
				SZERVO_PWM = SZERVO_PWM + 5;
				if(SZERVO_PWM > 175)
				{
					SZERVO_PWM = 175;
				}
				szervoPWM(SZERVO_PWM);
				break;
			}
			case 157:	// S+J (83+74)		// szervo jobbra
			{
				SZERVO_PWM = SZERVO_PWM - 5;
				if(SZERVO_PWM < 105)
				{
					SZERVO_PWM = 105;
				}
				szervoPWM(SZERVO_PWM);
				break;
			}
			case 145:	// D+M (68+77)		// DC_PWM = code
			{
				DCmotor_Cmd(ENABLE, ENABLE);
				DC_PWM = code;
				if(DC_PWM == 50)
				{
					DC_motorPWM(DC_PWM);		// 50 - DC motor állj
					DCmotor_Cmd(DISABLE, DISABLE);
				}
				else
				{
					DC_motorPWM(DC_PWM);		// 40 - 60, DC Motor elore-hatra
				}
				break;
			}
			case 138:	// D+F (68+70)			// DC Forward -1 (50-40)
			{
				DCmotor_Cmd(ENABLE, ENABLE);
				if(DC_PWM == 50)
				{
					DC_PWM = 47;
				}
				else
				{
					DC_PWM = DC_PWM - 1;
				}
				if(DC_PWM == 50)
				{
					DC_motorPWM(DC_PWM);		// 50 - DC motor állj
					DCmotor_Cmd(DISABLE, DISABLE);
				}
				else if(DC_PWM < 40)
				{
					DC_PWM = 40;
					DC_motorPWM(DC_PWM);		// 40, DC Motor elore
				}
				else
				{
					DC_motorPWM(DC_PWM);		// DC Motor elore
				}
				break;
			}
			case 134:	// D+B (68+66)			// DC Backward +1 (50-60)
			{
				DCmotor_Cmd(ENABLE, ENABLE);
				if(DC_PWM == 50)
				{
					DC_PWM = 53;
				}
				else
				{
					DC_PWM = DC_PWM + 1;
				}
				if(DC_PWM == 50)
				{
					DC_motorPWM(DC_PWM);		// 50 - DC motor állj
					DCmotor_Cmd(DISABLE, DISABLE);
				}
				else if(DC_PWM > 60)
				{
					DC_PWM = 60;
					DC_motorPWM(DC_PWM);		// 60, DC Motor hatra
				}
				else
				{
					DC_motorPWM(DC_PWM);		// DC Motor hatra
				}
				break;
			}
			case 166:	// S+S (83+83)
			{
				SystemStop();		// System Stop
				break;
			}
			case 167:	// T+S (84+83)	--- Telemetria Send
			{
				telemetria_enable = code;	// 0-OFF, 1-ON
				break;
			}
			case 161:	// K+V (84+83)	--- Kamera Vilagitas
			{
				cameraLight = code;			// 0-OFF, 1-ON
				if(cameraLight == 1)
				{
					setWhiteLED();
				}
				break;
			}
			case 159:	// K+T (75+84)	--- Kapcsolouzemu Tap (4,8V) enable
			{
				if(code)		// 0-disable, 1-enable
				{
					enable_4V8();
				}
				else
				{
					disable_4V8();
				}
				break;
			}
			case 140:	// A+K (65+75)	--- aramkorlat
			{
				temp = ((float)code/10)*4096*20*0.0075/3.355;
				aramkorlat = (uint16_t)(temp);
				break;
			}
			case 158:	// S+K (83+75)	--- sebessegkorlat
			{
				temp = ((10000*3.6)/(code*12.8125));
				sebessegkorlat = (uint16_t)(temp);
				break;
			}
			case 154:	// U+E (85+69)	--- UtkozesElharito, feszultseget kap (10mV-ban)
			{
				temp = (4096*((float)code/100))/3.355;
				targytavolsag = (uint16_t)(temp);
				break;
			}
			case 151:	// R+E (82+69), --- Radio Enable
			{
				if(code)	// ENABLE
				{
					radio_on = 1;
					raspberry_on = 0;
				}
				else		// DISABLE
				{
					radio_on = 0;
					raspberry_on = 1;
				}
				break;
			}
			case 165:
			{
				NVIC_SystemReset();
				break;
			}
			case 162:	// R+P (82+80), Raspberry Parancsok
			{
				switch(code)
				{
					case 111:		// RPi feleledt
					{
						raspberry_on = 1;
						radio_on = 0;
						for(uint8_t i=0;i<15;i++)
						{
							Delay_N_x_10us(50000);	// delay 500 msec
						}
						red_led_toggle();
						break;
					}
					case 0:			// RPi close the ports
					{
						SystemStop();
						radio_on = 1;
						raspberry_on = 0;
						Raspberry_Send(command, sizeof(command));
						break;
					}
					case 1:			// RPi open the ports
					{
						SystemStop();
						radio_on = 0;
						raspberry_on = 1;
						Raspberry_Send(command, sizeof(command));
						break;
					}
					case 6:			// RPi reboot, valtas radiora
					{
						SystemStop();
						radio_on = 1;
						raspberry_on = 0;
						Raspberry_Send(command, sizeof(command));
						break;
					}
				}
			}
		}
	}
}

void DMA1_Channel5_IRQHandler(void) // USART1_RX
{
	if (DMA_GetITStatus(DMA1_IT_TC5))
	{
		// Do when RX message received
		red_led_toggle();
		commandReceived();

		DMA_ClearITPendingBit(DMA1_IT_TC5);
	}
}

uint16_t ascii2number(uint8_t data)
{
	uint16_t number;

	switch (data)
	{
		case 48:
		{
			number = 0;
			return number;
		}
		case 49:
		{
			number = 1;
			return number;
		}
		case 50:
		{
			number = 2;
			return number;
		}
		case 51:
		{
			number = 3;
			return number;
		}
		case 52:
		{
			number = 4;
			return number;
		}
		case 53:
		{
			number = 5;
			return number;
		}
		case 54:
		{
			number = 6;
			return number;
		}
		case 55:
		{
			number = 7;
			return number;
		}
		case 56:
		{
			number = 8;
			return number;
		}
		case 57:
		{
			number = 9;
			return number;
		}
		default:
		{
			return 0;
		}
	}
}
