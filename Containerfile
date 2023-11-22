FROM ubuntu

# Set environment variables for non-interactive APT installs
ENV DEBIAN_FRONTEND=noninteractive
ENV APT_LISTCHANGES_FRONTEND=none
ENV APT_LISTBUGS_FRONTEND=none

# Preconfigure timezone for tzdata
RUN echo 'tzdata tzdata/Areas select America' | debconf-set-selections
RUN echo 'tzdata tzdata/Zones/America select New_York' | debconf-set-selections

# Update and install packages non-interactively
RUN apt update && apt install -y --no-install-recommends ca-certificates tzdata curl sudo ubuntu-minimal

# Add your user and set up sudo
RUN useradd -m tester && echo "tester:tester" | chpasswd
RUN adduser tester sudo

# Clean up APT when done
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

USER tester
WORKDIR /home/tester

