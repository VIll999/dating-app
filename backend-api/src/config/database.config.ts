import { ConfigService } from '@nestjs/config';
import { TypeOrmModuleOptions } from '@nestjs/typeorm';

export const databaseConfig = (
  configService: ConfigService,
): TypeOrmModuleOptions => ({
  type: 'postgres',
  host: configService.get<string>('POSTGRES_HOST', 'localhost'),
  port: configService.get<number>('POSTGRES_PORT', 5432),
  username: configService.get<string>('POSTGRES_USER', 'postgres'),
  password: configService.get<string>('POSTGRES_PASSWORD', 'postgres'),
  database: configService.get<string>('POSTGRES_DB', 'dating_app'),
  autoLoadEntities: true,
  synchronize: configService.get<string>('NODE_ENV', 'development') === 'development',
  logging: configService.get<string>('NODE_ENV', 'development') === 'development',
  extra: {
    // PostGIS extension support
    max: 20,
  },
});
