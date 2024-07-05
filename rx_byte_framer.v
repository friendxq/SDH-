// 全并行帧搜索，帧头信号在J0后的1个字节位置出现

`timescale 1ns/1ps

// 连续多少帧丢失帧头时产生OOF告警，SDH规定为5帧
`define OOF_WARN_NUMBER  5'd5
// 连续多少帧找到帧头时取消OOF告警，SDH规定为2帧
`define OOF_DEL_NUMBER   5'd2
// 连续多少帧丢失帧头时产生LOF告警，SDH规定为24帧
`define LOF_WARN_NUMBER  5'd24
// 连续多少帧找到帧头时取消LOF告警，SDH规定为8帧
`define LOF_DEL_NUMBER   5'd8

module rx_byte_framer (
        	rst_n, 
        	sdh_clk, 
        	rx_data_i,
        
        	rx_rec_data_o, 
        	rx_1st_byte_valid,
        	b1_valid,
        	rx_descramb_en, 
        	rx_data_vld,
        
        	rx_stm_oof, 
        	rx_stm_lof
        );

	input 		      rst_n,  sdh_clk ;
	input    [7:0]	rx_data_i;
           
	output    		  rx_descramb_en;
	output   [7:0]  rx_rec_data_o;
	output          rx_1st_byte_valid;
	output          rx_data_vld;
  output          b1_valid ;
	output   		    rx_stm_oof, rx_stm_lof;
           
  
reg     [7:0]	  rx_rec_data_o;

// ----------------------------------------------------------
reg     [7:0]	  rx_data_d1;
reg 	   		    cont_2frm_ok_flag;
wire    [7:0]	  rbyte_0, rbyte_1, rbyte_2, rbyte_3;
wire    [7:0]	  rbyte_4, rbyte_5, rbyte_6, rbyte_7;
wire    		    r_f6_0, r_f6_1, r_f6_2, r_f6_3, r_f6_4, r_f6_5, r_f6_6, r_f6_7;
wire    		    r_28_0, r_28_1, r_28_2, r_28_3, r_28_4, r_28_5, r_28_6, r_28_7;
wire    		    r_f6_int;
reg	    		    r_f6, r_28, rsel_equ, r_byte_pos_int;
reg     [2:0]	  rsel_cur, rsel_last, rsel_end, actual_loc_code;
reg     [4:0]   cont_frm_fnd_cnt;	
reg     			  rsch_sta;
reg     [1:0]   alarm_sta;
reg     [3:0]	  rsch_cnt;
reg     [4:0]	  cont_frm_lost_cnt;
reg     [13:0]	framer_cnt;
reg			        framer_cnt_tc;
//------------- 内部信号定义 -------    
reg     [1:0]		stm_mu_cnt;
reg     [8:0]		stm_col; 	//SDH的列计数器
reg     [3:0]		stm_row; 	//SDH的行计数器


// 搜帧状态机
parameter 	SDH_SEARCH_A1	= 1'b0 ,
          	SDH_SEARCH_A2	= 1'b1 ;
 
// 告警状态机          	
parameter   SDH_ALARM_LOF  = 2'd0 ,
            SDH_ALARM_NORM = 2'd1 ,
            SDH_ALARM_OOF  = 2'd2 ;
         	
parameter   FRM_TOTAL_BYTE_NUM = 14'd9718 ;  //SDH一帧的字节数
parameter   RSCH_NUM           = 4'd11    ;  //分别是12个A1和A2,从0~11共12个

// 分成8组来搜索帧头
always@( negedge rst_n or posedge sdh_clk)
	begin
		if(!rst_n)
			rx_data_d1 <= 8'd0;
		else 
			rx_data_d1 <= rx_data_i;
	end

// 组成8组数据
assign rbyte_0 =   rx_data_d1;
assign rbyte_1 = { rx_data_d1[6:0], rx_data_i[7]};
assign rbyte_2 = { rx_data_d1[5:0], rx_data_i[7:6]};
assign rbyte_3 = { rx_data_d1[4:0], rx_data_i[7:5]};
assign rbyte_4 = { rx_data_d1[3:0], rx_data_i[7:4]};
assign rbyte_5 = { rx_data_d1[2:0], rx_data_i[7:3]};
assign rbyte_6 = { rx_data_d1[1:0], rx_data_i[7:2]};
assign rbyte_7 = { rx_data_d1[0],   rx_data_i[7:1]};

// 8组数据分别判断A1和A2字节
assign r_f6_0 = ( rbyte_0 == 8'hf6) ? 1'b1 : 1'b0;
assign r_f6_1 = ( rbyte_1 == 8'hf6) ? 1'b1 : 1'b0;
assign r_f6_2 = ( rbyte_2 == 8'hf6) ? 1'b1 : 1'b0;
assign r_f6_3 = ( rbyte_3 == 8'hf6) ? 1'b1 : 1'b0;
assign r_f6_4 = ( rbyte_4 == 8'hf6) ? 1'b1 : 1'b0;
assign r_f6_5 = ( rbyte_5 == 8'hf6) ? 1'b1 : 1'b0;
assign r_f6_6 = ( rbyte_6 == 8'hf6) ? 1'b1 : 1'b0;
assign r_f6_7 = ( rbyte_7 == 8'hf6) ? 1'b1 : 1'b0;

assign r_28_0 = ( rbyte_0 == 8'h28) ? 1'b1 : 1'b0;
assign r_28_1 = ( rbyte_1 == 8'h28) ? 1'b1 : 1'b0;
assign r_28_2 = ( rbyte_2 == 8'h28) ? 1'b1 : 1'b0;
assign r_28_3 = ( rbyte_3 == 8'h28) ? 1'b1 : 1'b0;
assign r_28_4 = ( rbyte_4 == 8'h28) ? 1'b1 : 1'b0;
assign r_28_5 = ( rbyte_5 == 8'h28) ? 1'b1 : 1'b0;
assign r_28_6 = ( rbyte_6 == 8'h28) ? 1'b1 : 1'b0;
assign r_28_7 = ( rbyte_7 == 8'h28) ? 1'b1 : 1'b0;

// 不管哪组数据，只要有A1字节出现，就认为是A1字节
assign r_f6_int = r_f6_0 | r_f6_1 | r_f6_2 | r_f6_3 |
			            r_f6_4 | r_f6_5 | r_f6_6 | r_f6_7;

// 对于找到的F6字节的位置进行编码存储
always@( negedge rst_n or posedge sdh_clk)
	begin
		if(!rst_n)
			begin
				rsel_cur <= 3'b0;
				rsel_last <= 3'b0;
			end
		else
			begin
				rsel_last <= rsel_cur;
				
				if(r_f6_int)
					begin
						rsel_cur[0] <= r_f6_1 | r_f6_3 | r_f6_5 | r_f6_7;
						rsel_cur[1] <= r_f6_2 | r_f6_3 | r_f6_6 | r_f6_7;
						rsel_cur[2] <= r_f6_4 | r_f6_5 | r_f6_6 | r_f6_7;
					end
			end
	end

// 用A1字节出现的数据组编码来选择A2字节的数据组
always@( negedge rst_n or posedge sdh_clk )
	begin
		if(!rst_n)
			begin
				r_28 <= 1'b0;
				r_f6 <= 1'b0;
			end
		else
			begin
				r_f6 <= r_f6_int;
				case(rsel_cur)
					3'b000 : r_28  <= r_28_0;
					3'b001 : r_28  <= r_28_1;
					3'b010 : r_28  <= r_28_2;
					3'b011 : r_28  <= r_28_3;
					3'b100 : r_28  <= r_28_4;
					3'b101 : r_28  <= r_28_5;
					3'b110 : r_28  <= r_28_6;
					3'b111 : r_28  <= r_28_7;
					default: r_28  <= r_28_0;
				endcase
			end
	end

// 判断前后两次A1字节出现的数据组数是否相同
always@(*)
	begin
		if( rsel_cur == rsel_last )
			rsel_equ = 1'b1;
		else
			rsel_equ = 1'b0;
	end



// SDH帧搜索状态机
always@( negedge rst_n or posedge sdh_clk)
	begin
		if(!rst_n)
			rsch_sta <= SDH_SEARCH_A1;
		else
			case(rsch_sta)
				SDH_SEARCH_A1 :
					if(r_f6)
						begin
							if(rsel_equ)
								begin
									if(rsch_cnt == RSCH_NUM)
										rsch_sta <= SDH_SEARCH_A2;
								end
						end
						
				SDH_SEARCH_A2 :
					if(r_28)
						begin
							if(rsch_cnt == RSCH_NUM )
								rsch_sta <= SDH_SEARCH_A1;
						end
					else if((rsch_cnt == 4'd0) && r_f6 && rsel_equ)
					  rsch_sta <= SDH_SEARCH_A2;
					else
						rsch_sta <= SDH_SEARCH_A1;
						
				default : rsch_sta <= SDH_SEARCH_A1;
			endcase
	end

always@( negedge rst_n or posedge sdh_clk)
	begin
		if(!rst_n)
			rsch_cnt <= 4'd0;
		else 
			case(rsch_sta)
				SDH_SEARCH_A1 :
					if(r_f6)
						begin
							if(rsel_equ)
								begin
									if(rsch_cnt == RSCH_NUM)
									  rsch_cnt <= 4'd0;
									else
										rsch_cnt <= rsch_cnt + 1'b1;
								end
							else
								rsch_cnt <= 4'd1;
						end
					else
						rsch_cnt <= 4'd0;
						
				SDH_SEARCH_A2 :
					if(r_28)
						begin
							if(rsch_cnt == RSCH_NUM )
								rsch_cnt <= 4'd0;
							else
								rsch_cnt <= rsch_cnt + 1'b1;
						end
					else
						begin
							if(r_f6 && (rsch_cnt!=4'd0))
								rsch_cnt <= 4'd1;
							else
								rsch_cnt <= 4'd0;
						end
				default : rsch_cnt <= 4'd0;
			endcase
	end

// 产生内部使用的帧头：这个位置在数据的J0字节处
always@( negedge rst_n or posedge sdh_clk)
	begin
		if(!rst_n)
			r_byte_pos_int <= 1'b0;
		else 
			begin
				if( (rsch_sta == SDH_SEARCH_A2) && r_28 && (rsch_cnt == RSCH_NUM ) )
					r_byte_pos_int <= 1'b1;
				else
					r_byte_pos_int <= 1'b0;
			end
	end

// SDH帧搜索状态机，产生帧头，同时产生由帧头锁住的数据组选择信号
always@( negedge rst_n or posedge sdh_clk)
	begin
		if(!rst_n)
			rsel_end <= 3'b0;
		else 
			begin
				if( (rsch_sta == SDH_SEARCH_A2) && r_28 && (rsch_cnt == RSCH_NUM ) )
					rsel_end <= rsel_cur;
			end
	end



// 帧头检测计数器
always@( negedge rst_n or posedge sdh_clk)
	begin
		if(!rst_n)
			begin
				framer_cnt <= 12'd0;
				framer_cnt_tc <= 1'b0;
			end
		else 
			begin
				if(r_byte_pos_int)
					begin
						framer_cnt <= 14'd0;
						framer_cnt_tc <= 1'b0;
					end
				else
					begin
						if(framer_cnt == FRM_TOTAL_BYTE_NUM)
							framer_cnt_tc <= 1'b1;
						else
							framer_cnt_tc <= 1'b0;

						if(framer_cnt_tc)
							framer_cnt <= 14'd0;
						else
							framer_cnt <= framer_cnt + 1'b1;
					end
			end
	end

// 连续帧头位置正确的计数器
always@(negedge rst_n or posedge sdh_clk)
	begin
		if(!rst_n)
			cont_frm_fnd_cnt <= 5'd0;	
		else 
			begin
				if(r_byte_pos_int)
					begin
						if(cont_frm_fnd_cnt < 5'd31)	
							cont_frm_fnd_cnt <= cont_frm_fnd_cnt + 1'b1;
					end
				else if(framer_cnt_tc)
					cont_frm_fnd_cnt <= 5'd0;	
			end
	end

// 首次连续两帧的位置正确，输出指示信号标记，在帧的J0字节的下一拍
always@(negedge rst_n or posedge sdh_clk)
	begin
		if(!rst_n)
			cont_2frm_ok_flag <= 1'b0;
		else
			begin
				if(r_byte_pos_int && framer_cnt_tc && (cont_frm_fnd_cnt==5'd1))
					cont_2frm_ok_flag <= 1'b1;
				else
					cont_2frm_ok_flag <= 1'b0;
			end
	end

// 锁定位置编码，此位置编码不受假帧头的影响
always@(negedge rst_n or posedge sdh_clk)
	begin
		if(!rst_n)
			actual_loc_code <= 3'b0;
		else 
			begin
				if(cont_2frm_ok_flag)
					actual_loc_code <= rsel_end;
			end
	end

// 根据选择信号选择哪组数据输出
always@( negedge rst_n or posedge sdh_clk)
	begin
		if(!rst_n)
			rx_rec_data_o <= 8'd0;
		else 
			begin
				case(actual_loc_code)
					3'b000 :  rx_rec_data_o <= rbyte_0;
					3'b001 :  rx_rec_data_o <= rbyte_1;
					3'b010 :  rx_rec_data_o <= rbyte_2;
					3'b011 :  rx_rec_data_o <= rbyte_3;
					3'b100 :  rx_rec_data_o <= rbyte_4;
					3'b101 :  rx_rec_data_o <= rbyte_5;
					3'b110 :  rx_rec_data_o <= rbyte_6;
					3'b111 :  rx_rec_data_o <= rbyte_7;
					default : rx_rec_data_o <= rbyte_0;
				endcase
			end
	end

// ===================================  产生OOF和LOF部分  ======================================


// 连续帧头错误的次数统计
always@(negedge rst_n or posedge sdh_clk)
	begin
		if(!rst_n)
			cont_frm_lost_cnt <= 5'd0;
		else 
			begin
				if(r_byte_pos_int && framer_cnt_tc)
					cont_frm_lost_cnt <= 5'd0;
				else if(framer_cnt_tc)
					begin
						if(cont_frm_lost_cnt < 5'd31)
							cont_frm_lost_cnt <= cont_frm_lost_cnt + 1'b1;
					end
			end
	end

	
	
	// SDH告警状态机
always@( negedge rst_n or posedge sdh_clk)
	begin
		if(!rst_n)
			alarm_sta <= SDH_ALARM_LOF;
		else
			case(alarm_sta)
				SDH_ALARM_LOF :
				begin
					if (cont_frm_fnd_cnt >= `LOF_DEL_NUMBER) 
					  alarm_sta <= SDH_ALARM_NORM;
				end
						
				SDH_ALARM_NORM :
				begin
					if (cont_frm_lost_cnt >= `OOF_WARN_NUMBER)
					  alarm_sta <= SDH_ALARM_OOF;
				end
						
				SDH_ALARM_OOF:
				begin
					if (cont_frm_fnd_cnt >= `OOF_DEL_NUMBER)
					  alarm_sta <= SDH_ALARM_NORM;
					else if (cont_frm_lost_cnt >= `LOF_WARN_NUMBER)
					  alarm_sta <= SDH_ALARM_LOF;
				end
						
				default : alarm_sta <= SDH_ALARM_LOF;
			endcase
	end
	
	assign  rx_stm_oof  =  (alarm_sta != SDH_ALARM_NORM)?   1'b1 : 1'b0 ;
	assign	rx_stm_lof  =  (alarm_sta == SDH_ALARM_LOF)?    1'b1 : 1'b0 ;

//SDH复用单元的计数器
always@(negedge rst_n or posedge sdh_clk)
	begin
		if(!rst_n)
  	  stm_mu_cnt <= 2'b00;
    else
    begin
    	if(cont_2frm_ok_flag)
    	  stm_mu_cnt <= 2'd2;
    	else
	      stm_mu_cnt <= stm_mu_cnt + 1'b1;
	  end
  end		

	
//SDH的列计数器
always@(negedge rst_n or posedge sdh_clk)
	begin
		if(!rst_n)
	    stm_col <= 9'd0;
    else
    begin
    	if(cont_2frm_ok_flag)
    	  stm_col <= 9'd6;
	    else if((stm_mu_cnt == 2'd3)&&(stm_col == 9'd269))
	      stm_col <= 9'd0;
	    else if(stm_mu_cnt == 3'd3)
	      stm_col <= stm_col + 1'b1;
    end
end		

//SDH的行计数器
always@(negedge rst_n or posedge sdh_clk)
	begin
		if(!rst_n)
	    stm_row <= 4'd0;
    else
    begin
    	if(cont_2frm_ok_flag)
    	  stm_row <= 4'd0;
	    else if ((stm_mu_cnt == 2'd3)&&(stm_col  == 9'd269)&&(stm_row == 4'd8))
	      stm_row <= 4'd0;
	    else if ((stm_mu_cnt == 2'd3)&&(stm_col  == 9'd269))
	      stm_row <= stm_row + 1'b1;
    end
end		

assign  rx_descramb_en    = ((stm_row==9'd0) && (stm_col<=9'd8))? 1'b0 : 1'b1;
assign  rx_data_vld       = (stm_col<=9'd8)? 1'b0 : 1'b1;
assign  rx_1st_byte_valid = ((stm_row==9'd0) && (stm_col==9'd0) && (stm_mu_cnt==2'd0))? 1'b1 : 1'b0;
assign  b1_valid          = ((stm_row==9'd1) && (stm_col==9'd0) && (stm_mu_cnt==2'd0))? 1'b1 : 1'b0;
endmodule
