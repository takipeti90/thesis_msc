#include "usb_radio.h"

uint8_t uartBuffNum = 0;
uint8_t uartBuff = 0;

//----------------------------RCC CONFIG----------------------------------
void clock_Init(void)
{
	RCC_DeInit();
	RCC_HSEConfig(RCC_HSE_OFF);
	RCC_HSICmd(ENABLE);

	FLASH_SetLatency(FLASH_Latency_2);

    RCC_PLLConfig(RCC_PLLSource_HSI_Div2, RCC_PLLMul_16);
    RCC_PLLCmd(ENABLE);
    while(RCC_GetFlagStatus(RCC_FLAG_PLLRDY) == RESET);
    RCC_SYSCLKConfig(RCC_SYSCLKSource_PLLCLK);

    /* Set HCLK, PCLK1, and PCLK2 to SCLK */
    RCC_HCLKConfig(RCC_SYSCLK_Div1);	// 64 MHz - AHB
    RCC_PCLK1Config(RCC_HCLK_Div2);		// 32 MHz - APB1
    RCC_PCLK2Config(RCC_HCLK_Div1);		// 64 MHz - APB2

    while(RCC_GetSYSCLKSource() != 0x08);

    timer1_Init();
    timer2_Init();

    // group 4 -> only pre-emption priority (0-15)
    NVIC_PriorityGroupConfig(NVIC_PriorityGroup_4);
}

void timer1_Init(void)
{
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_TIM1, ENABLE);

	TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;
	TIM_TimeBaseStructure.TIM_Period = 50000; 	//	max 500 mSec
	TIM_TimeBaseStructure.TIM_Prescaler = 639;	// 100 kHz - 10 us
	TIM_TimeBaseStructure.TIM_ClockDivision = 0;
	TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
	TIM_TimeBaseInit(TIM1, &TIM_TimeBaseStructure);
}

void timer2_Init(void)
{
	RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM2, ENABLE);

	TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;
	TIM_TimeBaseStructure.TIM_Period = 10000; 	//	max 5000 mSec
	TIM_TimeBaseStructure.TIM_Prescaler = 6399;	// 10 kHz - 100 us
	TIM_TimeBaseStructure.TIM_ClockDivision = 0;
	TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
	TIM_TimeBaseInit(TIM2, &TIM_TimeBaseStructure);
	TIM_ITConfig(TIM2, TIM_IT_Update, ENABLE);

	NVIC_InitTypeDef NVIC_TIM2;
    NVIC_TIM2.NVIC_IRQChannel = TIM2_IRQn;
	NVIC_TIM2.NVIC_IRQChannelPreemptionPriority = 1;
	NVIC_TIM2.NVIC_IRQChannelSubPriority = 0;
	NVIC_TIM2.NVIC_IRQChannelCmd = ENABLE;
	NVIC_Init(&NVIC_TIM2);
}

void Delay_N_x_10us(uint16_t delay)		// max 500 mSec -> delay = 50000
{
	if(delay > 50000)
	{
		delay = 50000;
	}
	TIM1->CNT = 0;
	TIM_Cmd(TIM1, ENABLE);
	while (TIM1->CNT != delay);
	TIM_Cmd(TIM1, DISABLE);
}

void count_N_x_100us(uint16_t count)		// max 5000 mSec -> count = 50000
{
	if(count > 50000)
	{
		count = 50000;
	}
	TIM2->CNT = 0;
	TIM2->ARR = (uint16_t)count;
	TIM_Cmd(TIM2, ENABLE);
}

void MCO_out(void) // PIN29
{
	GPIO_InitTypeDef mco;

	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA, ENABLE);
	mco.GPIO_Pin = GPIO_Pin_8;
	mco.GPIO_Speed = GPIO_Speed_50MHz;
	mco.GPIO_Mode = GPIO_Mode_AF_PP;
	GPIO_Init(GPIOA,&mco);
	RCC_MCOConfig(RCC_MCO_PLLCLK_Div2);	// 32 MHz
}


