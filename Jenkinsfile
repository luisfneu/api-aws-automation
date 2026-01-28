pipeline {
    agent any

    environment {
        AWS_REGION      = 'us-east-1'
        ECR_REPO        = 'api-node'
        ECR_URL         = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_TAG       = "${env.BUILD_NUMBER}"
        DOCKER_CONTEXT  = './app'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('ECR Login') {
            steps {
                sh """
                    aws ecr get-login-password --region ${AWS_REGION} \
                        | docker login --username AWS --password-stdin ${ECR_URL}
                """
            }
        }

        stage('Build') {
            steps {
                sh "docker build -t ${ECR_REPO}:${IMAGE_TAG} ${DOCKER_CONTEXT} --platform linux/amd64"
            }
        }

        stage('Tag') {
            steps {
                sh "docker tag ${ECR_REPO}:${IMAGE_TAG} ${ECR_URL}/${ECR_REPO}:${IMAGE_TAG}"
                sh "docker tag ${ECR_REPO}:${IMAGE_TAG} ${ECR_URL}/${ECR_REPO}:latest"
            }
        }

        stage('Push') {
            steps {
                sh "docker push ${ECR_URL}/${ECR_REPO}:${IMAGE_TAG}"
                sh "docker push ${ECR_URL}/${ECR_REPO}:latest"
            }
        }
    }

    post {
        always {
            sh "docker rmi ${ECR_REPO}:${IMAGE_TAG} || true"
            sh "docker rmi ${ECR_URL}/${ECR_REPO}:${IMAGE_TAG} || true"
            sh "docker rmi ${ECR_URL}/${ECR_REPO}:latest || true"
        }
    }
}
