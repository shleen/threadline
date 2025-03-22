"""
Functions related to image handling
"""

import boto3

IMAGE_BUCKET = "threadline-clothing"

# first param here is because boto3 was built for use with AWS S3,
# and Cloudflare R2 is compatible with many AWS S3 SDKs
r2 = boto3.client('s3',
  endpoint_url='https://b6e8480fbb6810acf1dd80dad4681c12.r2.cloudflarestorage.com',
  region_name='enam'
)
