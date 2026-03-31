import json
import boto3
from decimal import Decimal

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal): return float(obj)
        return super(DecimalEncoder, self).default(obj)

dynamodb = boto3.resource('dynamodb')
table_reviews = dynamodb.Table('Reviews')

def lambda_handler(event, context):
    method = event.get('requestContext', {}).get('http', {}).get('method', 'UNKNOWN')
    query_params = event.get('queryStringParameters', {})
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Content-Type': 'application/json; charset=utf-8'
    }

    if method == 'OPTIONS': return {'statusCode': 200, 'headers': headers}

    try:
        if method == 'GET':
            place_id = query_params.get('place_id')
            all_items = table_reviews.scan().get('Items', [])
            items = [i for i in all_items if i.get('place_id') == place_id] if place_id else all_items
            return {'statusCode': 200, 'headers': headers, 'body': json.dumps(items, cls=DecimalEncoder, ensure_ascii=False)}
        elif method == 'POST':
            body = json.loads(event.get('body', '{}'))
            table_reviews.put_item(Item=body)
            return {'statusCode': 201, 'headers': headers, 'body': json.dumps({'message': '리뷰 등록 성공'})}
    except Exception as e:
        return {'statusCode': 500, 'headers': headers, 'body': json.dumps({'error': str(e)})}
