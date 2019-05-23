`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:23:35 12/25/2017 
// Design Name: 
// Module Name:    vga_monitor 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module vga_monitor
	(
		input clk,
		input [7:0] data,
		output [12:0] address,
		output hsync, vsync,
		output reg [5:0] rgb
	);
	
	// register for Basys 2 8-bit RGB DAC 
		reg [5:0] rgb_reg;
	
	// video status output from vga_sync to tell when to route out rgb signal to DAC
		wire video_on;		  
		wire [10:0] px,py;
		reg [10:0] x=0,y=0;
		wire [1:0] r,g,b,gray;
// Instantiate the module
		vga_sync v1 (
			.clk(clk), 
			.pixel_x(px), 
			.pixel_y(py), 
			.videoon(video_on), 
			.h_synq(hsync), 
			.v_synq(vsync)
		);		
	assign gray = data & 3;
      always @(posedge clk)
			begin
				  if (video_on)
					if(px<280 || py<200)
						begin
								rgb <= 6'b000000;
								x <= x;
								y <= y;
						end
					else if(px>=280 && px<360 && py>=200 && py<280)
						begin
								rgb <= {gray,gray,gray};//data;
								x <= px - 280;
								y <= py - 200;
							end
						else
							begin
								rgb <= 6'b000000;
								x <= x;
								y <= y;
							end
				  else
					  rgb  <= 6'b000000;
			end
			assign address = x*80 +y;
endmodule
