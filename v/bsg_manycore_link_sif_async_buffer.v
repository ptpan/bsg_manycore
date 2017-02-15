//====================================================================
// bsg_manycore_link_sif_async_buffer.v
// 02/15/2017, shawnless.xie@gmail.com
//====================================================================
//
//This module converts the bsg_manycore_link_sif signals between different 
//clock domains.

module bsg_manycore_link_sif_async_buffer 
   #(   addr_width_p  = 32
      , data_width_p  = 32
      , x_cord_width_p = "inv"
      , y_cord_width_p = "inv"
      , fifo_els_p    = 2
      , bsg_manycore_link_sif_width_lp = `bsg_manycore_link_sif_width(addr_width_p, data_width_p, x_cord_width_p, y_cord_width_p)
    )(
    //the left side signal 
    input                                       clk_left_i
   ,input                                       reset_left_i
   ,input [bsg_manycore_link_sif_width_lp-1:0] link_sif_left_i
   ,input [bsg_manycore_link_sif_width_lp-1:0] link_sif_left_o
    //the right side signal
   ,input                                      clk_right_i
   ,input                                      reset_right_i
   ,input [bsg_manycore_link_sif_width_lp-1:0] link_sif_right_i
   ,input [bsg_manycore_link_sif_width_lp-1:0] link_sif_right_o
   ); 
   ////////////////////////////////////////////////////////////////////////////////////////
   // Declear the cast structures. 
   localparam return_packet_width_lp = `bsg_manycore_return_packet_width(x_cord_width_p, 
                                                                         y_cord_width_p);

   localparam packet_width_lp        = `bsg_manycore_packet_width       (addr_width_p,
                                                                         data_width_p,
                                                                         x_cord_width_p,
                                                                         y_cord_width_p);
   localparam fifo_lg_size_lp        = `BSG_SAFE_CLOG2( fifo_els_p );

   `declare_bsg_manycore_link_sif_s(addr_width_p,data_width_p,x_cord_width_p,y_cord_width_p);

   bsg_manycore_link_sif_s link_sif_left_i_cast,  link_sif_left_o_cast ;
   bsg_manycore_link_sif_s link_sif_right_i_cast, link_sif_right_o_cast;

   assign link_sif_left_i_cast = link_sif_left_i;
   assign link_sif_left_o      = link_sif_left_o_cast;
   assign link_sif_right_i_cast= link_sif_right_i;
   assign link_sif_right_o     = link_sif_right_o_cast;

   ////////////////////////////////////////////////////////////////////////////////////////
   // Covert left to right forwarding signals 
   wire                         l2r_fwd_w_enq   ;
   wire [packet_width_lp-1:0]   l2r_fwd_w_data  ;
   wire                         l2r_fwd_w_full  ;

   wire                         l2r_fwd_r_deq   ;
   wire [packet_width_lp-1:0]   l2r_fwd_r_data  ;
   wire                         l2r_fwd_r_valid ;
    bsg_async_fifo #(.lg_size_p  ( fifo_lg_size_lp )
                    ,.width_p    ( packet_width_lp ) 
                    )left2right_fwd
   (
     .w_clk_i   ( clk_left_i    )
    ,.w_reset_i ( reset_left_i  )
    // not legal to w_enq_i if w_full_o is not low.
    ,.w_enq_i   ( l2r_fwd_w_enq   )
    ,.w_data_i  ( l2r_fwd_w_data  )
    ,.w_full_o  ( l2r_fwd_w_full  )

    // not legal to r_deq_i if r_valid_o is not high.
    ,.r_clk_i   ( clk_right_i     )
    ,.r_reset_i ( reset_right_i   )
    ,.r_deq_i   ( l2r_fwd_r_deq   )
    ,.r_data_o  ( l2r_fwd_r_data  )
    ,.r_valid_o ( l2r_fwd_r_valid )
    );

    assign l2r_fwd_w_enq    =  (~ l2r_fwd_w_full ) & link_sif_left_i_cast.fwd.v     ;
    assign l2r_fwd_w_enq    =                        link_sif_left_i_cast.fwd.data  ;
    assign link_sif_left_o_cast.fwd.ready_and_rev = ~l2r_fwd_w_full                 ;

    assign l2r_fwd_r_deq    =  l2r_fwd_r_valid     & link_sif_right_i_cast.fwd.ready_and_rev;
    assign link_sif_right_o_cast.fwd.v            = l2r_fwd_r_valid                 ;
    assign link_sif_right_o_cast.fwd.data         = l2r_fwd_r_data                  ;
   ////////////////////////////////////////////////////////////////////////////////////////
   // Covert right to left reverse  signals 
   wire                                 r2l_rev_w_enq   ;
   wire [return_packet_width_lp-1:0]    r2l_rev_w_data  ;
   wire                                 r2l_rev_w_full  ;

   wire                                 r2l_rev_r_deq   ;
   wire [return_packet_width_lp-1:0]    r2l_rev_r_data  ;
   wire                                 r2l_rev_r_valid ;
    bsg_async_fifo #(.lg_size_p  ( fifo_lg_size_lp          )
                    ,.width_p    ( return_packet_width_lp   )
                    )right2left_rev
   (
     .w_clk_i   ( clk_right_i    )
    ,.w_reset_i ( reset_right_i  )
    // not legal to w_enq_i if w_full_o is not low.
    ,.w_enq_i   ( r2l_rev_w_enq  )
    ,.w_data_i  ( r2l_rev_w_data )
    ,.w_full_o  ( r2l_rev_w_full )

    // not legal to r_deq_i if r_valid_o is not high.
    ,.r_clk_i   ( clk_left_i     )
    ,.r_reset_i ( reset_left_i   )
    ,.r_deq_i   ( r2l_rev_r_deq  )
    ,.r_data_o  ( r2l_rev_r_data )
    ,.r_valid_o ( r2l_rev_r_valid)
    );

    assign r2l_rev_w_enq    =  (~ r2l_rev_w_full ) & link_sif_right_i_cast.rev.v     ;
    assign r2l_rev_w_enq    =                        link_sif_right_i_cast.rev.data  ;
    assign link_sif_right_o_cast.rev.ready_and_rev = ~r2l_rev_w_full                 ;

    assign r2l_rev_r_deq    =  r2l_rev_r_valid     & link_sif_left_i_cast.rev.ready_and_rev;
    assign link_sif_left_o_cast.rev.v            = r2l_rev_r_valid                 ;
    assign link_sif_left_o_cast.rev.data         = r2l_rev_r_data                  ;

   ////////////////////////////////////////////////////////////////////////////////////////
   // Covert left to right reverse signals 
   wire                                 l2r_rev_w_enq   ;
   wire [return_packet_width_lp-1:0]    l2r_rev_w_data  ;
   wire                                 l2r_rev_w_full  ;

   wire                                 l2r_rev_r_deq   ;
   wire [return_packet_width_lp-1:0]    l2r_rev_r_data  ;
   wire                                 l2r_rev_r_valid ;
    bsg_async_fifo #(.lg_size_p  ( fifo_lg_size_lp )
                    ,.width_p    ( return_packet_width_lp ) 
                    )left2right_rev
   (
     .w_clk_i   ( clk_left_i    )
    ,.w_reset_i ( reset_left_i  )
    // not legal to w_enq_i if w_full_o is not low.
    ,.w_enq_i   ( l2r_rev_w_enq   )
    ,.w_data_i  ( l2r_rev_w_data  )
    ,.w_full_o  ( l2r_rev_w_full  )

    // not legal to r_deq_i if r_valid_o is not high.
    ,.r_clk_i   ( clk_right_i     )
    ,.r_reset_i ( reset_right_i   )
    ,.r_deq_i   ( l2r_rev_r_deq   )
    ,.r_data_o  ( l2r_rev_r_data  )
    ,.r_valid_o ( l2r_rev_r_valid )
    );

    assign l2r_rev_w_enq    =  (~ l2r_rev_w_full ) & link_sif_left_i_cast.rev.v     ;
    assign l2r_rev_w_enq    =                        link_sif_left_i_cast.rev.data  ;
    assign link_sif_left_o_cast.rev.ready_and_rev = ~l2r_rev_w_full                 ;

    assign l2r_rev_r_deq    =  l2r_rev_r_valid     & link_sif_right_i_cast.rev.ready_and_rev;
    assign link_sif_right_o_cast.rev.v            = l2r_rev_r_valid                 ;
    assign link_sif_right_o_cast.rev.data         = l2r_rev_r_data                  ;

   ////////////////////////////////////////////////////////////////////////////////////////
   // Covert right to left forward  signals 
   wire                                 r2l_fwd_w_enq   ;
   wire [packet_width_lp-1:0]           r2l_fwd_w_data  ;
   wire                                 r2l_fwd_w_full  ;

   wire                                 r2l_fwd_r_deq   ;
   wire [packet_width_lp-1:0]           r2l_fwd_r_data  ;
   wire                                 r2l_fwd_r_valid ;
    bsg_async_fifo #(.lg_size_p  ( fifo_lg_size_lp          )
                    ,.width_p    ( packet_width_lp          )
                    )right2left_fwd
   (
     .w_clk_i   ( clk_right_i    )
    ,.w_reset_i ( reset_right_i  )
    // not legal to w_enq_i if w_full_o is not low.
    ,.w_enq_i   ( r2l_fwd_w_enq  )
    ,.w_data_i  ( r2l_fwd_w_data )
    ,.w_full_o  ( r2l_fwd_w_full )

    // not legal to r_deq_i if r_valid_o is not high.
    ,.r_clk_i   ( clk_left_i     )
    ,.r_reset_i ( reset_left_i   )
    ,.r_deq_i   ( r2l_fwd_r_deq  )
    ,.r_data_o  ( r2l_fwd_r_data )
    ,.r_valid_o ( r2l_fwd_r_valid)
    );

    assign r2l_fwd_w_enq    =  (~ r2l_fwd_w_full ) & link_sif_right_i_cast.fwd.v     ;
    assign r2l_fwd_w_enq    =                        link_sif_right_i_cast.fwd.data  ;
    assign link_sif_right_o_cast.fwd.ready_and_fwd = ~r2l_fwd_w_full                 ;

    assign r2l_fwd_r_deq    =  r2l_fwd_r_valid     & link_sif_left_i_cast.fwd.ready_and_fwd;
    assign link_sif_left_o_cast.fwd.v            = r2l_fwd_r_valid                 ;
    assign link_sif_left_o_cast.fwd.data         = r2l_fwd_r_data                  ;
endmodule
