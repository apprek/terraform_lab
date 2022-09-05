
from datetime import datetime
import os
from sqlite3 import Timestamp
import boto3
import json



def handler(event, context):
    sqs_client = boto3.client("sqs" )
    dynamodb = boto3.resource('dynamodb' )
    sts_client = boto3.client("sts")
    account_id= sts_client.get_caller_identity()["Account"]
    region = sqs_client.meta.region_name
    

    sqs_response = sqs_client.receive_message(
        QueueUrl= f"https://sqs.{region}.amazonaws.com/{account_id}/claim-check-s3-event-notification-queue",
        AttributeNames=['All'],
        WaitTimeSeconds=20,
        MaxNumberOfMessages=10)
    print(f"Number of messages received: {len(sqs_response.get('Messages'))}")

    for message in sqs_response['Messages']:
        message = json.loads(sqs_response['Messages'][0]['Body'])
        print(message)

    # Write message to DynamoDB
        table = dynamodb.Table('ClaimCheck')
        S3Bucket = message['Records'][0]['s3']['bucket']['name']
        ObjectKey = message['Records'][0]['s3']['object']['key']
        

        db_response = table.put_item(
            Item={
                'S3Bucket': S3Bucket,
                'ObjectKey': ObjectKey,
            }
        )
        print("Wrote message to DynamoDB:", json.dumps(db_response))
        print(S3Bucket)
        print(ObjectKey)
        return{
            'statusCode': 200,
            'body': db_response
        }
        
