`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.11.2026 18:57:41
// Design Name: 
// Module Name: apb_m
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


module apb_m
  (
    input pclk,
    input presetn,
    input [3:0] addrin,
    input [7:0] datain,
    input wr,
    input newd,
    input [7:0] prdata,
    input pready,
    
    output reg psel,
    output reg penable,
    output reg [3:0] paddr,
    output reg [7:0] pwdata,
    output reg pwrite,
    output reg [7:0] dataout
    
  
  );
  
  localparam [1:0] idle = 0, setup = 1, enable = 2;
  
  
  reg [1:0] state, nstate;
  
  //////reset decoder
  
  always@(posedge pclk)
    begin
      if(presetn == 1'b0)
          state <= idle;
      else
          state <= nstate;
    end
  
  //////state decoder
  
  always@(*)
    begin
      case(state)
        idle:
          begin
          if (newd == 1'b0)
             nstate = idle;
          else
             nstate = setup;
          end
        
        setup:
          begin
           nstate = enable; 
          end
        
        enable:
          begin
            if(newd == 1'b1 )
               begin
                 if(pready == 1'b1)
                    nstate = setup;
                 else
                    nstate = enable;
               end
           else
               begin
                 nstate = idle;
               end
            
          end
        
        default : nstate = idle; 
      endcase
      
    end

////////////////address decoding
always@(posedge pclk, negedge presetn)
    begin
        if(presetn == 1'b0)
            begin
              psel <= 1'b0;
            end
         else if (nstate == idle)
            begin
              psel <= 1'b0;
            end
         else if (nstate == enable || nstate == setup)
            begin
             psel <= 1'b1;
            end
         else 
            begin
             psel <= 1'b0;
            end     
    end
 
 
 /////////////// output logic
 always@(posedge pclk, negedge presetn)
     begin
        if(presetn == 1'b0)
          begin
          penable <= 1'b0;
          paddr   <= 4'h0;
          pwdata  <= 8'h00;
          pwrite  <= 1'b0;
          end
        else if (nstate == idle)
          begin
          penable <= 1'b0;
          paddr   <= 4'h0;
          pwdata  <= 8'h00;
          pwrite  <= 1'b0;
          end
        else if (nstate == setup)
          begin
            penable <= 1'b0;
            paddr   <= addrin;
            pwrite  <= wr;
            if(wr == 1'b1)
                begin
                pwdata <= datain;
                end
             end
        else if (nstate == enable)
            begin
                penable <= 1'b1;
            end
     end
 
 assign dataout = (psel == 1'b1 && penable == 1'b1 && wr == 1'b0) ? prdata : 8'h00;
 
endmodule

