#include "diploma.h"

void GPIO_Init_all(void)
{
	//GPIOB Init, DISABLE JTAG
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOB | RCC_APB2Periph_AFIO, ENABLE);
	GPIO_PinRemapConfig(GPIO_Remap_SWJ_JTAGDisable, ENABLE);	// PA15, PB3, PB4 enabled, JTDI, JTDO, NJTRST disabled
	GPIO_InitTypeDef gpiob_output = { WHITE_LED1 | WHITE_LED2, GPIO_Speed_50MHz, GPIO_Mode_Out_PP };
	GPIO_Init(GPIOB, &gpiob_output);
	resetWhiteLED();

	//GPIOD Init
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOD, ENABLE);
	GPIO_InitTypeDef gpiod_input = { BUTTON_LEFT, GPIO_Speed_50MHz, GPIO_Mode_IN_FLOATING };
	GPIO_InitTypeDef gpiod_output = { BLUE_LED, GPIO_Speed_50MHz, GPIO_Mode_Out_PP };
	GPIO_Init(GPIOD, &gpiod_input);
	GPIO_Init(GPIOD, &gpiod_output);

	//GPIOE Init
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOE, ENABLE);
	GPIO_InitTypeDef gpioe_input = { BUTTON_RIGHT, GPIO_Speed_50MHz, GPIO_Mode_IN_FLOATING };
	GPIO_InitTypeDef gpioe_output = { RED_LED | ENABLE_4V8, GPIO_Speed_50MHz, GPIO_Mode_Out_PP};
	GPIO_Init(GPIOE, &gpioe_input);
	GPIO_Init(GPIOE, &gpioe_output);

	enable_4V8();
}


void enable_4V8(void)
{
	GPIO_SetBits(GPIOE, ENABLE_4V8);
}

void disable_4V8(void)
{
	GPIO_ResetBits(GPIOE, ENABLE_4V8);
}

void setRedLED(void)
{
	GPIO_SetBits(GPIOE, RED_LED);
}

void setBlueLED(void)
{
	GPIO_SetBits(GPIOD, BLUE_LED);
}

void setWhiteLED(void)
{
	GPIO_SetBits(GPIOB, WHITE_LED1);
	GPIO_SetBits(GPIOB, WHITE_LED2);
}

void resetRedLED(void)
{
	GPIO_ResetBits(GPIOE, RED_LED);
}

void resetBlueLED(void)
{
	GPIO_ResetBits(GPIOD, BLUE_LED);
}

void resetWhiteLED(void)
{
	GPIO_ResetBits(GPIOB, WHITE_LED1);
	GPIO_ResetBits(GPIOB, WHITE_LED2);
}

void red_led_toggle(void)
{
    uint8_t led_bit = GPIO_ReadOutputDataBit(GPIOE, RED_LED);

    if(led_bit == (uint8_t)Bit_SET)
    {
        GPIO_ResetBits(GPIOE, RED_LED);
    }
    else
    {
        GPIO_SetBits(GPIOE, RED_LED);
    }
}

void blue_led_toggle(void)
{
    uint8_t led_bit = GPIO_ReadOutputDataBit(GPIOD, BLUE_LED);

    if(led_bit == (uint8_t)Bit_SET)
    {
        GPIO_ResetBits(GPIOD, BLUE_LED);
    }
    else
    {
        GPIO_SetBits(GPIOD, BLUE_LED);
    }
}

void white_led_toggle(void)
{
    uint8_t led_bit1 = GPIO_ReadOutputDataBit(GPIOB, WHITE_LED1);
    uint8_t led_bit2 = GPIO_ReadOutputDataBit(GPIOB, WHITE_LED2);

    if(led_bit1 == (uint8_t)Bit_SET)
    {
        GPIO_ResetBits(GPIOB, WHITE_LED1);
    }
    else
    {
        GPIO_SetBits(GPIOB, WHITE_LED1);
    }

    if(led_bit2 == (uint8_t)Bit_SET)
    {
        GPIO_ResetBits(GPIOB, WHITE_LED2);
    }
    else
    {
        GPIO_SetBits(GPIOB, WHITE_LED2);
    }
}

uint8_t button_right(void)
{
	return(!GPIO_ReadInputDataBit(GPIOE, BUTTON_RIGHT));
}

uint8_t button_left(void)
{
	return(!GPIO_ReadInputDataBit(GPIOD, BUTTON_LEFT));
}
