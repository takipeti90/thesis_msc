#include <stdio.h>
#include "diploma.h"
#include "diag/Trace.h"

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wmissing-declarations"
#pragma GCC diagnostic ignored "-Wreturn-type"

//----- lepteto motor ----------
uint16_t actualStep = 0;
uint16_t stepNumber = 3200;
uint8_t leptetoENBL = 0;
//----- radio ------------------
uint8_t radio_send = 0;
uint8_t radio_on = 0;
uint8_t radio_RX = 0;
uint8_t radio_response[64];
//----- UART -------------------
uint8_t uart_send = 0;
uint8_t uart_on = 0;
//----- Raspberry Pi -----------
uint8_t raspberry_send = 0;
uint8_t raspberry_on = 0;
//----- telemetria -------------
uint8_t telemetria[60];
uint8_t telemetria_enable = 0;
//----- vezerles ---------------
uint8_t command[8];
uint8_t DC_PWM;
uint8_t SZERVO_PWM;


int main(void)
{
	/*-----INICIALIZÁLÁS-----*/
	clock_Init();
	GPIO_Init_all();
	UART_PC_Init();
	Raspberry_Init();
	lepteto_Init();
	szervoPWM_Init();
	encoder_Init();
	DC_motor_Init();
	GPS_Init();
	radio_Init();
	ADC1_Init();
	radio_startRX();


    while(1)
    {
    	//-----------RADIO RX------------
    	if(GPIO_ReadInputDataBit(GPIOE, nIRQ) == 0)
    	{
    		radio_response[3] = 0x00;
    		radio_GetIntStatus();
    		if((radio_response[3] & 0x18) == 0x10)		// RX packet received, no CRC error
    		{
    			radio_ReadRxFIFO(8);
    			commandReceived();
    			red_led_toggle();
    			radio_startRX();
    		}
    		else
    		{
    			red_led_toggle();
    		}
    	}
    	//------------RADIO TX------------
    	if (radio_send == 1 && radio_on == 1)
    	{
    		telemetria[54] = DC_PWM;
    		telemetria[55] = SZERVO_PWM;
    		telemetria[56] = (uint8_t)((stepNumber>>8));	 // MSB
    		telemetria[57] = (uint8_t)stepNumber;		  	 // LSB
    		radio_response[3] = 0x00;
    	    radio_SendPacket(sizeof(telemetria), telemetria);
    	    while(!((radio_response[3] & 0x20) == 0x20))		// TX packet sent
    	    {
    	    	radio_GetIntStatus();
    	    }
    	    radio_startRX();
    	    blue_led_toggle();
    	    radio_send = 0;
    	}
    	//---------RADIO TX EXTI15---------
    	/*if (radio_send == 1 && radio_on == 1)
    	{
    		telemetria[54] = DC_PWM;
    	    telemetria[55] = SZERVO_PWM;
    	    telemetria[56] = (uint8_t)((stepNumber>>8));	 // MSB
    	    telemetria[57] = (uint8_t)stepNumber;		  	 // LSB
    	    radio_SendPacket(sizeof(telemetria), telemetria);
    	    while(radio_RX == 0);
    	    radio_startRX();
    	    blue_led_toggle();
    	    radio_send = 0;
    	    radio_RX = 0;
    	}*/

    	//----------UART------------
    	if (uart_send == 1 && uart_on == 1)
    	{
    		telemetria[54] = DC_PWM;
    		telemetria[55] = SZERVO_PWM;
    		telemetria[56] = (uint8_t)((stepNumber>>8));	 // MSB
    		telemetria[57] = (uint8_t)stepNumber;		  	 // LSB
    		UART_PC_Send(telemetria, sizeof(telemetria));
    		blue_led_toggle();
    		uart_send = 0;
    	}

    	//----------Raspberry------------
    	if (raspberry_send == 1 && raspberry_on == 1)
    	{
    		telemetria[54] = DC_PWM;
    		telemetria[55] = SZERVO_PWM;
    		telemetria[56] = (uint8_t)((stepNumber>>8));	 // MSB
    		telemetria[57] = (uint8_t)stepNumber;		  	 // LSB
    		Raspberry_Send(telemetria, sizeof(telemetria));
    	    blue_led_toggle();
    	    raspberry_send = 0;
    	}

    	//---------LEPTETO MOTOR----------
    	if (leptetoENBL == 1)
    	{
    		lepteto_Cmd(ENABLE);
    		if (actualStep != 0)
    		{
    			lepteto_step();
    	    	actualStep = actualStep - 1;
    		}
    		else
    		{
    			lepteto_Cmd(DISABLE);
    			leptetoENBL = 0;
    		}
    	}

    	//-----------NYOMOGOMBOK----------
    	if (button_right())
    	{
    		red_led_toggle();

    		Delay_N_x_10us(20000); // 200 mSec
    	}
    	if (button_left())
    	{
    		blue_led_toggle();

    		Delay_N_x_10us(20000); // 200 mSec
    	}
    }
}
#pragma GCC diagnostic pop
