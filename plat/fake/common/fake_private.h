/*
 * Copyright (c) 2015-2022, ARM Limited and Contributors. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

#ifndef FAKE_PRIVATE_H
#define FAKE_PRIVATE_H

#include <stdint.h>

void fake_configure_mmu_svc_mon(unsigned long total_base,
			unsigned long total_size,
			unsigned long code_start, unsigned long code_limit,
			unsigned long ro_start, unsigned long ro_limit,
			unsigned long coh_start, unsigned long coh_limit);

void fake_configure_mmu_el1(unsigned long total_base, unsigned long total_size,
			unsigned long code_start, unsigned long code_limit,
			unsigned long ro_start, unsigned long ro_limit,
			unsigned long coh_start, unsigned long coh_limit);

void fake_configure_mmu_el3(unsigned long total_base, unsigned long total_size,
			unsigned long code_start, unsigned long code_limit,
			unsigned long ro_start, unsigned long ro_limit,
			unsigned long coh_start, unsigned long coh_limit);

void plat_fake_io_setup(void);
unsigned int plat_fake_calc_core_pos(u_register_t mpidr);

void fake_console_init(void);

void plat_fake_gic_init(void);
void fake_pwr_gic_on_finish(void);
void fake_pwr_gic_off(void);

#endif /* FAKE_PRIVATE_H */
