---
name: PitMate Telemetry Core
colors:
  surface: '#0f1419'
  surface-dim: '#0f1419'
  surface-bright: '#353a3f'
  surface-container-lowest: '#0a0f13'
  surface-container-low: '#171c21'
  surface-container: '#1b2025'
  surface-container-high: '#252a30'
  surface-container-highest: '#30353b'
  on-surface: '#dee3ea'
  on-surface-variant: '#e1bfba'
  inverse-surface: '#dee3ea'
  inverse-on-surface: '#2c3136'
  outline: '#a88a86'
  outline-variant: '#59413e'
  surface-tint: '#ffb4ab'
  primary: '#ffb4ab'
  on-primary: '#690005'
  primary-container: '#f65e53'
  on-primary-container: '#5c0004'
  inverse-primary: '#b12c27'
  secondary: '#bfc7d1'
  on-secondary: '#293138'
  secondary-container: '#424a52'
  on-secondary-container: '#b1b9c2'
  tertiary: '#77daa8'
  on-tertiary: '#003823'
  tertiary-container: '#3da275'
  on-tertiary-container: '#00311e'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffdad6'
  primary-fixed-dim: '#ffb4ab'
  on-primary-fixed: '#410002'
  on-primary-fixed-variant: '#8e1112'
  secondary-fixed: '#dbe3ed'
  secondary-fixed-dim: '#bfc7d1'
  on-secondary-fixed: '#151c23'
  on-secondary-fixed-variant: '#40484f'
  tertiary-fixed: '#93f6c3'
  tertiary-fixed-dim: '#77daa8'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005235'
  background: '#0f1419'
  on-background: '#dee3ea'
  surface-variant: '#30353b'
typography:
  display-lg:
    fontFamily: Barlow Condensed
    fontSize: 44px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: 0.5px
  display-lg-mobile:
    fontFamily: Barlow Condensed
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: 0.5px
  headline-xl:
    fontFamily: Barlow Condensed
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 36px
    letterSpacing: 0.25px
  headline-xl-mobile:
    fontFamily: Barlow Condensed
    fontSize: 26px
    fontWeight: '600'
    lineHeight: 30px
    letterSpacing: 0.25px
  headline-lg:
    fontFamily: Barlow Condensed
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: 0.25px
  headline-md:
    fontFamily: Barlow Condensed
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: 0.2px
  headline-sm:
    fontFamily: Barlow Condensed
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.15px
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
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 18px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.4px
  code-lg:
    fontFamily: JetBrains Mono
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 22px
  code-md:
    fontFamily: JetBrains Mono
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 18px
  code-sm:
    fontFamily: JetBrains Mono
    fontSize: 11px
    fontWeight: '400'
    lineHeight: 14px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-sm: 0.5rem
  gutter-lg: 1.5rem
  margin: 1.5rem
  margin-mobile: 1rem
  margin-desktop: 2rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

The design system establishes a high-performance, dark-mode engineering console designed for automotive workshop management, pit technicians, and master mechanics. It combines the rigorous ergonomics of motorsport trackside telemetry with the disciplined workflows of modern repair facilities. The target audience operates in variable shop-floor lighting conditions—frequently switching between diagnostic scanners, tablet mounts, and overhead bay monitors.

### Aesthetic Foundation
- **Discipline & Precision:** The interface uses an engineered utilitarian aesthetic. No decorative neon glows, no synthetic dropshadow blurs, and no pitch-black surfaces.
- **Surface Layering:** Tone-on-tone charcoal and slate foundations create perceived depth and clear data grouping while reducing ocular fatigue over long shifts.
- **Functional Accentuation:** The crimson primary accent (`#F05A4F`) is strictly reserved for actionable signals, critical mechanical states, priority work orders, and interactive commitments.
- **Industrial Compactness:** Visual density is prioritized over vast decorative whitespace. Data density is achieved through structural hairline dividers, condensed metric typography, and monospaced diagnostic strings.

## Colors

The palette operates in strict dark mode, deliberately omitting absolute black (`#000000`) in favor of calibrated deep carbon tones. This prevents halation and enhances border clarity under harsh shop-floor lighting.

### Base Surfaces & Structure
- **Background (`#111417`):** The primary application canvas. Used behind all modular bay panels and master lists.
- **Surface (`#191E23`):** Default card background, table frames, and navigation sidebars.
- **Elevated Surface (`#242B32`):** Interactive inputs, nested cards, table hover rows, and dropdown menus.
- **Secondary Elevated Surface (`#2B333B`):** Modal dialogs, active pill containers, and highlighted status badges.
- **Default Border (`#343C44`):** 1px structural boundaries defining modular metric blocks.
- **Strong Border (`#46515B`):** Focus rings, active partition rules, and elevated card perimeters.

