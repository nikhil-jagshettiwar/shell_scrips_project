a=0
while [ "$a" -lt 100 ]    # this is loop1
do
	insmod imgvideo.ko
	insmod vxekm.ko 
	./vxe_testbench -test DriverTest -psnrlog 1 -encresolution 420 -framecount 10 -coreRev 0x50300 -realfw 1 -framerate 30 -t AVC -o codeddata.264 -srcyuv /user/quartz.sim/yuv_files/YUVFormats/batman_1920x1080_YUV_10.yuv    -src_w 1920    -src_h 1080    -src_format PL12_10 -encbitdepth 10 -MMUTiling 0
	rmmod vxekm.ko 
	rmmod imgvideo.ko	
	a=`expr $a + 1`
done

