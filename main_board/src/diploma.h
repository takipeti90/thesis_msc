#ifndef DIPLOMA_H_
#define DIPLOMA_H_

#include "stm32f10x.h"
#include "stm32f10x_rcc.h"
#include "stm32f10x_flash.h"
#include "stm32f10x_gpio.h"
#include "stm32f10x_usart.h"
#include "stm32f10x_dma.h"
#include "stm32f10x_adc.h"
#include "stm32f10x_tim.h"
#include "stm32f10x_spi.h"
#include "radio_config_Si4461_433_WDS_packet.h"


/*-----------------RCC------------------*/
void clock_Init(void);
void timer6_Init(void);
void Delay_N_x_10us(uint16_t delay);
void MCO_out(void);

/*-----------------GPIO------------------*/
#define BUTTON_RIGHT		GPIO_Pin_7
#define BUTTON_LEFT			GPIO_Pin_9
#define RED_LED				GPIO_Pin_8
#define BLUE_LED			GPIO_Pin_8
#define WHITE_LED1			GPIO_Pin_4
#define WHITE_LED2			GPIO_Pin_9
#define ENABLE_4V8			GPIO_Pin_2

extern uint8_t lampa_on;
extern uint8_t cameraLight;

void GPIO_Init_all(void);
void enable_4V8(void);
void disable_4V8(void);
void setRedLED(void);
void setBlueLED(void);
void setWhiteLED(void);
void resetRedLED(void);
void resetBlueLED(void);
void resetWhiteLED(void);
void red_led_toggle(void);
void blue_led_toggle(void);
void white_led_toggle(void);
uint8_t button_right(void);
uint8_t button_left(void);

/*-----------------UART_PC------------------*/
extern uint8_t command[8];
extern uint8_t telemetria[60];
extern uint8_t telemetria_enable;
extern uint8_t uart_send;
extern uint8_t uart_on;

void UART_PC_Init();
void UART_PC_Send(const unsigned char *array, uint8_t length);
void commandReceived(void);
uint16_t ascii2number(uint8_t data);

/*-----------------RASPBERRY_PI------------------*/
extern uint8_t raspberry_send;
extern uint8_t raspberry_on;
extern uint8_t raspberry_uartBuff;
extern uint8_t raspberry_uartBuffNum;

void Raspberry_Init(void);
void Raspberry_Send(const unsigned char *array, uint8_t length);

/*-----------------GPS------------------*/
extern uint8_t gps_dma;
extern uint8_t gps_data[82];
extern uint8_t gps_data_number;
extern uint8_t telemetria_number;

void GPS_Init(void);

/*-----------------ADC------------------*/
extern uint16_t batteryVoltageArray[88];
extern uint16_t batteryVoltage;
extern uint8_t batteryVoltageNumber;
extern uint16_t DCcurrentArray[100];
extern uint32_t DCcurrent;
extern uint16_t DCcurrentNumber;
extern uint8_t ADC1ready;
extern uint8_t ADC2ready;
extern uint8_t ADC2averaged;
extern uint16_t aramkorlat;
extern uint16_t targytavolsag;

void ADC1_Init(void);
void ADC1_TIM3trigger(void);
uint16_t readADC2();			//channel 10 -> DC motoraram

/*-----------------DC_MOTOR------------------*/
#define FF1			GPIO_Pin_5
#define FF2			GPIO_Pin_4
#define DCnRESET	GPIO_Pin_6		// low -> RESET, low less than 0.1 us -> clear fault latch
#define DCSR		GPIO_Pin_7
#define PWMH		GPIO_Pin_6
#define PWML		GPIO_Pin_7
#define PHASE		GPIO_Pin_8

extern uint8_t DC_PWM;
extern uint16_t sebessegkorlat;


void DC_motor_Init(void);
void DCmotor_Cmd(FunctionalState chipSelect, FunctionalState H_bridge);
void DCmotor_faultClear(void);
void DC_motorPWM(uint8_t duty_cycle);
void encoder_Init(void);
void SystemStop(void);

/*-----------------LEPTETO_MOTOR------------------*/
#define STEP 		GPIO_Pin_8
#define nRESET 		GPIO_Pin_9
#define nSLEEP 		GPIO_Pin_8
#define nFAULT 		GPIO_Pin_7
#define DECAY 		GPIO_Pin_6
#define DIR 		GPIO_Pin_15
#define nENBL 		GPIO_Pin_14
#define MODE0 		GPIO_Pin_13
#define MODE1 		GPIO_Pin_12
#define MODE2 		GPIO_Pin_11
#define nHOME 		GPIO_Pin_10

typedef struct
{
    uint8_t Mode;
    uint8_t Direction;
    uint8_t Decay_Mode;
} Lepteto_InitTypeDef;

extern uint16_t actualStep;
extern uint8_t leptetoENBL;
extern uint16_t stepNumber;
extern uint8_t SZERVO_PWM;

#define Mode_Fullstep                  		((uint8_t)0x0)
#define Mode_Halfstep                  		((uint8_t)0x1)
#define Mode_4microstep                		((uint8_t)0x2)
#define Mode_8microstep                  	((uint8_t)0x3)
#define Mode_16microstep                  	((uint8_t)0x4)
#define Mode_32microstep               		((uint8_t)0x5)

#define Direction_Right                 ((uint8_t)0x1)
#define Direction_Left                  ((uint8_t)0x0)

#define Decay_Mode_Fast                  ((uint8_t)0x1)
#define Decay_Mode_Slow                  ((uint8_t)0x0)

void lepteto_Init(void);
void lepteto_Cmd(FunctionalState enable);
void lepteto_step(void);
uint16_t lepteto_stepNumber(uint8_t angle, uint8_t direction);
void lepteto_defaultStep(void);
void lepteto_config(uint8_t config);
void szervoPWM_Init(void);
void szervoPWM(uint8_t duty_cycle);

/*-----------------RADIO------------------*/
#define SDN 		GPIO_Pin_11
#define nSEL 		GPIO_Pin_12
#define GPIO0 		GPIO_Pin_13		// Output low until power on reset is complete then output high.
#define GPIO1		GPIO_Pin_14		// CTS - Output High when clear to send a new command, output low otherwise.
#define nIRQ 		GPIO_Pin_15		// PE15 -EXTI15
#define SCLK 		GPIO_Pin_13
#define MISO 		GPIO_Pin_14
#define MOSI 		GPIO_Pin_15

#define MAX_CTS_WAIT	2500

extern uint8_t radio_cfg_data_array[];
extern uint8_t radio_response[64];
extern uint8_t radio_send;
extern uint8_t radio_on;
extern uint8_t radio_RX;

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


#endif /* DIPLOMA_H_ */
