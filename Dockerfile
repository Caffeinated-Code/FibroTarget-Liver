FROM rocker/r-ver:4.6.0

LABEL org.opencontainers.image.title="Human Liver Fibrosis Single-Cell Target Discovery"
LABEL org.opencontainers.image.description="Reproducible R pipeline for liver fibrosis biomarker and target prioritization"

ENV RENV_VERSION=1.0.11
ENV RENV_PATHS_CACHE=/renv/cache

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    libcurl4-openssl-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libfribidi-dev \
    libharfbuzz-dev \
    libjpeg-dev \
    libpng-dev \
    libssl-dev \
    libtiff5-dev \
    libxml2-dev \
    pandoc \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /project

COPY renv.lock* ./
RUN R -e "install.packages('renv', repos='https://cloud.r-project.org')" \
    && if [ -f renv.lock ]; then R -e "renv::restore(prompt = FALSE)"; fi

COPY . .

CMD ["make", "all"]
