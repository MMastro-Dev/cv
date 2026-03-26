# ── Stage 1: Build ────────────────────────────────────────────────────────────
# Installs Hugo Extended + Chromium, builds the site and generates the PDF.
FROM debian:bookworm-slim AS builder

ARG HUGO_VERSION=0.159.0
# Pass your public domain so Hugo generates correct canonical URLs.
# Override at build time: --build-arg BASE_URL=https://cv.example.com
ARG BASE_URL=http://localhost:8080

RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends \
      curl tar ca-certificates chromium && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL \
    "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz" \
    | tar xz -C /usr/local/bin hugo

WORKDIR /site
COPY . .

RUN hugo --gc --minify --baseURL "${BASE_URL}"

# PDF generation is best-effort; warns and continues if Chromium fails.
RUN chromium --headless --disable-gpu --no-sandbox \
      --run-all-compositor-stages-before-draw \
      --print-to-pdf=/site/public/cv.pdf \
      --print-to-pdf-no-header \
      "file:///site/public/index.html" 2>/dev/null \
    || echo "WARNING: PDF generation skipped"

# ── Stage 2: Serve ────────────────────────────────────────────────────────────
# Copies only the built static files into a minimal nginx image.
FROM nginx:alpine AS server

COPY --from=builder /site/public /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