//----------------------------GPIO CONFIG----------------------------------
void GPIO_Init_all(void)
{
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA | RCC_APB2Periph_GPIOB | RCC_APB2Periph_AFIO, ENABLE);
	GPIO_PinRemapConfig(GPIO_Remap_SWJ_JTAGDisable, ENABLE);	// PA15, PB3, PB4 enabled, JTDI, JTDO, NJTRST disabled

	//GPIOA Init
	GPIO_InitTypeDef gpioa_output = { RED_LED | nRESET_USBUART, GPIO_Speed_50MHz, GPIO_Mode_Out_PP };
	GPIO_Init(GPIOA, &gpioa_output);

	GPIO_SetBits(GPIOA, nRESET_USBUART);

	//GPIOB Init
	GPIO_InitTypeDef gpiob_output = { BLUE_LED, GPIO_Speed_50MHz, GPIO_Mode_Out_PP };
	GPIO_Init(GPIOB, &gpiob_output);
}

void setBlueLED(void)
{
	GPIO_SetBits(GPIOB, BLUE_LED);
}

void setRedLED(void)
{
	GPIO_SetBits(GPIOA, RED_LED);
}

void resetBlueLED(void)
{
	GPIO_ResetBits(GPIOB, BLUE_LED);
}

void resetRedLED(void)
{
	GPIO_ResetBits(GPIOA, RED_LED);
}

void blue_led_toggle(void)
{
    uint8_t led_bit = GPIO_ReadOutputDataBit(GPIOB, BLUE_LED);

    if(led_bit == (uint8_t)Bit_SET)
    {
        GPIO_ResetBits(GPIOB, BLUE_LED);
    }
    else
    {
        GPIO_SetBits(GPIOB, BLUE_LED);
    }
}

void red_led_toggle(void)
{
    uint8_t led_bit = GPIO_ReadOutputDataBit(GPIOA, RED_LED);

    if(led_bit == (uint8_t)Bit_SET)
    {
        GPIO_ResetBits(GPIOA, RED_LED);
    }
    else
    {
        GPIO_SetBits(GPIOA, RED_LED);
    }
}


