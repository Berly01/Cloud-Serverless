"""
BPM Processor Lambda Function
Processes incoming BPM measurements from IoT Core devices.

This function:
1. Validates incoming BPM data
2. Classifies the BPM status (normal, warning, critical)
3. Stores data in DynamoDB for real-time access
4. Archives data to S3 for historical analysis
5. Triggers SNS alerts for abnormal readings
"""

import json
import os
import logging
from datetime import datetime, timezone
from decimal import Decimal
import boto3
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')
sns = boto3.client('sns')

# Environment variables
DYNAMODB_TABLE_NAME = os.environ.get('DYNAMODB_TABLE_NAME')
S3_BUCKET_NAME = os.environ.get('S3_BUCKET_NAME')
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')

# BPM Thresholds
BPM_CRITICAL_LOW = int(os.environ.get('BPM_CRITICAL_LOW', 40))
BPM_WARNING_LOW = int(os.environ.get('BPM_WARNING_LOW', 50))
BPM_WARNING_HIGH = int(os.environ.get('BPM_WARNING_HIGH', 100))
BPM_CRITICAL_HIGH = int(os.environ.get('BPM_CRITICAL_HIGH', 150))


def classify_bpm(bpm: int) -> dict:
    """
    Classify BPM reading into status categories.
    
    Args:
        bpm: The heart rate measurement in beats per minute
        
    Returns:
        dict with status and severity
    """
    if bpm <= BPM_CRITICAL_LOW:
        return {"status": "critical", "severity": "critical_low", "message": f"Critical: Very low BPM ({bpm})"}
    elif bpm <= BPM_WARNING_LOW:
        return {"status": "warning", "severity": "warning_low", "message": f"Warning: Low BPM ({bpm})"}
    elif bpm >= BPM_CRITICAL_HIGH:
        return {"status": "critical", "severity": "critical_high", "message": f"Critical: Very high BPM ({bpm})"}
    elif bpm >= BPM_WARNING_HIGH:
        return {"status": "warning", "severity": "warning_high", "message": f"Warning: High BPM ({bpm})"}
    else:
        return {"status": "normal", "severity": "normal", "message": "Normal BPM reading"}


def validate_payload(payload: dict) -> tuple:
    """
    Validate the incoming BPM measurement payload.
    
    Args:
        payload: The incoming message payload
        
    Returns:
        Tuple of (is_valid, error_message)
    """
    required_fields = ['user_id', 'device_id', 'timestamp', 'bpm']
    
    for field in required_fields:
        if field not in payload:
            return False, f"Missing required field: {field}"
    
    # Validate BPM is a number
    try:
        bpm = int(payload['bpm'])
        if bpm < 0 or bpm > 300:
            return False, f"BPM value out of valid range: {bpm}"
    except (ValueError, TypeError):
        return False, f"Invalid BPM value: {payload['bpm']}"
    
    return True, None


def store_in_dynamodb(measurement: dict) -> bool:
    """
    Store BPM measurement in DynamoDB.
    
    Args:
        measurement: The measurement data to store
        
    Returns:
        True if successful, False otherwise
    """
    try:
        table = dynamodb.Table(DYNAMODB_TABLE_NAME)
        
        # Create composite sort key
        timestamp_device = f"{measurement['timestamp']}#{measurement['device_id']}"
        
        # Parse date for GSI
        measurement_date = measurement['timestamp'][:10]  # YYYY-MM-DD
        
        # Calculate TTL (90 days from now)
        ttl = int(datetime.now(timezone.utc).timestamp()) + (90 * 24 * 60 * 60)
        
        item = {
            'user_id': measurement['user_id'],
            'timestamp_device': timestamp_device,
            'device_id': measurement['device_id'],
            'timestamp': measurement['timestamp'],
            'measurement_date': measurement_date,
            'bpm': Decimal(str(measurement['bpm'])),
            'status': measurement['classification']['status'],
            'severity': measurement['classification']['severity'],
            'ttl': ttl,
            'created_at': datetime.now(timezone.utc).isoformat()
        }
        
        table.put_item(Item=item)
        logger.info(f"Stored measurement in DynamoDB for user {measurement['user_id']}")
        return True
        
    except ClientError as e:
        logger.error(f"Error storing in DynamoDB: {e}")
        return False


def archive_to_s3(measurement: dict) -> bool:
    """
    Archive BPM measurement to S3 for historical storage.
    
    Args:
        measurement: The measurement data to archive
        
    Returns:
        True if successful, False otherwise
    """
    try:
        # Parse timestamp for S3 path
        ts = datetime.fromisoformat(measurement['timestamp'].replace('Z', '+00:00'))
        
        # S3 key: user_id/device_id/year/month/day/timestamp.json
        s3_key = (
            f"{measurement['user_id']}/"
            f"{measurement['device_id']}/"
            f"{ts.year}/{ts.month:02d}/{ts.day:02d}/"
            f"{ts.strftime('%H%M%S%f')}.json"
        )
        
        s3.put_object(
            Bucket=S3_BUCKET_NAME,
            Key=s3_key,
            Body=json.dumps(measurement),
            ContentType='application/json'
        )
        
        logger.info(f"Archived measurement to S3: {s3_key}")
        return True
        
    except ClientError as e:
        logger.error(f"Error archiving to S3: {e}")
        return False


def send_alert(measurement: dict) -> bool:
    """
    Send SNS alert for critical or warning BPM readings.
    
    Args:
        measurement: The measurement data with classification
        
    Returns:
        True if successful, False otherwise
    """
    try:
        classification = measurement['classification']
        
        if classification['status'] == 'normal':
            return True  # No alert needed
        
        message = {
            'default': classification['message'],
            'email': (
                f"BPM Alert for User: {measurement['user_id']}\n"
                f"Device: {measurement['device_id']}\n"
                f"BPM: {measurement['bpm']}\n"
                f"Status: {classification['status'].upper()}\n"
                f"Time: {measurement['timestamp']}\n"
                f"\nPlease take appropriate action."
            ),
            'sms': f"BPM Alert: {classification['message']} - User: {measurement['user_id']}"
        }
        
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Message=json.dumps(message),
            MessageStructure='json',
            Subject=f"BPM Alert: {classification['status'].upper()}"
        )
        
        logger.info(f"Sent {classification['status']} alert for user {measurement['user_id']}")
        return True
        
    except ClientError as e:
        logger.error(f"Error sending SNS alert: {e}")
        return False


def lambda_handler(event, context):
    """
    Main Lambda handler for processing BPM measurements.
    
    Args:
        event: The incoming event from IoT Core
        context: Lambda context object
        
    Returns:
        Response dict with processing status
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    processed = 0
    errors = 0
    
    # Handle both single messages and batches
    messages = event if isinstance(event, list) else [event]
    
    for message in messages:
        try:
            # Validate payload
            is_valid, error = validate_payload(message)
            if not is_valid:
                logger.error(f"Invalid payload: {error}")
                errors += 1
                continue
            
            # Classify BPM
            bpm = int(message['bpm'])
            classification = classify_bpm(bpm)
            
            # Create measurement record
            measurement = {
                **message,
                'bpm': bpm,
                'classification': classification
            }
            
            # Store in DynamoDB
            if not store_in_dynamodb(measurement):
                errors += 1
                continue
            
            # Archive to S3
            archive_to_s3(measurement)  # Non-critical, continue even if fails
            
            # Send alerts if needed
            if classification['status'] != 'normal':
                send_alert(measurement)
            
            processed += 1
            
        except Exception as e:
            logger.error(f"Error processing message: {e}")
            errors += 1
    
    response = {
        'statusCode': 200,
        'body': {
            'processed': processed,
            'errors': errors,
            'total': len(messages)
        }
    }
    
    logger.info(f"Processing complete: {response['body']}")
    return response
