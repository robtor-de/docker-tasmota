FROM python:latest AS build1

LABEL description="Docker Container with a complete build environment for Tasmota using PlatformIO" \
      version="12.3" \
      maintainer="blakadder_" \
      organization="https://github.com/tasmota"       

# Install platformio. 
RUN pip install --upgrade --no-cache-dir pip &&\ 
    pip install --upgrade --no-cache-dir platformio

# Install full project dependencies
RUN --mount=type=bind,target=/tasmota,source=Tasmota \
    --mount=type=cache,target=/root/.cache \
    cd /tasmota &&\
    platformio upgrade &&\
    pio pkg update &&\
    pio pkg install

# Install project dependencies using a init project.
RUN --mount=type=bind,target=/init_pio_tasmota,source=init_pio_tasmota,rw \
    --mount=type=cache,target=/root/.cache \
    --mount=type=cache,target=/root/.local \
    cd /init_pio_tasmota &&\
    platformio upgrade &&\
    pio pkg update &&\
    pio pkg install &&\
    pio run &&\
    cd ../

COPY entrypoint.sh /entrypoint.sh

# Generate separate layer to minimize image size
FROM python:latest

# Install platformio.
RUN pip install --upgrade --no-cache-dir pip &&\
    pip install --upgrade --no-cache-dir platformio

# Copy from build layer to avoid inflating image size by chmod command
COPY    --from=build1 \
        --chmod=777 \
        --chown=1000:1000 \
        /root/.platformio /.platformio

COPY    --from=build1 \
        /usr/local/lib /usr/local/lib

RUN mkdir /.cache /.local &&\
    chmod -R 777 /.cache /.local

COPY    --from=build1 \
        /entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
