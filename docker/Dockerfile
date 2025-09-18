FROM debian:bookworm-slim

# Installing Chromium and its drivers from the official Debian 12 repository
RUN apt-get update && apt-get install -y \
    python3 python3-pip \
    chromium chromium-driver \
    wget curl unzip sudo iproute2 tcpdump \
    --no-install-recommends && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ENV CHROME_BIN="/usr/bin/chromium"

WORKDIR /app
COPY . /app

RUN pip install --break-system-packages --no-cache-dir selenium

RUN chmod +x /app/*.sh
RUN mkdir -p /app/data

ENTRYPOINT ["/bin/bash"]
