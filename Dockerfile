
# If push fails restart docker engine on gram ('sudo service docker restart')

#     docker build --no-cache --file Dockerfile -t gram:5000/rvrbot:arm64 . --push

#     docker build --no-cache --file Dockerfile -t gram:5000/rvrbot:x86 . --push

# Bringup container:

#     docker run -it --rm --network=host --privileged --name=rvrbot gram:5000/rvrbot:arm64 

#     docker run -it --rm --network=host --privileged --name=rvrbot gram:5000/rvrbot:x86

# Access bash prompt on running rvrbot container:

#     docker exec -it rvrbot /bin/bash

# Launch rvrbot (in ros_entrypoint.bash):

#     roslaunch sphero_rvr_bringup sphero_rvr_merged_bringup.launch


FROM ros:noetic-ros-base-focal
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

# All COPY from locations are based at location of this Dockerfile
COPY src $ROS_WS/src

# Clone ROS Robot Localization package
# RUN git -C src clone \
#      -b noetic-devel \
#      https://github.com/cra-ros-pkg/robot_localization.git

# Clone LDLIDAR package
# RUN git -C src clone \
#     -b master \
#     https://github.com/ldrobotSensorTeam/ldlidar_stl_ros.git

# Add the Sphero SDK
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

# Do not change following ENV variables - they are set this way after much debugging
ENV ROS_MASTER_URI=http://localhost:11311/
ENV ROS_HOSTNAME=rvrbot

COPY ros_entrypoint.bash .
RUN chmod +x ./ros_entrypoint.bash
ENTRYPOINT ["./ros_entrypoint.bash"]
# Following executes at <exec "$@"> in entrypoint file
CMD ["/bin/bash"]