#include "diploma.h"

void lepteto_Init(void)
{
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA | RCC_APB2Periph_AFIO, ENABLE);
	GPIO_InitTypeDef gpioa_step = { STEP, GPIO_Speed_50MHz, GPIO_Mode_AF_PP };
	GPIO_Init(GPIOA, &gpioa_step);

	RCC_APB2PeriphClockCmd(RCC_APB2Periph_TIM1, ENABLE);
	//uint16_t period = (uint16_t)((49999+1)/32); 	// 1.562 ms -> 640.205 Hz
	TIM_TimeBaseInitTypeDef timer1;
	TIM_DeInit(TIM1);
	TIM_TimeBaseStructInit(TIM1);
	timer1.TIM_Period = 1562;		// 3200 lépés 1/32 módban = 180° 1562*3200=5 sec, 5 sec-180°
	timer1.TIM_Prescaler = 71;	// 1 MHz - 1 us
	timer1.TIM_ClockDivision = 0;
	timer1.TIM_CounterMode = TIM_CounterMode_Up;
	timer1.TIM_RepetitionCounter = 0;
	TIM_TimeBaseInit(TIM1, &timer1);
	TIM_SelectOnePulseMode(TIM1, TIM_OPMode_Single);
	TIM_ITConfig(TIM1, TIM_IT_Update, ENABLE);

	//uint8_t duty_cycle = 50;
	TIM_OCInitTypeDef tim1_pwm;
	TIM_OCStructInit(&tim1_pwm);
	tim1_pwm.TIM_OCMode = TIM_OCMode_PWM2; 	// 0->1  PWM1: 1->0
	tim1_pwm.TIM_OutputState = TIM_OutputState_Enable;
	//tim1_pwm.TIM_Pulse = (uint16_t)(((period+1)*duty_cycle)/100);
	tim1_pwm.TIM_Pulse = 730;
	tim1_pwm.TIM_OCPolarity = TIM_OCPolarity_High;
	TIM_OC1Init(TIM1, &tim1_pwm);
	TIM_OC1PreloadConfig(TIM1, TIM_OCPreload_Enable);
	TIM_ARRPreloadConfig(TIM1, ENABLE);
	TIM_CtrlPWMOutputs(TIM1, ENABLE);
	//TIM_Cmd(TIM1, ENABLE);


	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOC, ENABLE);
	GPIO_InitTypeDef gpioc_input = { nFAULT, GPIO_Speed_50MHz, GPIO_Mode_IN_FLOATING };
	GPIO_InitTypeDef gpioc_output = { DECAY | nSLEEP | nRESET, GPIO_Speed_50MHz, GPIO_Mode_Out_PP };
	GPIO_Init(GPIOC, &gpioc_input);
	GPIO_Init(GPIOC, &gpioc_output);

	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOD, ENABLE);
	GPIO_InitTypeDef gpiod_input = { nHOME, GPIO_Speed_50MHz, GPIO_Mode_IN_FLOATING };
	GPIO_InitTypeDef gpiod_output = { MODE0 | MODE1 | MODE2 | nENBL | DIR, GPIO_Speed_50MHz, GPIO_Mode_Out_PP };
	GPIO_Init(GPIOD, &gpiod_input);
	GPIO_Init(GPIOD, &gpiod_output);

	uint8_t mode0 = 0x0, mode1 = 0x0, mode2 = 0x0;
	uint8_t dir = 0x1;
	uint8_t decay = 0x1;

	Lepteto_InitTypeDef Lepteto_InitStruct;
	Lepteto_InitStruct.Mode = Mode_32microstep;
	Lepteto_InitStruct.Direction = Direction_Left;
	Lepteto_InitStruct.Decay_Mode = Decay_Mode_Fast;

	mode0 = Lepteto_InitStruct.Mode & 0b00000001;
	mode1 = Lepteto_InitStruct.Mode & 0b00000010;
	mode2 = Lepteto_InitStruct.Mode & 0b00000100;

	dir = Lepteto_InitStruct.Direction;
	decay = Lepteto_InitStruct.Decay_Mode;

	if (mode0)
	{
		GPIO_SetBits(GPIOD, MODE0);
	}
	else
	{
		GPIO_ResetBits(GPIOD, MODE0);
	}

	if (mode1)
	{
		GPIO_SetBits(GPIOD, MODE1);
	}
	else
	{
		GPIO_ResetBits(GPIOD, MODE1);
	}
	if (mode2)
	{
		GPIO_SetBits(GPIOD, MODE2);
	}
	else
	{
		GPIO_ResetBits(GPIOD, MODE2);
	}

	if (dir)
	{
		GPIO_SetBits(GPIOD, DIR);
	}
	else
	{
		GPIO_ResetBits(GPIOD, DIR);
	}

	if (decay)
	{
		GPIO_SetBits(GPIOC, DECAY);
	}
	else
	{
		GPIO_ResetBits(GPIOC, DECAY);
	}
	GPIO_SetBits(GPIOD, nENBL);
	GPIO_SetBits(GPIOC, nRESET);
	GPIO_SetBits(GPIOC, nSLEEP);
	stepNumber = 3200;
}

