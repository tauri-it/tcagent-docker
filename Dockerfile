#Pull the base image
FROM ubuntu:16.04

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
    software-properties-common -y && \
    DEBIAN_FRONTEND=noninteractive curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    DEBIAN_FRONTEND=noninteractive add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable" && \
    apt-get update -y && apt-get -y install docker-ce && \
    curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose && \
    usermod -a -G docker root

# Install JAVA for build agent
# Make the directory to share the nuget volume and house buildAgent config and some scripts
RUN apt-get --assume-yes install --no-install-recommends openjdk-8-jre-headless && \
    mkdir -p /root/.nuget/NuGet/ && \
    mkdir /root/buildAgent \
    /root/scripts

# Copy and Add Configs
COPY agent_autostart/buildAgent /etc/init.d
COPY agent_autostart/agent_start.sh /root/scripts
COPY buildAgent.zip /root/buildAgent
# Run installs for buildAgent
WORKDIR /root/buildAgent
RUN unzip /root/buildAgent/buildAgent.zip && \
    rm -rf *.zip
COPY buildAgent.properties /root/buildAgent/conf/
RUN chmod -R 755 /root/buildAgent && \
    chmod 755 /etc/init.d/buildAgent \
    /root/scripts/agent_start.sh && \
    sed -i -e 's/\r//g' /etc/init.d/buildAgent && \
    sed -i -e 's/\r//g' /root/scripts/agent_start.sh && \
    update-rc.d buildAgent defaults && \
    apt-get -y remove --purge curl wget unzip  && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* 
# Set work directory
WORKDIR /root/

# Start the agent
CMD ["./scripts/agent_start.sh"]