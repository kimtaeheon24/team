import json
import boto3
import os
from decimal_encoder import DecimalEncoder
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')

bookmark_table = dynamodb.Table(os.environ.get('BOOKMARK_TABLE', 'Bookmarks'))
restaurant_table = dynamodb.Table(os.environ.get('RESTAURANT_TABLE', 'Restaurants'))

def lambda_handler(event, context):
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization'
    }

    if event.get('requestContext', {}).get('http', {}).get('method') == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': headers
        }

    try:
        claims = event.get('requestContext', {}).get('authorizer', {}).get('jwt', {}).get('claims', {})
        user_id = claims.get('sub')

        if not user_id:
            return {
                'statusCode': 401,
                'headers': headers,
                'body': json.dumps({'error': '로그인이 필요합니다.'}, ensure_ascii=False)
            }

        # 1) 내 북마크 목록 조회
        response = bookmark_table.query(
            KeyConditionExpression=Key('user_id').eq(user_id)
        )
        bookmark_items = response.get('Items', [])

        # 북마크가 없으면 빈 배열 반환
        if not bookmark_items:
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps([], ensure_ascii=False)
            }

        # 2) place_id 기준으로 Restaurants 상세 조회
        results = []

        for bookmark in bookmark_items:
            place_id = bookmark.get('place_id')
            created_at = bookmark.get('created_at')

            restaurant_res = restaurant_table.get_item(
                Key={'place_id': place_id}
            )
            restaurant = restaurant_res.get('Item')

            # Restaurants에 데이터가 있을 때만 합쳐서 반환
            if restaurant:
                results.append({
                    'place_id': restaurant.get('place_id'),
                    'name': restaurant.get('name'),
                    'address': restaurant.get('address'),
                    'category': restaurant.get('category'),
                    'lat': restaurant.get('lat'),
                    'lng': restaurant.get('lng'),
                    'bookmark_count': restaurant.get('bookmark_count', 0),
                    'created_at': created_at
                })

        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps(results, ensure_ascii=False, cls=DecimalEncoder)
        }

    except Exception as e:
        print(f"get_my_bookmarks error: {e}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)}, ensure_ascii=False)
        }