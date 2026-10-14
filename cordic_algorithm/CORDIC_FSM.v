`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.09.2026 18:45:32
// Design Name: 
// Module Name: CORDIC_FSM
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



module CORDIC_FSM #(
    parameter WIDTH = 16,
    parameter ITER  = 16
)(
    input  wire                   clock,
    input  wire                   reset,
    input  wire                   start,
    input  wire [15:0]            angle,

    output wire signed [15:0]     cosine,
    output wire signed [15:0]     sine,
    output reg                    done
);

    //========================================================
    // FSM STATES
    //========================================================

    localparam IDLE   = 2'b00;
    localparam SETUP  = 2'b01;
    localparam ROTATE = 2'b10;
    localparam DONE   = 2'b11;

    reg [1:0] state;
    reg [1:0] next_state;

    //========================================================
    // CORDIC INTERNAL REGISTERS
    //========================================================

    // Q1.17 format
    reg signed [17:0] x;
    reg signed [17:0] y;

    // Binary angle format
    reg signed [16:0] z;

    reg signed [17:0] x_shift;
    reg signed [17:0] y_shift;

    reg signed [17:0] x_next;
    reg signed [17:0] y_next;

    reg signed [16:0] z_next;

    reg [4:0] iteration;

    reg [1:0] quadrant;

    //========================================================
    // CORDIC GAIN COMPENSATION
    //
    // K = 1 / 1.646760258
    // K = 0.607252935
    //
    // Q1.17:
    // 0.607252935 * 131072 = 79594
    //========================================================

    localparam signed [17:0] K = 18'sd79594;

    //========================================================
    // ATAN TABLE
    //
    // Binary angle representation:
    //
    // 360 degrees = 65536
    // 180 degrees = 32768
    //  90 degrees = 16384
    //  45 degrees = 8192
    //========================================================

    reg signed [16:0] atan_table [0:15];

    initial begin

        atan_table[0]  = 17'sd8192;
        atan_table[1]  = 17'sd4836;
        atan_table[2]  = 17'sd2555;
        atan_table[3]  = 17'sd1297;
        atan_table[4]  = 17'sd648;
        atan_table[5]  = 17'sd324;
        atan_table[6]  = 17'sd162;
        atan_table[7]  = 17'sd81;
        atan_table[8]  = 17'sd41;
        atan_table[9]  = 17'sd20;
        atan_table[10] = 17'sd10;
        atan_table[11] = 17'sd5;
        atan_table[12] = 17'sd3;
        atan_table[13] = 17'sd1;
        atan_table[14] = 17'sd1;
        atan_table[15] = 17'sd0;

    end

    //========================================================
    // OUTPUT REGISTERS
    //========================================================

    reg signed [15:0] cosine_reg;
    reg signed [15:0] sine_reg;

    assign cosine = cosine_reg;
    assign sine   = sine_reg;

    //========================================================
    // STATE REGISTER
    //========================================================

    always @(posedge clock or posedge reset) begin

        if (reset)
            state <= IDLE;
        else
            state <= next_state;

    end

    //========================================================
    // NEXT STATE LOGIC
    //========================================================

    always @(*) begin

        case (state)

            IDLE: begin

                if (start)
                    next_state = SETUP;
                else
                    next_state = IDLE;

            end

            SETUP: begin

                next_state = ROTATE;

            end

            ROTATE: begin

                if (iteration == ITER-1)
                    next_state = DONE;
                else
                    next_state = ROTATE;

            end

            DONE: begin

                next_state = IDLE;

            end

            default: begin

                next_state = IDLE;

            end

        endcase

    end

    //========================================================
    // MAIN SEQUENTIAL LOGIC
    //========================================================

    always @(posedge clock or posedge reset) begin

        if (reset) begin

            x           <= 18'sd0;
            y           <= 18'sd0;
            z           <= 17'sd0;

            x_shift     <= 18'sd0;
            y_shift     <= 18'sd0;

            x_next      <= 18'sd0;
            y_next      <= 18'sd0;

            z_next      <= 17'sd0;

            iteration   <= 5'd0;
            quadrant    <= 2'b00;

            cosine_reg  <= 16'sd0;
            sine_reg    <= 16'sd0;

            done        <= 1'b0;

        end

        else begin

            // Default
            done <= 1'b0;

            case (state)

                //================================================
                // IDLE
                //================================================

                IDLE: begin

                    done <= 1'b0;

                end


                //================================================
                // SETUP
                //================================================

                SETUP: begin

                    // Store quadrant
                    quadrant <= angle[15:14];

                    // Start with X = K
                    x <= K;

                    // Y = 0
                    y <= 18'sd0;

                    //================================================
                    // Quadrant reduction
                    //
                    // Q0: angle - 0°
                    // Q1: angle - 90°
                    // Q2: angle - 180°
                    // Q3: angle - 270°
                    //================================================

                    case (angle[15:14])

                        2'b00: begin

                            z <= $signed({1'b0, angle});

                        end

                        2'b01: begin

                            z <= $signed({1'b0, angle})
                                 - 17'sd16384;

                        end

                        2'b10: begin

                            z <= $signed({1'b0, angle})
                                 - 17'sd32768;

                        end

                        2'b11: begin

                            z <= $signed({1'b0, angle})
                                 - 17'sd49152;

                        end

                    endcase

                    // Start iteration count
                    iteration <= 5'd0;

                end


                //================================================
                // ROTATION
                //================================================

                ROTATE: begin

                    // Arithmetic right shift
                    x_shift = x >>> iteration;
                    y_shift = y >>> iteration;

                    //================================================
                    // CORDIC rotation
                    //================================================

                    if (z >= 0) begin

                        x_next = x - y_shift;
                        y_next = y + x_shift;
                        z_next = z - atan_table[iteration];

                    end

                    else begin

                        x_next = x + y_shift;
                        y_next = y - x_shift;
                        z_next = z + atan_table[iteration];

                    end

                    // Update registers
                    x <= x_next;
                    y <= y_next;
                    z <= z_next;

                    // Next iteration
                    iteration <= iteration + 1'b1;

                end


                //================================================
                // DONE
                //================================================

                DONE: begin

                    //================================================
                    // Convert Q1.17 ? Q1.15
                    //
                    // Divide by 4
                    //================================================

                    case (quadrant)

                        //============================================
                        // Q0
                        // 0° ? 90°
                        //============================================

                        2'b00: begin

                            cosine_reg <= x >>> 2;
                            sine_reg   <= y >>> 2;

                        end


                        //============================================
                        // Q1
                        // 90° ? 180°
                        //
                        // cos = -sin(alpha)
                        // sin =  cos(alpha)
                        //============================================

                        2'b01: begin

                            cosine_reg <= -(y >>> 2);
                            sine_reg   <=  (x >>> 2);

                        end


                        //============================================
                        // Q2
                        // 180° ? 270°
                        //
                        // cos = -cos(alpha)
                        // sin = -sin(alpha)
                        //============================================

                        2'b10: begin

                            cosine_reg <= -(x >>> 2);
                            sine_reg   <= -(y >>> 2);

                        end


                        //============================================
                        // Q3
                        // 270° ? 360°
                        //
                        // cos =  sin(alpha)
                        // sin = -cos(alpha)
                        //============================================

                        2'b11: begin

                            cosine_reg <=  (y >>> 2);
                            sine_reg   <= -(x >>> 2);

                        end

                    endcase

                    // Signal completion
                    done <= 1'b1;

                end

            endcase

        end

    end

endmodule