#include <stdio.h>
#include "usb_radio.h"
#include "diag/Trace.h"

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wmissing-declarations"
#pragma GCC diagnostic ignored "-Wreturn-type"


uint8_t radio_response[64];
uint8_t command[8];
uint8_t radio_send = 0;
uint8_t telemetria[60];


void main(void)
{
	clock_Init();
	GPIO_Init_all();
	UART_PC_Init();
	radio_Init();

	radio_startRX();

	while(1)
	{
		//---------- RADIO TX ----------
	    if (radio_send == 1)
	    {
	    	radio_response[3] = 0x00;
	    	radio_SendPacket(sizeof(command), command);
	    	while(!((radio_response[3] & 0x20) == 0x20))		// TX packet sent
	    	{
	    		radio_GetIntStatus();
	    	}
	    	radio_startRX();
	    	radio_send = 0;
	    }

	    //---------- RADIO RX ----------
	    if(GPIO_ReadInputDataBit(GPIOA, nIRQ) == 0)
	    {
	    	radio_response[2] = 0x00;
	    	radio_GetIntStatus();

	    	if((radio_response[2] & 0x18) == 0x10)		// RX packet received, no CRC error
	        {
	        	radio_ReadRxFIFO(60);
	        	UART_PC_Send(radio_response, 60);
	        	radio_startRX();
	        	blue_led_toggle();
	        }
	        else
	        {
	        	red_led_toggle();
	     	}
	    }
	}
}

#pragma GCC diagnostic pop
