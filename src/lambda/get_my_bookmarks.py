import json
import boto3
import os
from decimal_encoder import DecimalEncoder
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')

bookmark_table_name = os.environ.get('BOOKMARK_TABLE', 'Bookmarks')
restaurant_table_name = os.environ.get('RESTAURANT_TABLE', 'Restaurants')

bookmark_table = dynamodb.Table(bookmark_table_name)
restaurant_table = dynamodb.Table(restaurant_table_name)

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

        if not bookmark_items:
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps([], ensure_ascii=False)
            }

        # 2) place_id 목록 추출
        place_ids = [item['place_id'] for item in bookmark_items if item.get('place_id')]

        if not place_ids:
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps([], ensure_ascii=False)
            }

        # 3) BatchGetItem용 Key 목록 생성
        keys = [{'place_id': pid} for pid in place_ids]

        # 4) Restaurants 상세정보 일괄 조회
        batch_response = dynamodb.batch_get_item(
            RequestItems={
                restaurant_table_name: {
                    'Keys': keys
                }
            }
        )

        restaurant_items = batch_response.get('Responses', {}).get(restaurant_table_name, [])

        # 5) place_id 기준으로 dict 변환
        restaurant_map = {
            item['place_id']: item for item in restaurant_items
        }

        results = []
        for bookmark in bookmark_items:
            place_id = bookmark.get('place_id')
            created_at = bookmark.get('created_at')

            restaurant = restaurant_map.get(place_id)
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