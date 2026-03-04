import {
  Controller,
  Get,
  Put,
  Param,
  Body,
  UseGuards,
  Request,
  NotFoundException,
} from '@nestjs/common';
import { ProfilesService } from './profiles.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { Profile } from './entities/profile.entity';

@Controller('profiles')
export class ProfilesController {
  constructor(private readonly profilesService: ProfilesService) {}

  @UseGuards(JwtAuthGuard)
  @Get('me')
  async getMyProfile(@Request() req: { user: { userId: string } }) {
    const profile = await this.profilesService.findByUserId(req.user.userId);
    if (!profile) {
      throw new NotFoundException('Profile not found. Please create a profile first.');
    }
    return profile;
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    const profile = await this.profilesService.findByUserId(id);
    if (!profile) {
      throw new NotFoundException('Profile not found');
    }
    return profile;
  }

  @UseGuards(JwtAuthGuard)
  @Put(':id')
  async update(
    @Param('id') id: string,
    @Body() updateData: Partial<Profile>,
    @Request() req: { user: { userId: string } },
  ) {
    // Ensure users can only update their own profile
    if (id !== req.user.userId) {
      throw new NotFoundException('Profile not found');
    }

    let profile = await this.profilesService.findByUserId(id);
    if (!profile) {
      // Auto-create profile if it doesn't exist
      profile = await this.profilesService.create(id, updateData);
    } else {
      profile = await this.profilesService.update(id, updateData);
    }
    return profile;
  }
}
