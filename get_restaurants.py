import json
import boto3
from decimal import Decimal

# Decimal 처리를 위한 인코더
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Restaurants')

def lambda_handler(event, context):
    # CORS 헤더 설정 (브라우저에서 호출 가능하게 함)
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type'
    }

    # 1. 브라우저의 사전 검사(OPTIONS) 대응
    if event.get('httpMethod') == 'OPTIONS':
        return {'statusCode': 200, 'headers': headers}

    try:
        method = event.get('httpMethod')

        # --- [GET] 지도에 마크 표시를 위해 전체 데이터 조회 ---
        if method == 'GET':
            response = table.scan()
            items = response.get('Items', [])
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps(items, ensure_ascii=False, cls=DecimalEncoder)
            }

        # --- [POST] 북마크 클릭 시 Restaurants 테이블에 저장 ---
        elif method == 'POST':
            # 프론트엔드에서 보낸 식당 정보를 읽어옴
            body = json.loads(event.get('body', '{}'))
            
            # DB에 저장 (식당ID, 이름, 좌표, 사용자ID 등)
            table.put_item(Item=body)
            
            return {
                'statusCode': 201,
                'headers': headers,
                'body': json.dumps({'message': '북마크 저장 성공!'}, ensure_ascii=False)
            }

    except Exception as e:
        print(f"Error: {e}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }