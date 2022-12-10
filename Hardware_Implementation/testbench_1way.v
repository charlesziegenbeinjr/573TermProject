`timescale 1ns / 1ps
module testbench_e2cd();

logic clk, reset, training, valid,finished;
logic update_centroids; // signal to rf to update centroids
logic recalculate_centroids; //signal from counter to centroid sum unit
logic [38:0] element, data;
logic [`K-1:0][34:0] fc;
logic [38:0] element_from_memory;
logic trigger;


integer readfile,writefile0,writefile1,sout;

toplevel testunit(.clk(clk),.reset(reset),.training(training),.valid(valid),
                    .element_in(element),.formatted_centroids(fc),
                    .element_from_memory(element_from_memory),.finished(finished),
                    .update_centroids(update_centroids),.recalculate_centroids(recalculate_centroids)
                    );

always begin
    #5;
    clk = ~clk;
end



initial begin

    $monitor("Time:%4.0f clock:%b reset:%b Recalc Centroid:%b Update Centroids:%b 300 cycels done:%b", 
                 $time, clk, reset, recalculate_centroids, update_centroids, finished);
    valid = 1'b0;
    clk = 1'b0;
    reset = 1'b1;
    training = 1'b1;
    trigger = 1'b0;

    $display("\nStarting up Testbench\n");
    @(negedge clk);
    @(negedge clk);
    reset = 1'b0;
    writefile0=$fopen("dataset_v_out.txt","w");
    writefile1=$fopen("centroids_v_out.txt","w");
    readfile = $fopen("element_data_small.txt","r");
    valid = 1'b1;
    @(negedge clk);
    @(negedge clk);
    @(negedge clk);

    #1000
    $display("\nHalfway there\n");
    #1000
    #1000
    #1000
    #1000
    #1000
    #1000
    
    //$stop;
    trigger = 1'b1;
    @(negedge clk);
    @(negedge clk);

    $fclose(writefile0);
    $fclose(writefile1);
    #5
    $display("\nENDING TESTBENCH: SUCCESS!\n");
    $finish;
end

// always @(posedge clk) begin
// 	data = $fscanf(readfile,"%b\n", element);
// end

always_ff @(posedge clk) begin
  if (!$feof(readfile)) begin
    sout = $fscanf(readfile,"%b\n", data); 
    element = data;
  end
end

always_ff @(negedge clk)begin
    if(trigger)begin
        $fdisplay(writefile0,"%b",element_from_memory);
        $fdisplay(writefile1,"%b",fc[0],fc[1],fc[2],fc[3],fc[4],fc[5],fc[6],fc[7],fc[8],fc[9],fc[10],fc[11],fc[12],fc[13], "\n");
    end
end



endmodule