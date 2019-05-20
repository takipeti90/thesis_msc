#include "diploma.h"

uint8_t radio_cfg_data_array[] = RADIO_CONFIGURATION_DATA_ARRAY;

void radio_Init(void)
{
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOE, ENABLE);
	GPIO_InitTypeDef gpioe_input = { nIRQ | GPIO0 | GPIO1, GPIO_Speed_50MHz, GPIO_Mode_IN_FLOATING };
	GPIO_InitTypeDef gpioe_output = { SDN | nSEL, GPIO_Speed_50MHz, GPIO_Mode_Out_PP };
	GPIO_Init(GPIOE, &gpioe_input);
	GPIO_Init(GPIOE, &gpioe_output);

	GPIO_SetBits(GPIOE, SDN);
	GPIO_SetBits(GPIOE, nSEL);

	/*---------SPI2 INIT--------*/
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOB | RCC_APB2Periph_AFIO, ENABLE);
	GPIO_InitTypeDef gpiob_spi_in = { MISO, GPIO_Speed_50MHz, GPIO_Mode_IN_FLOATING };
	GPIO_InitTypeDef gpiob_spi_out = { MOSI | SCLK, GPIO_Speed_50MHz, GPIO_Mode_AF_PP };
	GPIO_Init(GPIOB, &gpiob_spi_in);
	GPIO_Init(GPIOB, &gpiob_spi_out);

	RCC_APB1PeriphClockCmd(RCC_APB1Periph_SPI2, ENABLE);
	SPI_I2S_DeInit(SPI2);
	SPI_InitTypeDef SPI2_InitStructure;
	SPI2_InitStructure.SPI_Direction = SPI_Direction_2Lines_FullDuplex;
	SPI2_InitStructure.SPI_Mode = SPI_Mode_Master;
	SPI2_InitStructure.SPI_DataSize = SPI_DataSize_8b;
	SPI2_InitStructure.SPI_CPOL = SPI_CPOL_Low;		// first rising edge
	SPI2_InitStructure.SPI_CPHA = SPI_CPHA_1Edge;
	SPI2_InitStructure.SPI_NSS = SPI_NSS_Soft;		// software SlaveSelect
	SPI2_InitStructure.SPI_BaudRatePrescaler = SPI_BaudRatePrescaler_4;	// 36MHz/4 = 9 MHz
	SPI2_InitStructure.SPI_FirstBit = SPI_FirstBit_MSB;
	SPI2_InitStructure.SPI_CRCPolynomial = 7;
	SPI_Init(SPI2, &SPI2_InitStructure);
	//SPI_I2S_ITConfig(SPI2, SPI_I2S_IT_RXNE, ENABLE);
	SPI_CalculateCRC(SPI2, DISABLE);
	SPI_Cmd(SPI2, ENABLE);

	radio_Cmd(ENABLE);
	radio_config();
	Delay_N_x_10us(50000);

	/*GPIO_EXTILineConfig(GPIO_PortSourceGPIOE,GPIO_PinSource15);		// nIRQ interrupt
	// Configure EXTI15 line
	EXTI_InitTypeDef EXTI_InitStructure;
	EXTI_InitStructure.EXTI_Line = EXTI_Line15;
	EXTI_InitStructure.EXTI_Mode = EXTI_Mode_Interrupt;
	EXTI_InitStructure.EXTI_Trigger = EXTI_Trigger_Falling;
	EXTI_InitStructure.EXTI_LineCmd = ENABLE;
	EXTI_Init(&EXTI_InitStructure);

	NVIC_InitTypeDef NVIC_EXTI15;
	NVIC_EXTI15.NVIC_IRQChannel = EXTI15_10_IRQn;
	NVIC_EXTI15.NVIC_IRQChannelPreemptionPriority = 0;
	NVIC_EXTI15.NVIC_IRQChannelSubPriority = 0;
	NVIC_EXTI15.NVIC_IRQChannelCmd = ENABLE;
	NVIC_Init(&NVIC_EXTI15);*/
}

void radio_Cmd(FunctionalState state)
{
	if (state != DISABLE)
	{
		/* Enable */
		GPIO_ResetBits(GPIOE, SDN);
		while(!GPIO_ReadInputDataBit(GPIOE, GPIO0));	// amig GPIO0 (POR) != 1
		while(!GPIO_ReadInputDataBit(GPIOE, GPIO1));	// amig GPIO1 (CTS) != 1
	}
	else
	{
	    /* Disable */
		GPIO_SetBits(GPIOE, SDN);
	}
}

