pipeline {
  agent any

  environment {
    // Jenkins (en Docker) habla con tu Docker Desktop por TCP 2375
    DOCKER_HOST = "tcp://host.docker.internal:2375"

    APP_NAME   = "practice-app-01"
    IMAGE_LATEST = "${APP_NAME}:latest"
    IMAGE_SHA    = "${APP_NAME}:sha-${env.GIT_COMMIT}"

    CONTAINER = "${APP_NAME}"
    PORT_HOST = "8081"  // cambia si querés otro puerto local
    PORT_CONT = "80"    // Nginx expone 80 en la imagen final
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('NPM validate (in Docker)') {
      steps {
        // Ejecuta npm dentro de un contenedor node:20-alpine; no instala nada en Jenkins
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
        // Construye la imagen usando TU Dockerfile (multi-stage: node -> nginx)
        sh '''
          set -eux
          docker build -t ${IMAGE_LATEST} -t ${IMAGE_SHA} .
        '''
      }
    }

    // (Opcional) Escaneo rápido de vulnerabilidades con Trivy
    // stage('Security scan (Trivy)') {
    //   steps {
    //     sh '''
    //       docker run --rm aquasec/trivy:latest image \
    //         --severity HIGH,CRITICAL --no-progress ${IMAGE_LATEST} || true
    //     '''
    //   }
    // }

    stage('Deploy Local') {
      steps {
        // Reemplaza el contenedor local por la nueva versión
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
    success {
      echo "✅ Deploy OK: http://localhost:${PORT_HOST}"
    }
    failure {
      echo "❌ Falló el pipeline."
    }
  }
}
