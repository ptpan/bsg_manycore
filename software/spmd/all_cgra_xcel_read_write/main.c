#include "cgra_xcel.h"

int main()
{
  int i, j, y_cord, val, ref_val;
  int cgra_n;
  int cnt = 0;
  bsg_set_tile_x_y();
  bsg_remote_int_ptr cgra_ptr;

  if ((__bsg_x == bsg_tiles_X-1) && (__bsg_y == bsg_tiles_Y-1)) {

    bsg_printf("\nManycore>> Active core %d, %d in group origin=(%d,%d).\n", \
                       __bsg_x, __bsg_y, __bsg_grp_org_x, __bsg_grp_org_y);

    // Write to CGRA SRAM
    for (i = 0; i < NUM_POD_Y; i++) {
      for (j = 0; j < NUM_XCEL_POD_PER_POD_Y; j++) {
        cgra_n = i*NUM_XCEL_POD_PER_POD_Y+j;
        ref_val = 0xdeadbeef + cgra_n;
        y_cord = ((1+NUM_XCEL_POD_PER_POD_Y*i) << TILE_CORD_Y_WIDTH) | (j == 0 ? 0 : 4);
        cgra_ptr = bsg_global_ptr(XCEL_X_CORD, y_cord, 0);
        cgra_ptr += CGRA_BASE_SCRATCHPAD_WORD_ADDR + 1;
        *cgra_ptr = ref_val;
        bsg_printf("\n[CGRA #%d] Value %X written.\n", cgra_n, ref_val );
      }
    }

    // Read from the same address
    for (i = 0; i < NUM_POD_Y; i++) {
      for (j = 0; j < NUM_XCEL_POD_PER_POD_Y; j++) {
        cgra_n = i*NUM_XCEL_POD_PER_POD_Y+j;
        ref_val = 0xdeadbeef + cgra_n;
        y_cord = ((1+NUM_XCEL_POD_PER_POD_Y*i) << TILE_CORD_Y_WIDTH) | (j == 0 ? 0 : 4);
        cgra_ptr = bsg_global_ptr(XCEL_X_CORD, y_cord, 0);
        cgra_ptr += CGRA_BASE_SCRATCHPAD_WORD_ADDR + 1;
        val = *cgra_ptr;
        if (val != ref_val) {
          bsg_printf("\n[CGRA #%d] Wrong value: got %X but ref is %X.\n", \
                        cgra_n, val, ref_val );
          bsg_fail();
        } else {
          bsg_printf("\n[CGRA #%d] Passed!", cgra_n );
        }
      }
    }

    bsg_finish();

  }

  bsg_wait_while(1);
}
