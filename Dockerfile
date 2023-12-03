
# If push fails restart docker engine on gram ('sudo service docker restart')


# Commands for rvrbot on RPi/arm64

#     no-cache / registry:  docker build --no-cache --target=rvrbot --file Dockerfile -t gram:5000/rvr:arm64 . --push

#     cache / registry:     docker build --target=rvrbot --file Dockerfile -t gram:5000/rvr:arm64 . --push

#     cache / local:        docker build --target=rvrbot --file Dockerfile -t rvr:arm64 .       DON'T FORGET '.'

#     run registry:         docker run -it --rm --network=host --privileged --name=rvrbot gram:5000/rvr:arm64 

#     run local:            docker run -it --rm --network=host --privileged --name=rvrbot rvr:arm64

#     roslaunch sphero_rvr_bringup sphero_rvr_merged_bringup.launch

#     docker exec -it rvrbot /bin/bash

# Commands for devhost on gram/x86:

#     docker build --no-cache --target=devhost --file Dockerfile -t gram:5000/rvr:x86 . --push

#     docker build --target=devhost --file Dockerfile -t gram:5000/rvr:x86 . --push

#     docker run -it --rm --network=host --privileged --name=devhost gram:5000/rvr:x86

#     xhost +local:

#     rosrun tf2_tools view_frames.py

#     evince frames.pdf

#     docker exec -it devhost /bin/bash

#     roslaunch sphero_rvr_navigation navigation.launch


FROM ros:noetic-ros-base-focal AS base
USER root
# Suppress all interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update -y && \
# Upgrade required or 'rosdep install' gets errors pulling dependencies 
    apt upgrade -y && \
    apt install -y \
    python3-catkin-tools \
    python3-vcstool \
    wget \
    git \
    python3-pip \
# Install tools for debugging comms at runtime
    net-tools \
    iputils-ping \
    netcat \
    nano

# Set location of our container's catkin workspace
ENV ROS_WS /opt/ros_ws
RUN mkdir -p $ROS_WS/src
WORKDIR ${ROS_WS}

# COPY-from is rooted at location of this Dockerfile
COPY src $ROS_WS/src

# Clone ROS Robot Localization package
# RUN git -C src clone \
#      -b noetic-devel \
#      https://github.com/cra-ros-pkg/robot_localization.git

# Clone LDLIDAR package
# RUN git -C src clone \
#     -b master \
#     https://github.com/ldrobotSensorTeam/ldlidar_stl_ros.git

# Add the Sphero SDK and MQTT library
RUN pip install sphero-sdk
RUN pip install paho-mqtt

# Install ROS package dependencies
RUN rosdep update && \
    rosdep install --from-paths src --ignore-src -r -y

# Build ROS packages from source code
RUN catkin config --extend /opt/ros/$ROS_DISTRO && \
    catkin build

# Tell container that UI output goes to host X11 server
# Note: Host must execute 'xhost +local:' command BEFORE rviz starts    
# Note: 'docker run --ipc=' parameter may improve some rviz rendering artifacts
ENV DISPLAY=:0

COPY ros_entrypoint.bash .
RUN chmod +x ./ros_entrypoint.bash
ENTRYPOINT ["./ros_entrypoint.bash"]
# Following executes at <exec "$@"> in entrypoint file
CMD ["/bin/bash"]

# Do not change following ENVs - they are set this way after much debugging
# Create two layers with active one selected by build --target argument
FROM base AS rvrbot
ENV ROS_MASTER_URI=http://localhost:11311/
ENV ROS_HOSTNAME=rvrbot

FROM base AS devhost
ENV ROS_MASTER_URI=http://rvrbot:11311/
ENV ROS_HOSTNAME=gram