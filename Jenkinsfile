#!/usr/bin/env groovy

BRANCH = env.BRANCH
node {
    parallel "${BRANCH}": {
        stage('Checkout, build and push specified branch') {
            directoryName = BRANCH.replaceAll("/","_")
            dir("${directoryName}") {
                buildAndPush(BRANCH)
            }
        }
    },
    jessie: {
        stage('Build and push jessie images') {
            directoryName = "jessie"
            dir("${directoryName}") {
                if (BRANCH == "master") {
                    buildAndPush("jessie")
                }
            }
        }
    },
    stretch: {
        stage('Build and push stretch images') {
            directoryName = "stretch"
            dir("${directoryName}") {
                if (BRANCH == "master") {
                    buildAndPush("stretch")
                }
            }
        }
    }
}

def buildAndPush(branch) {
    checkout([$class: 'GitSCM',
             branches: [[name: "*/${branch}"]],
             doGenerateSubmoduleConfigurations: false,
             extensions: [[$class: 'WipeWorkspace'],
                          [$class: 'LocalBranch', localBranch: '**']],
                           submoduleCfg: [],
                           userRemoteConfigs: [[url: 'https://github.com/gravitational/docker-debian.git']]])
    sh 'make images'
    sh 'make push'
}
