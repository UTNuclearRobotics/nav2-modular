# nav2-modular
Modular ROS 2 Nav2 Docker environment for UTNRG robots.  Provides a reproducible, containerized ROS 2 setup with Nav2, pre-cloned robot-specific repositories, and support for dynamic configuration of platforms (Husarion Panther, Clearpath Warthog) and sensors (Ouster lidar, DepthAI cameras, etc.) via build-time selection.

**Quick Start Instructions**<br><br>

```bash
git clone git@github.com:UTNuclearRobotics/nav2-modular.git
```<br><br>

1. Edit config file in `Docker/repos/` directory for platform specific navigation repo and repos for hardware<br><br>

2. Modify Dockerfile ARG CONFIG to the name of your .yaml file<br>
   Example:<br>
   ```dockerfile
   ARG CONFIG=my_robot_config.yaml
   ```<br><br>

3. Make the alias script executable<br>
   ```bash
   chmod +x nav2-modular/scripts/alias
   ```<br><br>

4. Add the alias (adjust the path to match your system)<br>
   ```bash
   alias nav2='$HOME/path/to/nav2-modular/scripts/alias'
   ```<br><br>

5a. Launch simulation<br>
   ```bash
   ros2 launch husarion_ugv_gazebo simulation.launch.py
   ```<br><br>

5b. Launch hardware<br>
   ```bash
   ros2 launch utexas_panther bringup.launch.py
   ```<br><br>

6. Launch navigation + SLAM<br>
   ```bash
   ros2 launch husarion_ugv_navigation bringup_launch.py \
       slam:=true \
       observation_topic:=/ouster/ouster/points \
       slam_params_file:=/opt/ros/humble/share/slam_toolbox/config/mapper_params_online_sync.yaml \
       use_sim_time:=true
   ```<br><br>

**Important:**<br>
Make sure to set **Fixed Frame** in RViz to `map`<br>
Otherwise nav goals will not work.<br><br>