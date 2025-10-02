"""
Cloud CV Visitor Counter Lambda Function - Fixed Version
Handles visitor count tracking with DynamoDB
"""

import json
import boto3
import os
from datetime import datetime
from decimal import Decimal

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('DYNAMODB_TABLE', 'visitor-counter')
table = dynamodb.Table(table_name)

def decimal_default(obj):
    """Convert Decimal objects to int/float for JSON serialization"""
    if isinstance(obj, Decimal):
        return int(obj) if obj % 1 == 0 else float(obj)
    raise TypeError

def lambda_handler(event, context):
    """
    Lambda handler for visitor counter API
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        dict: API Gateway response
    """
    try:
        # Handle CORS preflight request
        if event.get('httpMethod') == 'OPTIONS':
            return {
                'statusCode': 200,
                'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type',
                    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'
                },
                'body': json.dumps({'message': 'CORS preflight'})
            }
        
        # Get current visitor count
        response = table.get_item(
            Key={'id': 'visitor_count'}
        )
        
        if 'Item' in response:
            current_count = int(response['Item']['count'])
        else:
            current_count = 0
        
        # Increment visitor count
        new_count = current_count + 1
        
        # Update DynamoDB
        table.put_item(
            Item={
                'id': 'visitor_count',
                'count': new_count,
                'last_updated': datetime.utcnow().isoformat(),
                'timestamp': int(datetime.utcnow().timestamp())
            }
        )
        
        # Return response with proper JSON serialization
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
                'Content-Type': 'application/json'
            },
            'body': json.dumps({
                'visitor_count': new_count,
                'timestamp': datetime.utcnow().isoformat(),
                'status': 'success'
            }, default=decimal_default)
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Content-Type': 'application/json'
            },
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e),
                'status': 'error'
            }, default=decimal_default)
        }
