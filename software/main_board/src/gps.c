#include "diploma.h"

uint8_t gps_dma;
uint8_t gps_data[82];
uint8_t gps_data_number = 0;
uint8_t telemetria_number = 1;

void GPS_Init(void)
{
	/*----------USART3 INIT----------*/								// GPS
    USART_InitTypeDef usart3_init_struct;
    GPIO_InitTypeDef gpiob_uart3_init_struct;

    RCC_APB1PeriphClockCmd(RCC_APB1Periph_USART3, ENABLE);

    /* GPIOB PIN11 alternative function Rx */
    gpiob_uart3_init_struct.GPIO_Pin = GPIO_Pin_11;					// GPS, only receive
    gpiob_uart3_init_struct.GPIO_Speed = GPIO_Speed_50MHz;
    gpiob_uart3_init_struct.GPIO_Mode = GPIO_Mode_IN_FLOATING;
    GPIO_Init(GPIOB, &gpiob_uart3_init_struct);

    USART_Cmd(USART3, ENABLE);
    /* Baud rate 4800, 8-bit data, One stop bit, No parity, only Rx, No HW flow control*/
    usart3_init_struct.USART_BaudRate = 4800;
    usart3_init_struct.USART_WordLength = USART_WordLength_8b;
    usart3_init_struct.USART_StopBits = USART_StopBits_1;
    usart3_init_struct.USART_Parity = USART_Parity_No;
    usart3_init_struct.USART_Mode = USART_Mode_Rx;
    usart3_init_struct.USART_HardwareFlowControl = USART_HardwareFlowControl_None;
    USART_Init(USART3, &usart3_init_struct);
    //USART_DMACmd(USART3, USART_DMAReq_Rx, ENABLE);
    USART_ITConfig(USART3, USART_IT_RXNE, ENABLE);

    NVIC_InitTypeDef NVIC_UART3;
    NVIC_UART3.NVIC_IRQChannel = USART3_IRQn;
    NVIC_UART3.NVIC_IRQChannelPreemptionPriority = 3;
    NVIC_UART3.NVIC_IRQChannelSubPriority = 0;
    NVIC_UART3.NVIC_IRQChannelCmd = ENABLE;
    NVIC_Init(&NVIC_UART3);


    /*-----DMA_CHANNEL3 = UART3_RX (GPS) -----*/
    /*DMA_InitTypeDef DMA_UART3_RX;

    RCC_AHBPeriphClockCmd(RCC_AHBPeriph_DMA1, ENABLE);

    DMA_DeInit(DMA1_Channel3);
   	DMA_UART3_RX.DMA_PeripheralBaseAddr = (uint32_t)&USART3->DR;
    DMA_UART3_RX.DMA_MemoryBaseAddr = (uint32_t)&gps_dma;
    DMA_UART3_RX.DMA_DIR = DMA_DIR_PeripheralSRC; // receive from UART3 to Memory
    DMA_UART3_RX.DMA_BufferSize = 1;
    DMA_UART3_RX.DMA_PeripheralInc = DMA_PeripheralInc_Disable;
    DMA_UART3_RX.DMA_MemoryInc = DMA_MemoryInc_Enable;
    DMA_UART3_RX.DMA_PeripheralDataSize = DMA_PeripheralDataSize_Byte;
    DMA_UART3_RX.DMA_MemoryDataSize = DMA_MemoryDataSize_Byte;
    DMA_UART3_RX.DMA_Mode = DMA_Mode_Circular;
    DMA_UART3_RX.DMA_Priority = DMA_Priority_High;
    DMA_UART3_RX.DMA_M2M = DMA_M2M_Disable;
    DMA_Init(DMA1_Channel3, &DMA_UART3_RX);
    DMA_Cmd(DMA1_Channel3, ENABLE);
    DMA_ITConfig(DMA1_Channel3, DMA_IT_TC, ENABLE);

    NVIC_InitTypeDef NVIC_DMA_CH3;
    NVIC_DMA_CH3.NVIC_IRQChannel = DMA1_Channel3_IRQn;
    NVIC_DMA_CH3.NVIC_IRQChannelPreemptionPriority = 2;
    NVIC_DMA_CH3.NVIC_IRQChannelSubPriority = 0;
    NVIC_DMA_CH3.NVIC_IRQChannelCmd = ENABLE;
    NVIC_Init(&NVIC_DMA_CH3);*/
}

