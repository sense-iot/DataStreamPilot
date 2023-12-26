
---

# Server 

## Overview

This project implements a cloud-based solution for handling CoAP data. The server listens for CoAP data, writes it into an InfluxDB database, and visualizes the data using Grafana. The implementation utilizes **Docker for easy deployment**, and the entire system can be deployed on an AWS EC2 instance.

## Prerequisites

- AWS account with EC2 access

## Setting Up EC2 and Assigning a Public IPv6 Address

1. **Create an EC2 Instance**

   - Launch an EC2 instance with a suitable AMI (Amazon Machine Image).
   - Ensure that the instance has the necessary permissions to interact with other AWS services.

2. **Assign a Public IPv6 Address**

   - Follow the [AWS Documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-instance-addressing.html#ipv6-assign-instance) to assign a public IPv6 address to your EC2 instance.

3. **Configure Inbound Rules for CoAP**

   - Go to the AWS Management Console.
   - Navigate to the EC2 Dashboard.
   - Select your instance, go to the "Security" tab, and click on the associated Security Group.
   - In the Security Group settings, add an inbound rule for UDP at port 5683 for IPv6.

     ```plaintext
     Type: Custom UDP Rule
     Protocol: UDP
     Port Range: 5683
     Source: ::/0
     ```

     This allows incoming UDP traffic on port 5683 from any IPv6 address.
     
    - Note for Testing:
    For testing purposes, all IPv6 addresses are allowed (::/0). In a production environment, consider limiting access by applying a range of IPs.
4. **Configure Inbound Rules for Grafana**

   - Add an inbound rule for TCP at port 3000 for IPv4.

     ```plaintext
     Type: Custom TCP Rule
     Protocol: TCP
     Port Range: 3000
     Source: 0.0.0.0/0
     ```

     This allows incoming TCP traffic on port 3000 from any IPv4 address.
    - Note for Testing:
    For testing purposes, all IPv4 addresses are allowed (0.0.0.0/0). In a production environment, consider limiting access by applying a range of IPs.

## Setting up the server

## Running the CoAP Server using Docker

1. **Clone the Repository and**

   ```bash
   git clone <repository_url>
   cd <repository_directory>/src/server
   ```

2. **Install docker**

   Run the below script to install docker
   ```bash
   ./amazon_ubuntu_docker_install.sh
   ```

3. **Build and Deploy the CoAP Server, Influxdb and Grafana**

   ```bash
   docker-compose up -d
   ```

   This script builds the CoAP server Docker container and deploys it. This will also setup the Grafana dashboard visualizing time-series data and create influxdb instances as docker containers.

## Usage: Grafana with InfluxDB


1. **Access Grafana Dashboard**

   - Open your web browser and go to `http://<public-ip>:3000/`.

## InfluxDB Database Architecture

- **Database Name:** `dht`
- **Measurement Name:** `<sitename>`