void radio_config(void)
{
	uint16_t index = 0;
	uint8_t cmdSize;

	while(index < sizeof(radio_cfg_data_array))
	{
		cmdSize = radio_cfg_data_array[index];
		GPIO_ResetBits(GPIOE, nSEL);
		for(uint8_t i = 0; i < cmdSize; i++)
		{
			SPI_I2S_SendData(SPI2, radio_cfg_data_array[index + 1 + i]);
			while(SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
		}
		GPIO_SetBits(GPIOE, nSEL);
		index = index + (cmdSize + 1);
		radio_WaitforCTS();
	}
	radio_GetIntStatus();
}

void radio_SendCommand(uint8_t length, const unsigned char *radioCommand) // Send a command + data to the chip
{
	GPIO_ResetBits(GPIOE, nSEL); // select radio IC by pulling its nSEL pin low
	spi_SendDataNoResp(length, radioCommand); // Send data array to the radio IC via SPI
	while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_BSY) == SET);
	GPIO_SetBits(GPIOE, nSEL); // de-select radio IC by putting its nSEL pin high
}

uint8_t radio_WaitforCTS(void)
{
	uint8_t CtsValue = 0, dummy = 0xAA;
	uint16_t ErrCnt = 0;
	unsigned char errorString[] = "CTS waiting overrun!";

	while (CtsValue != 0xFF) // Wait until radio IC is ready with the data
	{
		GPIO_ResetBits(GPIOE, nSEL); // select radio IC by pulling its nSEL pin low
		SPI_I2S_ReceiveData(SPI2);		//??????????????????????	just to clear RXNE bit if it is set
		SPI_I2S_SendData(SPI2, READ_CMD_BUFF); // Read command buffer; send command byte (CTS = 0x44)
		while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
		while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_RXNE) == RESET);
		SPI_I2S_ReceiveData(SPI2);
		SPI_I2S_SendData(SPI2, dummy);
		while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
		while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_RXNE) == RESET);
		CtsValue = SPI_I2S_ReceiveData(SPI2);
		while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_BSY) == SET);
		GPIO_SetBits(GPIOE, nSEL); // If CTS is not 0xFF, put nSEL high and stay in waiting
		if (++ErrCnt > MAX_CTS_WAIT)
		{
			UART_PC_Send(errorString, sizeof(errorString));
			return 1; // Error handling; if wrong CTS reads exceeds a limit
		}
	}
	return 0;
}

uint8_t radio_GetResponse(uint8_t length) //Get response from the chip (used after a command)
{
	uint8_t CtsValue = 0, dummy = 0xAA;
	uint16_t ErrCnt = 0;
	unsigned char errorString[] = "CTS waiting overrun!";

	while (CtsValue != 0xFF) // Wait until radio IC is ready with the data
	{
		GPIO_ResetBits(GPIOE, nSEL); // select radio IC by pulling its nSEL pin low
		SPI_I2S_ReceiveData(SPI2);		//??????????????????????	just to clear RXNE bit if it is set
		SPI_I2S_SendData(SPI2, READ_CMD_BUFF); // Read command buffer; send command byte
		while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
		while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_RXNE) == RESET);
		SPI_I2S_ReceiveData(SPI2);
		SPI_I2S_SendData(SPI2, dummy);
		while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
		while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_RXNE) == RESET);
		CtsValue = SPI_I2S_ReceiveData(SPI2);
		if(CtsValue != 0xFF)
		{
			GPIO_SetBits(GPIOE, nSEL);
		}
		if(++ErrCnt > MAX_CTS_WAIT)
		{
			UART_PC_Send(errorString, sizeof(errorString));
			return 1;
		}
	}
	spi_SendDataGetResp(length); // CTS value ok, get the response data from the radio IC
	GPIO_SetBits(GPIOE, nSEL); // de-select radio IC by putting its nSEL pin high
	return 0;
}

void radio_GetIntStatus(void)
{
	GPIO_ResetBits(GPIOE, nSEL);
	SPI_I2S_SendData(SPI2, GET_INT_STATUS);
	while(SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI2, 0x00);
	while(SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI2, 0x00);
	while(SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI2, 0x00);
	while(SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
	GPIO_SetBits(GPIOE, nSEL);
	radio_GetResponse(8);
}

void readFIFOinfo(void)
{
	GPIO_ResetBits(GPIOE, nSEL);
	SPI_I2S_SendData(SPI2, FIFO_INFO);
	while(SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI2, 0x00);		// do not clear TX RX FIFO
	while(SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
	//SPI_I2S_SendData(SPI2, 0x01);		// clear TX FIFO
	//while(SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
	//SPI_I2S_SendData(SPI2, 0x02);		// clear RX FIFO
	//while(SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
	//SPI_I2S_SendData(SPI2, 0x03);		// clear TX RX FIFO
	//while(SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
	GPIO_SetBits(GPIOE, nSEL);
	radio_GetResponse(2);
}

void radio_WriteTxFIFO(uint8_t radioTxFifoLength, const unsigned char *radioTxFifoData) // Write Tx FIFO
{
	GPIO_ResetBits(GPIOE, nSEL); // select radio IC by pulling its nSEL pin low
	SPI_I2S_SendData(SPI2, WRITE_TX_FIFO); // Send Tx write command
	while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
	spi_SendDataNoResp(radioTxFifoLength, radioTxFifoData); // Write date to Tx FIFO
	while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_BSY) == SET);
	GPIO_SetBits(GPIOE, nSEL); // de-select radio IC by putting its nSEL pin high
}

