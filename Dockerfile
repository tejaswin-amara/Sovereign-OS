# Ubuntu-based Sovereign OS Container
FROM mcr.microsoft.com/powershell:lts-ubuntu-22.04

# Set noninteractive for apt
ENV DEBIAN_FRONTEND=noninteractive

# Install core dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    sqlite3 \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Create Sovereign workspace
WORKDIR /opt/sovereign

# Copy the entire Sovereign ecosystem
COPY . .

# Set default pwsh shell profile and execution policy
SHELL ["pwsh", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Install Pester globally for testing
RUN Install-Module -Name Pester -Force -SkipPublisherCheck -AcceptLicense

# Set the default entrypoint to the Sovereign Master Controller
ENTRYPOINT ["pwsh", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "sovereign.ps1"]
