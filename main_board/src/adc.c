#include "diploma.h"

uint16_t batteryVoltageArray[88];
uint16_t batteryVoltage;
uint8_t batteryVoltageNumber;
uint16_t DCcurrentArray[100];
uint32_t DCcurrent;
uint16_t DCcurrentNumber;
uint8_t ADC1ready;
uint8_t ADC2ready;
uint8_t ADC2averaged;
uint8_t cameraLight = 0;
uint16_t aramkorlat = 1282; // 7A
uint16_t targytavolsag = 762; // 50cm

void ADC1_Init()
{
	for(uint8_t j=0;j<88;j++)
	{
		batteryVoltageArray[j] = 0;
	}
	batteryVoltage = 0;
	batteryVoltageNumber = 8;

	ADC1ready = 0;
	ADC2ready = 0;
	ADC2averaged = 0;

	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA, ENABLE);
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOB, ENABLE);
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOC, ENABLE);
	GPIO_InitTypeDef gpioa_analog_input = { GPIO_Pin_4 | GPIO_Pin_5 | GPIO_Pin_6 | GPIO_Pin_7, GPIO_Speed_50MHz, GPIO_Mode_AIN };
	GPIO_InitTypeDef gpioc_analog_input = { GPIO_Pin_0 | GPIO_Pin_1 | GPIO_Pin_2 | GPIO_Pin_3, GPIO_Speed_50MHz, GPIO_Mode_AIN };
	GPIO_Init(GPIOA, &gpioa_analog_input);
	GPIO_Init(GPIOC, &gpioc_analog_input);

    ADC_InitTypeDef  ADC_InitStructure;
    /* ADCCLK = PCLK2/6 = 72/6 = 12MHz*/
    RCC_ADCCLKConfig(RCC_PCLK2_Div6);
    RCC_APB2PeriphClockCmd(RCC_APB2Periph_ADC1, ENABLE);

    ADC_DeInit(ADC1);
    /* ---------------ADC1 Configuration -------------------- */
    ADC_InitStructure.ADC_Mode = ADC_Mode_Independent;
    ADC_InitStructure.ADC_ScanConvMode = ENABLE;
    ADC_InitStructure.ADC_ContinuousConvMode = DISABLE;
    ADC_InitStructure.ADC_ExternalTrigConv = ADC_ExternalTrigConv_T3_TRGO;	// TIM3 triggereli
    ADC_InitStructure.ADC_DataAlign = ADC_DataAlign_Right;
    ADC_InitStructure.ADC_NbrOfChannel = 8;
    ADC_RegularChannelConfig(ADC1, ADC_Channel_4,  1, ADC_SampleTime_239Cycles5);	// 3 cella
    ADC_RegularChannelConfig(ADC1, ADC_Channel_13, 2, ADC_SampleTime_239Cycles5);	// 2 cella
    ADC_RegularChannelConfig(ADC1, ADC_Channel_12, 3, ADC_SampleTime_239Cycles5);	// 1 cella
    ADC_RegularChannelConfig(ADC1, ADC_Channel_11, 4, ADC_SampleTime_239Cycles5);	// 3.3 V
    ADC_RegularChannelConfig(ADC1, ADC_Channel_5,  5, ADC_SampleTime_239Cycles5);	// 4.8 V
    ADC_RegularChannelConfig(ADC1, ADC_Channel_6,  6, ADC_SampleTime_71Cycles5);	// hoellenallas
    ADC_RegularChannelConfig(ADC1, ADC_Channel_7,  7, ADC_SampleTime_71Cycles5);	// fenyerosseg
    ADC_RegularChannelConfig(ADC1, ADC_Channel_9,  8, ADC_SampleTime_71Cycles5);	// sharp,PING
    //ADC_RegularChannelConfig(ADC1, ADC_Channel_10, 9, ADC_SampleTime_1Cycles5);	// DC motor - Rout=1.5ohm
    ADC_Init(ADC1, &ADC_InitStructure);
    ADC_DMACmd(ADC1, ENABLE);
    ADC_Cmd(ADC1, ENABLE);
    ADC_ResetCalibration(ADC1);
    while(ADC_GetResetCalibrationStatus(ADC1));
    ADC_StartCalibration(ADC1);
    while(ADC_GetCalibrationStatus(ADC1));


    RCC_AHBPeriphClockCmd(RCC_AHBPeriph_DMA1, ENABLE);
    /*-----DMA_CHANNEL1 = ADC1-----*/
    DMA_InitTypeDef DMA_ADC1;

    DMA_DeInit(DMA1_Channel1);
    DMA_ADC1.DMA_PeripheralBaseAddr = (uint32_t)&ADC1->DR;; // ADC1 cime
    DMA_ADC1.DMA_MemoryBaseAddr = ((uint32_t)&batteryVoltageArray);
    DMA_ADC1.DMA_DIR = DMA_DIR_PeripheralSRC; // receive from ADC1 to Memory
    DMA_ADC1.DMA_BufferSize = 8;
    DMA_ADC1.DMA_PeripheralInc = DMA_PeripheralInc_Disable;
    DMA_ADC1.DMA_MemoryInc = DMA_MemoryInc_Enable;
    DMA_ADC1.DMA_PeripheralDataSize = DMA_PeripheralDataSize_HalfWord;
    DMA_ADC1.DMA_MemoryDataSize = DMA_MemoryDataSize_HalfWord;
    DMA_ADC1.DMA_Mode = DMA_Mode_Circular;
    DMA_ADC1.DMA_Priority = DMA_Priority_Medium;
    DMA_ADC1.DMA_M2M = DMA_M2M_Disable;
    DMA_Init(DMA1_Channel1, &DMA_ADC1);
    DMA_ITConfig(DMA1_Channel1, DMA_IT_TC, ENABLE);
    DMA_Cmd(DMA1_Channel1, ENABLE);

    NVIC_InitTypeDef NVIC_DMA_CH1;
    NVIC_DMA_CH1.NVIC_IRQChannel = DMA1_Channel1_IRQn;
    NVIC_DMA_CH1.NVIC_IRQChannelPreemptionPriority = 1;
    NVIC_DMA_CH1.NVIC_IRQChannelSubPriority = 0;
    NVIC_DMA_CH1.NVIC_IRQChannelCmd = ENABLE;
    NVIC_Init(&NVIC_DMA_CH1);


    /* ---------------ADC2 Configuration -------------------- */
    for(uint8_t i=0;i<100;i++)
    {
    	DCcurrentArray[i] = 0;
    }
    DCcurrent = 0;
    DCcurrentNumber = 0;

    ADC_InitTypeDef  ADC2_InitStructure;
    RCC_APB2PeriphClockCmd(RCC_APB2Periph_ADC2, ENABLE);
    ADC_DeInit(ADC2);
    ADC2_InitStructure.ADC_Mode = ADC_Mode_Independent;
    ADC2_InitStructure.ADC_ScanConvMode = DISABLE;
    ADC2_InitStructure.ADC_ContinuousConvMode = DISABLE;
    ADC2_InitStructure.ADC_ExternalTrigConv = ADC_ExternalTrigConv_None;
    ADC2_InitStructure.ADC_DataAlign = ADC_DataAlign_Right;
    ADC2_InitStructure.ADC_NbrOfChannel = 1;
    ADC_RegularChannelConfig(ADC2, ADC_Channel_10, 1, ADC_SampleTime_71Cycles5);// DC motor - Rout=1.5ohm
    ADC_Init(ADC2, &ADC2_InitStructure);
    ADC_Cmd(ADC2, ENABLE);
    ADC_ResetCalibration(ADC2);
    while(ADC_GetResetCalibrationStatus(ADC2));
    ADC_StartCalibration(ADC2);
    while(ADC_GetCalibrationStatus(ADC2));

    RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM7, ENABLE);	// DC motor aram
    TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;
    TIM_TimeBaseStructure.TIM_Period = 99; 	//	10 mSec
    TIM_TimeBaseStructure.TIM_Prescaler = 7199;	// 10 kHz - 100 us
    TIM_TimeBaseStructure.TIM_ClockDivision = 0;
    TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
    TIM_TimeBaseInit(TIM7, &TIM_TimeBaseStructure);
    TIM_ITConfig(TIM7, TIM_IT_Update, ENABLE);

    NVIC_InitTypeDef NVIC_InitStructure;
    NVIC_InitStructure.NVIC_IRQChannel = TIM7_IRQn;
    NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 3;
    NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
    NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
    NVIC_Init(&NVIC_InitStructure);

    TIM_Cmd(TIM7, ENABLE);
    ADC1_TIM3trigger();
}


