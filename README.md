# nav2-modular
Modular ROS 2 Nav2 Docker environment for UTNRG robots.  Provides a reproducible, containerized ROS 2 setup with Nav2, pre-cloned robot-specific repositories, and support for dynamic configuration of platforms (Husarion Panther, Clearpath Warthog) and sensors (Ouster lidar, DepthAI cameras, etc.) via build-time selection.

# Setup & Configuration
> Note these steps are only required if you are setting up a new robot. If someone has already installed and built this docker image on your robot, then you can skip to the Running section below
1. Clone repo into your user workspace.
   ```shell
   git clone git@github.com:UTNuclearRobotics/nav2-modular.git
   ```
2. Edit the `<robot>.yaml` config file located in `/Docker/repos/` directory to specify your robot specific repos for navigation and hardware
3. Modify the following variable in the `Dockerfile` to match the name of your `<robot>.yaml` config file
   - `ARG CONFIG=<robot>`
4. Make the alias script executable
   ```shell
   chmod +x nav2-modular/scripts/alias
   ```
5. Create an alias for easy use
   ```shell
   echo "alias nav2='<path_to_pkg>/nav2-modular/scripts/alias'" >> ~/.bash_aliases && source ~/.bashrc
   ```
# Build and Start
1. Build the docker image (Optional)
   > Only required if the image does not already exist.
   ```shell
   nav2 build
   ```
3. Start the docker image
   ```shell
   nav2 start
   ```
   
# Running
## Husarion Panther (Bagherra)
1. Launch Simulation (Optional)
   ```shell
   nav2 shell
   ```
   ```shell
   ros2 launch husarion_ugv_gazebo simulation.launch.py
   ```
3. Launch Sensors
   ```shell
   nav2 shell
   ```
   ```shell
   ros2 launch utexas_panther sensors.launch.py
   ```
5. Launch navigation package
   ```shell
   nav2 shell
   ```
   ```shell
   ros2 launch utexas_panther bringup.launch.py namespace:=panther observation_topic_type:=laserscan slam:=True
   ```
