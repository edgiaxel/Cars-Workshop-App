---
name: Motorsport Engineering Interface
colors:
  surface: '#FFFFFF'
  surface-dim: '#d5dae4'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eef4fe'
  surface-container: '#e9eef8'
  surface-container-high: '#e3e8f3'
  surface-container-highest: '#dde3ed'
  on-surface: '#161c23'
  on-surface-variant: '#5a403d'
  inverse-surface: '#2b3139'
  inverse-on-surface: '#ecf1fb'
  outline: '#8e706c'
  outline-variant: '#e3beb9'
  surface-tint: '#b5251e'
  primary: '#b2221c'
  on-primary: '#ffffff'
  primary-container: '#d53c31'
  on-primary-container: '#fffbff'
  inverse-primary: '#ffb4aa'
  secondary: '#5d5e62'
  on-secondary: '#ffffff'
  secondary-container: '#dfdfe3'
  on-secondary-container: '#616266'
  tertiary: '#585c62'
  on-tertiary: '#ffffff'
  tertiary-container: '#71757b'
  on-tertiary-container: '#fdfcff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdad5'
  primary-fixed-dim: '#ffb4aa'
  on-primary-fixed: '#410001'
  on-primary-fixed-variant: '#920408'
  secondary-fixed: '#e2e2e6'
  secondary-fixed-dim: '#c6c6ca'
  on-secondary-fixed: '#1a1c1f'
  on-secondary-fixed-variant: '#45474a'
  tertiary-fixed: '#e0e2e9'
  tertiary-fixed-dim: '#c3c7cd'
  on-tertiary-fixed: '#181c21'
  on-tertiary-fixed-variant: '#43474c'
  background: '#f8f9ff'
  on-background: '#161c23'
  surface-variant: '#dde3ed'
  surface-elevated: '#ECEEF0'
  background-primary: '#F4F5F6'
  graphite-primary: '#17191C'
  graphite-secondary: '#24282D'
  accent-red: '#E5483B'
  accent-red-hover: '#C9362B'
  border-divider: '#DFE2E5'
  text-primary: '#17191C'
  text-secondary: '#737982'
  text-muted: '#9BA1A8'
  status-success: '#25845A'
  status-warning: '#D28A26'
  status-danger: '#D44343'
  status-info: '#3479B8'
typography:
  display-lg:
    fontFamily: Barlow Condensed
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 52px
    letterSpacing: 0.02em
  display-lg-mobile:
    fontFamily: Barlow Condensed
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: 0.02em
  headline-lg:
    fontFamily: Barlow Condensed
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 36px
    letterSpacing: 0.01em
  headline-md:
    fontFamily: Barlow Condensed
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: 0.01em
  headline-sm:
    fontFamily: Barlow Condensed
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: 0.02em
  title-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-md:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.04em
  technical-data:
    fontFamily: JetBrains Mono
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: -0.01em
  technical-metric:
    fontFamily: Barlow Condensed
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: 0.01em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-desktop: 1.5rem
  margin: 1rem
  margin-desktop: 2rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

# PitMate Design System — Motorsport Engineering Interface

## 1. Visual Language & Principles
- **Theme**: Motorsport Engineering Interface. Precision, technical sophistication, performance-oriented information hierarchy, minimalist industrial aesthetics.
- **Rules (Anti-Slop)**: No generic blue-purple gradients, no glassmorphism or floating shadows, no pill-shaped cards, no random emoji or AI buzzwords. Every element serves an operational purpose.
- **Geometry**: Strict 6-8px border radius for controls/buttons, 10-12px for content surfaces and cards. Subtle 1px borders (`#DFE2E5`), no heavy floating drop shadows. 8px spacing grid.

## 2. Color Tokens (Invariants)
- **Primary Background**: `#F4F5F6`
- **Surface**: `#FFFFFF`
- **Elevated Surface**: `#ECEEF0`
- **Graphite (Primary Dark)**: `#17191C`
- **Graphite Secondary**: `#24282D`
- **Primary Accent**: `#E5483B` (Racing Red - used deliberately for primary actions, active indicators, and critical signals)
- **Accent Hover / Pressed**: `#C9362B`
- **Primary Text**: `#17191C`
- **Secondary Text**: `#737982`
- **Muted Text**: `#9BA1A8`
- **Border / Dividers**: `#DFE2E5`
- **Semantic Success**: `#25845A` (Completed / normal)
- **Semantic Warning**: `#D28A26` (Pending / attention required)
- **Semantic Danger**: `#D44343` (Critical / blocked / error)
- **Semantic Information**: `#3479B8` (Diagnostics / notices)

## 3. Typography
- **Headings & Major Metrics**: `'Barlow Condensed', sans-serif` (condensed, high impact, engineering feel)
- **Interface & Body Text**: `'Inter', sans-serif` (legibility, neutral, clean UI)
- **Technical & Numeric Data**: `'IBM Plex Mono', monospace` (tabular numerals, service IDs, timestamps, VINs, part numbers)

## 4. Application Shell Structure
- Three-role awareness: Admin, Mechanic, Customer.
- Mobile: Top minimal status bar + app bar (with role switcher & notifications) + bottom navigation bar with clear icon & label.
- Responsive Desktop: Left navigation rail/sidebar with compact brand lockup, primary navigation links, user profile, and system telemetry status.
