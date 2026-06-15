# ArenaVault - Football Predictions Platform
## Technical Design Specification v3.0

**Project Name:** `arena-vault`  
**Version:** 3.0.0 (Complete Architecture Edition)  
**Date:** June 14, 2026  
**Architecture:** 2 Microservices + Clean Architecture + TDD + PostgreSQL

---

## Table of Contents
1. [Executive Summary](#1-executive-summary)
2. [Technology Stack](#2-technology-stack)
3. [Database Decision: PostgreSQL](#3-database-decision-postgresql)
4. [Microservices Architecture (2 Services)](#4-microservices-architecture-2-services)
5. [Clean Architecture Structure](#5-clean-architecture-structure)
6. [TDD Strategy](#6-tdd-strategy)
7. [Project Structure](#7-project-structure)
8. [Database Schema (PostgreSQL)](#8-database-schema-postgresql)
9. [Implementation Guidelines](#9-implementation-guidelines)
10. [Docker Compose Configuration](#10-docker-compose-configuration)
11. [Deployment Strategy](#11-deployment-strategy)
12. [Development Phases](#12-development-phases)

---

## 1. Executive Summary

**ArenaVault** is a football match prediction platform that enables users to create groups, predict match outcomes, and compete for prize pools. The system implements a sophisticated rules engine with customizable scoring, phase bonuses, and tie-breaking criteria.

### Key Features
- Public and private groups with invite/PIN access
- Customizable prediction rules per group
- Multi-criteria scoring system (exact score, winner, goals)
- Phase bonuses for tournament predictions
- Virtual prize pool management
- Responsive mobile/tablet/desktop UI

### Architecture Highlights
- **2 Microservices:** Auth & Groups + Game Management (rules integrated with matches)
- **Clean Architecture:** Domain → Application  Infrastructure  WebApi layers
- **TDD Approach:** 90% Domain, 80% Application, 60% Infrastructure coverage
- **PostgreSQL:** Free tier optimized with Neon (10GB) or Railway
- **Docker Compose:** All-in-one deployment

---

## 2. Technology Stack

### Backend
- **Framework:** .NET 8+
- **Language:** C# 12
- **Architecture:** 2 Microservices + Clean Architecture
- **Database:** PostgreSQL 16
- **ORM:** Entity Framework Core with Npgsql provider
- **Authentication:** JWT tokens
- **API Style:** RESTful with OpenAPI/Swagger
- **CQRS:** MediatR pattern for commands/queries
- **Validation:** FluentValidation
- **Mapping:** AutoMapper

### Frontend
- **Framework:** Angular 18+
- **Styling:** TailwindCSS or Angular Material
- **State Management:** NgRx or Signals
- **Responsive:** Mobile-first design (mobile/tablet/desktop)

### Database
- **Engine:** PostgreSQL 16
- **Hosting Options:**
  - **Development:** Docker container
  - **Production:** Railway PostgreSQL or Neon (10GB free)
- **Connection:** Npgsql (.NET provider)
- **Migrations:** EF Core Migrations

### Testing
- **Unit Tests:** xUnit + Moq + FluentAssertions + AutoFixture (75% of tests)
- **Integration Tests:** Testcontainers (PostgreSQL) (20% of tests)
- **E2E Tests:** Playwright (5% of tests)
- **Frontend Tests:** Jasmine/Karma (Angular)
- **TDD Approach:** Red-Green-Refactor workflow
- **Coverage Goals:** 90% Domain, 80% Application, 60% Infrastructure

### DevOps
- **Containerization:** Docker & Docker Compose
- **Hosting:** Railway (recommended all-in-one) or Render
- **Logging:** Serilog + Seq (centralized logging)
- **CI/CD:** GitHub Actions
- **Monitoring:** Health checks + structured logging

---

## 3. Database Decision: PostgreSQL

### 3.1 Free Tier Comparison

| Provider | Database | Free Storage | Limitations | Best For |
|----------|----------|--------------|-------------|----------|
| **Neon** | PostgreSQL | **10GB** | Serverless, auto-sleep |  Best long-term |
| **Supabase** | PostgreSQL | 500MB + API | 2 projects | MVP with API |
| **Railway** | PostgreSQL | In $5 credit | Shared resource | All-in-one |
| **Render** | PostgreSQL | 90 days free | Then sleeps | Testing |
| **PlanetScale** | MySQL | 5GB | Serverless | Scaling |
| **AWS RDS** | MySQL | 12 months free | After = paid | Short-term |

### 3.2 Winner: PostgreSQL

**Reasons:**
1.  More free tier providers (5 vs 3 for MySQL)
2.  Better free storage (Neon: 10GB vs PlanetScale: 5GB)
3.  .NET Core has excellent Npgsql driver
4.  JSON support (good for future features)
5.  More mature open-source ecosystem
6.  Better for Docker deployments

**Recommendation:** Use **Neon** for production (10GB free forever) and **Railway** for all-in-one development

---

## 4. Microservices Architecture (2 Services)

### 4.1 Architecture Decision Rationale

**Why 2 services instead of 3?**
- Rules are tightly coupled with scoring calculations
- Reduces inter-service communication overhead
- Simplifies transaction boundaries
- Lower operational complexity
- Better data consistency for predictions + scoring

---

### 4.2 Service 1: Auth & Groups Service

**Port:** 5001  
**Database:** `arenavault_auth` (PostgreSQL)  
**Clean Architecture:** Domain  Application  Infrastructure  WebApi

#### Responsibilities (Bounded Context)
- User authentication (JWT tokens)
- User registration, login, profiles
- Group CRUD operations (public/private)
- Group membership management
- Invitation system (link/PIN generation)
- Approval workflow for private groups
- Authorization policies

#### Key Domain Entities
- `User`: Identity, email, password hash, profile
- `UserProfile`: Name, avatar, preferences
- `Group`: Name, description, type (public/private), access code
- `GroupMembership`: User-group relationships, status (pending/approved)
- `GroupInvitation`: Invitation links, expiry, usage tracking

#### Value Objects
- `Email`: Validated email address
- `GroupPin`: 6-digit access code
- `AccessLevel`: Admin, Member, Viewer

#### API Endpoints
```
POST   /api/v1/auth/register
POST   /api/v1/auth/login
POST   /api/v1/auth/refresh-token
GET    /api/v1/users/{id}
PUT    /api/v1/users/{id}/profile
POST   /api/v1/groups
GET    /api/v1/groups/{id}
PUT    /api/v1/groups/{id}
DELETE /api/v1/groups/{id}
GET    /api/v1/groups/search?code={pin}
POST   /api/v1/groups/{id}/join
PUT    /api/v1/groups/{id}/members/{userId}/approve
GET    /api/v1/groups/{id}/members
DELETE /api/v1/groups/{id}/members/{userId}
```

---

### 4.3 Service 2: Game Management Service

**Port:** 5002  
**Database:** `arenavault_game` (PostgreSQL)  
**Clean Architecture:** Domain  Application  Infrastructure  WebApi

#### Responsibilities (Bounded Context)
- Tournament and match data management
- Team management
- Rule configurations (per group)
- Predictions and deadline enforcement
- Scoring engine (exact, winner, goals, bonuses)
- Leaderboards and rankings
- Prize pool management
- Statistics and analytics

#### Key Domain Entities
- `Tournament`: Competition data, teams, phase structure
- `Team`: Name, logo, country
- `Match`: Tournament, teams, kickoff time, phase
- `MatchResult`: Final score, goals, timestamps
- `GroupRuleConfiguration`: Points for exact/winner/goals, bonuses
- `Prediction`: User prediction, score, timestamp
- `LeaderboardEntry`: User standings, points breakdown
- `PrizePool`: Group prize tracking, distribution

#### Value Objects
- `Score`: Home and away goals (immutable)
- `RulePoints`: Points configuration
- `MatchDate`: Kickoff time with timezone
- `PhaseBonus`: Phase-specific bonus configuration

#### Domain Services
- `ScoringEngine`: Calculate points from predictions
- `LeaderboardCalculator`: Update rankings and tie-breaking
- `DeadlineEnforcer`: Validate prediction timing

#### API Endpoints
```
# Tournaments & Matches
GET    /api/v1/tournaments
GET    /api/v1/tournaments/{id}
GET    /api/v1/tournaments/{id}/matches
GET    /api/v1/matches/{id}
POST   /api/v1/matches/{id}/results  (Admin)

# Predictions
POST   /api/v1/predictions
GET    /api/v1/predictions/{id}
PUT    /api/v1/predictions/{id}
GET    /api/v1/predictions/user/{userId}
GET    /api/v1/predictions/match/{matchId}

# Rules Configuration
POST   /api/v1/groups/{groupId}/rules
GET    /api/v1/groups/{groupId}/rules
PUT    /api/v1/groups/{groupId}/rules
GET    /api/v1/groups/{groupId}/rules/history

# Leaderboards
GET    /api/v1/groups/{groupId}/leaderboard
GET    /api/v1/groups/{groupId}/leaderboard/phase/{phase}
GET    /api/v1/users/{userId}/stats

# Prize Pools
POST   /api/v1/groups/{groupId}/prize-pool
GET    /api/v1/groups/{groupId}/prize-pool
PUT    /api/v1/groups/{groupId}/prize-pool/distribute
```

---

## 5. Clean Architecture Structure

### 5.1 Architecture Layers

Each microservice follows **Clean Architecture** principles with 4 layers:

```
─
                    WebApi Layer                         
  Controllers, Middleware, Filters, DTOs (external)      

                       
─
                 Application Layer                       
  Use Cases, Application Services, DTOs (internal)       
  Interfaces (for Infrastructure), Validators            
┘
                       

                   Domain Layer                          
  Entities, Value Objects, Domain Services               
  Domain Events, Business Rules, Interfaces              

                       
─
               Infrastructure Layer                      
  EF Core, Repositories, External APIs                   
  JWT Services, Email, Database Migrations               
─
```

**Dependency Rule:** Dependencies flow INWARD
- WebApi  Application  Domain
- Infrastructure  Application, Domain
- Domain has NO dependencies (pure business logic)

---

### 5.2 Layer Responsibilities

#### **Domain Layer** (`ArenaVault.{Service}.Domain`)
**Purpose:** Core business logic, independent of frameworks

**Contents:**
- **Entities:** Rich domain models with behavior
- **Value Objects:** Immutable objects
- **Domain Services:** Complex logic spanning multiple entities
- **Domain Events:** Event-driven domain logic
- **Interfaces:** Repository contracts
- **Exceptions:** Domain-specific exceptions

**Key Principles:**
- No external dependencies (no EF Core, no JSON, no HTTP)
- Business rules enforced in entity methods
- Encapsulation: private setters, factory methods

**Example Entity:**
```csharp
public class Prediction : BaseEntity
{
    public Guid UserId { get; private set; }
    public Guid MatchId { get; private set; }
    public Score PredictedScore { get; private set; }
    public DateTime SubmittedAt { get; private set; }
    public bool IsLocked { get; private set; }
    
    // Business rule: Can't change prediction after deadline
    public void UpdateScore(Score newScore, Match match, int deadlineMinutes)
    {
        var deadline = match.KickoffTime.AddMinutes(-deadlineMinutes);
        
        if (DateTime.UtcNow >= deadline)
            throw new PredictionDeadlineExceededException();
        
        if (IsLocked)
            throw new PredictionLockedException();
        
        PredictedScore = newScore;
    }
    
    public void Lock()
    {
        if (IsLocked)
            throw new PredictionAlreadyLockedException();
        
        IsLocked = true;
    }
}
```

---

#### **Application Layer** (`ArenaVault.{Service}.Application`)
**Purpose:** Orchestrate use cases, coordinate domain and infrastructure

**Contents:**
- **Use Cases / Commands:** CQRS pattern
- **Queries:** Read-only operations
- **DTOs:** Data Transfer Objects
- **Interfaces:** For infrastructure services
- **Validators:** FluentValidation rules
- **Mappers:** AutoMapper profiles

**Key Principles:**
- Thin orchestration layer
- No business logic (delegate to Domain)
- Transaction boundaries defined here

**Example Command Handler:**
```csharp
public class CreatePredictionCommandHandler : IRequestHandler<CreatePredictionCommand, PredictionDto>
{
    private readonly IPredictionRepository _repository;
    private readonly IMatchRepository _matchRepository;
    private readonly IMapper _mapper;
    
    public async Task<PredictionDto> Handle(CreatePredictionCommand request, CancellationToken cancellationToken)
    {
        // 1. Fetch match
        var match = await _matchRepository.GetByIdAsync(request.MatchId);
        if (match == null)
            throw new MatchNotFoundException();
        
        // 2. Domain logic
        var prediction = Prediction.Create(request.UserId, match.Id, request.PredictedScore);
        
        // 3. Persist
        await _repository.AddAsync(prediction);
        await _repository.SaveChangesAsync();
        
        // 4. Return DTO
        return _mapper.Map<PredictionDto>(prediction);
    }
}
```

---

#### **Infrastructure Layer** (`ArenaVault.{Service}.Infrastructure`)
**Purpose:** External concerns (database, APIs, file system)

**Contents:**
- **Persistence:** EF Core DbContext, Migrations, Repositories
- **External Services:** JWT generation, email, file storage
- **Configurations:** Entity configurations (Fluent API)
- **Seed Data:** Initial data for development

**Key Principles:**
- Implements interfaces defined in Application/Domain
- EF Core knowledge isolated here
- Can swap implementations (e.g., in-memory for tests)

**Example Repository:**
```csharp
public class PredictionRepository : IPredictionRepository
{
    private readonly GameDbContext _context;
    
    public async Task<Prediction?> GetByIdAsync(Guid id)
    {
        return await _context.Predictions
            .Include(p => p.Match)
            .FirstOrDefaultAsync(p => p.Id == id);
    }
    
    public async Task AddAsync(Prediction prediction)
    {
        await _context.Predictions.AddAsync(prediction);
    }
    
    public async Task SaveChangesAsync()
    {
        await _context.SaveChangesAsync();
    }
}
```

---

#### **WebApi Layer** (`ArenaVault.{Service}.WebApi`)
**Purpose:** HTTP interface, routing, authentication

**Contents:**
- **Controllers:** REST endpoints
- **Middleware:** JWT authentication, exception handling, logging
- **Filters:** Authorization, validation
- **DTOs:** API request/response models (external contracts)
- **Swagger:** API documentation

**Key Principles:**
- Thin controllers (delegate to Application layer)
- API versioning (v1, v2)
- Consistent error responses

**Example Controller:**
```csharp
[ApiController]
[Route("api/v1/[controller]")]
[Authorize]
public class PredictionsController : ControllerBase
{
    private readonly IMediator _mediator;
    
    public PredictionsController(IMediator mediator)
    {
        _mediator = mediator;
    }
    
    [HttpPost]
    public async Task<ActionResult<PredictionDto>> CreatePrediction([FromBody] CreatePredictionRequest request)
    {
        var command = new CreatePredictionCommand
        {
            UserId = User.GetUserId(),
            MatchId = request.MatchId,
            PredictedScore = request.PredictedScore
        };
        
        var result = await _mediator.Send(command);
        return CreatedAtAction(nameof(GetPrediction), new { id = result.Id }, result);
    }
    
    [HttpGet("{id}")]
    public async Task<ActionResult<PredictionDto>> GetPrediction(Guid id)
    {
        var query = new GetPredictionQuery { Id = id };
        var result = await _mediator.Send(query);
        
        return result != null ? Ok(result) : NotFound();
    }
}
```

---

## 6. TDD Strategy

### 6.1 Testing Pyramid

```
                  
                 / \
                /   \
               / E2E \          ~5% (Critical paths)
              /_______\
             /         \
            / Integration\     ~20% (Database, API)
           /_____________\
          /               \
         /   Unit Tests    \   ~75% (Domain, Application)
        /___________________\
```

### 6.2 Test Types

#### **Unit Tests** (75% of tests)
**Scope:** Domain entities, value objects, domain services, command handlers

**Tools:**
- **xUnit:** Test framework
- **FluentAssertions:** Readable assertions
- **Moq:** Mocking dependencies
- **AutoFixture:** Test data generation

**Strategy:**
- Test domain logic in isolation
- Mock all external dependencies
- Fast execution (<1ms per test)
- No database access

**Example:**
```csharp
public class PredictionTests
{
    [Fact]
    public void UpdateScore_WhenDeadlinePassed_ThrowsException()
    {
        // Arrange
        var match = MatchBuilder.Create()
            .WithKickoff(DateTime.UtcNow.AddMinutes(-10))
            .Build();
        var prediction = PredictionBuilder.Create()
            .WithMatch(match)
            .Build();
        var newScore = new Score(2, 1);
        
        // Act & Assert
        prediction.Invoking(p => p.UpdateScore(newScore, match, 15))
            .Should().Throw<PredictionDeadlineExceededException>();
    }
    
    [Fact]
    public void Lock_WhenAlreadyLocked_ThrowsException()
    {
        // Arrange
        var prediction = PredictionBuilder.Create().Locked().Build();
        
        // Act & Assert
        prediction.Invoking(p => p.Lock())
            .Should().Throw<PredictionAlreadyLockedException>();
    }
}
```

---

#### **Integration Tests** (20% of tests)
**Scope:** Database operations, API endpoints

**Tools:**
- **xUnit:** Test framework
- **Testcontainers:** Real PostgreSQL in Docker
- **WebApplicationFactory:** In-memory API testing

**Strategy:**
- Test with REAL PostgreSQL (via Testcontainers)
- Verify EF Core mappings, queries
- Test HTTP endpoints end-to-end
- Slower execution (~50-200ms per test)

**Example:**
```csharp
public class PredictionRepositoryTests : IClassFixture<DatabaseFixture>
{
    private readonly GameDbContext _context;
    
    public PredictionRepositoryTests(DatabaseFixture fixture)
    {
        _context = fixture.Context;
    }
    
    [Fact]
    public async Task GetByIdAsync_WithIncludes_ReturnsMatchData()
    {
        // Arrange
        var match = MatchBuilder.Create().Build();
        var prediction = PredictionBuilder.Create().WithMatch(match).Build();
        await _context.Predictions.AddAsync(prediction);
        await _context.SaveChangesAsync();
        
        var repository = new PredictionRepository(_context);
        
        // Act
        var result = await repository.GetByIdAsync(prediction.Id);
        
        // Assert
        result.Should().NotBeNull();
        result.Match.Should().NotBeNull(); // Verify eager loading
    }
}
```

---

#### **E2E Tests** (5% of tests)
**Scope:** Critical user flows

**Tools:**
- **Playwright:** Browser automation
- **Docker Compose:** Full stack

**Strategy:**
- Test REAL user scenarios
- Only critical paths
- Run in CI pipeline
- Slowest execution (~5-30s per test)

---

### 6.3 TDD Workflow (Red-Green-Refactor)

#### **Step 1: RED** (Write failing test)
```csharp
[Fact]
public void CalculatePoints_ExactScore_ReturnsOnlyExactPoints()
{
    var engine = new ScoringEngine();
    var prediction = new Prediction(homeGoals: 2, awayGoals: 1);
    var result = new MatchResult(homeGoals: 2, awayGoals: 1);
    var rules = RuleConfigurationBuilder.WithExactScore(10).Build();
    
    var points = engine.Calculate(prediction, result, rules);
    
    points.Should().Be(10);
}
```

#### **Step 2: GREEN** (Make it pass)
```csharp
public class ScoringEngine
{
    public int Calculate(Prediction prediction, MatchResult result, RuleConfiguration rules)
    {
        if (prediction.IsExactMatch(result))
            return rules.ExactScorePoints;
        
        return 0;
    }
}
```

#### **Step 3: REFACTOR** (Improve code)
```csharp
public class ScoringEngine
{
    public PointsResult Calculate(Prediction prediction, MatchResult result, RuleConfiguration rules)
    {
        if (prediction.IsExactMatch(result))
            return new PointsResult 
            { 
                Points = rules.ExactScorePoints,
                ExactScores = 1 
            };
        
        return PointsResult.Empty;
    }
}
```

---

### 6.4 Test Coverage Goals

| Layer | Minimum Coverage | Rationale |
|-------|------------------|-----------|
| **Domain** | 90%+ | Critical business logic |
| **Application** | 80%+ | Command handlers, queries |
| **Infrastructure** | 60%+ | Repository implementations |
| **WebApi** | 50%+ | Controller actions |

**Coverage Tools:**
- **Coverlet:** Code coverage collection
- **ReportGenerator:** HTML coverage reports

---


## 7. Project Structure

### 7.1 Solution Structure (.NET)

```
ArenaVault/
 src/
    Services/
       Auth/
          ArenaVault.Auth.Domain/
          ArenaVault.Auth.Application/
          ArenaVault.Auth.Infrastructure/
          ArenaVault.Auth.WebApi/
      
       Game/
           ArenaVault.Game.Domain/
           ArenaVault.Game.Application/
           ArenaVault.Game.Infrastructure/
           ArenaVault.Game.WebApi/
   
    Shared/
       ArenaVault.Shared/
          ─ Common/
           Extensions/
           Exceptions/
   
    Frontend/
        arena-vault-app/   (Angular)

 tests/
    Auth/
       ArenaVault.Auth.UnitTests/
       ArenaVault.Auth.IntegrationTests/
       ArenaVault.Auth.FunctionalTests/
   
    Game/
        ArenaVault.Game.UnitTests/
        ArenaVault.Game.IntegrationTests/
        ArenaVault.Game.FunctionalTests/

 infrastructure/
    database/
       init.sql
    docker/
        Dockerfile.auth
        Dockerfile.game

 docker-compose.yml
 docker-compose.override.yml
 .github/
    workflows/
        ci-backend.yml
        ci-frontend.yml
 ArenaVault.sln
 README.md
```

---

### 7.2 Detailed Project Structures

#### Auth Service
```
ArenaVault.Auth.Domain/
 Entities/
    User.cs
    UserProfile.cs
    Group.cs
    GroupMembership.cs
    GroupInvitation.cs
 ValueObjects/
    Email.cs
    GroupPin.cs
    AccessLevel.cs
 Interfaces/
    IUserRepository.cs
    IGroupRepository.cs
 Events/
    UserRegisteredEvent.cs
    GroupCreatedEvent.cs
 Exceptions/
     UserAlreadyExistsException.cs
     InvalidGroupPinException.cs

ArenaVault.Auth.Application/
 Commands/
    RegisterUser/
    CreateGroup/
    JoinGroup/
 Queries/
    GetUser/
    GetUserGroups/
 DTOs/
    UserDto.cs
    GroupDto.cs
 Interfaces/
    IJwtService.cs
    IEmailService.cs
 Mappers/
     AuthMappingProfile.cs

ArenaVault.Auth.Infrastructure/
 Persistence/
    AuthDbContext.cs
    Migrations/
    Configurations/
    Repositories/
 Services/
    JwtService.cs
    EmailService.cs
 DependencyInjection.cs

ArenaVault.Auth.WebApi/
 Controllers/
    AuthController.cs
    UsersController.cs
   ─ GroupsController.cs
 Middleware/
    ExceptionHandlingMiddleware.cs
 DTOs/
    Requests/
    Responses/
 Program.cs
 Dockerfile
```

#### Game Service
```
ArenaVault.Game.Domain/
 Entities/
    Tournament.cs
    Team.cs
    Match.cs
    Prediction.cs
    MatchResult.cs
    GroupRuleConfiguration.cs
    LeaderboardEntry.cs
─ ValueObjects/
    Score.cs
    RulePoints.cs
    MatchDate.cs
 Services/
    ScoringEngine.cs
    LeaderboardCalculator.cs
 Interfaces/
    IPredictionRepository.cs
    IMatchRepository.cs
 Exceptions/
     PredictionDeadlineExceededException.cs

ArenaVault.Game.Application/
 Commands/
    CreatePrediction/
    RecordMatchResult/
    ConfigureGroupRules/
 Queries/
    GetLeaderboard/
    GetUserPredictions/
 DTOs/
    PredictionDto.cs
    LeaderboardDto.cs
 Mappers/
     GameMappingProfile.cs

ArenaVault.Game.Infrastructure/
 Persistence/
    GameDbContext.cs
    Migrations/
    Configurations/
    Repositories/
 DependencyInjection.cs

ArenaVault.Game.WebApi/
 Controllers/
    PredictionsController.cs
    MatchesController.cs
    LeaderboardsController.cs
 Middleware/
    ExceptionHandlingMiddleware.cs
 Program.cs
 Dockerfile
```

---

## 8. Database Schema (PostgreSQL)

### 8.1 Auth Database Schema

```sql
-- Database: arenavault_auth

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User profiles
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    avatar_url TEXT,
    preferences JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Groups table
CREATE TABLE groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    type VARCHAR(50) CHECK(type IN ('public', 'private')) NOT NULL,
    access_code VARCHAR(6) UNIQUE NOT NULL,
    created_by UUID NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id)
);

-- Group memberships
CREATE TABLE group_memberships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL,
    user_id UUID NOT NULL,
    status VARCHAR(50) CHECK(status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
    role VARCHAR(50) CHECK(role IN ('admin', 'member', 'viewer')) DEFAULT 'member',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(group_id, user_id)
);

-- Group invitations
CREATE TABLE group_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL,
    invited_by UUID NOT NULL,
    invite_code VARCHAR(50) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    max_uses INT DEFAULT 1,
    used_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
    FOREIGN KEY (invited_by) REFERENCES users(id)
);

-- Indexes
CREATE INDEX idx_groups_access_code ON groups(access_code);
CREATE INDEX idx_memberships_group_id ON group_memberships(group_id);
CREATE INDEX idx_memberships_user_id ON group_memberships(user_id);
CREATE INDEX idx_invitations_code ON group_invitations(invite_code);
```

---

### 8.2 Game Database Schema

```sql
-- Database: arenavault_game

-- Tournaments table
CREATE TABLE tournaments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    year INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Teams table
CREATE TABLE teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    country VARCHAR(100) NOT NULL,
    logo_url TEXT,
    tournament_id UUID NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE CASCADE
);

-- Matches table
CREATE TABLE matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL,
    home_team_id UUID NOT NULL,
    away_team_id UUID NOT NULL,
    kickoff_time TIMESTAMP NOT NULL,
    phase VARCHAR(50) CHECK(phase IN ('group', 'round_of_16', 'quarter', 'semi', 'final')) NOT NULL,
    home_goals INT,
    away_goals INT,
    status VARCHAR(50) CHECK(status IN ('scheduled', 'live', 'finished')) DEFAULT 'scheduled',
    finished_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE CASCADE,
    FOREIGN KEY (home_team_id) REFERENCES teams(id),
    FOREIGN KEY (away_team_id) REFERENCES teams(id)
);

-- Group rule configurations
CREATE TABLE group_rule_configurations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL UNIQUE,
    exact_score_points INT NOT NULL DEFAULT 5,
    winner_points INT NOT NULL DEFAULT 2,
    goal_points INT NOT NULL DEFAULT 1,
    unique_prediction_points INT NOT NULL DEFAULT 5,
    prediction_deadline_minutes INT NOT NULL DEFAULT 15,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Phase bonus configurations
CREATE TABLE phase_bonus_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL,
    phase VARCHAR(50) NOT NULL,
    points INT NOT NULL,
    enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES group_rule_configurations(group_id) ON DELETE CASCADE,
    UNIQUE(group_id, phase)
);

-- Predictions table
CREATE TABLE predictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id UUID NOT NULL,
    user_id UUID NOT NULL,
    group_id UUID NOT NULL,
    home_goals INT NOT NULL,
    away_goals INT NOT NULL,
    predicted_qualifier_id UUID,
    is_locked BOOLEAN DEFAULT false,
    locked_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE,
    FOREIGN KEY (predicted_qualifier_id) REFERENCES teams(id),
    UNIQUE(match_id, user_id, group_id)
);

-- Leaderboard entries
CREATE TABLE leaderboard_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL,
    user_id UUID NOT NULL,
    total_points INT DEFAULT 0,
    exact_scores INT DEFAULT 0,
    winners_correct INT DEFAULT 0,
    goals_correct INT DEFAULT 0,
    unique_predictions INT DEFAULT 0,
    phase_bonuses INT DEFAULT 0,
    rank INT DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(group_id, user_id)
);

-- Prize pools
CREATE TABLE prize_pools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL UNIQUE,
    total_amount DECIMAL(10, 2) DEFAULT 0.00,
    first_place_percentage DECIMAL(5, 2) DEFAULT 50.00,
    second_place_percentage DECIMAL(5, 2) DEFAULT 30.00,
    third_place_percentage DECIMAL(5, 2) DEFAULT 20.00,
    distributed BOOLEAN DEFAULT false,
    distributed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_matches_tournament ON matches(tournament_id);
CREATE INDEX idx_matches_kickoff ON matches(kickoff_time);
CREATE INDEX idx_predictions_match ON predictions(match_id);
CREATE INDEX idx_predictions_user_group ON predictions(user_id, group_id);
CREATE INDEX idx_leaderboard_group ON leaderboard_entries(group_id);
CREATE INDEX idx_leaderboard_rank ON leaderboard_entries(group_id, rank);
```

---

### 8.3 Entity Framework Configuration Examples

#### Prediction Configuration
```csharp
public class PredictionConfiguration : IEntityTypeConfiguration<Prediction>
{
    public void Configure(EntityTypeBuilder<Prediction> builder)
    {
        builder.ToTable("predictions");
        
        builder.HasKey(p => p.Id);
        builder.Property(p => p.Id).HasColumnName("id");
        
        builder.Property(p => p.MatchId).HasColumnName("match_id").IsRequired();
        builder.Property(p => p.UserId).HasColumnName("user_id").IsRequired();
        builder.Property(p => p.GroupId).HasColumnName("group_id").IsRequired();
        
        builder.OwnsOne(p => p.PredictedScore, score =>
        {
            score.Property(s => s.HomeGoals).HasColumnName("home_goals").IsRequired();
            score.Property(s => s.AwayGoals).HasColumnName("away_goals").IsRequired();
        });
        
        builder.Property(p => p.IsLocked).HasColumnName("is_locked").HasDefaultValue(false);
        builder.Property(p => p.LockedAt).HasColumnName("locked_at");
        builder.Property(p => p.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("CURRENT_TIMESTAMP");
        builder.Property(p => p.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("CURRENT_TIMESTAMP");
        
        builder.HasIndex(p => p.MatchId).HasDatabaseName("idx_predictions_match");
        builder.HasIndex(p => new { p.UserId, p.GroupId }).HasDatabaseName("idx_predictions_user_group");
    }
}
```

---

## 9. Implementation Guidelines

### 9.1 Dependency Injection Setup

**Program.cs (WebApi Layer):**
```csharp
var builder = WebApplication.CreateBuilder(args);

// Add layers
builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);

// Add API services
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// JWT Authentication
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Secret"]))
        };
    });

var app = builder.Build();

// Middleware pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();
```

**Application Layer DI:**
```csharp
public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(Assembly.GetExecutingAssembly()));
        services.AddAutoMapper(Assembly.GetExecutingAssembly());
        services.AddValidatorsFromAssembly(Assembly.GetExecutingAssembly());
        
        // Add behaviors
        services.AddTransient(typeof(IPipelineBehavior<,>), typeof(ValidationBehavior<,>));
        services.AddTransient(typeof(IPipelineBehavior<,>), typeof(LoggingBehavior<,>));
        
        return services;
    }
}
```

**Infrastructure Layer DI:**
```csharp
public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        // Database
        services.AddDbContext<GameDbContext>(options =>
            options.UseNpgsql(configuration.GetConnectionString("PostgreSQL")));
        
        // Repositories
        services.AddScoped<IPredictionRepository, PredictionRepository>();
        services.AddScoped<IMatchRepository, MatchRepository>();
        services.AddScoped<ILeaderboardRepository, LeaderboardRepository>();
        
        // Services
        services.AddScoped<IJwtService, JwtService>();
        
        // Domain Services
        services.AddScoped<ScoringEngine>();
        services.AddScoped<LeaderboardCalculator>();
        
        return services;
    }
}
```

---

### 9.2 EF Core Migrations

**Create Migration:**
```bash
cd src/Services/Game/ArenaVault.Game.Infrastructure
dotnet ef migrations add InitialCreate --startup-project ../ArenaVault.Game.WebApi
```

**Apply Migration:**
```bash
dotnet ef database update --startup-project ../ArenaVault.Game.WebApi
```

**Remove Last Migration:**
```bash
dotnet ef migrations remove --startup-project ../ArenaVault.Game.WebApi
```

---

### 9.3 Coding Standards

**C# Conventions:**
- Use **C# 12** features (primary constructors, collection expressions)
- **Async/await** for all I/O operations
- **Nullable reference types** enabled
- **Record types** for DTOs and Value Objects
- **Pattern matching** for type checks

**Naming Conventions:**
- **PascalCase:** Classes, methods, properties
- **camelCase:** Local variables, parameters
- **_camelCase:** Private fields
- **UPPER_CASE:** Constants

---


## 10. Docker Compose Configuration

```yaml
version: '3.8'

services:
  # PostgreSQL Database
  postgres:
    image: postgres:16-alpine
    container_name: arenavault-db
    environment:
      POSTGRES_DB: arenavault
      POSTGRES_USER: ${DB_USER:-postgres}
      POSTGRES_PASSWORD: ${DB_PASSWORD:-devpassword}
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./infrastructure/database/init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
    networks:
      - arenavault-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-postgres}"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Auth & Groups API
  auth-api:
    build:
      context: ./src/Services/Auth
      dockerfile: ArenaVault.Auth.WebApi/Dockerfile
    container_name: arenavault-auth-api
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - ASPNETCORE_URLS=http://+:8080
      - ConnectionStrings__PostgreSQL=Host=postgres;Port=5432;Database=arenavault_auth;Username=${DB_USER:-postgres};Password=${DB_PASSWORD:-devpassword}
      - Jwt__Secret=${JWT_SECRET:-your-super-secret-key-change-in-production}
      - Jwt__Issuer=ArenaVault
      - Jwt__Audience=ArenaVault.Users
      - Jwt__ExpirationMinutes=1440
    ports:
      - "5001:8080"
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - arenavault-network
    restart: unless-stopped

  # Game Management API
  game-api:
    build:
      context: ./src/Services/Game
      dockerfile: ArenaVault.Game.WebApi/Dockerfile
    container_name: arenavault-game-api
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - ASPNETCORE_URLS=http://+:8080
      - ConnectionStrings__PostgreSQL=Host=postgres;Port=5432;Database=arenavault_game;Username=${DB_USER:-postgres};Password=${DB_PASSWORD:-devpassword}
      - AuthApi__BaseUrl=http://auth-api:8080
    ports:
      - "5002:8080"
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - arenavault-network
    restart: unless-stopped

  # Angular Frontend
  frontend:
    build:
      context: ./src/Frontend/arena-vault-app
      dockerfile: Dockerfile
    container_name: arenavault-frontend
    ports:
      - "4200:80"
    depends_on:
      - auth-api
      - game-api
    networks:
      - arenavault-network
    restart: unless-stopped

volumes:
  postgres-data:

networks:
  arenavault-network:
    driver: bridge
```

### .env File Example

```env
# Database
DB_USER=postgres
DB_PASSWORD=your_secure_password_here

# JWT
JWT_SECRET=your-256-bit-secret-key-change-in-production

# CORS (frontend URL)
CORS_ORIGINS=http://localhost:4200,https://yourdomain.com
```

---

## 11. Deployment Strategy

### 11.1 Development Environment

**Requirements:**
- Docker Desktop
- .NET SDK 8.0+
- Node.js 20+ & npm
- Angular CLI
- PostgreSQL client (optional, for manual queries)

**Setup Commands:**
```bash
# Clone repository
git clone https://github.com/your-org/arena-vault.git
cd arena-vault

# Start all services
docker-compose up --build

# Access:
# - Auth API: http://localhost:5001/swagger
# - Game API: http://localhost:5002/swagger
# - Frontend: http://localhost:4200
# - PostgreSQL: localhost:5432
```

---

### 11.2 Production Deployment (Railway - Recommended)

**Why Railway?**
- All-in-one solution (database + backends + frontend)
- $5/month credit initially
- PostgreSQL included
- GitHub Actions integration
- Simple environment variable management

**Deployment Steps:**

1. **Create Railway Account** (https://railway.app)

2. **Create New Project**
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Connect your repository

3. **Add PostgreSQL Service**
   - Click "+ New"
   - Select "Database"  "PostgreSQL"
   - Copy connection string

4. **Deploy Auth API Service**
   - Click "+ New"
   - Select "GitHub Repo"
   - Configure:
     - Build Command: `dotnet publish -c Release -o out src/Services/Auth/ArenaVault.Auth.WebApi`
     - Start Command: `dotnet out/ArenaVault.Auth.WebApi.dll`
     - Port: 8080
   - Add environment variables:
     - `ConnectionStrings__PostgreSQL`: (PostgreSQL connection string)
     - `Jwt__Secret`: (generate strong secret)
     - `Jwt__Issuer`: ArenaVault
     - `Jwt__Audience`: ArenaVault.Users

5. **Deploy Game API Service**
   - Repeat step 4 for Game service
   - Add environment variables:
     - `ConnectionStrings__PostgreSQL`: (PostgreSQL connection string)
     - `AuthApi__BaseUrl`: (Auth API URL from Railway)

6. **Deploy Frontend**
   - Build Command: `cd src/Frontend/arena-vault-app && npm install && npm run build`
   - Start Command: Serve static files from `dist/`
   - Add environment variables:
     - `API_AUTH_URL`: (Auth API URL)
     - `API_GAME_URL`: (Game API URL)

7. **Run Migrations**
   - Connect to PostgreSQL via Railway CLI
   - Run EF Core migrations:
     ```bash
     dotnet ef database update --project src/Services/Auth/ArenaVault.Auth.Infrastructure --startup-project src/Services/Auth/ArenaVault.Auth.WebApi
     dotnet ef database update --project src/Services/Game/ArenaVault.Game.Infrastructure --startup-project src/Services/Game/ArenaVault.Game.WebApi
     ```

---

### 11.3 Alternative: Render + Neon (Free Tier Max)

**Stack:**
- **Database:** Neon (10GB free, forever)
- **Backends:** Render (free tier with sleep)
- **Frontend:** Vercel (free tier)

**Pros:**
- Neon: 10GB free (best storage)
- Each service on specialized platform
- Generous free tiers

**Cons:**
- 3 different platforms to manage
- More environment variable complexity

---

### 11.4 CI/CD with GitHub Actions

**.github/workflows/ci-backend.yml:**
```yaml
name: Backend CI/CD

on:
  push:
    branches: [ master ]
    paths:
      - 'src/Services/**'
  pull_request:
    branches: [ master ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup .NET
      uses: actions/setup-dotnet@v3
      with:
        dotnet-version: 8.0.x
    
    - name: Restore dependencies
      run: dotnet restore
    
    - name: Build
      run: dotnet build --no-restore
    
    - name: Run unit tests
      run: dotnet test --no-build --verbosity normal --filter Category=Unit
    
    - name: Run integration tests
      run: dotnet test --no-build --verbosity normal --filter Category=Integration
    
    - name: Generate coverage report
      run: |
        dotnet test --collect:"XPlat Code Coverage" --results-directory ./coverage
        reportgenerator -reports:./coverage/**/coverage.cobertura.xml -targetdir:./coverage/report
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        directory: ./coverage/report

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/master'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Deploy to Railway
      uses: bervProject/railway-deploy@main
      with:
        railway_token: ${{ secrets.RAILWAY_TOKEN }}
        service: auth-api
```

---

## 12. Development Phases

### Phase 1: Foundation (Weeks 1-2)
- [x] Project architecture design
- [x] Database schema design
- [x] Technology stack selection
- [ ] Create .NET solution structure
- [ ] Create Angular project
- [ ] Set up Docker Compose
- [ ] Set up PostgreSQL with init scripts
- [ ] Configure EF Core + migrations
- [ ] Set up CI/CD pipeline basics

### Phase 2: Auth & Groups Service (Weeks 3-4)
- [ ] Implement Domain layer (TDD)
  - [ ] User entity with tests
  - [ ] Group entity with tests
  - [ ] GroupMembership entity with tests
- [ ] Implement Application layer
  - [ ] RegisterUser command + handler + tests
  - [ ] Login command + handler + tests
  - [ ] CreateGroup command + handler + tests
  - [ ] JoinGroup command + handler + tests
- [ ] Implement Infrastructure layer
  - [ ] EF Core repositories + tests
  - [ ] JWT service + tests
- [ ] Implement WebApi layer
  - [ ] AuthController + integration tests
  - [ ] GroupsController + integration tests
- [ ] JWT authentication middleware
- [ ] Swagger documentation

### Phase 3: Game Management Service (Weeks 5-7)
- [ ] Implement Domain layer (TDD)
  - [ ] Match, Tournament, Team entities + tests
  - [ ] Prediction entity + deadline logic + tests
  - [ ] ScoringEngine domain service + tests
  - [ ] LeaderboardCalculator domain service + tests
- [ ] Implement Application layer
  - [ ] CreatePrediction command + tests
  - [ ] RecordMatchResult command + tests
  - [ ] GetLeaderboard query + tests
  - [ ] ConfigureGroupRules command + tests
- [ ] Implement Infrastructure layer
  - [ ] Repositories + tests
- [ ] Implement WebApi layer
  - [ ] Controllers + integration tests
- [ ] Background job: Prediction locking (15 min before kickoff)
- [ ] Background job: Leaderboard recalculation

### Phase 4: Frontend (Weeks 8-10)
- [ ] Set up Angular 18 project
- [ ] Configure routing and authentication
- [ ] Implement authentication pages (login, register)
- [ ] Implement group management pages
  - [ ] Create/join group
  - [ ] Group dashboard
  - [ ] Member management (admin)
- [ ] Implement prediction pages
  - [ ] Upcoming matches list
  - [ ] Create/edit prediction form
  - [ ] My predictions history
- [ ] Implement leaderboard page
  - [ ] Group leaderboard with filters
  - [ ] User statistics
- [ ] Responsive design (mobile/tablet/desktop)
- [ ] E2E tests with Playwright

### Phase 5: Testing & Polish (Week 11)
- [ ] Achieve test coverage goals (90/80/60)
- [ ] Integration testing with Testcontainers
- [ ] E2E testing critical flows
- [ ] Performance testing
- [ ] Security audit (OWASP Top 10)
- [ ] Load testing with k6
- [ ] UI/UX polish
- [ ] Documentation completion

### Phase 6: Deployment & Launch (Week 12)
- [ ] Deploy to Railway (or chosen platform)
- [ ] Configure production environment variables
- [ ] Set up monitoring & logging
- [ ] Set up alerts
- [ ] Load test in production
- [ ] User acceptance testing
- [ ] Launch! 

---

## 13. Success Criteria

### Functional
-  Users can register and log in
-  Users can create public/private groups
-  Users can join groups with PIN/invite
-  Users can predict match outcomes before deadline
-  Predictions lock 15 minutes before kickoff
-  Admin can record match results
-  Points calculated automatically (exact/winner/goals)
-  Leaderboards update in real-time
-  Phase bonuses awarded correctly
-  Tie-breaking works as specified

### Non-Functional
-  API response times < 200ms (P95)
-  Frontend loads < 2 seconds
-  90%+ test coverage on Domain layer
-  Zero security vulnerabilities (OWASP audit)
-  Responsive on mobile/tablet/desktop
-  Deployable with single command (Docker Compose)
-  Free tier hosting costs < $10/month

---

## 14. Future Enhancements (Post-MVP)

### Phase 2 Features
- Multiple sports support (basketball, NFL, etc.)
- Real-time match updates via SignalR/WebSockets
- Push notifications (web push)
- Social features (comments, reactions)
- Advanced statistics and charts
- Historical data analysis
- Export data to CSV/Excel

### Phase 3 Features
- Mobile apps (iOS/Android with .NET MAUI)
- AI-powered prediction suggestions
- Integration with sports data APIs
- Real money payments (Stripe/PayPal)
- Referral system
- Premium tiers with advanced features
- Multi-language support

---

## Appendix: Key Business Rules

### Scoring Rules (from arena-vault-rules.md)

1. **Exact Score (5 points)** - EXCLUSIVE
   - If exact score matched, no other points awarded
   - Unique prediction bonus (+5) only applies with exact score

2. **Winner (2 points)** - Only if exact score NOT matched
   - Predict which team wins or if it's a draw

3. **Goals (1 point each)** - Only if exact score NOT matched
   - Home goals correct = 1 point
   - Away goals correct = 1 point
   - Max 2 points per match from goals

4. **Phase Bonuses** - Requires 100% correct predictions in phase
   - Round of 16: +10 points
   - Quarterfinals: +15 points
   - Semifinals: +20 points
   - Final: +30 points

5. **Tie-Breaking Order:**
   1. Champion prediction correct
   2. Most exact scores
   3. Most winners correct
   4. Most goals correct
   5. Most unique predictions
   6. Shared position

---

**Document Status:**  Complete and Ready for Implementation

**Last Updated:** June 14, 2026  
**Version:** 3.0.0