### Typography & Content Contrast
- **Primary Text (`#F1F3F5`):** Metric values, primary headers, active plate identifiers, and main data cells.
- **Secondary Text (`#A5ADB6`):** Field labels, standard table descriptions, technician names, and secondary metadata.
- **Muted Text (`#7D8791`):** Inactive timestamps, measurement units (`Nm`, `PSI`, `km/h`), and disabled states.
- **Inverted Text (`#17191C`):** Used inside high-contrast solid chips and bright status badges.
- **Graphite / High Contrast (`#E8EAED`):** Key readouts, warning headers, and prominent vehicle VIN displays.

### Accents & Telemetry States
- **Primary Accent (`#F05A4F`):** Motorsport red. Indicates primary buttons, active service selections, and immediate actions.
- **Accent Hover (`#FF7166`):** High-response state for crimson action items.
- **Status Success (`#55B889`):** Diagnostic pass, completed bay work, green tire tread threshold, paid invoice.
- **Status Warning (`#E6B45A`):** Immediate attention required, fluids low, torque calibration pending.
- **Status Danger (`#F07171`):** Critical mechanical failure, overdue safety inspection, red alert.
- **Status Info (`#72A9DE`):** Telemetry ping, parts ordered, queue pending, staging notice.

## Typography

Typography acts as a dynamic telemetry scale. Three typefaces work in synchronization:

1. **Barlow Condensed:** Used exclusively for high-impact module titles, bay identifiers, vehicle model headings, and live numerical readouts (e.g., speed, torque, compression ratio, invoice totals). Its compact vertical proportions allow high numerical density without visual clutter.
2. **Inter:** Used for all continuous system prose, form labels, parameter descriptors, and conversational repair notes. Inter preserves legibility at small sizes (`11px`–`14px`) during active handheld tablet operation.
3. **JetBrains Mono:** Dedicated to automotive data points: Vehicle Identification Numbers (VIN), license plate tags, OBD-II error codes (`P0300`, `C1201`), hardware serial numbers, and millisecond-accurate timestamps. Monospaced widths ensure numerical values align vertically in multi-column audit logs.

### Typographic Rules
- Always render units of measurement (`PSI`, `bar`, `Nm`, `deg`, `hrs`) in `label-sm` or `code-sm` using `Muted Text` directly adjacent to high-contrast numeric values.
- Capitalize OBD-II codes, license plates, and hex registers in `code-md` or `code-sm`.
- Table numeric columns must use `tabular-nums` formatting to prevent baseline shifting during real-time telemetry streaming.

## Layout & Spacing

The layout is structured around an industrial modular rack concept, providing continuous situational awareness without requiring deep page nesting.

### Grid Structure
- **Desktop (1200px+):** 12-column layout with fixed 16px (`gutter`) spacing and 32px (`margin-desktop`) canvas padding. Panels conform strictly to modular spans: 3 cols (service roster / vehicle summary), 6 cols (live bay status / OBD log), and 3 cols (telemetry graphs / billable items).
- **Tablet / Mounted Bay Display (768px - 1199px):** 8-column layout with 16px margins and 12px gutters. Sidebars fold into an icon rail, and multi-bay consoles stack into dual-column diagnostic blocks.
- **Mobile Handheld (320px - 767px):** Single-column layout with 12px gutters and 16px margins. Metric summaries compress into horizontally swipeable cards.

### Spacing Philosophy
- Maintain a compact baseline rhythm: `space-xs` (4px) for pairing related metadata like an OBD code to its severity badge; `space-sm` (8px) for input padding and component inner gaps; `space-md` (16px) for card body padding; and `space-lg` (24px) for distinct module separations.
- Density is king: interfaces should present all critical bay telemetry above the fold whenever possible, minimizing excessive scroll travel on workshop touchscreens.

## Elevation & Depth

This design system avoids soft ambient shadows, colored neon blooms, and heavy blurs. Depth is achieved purely through calibrated tone stepping and high-precision hairline borders.

### Surface Tiers
- **Level 0 (Canvas):** `#111417` – System floor, static workbench background.
- **Level 1 (Card & Module Foundation):** `#191E23` bordered with 1px `#343C44`. Houses bay telemetry, invoice rows, and inspection checklists.
- **Level 2 (Interactive Modules & Table Headers):** `#242B32` bordered with 1px `#343C44`. Applied to form inputs, search filters, secondary action bars, and collapsed diagnostic trays.
- **Level 3 (Overlays, Modals, & Flyout Tooltips):** `#2B333B` bordered with 1px `#46515B`. Used for active repair order dialogs, diagnostic drill-downs, and popover notifications.

