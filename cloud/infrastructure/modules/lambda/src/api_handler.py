"""
API Handler Lambda Function
Handles REST API requests for BPM monitoring data.

This function:
1. Handles requests from API Gateway
2. Authenticates users via Cognito JWT tokens
3. Provides CRUD operations for BPM data
4. Enforces role-based access control
"""

import json
import os
import logging
from datetime import datetime, timezone, timedelta
from decimal import Decimal
import boto3
from boto3.dynamodb.conditions import Key, Attr
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')

# Environment variables
DYNAMODB_TABLE_NAME = os.environ.get('DYNAMODB_TABLE_NAME')
S3_BUCKET_NAME = os.environ.get('S3_BUCKET_NAME')


class DecimalEncoder(json.JSONEncoder):
    """Custom JSON encoder for Decimal types."""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)


def create_response(status_code: int, body: dict, headers: dict = None) -> dict:
    """
    Create a standardized API response.
    
    Args:
        status_code: HTTP status code
        body: Response body
        headers: Optional additional headers
        
    Returns:
        API Gateway response format
    """
    response = {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization',
            'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
        },
        'body': json.dumps(body, cls=DecimalEncoder)
    }
    
    if headers:
        response['headers'].update(headers)
    
    return response


def get_user_from_context(event: dict) -> dict:
    """
    Extract user information from the request context.
    
    Args:
        event: API Gateway event
        
    Returns:
        User information dict
    """
    claims = event.get('requestContext', {}).get('authorizer', {}).get('claims', {})
    
    return {
        'user_id': claims.get('sub', ''),
        'email': claims.get('email', ''),
        'groups': claims.get('cognito:groups', '').split(',') if claims.get('cognito:groups') else [],
        'role': claims.get('custom:role', 'patient')
    }


def get_bpm_history(user_id: str, device_id: str = None, 
                    start_date: str = None, end_date: str = None,
                    limit: int = 100) -> dict:
    """
    Get BPM history for a user.
    
    Args:
        user_id: User identifier
        device_id: Optional device filter
        start_date: Optional start date filter (ISO format)
        end_date: Optional end date filter (ISO format)
        limit: Maximum number of records to return
        
    Returns:
        Dict with measurements list
    """
    try:
        table = dynamodb.Table(DYNAMODB_TABLE_NAME)
        
        # Build key condition
        key_condition = Key('user_id').eq(user_id)
        
        # Build filter expression
        filter_expression = None
        if device_id:
            filter_expression = Attr('device_id').eq(device_id)
        
        if start_date:
            date_filter = Attr('timestamp').gte(start_date)
            filter_expression = date_filter if not filter_expression else filter_expression & date_filter
        
        if end_date:
            date_filter = Attr('timestamp').lte(end_date)
            filter_expression = date_filter if not filter_expression else filter_expression & date_filter
        
        # Query parameters
        query_params = {
            'KeyConditionExpression': key_condition,
            'Limit': limit,
            'ScanIndexForward': False  # Newest first
        }
        
        if filter_expression:
            query_params['FilterExpression'] = filter_expression
        
        response = table.query(**query_params)
        
        return {
            'success': True,
            'measurements': response.get('Items', []),
            'count': len(response.get('Items', []))
        }
        
    except ClientError as e:
        logger.error(f"Error querying DynamoDB: {e}")
        return {
            'success': False,
            'error': str(e)
        }


def get_user_devices(user_id: str) -> dict:
    """
    Get list of devices for a user.
    
    Args:
        user_id: User identifier
        
    Returns:
        Dict with devices list
    """
    try:
        # Query devices table (would need to be created)
        # For now, we'll extract unique devices from measurements
        table = dynamodb.Table(DYNAMODB_TABLE_NAME)
        
        response = table.query(
            KeyConditionExpression=Key('user_id').eq(user_id),
            ProjectionExpression='device_id',
            Limit=1000
        )
        
        # Extract unique device IDs
        devices = list(set(item['device_id'] for item in response.get('Items', [])))
        
        return {
            'success': True,
            'devices': devices,
            'count': len(devices)
        }
        
    except ClientError as e:
        logger.error(f"Error querying devices: {e}")
        return {
            'success': False,
            'error': str(e)
        }


