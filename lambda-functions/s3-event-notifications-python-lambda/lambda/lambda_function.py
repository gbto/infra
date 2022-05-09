import boto3
import gzip
import json
import datetime
import io
import sys
import logging
import traceback
import re

logger = logging.getLogger()
logger.setLevel(logging.INFO)


class LedgerLiveCleaner():

    def __init__(self):

        self.execution_date = datetime.datetime.now()
        self.s3_client = boto3.client('s3')

    def download_file(self, bucket: str, file_path: str) -> str:
        """Extracts a zipped file from S3 and returns its content."""
        obj = self.s3_client.get_object(Bucket=bucket, Key=file_path)
        with gzip.GzipFile(fileobj=obj.get("Body")) as gzipfile:
            content = gzipfile.read().decode()
        return content

    def parse_file(self, file: str) -> list:
        """Parse the binary string of an S3 bucket into a list of json."""
        parsed_file = [json.loads(itm) for itm in file.split('\n') if len(itm) > 0]
        return parsed_file

    def search_file(self, lookup_key: str, object: dict, search_result=list()) -> list[dict]:
        """Extracts the values of a lookup key from a json file by recursively
        navigating the different level of the file."""
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
        navigating the different level of the file."""
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
        """Compressed processed file to gzip and write it to s3."""

        file_src_path = file_path
        file_dst_path = re.sub('.gz$', '.gzip', file_src_path)

        inmem = io.BytesIO()
        with gzip.GzipFile(fileobj=inmem, mode='wb') as fh:
            with io.TextIOWrapper(fh, encoding='utf-8') as wrapper:
                wrapper.write(json.dumps(data, ensure_ascii=False, default=None))

        inmem.seek(0)

        self.s3_client.put_object(Bucket=bucket, Body=inmem, Key=file_dst_path)

        if replace == True:
            self.s3_client.delete_object(Bucket=bucket, Key=file_src_path)

        return


def lambda_handler(event, context):
    """Scans the file in a bucket and replace IPs with None values."""

    logger.info("-------------------------------------------------------------------")
    logger.info(f"Lambda function ARN: {context.invoked_function_arn}")
    logger.info(f"CloudWatch log stream name: {context.log_stream_name}")
    logger.info(f"CloudWatch log group name: {context.log_group_name}")
    logger.info(f"Lambda Request ID: {context.aws_request_id}")
    logger.info(f"Lambda function memory limits in MB: {context.memory_limit_in_mb}")
    logger.info(f'S3 event notification: {event}')

    try:
        pii_key = 'ip'
        file_path = event.get('Records')[0].get('s3').get('object').get('key')
        bucket_name = event.get('Records')[0].get('s3').get('bucket').get('name')

        logger.info(f"Added file to S3 bucket {bucket_name}: {file_path}")

        helper = LedgerLiveCleaner()
        file_raw = helper.download_file(bucket_name, file_path)
        file_parsed = helper.parse_file(file_raw)
        file_cleaned = helper.cleanup_file(pii_key, file_parsed)
        helper.write_file(bucket_name, file_path, file_cleaned, replace=False)
        logger.info("Finished processing {file_path}")

    except Exception:
        exception_type, exception_value, exception_traceback = sys.exc_info()
        traceback_string = traceback.format_exception(exception_type, exception_value, exception_traceback)
        err_msg = json.dumps({
            "errorType": exception_type.__name__,
            "errorMessage": str(exception_value),
            "stackTrace": traceback_string
        })
        logger.error(err_msg)

    logger.info("-------------------------------------------------------------------")

    return
