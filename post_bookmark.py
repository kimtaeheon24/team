import json
import boto3
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
# 두 개의 테이블을 모두 불러옵니다.
bookmark_table = dynamodb.Table('Bookmarks')
restaurant_table = dynamodb.Table('Restaurants')

def lambda_handler(event, context):
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type'
    }
    
    if event.get('httpMethod') == 'OPTIONS':
        return {'statusCode': 200, 'headers': headers}

    try:
        # 프론트에서 넘겨준 데이터 (user_id, place_id, name, lat, lng 등)
        body = json.loads(event.get('body', '{}'))
        user_id = body.get('user_id')
        place_id = body.get('place_id')
        
        # 1. Bookmarks 테이블에 저장 (사용자별 찜 목록)
        bookmark_table.put_item(
            Item={
                'user_id': user_id,
                'place_id': place_id,
                'created_at': datetime.now().isoformat()
            }
        )
        
        # 2. Restaurants 테이블에 저장 (전체 지도 표시용)
        # 이미 있어도 덮어쓰기(Put) 하거나, 정보가 최신화됩니다.
        restaurant_table.put_item(
            Item={
                'place_id': place_id,
                'name': body.get('name'),
                'address': body.get('address'),
                'category': body.get('category'),
                'lat': body.get('lat'),
                'lng': body.get('lng')
            }
        )

        return {
            'statusCode': 201,
            'headers': headers,
            'body': json.dumps({'message': '북마크 및 맛집 수집 완료!'}, ensure_ascii=False)
        }

    except Exception as e:
        print(e)
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }