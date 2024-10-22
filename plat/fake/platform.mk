#
# Copyright (c) 2013-2022, ARM Limited and Contributors. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Use the GICv2 or v3 driver
USE_GIC_DRIVER := GICV3

ifeq (${ARM_ARCH_MAJOR},7)
# ARMv7 support in trusted firmware expects the Cortex-A15 model.
# Cortex-A15 model does not implement the virtualization extension.
# For this reason, we cannot set ARM_CORTEX_A15=yes and must define all
# the ARMv7 build directives.
MARCH32_DIRECTIVE := -mcpu=cortex-a15
$(eval $(call add_define,ARMV7_SUPPORTS_LARGE_PAGE_ADDRESSING))
$(eval $(call add_define,ARMV7_SUPPORTS_GENERIC_TIMER))
$(eval $(call add_define,ARMV7_SUPPORTS_VFP))
# expects a BL32 boot stage.
NEED_BL32 := yes
endif # ARMv7

ifeq (${SPD},opteed)
add-lib-optee := yes
endif
ifeq ($(AARCH32_SP),optee)
add-lib-optee := yes
endif
ifeq ($(SPMC_OPTEE),1)
$(eval $(call add_define,SPMC_OPTEE))
add-lib-optee := yes
endif

ifeq ($(NEED_BL32),yes)
$(eval $(call add_define,FAKE_LOAD_BL32))
endif

PLAT_FAKE_PATH := plat/fake
PLAT_FAKE_COMMON_PATH := plat/fake/common
PLAT_INCLUDES := -Iinclude/plat/arm/common/ \
                 -I${PLAT_FAKE_COMMON_PATH}/include \
                 -I${PLAT_FAKE_PATH}/include \
                 -Iinclude/common/tbbr

ifeq (${ARM_ARCH_MAJOR},8)
PLAT_INCLUDES += -Iinclude/plat/arm/common/${ARCH}
endif

PLAT_BL_COMMON_SOURCES := ${PLAT_FAKE_COMMON_PATH}/fake_common.c \
                ${PLAT_FAKE_COMMON_PATH}/fake_console.c \
                drivers/arm/pl011/${ARCH}/pl011_console.S

include lib/xlat_tables_v2/xlat_tables.mk
PLAT_BL_COMMON_SOURCES += ${XLAT_TABLES_LIB_SRCS}

ifneq (${TRUSTED_BOARD_BOOT},0)

    AUTH_SOURCES := drivers/auth/auth_mod.c \
                drivers/auth/img_parser_mod.c \
                drivers/auth/tbbr/tbbr_cot_common.c

    BL1_SOURCES += ${AUTH_SOURCES} \
                bl1/tbbr/tbbr_img_desc.c \
                plat/common/tbbr/plat_tbbr.c \
                ${PLAT_FAKE_COMMON_PATH}/fake_trusted_boot.c \
                $(PLAT_FAKE_COMMON_PATH)/fake_rotpk.S \
                drivers/auth/tbbr/tbbr_cot_bl1.c

    BL2_SOURCES += ${AUTH_SOURCES} \
                plat/common/tbbr/plat_tbbr.c \
                ${PLAT_FAKE_COMMON_PATH}/fake_trusted_boot.c \
                $(PLAT_FAKE_COMMON_PATH)/fake_rotpk.S \
                drivers/auth/tbbr/tbbr_cot_bl2.c

    include drivers/auth/mbedtls/mbedtls_x509.mk

    ROT_KEY = $(BUILD_PLAT)/rot_key.pem
    ROTPK_HASH = $(BUILD_PLAT)/rotpk_sha256.bin

    $(eval $(call add_define_val,ROTPK_HASH,'"$(ROTPK_HASH)"'))

    $(BUILD_PLAT)/bl1/fake_rotpk.o: $(ROTPK_HASH)
    $(BUILD_PLAT)/bl2/fake_rotpk.o: $(ROTPK_HASH)

    certificates: $(ROT_KEY)

    $(ROT_KEY): | $(BUILD_PLAT)
    @echo "  OPENSSL $@"
    $(Q)${OPENSSL_BIN_PATH}/openssl genrsa 2048 > $@ 2>/dev/null

    $(ROTPK_HASH): $(ROT_KEY)
    @echo "  OPENSSL $@"
    $(Q)${OPENSSL_BIN_PATH}/openssl rsa -in $< -pubout -outform DER 2>/dev/null |\
    ${OPENSSL_BIN_PATH}/openssl dgst -sha256 -binary > $@ 2>/dev/null
