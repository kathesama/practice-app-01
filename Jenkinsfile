pipeline {
  agent any

  environment {
    DOCKER_HOST = "tcp://host.docker.internal:2375"

    APP_NAME     = "practice-app-01"
    IMAGE_LATEST = "${APP_NAME}:latest"
    IMAGE_SHA    = "${APP_NAME}:sha-${env.GIT_COMMIT}"

    CONTAINER = "${APP_NAME}"
    PORT_HOST = "8081"
    PORT_CONT = "80"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Detect paths') {
      steps {
        sh '''
          set -eux

          # Detectar carpeta con package.json (evitando node_modules)
          if [ -f package.json ]; then
            APP_DIR="."
          else
            APP_DIR="$(find . -maxdepth 3 -type f -name package.json -not -path "*/node_modules/*" -print -quit | xargs -r dirname || true)"
            [ -z "${APP_DIR}" ] && { echo "No se encontró package.json"; exit 1; }
          fi

          # Detectar carpeta con Dockerfile
          if [ -f Dockerfile ]; then
            DOCKER_CTX="."
          else
            DOCKER_CTX="$(find . -maxdepth 3 -type f -name Dockerfile -print -quit | xargs -r dirname || true)"
            [ -z "${DOCKER_CTX}" ] && { echo "No se encontró Dockerfile"; exit 1; }
          fi

          echo "APP_DIR=${APP_DIR}"         >  .ci-paths.env
          echo "DOCKER_CTX=${DOCKER_CTX}"  >> .ci-paths.env
          echo ">> APP_DIR=${APP_DIR}"
          echo ">> DOCKER_CTX=${DOCKER_CTX}"
          echo ">> Contenido APP_DIR:"
          ls -la "${APP_DIR}"
          echo ">> Contenido DOCKER_CTX:"
          ls -la "${DOCKER_CTX}"
        '''
      }
    }

    stage('NPM validate (in Docker)') {
      steps {
        sh '''
          set -eux
          . ./.ci-paths.env

          # Montar solo APP_DIR en /app
          docker run --rm \
            -v "$PWD/${APP_DIR}":/app -w /app \
            -e CI=true \
            node:20-alpine sh -lc "
              if [ -f package-lock.json ] || [ -f npm-shrinkwrap.json ]; then
                npm ci
              else
                npm install
              fi &&
              npm run build
            "
        '''
      }
    }

    stage('Docker Build') {
      steps {
        sh '''
          set -eux
          . ./.ci-paths.env

          # Build usando el contexto donde está el Dockerfile
          docker build -t ${IMAGE_LATEST} -t ${IMAGE_SHA} "${DOCKER_CTX}"
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
