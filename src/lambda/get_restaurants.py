import json
import boto3
import os
from boto3.dynamodb.conditions import Key
from decimal_encoder import DecimalEncoder

dynamodb = boto3.resource('dynamodb')
table_restaurants = dynamodb.Table(os.environ.get('RESTAURANT_TABLE', 'Restaurants'))

def lambda_handler(event, context):
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization'
    }

    method = event.get('requestContext', {}).get('http', {}).get('method')

    if method == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': headers
        }

    if method != 'GET':
        return {
            'statusCode': 405,
            'headers': headers,
            'body': json.dumps({'error': '허용되지 않은 메서드입니다.'}, ensure_ascii=False)
        }

    try:
        query_params = event.get('queryStringParameters') or {}
        limit = int(query_params.get('limit', 20))

        response = table_restaurants.query(
            IndexName='recommended_index',
            KeyConditionExpression=Key('recommended_pk').eq('RECOMMENDED'),
            ScanIndexForward=False,  # recommended_score 내림차순
            Limit=limit
        )

        items = response.get('Items', [])

        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps(items, cls=DecimalEncoder, ensure_ascii=False)
        }

    except Exception as e:
        print(f"CRITICAL ERROR: {str(e)}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)}, ensure_ascii=False)
        }