node {
    def app

    stage('Clone repository') {
        checkout scm
    }

    stage('Build image') {
        app = docker.build("nashvillest/nashvillest-hubot")
    }

    stage('Test image') {
        app.inside {
            sh 'cd /hubot'
            sh 'cp .env-dist .env'
            sh 'npm test'
        }
    }

    stage('Push image') {
        docker.withRegistry('https://registry.hub.docker.com', '5251fb33-a45a-4251-8271-b849fad23e03') {
            app.push("build-${env.BUILD_NUMBER}")
            app.push("latest")
        }
    }
}
