# EECS 573 Final Project
## Peter Hevrdejs, Charles B. Ziegenbein Jr., Nam Ho Koh, Joseph Plata


### Directory Organization
1. Hardware_Implementation: Our main directory for the Hardware Implementation. Contains:
    1. kmeans_1way.sv for System Verilog that we wrote for our ASIC
    1. testbench_1way.sv for System Verilog that we wrote to test our ASIC
    1. Makefile for the Synopsys Verdi
1. Software_Implementation: Our main directory for the Software Implementation. Contains:
    1. DecisionTree directory for decision tree output
    1. ExplainableKMC directory for edited version of ExKMC library to work with our hardware acceleration
    1. PowerData to hold our power data for graphing
    1. Centroids.txt as output from hardware for the centroids themselves
    1. requirements.txt to pip install required libraries
    1. sw_explainable.py for main script
    1. times.txt as holder for the average times we generated for the subprocesses of the script
1. Data: Our main directory for holding our data that we used to generate this project. Should contain the raw Mental Health data, as well as our cleaned Mental Health data set.
1. HardwareTestData where we created random data that we fed to the hardware component, including random samples for the features and random centroids to begin with 


### Running the Software
To run the software, please go to the Software_Implementation folder and look at the sw_explainable.py for specific instructions. Our code is documented.

### Running the Hardware
This will require CAEN and Synopsys Verdi. On a CAEN machine, please go into VSCode and run the make file associated with Verdi itself. Refer to the ReadMe inside of the Hardware_Implementation Directory.

### Questions
Please reach out to cbzjr@umich.edu should there be questions concerning the software, and hevrdejs@umich.edu for questions concerning the hardware.