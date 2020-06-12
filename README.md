# Sample CI/CD with Packer and Jenkins

## Specifications

### Background

* The application is a golang application.
* The application has already been compiled for windows, linux and osx and the binaries are available in the `app/bin` directory. Compiling or modifying the application is not part of the test, you can assume the binary will be available under `app/bin` and write the scripts to deploy that binary.
* The application listens on port 8080 by default and exposes the following 3 endpoints:
    * `/` serve the HTML home page
    * `/health` basic health check returning 200 OK
    * `/ws` simple endpoint for websocket communication (optional)

## DevOps info

* Jenkins server
    * The `Amazon Elastic Container Service (ECS) / Fargate` should be installed and configured
    * The `Amazon Elastic Container Service (ECS) / Fargate` should have one slave configured with the docker image which is in the `jenkins-docker` directory in this project
    * A Jenkins pipeline should be configured with this Git repository
    * The jenkins slave should have permissions to destination AWS account

## Project structure

There are 4 directories in this project

1. app - contains the app binaries
2. cd - contains the deployment code, scripts and utilities which are being used in the deployment process.
3. packer - contains the packer contents of the final AMI and some utilities
4. jenkins-docker - container the docker files for the Jenkins server; those images should be built and pushed to the AWS ECR and configured in Jenkins, those images contains common tools and utilities.


## Build and deployment process

The process is fully automated -  once a commit has been pushed to the master branch in  the configured Github repository  in the Jenkins pipeline - the AMI build and deployment is happening.

The deployment is being achieved with `Cloudformation` 

There's a foundation docker image which the Jenkins pipeline is running on - this image is based on the Jenkins `jnlp` image which contains the jenkins agent so it'll be able to communicate with the master, on top of that it contains some custom utilities and installed packages such as:
1. A script for the cloudformation deployment
2. Packer
3. AWS ClI
4. And more...

Here's a summary of the Jenkins Pipeline:
* The pipeline is building the packer AMI
* The created AMI ID(s) breing pushed to AWS Parameter store `PARAMETER_NAME="/DeploymentConfig/${ENVIRONMENT}/App/AmiId"`
* The Deployment process is starting
    * The parameters for the main cloudformation template are being generated  - the AMI ID and some more parameters.
    * The templates are being synced to pre-created S3 bucket which holds the infrastructure code
    * The pipeline is triggering the cloudformation script `deploy-wrapper.sh` which is triggering the cloudformation utility which baked into the docker container (where the pipeline is running on)



