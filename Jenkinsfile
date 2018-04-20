pipeline {
    agent any

    stages {
        stage('Prerun Diag') {
            steps {
                sh 'pwd'
            }
        }
        stage('Setup') {
            steps {
                sh 'echo "No setup"'
            }
        }
        stage('Build') {
            steps {
                script {
                    sh '''
wget -qO- http://dl.gawati.org/dev/jenkinslib-latest.tbz | tar -xvjf -
. ./jenkinslib.sh
makebuild
'''
                }
            }
        }
        stage('Upload') {
            steps {
                script {
                    sh '''
. ./jenkinslib.sh
cd build
PkgXar
PkgLinkLatest
'''
                }
            }
        }
        stage('Clean') {
            steps {
                cleanWs(cleanWhenAborted: true, cleanWhenNotBuilt: true, cleanWhenSuccess: true, cleanWhenUnstable: true, cleanupMatrixParent: true, deleteDirs: true)
            }
        }
    }

    post {
        always {
            slackSend (message: "${currentBuild.currentResult}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
        }
        failure {
            slackSend (channel: '#failure', message: "${currentBuild.currentResult}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
        }
        unstable {
            slackSend (channel: '#failure', message: "${currentBuild.currentResult}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
        }
    }
}
