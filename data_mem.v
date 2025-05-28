module data_mem(  
      input clk, 
      input rst,  
      input [15:0] mem_access_addr,        // address input, shared by read and write port  
      input [15:0] mem_write_data,         // write port 
      input mem_write_en,  
      input mem_read_en,                          
      output reg [15:0] mem_read_data          // read port 
 );  
      integer k;
      reg [15:0] ram [255:0];  // Memory rows will be 65536 but for testing we consider 256
      wire [7:0] ram_addr = mem_access_addr[7 : 0]; 
		
always @(posedge clk) begin 
if(rst) begin
 for(k=0;k<256;k=k+1) begin 
        ram[k] <= 15'd2 ;  
       end
    mem_read_data <= 0;
//    ram[0] <= 16'd4;
//    ram[1] <= 16'd9; 
//    ram[9] <= 16'd16;
//    ram[10] <= 16'd20;
//    ram[11] <= 16'd24;
//    ram[12] <= 16'd28;
end
else if (mem_write_en)  
	ram[ram_addr] <= mem_write_data;  
else if(mem_read_en) 
     mem_read_data <= ram[ram_addr];
end  

endmodule  