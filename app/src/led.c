/*
 * Blink the board LED with a periodic kernel timer. The expiry callback runs in
 * the system clock ISR and toggles the GPIO LED every half period; the
 * gpio-leds + esp32 gpio set path uses only irq_lock(), so it is ISR-safe.
 * Nothing polls, so the CPU idles between timer ticks.
 */

#include "led.h"

#include <zephyr/drivers/led.h>
#include <zephyr/logging/log.h>

#include <errno.h>

LOG_MODULE_REGISTER(led, CONFIG_LOG_DEFAULT_LEVEL);

static void on_blink_timer(struct k_timer *timer)
{
	app_led_t *app = CONTAINER_OF(timer, app_led_t, timer);

	app->is_on = !app->is_on;

	if (app->is_on) {
		led_on_dt(app->config.spec);
	} else {
		led_off_dt(app->config.spec);
	}
}

int led_start(app_led_t *app)
{
	if (!led_is_ready_dt(app->config.spec)) {
		LOG_ERR("%s not ready", app->config.spec->dev->name);
		return -ENODEV;
	}

	const k_timeout_t half_period = K_USEC(app->config.blink_period_us / 2);

	k_timer_init(&app->timer, on_blink_timer, NULL);
	k_timer_start(&app->timer, half_period, half_period);

	LOG_INF("started");
	return 0;
}
