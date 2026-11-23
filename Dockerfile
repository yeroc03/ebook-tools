# ebook-tools with a current calibre: every script in this repository, plus
# calibre's command-line tools (calibredb, ebook-meta, fetch-ebook-metadata,
# ebook-convert) and the OCR and document tools the scripts use.
#
#   docker build -t ebook-tools .
#   docker run --rm --user "$(id -u):$(id -g)" -v "$PWD:/books" -w /books \
#       ebook-tools organize-ebooks.sh --output-folder=organized unorganized/
#
# Published as ghcr.io/yeroc03/ebook-tools by .github/workflows/docker.yml.
#
# What changed from the original Dockerfile, and why:
# - Debian stable instead of sid, and no python-lxml (Python 2, gone from
#   Debian): the original no longer builds.
# - No Goodreads or WorldCat plugins: both services have shut their APIs
#   down. calibre's own sources (Amazon.com, Google) do the fetching; choose
#   with ISBN_METADATA_FETCH_ORDER.
# - No ENTRYPOINT: any tool in the image runs directly (organize-ebooks.sh,
#   calibredb ...), and plain `docker run -it` gives bash.
# - No fixed user: it runs as whatever --user it's given, with HOME=/tmp so
#   calibre can keep its settings whoever that is.
# - The scripts are copied from this repository, not downloaded, so an
#   image is exactly the commit it was built from.
FROM debian:trixie-slim

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      calibre file bash coreutils gawk sed grep p7zip-full \
      tesseract-ocr tesseract-ocr-osd tesseract-ocr-eng \
      poppler-utils catdoc djvulibre-bin ca-certificates \
 && rm -rf /var/lib/apt/lists/*

COPY *.sh /ebook-tools/
RUN chmod a+rx /ebook-tools/*.sh

ENV PATH="${PATH}:/ebook-tools" \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    QT_QPA_PLATFORM=offscreen \
    HOME=/tmp

LABEL org.opencontainers.image.source="https://github.com/yeroc03/ebook-tools" \
      org.opencontainers.image.description="ebook-tools (na--/ebook-tools) with a current calibre" \
      org.opencontainers.image.licenses="GPL-3.0-only"

WORKDIR /ebook-tools
RUN command -v organize-ebooks.sh calibredb ebook-meta fetch-ebook-metadata ebook-convert \
      tesseract pdftotext catdoc djvutxt 7z
CMD ["bash"]
