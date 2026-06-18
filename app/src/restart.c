/*
 * "restart" shell command: cold-reboot the SoC so main() re-runs from a clean
 * state. SHELL_CMD_REGISTER self-registers the command at boot via an iterable
 * section, so nothing in the app calls into this file.
 */

#include <zephyr/shell/shell.h>
#include <zephyr/sys/reboot.h>

static int cmd_restart(const struct shell *sh, size_t argc, char **argv)
{
	ARG_UNUSED(argc);
	ARG_UNUSED(argv);

	shell_print(sh, "rebooting...");
	sys_reboot(SYS_REBOOT_COLD);

	return 0; /* not reached: sys_reboot does not return */
}

SHELL_CMD_REGISTER(restart, NULL, "Reboot the board (re-runs main)", cmd_restart);
