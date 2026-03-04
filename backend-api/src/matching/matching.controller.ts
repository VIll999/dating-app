import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { MatchingService } from './matching.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { SwipeDirection } from './entities/swipe.entity';

class SwipeDto {
  swipedId!: string;
  direction!: SwipeDirection;
}

@Controller('matching')
@UseGuards(JwtAuthGuard)
export class MatchingController {
  constructor(private readonly matchingService: MatchingService) {}

  @Get('cards')
  async getCards(
    @Request() req: { user: { userId: string } },
    @Query('limit') limit?: number,
  ) {
    return this.matchingService.getCards(req.user.userId, limit || 10);
  }

  @Post('swipe')
  async swipe(
    @Request() req: { user: { userId: string } },
    @Body() swipeDto: SwipeDto,
  ) {
    return this.matchingService.swipe(
      req.user.userId,
      swipeDto.swipedId,
      swipeDto.direction,
    );
  }

  @Get('matches')
  async getMatches(@Request() req: { user: { userId: string } }) {
    return this.matchingService.getMatches(req.user.userId);
  }
}
