pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = '879786010528'

        FRONTEND_ECR = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/nutriflow-frontend"
        BACKEND_ECR = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/nutriflow-backend"

        BACKEND_URL = 'http://a8bc232085aab4f68ad617173d1bf692-49272255.us-east-1.elb.amazonaws.com:8000/nutriflow'

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
                      -t nutriflow-backend:${BUILD_NUMBER} \
                      ./backend
                '''
            }
        }

        stage('Build Frontend') {
            steps {
                sh '''
                    docker build \
                      --build-arg VITE_API_URL=$BACKEND_URL \
                      -t nutriflow-frontend:${BUILD_NUMBER} \
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
                    docker tag nutriflow-backend:${BUILD_NUMBER} \
                      $BACKEND_ECR:${BUILD_NUMBER}

                    docker tag nutriflow-frontend:${BUILD_NUMBER} \
                      $FRONTEND_ECR:${BUILD_NUMBER}

                    docker push $BACKEND_ECR:${BUILD_NUMBER}
                    docker push $FRONTEND_ECR:${BUILD_NUMBER}
                '''
            }
        }

        stage('Update GitOps Manifests') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'github',
                        usernameVariable: 'GIT_USERNAME',
                        passwordVariable: 'GIT_TOKEN'
                    )
                ]) {
                    sh '''
                        git config user.name "Jenkins"
                        git config user.email "jenkins@nutriflow.local"

                        sed -i "s|nutriflow-backend:latest|nutriflow-backend:${BUILD_NUMBER}|g" \
                          k8s/backend/backend-deployment.yaml

                        sed -i "s|nutriflow-frontend:latest|nutriflow-frontend:${BUILD_NUMBER}|g" \
                          k8s/frontend/frontend-deployment.yaml

                        git add k8s/backend/backend-deployment.yaml \
                                k8s/frontend/frontend-deployment.yaml

                        git commit -m "Update NutriFlow images to build ${BUILD_NUMBER}" || true

                        git remote set-url origin \
                          https://${GIT_USERNAME}:${GIT_TOKEN}@github.com/karthikpillai713/nutriflow-app.git

                        git push origin HEAD:main
                    '''
                }
            }
        }
    }
}
