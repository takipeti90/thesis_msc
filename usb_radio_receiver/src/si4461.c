#include "usb_radio.h"

uint8_t command[8];
uint8_t radio_cfg_data_array[] = RADIO_CONFIGURATION_DATA_ARRAY;

void radio_Init(void)
{
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA, ENABLE);
	GPIO_InitTypeDef gpioa_input = { nIRQ, GPIO_Speed_50MHz, GPIO_Mode_IN_FLOATING };
	GPIO_Init(GPIOA, &gpioa_input);

	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOB, ENABLE);
	GPIO_InitTypeDef gpiob_output = { SDN | nSEL, GPIO_Speed_50MHz, GPIO_Mode_Out_PP };
	GPIO_Init(GPIOB, &gpiob_output);

	GPIO_SetBits(GPIOB, SDN);
	GPIO_SetBits(GPIOB, nSEL);

	/*---------SPI1 INIT--------*/
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA | RCC_APB2Periph_AFIO, ENABLE);
	GPIO_InitTypeDef gpioa_spi_in = { MISO, GPIO_Speed_50MHz, GPIO_Mode_IN_FLOATING };
	GPIO_InitTypeDef gpioa_spi_out = { MOSI | SCLK, GPIO_Speed_50MHz, GPIO_Mode_AF_PP };
	GPIO_Init(GPIOA, &gpioa_spi_in);
	GPIO_Init(GPIOA, &gpioa_spi_out);

	RCC_APB2PeriphClockCmd(RCC_APB2Periph_SPI1, ENABLE);
	SPI_I2S_DeInit(SPI1);
	SPI_InitTypeDef SPI1_InitStructure;
	SPI1_InitStructure.SPI_Direction = SPI_Direction_2Lines_FullDuplex;
	SPI1_InitStructure.SPI_Mode = SPI_Mode_Master;
	SPI1_InitStructure.SPI_DataSize = SPI_DataSize_8b;
	SPI1_InitStructure.SPI_CPOL = SPI_CPOL_Low;		// first rising edge
	SPI1_InitStructure.SPI_CPHA = SPI_CPHA_1Edge;
	SPI1_InitStructure.SPI_NSS = SPI_NSS_Soft;		// software SlaveSelect
	SPI1_InitStructure.SPI_BaudRatePrescaler = SPI_BaudRatePrescaler_8;	// 64MHz/8 = 8 MHz
	SPI1_InitStructure.SPI_FirstBit = SPI_FirstBit_MSB;
	SPI1_InitStructure.SPI_CRCPolynomial = 7;
	SPI_Init(SPI1, &SPI1_InitStructure);
	SPI_CalculateCRC(SPI1, DISABLE);
	SPI_Cmd(SPI1, ENABLE);

	radio_Cmd(ENABLE);
	Delay_N_x_10us(50000);
	radio_config();
	Delay_N_x_10us(50000);
}


void radio_Cmd(FunctionalState state)
{
	if (state != DISABLE)
	{
		/* Enable */
		GPIO_ResetBits(GPIOB, SDN);
	}
	else
	{
	    /* Disable */
		GPIO_SetBits(GPIOB, SDN);
	}
}

void radio_config(void)
{
	uint16_t index = 0;
	uint8_t cmdSize;

	while(index < sizeof(radio_cfg_data_array))
	{
		cmdSize = radio_cfg_data_array[index];
		GPIO_ResetBits(GPIOB, nSEL);
		for(uint8_t i = 0; i < cmdSize; i++)
		{
			SPI_I2S_SendData(SPI1, radio_cfg_data_array[index + 1 + i]);
			while(SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
		}
		GPIO_SetBits(GPIOB, nSEL);
		index = index + (cmdSize + 1);
		radio_WaitforCTS();
	}
	radio_GetIntStatus();
}

void radio_SendCommand(uint8_t length, const unsigned char *radioCommand) // Send a command + data to the chip
{
	GPIO_ResetBits(GPIOB, nSEL); // select radio IC by pulling its nSEL pin low
	spi_SendDataNoResp(length, radioCommand); // Send data array to the radio IC via SPI
	while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_BSY) == SET);
	GPIO_SetBits(GPIOB, nSEL); // de-select radio IC by putting its nSEL pin high
}


uint8_t radio_WaitforCTS(void)
{
	uint8_t CtsValue = 0, dummy = 0xAA;
	uint16_t ErrCnt = 0;
	unsigned char errorString[] = "CTS waiting overrun!";

	while (CtsValue != 0xFF) // Wait until radio IC is ready with the data
	{
		GPIO_ResetBits(GPIOB, nSEL); // select radio IC by pulling its nSEL pin low
		SPI_I2S_ReceiveData(SPI1);		//??????????????????????	just to clear RXNE bit if it is set
		SPI_I2S_SendData(SPI1, READ_CMD_BUFF); // Read command buffer; send command byte (CTS = 0x44)
		while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
		while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_RXNE) == RESET);
		SPI_I2S_ReceiveData(SPI1);
		SPI_I2S_SendData(SPI1, dummy);
		while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
		while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_RXNE) == RESET);
		CtsValue = SPI_I2S_ReceiveData(SPI1);
		while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_BSY) == SET);
		GPIO_SetBits(GPIOB, nSEL); // If CTS is not 0xFF, put nSEL high and stay in waiting
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
		GPIO_ResetBits(GPIOB, nSEL); // select radio IC by pulling its nSEL pin low
		SPI_I2S_ReceiveData(SPI1);		//??????????????????????	just to clear RXNE bit if it is set
		SPI_I2S_SendData(SPI1, READ_CMD_BUFF); // Read command buffer; send command byte
		while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
		while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_RXNE) == RESET);
		SPI_I2S_ReceiveData(SPI1);
		SPI_I2S_SendData(SPI1, dummy);
		while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
		while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_RXNE) == RESET);
		CtsValue = SPI_I2S_ReceiveData(SPI1);
		if(CtsValue != 0xFF)
		{
			GPIO_SetBits(GPIOB, nSEL);
		}
		if(++ErrCnt > MAX_CTS_WAIT)
		{
			UART_PC_Send(errorString, sizeof(errorString));
			return 1;
		}
	}
	spi_SendDataGetResp(length); // CTS value ok, get the response data from the radio IC
	GPIO_SetBits(GPIOB, nSEL); // de-select radio IC by putting its nSEL pin high
	return 0;
}

