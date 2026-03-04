import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { IStorageService, UploadedFile } from './storage.interface';

/**
 * Placeholder AWS S3 implementation of IStorageService.
 * To use this, install @aws-sdk/client-s3 and implement the methods.
 */
@Injectable()
export class S3StorageService implements IStorageService {
  private readonly bucket: string;
  private readonly region: string;

  constructor(private readonly configService: ConfigService) {
    this.bucket = this.configService.get<string>('AWS_S3_BUCKET', 'dating-app-uploads');
    this.region = this.configService.get<string>('AWS_REGION', 'us-east-1');
  }

  async upload(file: UploadedFile, bucket: string, key: string): Promise<string> {
    // Placeholder: Implement with @aws-sdk/client-s3
    // const command = new PutObjectCommand({
    //   Bucket: bucket,
    //   Key: key,
    //   Body: file.buffer,
    //   ContentType: file.mimetype,
    // });
    // await this.s3Client.send(command);
    throw new Error(
      'S3StorageService is a placeholder. Install @aws-sdk/client-s3 and implement.',
    );
  }

  async getUrl(bucket: string, key: string): Promise<string> {
    // Placeholder: Implement with @aws-sdk/client-s3 getSignedUrl
    return `https://${bucket}.s3.${this.region}.amazonaws.com/${key}`;
  }

  async delete(bucket: string, key: string): Promise<void> {
    // Placeholder: Implement with @aws-sdk/client-s3
    // const command = new DeleteObjectCommand({ Bucket: bucket, Key: key });
    // await this.s3Client.send(command);
    throw new Error(
      'S3StorageService is a placeholder. Install @aws-sdk/client-s3 and implement.',
    );
  }
}
