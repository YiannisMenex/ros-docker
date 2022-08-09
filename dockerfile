FROM ros:melodic-ros-base

# Install native programs & packages 
RUN dpkg --add-architecture i386 && \
    apt-get update -y && \
    apt-get install -y tmux && \
    apt-get install -y nano &&\
    # install ROS opt packages (below)
    apt-get install -y ros-melodic-roslint &&\
    apt-get install -y ros-melodic-nmea-navsat-driver &&\
    apt-get install -y ros-melodic-nmea-msgs &&\
    apt-get install -y ros-melodic-catkin-virtualenv



# Install ROS tools to compile TF2 for python3 (explained below) 
RUN sudo apt install -y python3-catkin-pkg-modules python3-rospkg-modules python3-empy



# Copy our bashrc into root folder for automatic sourcing to our packages
# whenever we create a new tab using Tmux, and use bash
#==============================================================================
COPY mybashrc /root/.bashrc
SHELL ["/bin/bash", "-c"]
#==============================================================================



# Initialize catkin workspace
#==============================================================================
RUN mkdir -p /catkin_ws/src
WORKDIR /catkin_ws
RUN source /opt/ros/melodic/setup.bash && catkin_make
#==============================================================================



# "Hack" to compile tf2 using python3 (ros melodic)
# otherwise it wouldn't install tf (since it was made for python2)
#==============================================================================
RUN source devel/setup.bash
RUN wstool init
RUN wstool set -y src/geometry2 --git https://github.com/ros/geometry2 -v 0.6.5
RUN wstool up
RUN rosdep install --from-paths src --ignore-src -y -r
RUN source /opt/ros/melodic/setup.bash && catkin_make --cmake-args \
            -DCMAKE_BUILD_TYPE=Release \
            -DPYTHON_EXECUTABLE=/usr/bin/python3 \
            -DPYTHON_INCLUDE_DIR=/usr/include/python3.6m \
            -DPYTHON_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython3.6m.so
#==============================================================================



# Download or Transfer catkin workspace packages
# (private repositories are best to be downloaded in the host, and copied to the container from here)
#==============================================================================
#COPY NMEAparser/ /catkin_ws/src/NMEAparser/
#==============================================================================


# Build our catkin_ws packages
RUN source /opt/ros/melodic/setup.bash && catkin_make
