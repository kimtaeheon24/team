import json
import boto3
from decimal import Decimal

# 숫자가 Decimal 형태일 때 오류 안 나게 해주는 도구
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Restaurants')

def lambda_handler(event, context):
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type'
    }
    
    try:
        # 전체 식당 정보를 긁어와서 지도에 뿌려줍니다.
        response = table.scan()
        items = response.get('Items', [])

        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps(items, ensure_ascii=False, cls=DecimalEncoder)
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }