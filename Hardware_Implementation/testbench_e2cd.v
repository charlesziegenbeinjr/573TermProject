`timescale 1ns / 1ps
module testbench_e2cd();

logic clk, reset, valid;
logic [38:0] element;
logic [`K-1:0][38:0] centroid;
logic [`K-1:0][38:0] distance;
logic valid_out;

integer readfile,writefile,data;

e2cd testunit(.clk(clk),.reset(reset),.valid_in(valid),
              .element(element),.centroid(centroid),.distance(distance),
              .valid_out(valid_out));

always begin
    #10;
    clk = ~clk;
end

initial begin
    valid = 1'b0;
    clk = 1'b0; //NEG
    reset = 1'b1;

    //readfile = $fopen("inputstream.txt","r");
	//writefile = $fopen("outputstream.txt","w");

    #10 //POS
    valid = 1'b1;
    reset = 1'b0;
    element         = 39'b100110100000110011000101010100110000100;
    centroid[0]     = 39'b100110100000110011000101010100110000100; //dis 0
    centroid[1]     = 39'b100110100000110011000101010100110000101; //dis 1 (-)
    centroid[2]     = 39'b100110100000110011000101010100110000110; //dis 2 (-)
    centroid[3]     = 39'b100110100000110011000101010100110000111; //dis 3 (-)
    centroid[4]     = 39'b100110100000110011000101010100110000000; //dis 4 (+)
    centroid[5]     = 39'b100110100000110011000101010100110000100; // dis 0 
    centroid[6]     = 39'b100110100000110011000101010100110000100;
    centroid[7]     = 39'b100110100000110011000101010100110000100;
    centroid[8]     = 39'b100110100000110011000101010100110000100;
    centroid[9]     = 39'b100110100000110011000101010100110000100;
    centroid[10]    = 39'b100110100000110011000101010100110000100;
    centroid[11]    = 39'b100110100000110011000101010100110000100;
    centroid[12]    = 39'b100110100000110011000101010100110000100; // dis 0
    #10 //NEG
    
    #100

    //#165000;
    //$stop;
    $finish;
end

// always @(posedge clk) begin
// 	data = $fscanf(readfile,"%b\n", element);
// end


endmodule