pipeline {
    agent any
    parameters {
        choice(
            name: 'action',
            choices: ['apply', 'destroy'],
            description: 'Choose Terraform action' 
            )
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
    
        stage ("terraform init") {
            steps {
                sh ("terraform init -reconfigure") 
            }
        }
        
        stage ("plan") {
            steps {
                sh ('terraform plan') 
            }
        }

        stage (" Action") {
            steps {
                echo "Terraform action is --> ${params.action}"
                sh "terraform ${params.action} --auto-approve"
           }
        }
    }
}
    
