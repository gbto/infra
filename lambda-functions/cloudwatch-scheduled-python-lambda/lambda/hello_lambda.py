import os
import datetime
import boto3


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

    helper = S3Toolkit()

    bucket = os.environ.get('bucket_name')
    file_path = 'test.json'
    data = {'this_is_a_test': "for writing to S3 with lambda",
            "inserted_at": helper.execution_date}

    helper.write_file(bucket, file_path, data)

    return "This lambda function seems to execute properly."
