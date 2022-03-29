@echo off
set xv_path=C:\\Xilinx\\Vivado\\2017.1\\bin
call %xv_path%/xsim TB_WIFI_DECRYPT_behav -key {Behavioral:sim_1:Functional:TB_WIFI_DECRYPT} -tclbatch TB_WIFI_DECRYPT.tcl -view D:/workdir/vivado_project/wifi_decrypt/wifi_decrypt/TB_WIFI_DECRYPT_behav.wcfg -log simulate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
