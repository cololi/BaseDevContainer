FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Shanghai \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    # 用户设置
    USER_NAME=devuser \
    USER_UID=1001 \
    # 软件版本
    JDK_VERSION=17.0.12 \
    NODE_VERSION=18.20.8 \
    NODE_DIR=node-v18.20.8

# 使用清华源替换默认源
RUN sed -i 's@archive.ubuntu.com@mirrors.tuna.tsinghua.edu.cn@g' /etc/apt/sources.list && \
    sed -i 's@security.ubuntu.com@mirrors.tuna.tsinghua.edu.cn@g' /etc/apt/sources.list

# 安装基础工具和 SSH 服务
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openssh-server \
        sudo \
        curl \
        wget \
        vim \
        net-tools \
        iputils-ping \
        ca-certificates \
        software-properties-common \
        gnupg \
        gosu \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 创建用户
RUN groupadd -g 1001 $USER_NAME && useradd --uid $USER_UID --gid 1001 -m -s /bin/bash $USER_NAME && \
    echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USER_NAME && \
    chmod 0440 /etc/sudoers.d/$USER_NAME

# 配置 SSH
RUN mkdir /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd && \
    echo "AllowUsers $USER_NAME" >> /etc/ssh/sshd_config

# 安装 JDK 17
COPY jdk-17.0.12_linux-x64_bin.deb /tmp/jdk.deb
RUN apt-get update && \
    apt-get install -y /tmp/jdk.deb && \
    rm /tmp/jdk.deb

# 安装 Node.js 18
COPY $NODE_DIR/ /usr/local/nodejs-18
RUN ln -s /usr/local/nodejs-18/bin/node /usr/local/bin/node
RUN ln -s /usr/local/nodejs-18/bin/npm /usr/local/bin/npm
RUN ln -s /usr/local/nodejs-18/bin/npx /usr/local/bin/npx

RUN mkdir -p /home/$USER_NAME/.ssh && \
    chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.ssh && \
    chmod 700 /home/$USER_NAME/.ssh

EXPOSE 22

# 启动脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 切换到普通用户
USER $USER_NAME
WORKDIR /home/$USER_NAME

# 验证安装
RUN java -version && \
    node -v && \
    npm -v

ENTRYPOINT ["/entrypoint.sh"]