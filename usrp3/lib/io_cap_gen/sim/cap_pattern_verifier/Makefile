#
# Copyright 2015 Ettus Research LLC
#

#-------------------------------------------------
# Top-of-Makefile
#-------------------------------------------------
# Define BASE_DIR to point to the "top" dir
BASE_DIR = $(abspath ../../../../top)
# Include viv_sim_preample after defining BASE_DIR
include $(BASE_DIR)/../tools/make/viv_sim_preamble.mak

#-------------------------------------------------
# Design Specific
#-------------------------------------------------
# Define part using PART_ID (<device>/<package>/<speedgrade>)
ARCH = kintex7
PART_ID = xc7k410t/ffg900/-2

DESIGN_SRCS += $(abspath \
../../cap_pattern_verifier.v \
)

#-------------------------------------------------
# Testbench Specific
#-------------------------------------------------
include $(BASE_DIR)/../sim/general/Makefile.srcs
include $(BASE_DIR)/../sim/axi/Makefile.srcs

# Define only one toplevel module
SIM_TOP = cap_pattern_verifier_tb
# Simulation runtime in microseconds
SIM_RUNTIME_US = 1000

SIM_SRCS = \
$(abspath cap_pattern_verifier_tb.sv) \
$(SIM_GENERAL_SRCS) \
$(SIM_AXI_SRCS)

#-------------------------------------------------
# Bottom-of-Makefile
#-------------------------------------------------
# Include all simulator specific makefiles here
# Each should define a unique target to simulate
# e.g. xsim, vsim, etc and a common "clean" target
include $(BASE_DIR)/../tools/make/viv_simulator.mak
