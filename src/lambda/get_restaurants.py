import json
import boto3
from boto3.dynamodb.conditions import Key
from decimal_encoder import DecimalEncoder


dynamodb = boto3.resource('dynamodb')
table_restaurants = dynamodb.Table('Restaurants')
table_reviews = dynamodb.Table('Reviews')

def lambda_handler(event, context):
    try:
        res_data = table_restaurants.scan()
        items = res_data.get('Items', [])
        filtered_restaurants = []

        for item in items:
            place_id = item.get('place_id')
            
            # 해당 식당의 모든 리뷰 조회
            review_res = table_reviews.query(
                KeyConditionExpression=Key('place_id').eq(place_id)
            )
            reviews = review_res.get('Items', [])
            
            count = len(reviews)
            avg = round(sum(int(r['rating']) for r in reviews) / count, 1) if count > 0 else 0
            
            # 🎯 [수정된 핵심 로직] 
            # 1. 리뷰가 3개 미만이면 추천 맛집에서 제외
            if count < 3:
                continue
                
            # 2. 리뷰가 3개 이상이더라도 평점이 4.0점 미만이면 제외
            if avg < 4.0:
                continue
            
            # 위 조건을 모두 통과한(리뷰 3개 이상 & 평점 4.0 이상) 곳만 추가
            item['avg_rating'] = avg
            item['review_count'] = count
            filtered_restaurants.append(item)

        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Content-Type': 'application/json'
            },
            'body': json.dumps(filtered_restaurants, cls=DecimalEncoder, ensure_ascii=False)
        }
        
    except Exception as e:
        print(f"Error: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }