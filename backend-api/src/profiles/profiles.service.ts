import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Profile } from './entities/profile.entity';

@Injectable()
export class ProfilesService {
  constructor(
    @InjectRepository(Profile)
    private readonly profileRepository: Repository<Profile>,
  ) {}

  async findByUserId(userId: string): Promise<Profile | null> {
    return this.profileRepository.findOne({ where: { userId } });
  }

  async create(userId: string, data: Partial<Profile>): Promise<Profile> {
    const profile = this.profileRepository.create({
      ...data,
      userId,
    });
    return this.profileRepository.save(profile);
  }

  async update(userId: string, data: Partial<Profile>): Promise<Profile> {
    const profile = await this.findByUserId(userId);
    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    Object.assign(profile, data);
    return this.profileRepository.save(profile);
  }
}
