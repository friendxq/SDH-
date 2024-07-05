`timescale 1ns/1ps
////////////////////////////////////////////////////////////////////////////////
// Company		: cheerchips
// Engineer		: david
// Design Name	: 
// Module Name	: sdh_transmitter
// Project Name	: 
// Target Device: 
// Tool versions: 
// Description	: 
//				
// Revision		: V1.0
// Additional Comments	:  
// 
////////////////////////////////////////////////////////////////////////////////

module sdh_transmitter 
           (
                   input             rst_n,
                   input             sdh_clk, 
        
//////////////////////////////传输侧信号接口/////////////////////////
        
                   input [7:0]       sdh_tx_din,
                   output            sdh_tx_din_req,    //提前1拍
                   
  				         // 输出经过加扰后的32位数据，同时有下插全1功能
		               output [31:0]	   sdh_gtx_fifo_data  ,
	                 output            sdh_gtx_fifo_wen   
            			);
    
//------------- 内部信号定义 -----------    
wire   [7:0]	  tx_no_scramble_data        ;
wire            tx_scramb_en    ;
wire            start_of_frame  ,start_of_frame_d1;
wire   [7:0]    tx_int_scram_data   ;
wire   [7:0]    b1_cal ;
	
tx_sdh_framer  U_tx_sdh_framer 
           (
            .rst_n         (rst_n),
            .sdh_clk       (sdh_clk),
        
//////////////////////////////传输侧信号接口/////////////////////////
           
            .sdh_tx_din    (sdh_tx_din  ), 
            .sdh_tx_din_req(sdh_tx_din_req), //提前1拍
            .b1_cal        (b1_cal),
                   
  				  //SDH发送方向的相关接口信号
			      .tx_no_scramble_data      (tx_no_scramble_data),
			      .start_of_frame           (start_of_frame),
			      .tx_scramb_en             (tx_scramb_en)
             );
             
tx_scram  U_tx_scram (
// 输入复位信号，高有效，输入77.76M时钟，8位需加扰数据
		.rst_n                   (rst_n),
		.sdh_clk                 (sdh_clk),
		.tx_no_scramble_data     (tx_no_scramble_data),
    .start_of_frame          (start_of_frame),
// 输入加扰使能信号，为1时允许加扰，为0时不加扰，初始化为0xFE，一般前9xN个不用加扰。
		.tx_scramb_en            (tx_scramb_en),

// 输出经过加扰后的32位数据，同时有下插全1功能
		.sdh_gtx_fifo_data       (sdh_gtx_fifo_data),
		.sdh_gtx_fifo_wen        (sdh_gtx_fifo_wen),
		.tx_int_scram_data       (tx_int_scram_data),
		.start_of_frame_d1       (start_of_frame_d1)
	);
	
b1_calculation  U_b1_calculation

       (
        .rst_n             (rst_n),
        .sdh_clk           (sdh_clk), 
		    .tx_int_scram_data (tx_int_scram_data),
		    .start_of_frame_d1 (start_of_frame_d1),
		    .b1_cal            (b1_cal)
       );

			
endmodule
   