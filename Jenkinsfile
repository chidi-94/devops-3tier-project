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

        stage('Trivy Security Scan') {
            steps {
                sh '''
                    set -eu

                    IMAGE="devops-3tier-app:${BUILD_NUMBER}"
                    SCAN_CONTAINER="trivy-scan-${BUILD_NUMBER}"

                    rm -f image.tar trivy-report.txt

                    cleanup() {
                        docker rm -f "$SCAN_CONTAINER" >/dev/null 2>&1 || true
                        rm -f image.tar
                    }
                    trap cleanup EXIT

                    echo "Exporting image for security scanning..."
                    docker save "$IMAGE" > image.tar

                    echo "Creating Trivy scanner..."
                    docker create \
                        --name "$SCAN_CONTAINER" \
                        -v trivy-cache:/root/.cache/ \
                        aquasec/trivy:0.67.2 \
                        image \
                        --input /tmp/image.tar \
                        --scanners vuln \
                        --timeout 20m \
                        --skip-version-check \
                        --format table

                    docker cp image.tar "$SCAN_CONTAINER:/tmp/image.tar"

                    echo "Running vulnerability scan..."
                    set +e
                    docker start -a "$SCAN_CONTAINER" > trivy-report.txt 2>&1
                    SCAN_STATUS=$?
                    set -e

                    cat trivy-report.txt
                    exit "$SCAN_STATUS"
                '''
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'trivy-report.txt', allowEmptyArchive: true
        }

        success {
            echo 'CI pipeline and security scan completed successfully.'
        }

        failure {
            echo 'Pipeline failed. Check the stage logs and Trivy report.'
        }
    }
}
