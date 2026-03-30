import json
import boto3
from decimal import Decimal

# 1. 이 클래스는 def lambda_handler와 같은 라인(맨 왼쪽)에 있어야 합니다.
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
        # 2. 여기 안쪽은 반드시 4칸 들여쓰기가 되어야 합니다.
        response = table.scan()
        items = response.get('Items', [])

        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps(items, ensure_ascii=False, cls=DecimalEncoder)
        }
        
    except Exception as e:
        print(e) # 로그 확인용
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error_message': str(e)})
        }
