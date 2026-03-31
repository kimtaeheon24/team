import json
import boto3
from datetime import datetime
import uuid

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Reviews')

def lambda_handler(event, context):
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type'
    }
    
    # 브라우저 사전 검사 대응
    if event.get('httpMethod') == 'OPTIONS':
        return {'statusCode': 200, 'headers': headers}

    try:
        body = json.loads(event.get('body', '{}'))
        
        # 리뷰는 고유한 ID가 필요하므로 uuid를 사용합니다.
        review_id = str(uuid.uuid4())
        
        # DB에 저장할 데이터 구성
        item = {
            'place_id': body.get('place_id'),       # 카카오맵 장소 ID (Partition Key)
            'review_id': review_id,                # 리뷰 고유 ID (Sort Key)
            'user_id': body.get('user_id'),         # 작성자 ID
            'user_name': body.get('user_name'),     # 작성자 닉네임 (화면 표시용)
            'rating': body.get('rating'),           # 별점
            'comment': body.get('comment'),         # 리뷰 내용
            'created_at': datetime.now().isoformat() # 생성 시간
        }
        
        table.put_item(Item=item)

        return {
            'statusCode': 201,
            'headers': headers,
            'body': json.dumps({
                'message': '리뷰가 등록되었습니다!',
                'review_id': review_id
            }, ensure_ascii=False)
        }

    except Exception as e:
        print(f"Review Error: {e}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }