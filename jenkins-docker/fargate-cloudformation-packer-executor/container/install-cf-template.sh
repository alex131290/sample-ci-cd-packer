#! /bin/bash -xe

################################################################################
# Required environment variables:
#
# JENKINS_CF_STACK_NAME
#    - Name of the CloudFormation Stack
# JENKINS_CF_TEMPLATE_NAME
#    - Name of the CloudFormation template file
# JENKINS_CF_PARAMETERS_NAME
#    - Name of the CloudFormation parametrs file
# JENKINS_SETTING_AWS_REGION:
#    - Region for stack deployment
# JENKINS_SETTING_ENVIRONMENT_DEPLOY:
#    - Directory of cloudformation and parameters template according to environment,i.e dev, stage, prod
# WORKSPACE
#    - The source directory of the cloudformation templates
# JENKINS_SETTING_CF_CAPABILITIES_NAME:
#    - When creating some services, need to acknowledge the capabilities of AWS CF templates. i.e. CAPABILITY_IAM or CAPABILITY_NAMED_IAM as values
# JENKINS_SETTING_CF_DISABLE_ROLLBACK
#    - Disable rollback of the stacks
# JENKINS_SETTING_AWS_PROFILE
#    - The AWS profile to use from the credentials file, defaults to the "default" profile
# CF_PARAMETERS_FILE_PATH:
#    - The full path of the cloudformation parameters file name

################################################################################
# Optional environment variables:
#
# If running script locally, edit ~/.aws/credentials file to only contain credentials for account you're testing against.
#
# AWS_ACCESS_KEY_ID
#    - AWS access key
# AWS_SECRET_ACCESS_KEY
#    - AWS secret key
# AWS_SESSION_TOKEN
#    - AWS temporary session token


################################################################################"

EXTRA_ARGS=""

if [[ ! -z "${JENKINS_SETTING_AWS_PROFILE}" ]]; then
   EXTRA_ARGS+="--profile ${JENKINS_SETTING_AWS_PROFILE}"
fi

function check-for-changes-cf-template() {
    aws cloudformation create-change-set --stack-name ${JENKINS_CF_STACK_NAME} --template-body file://"${JENKINS_CF_TEMPLATE_NAME}" --parameters file://"${CF_PARAMETERS_FILE_PATH}" --change-set-name "${JENKINS_CF_STACK_NAME}-changeset" --region ${JENKINS_SETTING_AWS_REGION} ${EXTRA_ARGS}

    aws cloudformation describe-change-set --change-set-name "${JENKINS_CF_STACK_NAME}-changeset" --stack-name ${JENKINS_CF_STACK_NAME} --region ${JENKINS_SETTING_AWS_REGION} ${EXTRA_ARGS} | grep "The submitted information didn't contain changes" || diff=true

    if [[ $diff == "true" ]]
    then
    aws cloudformation delete-change-set --change-set-name "${JENKINS_CF_STACK_NAME}-changeset" --stack-name ${JENKINS_CF_STACK_NAME} --region ${JENKINS_SETTING_AWS_REGION} ${EXTRA_ARGS}
	return "1"
    else
    aws cloudformation delete-change-set --change-set-name "${JENKINS_CF_STACK_NAME}-changeset" --stack-name ${JENKINS_CF_STACK_NAME} --region ${JENKINS_SETTING_AWS_REGION} ${EXTRA_ARGS}
	return "0"
    fi
}

function install-cf-template() {
    aws cloudformation $1 --stack-name ${JENKINS_CF_STACK_NAME} --template-body file://"${JENKINS_CF_TEMPLATE_NAME}" --parameters file://"${CF_PARAMETERS_FILE_PATH}" --region ${JENKINS_SETTING_AWS_REGION} --capabilities ${JENKINS_SETTING_CF_CAPABILITIES_NAME} ${2} ${EXTRA_ARGS}

   wait_stack 15 0
}

