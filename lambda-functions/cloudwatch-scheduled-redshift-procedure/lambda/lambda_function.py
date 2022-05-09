import base64
import datetime
import json
import logging
import os
import sys
import traceback

import boto3
import redshift_connector
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)


class RedshiftPermissions:

    def __init__(self):

        self.aws_region = os.environ['aws_region']
        self.secret_arn = os.environ['secrets_config_arn']
        __redshift_config = json.loads(self.__get_config(self.secret_arn, self.aws_region))
        self.cursor = self.__connect_to_redshift(__redshift_config)

    def __get_config(self, secret_arn: str, region_name: str) -> None:
        """Retrieves the AWS Redshift credentials from AWS Secret Manager. The returned secret should
        include the host, port, database, user and password."""

        # Create a Secrets Manager client
        session = boto3.session.Session()
        client = session.client(service_name='secretsmanager',
                                region_name=region_name)

        try:
            get_secret_value_response = client.get_secret_value(SecretId=secret_arn)

        except ClientError as e:
            # Log potential errors
            if e.response['Error']['Code'] == 'DecryptionFailureException':
                logger.error("Secrets Manager can't decrypt the protected "
                             "secret text using the provided KMS key.")
                raise e
            elif e.response['Error']['Code'] == 'InternalServiceErrorException':
                logger.error("An error occurred on the server side.")
                raise e
            elif e.response['Error']['Code'] == 'InvalidParameterException':
                logger.error("You provided an invalid value for a parameter.")
                raise e
            elif e.response['Error']['Code'] == 'InvalidRequestException':
                logger.error("You provided a parameter value that is not "
                             "valid for the current state of the resource.")
                raise e
            elif e.response['Error']['Code'] == 'ResourceNotFoundException':
                logger.error("We can't find the resource that you asked for.")
                raise e

        else:
            # Decrypts secret using the associated KMS key
            if 'SecretString' in get_secret_value_response:
                secret = get_secret_value_response['SecretString']
            else:
                secret = base64.b64decode(get_secret_value_response['SecretBinary'])

            logger.info(f"Secret : {secret}")

            return secret

    def __connect_to_redshift(self, params: dict) -> redshift_connector.Cursor:
        """Connects to the redshift instance used as storage backend for the extraction with redshift - connector.
        For more information about this library, see https://pypi.org/project/redshift-connector/.

        Raises:
            ValueError: The configuration crendetials are not correct.

        Returns:
            redshift_connector.Cursor: The client used to interact with the Redshift instance.
        """

        try:
            con = redshift_connector.connect(
                host=params['host'],
                port=int(params['port']),
                database=params['database'],
                user=params['username'],
                password=params['password']
            )

            con.rollback()
            con.autocommit = True
            cursor = con.cursor()
            return cursor

        except redshift_connector.InterfaceError:
            raise ValueError("The Redshift authentication configuration used is incorrect.")

    def create_redshift_table(self):
        """Create a table in the Redshift instance."""
        logger.info('Creating the phonebook table')
        query = """CREATE TABLE IF NOT EXISTS phonebook(phone VARCHAR(32), firstname VARCHAR(32), lastname VARCHAR(32), address VARCHAR(64));"""
        self.cursor.execute(query)
        return

    def insert_redshift_data(self):
        """Create a table in the Redshift instance."""
        logger.info('Inserting a record into the table')
        query = """INSERT INTO phonebook(phone, firstname, lastname, address) VALUES('+1 123 456 7890', 'John', 'Doe', 'North America');"""
        self.cursor.execute(query)
        return

    def delete_redshift_table(self):
        """Delete the created table from Redshift."""
        logger.info('Deleting the phonebook table')
        query = """DROP TABLE IF EXISTS phonebook"""
        self.cursor.execute(query)
        return

    def write_s3_file(self, bucket: str, file_path: str, replace=False) -> None:
        """Write the cleaned file to s3."""

        logger.info('Querying the phonebook table')
        query = "SELECT * FROM phonebook"
        data = self.cursor.execute(query).fetch_dataframe()
        file = json.dumps(data.to_dict()).encode('utf-8')
        logger.info(f'Writing the following json to S3: {data.to_dict()}')

        if replace == False:
            new_path = file_path.split('.')
            new_path.insert(-1, f'-{datetime.datetime.now()}.')
            file_path = ''.join(new_path)

        client = boto3.session.Session().client('s3')
        client.put_object(Bucket=bucket, Body=file, Key=file_path)

        return


def lambda_handler(event, context):

    logger.info("-------------------------------------------------------------------")
    logger.info(f"Lambda function ARN: {context.invoked_function_arn}")
    logger.info(f"CloudWatch log stream name: {context.log_stream_name}")
    logger.info(f"CloudWatch log group name: {context.log_group_name}")
    logger.info(f"Lambda Request ID: {context.aws_request_id}")
    logger.info(f"Lambda function memory limits in MB: {context.memory_limit_in_mb}")
    logger.info(f'S3 event notification: {event}')

    try:

        module = RedshiftPermissions()
        execution_date = datetime.datetime.now().strftime("%Y-%m-%d_%H:%M:%S")
        bucket = os.environ.get('bucket_name')
        file_path = f'test_{execution_date}.json'

        module.create_redshift_table()
        module.insert_redshift_data()
        module.write_s3_file(bucket, file_path)
        module.delete_redshift_table()

    except Exception:
        exception_type, exception_value, exception_traceback = sys.exc_info()
        traceback_string = traceback.format_exception(exception_type, exception_value, exception_traceback)
        err_msg = json.dumps({
            "errorType": exception_type.__name__,
            "errorMessage": str(exception_value),
            "stackTrace": traceback_string
        })
        logger.error(err_msg)

    return
