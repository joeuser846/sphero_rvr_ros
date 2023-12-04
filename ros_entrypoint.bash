#!/bin/bash

source devel/setup.bash
if [ $ROS_HOSTNAME == "rvrbot" ]
then
	echo ">>>>> RUNNING ON SPHERO-RVR <<<<<"
    roslaunch sphero_rvr_bringup sphero_rvr_bringup.launch
else
	echo ">>>>> RUNNING ON DEVHOST <<<<<"
    roslaunch sphero_rvr_navigation sphero_rvr_navigation.launch
fi

# Execute CMD parameter if we get here
exec "$@"