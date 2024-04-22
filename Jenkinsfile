def COLOR_MAP = [
    'FAILURE' : 'danger',
    'SUCCESS' : 'good'
]

pipeline{
    agent any 
    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }
    environment {
        SCANNER_HOME=tool 'sonar-scanner'
    }
    stages {
        stage("Sonarqube Analysis "){
            steps{
                withSonarQubeEnv('sonar-server') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=gaming-hunt-12 \
                    -Dsonar.projectKey=gaming-hunt-12'''
                }
            }
        }
        stage("quality gate"){
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar-text'
                }
            }
        }
        stage("Install Npm Dependencies"){
            steps{
                sh "npm install"
            }
        }
        stage('OWASP FS SCAN') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
        stage("File System Scan"){
            steps{
                sh "trivy fs --severity HIGH,CRITICAL . "
            }
        }
        stage('Docker Scout FS') {
            steps {
                script{
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){
                        sh 'docker-scout quickview fs://.'
                        sh 'docker-scout cves fs://.'
                    }
                }
            }
        }
        stage("Docker Build & Push"){
            steps{
                script{
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){
                        sh 'docker build -t gaming-hunt:v1 .'
                        sh 'docker tag gaming-hunt:v1 amuldark/gaming-hunt:v1'
                        sh 'docker push amuldark/gaming-hunt:v1'
                }
                }
            }
        }
        stage('Trivy image scan') {
            steps {
                script{
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){
                        sh 'trivy image --severity HIGH,CRITICAL amuldark/gaming-hunt:v1'
                    }
                }
            }
        }
        stage("Run the Docker Container"){
            steps{
                script{
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){
                        sh 'docker run -d -p 3000:3000 --name=huntv1 amuldark/gaming-hunt:v1'
                    }
                }
            }
        }
        stage('Deploy to kubernets'){
            steps{
                script{
                    dir('K8S') {
                        withKubeConfig(caCertificate: '', clusterName: '', contextName: '', credentialsId: 'k8s', namespace: '', restrictKubeConfigAccess: false, serverUrl: '') {
                                sh 'kubectl apply -f deployment.yml'
                                sh 'kubectl apply -f service.yml'
                        }
                    }
                }
            }
        }

    }
    post {
    always {
        echo 'Slack Notifications'
        slackSend (
            channel: '#jenkins',   
            color: COLOR_MAP[currentBuild.currentResult],
            message: "*${currentBuild.currentResult}:* Job ${env.JOB_NAME} \n build ${env.BUILD_NUMBER} \n More info at: ${env.BUILD_URL}"
        )
    }
}
}
