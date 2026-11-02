`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.11.2026 19:15:43
// Design Name: 
// Module Name: tb_top
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


module tb_top;
    // Define testbench ports
    reg clk = 0;
    reg rstn;
    reg wr;
    reg s_wait = 0;
    reg newd;
    reg [3:0] ain;
    reg [7:0] din;
    wire [7:0] dout;
    reg [1:0] delay = 0;

always #10 clk = ~clk;
    // Instantiate the top module
    top dut (
        .clk(clk),
        .rstn(rstn),
        .wr(wr),
        .newd(newd),
        .ain(ain),
        .din(din),
        .dout(dout),
        .s_wait(s_wait)
    );
    
    initial 
    begin
    rstn = 1'b0;
    repeat(5) @(posedge clk);
    rstn = 1'b1;
    
        for (int i = 0; i< 5; i++)
        begin
        newd = 1;
        s_wait = 1;
        wr = 1;
        ain = $urandom_range(0,4);
        din = $urandom_range(100,250);
        delay = $urandom_range(0,3);
        repeat(delay)@(posedge clk);
        s_wait = 0;
        @(posedge clk);
        @(negedge dut.m1.pready);
        @(posedge clk);
        end
        
        
        for (int i = 0; i< 5; i++)
        begin
        newd = 1;
        s_wait = 1;
        wr = 0;
        ain = $urandom_range(0,4);
        din = $urandom_range(100,250);
        delay = $urandom_range(0,3);
        repeat(delay)@(posedge clk);
        s_wait = 0;
        @(posedge clk);
        @(negedge dut.m1.pready);
        @(posedge clk);
        end        
        
        
        
    $stop;
    end

endmodule  
