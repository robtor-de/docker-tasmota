FROM python:latest

LABEL description="Docker Container with a complete build environment for Tasmota using PlatformIO" \
      version="12.3" \
      maintainer="blakadder_" \
      organization="https://github.com/tasmota"       

# Install platformio. 
RUN pip install --upgrade pip &&\ 
    pip install --upgrade platformio

# Init project
COPY init_pio_tasmota /init_pio_tasmota

# Install full project dependencies
RUN --mount=type=bind,target=/tasmota,source=Tasmota \
	cd /tasmota &&\
	platformio upgrade &&\
	pio pkg update &&\
	pio pkg install

# Install project dependencies using a init project.
RUN cd /init_pio_tasmota &&\ 
    platformio upgrade &&\
    pio pkg update &&\
    pio pkg install &&\
    pio run &&\
    cd ../ &&\ 
    rm -fr init_pio_tasmota

# Save platformio caches and toolchains
RUN cp -r /root/.platformio / &&\ 
    chmod -R 777 /.platformio &&\
    mkdir /.cache /.local &&\
    chmod -R 777 /.cache /.local


COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]