endif

# Include Measured Boot makefile before any Crypto library makefile.
# Crypto library makefile may need default definitions of Measured Boot build
# flags present in Measured Boot makefile.
ifeq (${MEASURED_BOOT},1)
    MEASURED_BOOT_MK := drivers/measured_boot/event_log/event_log.mk
    $(info Including ${MEASURED_BOOT_MK})
    include ${MEASURED_BOOT_MK}

    ifneq (${MBOOT_EL_HASH_ALG}, sha256)
        $(eval $(call add_define,TF_MBEDTLS_MBOOT_USE_SHA512))
    endif

    BL2_SOURCES += plat/fake/fake_measured_boot.c \
                plat/fake/fake_common_measured_boot.c \
                ${EVENT_LOG_SOURCES}

     BL1_SOURCES += plat/fake/fake_bl1_measured_boot.c

endif

ifneq ($(filter 1,${MEASURED_BOOT} ${TRUSTED_BOARD_BOOT}),)
    CRYPTO_SOURCES := drivers/auth/crypto_mod.c

    BL1_SOURCES += ${CRYPTO_SOURCES}
    BL2_SOURCES += ${CRYPTO_SOURCES}

    # We expect to locate the *.mk files under the directories specified below
    include drivers/auth/mbedtls/mbedtls_crypto.mk
endif

BL1_SOURCES += drivers/io/io_semihosting.c \
                drivers/io/io_storage.c \
                drivers/io/io_fip.c \
                drivers/io/io_memmap.c \
                lib/semihosting/semihosting.c \
                lib/semihosting/${ARCH}/semihosting_call.S \
                ${PLAT_FAKE_COMMON_PATH}/fake_io_storage.c \
                ${PLAT_FAKE_COMMON_PATH}/${ARCH}/plat_helpers.S \
                ${PLAT_FAKE_COMMON_PATH}/fake_bl1_setup.c

ifeq (${ARM_ARCH_MAJOR},8)
BL1_SOURCES += lib/cpus/aarch64/aem_generic.S \
                lib/cpus/aarch64/cortex_a53.S \
                lib/cpus/aarch64/cortex_a57.S \
                lib/cpus/aarch64/cortex_a72.S
else
BL1_SOURCES += lib/cpus/${ARCH}/cortex_a15.S
endif

BL2_SOURCES += drivers/io/io_semihosting.c \
                drivers/io/io_storage.c \
                drivers/io/io_fip.c \
                drivers/io/io_memmap.c \
                lib/semihosting/semihosting.c \
                lib/semihosting/${ARCH}/semihosting_call.S \
                ${PLAT_FAKE_COMMON_PATH}/fake_io_storage.c \
                ${PLAT_FAKE_COMMON_PATH}/${ARCH}/plat_helpers.S \
                ${PLAT_FAKE_COMMON_PATH}/fake_bl2_setup.c \
                ${PLAT_FAKE_COMMON_PATH}/fake_bl2_mem_params_desc.c \
                ${PLAT_FAKE_COMMON_PATH}/fake_image_load.c \
                common/desc_image_load.c

ifeq ($(add-lib-optee),yes)
BL2_SOURCES += lib/optee/optee_utils.c
endif

ifneq (${DECRYPTION_SUPPORT},none)
BL1_SOURCES += drivers/io/io_encrypted.c
BL2_SOURCES += drivers/io/io_encrypted.c
endif

# Include GICv2 driver files
include drivers/arm/gic/v2/gicv2.mk
FAKE_GICV2_SOURCES := ${GICV2_SOURCES} \
                plat/common/plat_gicv2.c \
                ${PLAT_FAKE_COMMON_PATH}/fake_gicv2.c

