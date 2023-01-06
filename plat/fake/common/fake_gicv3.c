/*
 * Copyright (c) 2019, Linaro Limited and Contributors. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <drivers/arm/gicv3.h>
#include <drivers/arm/gic_common.h>
#include <platform_def.h>
#include <plat/common/platform.h>

static const interrupt_prop_t fake_interrupt_props[] = {
	PLATFORM_G1S_PROPS(INTR_GROUP1S),
	PLATFORM_G0_PROPS(INTR_GROUP0)
};

static uintptr_t fake_rdistif_base_addrs[PLATFORM_CORE_COUNT];

static unsigned int fake_mpidr_to_core_pos(unsigned long mpidr)
{
	return (unsigned int)plat_core_pos_by_mpidr(mpidr);
}

static const gicv3_driver_data_t fake_gicv3_driver_data = {
	.gicd_base = GICD_BASE,
	.gicr_base = GICR_BASE,
	.interrupt_props = fake_interrupt_props,
	.interrupt_props_num = ARRAY_SIZE(fake_interrupt_props),
	.rdistif_num = PLATFORM_CORE_COUNT,
	.rdistif_base_addrs = fake_rdistif_base_addrs,
	.mpidr_to_core_pos = fake_mpidr_to_core_pos
};

void plat_fake_gic_init(void)
{
	gicv3_driver_init(&fake_gicv3_driver_data);
	gicv3_distif_init();
	gicv3_rdistif_init(plat_my_core_pos());
	gicv3_cpuif_enable(plat_my_core_pos());
}

void fake_pwr_gic_on_finish(void)
{
	gicv3_rdistif_init(plat_my_core_pos());
	gicv3_cpuif_enable(plat_my_core_pos());
}

void fake_pwr_gic_off(void)
{
	gicv3_cpuif_disable(plat_my_core_pos());
	gicv3_rdistif_off(plat_my_core_pos());
}
