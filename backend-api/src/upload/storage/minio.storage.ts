import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as Minio from 'minio';
import { IStorageService, UploadedFile } from './storage.interface';

@Injectable()
export class MinioStorageService implements IStorageService {
  private readonly minioClient: Minio.Client;
  private readonly publicEndpoint: string;

  constructor(private readonly configService: ConfigService) {
    this.minioClient = new Minio.Client({
      endPoint: this.configService.get<string>('MINIO_ENDPOINT', 'localhost'),
      port: this.configService.get<number>('MINIO_PORT', 9000),
      useSSL: this.configService.get<boolean>('MINIO_USE_SSL', false),
      accessKey: this.configService.get<string>('MINIO_ACCESS_KEY', 'minioadmin'),
      secretKey: this.configService.get<string>('MINIO_SECRET_KEY', 'minioadmin'),
    });

    this.publicEndpoint = this.configService.get<string>(
      'MINIO_PUBLIC_ENDPOINT',
      'http://localhost:9000',
    );
  }

  async upload(file: UploadedFile, bucket: string, key: string): Promise<string> {
    // Ensure bucket exists
    const exists = await this.minioClient.bucketExists(bucket);
    if (!exists) {
      await this.minioClient.makeBucket(bucket, 'us-east-1');
    }

    await this.minioClient.putObject(bucket, key, file.buffer, file.size, {
      'Content-Type': file.mimetype,
    });

    return `${this.publicEndpoint}/${bucket}/${key}`;
  }

  async getUrl(bucket: string, key: string): Promise<string> {
    // Generate a presigned URL valid for 7 days
    return this.minioClient.presignedGetObject(bucket, key, 7 * 24 * 60 * 60);
  }

  async delete(bucket: string, key: string): Promise<void> {
    await this.minioClient.removeObject(bucket, key);
  }
}
