#! /bin/bash 
# /bin/bash -xe

# http://www.gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html
# Make shell to be case insensitive
shopt -s nocasematch
case "${ENVIRONMENT}" in
    *dev* | *development*)
        export MAX_NUMBER_OF_INSTANCES=1
        echo "Deployment is dev, setting the number of maximum instances to ${MAX_NUMBER_OF_INSTANCES}"
        export MIN_NUMBER_OF_INSTANCES=1
        echo "Deployment is dev, setting the number of minimum instances to ${MIN_NUMBER_OF_INSTANCES}"
        export DEPLOYMENT_ENVIRONMENT=DEV
        echo "Deployment is dev, setting the deployment environment to ${DEPLOYMENT_ENVIRONMENT}"
        export INSTANCE_TYPE="t2.small"
        echo "Deployment is dev, Setting instance type to ${INSTANCE_TYPE}"
        ;;
    *qa*)
        export MAX_NUMBER_OF_INSTANCES=1
        echo "Deployment is qa, setting the number of maximum instances to ${MAX_NUMBER_OF_INSTANCES}"
        export MIN_NUMBER_OF_INSTANCES=1
        echo "Deployment is qa, setting the number of minimum instances to ${MIN_NUMBER_OF_INSTANCES}"
        export DEPLOYMENT_ENVIRONMENT=QA
        echo "Deployment is qa, setting the deployment environment to ${DEPLOYMENT_ENVIRONMENT}"
        export INSTANCE_TYPE="t2.small"
        echo "Deployment is qa, Setting instance type to ${INSTANCE_TYPE}"
        ;;
    *prod* | *production*)
        export MAX_NUMBER_OF_INSTANCES=100
        echo "Deployment is production, setting the number of maximum instances to ${MAX_NUMBER_OF_INSTANCES}"
        export MIN_NUMBER_OF_INSTANCES=2
        echo "Deployment is production, setting the number of maximum instances to ${MIN_NUMBER_OF_INSTANCES}"
        export DEPLOYMENT_ENVIRONMENT=PRODUCTION
        echo "Deployment is production, setting the deployment environment to ${DEPLOYMENT_ENVIRONMENT}"
        export INSTANCE_TYPE="m4.large"
        echo "Deployment is production, Setting instance type to ${INSTANCE_TYPE}"
        ;;
    *staging* | *stage*)
        export MAX_NUMBER_OF_INSTANCES=1
        echo "Deployment is staging, setting the number of maximum instances to ${MAX_NUMBER_OF_INSTANCES}"
        export MIN_NUMBER_OF_INSTANCES=1
        echo "Deployment is staging, setting the number of minimum instances to ${MIN_NUMBER_OF_INSTANCES}"
        export DEPLOYMENT_ENVIRONMENT=STAGING
        echo "Deployment is staging, setting the deployment environment to ${DEPLOYMENT_ENVIRONMENT}"
        export INSTANCE_TYPE="t2.small"
        echo "Deployment is staging, Setting instance type to ${INSTANCE_TYPE}"
        ;;
    *)
        export MAX_NUMBER_OF_INSTANCES=1
        echo "Undefined environment... setting the number of maximum instances to ${MAX_NUMBER_OF_INSTANCES}"
        export MIN_NUMBER_OF_INSTANCES=1
        echo "Undefined environment... setting the number of maximum instances to ${MIN_NUMBER_OF_INSTANCES}"
        export DEPLOYMENT_ENVIRONMENT=DEV
        echo "Undefined environment... setting the deployment environment to ${DEPLOYMENT_ENVIRONMENT}"
        export INSTANCE_TYPE="t2.small"
        echo "Undefined environment... Setting instance type to ${INSTANCE_TYPE}"
        ;;
esac

echo "$DEPLOYMENT_ENVIRONMENT" > $TEMP_ENV_NAME_FILE

# Turn off shell case insensitive
shopt -u nocasematch

export DESIRED_NUMBER_OF_TASKS="$SERVICE_MIN_TASKS"
echo "Setting the desired number of tasks to $DESIRED_NUMBER_OF_TASKS"


mkdir -p $CF_PARAMETERS_FOLDER
pip2 install jinja2
python -c 'import os
import sys
import jinja2
sys.stdout.write(
    jinja2.Template(undefined=jinja2.StrictUndefined, source=sys.stdin.read()
).render(env=os.environ))' < ${JINJA_CF_PARAMS_TEMPLATE_FILE_PATH} > ${CF_PARAMETERS_FILE_PATH}

echo "The output of the ${CF_PARAMETERS_FILE_PATH}"
cat ${CF_PARAMETERS_FILE_PATH}