void lepteto_Cmd(FunctionalState enable)
{
	if (enable != DISABLE)
	{
		/* Enable */
		GPIO_ResetBits(GPIOD, nENBL);
	}
	else
	{
	    /* Disable */
		GPIO_SetBits(GPIOD, nENBL);
	}
}

void lepteto_step(void)
{
	TIM_Cmd(TIM1, ENABLE);

	// globalis valtozo allapota, lepesszamot abban szamolni, gyakorlatilag pl 100x meghivjuk
	// a függvenyt a mainbol es az engedelyezo bitet akkor tiltjuk le ha a lepesszam mar 0
	while(!TIM_GetITStatus(TIM1, TIM_IT_Update));

	TIM_ClearITPendingBit(TIM1, TIM_IT_Update);
}

uint16_t lepteto_stepNumber(uint8_t angle, uint8_t direction)
{
	uint8_t mode0, mode1, mode2, temp = 0x0;

	float lepesszog = 1.8/32, maradek = 0, lepesszam = 0;

	mode0 = GPIO_ReadInputDataBit(GPIOD, MODE0);
	mode1 = GPIO_ReadInputDataBit(GPIOD, MODE1);
	mode2 = GPIO_ReadInputDataBit(GPIOD, MODE2);

	if (direction == 1)
	{
		GPIO_SetBits(GPIOD, DIR);	// right
	}
	else if (direction == 0)
	{
		GPIO_ResetBits(GPIOD, DIR);	// left
	}

	temp = temp | mode0 | mode1<<1 | mode2<<2;

	if (angle <= 180)
	{
		switch (temp)
		{
			case 0:
			{
				lepesszog = 1.8;
				lepesszam = angle/lepesszog;
				maradek = lepesszam - (uint16_t)lepesszam;
				if (maradek < 0.5)
				{
					lepesszam = (uint16_t)lepesszam;
				}
				else
				{
					lepesszam = (uint16_t)(lepesszam + 1);
				}
				if (direction == 1)
				{
					if ((stepNumber + ((-1)*(32/1)*lepesszam)) < 0)
					{
						lepesszam = (32/1)*stepNumber;
						stepNumber = 0;
					}
					else
					{
						stepNumber = stepNumber + ((-1)*(32/1)*lepesszam);
					}
				}
				else if (direction == 0)
				{
					if ((stepNumber + ((32/1)*lepesszam)) > 6400)
					{
						lepesszam = (32/1)*(6400-stepNumber);
						stepNumber = 6400;
					}
					else
					{
						stepNumber = stepNumber + ((32/1)*lepesszam);
					}
				}
				return (uint16_t)lepesszam;
			}
			case 1:
			{
				lepesszog = 1.8/2;
				lepesszam = angle/lepesszog;
				maradek = lepesszam - (uint16_t)lepesszam;
				if (maradek < 0.5)
				{
					lepesszam = (uint16_t)lepesszam;
				}
				else
				{
					lepesszam = (uint16_t)(lepesszam + 1);
				}
				if (direction == 1)
				{
					if ((stepNumber + ((-1)*(32/2)*lepesszam)) < 0)
					{
						lepesszam = (32/2)*stepNumber;
						stepNumber = 0;
					}
					else
					{
						stepNumber = stepNumber + ((-1)*(32/2)*lepesszam);
					}
				}
				else if (direction == 0)
				{
					if ((stepNumber + ((32/2)*lepesszam)) > 6400)
					{
						lepesszam = (32/2)*(6400-stepNumber);
						stepNumber = 6400;
					}
					else
					{
						stepNumber = stepNumber + ((32/2)*lepesszam);
					}
				}
				return (uint16_t)lepesszam;
			}
			case 2:
			{
				lepesszog = 1.8/4;
				lepesszam = angle/lepesszog;
				maradek = lepesszam - (uint16_t)lepesszam;
				if (maradek < 0.5)
				{
					lepesszam = (uint16_t)lepesszam;
				}
				else
				{
					lepesszam = (uint16_t)(lepesszam + 1);
				}
				if (direction == 1)
				{
					if ((stepNumber + ((-1)*(32/4)*lepesszam)) < 0)
					{
						lepesszam = (32/4)*stepNumber;
						stepNumber = 0;
					}
					else
					{
						stepNumber = stepNumber + ((-1)*(32/4)*lepesszam);
					}
				}
				else if (direction == 0)
				{
					if ((stepNumber + ((32/4)*lepesszam)) > 6400)
					{
						lepesszam = (32/4)*(6400-stepNumber);
						stepNumber = 6400;
					}
					else
					{
						stepNumber = stepNumber + ((32/4)*lepesszam);
					}
				}
				return (uint16_t)lepesszam;
			}
			case 3:
			{
				lepesszog = 1.8/8;
				lepesszam = angle/lepesszog;
				maradek = lepesszam - (uint16_t)lepesszam;
				if (maradek < 0.5)
				{
					lepesszam = (uint16_t)lepesszam;
				}
				else
				{
					lepesszam = (uint16_t)(lepesszam + 1);
				}
				if (direction == 1)
				{
					if ((stepNumber + ((-1)*(32/8)*lepesszam)) < 0)
					{
						lepesszam = (32/8)*stepNumber;
						stepNumber = 0;
					}
					else
					{
						stepNumber = stepNumber + ((-1)*(32/8)*lepesszam);
					}
				}
				else if (direction == 0)
				{
					if ((stepNumber + ((32/8)*lepesszam)) > 6400)
					{
						lepesszam = (32/8)*(6400-stepNumber);
						stepNumber = 6400;
					}
					else
					{
						stepNumber = stepNumber + ((32/8)*lepesszam);
					}
				}
				return (uint16_t)lepesszam;
			}
			case 4:
			{
				lepesszog = 1.8/16;
				lepesszam = angle/lepesszog;
				maradek = lepesszam - (uint16_t)lepesszam;
				if (maradek < 0.5)
				{
					lepesszam = (uint16_t)lepesszam;
				}
				else
				{
					lepesszam = (uint16_t)(lepesszam + 1);
				}
				if (direction == 1)
				{
					if ((stepNumber + ((-1)*(32/16)*lepesszam)) < 0)
					{
						lepesszam = (32/16)*stepNumber;
						stepNumber = 0;
					}
					else
					{
						stepNumber = stepNumber + ((-1)*(32/16)*lepesszam);
					}
				}
				else if (direction == 0)
				{
					if ((stepNumber + ((32/16)*lepesszam)) > 6400)
					{
						lepesszam = (32/16)*(6400-stepNumber);
						stepNumber = 6400;
					}
					else
					{
						stepNumber = stepNumber + ((32/16)*lepesszam);
					}
				}
				return (uint16_t)lepesszam;
			}
			/*case 5:
			{
				lepesszog = 1.8/32;
				lepesszam = angle/lepesszog;
				maradek = (float)(lepesszam - (uint16_t)lepesszam);
				if (maradek < 0.5)
				{
					lepesszam = (uint16_t)lepesszam;
				}
				else
				{
					lepesszam = (uint16_t)(lepesszam + 1);
				}
				if (direction == 1)
				{
					if ((stepNumber + ((-1)*(32/32)*lepesszam)) < 0)
					{
						lepesszam = ((32/32)*stepNumber);
						stepNumber = 0;
					}
					else
					{
						stepNumber = stepNumber + ((-1)*(32/32)*lepesszam);
					}
				}
				else if (direction == 0)
				{
					if ((stepNumber + ((32/32)*lepesszam)) > 6400)
					{
						lepesszam = ((32/32)*(6400-stepNumber));
						stepNumber = 6400;
					}
					else
					{
						stepNumber = stepNumber + ((32/32)*lepesszam);
					}
				}
				return (uint16_t)lepesszam;*/
			case 5:
			{
				lepesszog = 1.8/32;
				lepesszam = angle/lepesszog;
				maradek = (float)(lepesszam - (uint16_t)lepesszam);
				if (maradek < 0.5)
				{
					lepesszam = (uint16_t)lepesszam;
				}
				else
				{
					lepesszam = (uint16_t)(lepesszam + 1);
				}
				if (direction == 1)
				{
					if ((stepNumber + (int16_t)((-1)*(32/32)*lepesszam)) < 0)
					{
						lepesszam = (float)((32/32)*stepNumber);
						stepNumber = 0;
					}
					else
					{
						stepNumber = stepNumber + (int16_t)((-1)*(32/32)*lepesszam);
					}
				}
				else if (direction == 0)
				{
					if ((stepNumber + (uint16_t)((32/32)*lepesszam)) > 6400)
					{
						lepesszam = (float)((32/32)*(6400-stepNumber));
						stepNumber = 6400;
					}
					else
					{
						stepNumber = stepNumber + (uint16_t)((32/32)*lepesszam);
					}
				}
				return (uint16_t)lepesszam;
			}
		}
	}
	else
	{
		return 0;
	}
}

