#ifndef USB_RADIO_H_
#define USB_RADIO_H_


#include "stm32f10x.h"
#include "stm32f10x_rcc.h"
#include "stm32f10x_flash.h"
#include "stm32f10x_gpio.h"
#include "stm32f10x_usart.h"
#include "stm32f10x_dma.h"
#include "stm32f10x_tim.h"
#include "stm32f10x_spi.h"
#include "radio_config_Si4461_433_WDS_packet.h"


/*-----------------RCC------------------*/
void clock_Init(void);
void timer1_Init(void);
void timer2_Init(void);
void Delay_N_x_10us(uint16_t delay);
void count_N_x_100us(uint16_t count);
void MCO_out(void);


/*-----------------GPIO------------------*/
#define BLUE_LED			GPIO_Pin_13
#define RED_LED				GPIO_Pin_12
#define nRESET_USBUART		GPIO_Pin_15

void GPIO_Init_all(void);
void setBlueLED(void);
void setRedLED(void);
void resetBlueLED(void);
void resetRedLED(void);
void blue_led_toggle(void);
void red_led_toggle(void);


/*-----------------UART_PC------------------*/
extern uint8_t command[8];
extern uint8_t telemetria[60];
extern uint8_t uartBuffNum;
extern uint8_t uartBuff;

void UART_PC_Init(void);
void UART_PC_Send(const unsigned char *array, uint8_t length);


/*-----------------RADIO------------------*/
#define SDN 		GPIO_Pin_12
#define nSEL 		GPIO_Pin_0
#define nIRQ 		GPIO_Pin_4
#define SCLK 		GPIO_Pin_5
#define MISO 		GPIO_Pin_6
#define MOSI 		GPIO_Pin_7

#define MAX_CTS_WAIT	2500

extern uint8_t radio_cfg_data_array[];
extern uint8_t radio_response[64];
extern uint8_t radio_send;

//COMMANDS
#define POWER_UP 				0x02
#define NOP						0x00
#define PART_INFO				0x01
#define FUNC_INFO				0x10
#define SET_PROPERTY			0x11
#define GET_PROPERTY			0x12
#define GPIO_PIN_CFG			0x13
#define GET_ADC_READING			0x14
#define FIFO_INFO				0x15
#define PACKET_INFO				0x16
#define IRCAL					0x17
#define PROTOCOL_CFG			0x18
#define GET_INT_STATUS			0x20
#define GET_PH_STATUS			0x21
#define GET_MODEM_STATUS		0x22
#define GET_CHIP_STATUS			0x23
#define START_TX				0x31
#define START_RX				0x32
#define REQUEST_DEVICE_STATE	0x33
#define CHANGE_STATE			0x34
#define READ_CMD_BUFF			0x44
#define FRR_A_READ				0x50
#define FRR_B_READ				0x51
#define FRR_C_READ				0x53
#define FRR_D_READ				0x57
#define WRITE_TX_FIFO			0x66
#define READ_RX_FIFO			0x77
#define RX_HOP					0x36

void radio_Init(void);
void radio_Cmd(FunctionalState state);
void radio_config(void);
void radio_SendCommand(uint8_t length, const unsigned char *radioCommand);
uint8_t radio_WaitforCTS(void);
uint8_t radio_GetResponse(uint8_t length);
void radio_GetIntStatus(void);
void readFIFOinfo(void);
void radio_WriteTxFIFO(uint8_t radioTxFifoLength, const unsigned char *radioTxFifoData);
void radio_ReadRxFIFO(uint8_t radioRxFifoLength);
void spi_SendDataNoResp(uint8_t spiTxFifoLength, const unsigned char *spiTxBuffer);
void spi_SendDataGetResp(uint8_t spiRxFifoLength);
void radio_SendPacket(uint8_t radioTxFifoLength, const unsigned char *radioTxFifoData);
void radio_startRX(void);


#endif /* USB_RADIO_H_ */
