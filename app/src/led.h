#pragma once

#include <zephyr/kernel.h>
#include <zephyr/drivers/led.h>

#include <stdbool.h>
#include <stdint.h>

typedef struct {
	struct led_dt_spec *spec;
	uint64_t blink_period_us;
} app_led_config_t;

typedef struct {
	struct k_timer timer;
	app_led_config_t config;
	bool is_on;
} app_led_t;

/* Start a periodic kernel timer that blinks the LED. Returns 0 on success, or
 * -ENODEV (after logging) if the LED device failed to initialize at boot. */
int led_start(app_led_t *app);