void USART3_IRQHandler(void) // USART3_RX
{
	if (USART_GetITStatus(USART3, USART_IT_RXNE))
	{
		//USART_SendData(USART1, gps_dma);
		//while(!(USART1->SR & 0x00000040));
		gps_dma = USART_ReceiveData(USART3);
		if (gps_dma == '$'  && gps_data_number == 0)
		{
			gps_data_number = 1;
			gps_data[gps_data_number-1] = gps_dma;
		}
		if (gps_dma == 10 && gps_data_number != 0) // CR = 13, LF = 10
		{
			gps_data[gps_data_number] = gps_dma;	// itt a gps_data_number pont a tomb meretevel egyenlo

			//-----GGA uzenet feldolgozasa-----
			uint8_t vesszo1_helye, vesszo2_helye, vesszo_darab = 0;
			for (vesszo1_helye = 4; vesszo_darab <= 9; vesszo1_helye++)
			{
				if (gps_data[vesszo1_helye] == ',')
				{
					vesszo_darab++;
					if (vesszo_darab == 2 || vesszo_darab == 4 || vesszo_darab == 6 || vesszo_darab == 7 || vesszo_darab == 8 || vesszo_darab == 9)
					{
						for (vesszo2_helye = vesszo1_helye + 1; ;vesszo2_helye++)
						{
							if (gps_data[vesszo2_helye] == ',')
							{
								if (vesszo_darab == 8)
								{
									telemetria_number = 27;
									for(uint8_t j = vesszo2_helye - 1; j > vesszo1_helye ; j--)
									{
										telemetria[telemetria_number] = gps_data[j];
										telemetria_number--;
									}
								}
								else if (vesszo_darab == 9)
								{
									telemetria_number = 33;
									for(uint8_t j = vesszo2_helye - 1; j > vesszo1_helye ; j--)
									{
										telemetria[telemetria_number] = gps_data[j];
										telemetria_number--;
									}
								}
								else
								{
									for (uint8_t i = vesszo1_helye + 1; i < vesszo2_helye; i++)
									{
										telemetria[telemetria_number] = gps_data[i];
										telemetria_number++;
									}
									if (vesszo_darab != 6 && vesszo_darab != 7 && vesszo_darab != 8)
									{
										vesszo_darab++;
										vesszo1_helye = vesszo2_helye + 1;
									}
									else
									{
										vesszo1_helye = vesszo2_helye - 1;
									}
								}
								break;
							}
						}
					}
				}
			}
			vesszo_darab = 0;
			telemetria_number = 1;
			gps_data_number = 0;
		}
		if (gps_data_number != 0 && gps_dma != '$')
		{
			if(gps_dma != 'G' && gps_data_number == 4) // ha nem GGA uzenet jott
			{
				gps_data_number = 0;
				return;
			}
			gps_data_number++;
			gps_data[gps_data_number-1] = gps_dma;
		}
		USART_ClearITPendingBit(USART3, USART_IT_RXNE);
	}
}

/*
void DMA1_Channel3_IRQHandler(void) // USART3_RX
{
	if (DMA_GetITStatus(DMA1_IT_TC3))
	{
		//USART_SendData(USART1, gps_dma);
		//while(!(USART1->SR & 0x00000040));
		if (gps_dma == '$'  && gps_data_number == 0)
		{
			gps_data_number = 1;
			gps_data[gps_data_number-1] = gps_dma;
		}
		if (gps_dma == 10 && gps_data_number != 0) // CR = 13, LF = 10
		{
			gps_data[gps_data_number] = gps_dma;	// itt a gps_data_number pont a tomb meretevel egyenlo

			//-----GGA uzenet feldolgozasa-----
			uint8_t vesszo1_helye, vesszo2_helye, vesszo_darab = 0;
			for (vesszo1_helye = 4; vesszo_darab <= 9; vesszo1_helye++)
			{
				if (gps_data[vesszo1_helye] == ',')
				{
					vesszo_darab++;
					if (vesszo_darab == 2 || vesszo_darab == 4 || vesszo_darab == 6 || vesszo_darab == 7 || vesszo_darab == 8 || vesszo_darab == 9)
					{
						for (vesszo2_helye = vesszo1_helye + 1; ;vesszo2_helye++)
						{
							if (gps_data[vesszo2_helye] == ',')
							{
								if (vesszo_darab == 8)
								{
									telemetria_number = 27;
									for(uint8_t j = vesszo2_helye - 1; j > vesszo1_helye ; j--)
									{
										telemetria[telemetria_number] = gps_data[j];
										telemetria_number--;
									}
								}
								else if (vesszo_darab == 9)
								{
									telemetria_number = 33;
									for(uint8_t j = vesszo2_helye - 1; j > vesszo1_helye ; j--)
									{
										telemetria[telemetria_number] = gps_data[j];
										telemetria_number--;
									}
								}
								else
								{
									for (uint8_t i = vesszo1_helye + 1; i < vesszo2_helye; i++)
									{
										telemetria[telemetria_number] = gps_data[i];
										telemetria_number++;
									}
									if (vesszo_darab != 6 && vesszo_darab != 7 && vesszo_darab != 8)
									{
										vesszo_darab++;
										vesszo1_helye = vesszo2_helye + 1;
									}
									else
									{
										vesszo1_helye = vesszo2_helye - 1;
									}
								}
								break;
							}
						}
					}
				}
			}
			vesszo_darab = 0;
			telemetria_number = 1;
			gps_data_number = 0;
		}
		if (gps_data_number != 0 && gps_dma != '$')
		{
			if(gps_dma != 'G' && gps_data_number == 4) // ha nem GGA uzenet jott
			{
				gps_data_number = 0;
				return;
			}
			gps_data_number++;
			gps_data[gps_data_number-1] = gps_dma;
		}
		DMA_ClearITPendingBit(DMA1_IT_TC3);
	}
}*/
