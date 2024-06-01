set -x
PATH=/opt/ghdl/bin:$PATH
rm neo430-obj93.cf neo430_cpu.v

NEOSRC="core/neo430_package.vhd core/neo430_addr_gen.vhd core/neo430_alu.vhd core/neo430_control.vhd core/neo430_cpu.vhd core/neo430_reg_file.vhd "

for f in $NEOSRC ; do
    ghdl -a --work=neo430 --std=08 $f
done
ghdl -a --work=neo430 --std=08 neo430_cpu_std_logic.vhd
ghdl synth --std=08 --work=neo430 --out=verilog neo430_cpu_std_logic > neo430_cpu.v
