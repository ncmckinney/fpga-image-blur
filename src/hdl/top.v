`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/05/2018 05:20:36 PM
// Design Name: 
// Module Name: top
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


module top(
    i_clk, PS2_CLK, PS2_DATA, 
    VGA_HS, VGA_VS, VGA_R, VGA_B, VGA_G

   );

    input i_clk, PS2_CLK, PS2_DATA;
    output VGA_HS, VGA_VS;
    output [3:0] VGA_R, VGA_B, VGA_G;
    
    //vga display x & y position 
    wire [9:0] w_x;
    wire [8:0] w_y;
    
    //keyboard inputs
    wire [7:0] w_keyData, w_keyDataCnt;

   //image data out
    wire [3:0]   w_dOutPortARamOne;
    wire [3:0]   w_dOutPortBRamOne; 
    
    wire [3:0]   w_dOutPortARamTwo;
    wire [3:0]   w_dOutPortBRamTwo; 
    
    //25MHz VGA clk, vga display status, keyboard commands
    wire w_pixClk, w_line; 
    wire [1:0] w_keyPress;
    wire [3:0] w_blanking;
   
    //filter image stoage  
    reg [7:0] r_sum; 
    reg [3:0] r_filtPicData = 4'b0000;
   
   //state machine and ram memory index
    reg [4:0] r_blurFSM = 5'h0;
    reg [15:0] r_pixelIndex = 16'h0;
  
    //Filter weights
    reg [5:0] r_pixelArrayUL = 6'h0;
    reg [5:0] r_pixelArrayUC = 6'h0;
    reg [5:0] r_pixelArrayUR = 6'h0;
    reg [5:0] r_pixelArrayL = 6'h0;
    reg [5:0] r_pixelArrayC = 6'h0;
    reg [5:0] r_pixelArrayR = 6'h0;
    reg [5:0] r_pixelArrayLL = 6'h0;
    reg [5:0] r_pixelArrayLC = 6'h0;
    reg [5:0] r_pixelArrayLR = 6'h0;
    
    //ram write enable
    reg  r_writeEnableRamTwoA = 1'b0;
    reg  r_writeEnableRamTwoB = 1'b0;
    reg  r_writeEnableRamOneA = 1'b0;
    reg  r_writeEnableRamOneB = 1'b0;

   //ram addressing
    reg [15:0]  r_addrARamOne = 16'h0;
    reg [15:0]  r_addrBRamOne = 16'h0;
    
    reg [15:0]  r_addrARamTwo = 16'h0;
    reg [15:0]  r_addrBRamTwo = 16'h0;
    
    //ram data in
    reg [3:0]   r_dataInARamOne = 4'h0;
    reg [3:0]   r_dataInBRamOne = 4'h0; 
    
    reg [3:0]   r_dataInARamTwo = 4'h0;
    reg [3:0]   r_dataInBRamTwo = 4'h0; 
   
    blk_mem_pic imageRamOne(
        .clka(i_clk),               //in: clock
        .clkb(i_clk),
        .addra(r_addrARamOne),      //in: address
        .addrb(r_addrBRamOne),
        .dina(r_dataInARamOne),
        .dinb(r_dataInBRamOne),
        .wea(r_writeEnableRamOneA),  //in: write enable
        .web(r_writeEnableRamOneB),
        .douta(w_dOutPortARamOne),  //out: image data
        .doutb(w_dOutPortBRamOne)
    );
    
    blk_mem_pic imageRamTwo(
       .clka(i_clk),                //in: clock
       .clkb(i_clk),
       .addra(r_addrARamTwo),       //in: address
       .addrb(r_addrBRamTwo),
       .dina(r_dataInARamTwo),
       .dinb(r_dataInBRamTwo),
       .wea(r_writeEnableRamTwoA),   //in: write enable
       .web(r_writeEnableRamTwoB),
       .douta(w_dOutPortARamTwo),   //out: image data
       .doutb(w_dOutPortBRamTwo)
    );
    
   ps2_ctrl keyboard(
       .PS2Clk(PS2_CLK),        //in: PS2 clk
       .PS2Data(PS2_DATA),      //in: PS2 data
       .o_data(w_keyData),      //out: ASCII from keyboard
       .o_dataCnt(w_keyDataCnt) //out: keyboard bit counter
   );
   
   sync_gen vgaCtrl(
       .i_clk(i_clk),           //in: clock
       .o_hsync(VGA_HS),        //out: H sync
       .o_vsync(VGA_VS),        //out: V sync
       .o_blanking(w_blanking), //out: high when in no display region
       .o_x(w_x),               //out: display x position
       .o_y(w_y),               //out: display y position
       .o_line(w_line)          //out: high when new row starts
          );
   
   ascii_convert keyData(
        .i_clk(i_clk),                  //in: clock
        .i_keyData(w_keyData),          //in: keyboard ascii data
        .i_keyDataCnt(w_keyDataCnt),    //in: keyboard bit counter from ps2 module        
        .o_keyAddr(w_keyPress)          //out: keyboard commands 2 bit wide
   );

    always @ (posedge i_clk) begin
        r_addrARamOne <= {{w_x[7:0]},{w_y[7:0]}};
    end
    
    always @ (posedge i_clk)    begin
        case (r_blurFSM) 
        //Waits for 0 key to be pressed. 
        5'h0:   if (w_keyPress == 2'b01)    begin
                    r_blurFSM <= 5'h1;  end
                    
        //States 1 thru 18 stores pixel and neighboring pixel values. r_pixelIndex increments from 0 to 0xFFFF        
        5'h1:   begin   r_addrBRamOne <= r_pixelIndex - 16'hFE;
                r_blurFSM <= 5'h2;  end
                
        5'h2:   begin   r_pixelArrayUL <= w_dOutPortBRamOne;
                r_blurFSM <= 5'h3;  end
                
        5'h3:   begin   r_addrBRamOne <= r_pixelIndex - 16'hFF;
                r_blurFSM <= 5'h4;  end
                          
        5'h4:   begin   r_pixelArrayUC <= w_dOutPortBRamOne;
                r_blurFSM <= 5'h5;  end
          
        5'h5:   begin   r_addrBRamOne <= r_pixelIndex - 16'h100;
                r_blurFSM <= 5'h6;  end
                        
        5'h6:   begin   r_pixelArrayUR <= w_dOutPortBRamOne;
                r_blurFSM <= 5'h7;  end 
                
        5'h7:   begin   r_addrBRamOne <= r_pixelIndex - 16'h1;
                r_blurFSM <= 5'h8;  end
                                    
        5'h8:   begin   r_pixelArrayL <= w_dOutPortBRamOne;
                r_blurFSM <= 5'h9;  end 
                
        5'h9:   begin   r_addrBRamOne <= r_pixelIndex;
                r_blurFSM <= 5'hA;  end
                                 
        5'hA:   begin   r_pixelArrayC <= w_dOutPortBRamOne;
                r_blurFSM <= 5'hB;  end
                
        5'hB:   begin   r_addrBRamOne <= r_pixelIndex + 16'h1;
                r_blurFSM <= 5'hC;  end
                                 
        5'hC:   begin   r_pixelArrayR <= w_dOutPortBRamOne;
                r_blurFSM <= 5'hD;  end
                
        5'hD:   begin   r_addrBRamOne <= r_pixelIndex + 16'hFE;
                r_blurFSM <= 5'hE;  end
                                 
        5'hE:   begin   r_pixelArrayLL <= w_dOutPortBRamOne;
                r_blurFSM <= 5'hF;  end
                
        5'hF:   begin   r_addrBRamOne <= r_pixelIndex + 16'hFF;
                r_blurFSM <= 5'h10;  end
                                 
        5'h10:   begin   r_pixelArrayLC <= w_dOutPortBRamOne;
                r_blurFSM <= 5'h11;  end
                
        5'h11:   begin   r_addrBRamOne <= r_pixelIndex + 16'h100;
                r_blurFSM <= 5'h12;  end
                                 
        5'h12:   begin   r_pixelArrayLR <= w_dOutPortBRamOne;
                r_blurFSM <= 5'h18;  end
        
        //zero padding when addressing of circular buffer wraps around        
        5'h18:  begin  
                    if(r_pixelIndex[7:0] == 8'h0) begin
                        r_pixelArrayUL <= 16'h0;
                        r_pixelArrayL <= 16'h0;
                        r_pixelArrayLL <= 16'h0;     end
                    
                    if(r_pixelIndex[7:0] == 8'hFF) begin
                        r_pixelArrayUR <= 16'h0;
                        r_pixelArrayR <= 16'h0;
                        r_pixelArrayLR <= 16'h0;    end
                    
                    if(r_pixelIndex[15:8] == 8'h0) begin
                        r_pixelArrayUR <= 16'h0;
                        r_pixelArrayUC <= 16'h0;
                        r_pixelArrayUL <= 16'h0;    end 
                        
                    if(r_pixelIndex[15:8] == 8'hFF) begin
                        r_pixelArrayLR <= 16'h0;
                        r_pixelArrayLC <= 16'h0;
                        r_pixelArrayLL <= 16'h0; end  
                        
                     r_blurFSM <= 5'h13;
                end  
                
        //Apply filter kernel and sum        
        5'h13:  begin   
                r_sum <= r_pixelArrayUL + 2*r_pixelArrayUC + r_pixelArrayUR + 
                        2*r_pixelArrayL + 4*r_pixelArrayC + 2*r_pixelArrayR + 
                        r_pixelArrayLL + 2*r_pixelArrayLC + r_pixelArrayLR; 
                r_blurFSM <= 5'h14; end
                
        //Divde by 16 to average        
        5'h14:  begin   r_filtPicData <= r_sum >> 4;
                r_blurFSM <= 5'h15; 
                r_writeEnableRamTwoB <= 1'b1;
                r_addrBRamTwo <= r_pixelIndex; end
                
        //Store new pixel in old pixel location        
        5'h15:  begin   
                r_dataInBRamTwo <= r_filtPicData;
                r_writeEnableRamTwoB <= 1'b0;
                r_blurFSM <= 5'h16; end
                
        //Repeat for all pixels in 256x256 image. Once done pauses display image output        
        5'h16:  begin   if (r_pixelIndex < 16'hFFFF) begin
                            r_blurFSM <= 5'h1;   end
                        
                        else    begin
                            r_writeEnableRamOneB <= 1'b1;
                            r_blurFSM <= 5'h17;
                        end
                end
        //Copy image data from RAM2 to RAM 1
        5'h17:  begin    
                r_addrBRamOne <= r_pixelIndex;
                r_addrARamTwo <= r_pixelIndex;
                r_dataInBRamOne <= w_dOutPortARamTwo;
                if (r_pixelIndex < 16'hFFFF)    begin
                      r_blurFSM <= 5'h17;
                      end
                      
                else    begin
                    r_writeEnableRamOneB <= 1'b0;
                    r_blurFSM <= 5'h0;
                    end
                    
                end
                
        default:    r_blurFSM <= 5'h0;    
        
        endcase
    end   
    
    //steps through memory, contents stored at counter address stored or transferred during FSM operation
    always @(posedge i_clk)    begin
        if(r_blurFSM == 5'h16 || r_blurFSM == 5'h17)
                r_pixelIndex <= r_pixelIndex + 16'h1;
        else
                r_pixelIndex <= r_pixelIndex;
    end
        
    assign VGA_R [3:0] = w_dOutPortARamOne & ~w_blanking;
    assign VGA_B [3:0] = w_dOutPortARamOne & ~w_blanking;
    assign VGA_G [3:0] = w_dOutPortARamOne & ~w_blanking;

endmodule