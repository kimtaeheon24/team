import json
import boto3
import os
from decimal_encoder import DecimalEncoder

dynamodb = boto3.resource('dynamodb')

table_name = os.environ.get('RESTAURANT_TABLE', 'Restaurants')
table = dynamodb.Table(table_name)

def lambda_handler(event, context):

    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization'
    }

    if event.get('requestContext', {}).get('http', {}).get('method') == 'OPTIONS':
        return {'statusCode': 200, 'headers': headers}

    try:
        response = table.scan()
        items = response.get('Items', [])

        # 🔥 핵심: 데이터 보정
        result = []
        for item in items:
            result.append({
                "place_id": item.get("place_id"),
                "name": item.get("name"),
                "address": item.get("address"),
                "category": item.get("category"),
                "lat": item.get("lat"),
                "lng": item.get("lng"),
                "bookmark_count": item.get("bookmark_count", 0)  # ⭐ 없으면 0
            })

        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps(result, ensure_ascii=False, cls=DecimalEncoder)
        }

    except Exception as e:
        print(f"Error: {e}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }