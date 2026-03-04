export interface UploadedFile {
  buffer: Buffer;
  originalname: string;
  mimetype: string;
  size: number;
}

export interface IStorageService {
  /**
   * Upload a file to storage.
   */
  upload(file: UploadedFile, bucket: string, key: string): Promise<string>;

  /**
   * Get the public URL for a stored file.
   */
  getUrl(bucket: string, key: string): Promise<string>;

  /**
   * Delete a file from storage.
   */
  delete(bucket: string, key: string): Promise<void>;
}

export const STORAGE_SERVICE = 'STORAGE_SERVICE';
