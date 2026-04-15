import json
import boto3
import os
import uuid
from datetime import datetime
from decimal_encoder import DecimalEncoder

dynamodb = boto3.resource('dynamodb')
review_table = dynamodb.Table(os.environ.get('REVIEW_TABLE', 'Reviews'))
restaurant_table = dynamodb.Table(os.environ.get('RESTAURANT_TABLE', 'Restaurants'))

def lambda_handler(event, context):
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization'
    }

    method = event.get('requestContext', {}).get('http', {}).get('method')

    if method == 'OPTIONS':
        return {'statusCode': 200, 'headers': headers}

    try:
        # [1] 인증 정보 가져오기 로직 강화
        authorizer = event.get('requestContext', {}).get('authorizer', {})
        jwt_data = authorizer.get('jwt', {})
        claims = jwt_data.get('claims', {})
        
        user_id = claims.get('sub')
        # Cognito 설정에 따라 email 키값이 다를 수 있으므로 여러 시도
        user_email = claims.get('email') or claims.get('custom:email') or claims.get('username')

        # 디버깅을 위해 로그 출력 (CloudWatch에서 확인 가능)
        print(f"User ID: {user_id}, User Email: {user_email}")

        if not user_id:
            return {'statusCode': 401, 'headers': headers, 'body': json.dumps({'error': '인증 필요'})}

        body = json.loads(event.get('body') or '{}')

        # 🔥 POST: 리뷰 등록
        if method == 'POST':
            place_id = body.get('place_id')
            comment = body.get('comment')
            rating = int(body.get('rating', 5))
            

            if not place_id or not comment:
                return {'statusCode': 400, 'headers': headers, 'body': json.dumps({'error': '필수값 없음'})}

            review_item = {
                'place_id': str(place_id),
                'review_id': str(uuid.uuid4()),
                'user_id': user_id,
                'user_email': user_email if user_email else "익명@unknown", # 이메일이 없으면 기본값 저장
                'rating': rating,
                'comment': comment,
                'created_at': datetime.now().isoformat()
            }
            review_table.put_item(Item=review_item)

            return {
                'statusCode': 201,
                'headers': headers,
                'body': json.dumps(review_item, cls=DecimalEncoder, ensure_ascii=False)
            }

        # 🔥 DELETE: 리뷰 삭제
        elif method == 'DELETE':
            place_id = body.get('place_id')
            review_id = body.get('review_id')

            if not place_id or not review_id:
                return {'statusCode': 400, 'headers': headers, 'body': json.dumps({'error': '필수값 없음'})}

            review_table.delete_item(Key={'place_id': str(place_id), 'review_id': str(review_id)})
            return {'statusCode': 200, 'headers': headers, 'body': json.dumps({'message': '삭제 완료'})}

    except Exception as e:
        print("CRITICAL ERROR:", str(e))
        return {'statusCode': 500, 'headers': headers, 'body': json.dumps({'error': str(e)})}