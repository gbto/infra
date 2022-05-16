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


class SegmentBucketCleaner:
    def __init__(self):

        self.execution_date = datetime.datetime.now()
        self.s3_client = boto3.client("s3")

    def download_file(self, bucket: str, file_path: str) -> str:
        """Extract a zipped file from S3 and returns its content."

        Args:
            bucket (str): The S3 bucket where the raw files are stored.
            file_path (str): The path of the file to be processed.

        Returns:
            str: The raw content of the file to be processed.
        """
        obj = self.s3_client.get_object(Bucket=bucket, Key=file_path)
        with gzip.GzipFile(fileobj=obj.get("Body")) as gzipfile:
            content = gzipfile.read().decode()
        return content

    def parse_file(self, file: str) -> list:
        """Parse the binary string of an S3 bucket into a list of json.

        Args:
            file (str): The content of the raw files.

        Returns:
            list: The parsed raw file.
        """
        parsed_file = [json.loads(itm) for itm in file.split("\n") if len(itm) > 0]
        return parsed_file

    def search_file(self, lookup_key: str, object: dict, search_result=list()) -> list[dict]:
        """Extract the values of a lookup key from a json file.

        We extract the values by recursively navigating the different level of the file.

        Args:
            lookup_key (str): The key for which value should be replaced.
            object (dict): The JSON object to be processed.
            search_result (list, optional): The result of the file search. Defaults to list().

        Returns:
            list[dict]: The unprocessed file content.
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
            lookup_key (str): The key for which value should be replaced.
            object (dict): The JSON object to be processed.

        Returns:
            list[dict]: The processed file content.
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
            bucket (str): The S3 bucket where to write the processed files.
            file_path (str): The path of the file to be written in S3.
            data (str): The content of the file to be written.
            replace (bool, optional): Whether to remove the original file. Defaults to False.

        Returns:
            None
        """

        file_src_path = file_path
        file_dst_path = re.sub(".gz$", ".json.gzip", file_src_path)

        inmem = io.BytesIO()
        with gzip.GzipFile(fileobj=inmem, mode="wb") as fh:
            with io.TextIOWrapper(fh, encoding="utf-8") as wrapper:
                wrapper.write(json.dumps(data, ensure_ascii=False, default=None))

        inmem.seek(0)

        self.s3_client.put_object(Bucket=bucket, Body=inmem, Key=file_dst_path)

        if replace == True:
            self.s3_client.delete_object(Bucket=bucket, Key=file_src_path)

        return

    def process_s3_batch_operations(self, event: dict, pii_key: str) -> dict:
        """Wrap the processing steps for S3 batch operations tasks Lambda invocations.

        Args:
            event (dict): The event passed when Lambda is invoked by a S3 batch operations task.
            pii_key (str): The key of values to be replaced by null values.

        Returns:
            dict: The payload to pass to S3 Batch operations to send the job status.
        """

        results = list()
        try:
            # Get object attributes
            file_path = event.get("tasks")[0].get("s3Key")[1:]
            bucket = event.get("tasks")[0].get("s3BucketArn").split(":::")[-1]
            logger.info(f"Added file to S3 bucket {bucket}: {file_path}")

            # Process file
            file_raw = self.download_file(bucket, file_path)
            file_parsed = self.parse_file(file_raw)
            file_cleaned = self.cleanup_file(pii_key, file_parsed)
            self.write_file(bucket, file_path, file_cleaned, replace=True)

            # Set success parameters
            result_code = "Succeeded"
            result_string = f"Successfully parsed object {file_path}."

        except Exception as error:

            # Mark all other exceptions as permanent failures.
            result_code = "PermanentFailure"
            result_string = str(error)

            # Logg error traceback string
            exception_type, exception_value, exception_traceback = sys.exc_info()
            traceback_string = traceback.format_exception(exception_type, exception_value, exception_traceback)
            err_msg = json.dumps(
                {
                    "errorType": exception_type.__name__,
                    "errorMessage": str(exception_value),
                    "stackTrace": traceback_string,
                }
            )
            logger.error(err_msg)

        finally:
            results.append(
                {"taskId": event["tasks"][0]["taskId"], "resultCode": result_code, "resultString": result_string}
            )
            logger.info(f"Attempt to process {file_path} completed.")
            logger.info("-------------------------------------------------------------------")

        return {
            "invocationSchemaVersion": event["invocationSchemaVersion"],
            "treatMissingKeysAs": "PermanentFailure",
            "invocationId": event["invocationId"],
            "results": results,
        }

    def process_s3_event_notifications(self, event: dict, pii_key: str) -> bool:
        """Wrap the processing steps for S3 events notification Lambda invocations.

        Args:
            event (dict): The event passed when Lambda is invoked by a S3 events notification.
            pii_key (str): The key of values to be replaced by null values.

        Returns:
            bool: Whether the function succeeded or not.
        """
        try:
            # Get object attributes
            file_path = event.get("Records")[0].get("s3").get("object").get("key")
            bucket = event.get("Records")[0].get("s3").get("bucket").get("name")
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
            traceback_string = traceback.format_exception(exception_type, exception_value, exception_traceback)
            err_msg = json.dumps(
                {
                    "errorType": exception_type.__name__,
                    "errorMessage": str(exception_value),
                    "stackTrace": traceback_string,
                }
            )
            logger.error(err_msg)
            result = False

        finally:
            logger.info(f"Attempt to process {file_path} completed.")
            logger.info("-------------------------------------------------------------------")

        return result


def lambda_handler(event, context):
    """Scans the file in a bucket and replace IPs with None values."""
    logger.info("-------------------------------------------------------------------")
    logger.info(f"Lambda function ARN: {context.invoked_function_arn}")
    logger.info(f"CloudWatch log stream name: {context.log_stream_name}")
    logger.info(f"CloudWatch log group name: {context.log_group_name}")
    logger.info(f"Lambda Request ID: {context.aws_request_id}")
    logger.info(f"Lambda function memory limits in MB: {context.memory_limit_in_mb}")

    helper = SegmentBucketCleaner()

    pii_key = "ip"
    if event.get("invocationSchemaVersion"):
        logger.info(f"S3 batch operations task: {event}")
        result = helper.process_s3_batch_operations(event, pii_key)

    elif event.get("Records"):
        logger.info(f"S3 events notification: {event}")
        result = helper.process_s3_event_notifications(event, pii_key)

    else:
        logger.info(
            "Unrecognized event payload. This seems to be neither a S3 notifications, ",
            "nor a S3 Batch Operations job task.",
        )
        result = False

    return result
