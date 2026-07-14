# EKALIVAN UI MODERNIZATION ROADMAP

> Purpose: Transform the existing Flutter application into the approved
> Ekalivan UI while preserving the current Clean Architecture.

## Vision

The platform has two user personas:

### Creator (Admin Portal)

-   Upload textbook PDF
-   Configure medium/class/subject
-   Trigger AI pipeline
-   Monitor pipeline
-   Preview generated video
-   Publish lesson

### Student (Learning Portal)

-   Select medium
-   Select class
-   Select subject
-   Browse chapters
-   Watch published lessons

## Ground Rules

-   Preserve Clean Architecture
-   Preserve Riverpod
-   Preserve GoRouter
-   Preserve Repository Pattern
-   Preserve backend architecture
-   Do NOT rewrite working code
-   Implement phase by phase
-   Ensure the project builds after every phase

## Phase 1

Design system: - Theme - Typography - Colors - Buttons - Cards -
AppBar - Bottom navigation - Shared spacing

## Phase 2

Branding: - Rename app to Ekalivan - App icon - Splash - Logo - Tagline:
கற்போம் • கேட்போம் • பார்ப்போம் • பழகுவோம்

## Phase 3

Creator Portal UI: - Login - Dashboard - Upload Book - Pipeline
Progress - Rendering Progress - Publish Complete

UI only.

## Phase 4

Creator Backend Integration: - Upload PDF - Start generation - Poll
status - Preview video - Publish

Reuse existing backend.

## Phase 5

Student Portal UI: - Splash - Medium - Class - Subject - Chapter - Video
Player

Placeholder data only.

## Phase 6

Student Backend Integration: Replace placeholders with APIs.

## Phase 7

AI Pipeline Visualization: 1. Lesson Planner 2. Teacher 3. Storyboard 4.
Narration 5. Video Rendering 6. Publishing 7. Quality Check 8. Final
Publish

## Phase 8

Hackathon Demo Flow: Creator uploads Grade 6 Science PDF → AI pipeline →
Preview → Publish → Student opens app → English/Tamil → Grade 6 →
Science → Chapter 1 → Watch lesson.

## Scope

Real implementation only for: - English Medium - Tamil Medium - Grade
6 - Science - Chapter 1 (The World of Plants)

Everything else may remain placeholder UI.

## Instructions for Claude

The attached UI mockup is the design target. Implement one phase at a
time. Stop after each phase and wait for approval. Keep the project
compiling after every phase.
