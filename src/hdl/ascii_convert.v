`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/24/2018 01:05:15 PM
// Design Name: 
// Module Name: ascii_convert
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ascii_convert(
    i_clk, i_keyData, i_keyDataCnt,
    o_keyAddr
    
    );
    
    input i_clk;
    input [7:0] i_keyData, i_keyDataCnt;
    output [1:0] o_keyAddr;
    
    reg [7:0] r_key = 8'b0;
    reg [1:0] r_keyAddr = 2'b00;
    
    always @ (posedge i_clk)
        begin
            if(i_keyDataCnt == 32)
                begin
                    r_key <= i_keyData; 
                end
            else    begin
                r_key <= 8'h0;
//                r_key <= r_key;
                end
        end
    
    always @(*)
        begin
            case(r_key)
                8'h45: r_keyAddr = 2'b01;
//                8'h16: r_fontAddr = 7'b0001000;
//                8'h1E: r_fontAddr = 7'b0010000;
//                8'h26: r_fontAddr = 7'b0011000;
//                8'h25: r_fontAddr = 7'b0100000;
//                8'h2E: r_fontAddr = 7'b0101000;
//                8'h36: r_fontAddr = 7'b0110000;
//                8'h3D: r_fontAddr = 7'b0111000;
//                8'h3E: r_fontAddr = 7'b1000000;
//                8'h46: r_fontAddr = 7'b1001000;
                default: r_keyAddr = 2'b00;
            endcase
        end
    assign o_keyAddr = r_keyAddr;
endmodule
