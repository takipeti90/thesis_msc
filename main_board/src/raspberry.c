#include "diploma.h"

uint8_t raspberry_uartBuff;
uint8_t raspberry_uartBuffNum;

void Raspberry_Init(void)
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

	raspberry_uartBuffNum = 0;

	/*----------USART2 INIT----------*/								// RASPBERRY PI
    USART_InitTypeDef usart2_init_struct;
    GPIO_InitTypeDef gpioa_uart2_init_struct;

    RCC_APB1PeriphClockCmd(RCC_APB1Periph_USART2, ENABLE);

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
    //USART_DMACmd(USART2, USART_DMAReq_Rx, ENABLE);
    USART_ITConfig(USART2, USART_IT_RXNE, ENABLE);

    NVIC_InitTypeDef NVIC_UART2;
    NVIC_UART2.NVIC_IRQChannel = USART2_IRQn;
    NVIC_UART2.NVIC_IRQChannelPreemptionPriority = 0;
    NVIC_UART2.NVIC_IRQChannelSubPriority = 0;
    NVIC_UART2.NVIC_IRQChannelCmd = ENABLE;
    NVIC_Init(&NVIC_UART2);


    /*-----DMA_CHANNEL7 = UART2_TX (RASPBERRY PI) -----*/
    /*DMA_InitTypeDef DMA_UART2;

    DMA_DeInit(DMA1_Channel4);

    DMA_UART2.DMA_PeripheralBaseAddr = (uint32_t)&USART2->DR; // UART2 cime
    DMA_UART2.DMA_MemoryBaseAddr = (uint32_t)&telemetria; // telemetria tomb eleje
    DMA_UART2.DMA_DIR = DMA_DIR_PeripheralDST; // receive from Memory to UART2
    DMA_UART2.DMA_BufferSize = 56;
    DMA_UART2.DMA_PeripheralInc = DMA_PeripheralInc_Disable;
    DMA_UART2.DMA_MemoryInc = DMA_MemoryInc_Enable;
    DMA_UART2.DMA_PeripheralDataSize = DMA_PeripheralDataSize_Byte;
    DMA_UART2.DMA_MemoryDataSize = DMA_MemoryDataSize_Byte;
    DMA_UART2.DMA_Mode = DMA_Mode_Circular;
    DMA_UART2.DMA_Priority = DMA_Priority_VeryHigh;
    DMA_UART2.DMA_M2M = DMA_M2M_Disable;
    DMA_Init(DMA1_Channel7, &DMA_UART2);
    //DMA_Cmd(DMA1_Channel7, ENABLE);
    DMA_ITConfig(DMA1_Channel7, DMA_IT_TC, ENABLE);

    NVIC_InitTypeDef NVIC_DMA_CH7;
    NVIC_DMA_CH7.NVIC_IRQChannel = DMA1_Channel7_IRQn;
   	NVIC_DMA_CH7.NVIC_IRQChannelPreemptionPriority = 1;
    NVIC_DMA_CH7.NVIC_IRQChannelSubPriority = 0;
    NVIC_DMA_CH7.NVIC_IRQChannelCmd = ENABLE;
    NVIC_Init(&NVIC_DMA_CH7);*/


    /*-----DMA_CHANNEL6 = UART2_RX (RASPBERRY PI) -----*/
    /*DMA_InitTypeDef DMA_UART2_RX;

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
   	DMA_UART2_RX.DMA_Priority = DMA_Priority_Low;
   	DMA_UART2_RX.DMA_M2M = DMA_M2M_Disable;
   	DMA_Init(DMA1_Channel6, &DMA_UART2_RX);
   	DMA_Cmd(DMA1_Channel6, ENABLE);
   	DMA_ITConfig(DMA1_Channel6, DMA_IT_TC, ENABLE);

   	NVIC_InitTypeDef NVIC_DMA_CH6;
   	NVIC_DMA_CH6.NVIC_IRQChannel = DMA1_Channel6_IRQn;
   	NVIC_DMA_CH6.NVIC_IRQChannelPreemptionPriority = 0;
   	NVIC_DMA_CH6.NVIC_IRQChannelSubPriority = 0;
   	NVIC_DMA_CH6.NVIC_IRQChannelCmd = ENABLE;
   	NVIC_Init(&NVIC_DMA_CH6);*/
}

void Raspberry_Send(const unsigned char *array, uint8_t length)
{
	while(length--)
	{
		while( !(USART2->SR & 0x00000040));
		USART_SendData(USART2, *array++);
	}
}


void USART2_IRQHandler(void) // USART2_RX
{
	if (USART_GetITStatus(USART2, USART_IT_RXNE))
	{
		raspberry_uartBuff = USART_ReceiveData(USART2);
		while( !(USART1->SR & 0x00000040));
		USART_SendData(USART1, raspberry_uartBuff);
		if(raspberry_uartBuff == '#')
		{
			command[0] = raspberry_uartBuff;
			raspberry_uartBuffNum = 1;
		}
		else
		{
			command[raspberry_uartBuffNum] = raspberry_uartBuff;
			raspberry_uartBuffNum++;
		}
		if (raspberry_uartBuffNum == 8 && command[raspberry_uartBuffNum-2] == 13 && command[raspberry_uartBuffNum-1] == 10)	// &&
		{
			red_led_toggle();
			//UART_PC_Send(command, sizeof(command));
			commandReceived();
		}
		if (raspberry_uartBuffNum == 8)
		{
			raspberry_uartBuffNum = 0;
		}
		//blue_led_toggle();
		USART_ClearITPendingBit(USART2, USART_IT_RXNE);
	}
}


/*void DMA1_Channel7_IRQHandler(void) // USART2_TX
{
	if (DMA_GetITStatus(DMA1_IT_TC7))
	{
		DMA_Cmd(DMA1_Channel7, DISABLE);
		red_led_toggle();
		DMA_ClearITPendingBit(DMA1_IT_TC7);
	}
}*/

/*void DMA1_Channel6_IRQHandler(void) // USART2_RX
{
	if (DMA_GetITStatus(DMA1_IT_TC6))
	{
		// Do when RX message received
		red_led_toggle();
		commandReceived();

		DMA_ClearITPendingBit(DMA1_IT_TC6);
	}
}*/
