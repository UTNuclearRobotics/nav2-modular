FROM osrf/ros:humble-desktop-full-jammy

ARG CONFIG=bagheera
ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=humble

# Install tools needed for building
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-vcstool \
    python3-colcon-common-extensions \
    python3-rosdep \
    git \
    ros-${ROS_DISTRO}-navigation2 \
    ros-${ROS_DISTRO}-nav2-bringup \
    ros-${ROS_DISTRO}-slam-toolbox \
    ros-${ROS_DISTRO}-gz-ros2-control \
    ros-${ROS_DISTRO}-rmw-cyclonedds-cpp \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

# Force HTTPS for public repos
RUN git config --global url."https://github.com/".insteadOf "git@github.com:"

# Create workspace
WORKDIR /ros2_ws
RUN mkdir -p src

# Copy the recursive import script + configs
COPY vcs-recursive-import.sh /tmp/
RUN chmod +x /tmp/vcs-recursive-import.sh
COPY repos/ /tmp/repos/
COPY repos/${CONFIG}.yaml /tmp/active-repos.yaml

# Clone repositories (vcs import usually uses https → no ssh needed here)
RUN echo "Cloning repositories..." \
 && /tmp/vcs-recursive-import.sh /tmp/active-repos.yaml

# Update submodules — build fails if any repo fails to update
RUN echo "Final submodule check..." \
 && find /ros2_ws/src -name .gitmodules -print0 | while IFS= read -r -d '' gitmodules; do \
      repo_dir="$(dirname "$gitmodules")"; \
      (cd "$repo_dir" \
        && git submodule update --init --recursive --quiet \
        || { echo "ERROR: submodule update failed in $repo_dir"; exit 1; } \
      ); \
    done

# Install dependencies
RUN apt-get update && \ 
    rosdep update && \
    rosdep install --from-paths src --ignore-src --rosdistro ${ROS_DISTRO} -y -r \
        --skip-keys "gz-transport12 gz-sim7 gz-math7 gz-msgs9"

# Build workspace
RUN /bin/bash -c "\
    source /opt/ros/humble/setup.bash && \
    colcon build \
        --symlink-install \
        --packages-skip husarion_ugv_gazebo \
        --cmake-args \
            -DCMAKE_BUILD_TYPE=Release \
            -DBUILD_TESTING=OFF \
    "

# Clean up to reduce image size
RUN rm -rf /tmp/active-repos.yaml /tmp/repos /tmp/vcs-recursive-import.sh \
    && rm -rf build/*/CMakeCache.txt \
    && find build/ -type d -name CMakeFiles -exec rm -rf {} + 2>/dev/null || true

# Automatically source workspace in interactive shells
RUN echo "source /ros2_ws/install/setup.bash" >> /etc/bash.bashrc

# Entrypoint — only launch, no cloning/building
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]