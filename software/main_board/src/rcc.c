#include "diploma.h"

void clock_Init(void)
{
	ErrorStatus HSEStartUpStatus;

	/* Reset the RCC clock configuration to default reset state */
	RCC_DeInit();

	/* Configure the High Speed External oscillator */
	RCC_HSEConfig(RCC_HSE_ON);
	/* Wait for HSE start-up */
	HSEStartUpStatus = RCC_WaitForHSEStartUp();
	if(HSEStartUpStatus == SUCCESS)
	{
	    /* Enable Prefetch Buffer */
	    FLASH_PrefetchBufferCmd(FLASH_PrefetchBuffer_Enable);
	    /* Set the code latency value: FLASH Two Latency cycles */
	    FLASH_SetLatency(FLASH_Latency_2);
	    /* Configure the AHB clock(HCLK): HCLK = SYSCLK */
	    RCC_HCLKConfig(RCC_SYSCLK_Div1);
	    /* Configure the High Speed APB2 clcok(PCLK2): PCLK2 = HCLK */
	    RCC_PCLK2Config(RCC_HCLK_Div1);
	    /* Configure the Low Speed APB1 clock(PCLK1): PCLK1 = HCLK/2 */
	    RCC_PCLK1Config(RCC_HCLK_Div2);
	    /* Configure the PLL clock source and multiplication factor */
	    /* PLLCLK = HSE*PLLMul = 8*9 = 72MHz */
	    RCC_PLLConfig(RCC_PLLSource_PREDIV1, RCC_PLLMul_9);
	    /* Enable PLL */
	    RCC_PLLCmd(ENABLE);
	    /* Check whether the specified RCC flag is set or not */
	    /* Wait till PLL is ready       */
	    while(RCC_GetFlagStatus(RCC_FLAG_PLLRDY) == RESET);
	    /* Select PLL as system clock source */
	    RCC_SYSCLKConfig(RCC_SYSCLKSource_PLLCLK);
	    /* Get System Clock Source */
	    /* Wait till PLL is used as system clock source */
	    while(RCC_GetSYSCLKSource() != 0x08);
	}
	timer6_Init();
	// group 4 -> only pre-emption priority (0-15)
	NVIC_PriorityGroupConfig(NVIC_PriorityGroup_4);
}

void timer6_Init(void)
{
	RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM6, ENABLE);
	TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;
	TIM_TimeBaseStructure.TIM_Period = 50000; 	//	max 500 mSec
	TIM_TimeBaseStructure.TIM_Prescaler = 719;	// 100 kHz - 10 us
	TIM_TimeBaseStructure.TIM_ClockDivision = 0;
	TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
	TIM_TimeBaseInit(TIM6, &TIM_TimeBaseStructure);
}

void Delay_N_x_10us(uint16_t delay)		// max 500 mSec -> delay = 50000
{
	TIM6->CNT = 0;
	TIM_Cmd(TIM6, ENABLE);
	while (TIM6->CNT != delay);
	TIM_Cmd(TIM6, DISABLE);
}

void MCO_out(void)
{
	GPIO_InitTypeDef mco;

	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA,ENABLE);
	mco.GPIO_Pin = GPIO_Pin_8;
	mco.GPIO_Speed = GPIO_Speed_50MHz;
	mco.GPIO_Mode = GPIO_Mode_AF_PP;
	GPIO_Init(GPIOA,&mco);
	RCC_MCOConfig(RCC_MCO_PLLCLK_Div2);
}
