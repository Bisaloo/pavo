FROM rocker/tidyverse:devel

## Download and install RStudio server & dependencies
## Attempts to get detect latest version, otherwise falls back to version given in $VER
## Symlink pandoc, pandoc-citeproc so they are available system-wide
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    libmagic-dev \
    libmagick++-dev \
    imagemagick \
    libgl1-mesa-dev \
    zlib1g-dev \
    pandoc pandoc-citeproc \
    libglu1-mesa-dev \
    libpng-dev
