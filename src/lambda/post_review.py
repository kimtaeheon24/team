import json
import boto3
import os
import uuid
from datetime import datetime
from decimal_encoder import DecimalEncoder

dynamodb = boto3.resource('dynamodb')
# 환경변수 사용 권장 (Terraform에서 설정한 REVIEW_TABLE 참조)
table = dynamodb.Table(os.environ.get('REVIEW_TABLE', 'Reviews'))

def lambda_handler(event, context):
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization'
    }
    
    # 1. CORS 사전 검사 대응
    # HTTP API v2에서는 route_key나 method를 체크합니다.
    method = event.get('requestContext', {}).get('http', {}).get('method', 'POST')
    
    if method == 'OPTIONS':
        return {'statusCode': 200, 'headers': headers}

    try:
        # 2. Cognito 토큰에서 유저 정보 추출
        # API Gateway JWT Authorizer가 넣어주는 경로입니다.
        claims = event.get('requestContext', {}).get('authorizer', {}).get('jwt', {}).get('claims', {})
        user_id = claims.get('sub')       # 유저 고유 ID
        user_email = claims.get('email')   # 유저 이메일 (닉네임 대신 사용 가능)

        if not user_id:
            return {
                'statusCode': 401,
                'headers': headers,
                'body': json.dumps({'error': '인증되지 않은 사용자입니다.'})
            }

        body = json.loads(event.get('body', '{}'))

        # --- [POST] 리뷰 등록 로직 ---
        if method == 'POST':
            place_id = body.get('place_id')
            comment = body.get('comment')
            rating = body.get('rating', 5)
            
            if not place_id or not comment:
                return {'statusCode': 400, 'headers': headers, 'body': json.dumps({'error': '필수 정보 누락'})}

            review_id = str(uuid.uuid4())
            item = {
                'place_id': place_id,           # Partition Key
                'review_id': review_id,         # Sort Key
                'user_id': user_id,             # 작성자 검증용
                'user_email': user_email,       # 화면 표시용
                'rating': rating,
                'comment': comment,
                'created_at': datetime.now().isoformat()
            }
            
            table.put_item(Item=item)
            return {
                'statusCode': 201,
                'headers': headers,
                'body': json.dumps(item, cls=DecimalEncoder, ensure_ascii=False)
            }

        # --- [DELETE] 리뷰 삭제 로직 ---
        elif method == 'DELETE':
            place_id = body.get('place_id')
            review_id = body.get('review_id')

            if not place_id or not review_id:
                return {'statusCode': 400, 'headers': headers, 'body': json.dumps({'error': '필수 정보 누락'})}

            # 1단계: 삭제 전 해당 리뷰의 소유주인지 확인
            response = table.get_item(Key={'place_id': place_id, 'review_id': review_id})
            existing_item = response.get('Item')

            if not existing_item:
                return {'statusCode': 404, 'headers': headers, 'body': json.dumps({'error': '리뷰를 찾을 수 없습니다.'})}

            if existing_item.get('user_id') != user_id:
                return {'statusCode': 403, 'headers': headers, 'body': json.dumps({'error': '본인의 리뷰만 삭제할 수 있습니다.'})}

            # 2단계: 일치하면 삭제
            table.delete_item(Key={'place_id': place_id, 'review_id': review_id})
            
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({'message': '리뷰가 삭제되었습니다.'})
            }

    except Exception as e:
        print(f"Error: {e}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }