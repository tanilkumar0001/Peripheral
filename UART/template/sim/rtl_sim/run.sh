cd ../codes/
./run.sh ASM

cd ../rtl_sim/
rm -rf INCA_libs/ ncverilog.log
ncverilog -f TB_TOP.f +access+rw
