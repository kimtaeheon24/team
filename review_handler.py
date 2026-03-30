import json
import boto3
import uuid
from datetime import datetime, timedelta, timezone
from decimal import Decimal

# DynamoDB 연결
dynamodb = boto3.resource('dynamodb')
rev_table = dynamodb.Table('Reviews')      # 테이블명 확인 필요
rest_table = dynamodb.Table('Restaurants') # 테이블명 확인 필요

# Decimal 타입 처리를 위한 인코더
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

def lambda_handler(event, context):
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Content-Type': 'application/json'
    }

    # 한국 시간 설정
    kst = timezone(timedelta(hours=9))
    now_kst = datetime.now(kst).strftime('%Y-%m-%d %H:%M:%S')

    try:
        method = event.get('httpMethod')

        # 1. OPTIONS (CORS)
        if method == 'OPTIONS':
            return {'statusCode': 200, 'headers': headers, 'body': json.dumps('OK')}

        # 2. GET: 리뷰 목록 가져오기
        elif method == 'GET':
            params = event.get('queryStringParameters')
            if not params or 'place_id' not in params:
                return {'statusCode': 200, 'headers': headers, 'body': json.dumps([])}
            
            p_id = str(params['place_id'])
            response = rev_table.query(
                KeyConditionExpression=boto3.dynamodb.conditions.Key('place_id').eq(p_id)
            )
            
            return {
                'statusCode': 200, 
                'headers': headers, 
                'body': json.dumps(response.get('Items', []), ensure_ascii=False, cls=DecimalEncoder)
            }

        # 3. POST: 리뷰 등록
        elif method == 'POST':
            body = json.loads(event.get('body', '{}'))
            
            # 식당 정보 업데이트
            rest_table.put_item(Item={
                'place_id': str(body['place_id']),
                'name': str(body['name']),
                'lat': str(body['lat']),
                'lng': str(body['lng']),
                'updated_at': now_kst
            })
            
            # 리뷰 저장
            rev_table.put_item(Item={
                'place_id': str(body['place_id']),
                'review_id': str(uuid.uuid4()),
                'content': str(body['content']),
                'rating': Decimal(str(body['rating'])), # Decimal 변환
                'user_id': body.get('user_id', 'soohyun_test'),
                'created_at': now_kst
            })
            
            return {
                'statusCode': 200, 
                'headers': headers, 
                'body': json.dumps({'message': 'success', 'time': now_kst})
            }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'message': 'Internal Server Error', 'error': str(e)})
        }
