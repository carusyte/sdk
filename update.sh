filename=`ls assembly-sdk/target | grep codenvy`
SSH_KEY_NAME=wso2preview.pem
SSH_AS_USER_NAME=cl-server
AS_IP=wso2preview.codenvy-mkt.com
home=/home/cl-server/

deleteFileIfExists() {
    if [ -f $1 ]; then
        echo $1
        rm -rf $1
    fi
}
    echo "upload new tomcat..."
    scp -i ~/.ssh/${SSH_KEY_NAME} assembly-sdk/target/${filename} ${SSH_AS_USER_NAME}@${AS_IP}:${home}
    echo "stoping tomcat"
    ssh -i ~/.ssh/${SSH_KEY_NAME} ${SSH_AS_USER_NAME}@${AS_IP} "cd ${home}/tomcat-ide/bin/;if [ -f codenvy.sh ]; then ./codenvy.sh stop -force; fi"
    echo "clean up"
    ssh -i ~/.ssh/${SSH_KEY_NAME} ${SSH_AS_USER_NAME}@${AS_IP} "rm -rf ${home}/tomcat-ide/*"
    echo "unpack new tomcat..."
    ssh -i ~/.ssh/${SSH_KEY_NAME} ${SSH_AS_USER_NAME}@${AS_IP} "mv ${home}/${filename} ${home}/tomcat-ide"
    ssh -i ~/.ssh/${SSH_KEY_NAME} ${SSH_AS_USER_NAME}@${AS_IP} "cd ${home}/tomcat-ide && unzip ${filename}"
    echo "start new tomcat... on ${AS_IP}"
    ssh -i ~/.ssh/${SSH_KEY_NAME} ${SSH_AS_USER_NAME}@${AS_IP} "cd ${home}/tomcat-ide/bin;./codenvy.sh start"

    AS_STATE='Starting'
    testfile=/tmp/catalina.out
    while [[ "${AS_STATE}" != "Started" ]]; do

    deleteFileIfExists ${testfile}

    scp -i ~/.ssh/${SSH_KEY_NAME} ${SSH_AS_USER_NAME}@${AS_IP}:${home}/tomcat-ide/logs/catalina.out ${testfile}

      if grep -Fq "Server startup" ${testfile}
        then
         echo "Tomcat of application server started"
         AS_STATE=Started
      fi

         echo "AS state = ${AS_STATE}  Attempt ${COUNTER}"
         sleep 5
         let COUNTER=COUNTER+1
         deleteFileIfExists ${testfile}
    done
