#include <bcm2835.h>
#include "GPIO.h"

/**
 * Turn off all LEDs and finalize SPI.
 */
void restore_gpios() {
    bcm2835_gpio_set(ENABLE);
    bcm2835_spi_end();
    bcm2835_close();
}

/**
 * Configures all GPIO modes and initial state.
 */
bool initialize_gpios() {
    if (!bcm2835_init()) {
        return false;
    }

    // Set levels and ENABLE GPIOs mode to OUT
    bcm2835_gpio_fsel(ENABLE, BCM2835_GPIO_FSEL_OUTP);
    bcm2835_gpio_fsel(LEVEL1, BCM2835_GPIO_FSEL_OUTP);
    bcm2835_gpio_fsel(LEVEL2, BCM2835_GPIO_FSEL_OUTP);
    bcm2835_gpio_fsel(LEVEL3, BCM2835_GPIO_FSEL_OUTP);
    bcm2835_gpio_fsel(LEVEL4, BCM2835_GPIO_FSEL_OUTP);
    bcm2835_gpio_fsel(LEVEL5, BCM2835_GPIO_FSEL_OUTP);
    bcm2835_gpio_fsel(LEVEL6, BCM2835_GPIO_FSEL_OUTP);
    bcm2835_gpio_fsel(LEVEL7, BCM2835_GPIO_FSEL_OUTP);
    bcm2835_gpio_fsel(LEVEL8, BCM2835_GPIO_FSEL_OUTP);

    // Configure initial SPI properties
    bcm2835_spi_begin();
    bcm2835_spi_setDataMode(BCM2835_SPI_MODE0);
    bcm2835_spi_chipSelect(BCM2835_SPI_CS0);
    bcm2835_spi_setClockDivider(BCM2835_SPI_CLOCK_DIVIDER_32);

    // Set initial states
    bcm2835_gpio_set(LEVEL1);
    bcm2835_gpio_set(LEVEL2);
    bcm2835_gpio_set(LEVEL3);
    bcm2835_gpio_set(LEVEL4);
    bcm2835_gpio_set(LEVEL5);
    bcm2835_gpio_set(LEVEL6);
    bcm2835_gpio_set(LEVEL7);
    bcm2835_gpio_set(LEVEL8);
    bcm2835_gpio_clr(ENABLE);
    return true;
}
