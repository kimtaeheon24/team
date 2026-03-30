import json
import boto3
import os
from datetime import datetime, timedelta, timezone
from boto3.dynamodb.conditions import Key, Attr

# DynamoDB 연결
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Bookmarks') 

def lambda_handler(event, context):
    # 테라폼에서 설정한 환경 변수 읽기 (설정 안 되어 있으면 '*' 사용)
    cors_origin = os.environ.get('CORS_ORIGIN', '*')
    
    headers = {
        'Access-Control-Allow-Origin': cors_origin,
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS, DELETE',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Content-Type': 'application/json'
    }

    # 한국 시간 설정
    kst = timezone(timedelta(hours=9))
    now_kst = datetime.now(kst).strftime('%Y-%m-%d %H:%M:%S')

    # HTTP API(v2)에서는 routeKey나 method를 확인하는 방식이 다를 수 있어 유연하게 처리합니다.
    method = event.get('requestContext', {}).get('http', {}).get('method', event.get('httpMethod'))

    try:
        # 1. CORS 대응 (OPTIONS)
        if method == 'OPTIONS':
            return {'statusCode': 200, 'headers': headers, 'body': json.dumps('OK')}

        # 2. 찜하기 토글 로직 (POST)
        elif method == 'POST':
            body = json.loads(event.get('body', '{}'))
            
            # ⭐ 프론트엔드 getUserId()에서 보낸 ID를 우선 사용합니다.
            user_id = str(body.get('userId', body.get('user_id', 'guest_user')))
            place_id = str(body.get('place_id'))
            place_name = body.get('place_name', '이름 없음')
            
            if user_id == 'guest_user':
                print("Warning: Guest user attempting to bookmark.")

            # 기존 데이터 확인
            response = table.get_item(Key={
                'user_id': user_id,
                'place_id': place_id
            })
            
            if 'Item' in response:
                # 이미 있다면 삭제 (찜 취소)
                table.delete_item(Key={
                    'user_id': user_id,
                    'place_id': place_id
                })
                return {
                    'statusCode': 200,
                    'headers': headers,
                    'body': json.dumps({'message': '찜 취소됨', 'status': 'removed', 'userId': user_id})
                }
            else:
                # 없다면 등록 (찜 하기)
                table.put_item(Item={
                    'user_id': user_id,
                    'place_id': place_id,
                    'place_name': place_name,
                    'created_at': now_kst
                })
                return {
                    'statusCode': 200,
                    'headers': headers,
                    'body': json.dumps({'message': '찜 완료', 'status': 'added', 'userId': user_id})
                }

        # 3. 찜 목록 조회 (GET)
        elif method == 'GET':
            params = event.get('queryStringParameters') or {}
            place_id = params.get('place_id')
            
            if place_id:
                # 특정 장소의 총 찜 개수 확인
                response = table.scan(
                    FilterExpression=Attr('place_id').eq(str(place_id))
                )
            else:
                # ⭐ 쿼리 파라미터로 넘어온 user_id를 사용
                user_id = params.get('userId', params.get('user_id', 'guest_user'))
                response = table.query(
                    KeyConditionExpression=Key('user_id').eq(user_id)
                )
            
            return {
                'statusCode': 200, 
                'headers': headers, 
                'body': json.dumps(response.get('Items', []), ensure_ascii=False)
            }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'message': 'Internal Server Error', 'error': str(e)})
        }