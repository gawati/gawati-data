pipeline {
    agent any

//    define {
//      def COLOR_MAP = ['SUCCESS': 'good', 'FAILURE': 'danger', 'UNSTABLE': 'danger', 'ABORTED': 'danger']
//      def STATUS_MAP = ['SUCCESS': 'success', 'FAILURE': 'failed', 'UNSTABLE': 'failed', 'ABORTED': 'failed']
//    }

    environment {
        // CI="false"
        DLD="/var/www/html/dl.gawati.org/dev"
    }

    stages {
        stage('Prerun Diag') {
            steps {
                sh 'pwd'
            }
        }
        stage('Setup') {
            steps {
                sh 'ant xar'
            }
        }
        stage('Upload') {
            steps {
                sh 'ant -Ddst=$DLD provide'
                sh 'ant -Ddst=$DLD setlatest'
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
//            slackSend (color: COLOR_MAP[currentBuild.currentResult], message: "${currentBuild.currentResult}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
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
