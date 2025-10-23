pipeline {
  agent any

  environment {
    DOCKER_HOST = "tcp://host.docker.internal:2375"

    APP_NAME     = "practice-app-01"
    IMAGE_LATEST = "${APP_NAME}:latest"
    IMAGE_SHA    = "${APP_NAME}:sha-${env.GIT_COMMIT}"

    CONTAINER = "${APP_NAME}"
    PORT_HOST = "8081"   // cambiá si necesitás otro
    PORT_CONT = "80"     // Nginx expone 80 en la imagen final
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('NPM validate (in Docker)') {
      steps {
        sh '''
          set -eux
          docker run --rm \
            -v "$PWD":/app -w /app \
            -e CI=true \
            node:20-alpine sh -lc "
              npm ci &&
              npm run build
            "
        '''
      }
    }

    stage('Docker Build') {
      steps {
        sh '''
          set -eux
          docker build -t ${IMAGE_LATEST} -t ${IMAGE_SHA} .
        '''
      }
    }

    stage('Deploy Local') {
      steps {
        sh '''
          set -eux
          docker ps -q --filter "name=${CONTAINER}" && docker stop ${CONTAINER} || true
          docker ps -aq --filter "name=${CONTAINER}" && docker rm ${CONTAINER} || true
          docker run -d --name ${CONTAINER} -p ${PORT_HOST}:${PORT_CONT} ${IMAGE_LATEST}
        '''
      }
    }
  }

  post {
    success { echo "✅ Deploy OK: http://localhost:${PORT_HOST}" }
    failure { echo "❌ Falló el pipeline." }
  }
}
