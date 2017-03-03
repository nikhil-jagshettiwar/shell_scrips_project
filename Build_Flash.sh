#!/bin/bash
#script is designed to flash the FPGA and run the basic Build_Install/sanity/Color format test for aventurine as well as Tridymite

### Checking any command line argument available or not ####
if [  $# == 0 ]; then
	echo 'Give atleast one argument from the below list'
	echo '<debug> for Debug build'
	echo '<release> for Debug build'
	echo '<local> for build avialble on the same location as script'
	echo '<non-local> for build available at http://fpga-master.hh.imgtec.org/pub/builds/quartz/'
	echo 'if mentioned above four options then also please mentioned the build name'
	echo '<flash> for flashing the fpga'
	exit
fi
echo $#


##### Removing the folders if already presents #####

if [ -d "instal_release" -o -d "instal_debug" ]; then
	echo 'directory instal_release already exists do you want to remove it'
	read -p "enter <y> or  <n> if you want to delete the folder : " input
	echo $input

	if [[ "$input" = "y" ]]; then 
		echo 'removing the directory'
		if [ -d "instal_release" ]; then
			rm -rf instal_release
		fi		

		if [ -d "instal_debug" ]; then
			rm -rf instal_debug
		fi              

	else
		echo 'overwritting the km and executable files only'
	fi
	
fi




# Storing the root location as the location where script kept 
Root_Location=$(pwd)
echo $Root_Location

#### Assining the varibales #####
Local=false
Non_Local=false
Flag_Debug=false
Flag_Release=false
Flag_Program_FPGA=false
Build_Name=false
shopt -s nocasematch	# this command used for case sensivity
while (( "$#" )); do
	if [[ "$1" = "local" ]]; then
			Local=true
	elif [[ "$1" = "non_local" ]]; then
			Non_Local=true
	
	elif [ `echo "$1" | grep -c "PVR" ` -gt 0 ]; then
			Build_Name=$1
	
	elif [[ "$1" = "debug" ]]; then
			Flag_Debug=true
	
	elif [[ "$1" = "release" ]]; then
			Flag_Release=true

	elif [[ "$1" = "flash" ]]; then
			Flag_Program_FPGA=true			

	fi

shift
done

shopt -u nocasematch

#### checking few conditions ####
if [ "$Flag_Release" = true ] || [ "$Flag_Debug" = true ] && [ "$Build_Name" = false ]; then
	echo 'Enters the build name'
	exit
fi

if [ "$Flag_Release" = true ] || [ "$Flag_Debug" = true ] && [ "$Local" = false ] && [ "$Non_Local" = false ] ; then
	echo 'Mention build available locally or not by entering <local> or <non_local> on command line argument'
	exit
fi




#### Non Local build ####
# Copying the file to root location using wget command 

if [ $Non_Local == true ]; then
	file="http://fpga-master.hh.imgtec.org/pub/builds/quartz/$Build_Name"
	echo $file
	wget $file
	if [ $? -eq 0 ]; then
			echo OK
	else
			echo 'build package is not avialble at the fpga-master location'
			exit
	fi
fi


#### Release build ####

if [ $Flag_Release == true ]; then
	
	if [ -d "$instal_release" ]; then
		echo 'directory instal_release already exists do you want to remove it'
		echo 'press <y> or <n>'
		
	fi


	tar -zxvf $Build_Name
	mkdir img/obj
	cd img/obj
	
	##### One change specific to Quartz ####
	sed -i -e '/VXE_DEFAULT_TILE_STRIDE/ s/512/4096/' $Root_Location/img/encoder/quartz/include/VXE_Enc_GlobalDefs.h
	
	cmake -D BRIDGING=ON -D PLATFORM=img_fpga -DCMAKE_BUILD_TYPE=Release -DLARGE_BAR=ON ..; make clean; make


	# Copying the data to Release folder
	cd $Root_Location
	mkdir instal_release
	cd instal_release
	cp ../img/imgvideo/imgvideo.ko .
	cp ../img/encoder/quartz/vxekm.ko .
	cp ../img/obj/encoder/quartz/test_apps/vxe_testbench/vxe_testbench .
	
	# Removing the Release build
	cd ../
	rm -rf img/
fi

#### Debug build ####
if [ $Flag_Debug == true ]; then
	tar -zxvf $Build_Name
	mkdir img/obj
	cd img/obj
	
	##### One change specific to Quartz ####
	sed -i -e '/VXE_DEFAULT_TILE_STRIDE/ s/512/4096/' $Root_Location/img/encoder/quartz/include/VXE_Enc_GlobalDefs.h
	
	#### CMAKE command ####
	cmake -D BRIDGING=ON -D PLATFORM=img_fpga -DCMAKE_BUILD_TYPE=Debug -DLARGE_BAR=ON ..; make clean; make
	
	# Copying the data to Release folder
	cd $Root_Location
	mkdir instal_debug
	cd instal_debug
	cp ../img/imgvideo/imgvideo.ko .
	cp ../img/encoder/quartz/vxekm.ko .
	cp ../img/obj/encoder/quartz/test_apps/vxe_testbench/vxe_testbench .
	
	# Removing the Release build
	cd ../
	rm -rf img/
fi


#Flashing the FPGA

if [ $Flag_Program_FPGA == true ]; then

	# Below section I have written for changing load_fpga file and few supporting file - changes get automatic revert after reboot
	cp /mnt/fpga_master/testsystem/scripts/load_fpga.py .	# for copying the load_fpga.py as mounted file cant be rewritten
	sed -i -e '/DEFAULT_ENCODER_FPGA_IMAGES_ROOT/ s/fpga_images/aventurine_fpga_images/' load_fpga.py
	sed -i -e 's/quartz_fpga_images/aventurine_fpga_images/g' /opt/fpga_rpc/tcf_tools/dut/quartz.py
	
	# MAIN command line for flashing the FPGA
	python load_fpga.py --encoder --name quartz_10bit_dev_160524_4069846_1pipe_TCF5

fi
