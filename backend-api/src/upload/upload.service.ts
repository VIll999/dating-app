import { Injectable, Inject } from '@nestjs/common';
import { v4 as uuidv4 } from 'uuid';
import { IStorageService, STORAGE_SERVICE, UploadedFile } from './storage/storage.interface';

@Injectable()
export class UploadService {
  private readonly defaultBucket = 'dating-app-photos';

  constructor(
    @Inject(STORAGE_SERVICE)
    private readonly storageService: IStorageService,
  ) {}

  async upload(file: UploadedFile): Promise<{ url: string; key: string }> {
    const extension = this.getExtension(file.originalname);
    const key = `${uuidv4()}${extension}`;

    const url = await this.storageService.upload(file, this.defaultBucket, key);

    return { url, key };
  }

  async getUrl(key: string): Promise<string> {
    return this.storageService.getUrl(this.defaultBucket, key);
  }

  async delete(key: string): Promise<void> {
    return this.storageService.delete(this.defaultBucket, key);
  }

  private getExtension(filename: string): string {
    const parts = filename.split('.');
    if (parts.length > 1) {
      return `.${parts[parts.length - 1]}`;
    }
    return '';
  }
}