### Structural Outlines
- All surfaces use a crisp 1px stroke. The transition between active and resting states relies on border brightening: hovering over a Level 1 container shifts its border from `#343C44` to `#46515B`.
- Focused interactive components use a 1px border colored with `#F05A4F` without any outer glow.

## Shapes

The interface embraces a functional, mechanical geometry. Roundedness level 1 establishes micro-radii that feel machined, sturdy, and robust:

- **Base Elements (`rounded` = 4px / 0.25rem):** Standard buttons, text inputs, metric chips, diagnostic badges, and table cell containers.
- **Containers (`rounded-lg` = 8px / 0.5rem):** Workshop bay cards, live line-charts, customer vehicle profile modules, and modal dialogs.
- **Outer Shells (`rounded-xl` = 12px / 0.75rem):** Full-screen overlays and floating quick-action docks.

Circular or pill geometries are banned for interactive controls. Tags and status markers maintain crisp 4px corners to echo mechanical equipment bezels.

## Components

### Buttons & Action Triggers
- **Primary Action:** Solid `#F05A4F` background with `#F1F3F5` text, 4px corner radius, bold condensed text. Hover transitions directly to `#FF7166`. Active state shifts down 1px with no drop shadow.
- **Secondary / Technical Action:** Background `#242B32`, 1px border in `#343C44`, text `#F1F3F5`. Hover elevates background to `#2B333B` with border `#46515B`.
- **Destructive Action:** Ghost or subtle `#242B32` background with 1px border in `#F07171` and text `#F07171`. Hover transitions to solid `#F07171` with `#17191C` inverted text.
- **Dimensions:** Form inputs and action buttons maintain a standardized 36px height for standard desktop views and scale to 44px on mobile/tablet viewports to ensure glove-friendly touch targets.

### Inputs & Diagnostic Selectors
- **Input Fields:** Background `#242B32`, 1px border `#343C44`, inner text `#F1F3F5`, placeholder text `#7D8791`. Focused state switches the border to `#F05A4F` immediately.
- **Search & Filter Bars:** JetBrains Mono font support for direct VIN entry or stock SKU lookup. Include integrated clear (`x`) trigger and left-aligned telemetry icon in `#A5ADB6`.

### Chips & Telemetry Badges
- **Status Indicators:** 20px fixed height, 4px radius, uppercase `label-sm` font.
  - *Pass/Clear:* `#55B889` background at 15% opacity, border 1px solid `#55B889`, text `#55B889`.
  - *Warning/Advisory:* `#E6B45A` background at 15% opacity, border 1px solid `#E6B45A`, text `#E6B45A`.
  - *Critical/Fault:* `#F07171` background at 15% opacity, border 1px solid `#F07171`, text `#F07171`.
  - *Info/Queued:* `#72A9DE` background at 15% opacity, border 1px solid `#72A9DE`, text `#72A9DE`.
- **License Plate Badge:** Custom high-contrast container with `#E8EAED` background, `#17191C` monospaced bold text, and 2px solid `#343C44` border.

### Telemetry Cards & Bay Panels
- **Structure:** Surface `#191E23`, border 1px `#343C44`, radius 8px (`rounded-lg`).
- **Header:** Divided by a hairline 1px `#343C44` separator. Features bay numbers (`BAY 04 - HOIST`) in `headline-sm` using Barlow Condensed, accompanied by a real-time status pill on the right.
- **Body:** Arranged with compact internal padding (`space-md` / 16px). Metrics display paired groups: a muted uppercase label on top (`space-xs`) followed by a large numeric readout in Barlow Condensed.

### Tables & Data Grids
- **Header Row:** Background `#242B32`, text `#A5ADB6`, uppercase `label-sm`, letter-spaced, bottom border 1px `#46515B`.
- **Data Rows:** Background `#191E23`, bottom border 1px `#343C44`, text `#F1F3F5`. Alternating zebra striping is omitted; instead, active row hover shifts the entire row background to `#242B32`.
- **Numeric & Code Cells:** Formatted in JetBrains Mono with tabular alignment.

### Checkboxes, Radios, & Switches
- **Checkboxes & Radios:** Unchecked state has a `#242B32` background and 1px `#46515B` border. Checked state uses solid `#F05A4F` with `#F1F3F5` check mark. Radius is 2px for checkboxes and 50% for radios.
- **Toggles / Bay Switches:** Rectangular 40x22px track in `#242B32` with 1px `#343C44` border. Active state flips track to `#F05A4F`. The toggle thumb is a sharp 16x16px square block (`rounded: 2px`) sliding horizontally.