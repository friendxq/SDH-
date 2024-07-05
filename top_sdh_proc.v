`timescale 1ns/1ps
////////////////////////////////////////////////////////////////////////////////
// Company		: cheerchips
// Engineer		: david
// Design Name	: 
// Module Name	: top_sdh_proc
// Project Name	: 
// Target Device: 
// Tool versions: 
// Description	: 
//				
// Revision		: V1.0
// Additional Comments	:  
// 
////////////////////////////////////////////////////////////////////////////////

module top_sdh_proc 
           (
                   input             rst_n,
                   input             sdh_clk, 
        
//////////////////////////////传输侧信号接口/////////////////////////
        
                   input [7:0]       sdh_tx_din,
                   output            sdh_tx_din_req, //提前1拍
                   
  				         //SDH发送方向的相关接口信号
  				         output [31:0]     sdh_gtx_fifo_data,
                   output            sdh_gtx_fifo_wen,
                   
                   //SDH接收方向的相关接口信号
                   input  [7:0]      gtx_sdh_fifo_rdata,
                   output [7:0]      rx_int_data,
                   output            rx_int_data_vld,
                   output            warn_out

            			);
    
//------------- 内部信号定义 --------------------    

sdh_transmitter  U_sdh_transmitter 
     (
     .rst_n                (rst_n),
     .sdh_clk              (sdh_clk), 
   
////////////////传输侧信号接口/////////////////////////
                   
     .sdh_tx_din           (sdh_tx_din  ),
     .sdh_tx_din_req       (sdh_tx_din_req),//提前1拍
     
  	 // 输出经过加扰后的32位数据，同时有下插全1功能
		 .sdh_gtx_fifo_data    (sdh_gtx_fifo_data),
	   .sdh_gtx_fifo_wen     (sdh_gtx_fifo_wen )
   	);

		
sdh_receiver  U_sdh_receiver 
   (
     .rst_n              (rst_n),
     .sdh_clk            (sdh_clk), 
        
//////////////////////////////传输侧信号接口/////////////////////////
  	// 输出经过加扰后的32位数据，同时有下插全1功能
		 .gtx_sdh_fifo_rdata (gtx_sdh_fifo_rdata),
	   .rx_int_data        (rx_int_data       ),
	   .rx_int_data_vld    (rx_int_data_vld   ),
	   .warn_out           (warn_out          )
     );
			
endmodule