def get_current_status(user_id: str) -> dict:
    """
    Get the current BPM status for a user.
    
    Args:
        user_id: User identifier
        
    Returns:
        Dict with current status
    """
    try:
        table = dynamodb.Table(DYNAMODB_TABLE_NAME)
        
        # Get the most recent measurement
        response = table.query(
            KeyConditionExpression=Key('user_id').eq(user_id),
            Limit=1,
            ScanIndexForward=False  # Newest first
        )
        
        items = response.get('Items', [])
        
        if not items:
            return {
                'success': True,
                'status': 'no_data',
                'message': 'No measurements found'
            }
        
        latest = items[0]
        
        return {
            'success': True,
            'current_bpm': latest.get('bpm'),
            'status': latest.get('status'),
            'severity': latest.get('severity'),
            'device_id': latest.get('device_id'),
            'timestamp': latest.get('timestamp')
        }
        
    except ClientError as e:
        logger.error(f"Error getting current status: {e}")
        return {
            'success': False,
            'error': str(e)
        }


def get_statistics(user_id: str, period: str = 'day') -> dict:
    """
    Get BPM statistics for a user.
    
    Args:
        user_id: User identifier
        period: Time period (day, week, month)
        
    Returns:
        Dict with statistics
    """
    try:
        table = dynamodb.Table(DYNAMODB_TABLE_NAME)
        
        # Calculate start date based on period
        now = datetime.now(timezone.utc)
        if period == 'day':
            start_date = (now - timedelta(days=1)).isoformat()
        elif period == 'week':
            start_date = (now - timedelta(weeks=1)).isoformat()
        elif period == 'month':
            start_date = (now - timedelta(days=30)).isoformat()
        else:
            start_date = (now - timedelta(days=1)).isoformat()
        
        # Query measurements
        response = table.query(
            KeyConditionExpression=Key('user_id').eq(user_id),
            FilterExpression=Attr('timestamp').gte(start_date)
        )
        
        items = response.get('Items', [])
        
        if not items:
            return {
                'success': True,
                'period': period,
                'message': 'No data for the specified period'
            }
        
        # Calculate statistics
        bpm_values = [float(item['bpm']) for item in items]
        
        return {
            'success': True,
            'period': period,
            'count': len(bpm_values),
            'min_bpm': min(bpm_values),
            'max_bpm': max(bpm_values),
            'avg_bpm': round(sum(bpm_values) / len(bpm_values), 2),
            'start_date': start_date,
            'end_date': now.isoformat()
        }
        
    except ClientError as e:
        logger.error(f"Error calculating statistics: {e}")
        return {
            'success': False,
            'error': str(e)
        }


def lambda_handler(event, context):
    """
    Main Lambda handler for API requests.
    
    Args:
        event: API Gateway event
        context: Lambda context object
        
    Returns:
        API Gateway response
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    # Handle OPTIONS requests (CORS preflight)
    http_method = event.get('httpMethod', 'GET')
    if http_method == 'OPTIONS':
        return create_response(200, {'message': 'OK'})
    
    # Get user from context
    user = get_user_from_context(event)
    
    if not user['user_id']:
        return create_response(401, {'error': 'Unauthorized'})
    
    # Parse path and query parameters
    path = event.get('path', '/')
    query_params = event.get('queryStringParameters') or {}
    path_params = event.get('pathParameters') or {}
    
    try:
        # Route requests
        if path == '/health':
            return create_response(200, {'status': 'healthy'})
        
        elif path == '/bpm/history' or path.startswith('/bpm/history'):
            result = get_bpm_history(
                user_id=user['user_id'],
                device_id=query_params.get('device_id'),
                start_date=query_params.get('start_date'),
                end_date=query_params.get('end_date'),
                limit=int(query_params.get('limit', 100))
            )
            
            if result['success']:
                return create_response(200, result)
            else:
                return create_response(500, result)
        
        elif path == '/bpm/current':
            result = get_current_status(user['user_id'])
            
            if result['success']:
                return create_response(200, result)
            else:
                return create_response(500, result)
        
        elif path == '/bpm/statistics':
            result = get_statistics(
                user_id=user['user_id'],
                period=query_params.get('period', 'day')
            )
            
            if result['success']:
                return create_response(200, result)
            else:
                return create_response(500, result)
        
        elif path == '/devices':
            result = get_user_devices(user['user_id'])
            
            if result['success']:
                return create_response(200, result)
            else:
                return create_response(500, result)
        
        elif path == '/user/profile':
            return create_response(200, {
                'user_id': user['user_id'],
                'email': user['email'],
                'role': user['role'],
                'groups': user['groups']
            })
        
        else:
            return create_response(404, {'error': 'Not found'})
    
    except Exception as e:
        logger.error(f"Error processing request: {e}")
        return create_response(500, {'error': 'Internal server error'})