void ADC1_TIM3trigger(void)		// triggering ADC1
{
	RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM3, ENABLE);
	TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;
	TIM_TimeBaseStructure.TIM_Period = 999; 	// 999 = 100 mSec (atlagolashoz), 9999 = 1 sec, átlagolás nélkül
	TIM_TimeBaseStructure.TIM_Prescaler = 7199;	// clock 10 kHz	- 100 uSec
	TIM_TimeBaseStructure.TIM_ClockDivision = 0;
	TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
	TIM_TimeBaseInit(TIM3, &TIM_TimeBaseStructure);
	TIM_SelectOutputTrigger(TIM3, TIM_TRGOSource_Update); // ADC1_ExternalTrigConv_T3_TRGO
	TIM_Cmd(TIM3, ENABLE);
	ADC_SoftwareStartConvCmd(ADC1, ENABLE);
}


uint16_t readADC2()
{
    //ADC_RegularChannelConfig(ADC2, ADC_Channel_10, 1, ADC_SampleTime_1Cycles5);	// DC motor - Rout=1.5ohm
    ADC_SoftwareStartConvCmd(ADC2, ENABLE);
    while(ADC_GetFlagStatus(ADC2, ADC_FLAG_EOC) == RESET);
    return ADC_GetConversionValue(ADC2);
}


