#!/bin/bash
set -e

# Variables from Terraform
GITHUB_REPO=${1:-"dotnet/dotnet-docker"}
GITHUB_BRANCH=${2:-"main"}

# Clone the GitHub repository
git clone --depth 1 --branch $GITHUB_BRANCH https://github.com/$GITHUB_REPO.git
cd $(basename $GITHUB_REPO)/samples/aspnetapp

# Restore and build the .NET application
dotnet restore
dotnet build --configuration Release
