MODULE = hp_top

.PHONY:sim
sim: waveform.vcd

.PHONY:verilate
verilate: .stamp.verilate

.PHONY:build
build: obj_dir/Vhp_class

.PHONY:waves
waves: waveform.vcd
	gtkwave waveform.vcd


waveform.vcd:obj_dir/V$(MODULE)
	./obj_dir/V$(MODULE)

./obj_dir/V$(MODULE):.stamp.verilate
	make -C obj_dir -f V$(MODULE).mk V$(MODULE)


.stamp.verilate: ./rtl/$(MODULE).sv ./testing/tb_$(MODULE).cpp
	verilator  --trace -cc ./rtl/$(MODULE).sv --exe ./testing/tb_$(MODULE).cpp
	./add_helpers.bs
	touch .stamp.verilate

.PHONY:lint
lint: $(MODULE).sv
	verilator --lint-only $(MODULE).sv

.PHONY: clean
clean:
	rm -rf .stamp.*;
	rm -rf ./obj_dir
	rm -rf waveform.vcd
	rm -rf res_file_top.txt
	rm -rf res_file_class.txt
	rm -rf res_file_mult.txt
	rm -rf res_file_clz.txt