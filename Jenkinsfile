#!/usr/bin/env groovy

BRANCH = env.BRANCH
node {
    deleteDir()

    parallel "${BRANCH}": {
        stage('Checkout, build and push specified branch') {
            directoryName = BRANCH.replaceAll("/","_")
            dir("${directoryName}") {
                checkout([$class: 'GitSCM',
                         branches: [[name: "*/${BRANCH}"]],
                         doGenerateSubmoduleConfigurations: false,
                         extensions: [[$class: 'WipeWorkspace'],
                                      [$class: 'LocalBranch', localBranch: '**']],
                         submoduleCfg: [],
                         userRemoteConfigs: [[url: 'https://github.com/gravitational/docker-debian.git']]])
                sh 'make images'
                sh 'make push'
            }
        }
    },
    jessie: {
        stage('Build and push jessie images') {
            directoryName = "jessie"
            dir("${directoryName}") {
                if (BRANCH == "master") {
                        checkout([$class: 'GitSCM',
                                 branches: [[name: "*/jessie"]],
                                 doGenerateSubmoduleConfigurations: false,
                                 extensions: [[$class: 'WipeWorkspace'],
                                              [$class: 'LocalBranch', localBranch: '**']],
                                 submoduleCfg: [],
                                 userRemoteConfigs: [[url: 'https://github.com/gravitational/docker-debian.git']]])
                        sh 'make images'
                        sh 'make push'
                    }
            }
        }
    }
}
