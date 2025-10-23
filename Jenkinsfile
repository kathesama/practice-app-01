pipeline {
  agent any

  environment {
    // Jenkins (en Docker) hablará con Docker Desktop por TCP (ya lo habilitaste)
    DOCKER_HOST = "tcp://host.docker.internal:2375"
    IMAGE       = "practice-app-01:latest"
    CONTAINER   = "practice-app-01"
    PORT_HOST   = "8081"  // cambia si querés otro puerto local
    PORT_CONT   = "80"    // Nginx expone 80 en el contenedor
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Install & Build') {
      steps {
        sh '''
          npm ci
          npm run build
        '''
      }
    }

    stage('Docker Build') {
      steps {
        sh '''
          docker build -t ${IMAGE} .
        '''
      }
    }

    stage('Deploy Local') {
      steps {
        sh '''
          # si existe una versión vieja, detener y remover
          docker ps -q --filter name=${CONTAINER} && docker stop ${CONTAINER} || true
          docker ps -aq --filter name=${CONTAINER} && docker rm ${CONTAINER} || true

          # ejecutar nueva versión
          docker run -d --name ${CONTAINER} -p ${PORT_HOST}:${PORT_CONT} ${IMAGE}
        '''
      }
    }
  }

  post {
    success {
      echo "✅ Deploy listo: http://localhost:${PORT_HOST}"
    }
    failure {
      echo "❌ Falló el pipeline."
    }
  }
}
