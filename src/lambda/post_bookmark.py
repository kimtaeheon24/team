import json
import boto3
import os
from datetime import datetime
from decimal_encoder import DecimalEncoder

dynamodb = boto3.resource('dynamodb')
# 환경변수 참조 (Terraform 설정 권장)
bookmark_table = dynamodb.Table(os.environ.get('BOOKMARK_TABLE', 'Bookmarks'))
restaurant_table = dynamodb.Table(os.environ.get('RESTAURANT_TABLE', 'Restaurants'))

def lambda_handler(event, context):
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization'
    }
    
    # 1. CORS 사전 검사 대응
    if event.get('requestContext', {}).get('http', {}).get('method') == 'OPTIONS':
        return {'statusCode': 200, 'headers': headers}

    try:
        # 2. Cognito 토큰에서 유저 정보 추출
        claims = event.get('requestContext', {}).get('authorizer', {}).get('jwt', {}).get('claims', {})
        user_id = claims.get('sub')
        
        if not user_id:
            return {'statusCode': 401, 'headers': headers, 'body': json.dumps({'error': '로그인이 필요합니다.'})}

        body = json.loads(event.get('body', '{}'))
        place_id = str(body.get('place_id'))
        
        if not place_id:
            return {'statusCode': 400, 'headers': headers, 'body': json.dumps({'error': 'place_id가 없습니다.'})}

        # 3. 이미 찜했는지 확인 (조회)
        # Bookmarks 테이블 구성: PK(user_id), SK(place_id)
        response = bookmark_table.get_item(Key={'user_id': user_id, 'place_id': place_id})
        is_bookmarked = 'Item' in response

        if is_bookmarked:
            # --- [찜 취소 로직] ---
            # 1. 내 북마크 삭제
            bookmark_table.delete_item(Key={'user_id': user_id, 'place_id': place_id})
            # 2. 식당 테이블의 전체 찜 갯수 -1 (0 미만으로 내려가지 않도록 처리 가능)
            restaurant_table.update_item(
                Key={'place_id': place_id},
                UpdateExpression="ADD bookmark_count :dec",
                ExpressionAttributeValues={':dec': -1}
            )
            message = "찜이 취소되었습니다."
            status = "unmarked"
        else:
            # --- [찜 추가 로직] ---
            # 1. 내 북마크 추가
            bookmark_table.put_item(Item={
                'user_id': user_id,
                'place_id': place_id,
                'created_at': datetime.now().isoformat()
            })
            # 2. 식당 테이블 정보 업데이트 및 전체 찜 갯수 +1
            # (식당 정보가 없을 수도 있으므로 같이 저장해줍니다)
            restaurant_table.update_item(
                Key={'place_id': place_id},
                UpdateExpression="SET #n = :n, addr = :a, cat = :c, lat = :lat, lng = :lng ADD bookmark_count :inc",
                ExpressionAttributeNames={'#n': 'name'}, # name은 예약어일 수 있어 별칭 사용
                ExpressionAttributeValues={
                    ':n': body.get('name'),
                    ':a': body.get('address'),
                    ':c': body.get('category'),
                    ':lat': body.get('lat'),
                    ':lng': body.get('lng'),
                    ':inc': 1
                }
            )
            message = "찜 목록에 추가되었습니다!"
            status = "marked"

        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({
                'message': message,
                'status': status,
                'place_id': place_id
            }, cls=DecimalEncoder, ensure_ascii=False)
        }

    except Exception as e:
        print(f"Bookmark Error: {e}")
        return {'statusCode': 500, 'headers': headers, 'body': json.dumps({'error': str(e)})}