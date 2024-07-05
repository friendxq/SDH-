`timescale 1ns/1ps

module rx_descram (
// 输入复位信号，低有效
		rst_n, 
		sdh_clk, 
		rx_rec_data,
		rx_data_vld,
		b1_valid,

// rx_los_en, rx_lof_en和rx_oof_en是对应的告警发生时是否下插全1的使能信号，高有效
// rx_cpu_en为CPU强行下插全1的使能信号，高有效。
		rx_cpu_en, 
		rx_los_en, 
		rx_lof_en, 
		rx_oof_en,

// 输入LOs、OOF和LOF告警
		rx_stm_los, 
		rx_stm_oof, 
		rx_stm_lof,

// 输入解扰使能信号，为1时允许解扰，为0时不解扰，初始化为0xFE
		rx_descramb_en,
		rx_int_data,
		rx_int_data_vld,
		rec_b1 ,    
		b1_valid_d2
	);
	
	input			      rst_n, sdh_clk;
	input			      rx_cpu_en, rx_los_en, rx_lof_en, rx_oof_en;
	input			      rx_stm_los, rx_stm_oof, rx_stm_lof;
	input			      rx_descramb_en, rx_data_vld;
	input           b1_valid ;
	input  [7:0]		rx_rec_data;
	
	output [7:0]		rx_int_data;
	output          rx_int_data_vld ;
	output [7:0]		rec_b1;
	output          b1_valid_d2 ;
         
	reg    [7:0]		rx_int_data;
	reg             rx_int_data_vld, b1_valid_d2 ;
	reg    [7:0]		rec_b1;
// -------------------------------------------------
  reg			          rx_ais_en;	
  reg      [7:0]	  rx_descramb_byte;
  reg               b1_valid_d1 ;

// 先统一产生下插全1的信号，既节约资源又提高速度
always@(negedge rst_n or posedge sdh_clk)
	begin
		if(!rst_n)
			rx_ais_en <= 1'd0;
		else
			rx_ais_en <=   rx_lof_en & rx_stm_lof ;
	end

// 对输入数据RReceiveByte进行解扰，前9*16个数据不用解扰。
// 在不扰码时置扰码器为FE，扰码时根据扰码器的结构推出移八次后的扰码器值
  always@(negedge rst_n or posedge sdh_clk)
  	begin
		if(!rst_n)
			rx_descramb_byte <= 8'd0;
		else
			begin
				if(!rx_descramb_en)
					rx_descramb_byte <= 8'hfe;
				else
					begin
						rx_descramb_byte[7] <= rx_descramb_byte[6] ^ rx_descramb_byte[5];
						rx_descramb_byte[6] <= rx_descramb_byte[5] ^ rx_descramb_byte[4];
						rx_descramb_byte[5] <= rx_descramb_byte[4] ^ rx_descramb_byte[3];
						rx_descramb_byte[4] <= rx_descramb_byte[3] ^ rx_descramb_byte[2];
						rx_descramb_byte[3] <= rx_descramb_byte[2] ^ rx_descramb_byte[1];
						rx_descramb_byte[2] <= rx_descramb_byte[1] ^ rx_descramb_byte[0];
						rx_descramb_byte[1] <= rx_descramb_byte[0] ^ (rx_descramb_byte[6] ^ rx_descramb_byte[5]);
						rx_descramb_byte[0] <= rx_descramb_byte[6] ^ rx_descramb_byte[4];
					end
			end
	end

// 解扰输出，同时将发生告警时下插全1一起完成。
always@(negedge rst_n or posedge sdh_clk)
	begin
		if(!rst_n)
		begin
			rx_int_data <= 8'd0;
			rx_int_data_vld <= 1'b0;
		end
		else
			begin
				if(rx_ais_en)
					rx_int_data <= 8'hff;
				else if(rx_descramb_en)
					rx_int_data <= rx_rec_data ^ rx_descramb_byte;
				else
					rx_int_data <= rx_rec_data;
			 
			  rx_int_data_vld <= rx_data_vld ;
			end
	end

  always@(negedge rst_n or posedge sdh_clk)
	begin
		if(!rst_n)
		begin
			rec_b1 <= 8'd0;
			b1_valid_d1 <= 1'b0;
			b1_valid_d2 <= 1'b0;
		end
		else
			begin
				if(b1_valid_d1)
					rec_b1 <= rx_int_data;
			 
			  b1_valid_d1 <= b1_valid ;
			  b1_valid_d2 <= b1_valid_d1 ;
			end
	end

  endmodule
