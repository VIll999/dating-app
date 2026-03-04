import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

export enum SwipeDirection {
  LEFT = 'left',
  RIGHT = 'right',
}

@Entity('swipes')
export class Swipe {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid', name: 'swiper_id' })
  swiperId!: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'swiper_id' })
  swiper!: User;

  @Column({ type: 'uuid', name: 'swiped_id' })
  swipedId!: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'swiped_id' })
  swiped!: User;

  @Column({ type: 'enum', enum: SwipeDirection })
  direction!: SwipeDirection;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;
}
