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
                sh 'ant xar'
            }
        }
        stage('Upload') {
            steps {
                sh 'ant -Ddst=/var/www/html/dl.gawati.org/dev provide'
            }
        }
        stage('Clean') {
            steps {
                cleanWs(cleanWhenAborted: true, cleanWhenNotBuilt: true, cleanWhenSuccess: true, cleanWhenUnstable: true, cleanupMatrixParent: true, deleteDirs: true)
            }
        }
    }
}
