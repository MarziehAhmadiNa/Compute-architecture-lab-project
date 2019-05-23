`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:40:34 07/01/2018 
// Design Name: 
// Module Name:    image 
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
module image(input clk,input rx,input [1:0] s,output [5:0] rgb,output hsync,output vsync);
	reg [6:0] x=0,y=0;
	reg [1:0] i=0;
	reg signed [7:0] kernel [8:0];
	reg signed [7:0] marray [2:0];
	wire [20:0] v,h;
	wire [7:0] identity;
	wire [7:0] edge_detect;
	wire [7:0] goasi;
	reg flag = 0;
	
	wire CLK_OUT1,CLK_OUT2;
	wire LOCKED;
	clk_divider my_clk_div
   (// Clock in ports
    .CLK_IN(clk),      // IN
    // Clock out ports
    .CLK_OUT1(CLK_OUT1),     // OUT
    .CLK_OUT2(CLK_OUT2),     // OUT
    // Status and control signals
    .RESET(RESET),// IN
    .LOCKED(LOCKED));      // OUT
	
	wire [12:0] addrb_first;
	reg [12:0] addra_first;
	wire [7:0] doutb_first;
	reg [12:0] addra_second;
	wire [12:0] addrb_second;
	wire [7:0] dina_second,doutb_second;
	wire RxD_data_ready;
	reg RxD_data_re;
	wire[7:0] RxD_data;
	
	async_receiver  # (.Baud(115200)) receiver(
	.clk(CLK_OUT1), 
	.RxD(rx),  								// 1 bit input data
	.RxD_data_ready(RxD_data_ready),  	//if 8 bit data received
	.RxD_data(RxD_data),  					// 8 bit output data
	.RxD_idle(RxD_idle),  
	.RxD_endofpacket(RxD_endofpacket)
	);
	
	always @(posedge CLK_OUT1)
		RxD_data_re <= RxD_data_ready;
		
	always @(posedge CLK_OUT1)
		if(RxD_data_re)
		begin
			addra_first <= addra_first + 1'b1;
			if(addra_first == 6400)
				begin
					addra_first <= 0;
				end
		end		
	 
	first_ram my_first_ram (
  .clka(CLK_OUT1), // input clka
  .wea(RxD_data_ready),//1'b1), // input [0 : 0] wea
  .addra(addra_first), // input [12 : 0] addra
  .dina(RxD_data), // input [7 : 0] dina
  .douta(douta_first), // output [7 : 0] douta
  .clkb(CLK_OUT1), // input clkb
  .web(1'b0), // input [0 : 0] web
  .addrb(addrb_first), // input [12 : 0] addrb
  .dinb(dinb_first), // input [7 : 0] dinb
  .doutb(doutb_first) // output [7 : 0] doutb
	);
	
	wire [1:0] r,g,b,gray;
	wire[7 : 0] doutb_gray;
	
	assign addrb_first= flag ? 0 : (y+i)*80+x;
	
	assign b = doutb_first & 3;
	assign g = (doutb_first>>2) & 3;
	assign r = (doutb_first>>4) & 3;
	assign gray = (r+g+b)/3;
	assign doutb_gray ={gray,gray,gray};
	
	always @(posedge CLK_OUT2)
	begin
	if(LOCKED)
	begin
		
		marray[i]<=doutb_gray;
		i <= i+1'b1;
		if(i==2)
		begin
			x<=x+1'b1;
			addra_second <=addra_second+1'b1;
			i<=0;
			flag<=0;
			if(addra_second==6400 || addra_first == 6400)
			begin
				flag<=1;
				x<=0;
				y<=0;
				addra_second<=0;
			end
			kernel[0]<=kernel[3];
			kernel[1]<=kernel[4];
			kernel[2]<=kernel[5];
			kernel[3]<=marray[0];
			kernel[4]<=marray[1];
			kernel[5]<=marray[2];
		end
		if(x==80)
		begin
			x<=0;
			y<=y+1'b1;
			kernel[0]<=0;
			kernel[1]<=0;
			kernel[2]<=0;
			kernel[3]<=0;
			kernel[4]<=0;
			kernel[5]<=0;
			marray[0]<=0;
			marray[1]<=0;
			marray[2]<=0;
		end
	end
	end
	assign v = (kernel[0] + kernel[1] + 2 * kernel[2] - 2*marray[1] - marray[0] - marray[2])>0 ?
					(kernel[0] + kernel[1] + 2 * kernel[2] - 2*marray[1] - marray[0] - marray[2]):
					-(kernel[0] + kernel[1] + 2 * kernel[2] - 2*marray[1] - marray[0] - marray[2]);
	assign h = (kernel[0] + 2*kernel[3] + marray[0] - kernel[2] - 2*kernel[5] - marray[2])>0 ?
					(kernel[0] + 2*kernel[3] + marray[0] - kernel[2] - 2*kernel[5] - marray[2]):
					-(kernel[0] + 2*kernel[3] + marray[0] - kernel[2] - 2*kernel[5] - marray[2]);
	assign goasi = (2*kernel[0] + kernel[1] + 2*kernel[2] + kernel[3] + 4*kernel[4] + kernel[5] + 2*marray[0] + marray[1] + 2*marray[2])>>4;
	assign edge_detect = (h+v) > 8'b01111111 ? 8'b11111111 : 8'b00000000; 
	assign identity = marray[0];
	
	assign dina_second = (s == 2'b00) ? identity : (s == 2'b01) ? goasi : edge_detect;
	
	second_ram my_second_ram (
  .clka(CLK_OUT1), // input clka
  .wea(1'b1), // input [0 : 0] wea
  .addra(addra_second), // input [12 : 0] addra
  .dina(dina_second), // input [7 : 0] dina
  .douta(douta_second), // output [7 : 0] douta
  .clkb(CLK_OUT1), // input clkb
  .web(1'b0), // input [0 : 0] web
  .addrb(addrb_second), // input [12 : 0] addrb
  .dinb(dinb_second), // input [7 : 0] dinb
  .doutb(doutb_second) // output [7 : 0] doutb
	);

	
	vga_monitor vga (
    .clk(CLK_OUT1),  
    .data(doutb_second), 
    .address(addrb_second), 
    .hsync(hsync), 
    .vsync(vsync), 
    .rgb(rgb)
    );
endmodule
