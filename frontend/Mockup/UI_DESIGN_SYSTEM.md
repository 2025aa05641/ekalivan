# Ekalivan UI Design System

> **Purpose:** This document is the single source of truth for
> implementing the Flutter UI.
>
> **Reference:** Use the attached UI mockup image as the visual target.
> Recreate it as closely as possible. Do **not** redesign or simplify
> it.

------------------------------------------------------------------------

# Design Principles

-   Pixel-perfect recreation of the attached mockup.
-   Do **not** use default Material widgets without customization.
-   Keep the UI premium, child-friendly, modern, and educational.
-   Preserve the existing Flutter Clean Architecture and backend.

------------------------------------------------------------------------

# Overall Style

-   Premium educational application
-   Rounded cards
-   Soft shadows
-   Large whitespace
-   Blue gradient headers
-   Purple call-to-action buttons
-   Minimal borders
-   Clean hierarchy

------------------------------------------------------------------------

# Color Palette

  Name             Hex
  ---------------- -----------
  Primary Blue     `#0D3B73`
  Secondary Blue   `#144A92`
  Primary Purple   `#7E3FF2`
  Accent Purple    `#A855F7`
  Background       `#F6F8FC`
  Card             `#FFFFFF`
  Border           `#E9EEF5`
  Success          `#31C46C`
  Warning          `#F4B942`
  Danger           `#F25B5B`

------------------------------------------------------------------------

# Typography

-   Font: **Poppins**
-   Fallback: **Inter**

  Style     Weight
  --------- --------
  Heading   700
  Title     600
  Body      400
  Button    600

Never use Roboto.

------------------------------------------------------------------------

# Corner Radius

-   Buttons: 16
-   Cards: 18
-   Dialogs: 22
-   Bottom Sheets: 28
-   Text Fields: 14

------------------------------------------------------------------------

# Shadows

Very soft.

-   Blur: 20
-   Opacity: 8%
-   Y Offset: 8

Avoid harsh Material shadows.

------------------------------------------------------------------------

# Buttons

Primary

-   Blue/Purple gradient
-   Height: 52
-   Radius: 16

Secondary

-   White background
-   Blue outline

Icon Buttons

-   Circular
-   48x48

------------------------------------------------------------------------

# Cards

-   White background
-   Soft shadow
-   Radius: 18
-   Padding: 16
-   Gap: 16

------------------------------------------------------------------------

# Icons

-   Material Symbols Rounded
-   Rounded style
-   Blue outlined icons

------------------------------------------------------------------------

# Navigation

Bottom Navigation

-   Floating appearance
-   White background
-   Rounded top corners
-   Blue active icon
-   Gray inactive icon

------------------------------------------------------------------------

# Admin Portal

Include:

-   Login screen
-   Dashboard
-   Metrics cards
-   Upload book screen
-   AI pipeline progress
-   Rendering screen
-   Completion screen

Pipeline:

1.  Lesson Planner
2.  Teacher
3.  Storyboard
4.  Narration (TTS)
5.  Video Rendering
6.  Publishing
7.  Quality Check
8.  Final Publish

Completed = Green

Current = Blue

Pending = Gray

------------------------------------------------------------------------

# Student Portal

Include:

-   Splash/Home
-   Medium selection
-   Grade selection
-   Subject selection
-   Chapter list
-   Video player
-   Topic accordion

Use:

-   Large illustrations
-   Rounded chapter cards
-   16:9 video player
-   Bottom navigation

------------------------------------------------------------------------

# Flutter Implementation

Use

-   Material 3
-   Riverpod
-   GoRouter
-   ThemeExtension

Create reusable widgets:

-   AppScaffold
-   GradientHeader
-   PrimaryButton
-   SecondaryButton
-   RoundedInput
-   DashboardCard
-   MetricCard
-   ChapterCard
-   VideoCard
-   PipelineStep
-   StatusChip
-   BottomNav

Create constants for:

-   Colors
-   Typography
-   Spacing
-   Border Radius
-   Shadows
-   Gradients

Do not hardcode styling.

------------------------------------------------------------------------

# Implementation Rules

-   Treat the attached mockup as a Figma export.
-   Recreate every spacing, radius, shadow, alignment, and hierarchy.
-   Do not invent layouts.
-   Do not simplify components.
-   Use animations for card appearance, button presses, and progress
    updates.
-   Do not modify backend or business logic.
-   Only enhance the presentation layer.

## Final Requirement

The attached mockup image is the visual truth.

If implementation differs from the mockup, **the mockup wins**.
