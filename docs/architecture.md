# Architecture

## Overview

A dual-language microservices dating app designed for the Chinese market. Built with **Go** (IM server) and **NestJS** (business API), demonstrating multi-cloud portability (AWS/Alibaba Cloud).

## Service Architecture

| Service | Language | Port | Responsibility |
|---------|----------|------|----------------|
| Nginx | - | 80 | SSL termination, reverse proxy, load balancing |
| Backend API | NestJS/TypeScript | 3000 | User auth, profiles, matching, uploads |
| IM Server | Go | 8081 | WebSocket real-time messaging |
| PostgreSQL + PostGIS | - | 5432 | User data, geolocation queries |
| Redis | - | 6379 | Pub/Sub, session cache, offline messages |
| MinIO | - | 9000 | S3-compatible object storage for photos |

## Key Design Decisions

### Why dual-language?
- **Go for IM**: Superior concurrency model (goroutines) for handling thousands of WebSocket connections
- **NestJS for API**: Rapid development with decorators, built-in DI, TypeORM integration

### Why PostGIS?
- Spatial indexing for efficient "nearby users" queries
- ST_DWithin for distance-based filtering
- Industry standard for geolocation applications

### Multi-cloud Storage Abstraction
- `IStorageService` interface decouples business logic from storage provider
- Swap between MinIO (dev), AWS S3, or Alibaba Cloud OSS via configuration

### Recommendation Algorithm
- Multi-dimensional scoring: Distance (30%) + ELO (30%) + Collaborative Filtering (20%) + Interest Similarity (20%)
- ELO rating adjusts based on swipe patterns
- Jaccard similarity for interest tag matching
