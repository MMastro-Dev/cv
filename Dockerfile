# ── Stage 1: Build ────────────────────────────────────────────────────────────
# Uses the official hugomods Hugo Extended image (same approach as mastroblog).
# Chromium is added on top for PDF generation.
FROM hugomods/hugo:exts AS builder

# Pass your public domain so Hugo generates correct canonical URLs.
# Override at build time: --build-arg BASE_URL=https://cv.example.com
ARG BASE_URL=http://localhost:8080

RUN apk add --no-cache chromium

WORKDIR /src
COPY . .

RUN hugo --gc --minify --baseURL "${BASE_URL}"

# PDF generation is best-effort; warns and continues if Chromium fails.
RUN chromium-browser --headless --disable-gpu --no-sandbox \
      --run-all-compositor-stages-before-draw \
      --print-to-pdf=/src/public/cv.pdf \
      --print-to-pdf-no-header \
      "file:///src/public/index.html" 2>/dev/null \
    || echo "WARNING: PDF generation skipped"

# ── Stage 2: Serve ────────────────────────────────────────────────────────────
# Copies only the built static files into a minimal nginx image.
FROM nginx:alpine AS server

COPY --from=builder /src/public /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
