import json
import boto3
from decimal import Decimal

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal): return float(obj)
        return super(DecimalEncoder, self).default(obj)

dynamodb = boto3.resource('dynamodb')
table_restaurants = dynamodb.Table('Restaurants')

def lambda_handler(event, context):
    method = event.get('requestContext', {}).get('http', {}).get('method', 'UNKNOWN')
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Content-Type': 'application/json; charset=utf-8'
    }

    if method == 'OPTIONS': return {'statusCode': 200, 'headers': headers}

    try:
        if method == 'GET':
            items = table_restaurants.scan().get('Items', [])
            return {'statusCode': 200, 'headers': headers, 'body': json.dumps(items, cls=DecimalEncoder, ensure_ascii=False)}
        # (POST/DELETE 로직은 일단 생략하거나 아까 코드를 그대로 넣으셔도 됩니다)
    except Exception as e:
        return {'statusCode': 500, 'headers': headers, 'body': json.dumps({'error': str(e)})}
