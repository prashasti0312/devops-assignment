# Part 1. Build

A basic web application has been deployed using nginx web server. Please find the Dockerfile inside cyware-assignment folder. Docker image has been pushed to Docker Hub (URL - https://hub.docker.com/r/prashii0312/cyware-assignment)

# Part 2. Infrastructure Provisioning

A terraform script to provision VPC, Subnets, EC2, ALB and security Groups has been added in a subdirectory named terraform-scripts.

# Part 3. Deployment

The directory also contains a docker-compose file to deploy the docker image created in Part 1. Jenkins groovy scripted pipeline for the running the docker-compose file on EC2 instance has also been added.
