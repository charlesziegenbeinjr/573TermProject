
module testbench_e2cd();

logic clk, reset, training, valid;
logic [38:0] element;
logic [`K-1:0][38:0] centroid;
logic [`K-1:0][38:0] distance;
logic valid_out;

integer readfile,writefile,data;

toplevel testunit(.clk(clk),.reset(reset),.training(training),.valid(valid),
                    .element_in(element),.formatted_centroids(formatted_centroids),
                    .elements_out(element_out)
    );

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