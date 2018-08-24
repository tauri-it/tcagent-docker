#Pull the base image
FROM ubuntu:16.04

ENV TCAGENTUSER=tcagent
ENV DOCKERVERSION=1.21.2
ENV TCHOSTURL=""
ENV AGENT_NAME=""

# Install dependencies
# Install docker-ce and docker-compose
RUN export DEBIAN_FRONTEND=noninteractive && \
    sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
    apt-get update && apt-get install -y --no-install-recommends\
    build-essential \
    wget \
    unzip && \ 
    apt-get remove docker docker.io && \
    apt-get install -y --no-install-recommends\
    apt-transport-https \
    ca-certificates \
    curl \
    libcurl3 \
    software-properties-common -y && \
    DEBIAN_FRONTEND=noninteractive curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    DEBIAN_FRONTEND=noninteractive add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable" && \
    apt-get update -y && apt-get -y install docker-ce && \
    curl -L https://github.com/docker/compose/releases/download/${DOCKERVERSION}/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose && \
    systemctl enable docker && \
# Add Agent User and add to docker group
    useradd -ms /bin/bash ${TCAGENTUSER} && \
    usermod -a -G docker root && \
    usermod -a -G docker ${TCAGENTUSER} && \
    usermod -a -G sudo ${TCAGENTUSER}

# Install JAVA for build agent
# Make the directory to share the nuget volume and house buildAgent config and some scripts
RUN apt-get --assume-yes install --no-install-recommends openjdk-8-jre-headless && \
    mkdir -p /home/${TCAGENTUSER}/.nuget/NuGet/ && \
    mkdir /home/${TCAGENTUSER}/buildAgent \
    /home/${TCAGENTUSER}/scripts

# Copy and Add Configs
COPY agent_autostart/buildAgent /etc/init.d
COPY agent_autostart/agent_start.sh /home/${TCAGENTUSER}/scripts
COPY agent_autostart/startdocker.sh /home/${TCAGENTUSER}/scripts
COPY buildAgent.zip /home/${TCAGENTUSER}/buildAgent
# Run installs for buildAgent
WORKDIR /home/${TCAGENTUSER}/buildAgent
RUN unzip /home/${TCAGENTUSER}/buildAgent/buildAgent.zip && \
    rm -rf *.zip
COPY buildAgent.properties /home/${TCAGENTUSER}/buildAgent/conf/
RUN chown -R ${TCAGENTUSER}:${TCAGENTUSER} /home/${TCAGENTUSER} && \
    chmod -R 755 /home/${TCAGENTUSER} && \
    chmod 755 /etc/init.d/buildAgent \
    /home/${TCAGENTUSER}/scripts/agent_start.sh && \
    sed -i -e 's/\r//g' /etc/init.d/buildAgent && \
    sed -i -e 's/\r//g' /home/${TCAGENTUSER}/scripts/agent_start.sh && \
    update-rc.d buildAgent defaults && \
    apt-get -y remove --purge curl wget unzip  && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/*

# Set work directory
WORKDIR /home/${TCAGENTUSER}/

# Start the agent
CMD ["./scripts/agent_start.sh"]

#USER ${TCAGENTUSER}