void DMA1_Channel1_IRQHandler(void) 	// ADC1		10-es atlagolas, 100 msec -> masodpercenkent frissul
{
	uint16_t akkufesz;
	if (DMA_GetITStatus(DMA1_IT_TC1))
	{
		// alkonykapcsolo
		if(cameraLight == 0 && batteryVoltageArray[6] < 105)	// ~70 luxnal bekapcsol
		{
			setWhiteLED();
		}
		else if(cameraLight == 0 && batteryVoltageArray[6] > 144) // ~100 luxnal kikapcsol
		{
			resetWhiteLED();
		}

		// akadalyjelzo
		if(batteryVoltageArray[7] > targytavolsag && DC_PWM < 50) // ~50 cm - 762, csak, ha elõre fele halad
		{
			DC_PWM = 50;
			DC_motorPWM(DC_PWM);
			DCmotor_Cmd(DISABLE, DISABLE);
		}

		for(uint8_t i=0;i<8;i++)
		{
			batteryVoltageArray[i + batteryVoltageNumber] = batteryVoltageArray[i];
		}
		if (batteryVoltageNumber < 80)
		{
			batteryVoltageNumber = batteryVoltageNumber + 8;
		}
		else
		{
			batteryVoltageNumber = 8;
		}
		for(uint8_t j=0;j<8;j++)
		{
			for(uint8_t i=1;i<11;i++)
			{
				batteryVoltage = batteryVoltage + batteryVoltageArray[i*8 + j];

			}
			telemetria[37+j*2] = (uint8_t)((uint16_t)(batteryVoltage/10));
			telemetria[36+j*2] = (uint8_t)((uint16_t)((batteryVoltage/10)>>8));
			batteryVoltage = 0;
		}

		// akkumulator merules - 1903 -> 9,6 V
		akkufesz = 256*telemetria[36] + telemetria[37];
		if(akkufesz < 1903 && ADC1ready == 10)
		{
			SystemStop();
			telemetria_enable = 1;
			if(akkufesz < 1843) // akkumulator merules - 1843 -> 9,3 V
			{
				disable_4V8();
				radio_on = 1;
				raspberry_on = 0;
			}
		}

		if (ADC1ready < 10)
		{
			ADC1ready++;
		}
		if (ADC1ready == 10)
		{
			if (telemetria_enable == 1)
			{
				if(DC_PWM > 48 && DC_PWM < 52)
				{
					telemetria[34] = 0;
					telemetria[35] = 0;
				}
				radio_send = 1;
				uart_send = 1;
				raspberry_send = 1;
			}
			ADC1ready = 0;
		}
		DMA_ClearITPendingBit(DMA1_IT_TC1);
	}
}