void lepteto_defaultStep(void)
{
	TIM1->ARR = (uint16_t)((49999+1)/32);
	TIM1->EGR = TIM_PSCReloadMode_Immediate;
	GPIO_SetBits(GPIOD, MODE0);
	GPIO_ResetBits(GPIOD, MODE1);
	GPIO_SetBits(GPIOD, MODE2);
	if (stepNumber < 3200)
	{
		GPIO_ResetBits(GPIOD, DIR);		//jobbra van, ezert balra forgat vissza
		actualStep = 3200 - stepNumber;
		stepNumber = 3200;
		leptetoENBL = 1;
	}
	else if (stepNumber > 3200)
	{
		GPIO_SetBits(GPIOD, DIR);		//balra van, ezert jobbra forgat vissza
		actualStep = stepNumber - 3200;
		stepNumber = 3200;
		leptetoENBL = 1;
	}
}

void lepteto_config(uint8_t config)
{
	uint16_t sebesseg = 49999;				// 180° - 5 sec - fullstep

	switch(config)
	{
		case 0:		// fullstep
		{
			TIM1->ARR = sebesseg;
			TIM1->EGR = TIM_PSCReloadMode_Immediate;
			GPIO_ResetBits(GPIOD, MODE0);
			GPIO_ResetBits(GPIOD, MODE1);
			GPIO_ResetBits(GPIOD, MODE2);
			break;
		}
		case 1:		// halfstep
		{
			TIM1->ARR = ((sebesseg+1)/2)-1;
			TIM1->EGR = TIM_PSCReloadMode_Immediate;
			GPIO_SetBits(GPIOD, MODE0);
			GPIO_ResetBits(GPIOD, MODE1);
			GPIO_ResetBits(GPIOD, MODE2);
			break;
		}
		case 2:		// 1/4 step
		{
			TIM1->ARR = ((sebesseg+1)/4)-1;
			TIM1->EGR = TIM_PSCReloadMode_Immediate;
			GPIO_ResetBits(GPIOD, MODE0);
			GPIO_SetBits(GPIOD, MODE1);
			GPIO_ResetBits(GPIOD, MODE2);
			break;
		}
		case 3:		// 1/8 step
		{
			TIM1->ARR = ((sebesseg+1)/8)-1;
			TIM1->EGR = TIM_PSCReloadMode_Immediate;
			GPIO_SetBits(GPIOD, MODE0);
			GPIO_SetBits(GPIOD, MODE1);
			GPIO_ResetBits(GPIOD, MODE2);
			break;
		}
		case 4:		// 1/16 step
		{
			TIM1->ARR = ((sebesseg+1)/16)-1;
			TIM1->EGR = TIM_PSCReloadMode_Immediate;
			GPIO_ResetBits(GPIOD, MODE0);
			GPIO_ResetBits(GPIOD, MODE1);
			GPIO_SetBits(GPIOD, MODE2);
			break;
		}
		case 5:		// 1/32 step
		{
			TIM1->ARR = (uint16_t)((sebesseg+1)/32);
			TIM1->EGR = TIM_PSCReloadMode_Immediate;
			GPIO_SetBits(GPIOD, MODE0);
			GPIO_ResetBits(GPIOD, MODE1);
			GPIO_SetBits(GPIOD, MODE2);
			break;
		}
		case 6:		// fast DECAY
		{
			GPIO_SetBits(GPIOC, DECAY);
			break;
		}
		case 7:		// slow DECAY
		{
			GPIO_ResetBits(GPIOC, DECAY);
			break;
		}
		case 8:		// SLEEP
		{
			GPIO_ResetBits(GPIOC, nSLEEP);
			break;
		}
		case 9:		// NO SLEEP
		{
			GPIO_SetBits(GPIOC, nSLEEP);
			break;
		}
		case 10:		// RESET
		{
			GPIO_ResetBits(GPIOC, nRESET);
			break;
		}
		case 11:		// NO RESET
		{
			GPIO_SetBits(GPIOC, nRESET);
			break;
		}
		case 12:		// ENABLE
		{
			GPIO_ResetBits(GPIOD, nENBL);
			break;
		}
		case 13:		// DISABLE
		{
			GPIO_SetBits(GPIOD, nENBL);
			break;
		}
		case 14:		// DISABLE
		{
			lepteto_defaultStep();
			break;
		}
	}
}

