import json
import boto3
from boto3.dynamodb.conditions import Key
from decimal_encoder import DecimalEncoder

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Reviews')

def lambda_handler(event, context):

    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization'
    }

    # ✅ CORS OPTIONS 처리
    if event.get('requestContext', {}).get('http', {}).get('method') == 'OPTIONS':
        return {'statusCode': 200, 'headers': headers}

    try:
        # ✅ None 방지
        query_params = event.get('queryStringParameters') or {}
        place_id = query_params.get('place_id')

        if not place_id:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'error': 'place_id가 필요합니다.'})
            }

        response = table.query(
            KeyConditionExpression=Key('place_id').eq(place_id)
        )

        items = response.get('Items', [])

        # ✅ 프론트용 데이터 가공
        reviews = []
        for r in items:
            reviews.append({
                "place_id": r.get("place_id"),
                "review_id": r.get("review_id"),
                "user_id": r.get("user_id"),
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
        print("ERROR:", e)
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }