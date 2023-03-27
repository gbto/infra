import boto3
import pandas as pd
import awswrangler as wr


def get_bucket_inventory(bucket: str, profile="default") -> list[str]:
    """Extract the list of files from a s3 bucket.

    Args:
        bucket (str): The name of the bucket for which we extracts the objects inventory.
        profile (str, optional): The AWS config profile used. Defaults to 'sbx-mfa'.

    Returns:
        list(str): The list of objects paths in the bucket.
    """

    boto3.setup_default_session(profile_name=profile)
    inventory = wr.s3.list_objects(f"s3://{bucket}")
    inventory = [x.split(f"s3://{bucket}")[1] for x in inventory]
    return inventory


def create_batch_operations_manifest(bucket: str, inventory: list[str], extension: str = ".gz") -> str:
    """Create the S3 files manifest required by S3 Batch Operations job.

    Args:
        bucket (str): The bucket where files are located.
        inventory (list[str]): The inventory of the files in the bucket.
        extension (str, optional): The extension of the file to process. Defaults to '.gz'.

    Returns:
        str: The csv string of the S3 Job manifest.
    """
    manifest = [[bucket, key] for key in inventory]
    manifest = pd.DataFrame(manifest)
    manifest = manifest[manifest[1].str.endswith(extension)]
    manifest = manifest.to_csv(index=False, header=False, sep=",")
    return manifest


def compare_buckets(old_bucket: str, new_bucket, profile="sbx-mfa") -> dict:
    """Compare the file inventories of the old and new buckets to validate the migration process.

    Args:
        old_bucket (str): The source bucket of the migration.
        new_bucket (_type_): The target bucket of the migration.
        profile (str, optional): The AWS profile to use for the extraction. Defaults to 'sbx-mfa'.

    Returns:
        dict: The lists used for comparison in this test.
    """
    inventory_new = get_bucket_inventory(new_bucket, profile)
    inventory_old = get_bucket_inventory(old_bucket, profile)
    print(f"# files in new bucket: {len(inventory_new)}")
    print(f"# files in old bucket: {len(inventory_old)}")

    non_relevant_files_new = [x for x in inventory_new if not x.endswith(".json.gzip")]
    non_relevant_files_old = [x for x in inventory_old if not x.endswith(".gz")]
    print(f"# non-logs files in new bucket: {len(non_relevant_files_new)}")
    print(f"# non-logs files in old bucket: {len(non_relevant_files_old)}")

    inventory_new_paths = [
        x.split(new_bucket)[-1].strip(".json.gzip") for x in inventory_new if x.endswith(".json.gzip")
    ]
    inventory_old_paths = [x.split(old_bucket)[-1].strip(".gz") for x in inventory_old if x.endswith(".gz")]
    print(f"List of .gz files is same as list of .gzip files: {inventory_new_paths == inventory_old_paths}")

    data = {
        "inventory_new": inventory_new,
        "inventory_old": inventory_old,
        "non_relevant_files_new": non_relevant_files_new,
        "non_relevant_files_old": non_relevant_files_old,
        "inventory_new_paths": inventory_new_paths,
        "inventory_old_paths": inventory_old_paths,
    }

    return data


if __name__ == "__main__":

    create_job_manifest = False
    profile = "prd-mfa"
    platform = "mobile"

    old_bucket = f"ledger-segment-analytics-{platform}-prod"
    new_bucket = f"ledgerlive-segment-analytics-{platform}-prod"
    comparison_results = compare_buckets(old_bucket, new_bucket, profile)

    if create_job_manifest:
        inventory = get_bucket_inventory(bucket=new_bucket, profile=profile)
        manifest = create_batch_operations_manifest(new_bucket, inventory, ".gz")
        with open(f"{new_bucket}-manifest.csv", "w") as f:
            f.write(manifest)
