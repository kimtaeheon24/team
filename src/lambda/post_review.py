import json
import boto3
import os
import uuid
from datetime import datetime
from decimal import Decimal
from botocore.exceptions import ClientError
from decimal_encoder import DecimalEncoder

dynamodb = boto3.resource('dynamodb')
review_table = dynamodb.Table(os.environ.get('REVIEW_TABLE', 'Reviews'))
restaurant_table = dynamodb.Table(os.environ.get('RESTAURANT_TABLE', 'Restaurants'))


def calculate_recommendation(avg_rating, review_count):
    if review_count >= 3 and avg_rating >= 4.0:
        recommended_pk = 'RECOMMENDED'
        recommended_score = Decimal(str(avg_rating)) * Decimal('1000') + Decimal(str(min(review_count, 999)))
        return recommended_pk, recommended_score
    return None, None


def ensure_restaurant_exists(body):
    place_id = str(body.get('place_id'))
    name = body.get('name', '')
    address = body.get('address', '')
    lat = body.get('lat')
    lng = body.get('lng')

    if not place_id:
        raise ValueError('place_id가 없습니다.')

    item = {
        'place_id': place_id,
        'name': name,
        'address': address,
        'rating_sum': Decimal('0'),
        'rating_count': 0,
        'review_count': 0,
        'avg_rating': Decimal('0.0'),
        'bookmark_count': 0,
        'created_at': datetime.now().isoformat(),
        'updated_at': datetime.now().isoformat()
    }

    if lat is not None:
        item['lat'] = Decimal(str(lat))
    if lng is not None:
        item['lng'] = Decimal(str(lng))

    try:
        restaurant_table.put_item(
            Item=item,
            ConditionExpression='attribute_not_exists(place_id)'
        )
        print(f"Restaurants 신규 생성 완료: {place_id}")
    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'ConditionalCheckFailedException':
            print(f"Restaurants 이미 존재함: {place_id}")
        else:
            raise


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
        authorizer = event.get('requestContext', {}).get('authorizer', {})
        jwt_data = authorizer.get('jwt', {})
        claims = jwt_data.get('claims', {})

        user_id = claims.get('sub')
        user_email = claims.get('email') or claims.get('custom:email') or claims.get('username')

        print(f"User ID: {user_id}, User Email: {user_email}")

        if not user_id:
            return {
                'statusCode': 401,
                'headers': headers,
                'body': json.dumps({'error': '인증 필요'}, ensure_ascii=False)
            }

        body = json.loads(event.get('body') or '{}')

        if method == 'POST':
            place_id = body.get('place_id')
            comment = body.get('comment')
            rating = int(body.get('rating', 5))

            print(f"POST place_id = {place_id}")

            if not place_id or not comment:
                return {
                    'statusCode': 400,
                    'headers': headers,
                    'body': json.dumps({'error': '필수값 없음'}, ensure_ascii=False)
                }

            if rating < 1 or rating > 5:
                return {
                    'statusCode': 400,
                    'headers': headers,
                    'body': json.dumps({'error': 'rating은 1~5 사이여야 합니다'}, ensure_ascii=False)
                }

            # 1) Restaurants에 장소 없으면 자동 생성
            ensure_restaurant_exists(body)

            # 2) 리뷰 저장
            review_item = {
                'place_id': str(place_id),
                'review_id': str(uuid.uuid4()),
                'user_id': user_id,
                'user_email': user_email if user_email else "익명@unknown",
                'rating': rating,
                'comment': comment,
                'created_at': datetime.now().isoformat()
            }

            review_table.put_item(Item=review_item)

            # 3) Restaurants 현재 집계 조회
            restaurant_res = restaurant_table.get_item(Key={'place_id': str(place_id)})
            restaurant_item = restaurant_res.get('Item')

            if not restaurant_item:
                return {
                    'statusCode': 500,
                    'headers': headers,
                    'body': json.dumps({'error': 'Restaurants 생성/조회 실패'}, ensure_ascii=False)
                }

            old_rating_sum = Decimal(str(restaurant_item.get('rating_sum', 0)))
            old_rating_count = int(restaurant_item.get('rating_count', 0))
            old_review_count = int(restaurant_item.get('review_count', 0))

            # 4) 새 집계 계산
            new_rating_sum = old_rating_sum + Decimal(str(rating))
            new_rating_count = old_rating_count + 1
            new_review_count = old_review_count + 1
            new_avg_rating = (new_rating_sum / Decimal(str(new_rating_count))).quantize(Decimal('0.1'))

            # 5) 추천 여부 계산
            recommended_pk, recommended_score = calculate_recommendation(
                float(new_avg_rating),
                new_review_count
            )

            # 6) Restaurants 업데이트
            update_expr = """
                SET rating_sum = :rating_sum,
                    rating_count = :rating_count,
                    review_count = :review_count,
                    avg_rating = :avg_rating,
                    updated_at = :updated_at
            """

            expr_values = {
                ':rating_sum': new_rating_sum,
                ':rating_count': new_rating_count,
                ':review_count': new_review_count,
                ':avg_rating': new_avg_rating,
                ':updated_at': datetime.now().isoformat()
            }

            if recommended_pk:
                update_expr += ", recommended_pk = :recommended_pk, recommended_score = :recommended_score"
                expr_values[':recommended_pk'] = recommended_pk
                expr_values[':recommended_score'] = recommended_score
            else:
                update_expr += " REMOVE recommended_pk, recommended_score"

            restaurant_table.update_item(
                Key={'place_id': str(place_id)},
                UpdateExpression=update_expr,
                ExpressionAttributeValues=expr_values
            )

            return {
                'statusCode': 201,
                'headers': headers,
                'body': json.dumps(review_item, cls=DecimalEncoder, ensure_ascii=False)
            }

        elif method == 'DELETE':
            place_id = body.get('place_id')
            review_id = body.get('review_id')

            if not place_id or not review_id:
                return {
                    'statusCode': 400,
                    'headers': headers,
                    'body': json.dumps({'error': '필수값 없음'}, ensure_ascii=False)
                }

            # 1) 삭제할 리뷰 먼저 조회
            review_res = review_table.get_item(
                Key={
                    'place_id': str(place_id),
                    'review_id': str(review_id)
                }
            )
            review_item = review_res.get('Item')

            if not review_item:
                return {
                    'statusCode': 404,
                    'headers': headers,
                    'body': json.dumps({'error': '리뷰를 찾을 수 없음'}, ensure_ascii=False)
                }

            if review_item.get('user_id') != user_id:
                return {
                    'statusCode': 403,
                    'headers': headers,
                    'body': json.dumps({'error': '본인 리뷰만 삭제할 수 있습니다'}, ensure_ascii=False)
                }

            review_rating = int(review_item['rating'])

            # 2) 리뷰 삭제
            review_table.delete_item(
                Key={
                    'place_id': str(place_id),
                    'review_id': str(review_id)
                }
            )

            # 3) Restaurants 집계 조회
            restaurant_res = restaurant_table.get_item(Key={'place_id': str(place_id)})
            restaurant_item = restaurant_res.get('Item')

            if not restaurant_item:
                return {
                    'statusCode': 404,
                    'headers': headers,
                    'body': json.dumps({'error': '해당 식당이 Restaurants 테이블에 없음'}, ensure_ascii=False)
                }

            old_rating_sum = Decimal(str(restaurant_item.get('rating_sum', 0)))
            old_rating_count = int(restaurant_item.get('rating_count', 0))
            old_review_count = int(restaurant_item.get('review_count', 0))

            new_rating_sum = old_rating_sum - Decimal(str(review_rating))
            new_rating_count = max(old_rating_count - 1, 0)
            new_review_count = max(old_review_count - 1, 0)

            if new_rating_count > 0:
                new_avg_rating = (new_rating_sum / Decimal(str(new_rating_count))).quantize(Decimal('0.1'))
            else:
                new_avg_rating = Decimal('0.0')
                new_rating_sum = Decimal('0')

            recommended_pk, recommended_score = calculate_recommendation(
                float(new_avg_rating),
                new_review_count
            )

            update_expr = """
                SET rating_sum = :rating_sum,
                    rating_count = :rating_count,
                    review_count = :review_count,
                    avg_rating = :avg_rating,
                    updated_at = :updated_at
            """

            expr_values = {
                ':rating_sum': new_rating_sum,
                ':rating_count': new_rating_count,
                ':review_count': new_review_count,
                ':avg_rating': new_avg_rating,
                ':updated_at': datetime.now().isoformat()
            }

            if recommended_pk:
                update_expr += ", recommended_pk = :recommended_pk, recommended_score = :recommended_score"
                expr_values[':recommended_pk'] = recommended_pk
                expr_values[':recommended_score'] = recommended_score
            else:
                update_expr += " REMOVE recommended_pk, recommended_score"

            restaurant_table.update_item(
                Key={'place_id': str(place_id)},
                UpdateExpression=update_expr,
                ExpressionAttributeValues=expr_values
            )

            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({'message': '삭제 완료'}, ensure_ascii=False)
            }

        else:
            return {
                'statusCode': 405,
                'headers': headers,
                'body': json.dumps({'error': '허용되지 않은 메서드'}, ensure_ascii=False)
            }

    except Exception as e:
        print("CRITICAL ERROR:", str(e))
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)}, ensure_ascii=False)
        }