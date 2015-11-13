<?xml version='1.0' encoding='UTF-8'?>
<!--
  Copyright 2015 The Bazel Authors. All rights reserved.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->
<matrix-project plugin="%{JENKINS_PLUGIN_matrix-project}">
  <actions/>
  <description>Test the Tutorial project still build with Bazel at head.</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <com.coravy.hudson.plugins.github.GithubProjectProperty plugin="%{JENKINS_PLUGIN_github}">
      <projectUrl>https://tensorflow.org</projectUrl>
    </com.coravy.hudson.plugins.github.GithubProjectProperty>
  </properties>
  <scm class="hudson.plugins.git.GitSCM" plugin="%{JENKINS_PLUGIN_git}">
    <configVersion>2</configVersion>
    <userRemoteConfigs>
      <hudson.plugins.git.UserRemoteConfig>
        <refspec>+refs/heads/*:refs/remotes/origin/*</refspec>
        <url>https://github.com/tensorflow/tensorflow</url>
      </hudson.plugins.git.UserRemoteConfig>
    </userRemoteConfigs>
    <branches>
      <hudson.plugins.git.BranchSpec>
        <name>*/master</name>
      </hudson.plugins.git.BranchSpec>
    </branches>
    <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
    <submoduleCfg class="list"/>
    <extensions>
      <hudson.plugins.git.extensions.impl.CleanBeforeCheckout/>
      <hudson.plugins.git.extensions.impl.AuthorInChangelog/>
      <hudson.plugins.git.extensions.impl.SubmoduleOption>
        <disableSubmodules>false</disableSubmodules>
        <recursiveSubmodules>true</recursiveSubmodules>
        <trackingSubmodules>false</trackingSubmodules>
      </hudson.plugins.git.extensions.impl.SubmoduleOption>
    </extensions>
  </scm>
  <quietPeriod>5</quietPeriod>
  <canRoam>true</canRoam>
  <disabled>false</disabled>
  <blockBuildWhenDownstreamBuilding>false</blockBuildWhenDownstreamBuilding>
  <blockBuildWhenUpstreamBuilding>false</blockBuildWhenUpstreamBuilding>
  <triggers>
    <com.cloudbees.jenkins.GitHubPushTrigger plugin="%{JENKINS_PLUGIN_github}">
      <spec></spec>
    </com.cloudbees.jenkins.GitHubPushTrigger>
  </triggers>
  <concurrentBuild>false</concurrentBuild>
  <axes>
    <hudson.matrix.LabelAxis>
      <name>PLATFORM_NAME</name>
      <values>%{PLATFORMS}</values>
    </hudson.matrix.LabelAxis>
    <hudson.matrix.TextAxis>
      <name>BAZEL_VERSION</name>
      <values>
        <string>HEAD</string>
        <string>latest</string>
      </values>
    </hudson.matrix.TextAxis>
  </axes>
  <builders>
    <hudson.plugins.copyartifact.CopyArtifact plugin="%{JENKINS_PLUGIN_copyartifact}">
      <project>Bazel</project>
      <filter>**/ci/*installer*.sh</filter>
      <target>bazel-installer</target>
      <excludes></excludes>
      <selector class="hudson.plugins.copyartifact.TriggeredBuildSelector">
        <fallbackToLastSuccessful>true</fallbackToLastSuccessful>
        <upstreamFilterStrategy>UseGlobalSetting</upstreamFilterStrategy>
      </selector>
      <doNotFingerprintArtifacts>false</doNotFingerprintArtifacts>
    </hudson.plugins.copyartifact.CopyArtifact>
    <hudson.tasks.Shell>
      <command>#!/bin/bash
set -x
INSTALLER_PLATFORM=$(uname -s | tr &apos;[:upper:]&apos; &apos;[:lower:]&apos;)-$(uname -m)
if [ &quot;$BAZEL_VERSION&quot; = &quot;HEAD&quot; ]; then
  export BAZEL_INSTALLER=$(find $PWD/bazel-installer -name *.sh | \
      fgrep &quot;PLATFORM_NAME=${INSTALLER_PLATFORM}&quot; | fgrep -v jdk7 | head -1)
else
  if [ &quot;$BAZEL_VERSION&quot; = &quot;latest&quot; ]; then
    URL=$(curl -L https://github.com/bazelbuild/bazel/releases/latest | \
      grep -o &apos;&quot;/.*/bazel-.*-installer-&apos;${INSTALLER_PLATFORM}&apos;.sh&quot;&apos; | grep -v jdk7 | 
sed &apos;s/&quot;//g&apos;)
  else
    URL=https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-installer-${I
NSTALLER_PLATFORM}.sh
  fi
  export BAZEL_INSTALLER=${PWD}/bazel-installer/install.sh
  curl -L -o ${BAZEL_INSTALLER} https://github.com${URL}
fi
BASE=&quot;$(dirname &quot;${PWD}&quot;)/bazel-install&quot;
bash &quot;${BAZEL_INSTALLER}&quot; \
  --base=&quot;${BASE}&quot; \
  --bazelrc=&quot;$PWD/binary/bazel.bazelrc&quot; \
  --bin=&quot;${BASE}/binary&quot;
BAZEL=&quot;${BASE}/binary/bazel&quot;
${BAZEL} build -c opt //tensorflow/...</command>
    </hudson.tasks.Shell>
  </builders>
  <publishers>
    <hudson.tasks.Mailer plugin="%{JENKINS_PLUGIN_mailer}">
      <recipients>bazel-ci@googlegroups.com</recipients>
      <dontNotifyEveryUnstableBuild>false</dontNotifyEveryUnstableBuild>
      <sendToIndividuals>false</sendToIndividuals>
    </hudson.tasks.Mailer>
  </publishers>
  <buildWrappers/>
  <executionStrategy class="hudson.matrix.DefaultMatrixExecutionStrategyImpl">
    <runSequentially>false</runSequentially>
  </executionStrategy>
</matrix-project>
