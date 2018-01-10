pipeline {
    agent any

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
}
