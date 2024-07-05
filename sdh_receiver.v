`timescale 1ns/1ps
////////////////////////////////////////////////////////////////////////////////
// Company		: cheerchips
// Engineer		: david
// Design Name	: 
// Module Name	: tx_sdh_framer
// Project Name	: 
// Target Device: 
// Tool versions: 
// Description	: 
//				
// Revision		: V1.0
// Additional Comments	:  
// 
////////////////////////////////////////////////////////////////////////////////

module sdh_receiver 
           (
                   input             rst_n,
                   input             sdh_clk, 
        
//////////////////////////////������źŽӿ�/////////////////////////
  				       //SDH���շ������ؽӿ��ź�
                   input  [7:0]      gtx_sdh_fifo_rdata,
                   output [7:0]      rx_int_data,
                   output            rx_int_data_vld,
                   output            warn_out
            			);
    
//------------- �ڲ��źŶ��� -----------    
wire   [7:0]     rx_rec_data     ;
wire         	   rx_stm_oof      ;
wire         	   rx_stm_lof      ;
wire             rx_data_vld     ;
wire   [7:0]     rec_b1          ;
wire             b1_valid_d2     ;
wire             rx_1st_byte_valid;
wire             b1_err ;
	
assign   warn_out = rx_stm_oof | rx_stm_lof | b1_err ;
	
rx_byte_framer U_rx_byte_framer (
		.rst_n              (rst_n             ),
		.sdh_clk            (sdh_clk           ),
		.rx_data_i          (gtx_sdh_fifo_rdata),
		.rx_rec_data_o      (rx_rec_data      ),
		.rx_descramb_en     (rx_descramb_en   ),
		.rx_data_vld        (rx_data_vld      ),
		.rx_1st_byte_valid  (rx_1st_byte_valid),
		.b1_valid           (b1_valid         ),
		.rx_stm_oof         (rx_stm_oof       ),
		.rx_stm_lof         (rx_stm_lof       )
	);

rx_descram  U_rx_descram (
// ���븴λ�źţ�����Ч
		.rst_n          (rst_n),         
		.sdh_clk        (sdh_clk),
		.rx_rec_data    (rx_rec_data),
		.rx_data_vld    (rx_data_vld),
		.b1_valid       (b1_valid),

// Rx_LOS_En, Rx_LOF_En��Rx_OOF_En�Ƕ�Ӧ�ĸ澯����ʱ�Ƿ��²�ȫ1��ʹ���źţ�����Ч
// Rx_CPU_EnΪCPUǿ���²�ȫ1��ʹ���źţ�����Ч��
		.rx_cpu_en      (1'b0),
		.rx_los_en      (1'b0),
		.rx_lof_en      (1'b1),
		.rx_oof_en      (1'b1),

// ����LOs��OOF��LOF�澯
		.rx_stm_los     (1'b0),
		.rx_stm_oof     (rx_stm_oof),
		.rx_stm_lof     (rx_stm_lof),

// �������ʹ���źţ�Ϊ1ʱ������ţ�Ϊ0ʱ������
		.rx_descramb_en (rx_descramb_en ),
		.rx_int_data    (rx_int_data    ),
		.rx_int_data_vld(rx_int_data_vld),
		.rec_b1         (rec_b1),    
		.b1_valid_d2    (b1_valid_d2)
	);

b1_check  U_b1_check

       (
        .rst_n              (rst_n  ),
        .sdh_clk            (sdh_clk), 
		    .rec_b1             (rec_b1),
		    .b1_valid_d2        (b1_valid_d2),
		    .rx_1st_byte_valid  (rx_1st_byte_valid),
		    .rx_rec_data        (rx_rec_data),
		    .b1_err             (b1_err)
       );
			
endmodule
   