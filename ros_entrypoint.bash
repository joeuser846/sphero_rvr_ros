#!/bin/bash

source devel/setup.bash
roslaunch sphero_rvr_bringup sphero_rvr_bringup.launch

# Execute CMD parameter if we get here
exec "$@"