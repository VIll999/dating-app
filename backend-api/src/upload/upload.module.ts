import { Module } from '@nestjs/common';
import { UploadController } from './upload.controller';
import { UploadService } from './upload.service';
import { MinioStorageService } from './storage/minio.storage';
import { STORAGE_SERVICE } from './storage/storage.interface';

@Module({
  controllers: [UploadController],
  providers: [
    UploadService,
    {
      provide: STORAGE_SERVICE,
      useClass: MinioStorageService,
    },
  ],
  exports: [UploadService],
})
export class UploadModule {}
