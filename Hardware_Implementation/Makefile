# make          <- runs simv (after compiling simv if needed)
# make simv     <- compiles simv without running
# make verdi    <- runs GUI debugger (after compiling it if needed)
# make syn      <- runs syn_simv (after synthesizing if needed then 
#                                 compiling syn_simv if needed)
# make clean    <- remove files created during compilations (but not synthesis)
# make nuke     <- remove all files created during compilation and synthesis
#
# To compile additional files, add them to the TESTBENCH or SIMFILES as needed
# Every .vg file will need its own rule and one or more synthesis scripts
# The information contained here (in the rules for those vg files) will be 
# similar to the information in those scripts but that seems hard to avoid.
#

VCS = SW_VCS=2020.12-SP2-1 vcs -sverilog +vc -Mupdate -line -full64 -kdb -lca -debug_access+all+reverse +define+
LIB = /afs/umich.edu/class/eecs470/lib/verilog/lec25dscc25.v

all:	simv
	./simv | tee program.out

##### 
# Modify starting here
#####

HEADERS	  = sys_defs.svh
TESTBENCH = testbench_1way.v
SIMFILES = kmeans_1way.sv
SYNFILES = two_bit_pred.vg

export HEADERS


#####
# Should be no need to modify after here
#####
simv:	$(HEADERS) $(SIMFILES) $(TESTBENCH)
	$(VCS) $(HEADERS) $(TESTBENCH) $(SIMFILES) -o simv

novas.rc: initialnovas.rc
	sed s/UNIQNAME/$$USER/ initialnovas.rc > novas.rc

verdi:	simv novas.rc
	if [[ ! -d /tmp/$${USER}470 ]] ; then mkdir /tmp/$${USER}470 ; fi
	./simv -gui=verdi

syn_simv:	$(HEADERS) $(SYNFILES) $(TESTBENCH)
	$(VCS) $(TESTBENCH) $(SYNFILES) $(LIB) -o syn_simv

syn:	syn_simv
	./syn_simv | tee syn_program.out

clean:
	rm -rvf simv* *.daidir csrc vcs.key program.out \
	syn_simv syn_simv.daidir syn_program.out \
	dve *.vpd *.vcd *.dump ucli.key \
	DVEfiles/ verdi* novas* *fsdb*

nuke:	clean
	rm -rvf *.vg *.rep *.db *.chk *.log *.out
