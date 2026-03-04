import { Injectable } from '@nestjs/common';
import { Profile } from '../profiles/entities/profile.entity';

export interface RecommendationScore {
  userId: string;
  score: number;
}

@Injectable()
export class RecommendationService {
  /**
   * Calculate a recommendation score between two profiles.
   * This is a placeholder implementation. In production, this would use
   * factors like distance, shared interests, preferences, etc.
   */
  calculateScore(
    currentProfile: Profile,
    candidateProfile: Profile,
  ): number {
    let score = 0;

    // Placeholder: Score based on shared interests
    if (currentProfile.interests && candidateProfile.interests) {
      const currentInterests = new Set(currentProfile.interests);
      const sharedInterests = candidateProfile.interests.filter((interest) =>
        currentInterests.has(interest),
      );
      score += sharedInterests.length * 10;
    }

    // Placeholder: Score based on profile completeness
    if (candidateProfile.bio) score += 5;
    if (candidateProfile.photos && candidateProfile.photos.length > 0) {
      score += candidateProfile.photos.length * 3;
    }

    // Placeholder: Distance-based scoring would go here
    // using PostGIS ST_Distance on location columns

    return score;
  }

  /**
   * Rank candidate profiles by recommendation score.
   */
  rankCandidates(
    currentProfile: Profile,
    candidates: Profile[],
  ): RecommendationScore[] {
    return candidates
      .map((candidate) => ({
        userId: candidate.userId,
        score: this.calculateScore(currentProfile, candidate),
      }))
      .sort((a, b) => b.score - a.score);
  }
}