wait_stack () {
   if [ "$#" -ne 2 ]; then
      echo "Usage: wait_stack <seconds> <event-count>"
      exit 1
   fi

   SLEEP_TIME=$1
   EVENT_COUNT=$2

   TAC=`which tac` || TAC="tail -r"
   echo "TAC=$TAC"

   # Wait for template to create, update, or be deleted
   while true; do
      status=`aws cloudformation describe-stacks --stack-name ${JENKINS_CF_STACK_NAME} --region ${JENKINS_SETTING_AWS_REGION} ${EXTRA_ARGS} --query="Stacks[0].StackStatus" --output=text 2> /dev/null`
      if [ $? != 0 ]; then
         echo Stack ${JENKINS_CF_STACK_NAME} does not exist
         break
      fi
      events=`aws cloudformation describe-stack-events --stack-name ${JENKINS_CF_STACK_NAME} --region ${JENKINS_SETTING_AWS_REGION} ${EXTRA_ARGS} --query="StackEvents[].{f1:Timestamp,f2:ResourceType,f3:ResourceStatus}" --output=text | $TAC`
      new_event_count=`echo "$events" | wc -l`
      new_events=`expr $new_event_count - $EVENT_COUNT` || dont_exit_on_zero_new_events="true"
      if [ $SLEEP_TIME -gt 0 ]; then
         if [ $new_events -gt 0 ]; then
            echo "$events" | tail -n $new_events
            EVENT_COUNT=$new_event_count
         fi
      fi
      case "$status" in
         *ROLLBACK* | *FAILED)
            echo ERROR: Stack creation failed.  Manual intervention required
            exit 1
            ;;
         *COMPLETE)
         echo Current stack status: $status
            break
            ;;
      esac
      if [ $SLEEP_TIME -gt 0 ]; then
         sleep $SLEEP_TIME
      else
         echo Current stack status: $status
         break
      fi
   done
}

function main() {

 exists=0
 aws cloudformation describe-stacks --stack-name ${JENKINS_CF_STACK_NAME} --region ${JENKINS_SETTING_AWS_REGION} ${EXTRA_ARGS} > /dev/null && exists=1

 if [ $exists -eq 1 ]; then

 ## Check if the template contains any changes
   set +e
   check-for-changes-cf-template
   if [[ $? -eq 0 ]]
   then
       set -e
       echo "There are no updates to perform, exiting job."
       exit 0
   else
       set -e
       echo "Updating cloudformation stack \"${JENKINS_CF_STACK_NAME}\""
       install-cf-template 'update-stack'
   fi
 else
      disable_rollback_flag="--disable-rollback"
     if [[ -z "${JENKINS_SETTING_CF_DISABLE_ROLLBACK}" || "${JENKINS_SETTING_CF_DISABLE_ROLLBACK}" == "false"  ]]; then
         disable_rollback_flag="--no-disable-rollback"
     fi 
     echo "Creating new cloudformation stack \"${JENKINS_CF_STACK_NAME}\""
     install-cf-template 'create-stack' "$disable_rollback_flag"
 fi
}

function assertParameter() {
   if [[ ! $2 ]]; then
      echo "Parameter \"$1\" does not exist.  Exiting" >&2
      exit 1
   fi

}

cd ${WORKSPACE}/${JENKINS_SETTING_ENVIRONMENT_DEPLOY}


################################################################################
# set directory variables
################################################################################

assertParameter 'JENKINS_CF_STACK_NAME' ${JENKINS_CF_STACK_NAME}
assertParameter 'JENKINS_CF_TEMPLATE_NAME' ${JENKINS_CF_TEMPLATE_NAME}
assertParameter 'JENKINS_CF_PARAMETERS_NAME' ${JENKINS_CF_PARAMETERS_NAME}
assertParameter 'JENKINS_SETTING_AWS_REGION' ${JENKINS_SETTING_AWS_REGION}
assertParameter 'JENKINS_SETTING_CF_CAPABILITIES_NAME' ${JENKINS_SETTING_CF_CAPABILITIES_NAME}

main "$@"