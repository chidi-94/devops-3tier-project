pipeline {
    agent any

    options {
        timestamps()
    }

    environment {
        DOCKER_HOST = 'tcp://docker:2376'
        DOCKER_TLS_VERIFY = '1'
        DOCKER_CERT_PATH = '/var/jenkins_home/.docker-certs'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Format Check') {
            steps {
                sh 'terraform fmt -check -recursive'
            }
        }

        stage('Terraform Validate') {
            steps {
                sh 'terraform init -backend=false -input=false'
                sh 'terraform validate'
            }
        }

        stage('Python Syntax Check') {
            steps {
                sh 'python3 -m py_compile app/app.py'
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t devops-3tier-app:${BUILD_NUMBER} ./app'
            }
        }
    }

    post {
        success {
            echo 'CI pipeline completed successfully.'
        }

        failure {
            echo 'CI pipeline failed. Check the stage logs.'
        }
    }
}
