import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('matches')
export class Match {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid', name: 'user1_id' })
  user1Id!: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user1_id' })
  user1!: User;

  @Column({ type: 'uuid', name: 'user2_id' })
  user2Id!: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user2_id' })
  user2!: User;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;
}
