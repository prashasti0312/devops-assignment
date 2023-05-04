pipeline {
    agent any
    environment {
        AWS_REGION = "ap-south-1"
        TF_WORKING_DIR = "/var/jenkins_home/terraform"
        DOCKER_COMPOSE_FILE = "/var/jenkins_home/docker-compose.yml"
    }
    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/prashasti0312/devops-assignment'
            }
        }
        stage('Terraform Apply') {
            steps {
                sh "mkdir -p ${TF_WORKING_DIR}"
                sh "terraform init -input=false ${TF_WORKING_DIR}"
                sh "terraform apply -input=false -auto-approve ${TF_WORKING_DIR}"
            }
        }
        stage('Copy docker-compose.yml to EC2 instance') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'ssh-credentials', keyFileVariable: 'SSH_KEY', passphraseVariable: '', usernameVariable: 'SSH_USER')]) {
                    sshCommand remoteUser: "${SSH_USER}", remoteHost: "${terraform.output.ec2_instance_public_ip.value}", sshKey: "${SSH_KEY}", command: "mkdir -p /home/ubuntu/app && scp -i /home/${SSH_USER}/.ssh/id_rsa ${DOCKER_COMPOSE_FILE} ubuntu@${terraform.output.ec2_instance_public_ip.value}:/home/ubuntu/app/docker-compose.yml"
                }
            }
        }
        stage('SSH into EC2 instance and run docker-compose up') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'ssh-credentials', keyFileVariable: 'SSH_KEY', passphraseVariable: '', usernameVariable: 'SSH_USER')]) {
                    sshCommand remoteUser: "${SSH_USER}", remoteHost: "${terraform.output.ec2_instance_public_ip.value}", sshKey: "${SSH_KEY}", command: "cd /home/ubuntu/app && docker-compose up -d"
                }
            }
        }
    }
    post {
        always {
            sh "terraform destroy -auto-approve ${TF_WORKING_DIR}"
        }
    }
}

