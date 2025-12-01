FROM ubuntu:jammy

ENV DEBIAN_FRONTEND=noninteractive
EXPOSE 8080
#EXPOSE 27017

# install package dependencies
RUN apt-get update -qq \
	&& apt-get install -qq -y \
		apt-utils \
		cron \
		curl \
		git \
		zip \
        apt-transport-https \
        ca-certificates \
        gnupg \
        python3 \
        python3-pip \
        openjdk-17-jdk \
        openjdk-17-jre \
        docker.cli

# install mangodb
RUN curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor \
    && echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list

#install kubernetes
RUN curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg \
    && chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg \
    && echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list \
    && chmod 644 /etc/apt/sources.list.d/kubernetes.list 

# install nextflow
RUN curl -s https://get.nextflow.io | bash \
    && chmod +x nextflow \
    && mkdir -p $HOME/.local/bin/ \
    && mv nextflow $HOME/.local/bin/

ENV PATH="${PATH}:/root/.local/bin"

RUN nextflow info

RUN apt-get update -qq \
    && apt-get install -qq -y kubectl mongodb-org

RUN ln -s /usr/local/bin/python3 /usr/local/bin/python
# install nextflow-api from build context
WORKDIR /opt/nextflow-api

COPY . .

# install python dependencies
RUN pip install -r requirements.txt