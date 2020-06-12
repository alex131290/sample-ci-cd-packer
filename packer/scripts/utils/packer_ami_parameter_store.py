#!/usr/bin/env python
# encoding: utf-8


# Export AWS_SHARED_CREDENTIALS_FILE which will point to the creds file if it's not in the default location


__author__ = 'Alex Brodov <alex.suw@gmail.com>'

from botocore.exceptions import ProfileNotFound, ClientError
from enum import Enum, unique
import logging
import argcomplete
import argparse
import boto3
import json
import traceback


logger = logging.getLogger(__file__)


def init_logging():
    fmt = '%(asctime)s - %(name)s - %(levelname)s - %(module)s:%(lineno)s - ' + \
          '%(funcName)s() - %(message)s'
    logging.basicConfig(format=fmt, level=logging.DEBUG)
    logging.addLevelName(logging.WARNING, LoggingColors.RED.value.format(logging.getLevelName(logging.WARNING)))
    logging.addLevelName(logging.ERROR, LoggingColors.RED_BG.value.format(logging.getLevelName(logging.ERROR)))
    logging.addLevelName(logging.CRITICAL, LoggingColors.RED_BG.value.format(logging.getLevelName(logging.CRITICAL)))
    logging.addLevelName(logging.INFO, LoggingColors.GREEN.value.format(logging.getLevelName(logging.INFO)))
    logging.addLevelName(logging.DEBUG, LoggingColors.YELLOW.value.format(logging.getLevelName(logging.DEBUG)))


@unique
class LoggingColors(Enum):
    RED = "\033[1;31m{}\033[1;0m"
    RED_BG = "\033[1;41m{}\033[1;0m"
    YELLOW = "\033[1;33m{}\033[1;0m"
    GREEN = "\033[1;32m{}\033[1;0m"
    BLUE = "\033[1;34m{}\033[1;0m"


def create_session(profile_name=None):
    """
    Creating an AWS session
    :param profile_name: The profile name in the ~/.aws/credentials file to use
    :return: The session object
    """
    try:
        return boto3.Session(profile_name=profile_name)
    except ProfileNotFound as e:  # The profile hasn't been found in the ~/.aws/credentials file
        logger.error(e.message)
        raise e


def push_parameter(region, parameter_key, parameter_value, session):
    """
    Pushing a parameter key and value to parameter store in a given region
    :param region: The region where the parameter should be created or updated
    :param parameter_key: The parameter key to create or update
    :param parameter_value: The parameter value
    :param session: The aws session object
    """
    ssm_client = session.client(service_name='ssm', region_name=region)
    try:
        logger.debug("Pushing parameter {} with value {} to region {}".format(parameter_key, parameter_value, region))
        res = ssm_client.put_parameter(Name=parameter_key, Value=parameter_value, Type="String", Overwrite=True)
        # TODO: Check the response
    except ClientError as e:
        raise e


def parse_packer_manifest(manifest_path):
    """
    :param manifest_path: The packer manifest full path
    :return: A dictionary of all the found artifact IDs with their corresponding regions
    """
    '''
{
  "builds": [
    {
      "name": "amazon-ebs",
      "builder_type": "amazon-ebs",
      "build_time": 1582193406,
      "files": null,
      "artifact_id": "us-east-1:ami-0fe450666efdfb596",
      "packer_run_uuid": "aa9d9438-757b-0803-dd2b-efdc1effa162",
      "custom_data": null
    },
    {
      "name": "amazon-ebs",
      "builder_type": "amazon-ebs",
      "build_time": 1582194328,
      "files": null,
      "artifact_id": "eu-west-1:ami-0bf0865d095294552,us-east-1:ami-0885621e1fdadbd43",
      "packer_run_uuid": "7c30122f-7774-575e-6687-ba16e1eff548",
      "custom_data": null
    }
  ],
  "last_run_uuid": "7c30122f-7774-575e-6687-ba16e1eff548"
    '''
    ami_data = {}
    logger.debug('Opening the manifest file {}'.format(manifest_path))
    with open(manifest_path, 'rb') as f:
        manifest_data = json.load(f)
    logger.debug('Parsing the manifest file')
    for build in manifest_data['builds']:
        artifact_ids = build['artifact_id']
        artifact_ids_splitted = artifact_ids.split(',')
        for artifact in artifact_ids_splitted:
            artifact_splitted = artifact.split(':')
            ami_data.update({artifact_splitted[1]: artifact_splitted[0]})
    return ami_data


def push_parameters(args):
    try:
        logger.info("The manifest file location is: {}".format(args.manifest_path))
        ami_data = parse_packer_manifest(args.manifest_path)
        session = create_session(profile_name=args.profile_name)
        for ami_id, region in ami_data.iteritems():
            logger.debug("{} {}".format(ami_id, region))
            push_parameter(region=region, parameter_key=args.parameter_name, parameter_value=ami_id, session=session)
    except (ClientError, ProfileNotFound, KeyError) as e:
        tb = traceback.format_exc()
        logger.critical(tb)
        raise


def set_parser():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers()
    parser_push_parameter = subparsers.add_parser('push-parameter',
                                                  help='Create AMI parameters in parameter store based on the packer'
                                                  'manifest file')
    parser_push_parameter.add_argument('--manifest-path',
                                       required=True,
                                       help='The packer manifest file location')
    parser_push_parameter.add_argument('--profile-name',
                                       required=False,
                                       help='The AWS credentials profile name, defaults to the "default profile"')
    parser_push_parameter.add_argument('--parameter-name',
                                       required=True,
                                       help='The AWS credentials profile name, defaults to the "default profile"')
    parser_push_parameter.set_defaults(func=push_parameters)
    argcomplete.autocomplete(parser)
    args = parser.parse_args()
    args.func(args)


def main():
    init_logging()
    # Disable all the noise which is generated by boto3
    logging.getLogger('boto3').setLevel(logging.CRITICAL)
    logging.getLogger('botocore').setLevel(logging.CRITICAL)
    logging.getLogger('nose').setLevel(logging.CRITICAL)
    set_parser()


if __name__ == "__main__":
    main()
