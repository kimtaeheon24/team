import json
import boto3
from boto3.dynamodb.conditions import Key
from decimal_encoder import DecimalEncoder

dynamodb = boto3.resource('dynamodb')
# 테이블 이름을 직접 확인하세요. 'Reviews'가 맞는지!
table = dynamodb.Table('Reviews')

def lambda_handler(event, context):
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization'
    }

    # CORS OPTIONS 처리
    method = event.get('requestContext', {}).get('http', {}).get('method')
    if method == 'OPTIONS':
        return {'statusCode': 200, 'headers': headers}

    try:
        query_params = event.get('queryStringParameters') or {}
        place_id = query_params.get('place_id')

        if not place_id:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'error': 'place_id가 필요합니다.'})
            }

        # DynamoDB 쿼리
        response = table.query(
            KeyConditionExpression=Key('place_id').eq(str(place_id))
        )

        items = response.get('Items', [])

        # 프론트엔드에 필요한 데이터만 정제해서 보냄 (user_email 포함!)
        reviews = []
        for r in items:
            reviews.append({
                "place_id": r.get("place_id"),
                "review_id": r.get("review_id"),
                "user_id": r.get("user_id"),
                "user_email": r.get("user_email") or "익명@unknown",
                "comment": r.get("comment"),
                "rating": r.get("rating"),
                "created_at": r.get("created_at")
            })

        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps(reviews, cls=DecimalEncoder, ensure_ascii=False)
        }

    except Exception as e:
        # 에러 내용을 로그에 찍습니다.
        print("ERROR:", str(e))
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }