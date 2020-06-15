pipeline {
  agent any
    environment {
      SVC_ACCOUNT_KEY = credentials('terraform-auth')
      BASEMASTER = 'dev'
      
    }
    stages {
      stage('TF Plan') {
        steps {
          container('terraform') {
            sh 'terraform init'
            sh 'terraform plan -out myplan'
          }
        }
      }
      stage('Approval') {
        steps {
          script {
            def userInput = input(id: 'confirm', message: 'Apply Terraform?', parameters: [ [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Apply terraform', name: 'confirm'] ])
          }
        }
      }
      stage('Deploy to production ') {
        when { branch 'master' }
          steps{
            script {
              sh ''
      post {
          success {
              deleteDir()
          }
      }
  }
}
