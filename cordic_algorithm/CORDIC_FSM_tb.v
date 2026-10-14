`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.09.2026 18:47:10
// Design Name: 
// Module Name: CORDIC_FSM_tb
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


module CORDIC_FSM_tb;

    //========================================================
    // Signals
    //========================================================

    reg clock;
    reg reset;
    reg start;
    reg [15:0] angle;

    wire signed [15:0] cosine;
    wire signed [15:0] sine;
    wire done;

    //========================================================
    // DUT
    //========================================================

    CORDIC_FSM dut (

        .clock  (clock),
        .reset  (reset),
        .start  (start),
        .angle  (angle),

        .cosine (cosine),
        .sine   (sine),
        .done   (done)

    );

    //========================================================
    // CLOCK
    //========================================================

    initial begin

        clock = 0;

        forever #5 clock = ~clock;

    end

    //========================================================
    // VARIABLES
    //========================================================

    real angle_degrees;
    real angle_radians;

    real cos_value;
    real sin_value;

    integer expected_cos;
    integer expected_sin;

    integer cos_error;
    integer sin_error;

    integer abs_cos_error;
    integer abs_sin_error;

    integer total_tests;
    integer passed_tests;
    integer failed_tests;

    integer max_cos_error;
    integer max_sin_error;

    //========================================================
    // CALCULATE EXPECTED VALUE
    //========================================================

    task calculate_expected;

        input [15:0] angle_input;

        begin

            // Convert binary angle to degrees
            angle_degrees =
                    angle_input * 360.0 / 65536.0;

            // Degrees ? radians
            angle_radians =
                    angle_degrees *
                    3.141592653589793 / 180.0;

            // Reference sine/cosine
            cos_value = $cos(angle_radians);
            sin_value = $sin(angle_radians);

            // Convert to Q1.15
            expected_cos =
                    $rtoi(cos_value * 32768.0);

            expected_sin =
                    $rtoi(sin_value * 32768.0);

            // Saturation
            if (expected_cos > 32767)
                expected_cos = 32767;

            if (expected_cos < -32768)
                expected_cos = -32768;

            if (expected_sin > 32767)
                expected_sin = 32767;

            if (expected_sin < -32768)
                expected_sin = -32768;

        end

    endtask

    //========================================================
    // DISPLAY QUADRANT
    //========================================================

    task display_quadrant;

        input [15:0] angle_input;

        begin

            case (angle_input[15:14])

                2'b00:
                    $display(
                        "Quadrant      = Q0 (0 - 90 degrees)"
                    );

                2'b01:
                    $display(
                        "Quadrant      = Q1 (90 - 180 degrees)"
                    );

                2'b10:
                    $display(
                        "Quadrant      = Q2 (180 - 270 degrees)"
                    );

                2'b11:
                    $display(
                        "Quadrant      = Q3 (270 - 360 degrees)"
                    );

            endcase

        end

    endtask

    //========================================================
    // RUN TEST
    //========================================================

    task run_test;

        input [15:0] angle_input;

        begin

            // Calculate reference
            calculate_expected(angle_input);

            // Apply angle
            angle = angle_input;

            // Start pulse
            @(posedge clock);
            start = 1'b1;

            @(posedge clock);
            start = 1'b0;

            //================================================
            // Wait for DONE
            //================================================

            @(posedge done);

            #1;

            //================================================
            // Calculate errors
            //================================================

            cos_error =
                    expected_cos - cosine;

            sin_error =
                    expected_sin - sine;

            abs_cos_error = cos_error;

            abs_sin_error = sin_error;

            if (abs_cos_error < 0)
                abs_cos_error = -abs_cos_error;

            if (abs_sin_error < 0)
                abs_sin_error = -abs_sin_error;

            //================================================
            // Display
            //================================================

            $display("");
            $display("=============================================");
            $display("CORDIC TEST");
            $display("=============================================");

            $display(
                "Angle input  = 0x%04h",
                angle_input
            );

            $display(
                "Angle        = %f degrees",
                angle_degrees
            );

            display_quadrant(angle_input);

            $display("---------------------------------------------");

            $display(
                "Expected COS = %6d",
                expected_cos
            );

            $display(
                "Actual COS   = %6d",
                cosine
            );

            $display(
                "COS Error    = %11d",
                cos_error
            );

            $display("---------------------------------------------");

            $display(
                "Expected SIN = %6d",
                expected_sin
            );

            $display(
                "Actual SIN   = %6d",
                sine
            );

            $display(
                "SIN Error    = %11d",
                sin_error
            );

            $display("---------------------------------------------");

            //================================================
            // PASS / FAIL
            //================================================

            total_tests = total_tests + 1;

            // Allow maximum error of 20 LSB
            if ((abs_cos_error <= 20) &&
                (abs_sin_error <= 20)) begin

                $display("RESULT       = PASS");

                passed_tests = passed_tests + 1;

            end

            else begin

                $display("RESULT       = FAIL");

                failed_tests = failed_tests + 1;

            end

            //================================================
            // Track maximum errors
            //================================================

            if (abs_cos_error > max_cos_error)
                max_cos_error = abs_cos_error;

            if (abs_sin_error > max_sin_error)
                max_sin_error = abs_sin_error;

            $display("=============================================");

            // Allow done to return low
            @(negedge done);

        end

    endtask

    //========================================================
    // MAIN TEST
    //========================================================

    initial begin

        //====================================================
        // Initialize
        //====================================================

        reset = 1'b1;
        start = 1'b0;
        angle = 16'h0000;

        total_tests  = 0;
        passed_tests = 0;
        failed_tests = 0;

        max_cos_error = 0;
        max_sin_error = 0;

        //====================================================
        // RESET
        //====================================================

        #20;

        reset = 1'b0;

        #20;


        //====================================================
        // QUADRANT 0
        //====================================================

        $display("");
        $display("#################################################");
        $display("#                                               #");
        $display("#              QUADRANT 0 TESTS                 #");
        $display("#                0 - 90 degrees                 #");
        $display("#                                               #");
        $display("#################################################");

        run_test(16'h0000);     // 0°
        run_test(16'h0AAB);     // 15°
        run_test(16'h1555);     // 30°
        run_test(16'h2000);     // 45°
        run_test(16'h2AAB);     // 60°
        run_test(16'h3555);     // 75°
        run_test(16'h4000);     // 90°


        //====================================================
        // QUADRANT 1
        //====================================================

        $display("");
        $display("#################################################");
        $display("#                                               #");
        $display("#              QUADRANT 1 TESTS                 #");
        $display("#              90 - 180 degrees                 #");
        $display("#                                               #");
        $display("#################################################");

        run_test(16'h4AAB);     // 105°
        run_test(16'h5555);     // 120°
        run_test(16'h6000);     // 135°
        run_test(16'h6AAB);     // 150°
        run_test(16'h7555);     // 165°
        run_test(16'h8000);     // 180°


        //====================================================
        // QUADRANT 2
        //====================================================

        $display("");
        $display("#################################################");
        $display("#                                               #");
        $display("#              QUADRANT 2 TESTS                 #");
        $display("#             180 - 270 degrees                 #");
        $display("#                                               #");
        $display("#################################################");

        run_test(16'h8AAB);     // 195°
        run_test(16'h9555);     // 210°
        run_test(16'hA000);     // 225°
        run_test(16'hAAAB);     // 240°
        run_test(16'hB555);     // 255°
        run_test(16'hC000);     // 270°


        //====================================================
        // QUADRANT 3
        //====================================================

        $display("");
        $display("#################################################");
        $display("#                                               #");
        $display("#              QUADRANT 3 TESTS                 #");
        $display("#             270 - 360 degrees                 #");
        $display("#                                               #");
        $display("#################################################");

        run_test(16'hCAAB);     // 285°
        run_test(16'hD555);     // 300°
        run_test(16'hE000);     // 315°
        run_test(16'hEAAB);     // 330°
        run_test(16'hF555);     // 345°
        run_test(16'hFFAE);     // ~359°


        //====================================================
        // FINAL SUMMARY
        //====================================================

        $display("");
        $display("");
        $display("#################################################");
        $display("#                                               #");
        $display("#              FINAL TEST SUMMARY               #");
        $display("#                                               #");
        $display("#################################################");

        $display("");

        $display(
            "Total Tests  = %d",
            total_tests
        );

        $display(
            "Passed Tests = %d",
            passed_tests
        );

        $display(
            "Failed Tests = %d",
            failed_tests
        );

        $display("");

        $display(
            "Maximum COS Error = %d LSB",
            max_cos_error
        );

        $display(
            "Maximum SIN Error = %d LSB",
            max_sin_error
        );

        $display("");

        if (failed_tests == 0) begin

            $display("***********************************************");
            $display("*                                             *");
            $display("*       ALL CORDIC TESTS PASSED               *");
            $display("*                                             *");
            $display("***********************************************");

        end

        else begin

            $display("***********************************************");
            $display("*                                             *");
            $display("*       SOME CORDIC TESTS FAILED              *");
            $display("*                                             *");
            $display("***********************************************");

        end

        $display("");

        #20;

        $finish;

    end

endmodule