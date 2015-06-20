PROJECT=fpga
PART=xc6slx9-ftg256-3

TOOL_PATH ?= /opt/Xilinx/14.5/ISE_DS/ISE/bin/lin64
 
all: ${PROJECT}_routed.bit

project/${PROJECT}.prj:
	mkdir -p project
	echo "verilog work \"../top.v\"" > project/${PROJECT}.prj
	echo "verilog work \"../ftdi_if.v\"" >> project/${PROJECT}.prj
	echo "verilog work \"../ftdi_sync.v\"" >> project/${PROJECT}.prj
	echo "verilog work \"../sdram.v\"" >> project/${PROJECT}.prj
	echo "vhdl work \"../clk_50_100.vhd\"" >> project/${PROJECT}.prj

${PROJECT}.ngc: project/${PROJECT}.prj	
	cp ${PROJECT}.* project/
	mkdir -p project/xst/projnav.tmp/
	cd project; xst -intstyle ise -ifn ${PROJECT}.xst -ofn ${PROJECT}.syr
        
${PROJECT}.ngd: ${PROJECT}.ngc
	cd project; ngdbuild -intstyle ise -dd _ngo -nt timestamp \
	-uc ${PROJECT}.ucf -p ${PART} ${PROJECT}.ngc ${PROJECT}.ngd

${PROJECT}.ncd: ${PROJECT}.ngd
	cd project; map -w -intstyle ise -p ${PART} \
	-detail -ir off -ignore_keep_hierarchy -pr b -timing -ol high -logic_opt on  \
	-o ${PROJECT}.ncd ${PROJECT}.ngd ${PROJECT}.pcf 

${PROJECT}_routed.ncd: ${PROJECT}.ncd
	cd project; par -w -intstyle ise -ol high ${PROJECT}.ncd ${PROJECT}_routed.ncd ${PROJECT}.pcf

${PROJECT}_routed.bit: ${PROJECT}_routed.ncd
	cd project; bitgen -f ${PROJECT}.ut ${PROJECT}_routed.ncd

clean:
	@rm -rf project