# Include GICv3 driver files
include drivers/arm/gic/v3/gicv3.mk

GICV3_SOURCES := ${GICV3_SOURCES} \
                plat/common/plat_gicv3.c \
                ${PLAT_FAKE_COMMON_PATH}/fake_gicv3.c

ifeq (${USE_GIC_DRIVER}, GICV2)
FAKE_GIC_SOURCES := ${GICV2_SOURCES}
else ifeq (${USE_GIC_DRIVER}, GICV3)
FAKE_GIC_SOURCES := ${GICV3_SOURCES}
else
$(error "Incorrect GIC driver chosen for fake platform")
endif

ifeq (${ARM_ARCH_MAJOR},8)
BL31_SOURCES += lib/cpus/aarch64/aem_generic.S \
                lib/cpus/aarch64/cortex_a53.S \
                lib/cpus/aarch64/cortex_a57.S \
                lib/cpus/aarch64/cortex_a72.S \
                lib/semihosting/semihosting.c \
                lib/semihosting/${ARCH}/semihosting_call.S \
                plat/common/plat_psci_common.c \
                drivers/arm/pl061/pl061_gpio.c \
                drivers/gpio/gpio.c \
                ${PLAT_FAKE_COMMON_PATH}/fake_pm.c \
                ${PLAT_FAKE_COMMON_PATH}/topology.c \
                ${PLAT_FAKE_COMMON_PATH}/aarch64/plat_helpers.S \
                ${PLAT_FAKE_COMMON_PATH}/fake_bl31_setup.c \
                ${FAKE_GIC_SOURCES}

ifeq (${SPD},spmd)
BL31_SOURCES += plat/fake/common/fake_spmd_manifest.c
endif
endif

# Add the build options to pack Trusted OS Extra1 and Trusted OS Extra2 images
# in the FIP if the platform requires.
ifneq ($(BL32_EXTRA1),)
ifneq (${DECRYPTION_SUPPORT},none)
$(eval $(call TOOL_ADD_IMG,bl32_extra1,--tos-fw-extra1,,$(ENCRYPT_BL32)))
else
$(eval $(call TOOL_ADD_IMG,bl32_extra1,--tos-fw-extra1))
endif
endif
ifneq ($(BL32_EXTRA2),)
ifneq (${DECRYPTION_SUPPORT},none)
$(eval $(call TOOL_ADD_IMG,bl32_extra2,--tos-fw-extra2,,$(ENCRYPT_BL32)))
else
$(eval $(call TOOL_ADD_IMG,bl32_extra2,--tos-fw-extra2))
endif
endif

SEPARATE_CODE_AND_RODATA := 1
ENABLE_STACK_PROTECTOR := 0
ifneq ($(ENABLE_STACK_PROTECTOR), 0)
    PLAT_BL_COMMON_SOURCES += ${PLAT_FAKE_COMMON_PATH}/fake_stack_protector.c
endif

BL32_RAM_LOCATION := tdram
ifeq (${BL32_RAM_LOCATION}, tsram)
  BL32_RAM_LOCATION_ID = SEC_SRAM_ID
else ifeq (${BL32_RAM_LOCATION}, tdram)
  BL32_RAM_LOCATION_ID = SEC_DRAM_ID
else
  $(error "Unsupported BL32_RAM_LOCATION value")
endif

# Process flags
$(eval $(call add_define,BL32_RAM_LOCATION_ID))

# Don't have the Linux kernel as a BL33 image by default
ARM_LINUX_KERNEL_AS_BL33 := 0
$(eval $(call assert_boolean,ARM_LINUX_KERNEL_AS_BL33))
$(eval $(call add_define,ARM_LINUX_KERNEL_AS_BL33))

#FDT_SOURCES := fdts/fake.dts
ARM_PRELOADED_DTB_BASE := PLAT_FAKE_DT_BASE
$(eval $(call add_define,ARM_PRELOADED_DTB_BASE))

# Do not enable SVE
ENABLE_SVE_FOR_NS := 0
