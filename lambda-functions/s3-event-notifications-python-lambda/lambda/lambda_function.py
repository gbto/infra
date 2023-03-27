import datetime
import gzip
import io
import json
import logging
import re
import sys
import traceback

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)


class JSONCleaner():
    """The Lambda function is triggered by a S3 event notification or a
    S3 batch operations task. It is used to clean up the raw files dumped
    by Segment from potential PIIs.
    """
    def __init__(self):
        """Initialize the Lambda function."""
        self.execution_date = datetime.datetime.now()
        self.s3_client = boto3.client('s3')

    def download_file(self, bucket: str, file_path: str) -> str:
        """Extract a zipped file from S3 and returns its content."

        Args:
            bucket: The S3 bucket where the raw files are stored.
            file_path: The path of the file to be processed.

        Returns:
            The raw content of the file to be processed.
        """
        obj = self.s3_client.get_object(Bucket=bucket, Key=file_path)
        with gzip.GzipFile(fileobj=obj.get("Body")) as gzipfile:
            content = gzipfile.read().decode()
        return content

    def parse_file(self, file: str) -> list:
        """Parse the binary string of an S3 bucket into a list of json.

        Args:
            file: The content of the raw files.

        Returns:
            The parsed raw file.
        """
        parsed_file = [json.loads(itm) for itm in file.split('\n') if len(itm) > 0]
        return parsed_file

    def search_file(
        self,
        lookup_key: str,
        object: dict,
        search_result=list(),
    ) -> list[dict]:
        """Extract the values of a lookup key from a json file.

        We extract the values by recursively navigating the different level of the file.

        Args:
            lookup_key: The key for which value should be replaced.
            object: The JSON object to be processed.
            search_result: The result of the file search. Defaults to list().

        Returns:
            The unprocessed file content.
        """
        if type(object) == dict:
            for key, value in object.items():
                if lookup_key.lower() in key.lower():
                    search_result.append(dict(key=value))
                self.search_file(lookup_key, value, search_result)

        elif type(object) == list:
            for element in object:
                self.search_file(lookup_key, element, search_result)

        return search_result

    def cleanup_file(self, lookup_key: str, object: dict) -> list[dict]:
        """Replace the values of a lookup keyfrom a json file with None by recursively
        navigating the different level of the file.

        Args:
            lookup_key: The key for which value should be replaced.
            object: The JSON object to be processed.

        Returns:
            The processed file content.
        """

        if type(object) == dict:
            for key, value in object.items():
                if lookup_key.lower() in key.lower():
                    object[key] = None
                self.cleanup_file(lookup_key, value)
        elif type(object) == list:
            for element in object:
                self.cleanup_file(lookup_key, element)
        return object

    def write_file(self, bucket: str, file_path: str, data: str, replace=False) -> None:
        """Compresse processed file to gzip and write it to s3.

        Args:
            bucket: The S3 bucket where to write the processed files.
            file_path: The path of the file to be written in S3.
            data: The content of the file to be written.
            replace: Whether to remove the original file. Defaults to False.
        """

        file_src_path = file_path
        file_dst_path = re.sub('.gz$', '.json.gzip', file_src_path)

        inmem = io.BytesIO()
        with gzip.GzipFile(fileobj=inmem, mode='wb') as fh:
            with io.TextIOWrapper(fh, encoding='utf-8') as wrapper:
                wrapper.write(json.dumps(data, ensure_ascii=False, default=None))

        inmem.seek(0)

        self.s3_client.put_object(Bucket=bucket, Body=inmem, Key=file_dst_path)

        if replace == True:
            self.s3_client.delete_object(Bucket=bucket, Key=file_src_path)

        return

    def process_s3_batch_operations(self, event: dict, pii_key: str) -> None:
        """Wrap the processing steps for S3 batch operations tasks Lambda invocations.

        Args:
            event: The event passed on a S3 batch operations task.
            pii_key: The key of values to be replaced by null values.
        """

        results = list()
        try:
            # Get object attributes
            file_path = event.get('tasks')[0].get('s3Key')[1:]
            bucket = event.get('tasks')[0].get('s3BucketArn').split(':::')[-1]
            logger.info(f"Added file to S3 bucket {bucket}: {file_path}")

            # Process file
            file_raw = self.download_file(bucket, file_path)
            file_parsed = self.parse_file(file_raw)
            file_cleaned = self.cleanup_file(pii_key, file_parsed)
            self.write_file(bucket, file_path, file_cleaned, replace=True)

            # Set success parameters
            result_code = 'Succeeded'
            result_string = f"Successfully parsed object {file_path}."

        except Exception as error:

            # Mark all other exceptions as permanent failures.
            result_code = 'PermanentFailure'
            result_string = str(error)

            # Logg error traceback string
            exception_type, exception_value, exception_traceback = sys.exc_info()
            traceback_string = traceback.format_exception(
                exception_type, exception_value, exception_traceback
            )
            err_msg = json.dumps({
                "errorType": exception_type.__name__,
                "errorMessage": str(exception_value),
                "stackTrace": traceback_string
            })
            logger.error(err_msg)

        finally:
            results.append({
                           'taskId': event['tasks'][0]['taskId'],
                           'resultCode': result_code,
                           'resultString': result_string
                           })
            logger.info(f"Attempt to process {file_path} completed.")
            logger.info("-------------------------------------------------------------")

        return {
            'invocationSchemaVersion': event['invocationSchemaVersion'],
            'treatMissingKeysAs': 'PermanentFailure',
            'invocationId': event['invocationId'],
            'results': results
        }

    def process_s3_event_notifications(self, event: dict,  pii_key: str) -> None:
        """Wrap the processing steps for S3 events notification Lambda invocations.

        Args:
            event: The event passed when Lambda is invoked by a S3 events notification.
            pii_key: The key of values to be replaced by null values.

        Returns:
            None
        """
        try:
            # Get object attributes
            file_path = event.get('Records')[0].get('s3').get('object').get('key')
            bucket = event.get('Records')[0].get('s3').get('bucket').get('name')
            logger.info(f"Added file to S3 bucket {bucket}: {file_path}")

            # Process file
            file_raw = self.download_file(bucket, file_path)
            file_parsed = self.parse_file(file_raw)
            file_cleaned = self.cleanup_file(pii_key, file_parsed)
            self.write_file(bucket, file_path, file_cleaned, replace=True)
            result = True

        except Exception:
            # Log error traceback string
            exception_type, exception_value, exception_traceback = sys.exc_info()
            traceback_string = traceback.format_exception(
                exception_type, exception_value, exception_traceback
            )
            err_msg = json.dumps({
                "errorType": exception_type.__name__,
                "errorMessage": str(exception_value),
                "stackTrace": traceback_string
            })
            logger.error(err_msg)
            result = False

        finally:
            logger.info(f"Attempt to process {file_path} completed.")
            logger.info("-------------------------------------------------------------")

        return result


def lambda_handler(event, context):
    """Scans the file in a bucket and replace IPs with None values."""
    logger.info("-------------------------------------------------------------")
    logger.info(f"Lambda function ARN: {context.invoked_function_arn}")
    logger.info(f"CloudWatch log stream name: {context.log_stream_name}")
    logger.info(f"CloudWatch log group name: {context.log_group_name}")
    logger.info(f"Lambda Request ID: {context.aws_request_id}")
    logger.info(f"Lambda function memory limits in MB: {context.memory_limit_in_mb}")

    helper = JSONCleaner()

    pii_fields = ['ip', 'account', 'parent_account']

    for field in pii_fields:

        if event.get('invocationSchemaVersion'):
            logger.info(f'S3 batch operations task: {event}')
            event = helper.process_s3_batch_operations(event, field)

        elif event.get('Records'):
            logger.info(f'S3 events notification: {event}')
            event = helper.process_s3_event_notifications(event, field)

        else:
            logger.info("Unrecognized event payload. This seems to be neither "
                        "a S3 notifications or a S3 Batch Operations job task.")
            result = False

    return result
