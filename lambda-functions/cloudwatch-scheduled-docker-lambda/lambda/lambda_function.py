import datetime
import json
import logging
import os
import sys
import traceback

import boto3
import redshift_connector  # Test the import

logger = logging.getLogger()
logger.setLevel(logging.INFO)


class S3Toolkit():

    def __init__(self):

        self.execution_date = datetime.datetime.now()
        self.s3_session = boto3.session.Session().resource('s3')

    def generate_data(self) -> dict:
        """Generate sample data to push to S3."""

        data = {'this_is_a_test': "for writing to S3 with lambda",
                "inserted_at": self.execution_date}
        return data

    def write_file(self, bucket: str, file_path: str, data: str = None, replace=False) -> None:
        """Write the cleaned file to s3."""

        data = data if data else self.generate_data()
        file = str(data).encode('utf-8')

        if replace == False:
            new_path = file_path.split('.')
            new_path.insert(-1, f'-{datetime.datetime.now()}.')
            file_path = ''.join(new_path)

        object = self.s3_session.Object(bucket, file_path)
        object.put(Body=file)

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
        helper = S3Toolkit()
        execution_date = datetime.datetime.now().strftime("%Y-%m-%d_%H:%M:%S")
        bucket = os.environ.get('bucket_name')
        file_path = f'test_{execution_date}.json'
        data = {'this_is_a_test': "for writing to S3 with lambda",
                "inserted_at": helper.execution_date}

        helper.write_file(bucket, file_path, data)

    except Exception:
        exception_type, exception_value, exception_traceback = sys.exc_info()
        traceback_string = traceback.format_exception(exception_type, exception_value, exception_traceback)
        err_msg = json.dumps({
            "errorType": exception_type.__name__,
            "errorMessage": str(exception_value),
            "stackTrace": traceback_string
        })
        logger.error(err_msg)

    return "This lambda function seems to execute properly."
