import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Not, In } from 'typeorm';
import { Swipe, SwipeDirection } from './entities/swipe.entity';
import { Match } from './entities/match.entity';
import { Profile } from '../profiles/entities/profile.entity';
import { RecommendationService } from './recommendation.service';

@Injectable()
export class MatchingService {
  constructor(
    @InjectRepository(Swipe)
    private readonly swipeRepository: Repository<Swipe>,
    @InjectRepository(Match)
    private readonly matchRepository: Repository<Match>,
    @InjectRepository(Profile)
    private readonly profileRepository: Repository<Profile>,
    private readonly recommendationService: RecommendationService,
  ) {}

  /**
   * Get candidate cards for the user to swipe on.
   * Excludes users already swiped on.
   */
  async getCards(userId: string, limit = 10): Promise<Profile[]> {
    // Get IDs of users already swiped on
    const existingSwipes = await this.swipeRepository.find({
      where: { swiperId: userId },
      select: ['swipedId'],
    });
    const swipedIds = existingSwipes.map((s) => s.swipedId);
    const excludeIds = [userId, ...swipedIds];

    // Fetch candidate profiles
    const candidates = await this.profileRepository.find({
      where: {
        userId: Not(In(excludeIds)),
      },
      take: limit * 2, // fetch extra for ranking
    });

    // Get current user's profile for scoring
    const currentProfile = await this.profileRepository.findOne({
      where: { userId },
    });

    if (!currentProfile) {
      // If no profile, return unranked candidates
      return candidates.slice(0, limit);
    }

    // Rank and return top candidates
    const ranked = this.recommendationService.rankCandidates(
      currentProfile,
      candidates,
    );
    const rankedIds = ranked.slice(0, limit).map((r) => r.userId);

    return candidates
      .filter((c) => rankedIds.includes(c.userId))
      .sort(
        (a, b) =>
          rankedIds.indexOf(a.userId) - rankedIds.indexOf(b.userId),
      );
  }

  /**
   * Record a swipe and check for a mutual match.
   */
  async swipe(
    swiperId: string,
    swipedId: string,
    direction: SwipeDirection,
  ): Promise<{ matched: boolean; matchId?: string }> {
    // Record the swipe
    const swipe = this.swipeRepository.create({
      swiperId,
      swipedId,
      direction,
    });
    await this.swipeRepository.save(swipe);

    // If left swipe, no match possible
    if (direction === SwipeDirection.LEFT) {
      return { matched: false };
    }

    // Check if the other user already swiped right on this user
    const reciprocalSwipe = await this.swipeRepository.findOne({
      where: {
        swiperId: swipedId,
        swipedId: swiperId,
        direction: SwipeDirection.RIGHT,
      },
    });

    if (reciprocalSwipe) {
      // Mutual match! Create a match record
      const match = this.matchRepository.create({
        user1Id: swiperId < swipedId ? swiperId : swipedId,
        user2Id: swiperId < swipedId ? swipedId : swiperId,
      });
      const savedMatch = await this.matchRepository.save(match);
      return { matched: true, matchId: savedMatch.id };
    }

    return { matched: false };
  }

  /**
   * Get all matches for a user.
   */
  async getMatches(userId: string): Promise<Match[]> {
    return this.matchRepository.find({
      where: [{ user1Id: userId }, { user2Id: userId }],
      relations: ['user1', 'user2'],
      order: { createdAt: 'DESC' },
    });
  }
}
