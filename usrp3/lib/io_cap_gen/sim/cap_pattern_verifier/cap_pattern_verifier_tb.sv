//
// Copyright 2015 Ettus Research LLC
//


`timescale 1ns/1ps
`define NS_PER_TICK 1
`define NUM_TEST_CASES 7

`include "sim_clks_rsts.vh"
`include "sim_exec_report.vh"
`include "sim_axi4_lib.sv"


module cap_pattern_verifier_tb();
  `TEST_BENCH_INIT("cap_pattern_verifier_tb",`NUM_TEST_CASES,`NS_PER_TICK)

  // Define all clocks and resets
  `DEFINE_CLK(clk, 5, 50)            //100MHz sys_clk to generate DDR3 clocking
  `DEFINE_RESET(rst, 0, 100)          //100ns for GSR to deassert

  axis_t data0 (.clk(clk));
  axis_t data1 (.clk(clk));
  assign data0.tready = 1;
  assign data1.tready = 1;

  wire [31:0] count0, errors0, count1, errors1;
  wire        locked0, failed0, locked1, failed1;

  cap_pattern_verifier #(
    .WIDTH(14),
    .PATTERN("RAMP"),
    .RAMP_START(14'h0000),
    .RAMP_STOP(14'h3FFF),
    .RAMP_INCR(14'h0001),
    .NTH_CYCLE(1)
  ) dut0 (
    .clk(clk),
    .rst(rst),
    .valid(data0.tvalid),
    .data(data0.tdata[13:0]),
    .count(count0),
    .errors(errors0),
    .locked(locked0),
    .failed(failed0)
  );
  
  cap_pattern_verifier #(
    .WIDTH(14),
    .PATTERN("RAMP"),
    .RAMP_START(14'h0100),
    .RAMP_STOP(14'h0FFF),
    .RAMP_INCR(14'h0001),
    .NTH_CYCLE(1)
  ) dut1 (
    .clk(clk),
    .rst(rst),
    .valid(data1.tvalid),
    .data(data1.tdata[13:0]),
    .count(count1),
    .errors(errors1),
    .locked(locked1),
    .failed(failed1)
  );

  //------------------------------------------
  //Main thread for testbench execution
  //------------------------------------------
  initial begin : tb_main

    `TEST_CASE_START("Wait for reset");
    while (rst) @(posedge clk);
    @(posedge clk);
    `TEST_CASE_DONE((rst==0));
    
    repeat (10) @(posedge clk);

    `TEST_CASE_START("Check reset state");
    `ASSERT_ERROR(count0==0,"Invalid state: count");
    `ASSERT_ERROR(errors0==0,"Invalid state: errors");
    `ASSERT_ERROR(~locked0,"Invalid state: locked");
    `ASSERT_ERROR(~failed0,"Invalid state: failed");
    `TEST_CASE_DONE(1);

    `TEST_CASE_START("Simple ramp");
    data0.push_ramp_pkt(100, 64'd0, 64'h1);
    repeat (3) @(posedge clk);
    `ASSERT_ERROR(count0==100,"Invalid state: count");
    `ASSERT_ERROR(errors0==0,"Invalid state: errors");
    `ASSERT_ERROR(locked0,"Invalid state: locked");
    `ASSERT_ERROR(~failed0,"Invalid state: failed");
    `TEST_CASE_DONE(1);

    rst <= 1;
    @(posedge clk);
    rst <= 0;

    `TEST_CASE_START("Multiple ramp iterations");
    data0.push_ramp_pkt(65536, 64'd0, 64'h1);
    repeat (3) @(posedge clk);
    `ASSERT_ERROR(count0==65536,"Invalid state: count");
    `ASSERT_ERROR(errors0==0,"Invalid state: errors");
    `ASSERT_ERROR(locked0,"Invalid state: locked");
    `ASSERT_ERROR(~failed0,"Invalid state: failed");
    `TEST_CASE_DONE(1);

    rst <= 1;
    @(posedge clk);
    rst <= 0;

    `TEST_CASE_START("Simple failure");
    data0.push_ramp_pkt(9, 64'd0, 64'h1);
    data0.push_ramp_pkt(100, 64'd10, 64'h1);
    repeat (3) @(posedge clk);
    `ASSERT_ERROR(count0==109,"Invalid state: count");
    `ASSERT_ERROR(errors0==1,"Invalid state: errors");
    `ASSERT_ERROR(locked0,"Invalid state: locked");
    `ASSERT_ERROR(failed0,"Invalid state: failed");
    `TEST_CASE_DONE(1);

    `TEST_CASE_START("Late start success");
    data1.push_ramp_pkt(4096, 64'd0, 64'h1);
    repeat (3) @(posedge clk);
    `ASSERT_ERROR(count1==4096-256,"Invalid state: count");
    `ASSERT_ERROR(errors1==0,"Invalid state: errors");
    `ASSERT_ERROR(locked1,"Invalid state: locked");
    `ASSERT_ERROR(~failed1,"Invalid state: failed");
    `TEST_CASE_DONE(1);

    rst <= 1;
    @(posedge clk);
    rst <= 0;

    `TEST_CASE_START("Late failure overshoot");
    data1.push_ramp_pkt(4097, 64'd0, 64'h1);
    repeat (3) @(posedge clk);
    `ASSERT_ERROR(count1==4097-256,"Invalid state: count");
    `ASSERT_ERROR(errors1==1,"Invalid state: errors");
    `ASSERT_ERROR(locked1,"Invalid state: locked");
    `ASSERT_ERROR(failed1,"Invalid state: failed");
    `TEST_CASE_DONE(1);

  end

endmodule