void radio_ReadRxFIFO(uint8_t radioRxFifoLength)
{
	uint8_t dummy = 0xAA, i = 0;

	GPIO_ResetBits(GPIOE, nSEL); // select radio IC by pulling its nSEL pin low
	SPI_I2S_ReceiveData(SPI2);
	SPI_I2S_SendData(SPI2, READ_RX_FIFO); // Send Rx read command
	while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
	while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_RXNE) == RESET);
	SPI_I2S_ReceiveData(SPI2);

	while(radioRxFifoLength > 0)
	{
		SPI_I2S_SendData(SPI2, dummy);
		while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
		while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_RXNE) == RESET);
		command[i] = SPI_I2S_ReceiveData(SPI2);
		i++;
		radioRxFifoLength--;
	}
	while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_BSY) == SET);
	//spi_SendDataGetResp(radioRxFifoLength);
	GPIO_SetBits(GPIOE, nSEL); 		// de-select radio IC by putting its nSEL pin high
}

void spi_SendDataNoResp(uint8_t spiTxFifoLength, const unsigned char *spiTxBuffer)
{
    while(spiTxFifoLength--)
    {
    	SPI_I2S_SendData(SPI2, *spiTxBuffer++);
    	while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
    }
}

void spi_SendDataGetResp(uint8_t spiRxFifoLength)
{
	uint8_t dummy = 0xAA, i = 0;

	while(spiRxFifoLength > 0)
	{
		SPI_I2S_SendData(SPI2, dummy);
		while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
		while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_RXNE) == RESET);
		radio_response[i] = SPI_I2S_ReceiveData(SPI2);
		i++;
		spiRxFifoLength--;
	}
	while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_BSY) == SET);
	//UART_PC_Send(radio_response, length);
}

void radio_SendPacket(uint8_t radioTxFifoLength, const unsigned char *radioTxFifoData)
{
	//uint8_t up = (uint8_t)(radioTxFifoLength/16);
	//uint8_t down = (uint8_t)(radioTxFifoLength - (16 * up));

	radio_WriteTxFIFO(radioTxFifoLength, radioTxFifoData);
	radio_WaitforCTS();
	GPIO_ResetBits(GPIOE, nSEL);
	SPI_I2S_SendData(SPI2, START_TX);	// START TX
	while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI2, 0x00);	// channel 0
	while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI2, 0x30);	// READY after TX, start TX immediately
	while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI2, 0x00);	// PH is used, no length
	//SPI_I2S_SendData(SPI2, up);
	while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI2, 0x00);	// PH is used, no length
	//SPI_I2S_SendData(SPI2, down);
	while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
	GPIO_SetBits(GPIOE, nSEL);
	radio_WaitforCTS();
}

void radio_startRX(void)
{
	GPIO_ResetBits(GPIOE, nSEL);
	SPI_I2S_SendData(SPI2, START_RX);	// START RX
	while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI2, 0x00);	// channel 0
	while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI2, 0x00);	// start RX immediately
	while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI2, 0x00);	// PH is used, no length
	while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI2, 0x00);	// PH is used, no length
	while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI2, 0x08);	// state after RX timeout
	while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI2, 0x03);	// state after RX valid packet
	while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI2, 0x08);	// state after RX invalid
	while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);
	GPIO_SetBits(GPIOE, nSEL);
	radio_WaitforCTS();
}

/*void EXTI15_10_IRQHandler(void)
{
	if(EXTI_GetITStatus(EXTI_Line15) != RESET)
	{
		// RADIO RX
		radio_response[3] = 0x00;
		radio_GetIntStatus();
		if((radio_response[3] & 0x18) == 0x10)		// RX packet received, no CRC error
		{
		    radio_ReadRxFIFO(8);
		    commandReceived();
		    red_led_toggle();
		    radio_startRX();
		}
		else if((radio_response[3] & 0x20) == 0x20)
		{
			radio_RX = 1;
		}
		EXTI_ClearITPendingBit(EXTI_Line15);
	}
}*/
