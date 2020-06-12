#!/bin/bash
env_name=$(cat $TEMP_ENV_NAME_FILE)
echo "env_name=$env_name"
# FIXME - Don't disable rollcback
export JENKINS_SETTING_CF_DISABLE_ROLLBACK=true
install-cf-template