void radio_GetIntStatus(void)
{
	GPIO_ResetBits(GPIOB, nSEL);
	SPI_I2S_SendData(SPI1, GET_INT_STATUS);
	while(SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI1, 0x00);
	while(SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI1, 0x00);
	while(SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI1, 0x00);
	while(SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
	GPIO_SetBits(GPIOB, nSEL);
	radio_GetResponse(8);
}

void readFIFOinfo(void)
{
	GPIO_ResetBits(GPIOB, nSEL);
	SPI_I2S_SendData(SPI1, FIFO_INFO);
	while(SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI1, 0x00);		// do not clear TX RX FIFO
	while(SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
	//SPI_I2S_SendData(SPI1, 0x01);		// clear TX FIFO
	//while(SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
	//SPI_I2S_SendData(SPI1, 0x02);		// clear RX FIFO
	//while(SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
	//SPI_I2S_SendData(SPI1, 0x03);		// clear TX RX FIFO
	//while(SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
	GPIO_SetBits(GPIOB, nSEL);
	radio_GetResponse(2);
}

void radio_WriteTxFIFO(uint8_t radioTxFifoLength, const unsigned char *radioTxFifoData) // Write Tx FIFO
{
	GPIO_ResetBits(GPIOB, nSEL); // select radio IC by pulling its nSEL pin low
	SPI_I2S_SendData(SPI1, WRITE_TX_FIFO); // Send Tx write command
	while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
	spi_SendDataNoResp(radioTxFifoLength, radioTxFifoData); // Write data to Tx FIFO
	while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_BSY) == SET);
	GPIO_SetBits(GPIOB, nSEL); // de-select radio IC by putting its nSEL pin high
}

void radio_ReadRxFIFO(uint8_t radioRxFifoLength)
{
	GPIO_ResetBits(GPIOB, nSEL); // select radio IC by pulling its nSEL pin low
	SPI_I2S_ReceiveData(SPI1);
	SPI_I2S_SendData(SPI1, READ_RX_FIFO); // Send Rx read command
	while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
	while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_RXNE) == RESET);
	SPI_I2S_ReceiveData(SPI1);
	spi_SendDataGetResp(radioRxFifoLength);
	GPIO_SetBits(GPIOB, nSEL); 		// de-select radio IC by putting its nSEL pin high
}

void spi_SendDataNoResp(uint8_t spiTxFifoLength, const unsigned char *spiTxBuffer)
{
    while(spiTxFifoLength--)
    {
    	SPI_I2S_SendData(SPI1, *spiTxBuffer++);
    	while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
    }
}

void spi_SendDataGetResp(uint8_t spiRxFifoLength)
{
	uint8_t dummy = 0xAA, i = 0;

	while(spiRxFifoLength > 0)
	{
		SPI_I2S_SendData(SPI1, dummy);
		while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
		while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_RXNE) == RESET);
		radio_response[i] = SPI_I2S_ReceiveData(SPI1);
		i++;
		spiRxFifoLength--;
	}
	while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_BSY) == SET);
	//UART_PC_Send(radio_response, length);
}

void radio_SendPacket(uint8_t radioTxFifoLength, const unsigned char *radioTxFifoData)
{
	//uint8_t up = (uint8_t)(radioTxFifoLength/16);
	//uint8_t down = (uint8_t)(radioTxFifoLength - (16 * up));

	radio_WriteTxFIFO(radioTxFifoLength, radioTxFifoData);
	radio_WaitforCTS();
	GPIO_ResetBits(GPIOB, nSEL);
	SPI_I2S_SendData(SPI1, START_TX);	// START TX
	while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI1, 0x00);	// channel 0
	while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI1, 0x30);	// READY after TX, start TX immediately
	while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI1, 0x00);	// PH is used, no length
	//SPI_I2S_SendData(SPI1, up);
	while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI1, 0x00);	// PH is used, no length
	//SPI_I2S_SendData(SPI1, down);
	while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
	GPIO_SetBits(GPIOB, nSEL);
	radio_WaitforCTS();
}

void radio_startRX(void)
{
	GPIO_ResetBits(GPIOB, nSEL);
	SPI_I2S_SendData(SPI1, START_RX);	// START RX
	while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI1, 0x00);	// channel 0
	while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI1, 0x00);	// start RX immediately
	while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI1, 0x00);	// PH is used, no length
	while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI1, 0x00);	// PH is used, no length
	while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI1, 0x08);	// state after RX timeout
	while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI1, 0x03);	// state after RX valid packet
	while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
	SPI_I2S_SendData(SPI1, 0x08);	// state after RX invalid
	while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET);
	GPIO_SetBits(GPIOB, nSEL);
	radio_WaitforCTS();
}
