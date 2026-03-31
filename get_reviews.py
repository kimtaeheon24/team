import json
import boto3
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Reviews')

def lambda_handler(event, context):
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type'
    }

    try:
        # URL 파라미터에서 place_id를 읽어옵니다. (예: /reviews?place_id=12345)
        query_params = event.get('queryStringParameters', {})
        place_id = query_params.get('place_id')

        if not place_id:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'error': 'place_id가 필요합니다.'})
            }

        # 해당 식당의 리뷰만 쿼리해서 가져옵니다.
        response = table.query(
            KeyConditionExpression=Key('place_id').eq(place_id)
        )
        reviews = response.get('Items', [])

        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps(reviews, ensure_ascii=False)
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }