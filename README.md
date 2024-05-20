# ft_linux

Make your own linux distribution

## Introduction

This project is about creating a linux distribution from scratch. The goal is to understand how a linux distribution is built and how it works. The project is divided into several parts, each part is a step in the creation of the distribution.

## Prerequisites

- A linux distribution (Debian, Ubuntu, Fedora, Archlinux, etc.)
- A virtual machine (VirtualBox, Vmware, etc.)
- A linux distribution to build (LFS, Gentoo, etc.)
- A lot of time

## Steps

0. Fill disk configuration inside `/config/disk.conf` & `/config/kernel.conf`
1. Run `setup.sh` to set variables
2. Run `init.sh` to initialize the environment