/*void DMA1_Channel1_IRQHandler(void) 	// ADC1, 1 sec-enkent kuldi atlagolas nelkul
{
	if (DMA_GetITStatus(DMA1_IT_TC1))
	{
		// alkonykapcsolo
		if(lampa_on == 0 && batteryVoltageArray[6] < 37)
		{
			setWhiteLED();
			lampa_on = 1;
		}
		else if(lampa_on == 1 && batteryVoltageArray[6] > 86)
		{
			resetWhiteLED();
			lampa_on = 0;
		}

		// akadalyjelzo
		if(batteryVoltageArray[7] > targytavolsag && DC_PWM < 50) // ~50 cm - 762, csak, ha elõre fele halad
		{
			DC_PWM = 50;
			DC_motorPWM(DC_PWM);
			DCmotor_Cmd(DISABLE, DISABLE);
		}

		// akkumulator merules - 1903 -> 9,6 V
		if(batteryVoltageArray[0] < 1903)
		{
			SystemStop();
			telemetria_enable = 1;
			if(batteryVoltageArray[0] < 1843) // akkumulator merules - 1843 -> 9,3 V
			{
				disable_4V8();
				radio_on = 1;
				raspberry_on = 0;
			}
		}

		for(uint8_t j=0;j<8;j++)
		{
			telemetria[36+j*2] = (uint8_t)((uint16_t)(batteryVoltageArray[j]));
			telemetria[37+j*2] = (uint8_t)((uint16_t)((batteryVoltageArray[j])>>8));
		}

		if (telemetria_enable == 1)
		{
			radio_send = 1;
			uart_send = 1;
			raspberry_send = 1;
		}
		DMA_ClearITPendingBit(DMA1_IT_TC1);
	}
}*/

void TIM7_IRQHandler(void)
{
	if (TIM_GetITStatus(TIM7, TIM_IT_Update))
	{
		// readADC2, atlagolas utolso 100 ertekre, beirni a telemetria tombbe
		DCcurrentArray[DCcurrentNumber] = readADC2(); // 1920; // readADC2();
		if (DCcurrentNumber < 99)
		{
			DCcurrentNumber++;
		}
		else
		{
			DCcurrentNumber = 0;
			ADC2ready = 1;
		}
		if(ADC2ready == 1)
		{
			for(uint8_t i=0;i<100;i++)
			{
				DCcurrent = DCcurrent + DCcurrentArray[i];
			}
			DCcurrent = DCcurrent / 100;

			//---------- ARAMKORLATOZAS ----------
			if(DCcurrent > (uint32_t)(1935 + aramkorlat) && DC_PWM < 50)  // 1935 elvileg a kozepe (1.58 V), ELORE MENET, novel ha aramkorlat
			{
				DC_PWM = DC_PWM + 1;
				if(DC_PWM >= 50)
				{
					DC_PWM = 50;
					DC_motorPWM(DC_PWM);		// 50 - DC motor állj
					DCmotor_Cmd(DISABLE, DISABLE);
				}
				else
				{
					DC_motorPWM(DC_PWM);
				}
			}
			else if(DCcurrent < (uint32_t)(1935 - aramkorlat - 74) && DC_PWM > 50)  // -74 (0.404 A, ennyivel többet mér, offset), HATRA MENET, csokkent ha aramkorlat
			{
				DC_PWM = DC_PWM - 1;
				if(DC_PWM <= 50)
				{
					DC_PWM = 50;
					DC_motorPWM(DC_PWM);		// 50 - DC motor állj
					DCmotor_Cmd(DISABLE, DISABLE);
				}
				else
				{
					DC_motorPWM(DC_PWM);
				}
			}

			telemetria[52] = (uint8_t)((DCcurrent>>8));
			telemetria[53] = (uint8_t)DCcurrent;
			DCcurrent = 0;
		}
		TIM_ClearITPendingBit(TIM7, TIM_IT_Update);
	}
}
