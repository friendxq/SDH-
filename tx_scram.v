`timescale 1 ns/1ps

module tx_scram (
// 输入复位信号，高有效，输入77.76M时钟，8位需加扰数据
		rst_n, 
		sdh_clk, 
		start_of_frame,
		tx_no_scramble_data,

// 输入加扰使能信号，为1时允许加扰，为0时不加扰，初始化为0xFE，前9xN个不应被加扰。
		tx_scramb_en,

// 输出经过加扰后的32位数据，同时有下插全1功能
		sdh_gtx_fifo_data,
		sdh_gtx_fifo_wen,
		tx_int_scram_data,
		start_of_frame_d1
	);
	input			        rst_n, sdh_clk     ;
	input			        tx_scramb_en       ;
	input             start_of_frame     ;
	input  [7:0]		  tx_no_scramble_data;
	output [31:0]	    sdh_gtx_fifo_data  ;
	output            sdh_gtx_fifo_wen   ;
	output [7:0]      tx_int_scram_data  ;
	output            start_of_frame_d1  ;
                                       
	reg    [31:0]		  sdh_gtx_fifo_data  ;
	reg               sdh_gtx_fifo_wen   ;
	reg               start_of_frame_d1  ;
// -------------------------------------------------
  reg    [7:0]	    tx_scramb_byte;
  reg    [7:0]	    tx_int_scram_data;
  reg               sdh_gtx_fifo_wen_p2,   sdh_gtx_fifo_wen_p1;

// 在不扰码时置扰码器为FE，扰码时根据扰码器的结构推出移八次后的扰码器值
  always@(negedge rst_n or posedge sdh_clk)
  	begin
		if(!rst_n)
			tx_scramb_byte <= 8'd0;
		else
			begin
				if(!tx_scramb_en)
					tx_scramb_byte <= 8'hfe;
				else
					begin
						tx_scramb_byte[7] <= tx_scramb_byte[6] ^ tx_scramb_byte[5];
						tx_scramb_byte[6] <= tx_scramb_byte[5] ^ tx_scramb_byte[4];
						tx_scramb_byte[5] <= tx_scramb_byte[4] ^ tx_scramb_byte[3];
						tx_scramb_byte[4] <= tx_scramb_byte[3] ^ tx_scramb_byte[2];
						tx_scramb_byte[3] <= tx_scramb_byte[2] ^ tx_scramb_byte[1];
						tx_scramb_byte[2] <= tx_scramb_byte[1] ^ tx_scramb_byte[0];
						tx_scramb_byte[1] <= tx_scramb_byte[0] ^ (tx_scramb_byte[6] ^ tx_scramb_byte[5]);
						tx_scramb_byte[0] <= tx_scramb_byte[6] ^ tx_scramb_byte[4];
					end
			end
	end

// 扰码输出。
always@(negedge rst_n or posedge sdh_clk)
	begin
		if(!rst_n)
		begin
			tx_int_scram_data <= 16'd0;
			start_of_frame_d1 <= 1'b0;
		end
		else
			begin
				if(tx_scramb_en)
					tx_int_scram_data <= tx_no_scramble_data ^ tx_scramb_byte;
				else
					tx_int_scram_data <= tx_no_scramble_data;
					
				start_of_frame_d1 <= start_of_frame;
			end
	end
	
reg   [1:0]     btye_cnt     ;
always@(negedge rst_n or posedge sdh_clk)
	begin
		if(!rst_n)
		begin
			sdh_gtx_fifo_data <= 32'd0;
			btye_cnt <= 2'd0;
			sdh_gtx_fifo_wen_p2 <= 1'b0;
			sdh_gtx_fifo_wen_p1 <= 1'b0;
			sdh_gtx_fifo_wen <= 1'b0;
		end
		else
			begin
				btye_cnt <= btye_cnt + 1'b1;
				
				if(btye_cnt == 2'd3)
				  sdh_gtx_fifo_wen_p2 <= 1'b1;
				else
				  sdh_gtx_fifo_wen_p2 <= 1'b0;
				  
				sdh_gtx_fifo_wen_p1 <= sdh_gtx_fifo_wen_p2  ;
				sdh_gtx_fifo_wen    <= sdh_gtx_fifo_wen_p1  ;
					
				sdh_gtx_fifo_data <= {sdh_gtx_fifo_data[23:0], tx_int_scram_data};
			end
	end
	
 endmodule
