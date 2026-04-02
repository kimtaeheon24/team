import json
import boto3
import os  # 환경 변수를 읽기 위해 필요합니다.
from decimal import Decimal
from decimal_encoder import DecimalEncoder # 아까 만든 레이어에서 가져옵니다.

dynamodb = boto3.resource('dynamodb')

# 테라폼에서 설정한 환경 변수 'RESTAURANT_TABLE'의 값을 가져옵니다.
# 만약 환경 변수가 없으면 기본값으로 'Restaurants'를 사용합니다.
table_name = os.environ.get('RESTAURANT_TABLE', 'Restaurants')
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    # 헤더 설정 (CORS 대응)
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization'
    }
    
    # 브라우저 사전 검사(OPTIONS) 대응
    if event.get('requestContext', {}).get('http', {}).get('method') == 'OPTIONS':
        return {'statusCode': 200, 'headers': headers}
    
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
        print(f"Error: {e}") # 로그 확인용
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }