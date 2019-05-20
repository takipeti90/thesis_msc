#include "diploma.h"

uint16_t period = 599;		// 50 us - 20 kHz
uint16_t sebessegkorlat = 281; // 10km/h

void DC_motor_Init(void)
{
	DC_PWM = 50;

	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOD, ENABLE);
	GPIO_InitTypeDef gpiod_input = { FF1 | FF2, GPIO_Speed_50MHz, GPIO_Mode_IN_FLOATING };
	GPIO_InitTypeDef gpiod_output = { DCnRESET | DCSR, GPIO_Speed_50MHz, GPIO_Mode_Out_PP };
	GPIO_Init(GPIOD, &gpiod_input);
	GPIO_Init(GPIOD, &gpiod_output);
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOB, ENABLE);
	GPIO_InitTypeDef gpiob_output = { PWMH | PWML, GPIO_Speed_50MHz, GPIO_Mode_Out_PP };
	GPIO_Init(GPIOB, &gpiob_output);

	GPIO_ResetBits(GPIOD, DCnRESET);
	GPIO_SetBits(GPIOD, DCSR);
	GPIO_ResetBits(GPIOB, PWML);
	GPIO_ResetBits(GPIOB, PWMH);

	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOB | RCC_APB2Periph_AFIO, ENABLE);
	GPIO_InitTypeDef gpiob_phase = { PHASE, GPIO_Speed_50MHz, GPIO_Mode_AF_PP };
	GPIO_Init(GPIOB, &gpiob_phase);

	RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM4, ENABLE);
	TIM_TimeBaseInitTypeDef timer4;
	timer4.TIM_Period = period;
	timer4.TIM_Prescaler = 5;		// 12 MHz - 83.33 ns
	timer4.TIM_ClockDivision = 0;
	timer4.TIM_CounterMode = TIM_CounterMode_Up;
	TIM_TimeBaseInit(TIM4, &timer4);
	TIM_Cmd(TIM4, ENABLE);

	//uint8_t duty_cycle = 50;
	TIM_OCInitTypeDef tim4_pwm;
	tim4_pwm.TIM_OCMode = TIM_OCMode_PWM1;
	tim4_pwm.TIM_OutputState = TIM_OutputState_Enable;
	tim4_pwm.TIM_Pulse = (uint16_t)(((period+1)*DC_PWM)/100);
	//tim4_pwm.TIM_Pulse = 300;
	tim4_pwm.TIM_OCPolarity = TIM_OCPolarity_High;
	TIM_OC3Init(TIM4, &tim4_pwm);
	TIM_OC3PreloadConfig(TIM4, TIM_OCPreload_Enable);
	TIM_ARRPreloadConfig(TIM4, ENABLE);
}


void DCmotor_Cmd(FunctionalState chipSelect, FunctionalState H_bridge)
{
	if (chipSelect != DISABLE)
	{
		/* Enable */
		GPIO_SetBits(GPIOD, DCnRESET);
		Delay_N_x_10us(1000);	// 10 mSec
	}
	else
	{
	    /* Disable */
		GPIO_ResetBits(GPIOD, DCnRESET);
	}
	if (H_bridge != DISABLE)
	{
		/* Enable */
		GPIO_SetBits(GPIOB, PWMH);
		GPIO_SetBits(GPIOB, PWML);
	}
	else
	{
	    /* Disable */
		GPIO_ResetBits(GPIOB, PWMH);
		GPIO_ResetBits(GPIOB, PWML);
	}
}


void DCmotor_faultClear(void)
{
	GPIO_ResetBits(GPIOD, DCnRESET);
	GPIO_SetBits(GPIOD, DCnRESET);
}


void DC_motorPWM(uint8_t duty_cycle)	// duty_cycle > 50 ---> hatra
{										// duty_cycle < 50 ---> elore
	TIM4->CCR3 = (uint16_t)(((period+1)*duty_cycle)/100);
	//TIM4->CCR3 = duty_cycle;
}


void encoder_Init(void)
{
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA | RCC_APB2Periph_AFIO, ENABLE);
	GPIO_InitTypeDef gpioa_input = { GPIO_Pin_1, GPIO_Speed_50MHz, GPIO_Mode_IPD };	// input pulled down, felfuto elig szamol
	GPIO_Init(GPIOA, &gpioa_input);

	RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM2, ENABLE);
	TIM_TimeBaseInitTypeDef timer2;
	TIM_DeInit(TIM2);
	//TIM_TimeBaseStructInit(TIM2);
	timer2.TIM_Period = 49999;	// 16 biten vegig szamol -> 1/5 Hz (0.0562 km/h) - 10 kHz ()
	timer2.TIM_Prescaler = 7199;	// 10 kHz - 100 us
	timer2.TIM_ClockDivision = 0;
	timer2.TIM_CounterMode = TIM_CounterMode_Up;
	timer2.TIM_RepetitionCounter = 0;
	TIM_TimeBaseInit(TIM2, &timer2);
	//TIM_DMAConfig(TIM2, TIM_DMABase_CCR2, TIM_DMABurstLength_1Transfer);
	//TIM_DMACmd(TIM2, TIM_DMA_CC2, ENABLE);

	TIM_ICInitTypeDef TIM2_ICInitStructure;
	TIM2_ICInitStructure.TIM_Channel = TIM_Channel_2;
	TIM2_ICInitStructure.TIM_ICPolarity = TIM_ICPolarity_Rising;
	TIM2_ICInitStructure.TIM_ICSelection = TIM_ICSelection_DirectTI;
	TIM2_ICInitStructure.TIM_ICPrescaler = TIM_ICPSC_DIV1;
	TIM2_ICInitStructure.TIM_ICFilter = 0;
	TIM_ICInit(TIM2,&TIM2_ICInitStructure);
	TIM_ITConfig(TIM2, TIM_IT_CC2, ENABLE);

	NVIC_InitTypeDef NVIC_InitStructure;
	NVIC_InitStructure.NVIC_IRQChannel = TIM2_IRQn;
	NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 2;
	NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
	NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
	NVIC_Init(&NVIC_InitStructure);

	TIM_Cmd(TIM2, ENABLE);
}


uint8_t captureNumber = 0;
uint16_t counter1, counter2;

void TIM2_IRQHandler(void)
{
	uint16_t capture;

	if (TIM_GetITStatus(TIM2, TIM_IT_CC2))
	{
		if(captureNumber == 0)
		{
		    counter1 = TIM2->CCR2;
		    captureNumber = 1;
		}
		else if(captureNumber == 1)
		{
		    counter2 = TIM2->CCR2;
		    if (counter2 > counter1)
		    {
		         capture = (counter2 - counter1);
		    }
		    else if (counter2 <= counter1)
		    {
		    	capture = ((50000 - counter1) + counter2);
		    }
		    counter1 = counter2;

		    // sebessegkorlatozas
		    if(capture < sebessegkorlat && DC_PWM  < 46)
		    {
		    	DC_PWM = DC_PWM + 1;
		    	DC_motorPWM(DC_PWM);
		    }
		    else if (capture < sebessegkorlat && DC_PWM  > 54)
			{
		    	DC_PWM = DC_PWM - 1;
		    	DC_motorPWM(DC_PWM);
			}

		    telemetria[34] = (uint8_t)((capture>>8));
		    telemetria[35] = (uint8_t)capture;
		}
		TIM_ClearITPendingBit(TIM2,TIM_IT_CC2);
	}
}

void SystemStop(void)
{
	DC_PWM = 50;
	DC_motorPWM(DC_PWM);					// 50 - DC motor állj
	DCmotor_Cmd(DISABLE, DISABLE);			// DC motor, nem kell enable kulon
	SZERVO_PWM = 140;
	szervoPWM(SZERVO_PWM);
	Delay_N_x_10us(10000);
	TIM_Cmd(TIM5, DISABLE);					// szervo, nem kell enable
	lepteto_defaultStep();					// lepteto, nem kell enable
}
