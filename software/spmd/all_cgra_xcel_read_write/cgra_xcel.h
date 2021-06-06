#include "bsg_manycore.h"
#include "bsg_set_tile_x_y.h"

#define str(s) #s
#define xstr(s) str(s)

#define TEST_NAME xstr(TEST_SEL)

// Useful macros

#define NUM_POD_Y 4
#define NUM_XCEL_POD_PER_POD_Y 2

#define POD_CORD_X_WIDTH 3
#define POD_CORD_Y_WIDTH 4

#define TILE_CORD_X_WIDTH 4
#define TILE_CORD_Y_WIDTH 3

// For single pod simulations CGRA pod is at POD X=5,Y=1
#define XCEL_X_CORD ((5) << TILE_CORD_X_WIDTH | (0))
#define XCEL_Y_CORD ((1) << TILE_CORD_Y_WIDTH | (0))

#define CONFIG_INST 0
#define LAUNCH_INST 1

#define CGRA_REG_CALC_GO          0
#define CGRA_REG_CFG_GO           1
#define CGRA_REG_ME_CFG_BASE_ADDR 2
#define CGRA_REG_PE_CFG_BASE_ADDR 3
#define CGRA_REG_PE_CFG_STRIDE    4
#define CGRA_REG_CFG_CMD          5
#define CGRA_REG_CFG_DONE         6
#define CGRA_REG_CALC_DONE        7

#define CGRA_BASE_SCRATCHPAD_WORD_ADDR 8
