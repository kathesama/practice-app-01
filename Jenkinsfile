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

    stage('Detect project dir') {
      steps {
        script {
          // Busca package.json en raíz; si no, en subcarpetas (máx profundidad 2)
          env.PROJ_DIR = sh(
            script: '''
              set -e
              if [ -f package.json ]; then
                echo .
              else
                d=$(find . -maxdepth 2 -type f -name package.json -not -path "./node_modules/*" -printf "%h" -quit || true)
                if [ -z "$d" ]; then
                  echo "ERROR: No se encontró package.json en la raíz ni a 2 niveles." >&2
                  exit 1
                fi
                echo "$d"
              fi
            ''',
            returnStdout: true
          ).trim()

          echo "📁 PROJ_DIR detectado: ${env.PROJ_DIR}"
          sh "ls -la ${env.PROJ_DIR}"
        }
      }
    }

    stage('NPM validate (in Docker)') {
      steps {
        sh '''
          set -eux
          docker run --rm \
            -v "$PWD/${PROJ_DIR}":/app -w /app \
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
          # Si el Dockerfile está en PROJ_DIR úsalo; si no, usa el de la raíz
          DOCKERFILE="Dockerfile"
          CONTEXT="."
          if [ -f "${PROJ_DIR}/Dockerfile" ]; then
            DOCKERFILE="${PROJ_DIR}/Dockerfile"
            CONTEXT="${PROJ_DIR}"
          fi

          echo "Usando Dockerfile: ${DOCKERFILE}"
          echo "Usando contexto:   ${CONTEXT}"

          docker build -f "${DOCKERFILE}" -t ${IMAGE_LATEST} -t ${IMAGE_SHA} "${CONTEXT}"
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
