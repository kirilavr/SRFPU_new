MODULE = cleaner_top
SRC_FILE = basic_test


CC = riscv64-unknown-elf-gcc -O0
AS = riscv64-unknown-elf-as
LD = riscv64-unknown-elf-ld
OBJCOPY = riscv64-unknown-elf-objcopy

CFLAGS = -march=rv32if -mabi=ilp32
LDFLAGS = -T ./testing/linker.ld -m elf32lriscv

BIN = firmware.bin

all: sim

.PHONY:sim
sim: hex waveform.vcd 

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


.stamp.verilate: ./rtl_cleaner/$(MODULE).sv ./testing/tb_$(MODULE).cpp
	verilator  --trace -cc ./rtl_cleaner/$(MODULE).sv --exe ./testing/tb_$(MODULE).cpp --top-module $(MODULE)
	./add_helpers.bs $(MODULE)
	touch .stamp.verilate


.PHONY:lint
lint: $(MODULE).sv
	verilator --lint-only $(MODULE).sv

.PHONY: clean
clean:
	rm -f .stamp.*
	rm -rf ./obj_dir
	rm -f waveform.vcd
	rm -f res_file_muldiv_norm.txt
	rm -f res_file_muldiv.txt
	rm -f res_file_muldiv_pre.txt
	rm -f res_file_muldiv_top.txt
	rm -f res_file_addsub_top.txt
	rm -f res_file_addsub.txt
	rm -f res_file_addsub_norm.txt
	rm -f ./testing/start.o
	rm -f ./testing/$(SRC_FILE).o
	rm -f ./testing/firmware.elf
	rm -f ./testing/firmware.bin
	rm -f ./testing/firmware.hex
	rm -f ./testing/memory_dump.hex
	rm -f pc_monitor
	rm -f mem_interface_monitor
	rm -f fpu_mem_interface_monitor
	rm -f ./testing/fpu_reg_dump.hex
	rm -f fpu_debug_file
	rm -f fpu_res_file
	rm -f subverify
	rm -f accumulator
	rm -f layer
	rm -f fmaps
	rm -f filters
	rm -f tfmaps_file
	




.PHONY:hex

hex:./testing/firmware.bin
	xxd -e -g4 $< | cut -d" " -f2-5 > ./testing/firmware.hex
	rm -f $<

./testing/firmware.bin:./testing/firmware.elf
	$(OBJCOPY) -O binary $< $@
	@echo "Size of firmware.bin:"
	@wc -c < $@
	#rm -rf $<

./testing/firmware.elf: ./testing/start.o ./testing/$(SRC_FILE).o ./testing/linker.ld
	$(LD) $(LDFLAGS) -o $@ ./testing/start.o ./testing/$(SRC_FILE).o
	rm -rf ./testing/start.o
	rm -rf ./testing/$(SRC_FILE).o

./testing/$(SRC_FILE).o: ./testing/$(SRC_FILE).c
	$(CC) $(CFLAGS) -c -o $@ $<

./testing/start.o: ./testing/start.S
	$(AS) $(CFLAGS) -o $@ $<









