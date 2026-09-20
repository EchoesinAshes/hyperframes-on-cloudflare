# Extract only the target platform's FFprobe binary.
FROM node:22-bookworm-slim AS ffprobe-builder

WORKDIR /ffprobe-build

RUN npm install --no-audit --no-fund --omit=dev ffprobe-static@3.1.0 \
  && mkdir -p /out \
  && cp "$(node -p "require('ffprobe-static').path")" /out/ffprobe \
  && chmod +x /out/ffprobe \
  && /out/ffprobe -version

# Runtime image.
FROM node:22-bookworm-slim

# Chromium runtime libraries.
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libcairo2 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libglib2.0-0 \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libx11-6 \
    libxcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    wget \
    xdg-utils \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY container/package.json ./package.json

# Install renderer dependencies and discard npm's download cache
# within the same layer.
RUN npm install --no-audit --no-fund --omit=dev \
  && ln -sf /app/node_modules/ffmpeg-static/ffmpeg /usr/local/bin/ffmpeg \
  && /usr/local/bin/ffmpeg -version \
  && npm cache clean --force

# Copy only FFprobe, in a separate upload layer.
COPY --from=ffprobe-builder /out/ffprobe /usr/local/bin/ffprobe

RUN /usr/local/bin/ffprobe -version

COPY container/server.mjs ./server.mjs

ENV PORT=8080
EXPOSE 8080

CMD ["node", "server.mjs"]
