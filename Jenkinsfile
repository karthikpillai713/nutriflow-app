pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = '879786010528'

        FRONTEND_ECR = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/nutriflow-frontend"
        BACKEND_ECR = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/nutriflow-backend"

        EKS_CLUSTER = 'nutriflow-cluster'
        K8S_NAMESPACE = 'nutriflow'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Backend') {
            steps {
                sh '''
                    docker build \
                      -t nutriflow-backend:latest \
                      ./backend
                '''
            }
        }

        stage('Build Frontend') {
            steps {
                sh '''
                    docker build \
                      --build-arg VITE_API_URL=http://ac4d637ac01aa418396afc36e5c31648-200224050.us-east-1.elb.amazonaws.com:8000/nutriflow \
                      -t nutriflow-frontend:latest \
                      ./frontend
                '''
            }
        }

        stage('Login to ECR') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                     credentialsId: 'aws-credentials']
                ]) {
                    sh '''
                        aws ecr get-login-password --region $AWS_REGION | \
                        docker login --username AWS --password-stdin \
                        $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
                    '''
                }
            }
        }

        stage('Push Images') {
            steps {
                sh '''
                    docker tag nutriflow-backend:latest $BACKEND_ECR:latest
                    docker tag nutriflow-frontend:latest $FRONTEND_ECR:latest

                    docker push $BACKEND_ECR:latest
                    docker push $FRONTEND_ECR:latest
                '''
            }
        }

        stage('Deploy to EKS') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                     credentialsId: 'aws-credentials']
                ]) {
                    sh '''
                        aws eks update-kubeconfig \
                          --region $AWS_REGION \
                          --name $EKS_CLUSTER

                        kubectl set image deployment/nutriflow-backend \
                          backend=$BACKEND_ECR:latest \
                          -n $K8S_NAMESPACE

                        kubectl set image deployment/nutriflow-frontend \
                          frontend=$FRONTEND_ECR:latest \
                          -n $K8S_NAMESPACE

                        kubectl rollout status deployment/nutriflow-backend \
                          -n $K8S_NAMESPACE

                        kubectl rollout status deployment/nutriflow-frontend \
                          -n $K8S_NAMESPACE
                    '''
                }
            }
        }
    }
}
