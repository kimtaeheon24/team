import json
import boto3
import os
from datetime import datetime
from decimal_encoder import DecimalEncoder

dynamodb = boto3.resource('dynamodb')
bookmark_table = dynamodb.Table(os.environ.get('BOOKMARK_TABLE', 'Bookmarks'))
restaurant_table = dynamodb.Table(os.environ.get('RESTAURANT_TABLE', 'Restaurants'))

def lambda_handler(event, context):
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization'
    }

    if event.get('requestContext', {}).get('http', {}).get('method') == 'OPTIONS':
        return {'statusCode': 200, 'headers': headers}

    try:
        # 🔥 유저 정보 추출
        claims = event.get('requestContext', {}).get('authorizer', {}).get('jwt', {}).get('claims', {})
        user_id = claims.get('sub')

        if not user_id:
            return {
                'statusCode': 401,
                'headers': headers,
                'body': json.dumps({'error': '로그인이 필요합니다.'})
            }

        body = json.loads(event.get('body', '{}'))
        place_id = str(body.get('place_id'))

        if not place_id:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'error': 'place_id가 없습니다.'})
            }

        # 🔥 기존 찜 여부 확인
        response = bookmark_table.get_item(
            Key={'user_id': user_id, 'place_id': place_id}
        )
        is_bookmarked = 'Item' in response

        if is_bookmarked:
            # =====================
            # 🔥 찜 취소
            # =====================
            bookmark_table.delete_item(
                Key={'user_id': user_id, 'place_id': place_id}
            )

            restaurant_table.update_item(
                Key={'place_id': place_id},
                UpdateExpression="""
                    SET bookmark_count = if_not_exists(bookmark_count, :zero) - :one
                """,
                ConditionExpression="attribute_exists(place_id)",
                ExpressionAttributeValues={
                    ':one': 1,
                    ':zero': 0
                }
            )

            message = "찜 취소 완료"
            status = "unmarked"

        else:
            # =====================
            # 🔥 찜 추가
            # =====================
            bookmark_table.put_item(
                Item={
                    'user_id': user_id,
                    'place_id': place_id,
                    'created_at': datetime.now().isoformat()
                }
            )

            restaurant_table.update_item(
                Key={'place_id': place_id},
                UpdateExpression="""
                    SET #name = :name,
                        address = :address,
                        lat = :lat,
                        lng = :lng,
                        bookmark_count = if_not_exists(bookmark_count, :zero) + :one
                    REMOVE addr, cat
                """,
                ExpressionAttributeNames={
                    '#name': 'name'
                },
                ExpressionAttributeValues={
                    ':name': body.get('name'),
                    ':address': body.get('address'),
                    ':lat': body.get('lat'),
                    ':lng': body.get('lng'),
                    ':one': 1,
                    ':zero': 0
                }
            )

            message = "찜 완료!"
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
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }