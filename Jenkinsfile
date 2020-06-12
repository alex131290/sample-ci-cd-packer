pipeline {
    agent {label 'fargate-cloudformation-packer-slave'}
    environment {
        PACKER_FILENAME="${WORKSPACE}/packer/config.json"
        PACKER_MANIFEST_FILE_PATH="${WORKSPACE}/packer_manifest.json"
        PARAMETER_NAME="/DeploymentConfig/${ENVIRONMENT}/App/AmiId"
        COMPONENT_NAME = "myapp"
        JENKINS_CF_STACK_NAME = "${COMPONENT_NAME}-${ENVIRONMENT}"
        JENKINS_CF_TEMPLATE_NAME = "master.yaml"
        JENKINS_CF_PARAMETERS_NAME = "params.json"
        AWS_REGION = "us-east-1"
        JENKINS_SETTING_AWS_REGION = "${AWS_REGION}"
        JENKINS_SETTING_ENVIRONMENT_DEPLOY = "cd/cloudformation"
        JENKINS_SETTING_CF_CAPABILITIES_NAME = "CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND"
        CF_PARAMETERS_FOLDER = "${WORKSPACE}/${JENKINS_SETTING_ENVIRONMENT_DEPLOY}/${JENKINS_SETTING_AWS_REGION}"
        CF_PARAMETERS_FILE_PATH = "${CF_PARAMETERS_FOLDER}/${JENKINS_CF_PARAMETERS_NAME}"
        JINJA_CF_PARAMS_TEMPLATE_FILE_PATH = "${WORKSPACE}/${JENKINS_SETTING_ENVIRONMENT_DEPLOY}/params.j2"
        JENKINS_SCRIPTS="${WORKSPACE}/cd/scripts/jenkins"
        S3_INFRA_BUCKET="myapp-cloudformation-infra-templates"
        TEMP_ENV_NAME_FILE="${WORKSPACE}/env.name"
    }
    options { 
        timestamps () 
        ansiColor('xterm')
    }
    stages {
        stage('Set display name') {
            steps {
                script {
                    currentBuild.displayName = "#${currentBuild.number} (deployment: ${env.ENVIRONMENT})"
                }
            }
        }
        stage ('packer-build') {
            steps {
                sh '''
                packer build ${PACKER_FILENAME}
                '''
            }
        }
        stage ('push-ami-ids-parameters') {
            steps {
                sh '''
                #!/usr/bin/env bash
                pip2 install --upgrade pip
                pip2 install -r ${WORKSPACE}/packer/scripts/utils/requirements.txt
                python2 ${WORKSPACE}/packer/scripts/utils/packer_ami_parameter_store.py push-parameter --manifest-path "$PACKER_MANIFEST_FILE_PATH" --parameter-name "$PARAMETER_NAME"
                '''
            }
        }
        stage ('create-cf-params') {
            steps {
                sh '''bash -xe ${JENKINS_SCRIPTS}/generate-cf-params-file.sh
                '''
            }
        }
        stage ('upload-cf-templates-to-s3') {
            steps {
                sh '''aws s3 sync --exclude '*' --include '*.yaml' ${JENKINS_SETTING_ENVIRONMENT_DEPLOY} s3://${S3_INFRA_BUCKET}/${COMPONENT_NAME}/${ENVIRONMENT}
                '''
            }
        }
        stage ('deploy') {
            steps {
                sh '''
                bash -xe ${JENKINS_SCRIPTS}/deploy-wrapper.sh
                '''
            }
        }
    }
}