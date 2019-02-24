`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/26/2018 03:45:32 PM
// Design Name: 
// Module Name: ps2_ctrl
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


module ps2_ctrl(
    PS2Clk, PS2Data, 
    o_data, o_dataCnt

    );
    
    input PS2Clk, PS2Data;
    output[7:0] o_data; 
    output[7:0] o_dataCnt;
    
    reg [32:0] r_data = 33'b0;
    reg [7:0] r_dataCnt = 8'b0;
    
    
    always @ (negedge PS2Clk)
        begin
            if(r_dataCnt == 32)
                begin
                    r_dataCnt <= 0;
                end
            else
                begin
                    r_data[r_dataCnt] <= PS2Data;
                    r_dataCnt <= r_dataCnt + 1;
                end
        end
    
    assign o_data[7:0] = r_data[8:1];
    assign o_dataCnt = r_dataCnt;
endmodule
