import json
import boto3
import os
import uuid
from datetime import datetime
from decimal_encoder import DecimalEncoder

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ.get('REVIEW_TABLE', 'Reviews'))

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
        claims = event.get('requestContext', {}).get('authorizer', {}).get('jwt', {}).get('claims', {})
        user_id = claims.get('sub')
        user_email = claims.get('email')

        if not user_id:
            return {
                'statusCode': 401,
                'headers': headers,
                'body': json.dumps({'error': '인증 필요'})
            }

        body = json.loads(event.get('body') or '{}')

        # 🔥 POST
        if method == 'POST':
            place_id = body.get('place_id')
            comment = body.get('comment')
            rating = int(body.get('rating', 5))  # ✅ 수정

            if not place_id or not comment:
                return {'statusCode': 400, 'headers': headers, 'body': json.dumps({'error': '필수값 없음'})}

            item = {
                'place_id': place_id,
                'review_id': str(uuid.uuid4()),
                'user_id': user_id,
                'user_email': user_email,
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

        # 🔥 DELETE
        elif method == 'DELETE':
            place_id = body.get('place_id')
            review_id = body.get('review_id')

            if not place_id or not review_id:
                return {'statusCode': 400, 'headers': headers, 'body': json.dumps({'error': '필수값 없음'})}

            response = table.get_item(Key={'place_id': place_id, 'review_id': review_id})
            item = response.get('Item')

            if not item:
                return {'statusCode': 404, 'headers': headers, 'body': json.dumps({'error': '없음'})}

            if item.get('user_id') != user_id:
                return {'statusCode': 403, 'headers': headers, 'body': json.dumps({'error': '권한 없음'})}

            table.delete_item(Key={'place_id': place_id, 'review_id': review_id})

            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({'message': '삭제 완료'})
            }

    except Exception as e:
        print("ERROR:", e)
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }