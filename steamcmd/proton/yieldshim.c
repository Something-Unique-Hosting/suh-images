/*
 * LD_PRELOAD shim: turn sched_yield() into a short sleep.
 *
 * Enshrouded's server runs a ~60 Hz job graph even when empty (~2,200 jobs/s).
 * Each job handoff ends in a yield (Windows SwitchToThread/Sleep(0) and Wine's
 * own wait path all land in NtYieldExecution -> sched_yield). Under Wine those
 * yields return immediately, so the threads spin. Sleeping instead cut idle CPU
 * from ~33% to ~11% of a core in testing (ny2, 2026-10-15).
 *
 * SUH_YIELD_SLEEP_US: sleep length in microseconds. Unset, empty or 0 keeps the
 * real sched_yield, so the shim is a no-op unless configured.
 */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <sched.h>
#include <stdlib.h>
#include <time.h>

static long sleep_ns = -1;
static int (*real_yield)(void);

static void init(void) {
	const char *e = getenv("SUH_YIELD_SLEEP_US");
	long us = e ? atol(e) : 0;
	sleep_ns = us > 0 ? us * 1000L : 0;
	real_yield = dlsym(RTLD_NEXT, "sched_yield");
}

int sched_yield(void) {
	if (sleep_ns < 0)
		init();
	if (sleep_ns > 0) {
		struct timespec ts = { sleep_ns / 1000000000L, sleep_ns % 1000000000L };
		nanosleep(&ts, NULL);
		return 0;
	}
	return real_yield ? real_yield() : 0;
}