//----------------------------UART2 CONFIG----------------------------------
void UART_PC_Init(void)
{
	for(uint8_t i=0;i<7;i++)
	{
		command[i] = 'x';
	}

	/*----------USART2 INIT----------*/								// LAPTOP
    USART_InitTypeDef usart2_init_struct;
    GPIO_InitTypeDef gpioa_uart2_init_struct;

    RCC_APB1PeriphClockCmd(RCC_APB1Periph_USART2, ENABLE);
    RCC_APB2PeriphClockCmd(RCC_APB2Periph_AFIO, ENABLE);
    RCC_AHBPeriphClockCmd(RCC_AHBPeriph_DMA1, ENABLE);

    /* GPIOA PIN2 alternative function Tx */
    gpioa_uart2_init_struct.GPIO_Pin = GPIO_Pin_2;
    gpioa_uart2_init_struct.GPIO_Speed = GPIO_Speed_50MHz;
    gpioa_uart2_init_struct.GPIO_Mode = GPIO_Mode_AF_PP;
    GPIO_Init(GPIOA, &gpioa_uart2_init_struct);
    /* GPIOA PIN3 alternative function Rx */
    gpioa_uart2_init_struct.GPIO_Pin = GPIO_Pin_3;
    gpioa_uart2_init_struct.GPIO_Speed = GPIO_Speed_50MHz;
    gpioa_uart2_init_struct.GPIO_Mode = GPIO_Mode_IN_FLOATING;
    GPIO_Init(GPIOA, &gpioa_uart2_init_struct);

    USART_Cmd(USART2, ENABLE);
    /* Baud rate 115200, 8-bit data, One stop bit, No parity, both Rx and Tx, No HW flow control*/
    usart2_init_struct.USART_BaudRate = 115200;
    usart2_init_struct.USART_WordLength = USART_WordLength_8b;
    usart2_init_struct.USART_StopBits = USART_StopBits_1;
    usart2_init_struct.USART_Parity = USART_Parity_No;
    usart2_init_struct.USART_Mode = USART_Mode_Rx | USART_Mode_Tx;
    usart2_init_struct.USART_HardwareFlowControl = USART_HardwareFlowControl_None;
    USART_Init(USART2, &usart2_init_struct);
    USART_DMACmd(USART2, USART_DMAReq_Rx, ENABLE);
    /*USART_ITConfig(USART2, USART_IT_RXNE, ENABLE);

    NVIC_InitTypeDef NVIC_UART2;
    NVIC_UART2.NVIC_IRQChannel = USART2_IRQn;
    NVIC_UART2.NVIC_IRQChannelPreemptionPriority = 0;
    NVIC_UART2.NVIC_IRQChannelSubPriority = 0;
    NVIC_UART2.NVIC_IRQChannelCmd = ENABLE;
    NVIC_Init(&NVIC_UART2);*/


   	/*-----DMA_CHANNEL6 = UART2_RX (PC) -----*/
   	DMA_InitTypeDef DMA_UART2_RX;
   	DMA_DeInit(DMA1_Channel6);
   	DMA_UART2_RX.DMA_PeripheralBaseAddr = (uint32_t)&USART2->DR; // UART2 cime
   	DMA_UART2_RX.DMA_MemoryBaseAddr = (uint32_t)&command; // command tomb eleje
   	DMA_UART2_RX.DMA_DIR = DMA_DIR_PeripheralSRC; // receive from UART2 to Memory
   	DMA_UART2_RX.DMA_BufferSize = 8;
   	DMA_UART2_RX.DMA_PeripheralInc = DMA_PeripheralInc_Disable;
   	DMA_UART2_RX.DMA_MemoryInc = DMA_MemoryInc_Enable;
   	DMA_UART2_RX.DMA_PeripheralDataSize = DMA_PeripheralDataSize_Byte;
   	DMA_UART2_RX.DMA_MemoryDataSize = DMA_MemoryDataSize_Byte;
   	DMA_UART2_RX.DMA_Mode = DMA_Mode_Circular;
   	DMA_UART2_RX.DMA_Priority = DMA_Priority_VeryHigh;
   	DMA_UART2_RX.DMA_M2M = DMA_M2M_Disable;
   	DMA_Init(DMA1_Channel6, &DMA_UART2_RX);
   	DMA_Cmd(DMA1_Channel6, ENABLE);
   	DMA_ITConfig(DMA1_Channel6, DMA_IT_TC, ENABLE);

   	NVIC_InitTypeDef NVIC_DMA_CH6;
   	NVIC_DMA_CH6.NVIC_IRQChannel = DMA1_Channel6_IRQn;
   	NVIC_DMA_CH6.NVIC_IRQChannelPreemptionPriority = 0;
   	NVIC_DMA_CH6.NVIC_IRQChannelSubPriority = 0;
   	NVIC_DMA_CH6.NVIC_IRQChannelCmd = ENABLE;
   	NVIC_Init(&NVIC_DMA_CH6);
}

void UART_PC_Send(const unsigned char *array, uint8_t length)
{
    while(length--)
    {
    	while(!(USART2->SR & 0x00000040));
        USART_SendData(USART2, *array++);
    }
}


//---------------------------- INTERRUPTS ----------------------------------
void DMA1_Channel6_IRQHandler(void) // USART2_RX
{
	if (DMA_GetITStatus(DMA1_IT_TC6))
	{
		if(command[0] == '#' && command[6] == 13 && command[7] == 10)
		{
			blue_led_toggle();
			radio_send = 1;		// sending in main.c
		}
		else
		{
			red_led_toggle();
		}

		DMA_ClearITPendingBit(DMA1_IT_TC6);
	}
}

/*void USART2_IRQHandler(void) // USART2_RX
{
	if (USART_GetITStatus(USART2, USART_IT_RXNE))
	{
		uartBuff = USART_ReceiveData(USART2);
		if(uartBuff == '#')
		{
			command[0] = uartBuff;
			uartBuffNum = 1;
		}
		else
		{
			command[uartBuffNum] = uartBuff;
			uartBuffNum++;
		}
		if (uartBuffNum == 7 && command[uartBuffNum-1] == '*')	// &&
		{
			radio_send = 1;
		}
		if (uartBuffNum == 7)
		{
			uartBuffNum = 0;
		}
		USART_ClearITPendingBit(USART2, USART_IT_RXNE);
	}
}*/

void TIM2_IRQHandler(void)
{
    if (TIM_GetITStatus(TIM2, TIM_IT_Update) != RESET)
    {
    	TIM_Cmd(TIM2, DISABLE);
    	resetBlueLED();
    	resetRedLED();
        TIM_ClearITPendingBit(TIM2, TIM_IT_Update);
    }
}
