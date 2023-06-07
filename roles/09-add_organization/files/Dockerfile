FROM ubuntu:20.04
RUN apt update 
RUN DEBIAN_FRONTEND=noninteractive apt install -yq openvpn iputils-ping iproute2 git curl ssh python3.8-venv wget libmariadb-dev xvfb python3-xvfbwrapper libgtk-3-0 libdbus-glib-1-2 firefox mysql-client-core-8.0 python3-pip && \
    pip3 install paramiko scp selenium pyaml filetype mysql-connector-python pymysql mysqlclient pandas mouse && \
    cd /root/ &&  \
    wget https://github.com/mozilla/geckodriver/releases/download/v0.30.0/geckodriver-v0.30.0-linux64.tar.gz && \
    tar -xvf geckodriver-v0.30.0-linux64.tar.gz -C /usr/local/bin/ && \
    rm -f geckodriver-v0.30.0-linux64.tar.gz

COPY add_organization.py /root/add_organization.py
COPY run.sh /root/run.sh 
CMD ["/bin/bash", "/root/run.sh"]