//-------------------SZERVO MOTOR---------------------
void szervoPWM_Init(void)
{
	SZERVO_PWM = 140;

	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA | RCC_APB2Periph_AFIO, ENABLE);
    GPIO_InitTypeDef gpioa_tim5 = { GPIO_Pin_0, GPIO_Speed_50MHz, GPIO_Mode_AF_PP };
    GPIO_Init(GPIOA, &gpioa_tim5);

    RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM5, ENABLE);
    uint16_t period = 299;		// 3ms - 333.33 Hz - 299, (408-245 Hz)
    TIM_TimeBaseInitTypeDef timer5;
    timer5.TIM_Period = period;
    timer5.TIM_Prescaler = 719;		// 100 kHz - 10 us
    timer5.TIM_ClockDivision = 0;
    timer5.TIM_CounterMode = TIM_CounterMode_Up;
	TIM_TimeBaseInit(TIM5, &timer5);
	TIM_Cmd(TIM5, ENABLE);

	TIM_OCInitTypeDef tim5_pwm;
	tim5_pwm.TIM_OCMode = TIM_OCMode_PWM1;
	tim5_pwm.TIM_OutputState = TIM_OutputState_Enable;
	tim5_pwm.TIM_Pulse = 140;
	tim5_pwm.TIM_OCPolarity = TIM_OCPolarity_High;
	TIM_OC1Init(TIM5, &tim5_pwm);
	TIM_OC1PreloadConfig(TIM5, TIM_OCPreload_Enable);
	TIM_ARRPreloadConfig(TIM5, ENABLE);
}

void szervoPWM(uint8_t duty_cycle)		// 1.05ms(jobb-105) - (bal-175)1.75 ms -> kb. 26° összesen
{
	TIM_Cmd(TIM5, ENABLE);
	TIM5->CCR1 = (uint16_t)duty_cycle;
}
