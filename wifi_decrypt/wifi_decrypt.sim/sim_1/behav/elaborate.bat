@echo off
set xv_path=C:\\Xilinx\\Vivado\\2017.1\\bin
call %xv_path%/xelab  -wto 5600bfe3825145c0b9a191f8bb43f8cc -m64 --debug typical --relax --mt 2 -L xil_defaultlib -L secureip -L xpm --snapshot TB_WIFI_DECRYPT_behav xil_defaultlib.TB_WIFI_DECRYPT -log elaborate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
