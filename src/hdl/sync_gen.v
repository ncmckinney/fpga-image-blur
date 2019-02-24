`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/12/2018 04:38:46 PM
// Design Name: 
// Module Name: sync_gen
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//
// 31.77us 	Scanline time
//  3.77us 	Sync pulse lenght
//  1.89us 	Back porch
// 25.17us 	Display time
//  0.94us 	Front porch
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sync_gen(
    i_clk,
    o_hsync, o_vsync, o_blanking, o_line, o_x, o_y
    );
    
    input i_clk;
    output o_hsync, o_vsync, o_line;
    output [3:0] o_blanking;
    output [9:0] o_x;
    output [8:0] o_y;
    
// 640 x 480 4:3 aspect ratio 
    parameter c_VdisplayLength  = 480;  // No. of display lines/rows v display last
    parameter c_VpulseWidth     = 2;    // No. of display lines/rows v sync goes low for retrace
    parameter c_VfrontPorch     = 10;
    parameter c_VbackPorch      = 33;    
    parameter c_VsyncEnd        = c_VfrontPorch + c_VpulseWidth;
    parameter c_VdisplayStart   = c_VsyncEnd + c_VbackPorch;
    
    parameter c_HdisplayLength  = 640;
    parameter c_HpulseWidth     = 96;
    parameter c_HfrontPorch     = 16;
    parameter c_HbackPorch      = 48;
    parameter c_HsyncEnd        = c_HfrontPorch + c_HpulseWidth;
    parameter c_HdisplayStart   = c_HsyncEnd + c_HbackPorch;
    
    parameter c_HlineEnd        = c_HdisplayLength + c_HpulseWidth + c_HfrontPorch + c_HbackPorch;  // No. of clock ticks for H sync duration
    parameter c_Vend            = c_VdisplayLength + c_VpulseWidth + c_VfrontPorch + c_VbackPorch;  // No. of display lines/rows v sync last 
      
    reg [9:0] r_Hcnt = 10'b0;
    reg [8:0] r_Vcnt = 9'b0;
    reg r_line = 1'b0;
//    reg r_screenRefresh = 1'b0;
    
    wire w_pixClk;
    
    clk_div pixClk(
        .i_clk(i_clk),
        .o_clkSlow(w_pixClk)
    );
        
    always @(posedge i_clk)
        begin
        r_line <= 1'b0; //Keeps track of when a new line or row begins
            /*  Col and Row counters. Goes to next row after walking through each pixel in prev row */
            if (w_pixClk)
                begin
//                    r_screenRefresh <= 1'b0;
                    if(r_Hcnt == c_HlineEnd - 1'b1)
                        begin
                            r_Hcnt <= 10'b0;            //col set to zero
                            r_Vcnt <= r_Vcnt + 1'b1;    // increment row
                            r_line <= 1'b1;             // Start of new row/line
                        end
                    else
                        r_Hcnt <= r_Hcnt + 1'b1;        //increment col until we hit edge of screen
                    
                    if(r_Vcnt == c_Vend)
                        begin
//                            r_Hcnt <= 10'b0;                //reset col after hitting bottom of screen
                            r_Vcnt <= 9'b0;                //reset row after hitting bottom of screen
//                            r_screenRefresh <= 1'b1;
                        end
                end
        end
        
    assign o_x = (r_Hcnt < c_HdisplayStart) ? 10'b0 : (r_Hcnt - c_HdisplayStart);               // x from 0 to 639
    assign o_y = (r_Vcnt < c_VdisplayStart) ? 9'b0 : (r_Vcnt - c_VdisplayStart);
//    assign o_y = (r_Vcnt >= c_VdisplayLength) ? (c_VdisplayLength - 1) : (r_Vcnt);              // y from 0 to 479
    assign o_hsync = ~((r_Hcnt >= c_HfrontPorch) & (r_Hcnt < c_HsyncEnd));            //Pulls sync low in between front and back porch                                                        
    assign o_vsync = ~((r_Vcnt >= c_VfrontPorch) & (r_Vcnt < c_VsyncEnd));
    assign o_blanking = ((r_Hcnt < c_HdisplayStart) | (r_Vcnt < c_VdisplayStart) | (r_Hcnt - c_HdisplayStart > 8'hFF) | (r_Vcnt - c_VdisplayStart > 8'hFF)) ? 4'b1111 : 4'b0000;
//    assign o_blanking = ~o_hsync & ~o_vsync;
//    assign o_blanking = ((r_Hcnt < c_HdisplayStart) | (r_Vcnt > c_VdisplayLength));  //blank flag goes high when outside display region
    assign o_line = r_line;                                                          //goes high when next line starts   
//    assign o_screenRefresh = r_screenRefresh;
endmodule