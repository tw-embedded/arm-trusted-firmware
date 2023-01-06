/*
 * Copyright (c) 2022, Arm Limited. All rights reserved.
 * Copyright (c) 2022, Linaro.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <stdint.h>

#include <drivers/measured_boot/event_log/event_log.h>
#include <plat/common/common_def.h>
#include <tools_share/tbbr_oid.h>

#include "../common/fake_private.h"

/* Event Log data */
static uint8_t event_log[PLAT_EVENT_LOG_MAX_SIZE];
static uint64_t event_log_base;

/* FVP table with platform specific image IDs, names and PCRs */
const event_log_metadata_t fake_event_log_metadata[] = {
	{ BL31_IMAGE_ID, EVLOG_BL31_STRING, PCR_0 },
	{ BL32_IMAGE_ID, EVLOG_BL32_STRING, PCR_0 },
	{ BL32_EXTRA1_IMAGE_ID, EVLOG_BL32_EXTRA1_STRING, PCR_0 },
	{ BL32_EXTRA2_IMAGE_ID, EVLOG_BL32_EXTRA2_STRING, PCR_0 },
	{ BL33_IMAGE_ID, EVLOG_BL33_STRING, PCR_0 },
	{ HW_CONFIG_ID, EVLOG_HW_CONFIG_STRING, PCR_0 },
	{ NT_FW_CONFIG_ID, EVLOG_NT_FW_CONFIG_STRING, PCR_0 },
	{ SCP_BL2_IMAGE_ID, EVLOG_SCP_BL2_STRING, PCR_0 },
	{ SOC_FW_CONFIG_ID, EVLOG_SOC_FW_CONFIG_STRING, PCR_0 },
	{ TOS_FW_CONFIG_ID, EVLOG_TOS_FW_CONFIG_STRING, PCR_0 },

	{ EVLOG_INVALID_ID, NULL, (unsigned int)(-1) }	/* Terminator */
};

void bl2_plat_mboot_init(void)
{
	/*
	 * Here we assume that BL1/ROM code doesn't have the driver
	 * to measure the BL2 code which is a common case for
	 * already existing platforms
	 */
	event_log_init(event_log, event_log + sizeof(event_log));
	event_log_write_header();

	/*
	 * TBD - Add code to do self measurement of BL2 code and add an
	 * event for BL2 measurement
	 */

	event_log_base = (uintptr_t)event_log;
}
