#! /bin/bash
#
# Shell script to set up the required software environment for the R5-COP Natural Language Interface ROS demo
# Created by Tamás Mészáros <meszaros@mit.bme.hu>
#

cd "$(dirname "$0")"

/bin/rm .setup_ok 2>/dev/null

if [ ! -x /usr/bin/gazebo ] && [ -d /opt/ros/indigo ]; then
  echo "--- Installing the simulator. This may take a while..."
  echo -n "Updating package lists..."
  apt-get -qq update
  echo done.
  echo -n "Installing ROS packages..."
  apt-get -qqy install python-catkin-tools cmake python-catkin-pkg python-empy python-nose libgtest-dev unzip >/dev/null 2>/dev/null
  echo -n "still installing..."
  apt-get -qqy install ros-indigo-roslint ros-indigo-move-base ros-indigo-slam-gmapping >/dev/null 2>/dev/null
  echo -n "jackal and gazebo..."
  apt-get -qqy install ros-indigo-jackal-simulator ros-indigo-jackal-desktop ros-indigo-gazebo-ros-pkgs ros-indigo-gazebo-ros-control >/dev/null 2>/dev/null
  echo done.
else
  echo "Gazebo is installed."
fi

if [ ! -x /usr/bin/glxinfo ]; then
  echo "--- Checking 3D hardware acceleration..."
  apt-get -qqy install libgles1-mesa-lts-${HOST_LSB} libgles2-mesa-lts-${HOST_LSB} libgl1-mesa-dri-lts-${HOST_LSB} libglapi-mesa-lts-${HOST_LSB} >/dev/null 2>/dev/null
  apt-get -qqy install mesa-utils # must be separated from the above
  glxinfo | grep "\(\(renderer\|vendor\|version\) string\)\|direct rendering"
  # LIBGL_DEBUG=vebose glxinfo |grep render
else
  echo -n "3D acceleration info: "
  glxinfo | grep "OpenGL vendor string\|direct rendering"
fi

source /opt/ros/indigo/setup.bash
  
if [ ! -f ~/jackal_navigation/devel/setup.bash ]; then
  echo "--- Setting up Jackal navigation. This may take a while..."
  mkdir -p ~/jackal_navigation/src
  pushd ~/jackal_navigation/src
  catkin_init_workspace
  git clone https://github.com/jackal/jackal.git
  git clone https://github.com/jackal/jackal_simulator.git
  git clone https://github.com/clearpathrobotics/LMS1xx.git
  git clone https://github.com/ros-drivers/pointgrey_camera_driver.git
  cd ..
  catkin_make
  echo done.
  echo "--- Setting up R5-COP demo world in Jackal..."
  sed -i 's/"[^"]*jackal_race.world/"\/root\/NLdemo\/r5cop_world.sdf/' /root/jackal_navigation/src/jackal_simulator/jackal_gazebo/launch/jackal_world.launch
  echo done.
  popd
else
  echo "Jackal is installed."
fi

source ~/jackal_navigation/devel/setup.bash

if [ `grep -c jackal_race /opt/ros/indigo/share/jackal_gazebo/launch/jackal_world.launch` != 0 ]; then
  echo "--- Setting up R5-COP demo world in the global config..."
  sed -i 's/"[^"]*jackal_race.world/"\/root\/NLdemo\/r5cop_world.sdf/' /opt/ros/indigo/share/jackal_gazebo/launch/jackal_world.launch
  echo done.
else
  echo "R5-COP demo world is ready."
fi

if [ ! -x /usr/bin/java ]; then
  echo -n "--- Installing Oracle Java8..."
  apt-get -qqy install software-properties-common python-software-properties
  apt-add-repository -y ppa:webupd8team/java && apt-get -qq update
  echo "(this will take more time)..."
  apt-get -qqy install oracle-java8-installer oracle-java8-set-default
  ln -s /usr/lib/jvm/java-8-oracle /usr/lib/jvm/default-java
  echo done.
else
  echo "Java is installed."
fi

if [ ! -f AgentInterface/AgentInterface.jar ]; then
  echo "--- Installing R5-COP demo agents..."
  sleep 3
  wget -q http://r5cop.mit.bme.hu/AgentInterface.zip
  unzip -q AgentInterface.zip && rm AgentInterface.zip
# TODO build the agents...
#  git clone https://github.com/bme-mit-r5cop/wp24-agentinterface.git
  echo done.
else
  echo "R5-COP demo agents are installed."
fi

if [ ! -x /usr/bin/gazebo ] || [ ! -d /opt/ros/indigo ] || [ ! -f ~/jackal_navigation/devel/setup.bash ] || [ `grep -c jackal_race /opt/ros/indigo/share/jackal_gazebo/launch/jackal_world.launch` != 0 ] || [ ! -x /usr/bin/java ] || [ ! -f AgentInterface/AgentInterface.jar ]; then
  echo "Setup failed."
else
  echo "Setup seems to be fine."
  touch .setup_ok
fi

