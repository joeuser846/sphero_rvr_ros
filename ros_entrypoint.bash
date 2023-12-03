#!/bin/bash

source devel/setup.bash
if [ $ROS_HOSTNAME == "rvrbot" ]
then
	echo ">>>>> RUNNING AS RVRBOT <<<<<"
    roslaunch sphero_rvr_bringup sphero_rvr_bringup.launch
else
	echo ">>>>> RUNNING AS DEVHOST <<<<<"
    roslaunch sphero_rvr_navigation navigation.launch
fi

# Execute CMD parameter if we get here
exec "$@"