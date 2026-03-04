import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MatchingController } from './matching.controller';
import { MatchingService } from './matching.service';
import { RecommendationService } from './recommendation.service';
import { Swipe } from './entities/swipe.entity';
import { Match } from './entities/match.entity';
import { Profile } from '../profiles/entities/profile.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Swipe, Match, Profile])],
  controllers: [MatchingController],
  providers: [MatchingService, RecommendationService],
  exports: [MatchingService],
})
export class MatchingModule {}
