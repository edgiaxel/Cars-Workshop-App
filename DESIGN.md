# Pitstop Garage — Design System

## 1. Purpose

This document defines the visual design system and UI/UX direction for **Pitstop Garage**, the Cars Workshop App.

The design is intentionally inspired by the visual language of **endurance racing and FIA WEC-style timing, telemetry, pit-wall, and race-control graphics**:

- Strong information hierarchy
- Bold numerical information
- Compact status indicators
- Modular panels
- Technical labels and metadata
- High-contrast interfaces
- Racing-inspired blue and accent colors
- Structured grids and alignment
- Visual emphasis on status, progress, and activity

The application should feel like a **modern professional workshop control system with motorsport DNA**, rather than a generic CRUD administration application.

The visual direction must remain practical. Racing-inspired graphics are used to improve hierarchy and identity, not to make the application visually complicated.

The design is **mobile-first**. Desktop layouts may exist later, but the primary design target is a smartphone.

---

# 2. Design Goals

Pitstop Garage should communicate five things immediately:

1. **What is happening**
2. **What needs attention**
3. **What status something is in**
4. **What action the user can take**
5. **Who or what the information belongs to**

The design should feel:

- Technical
- Modern
- Fast
- Professional
- Organized
- Slightly aggressive
- Motorsport-inspired
- Easy to scan
- Easy to navigate with one hand

The design should avoid becoming:

- Overly decorative
- Difficult to read
- Excessively dark
- Full of unnecessary animations
- Dependent on racing knowledge
- Visually similar to a literal race-management application

---

# 3. Core Design Principles

## 3.1 Mobile First

All major screens are designed for smartphones first.

Primary target width:

- 360 px: minimum supported layout target
- 390 px: primary design reference
- 430 px: larger-phone reference

The UI must remain usable without requiring:

- Horizontal scrolling
- Desktop-style multi-column tables
- Tiny controls
- Hover interactions
- Precision mouse input

Desktop layouts may expand later, but the mobile layout is the source of truth.

---

## 3.2 Information Before Decoration

Visual elements inspired by motorsport must support information hierarchy.

A racing stripe, technical label, grid pattern, or telemetry-style element should only exist when it reinforces the interface.

Do not add decorative graphics simply because they look cool.

The application should always prioritize:

**Status → Important information → Action → Secondary information → Decoration**

---

## 3.3 Strong Visual Hierarchy

Important information should be visually obvious.

Examples:

- Service order status should be more prominent than its creation timestamp.
- Vehicle identity should be more prominent than optional notes.
- Final cost should be more prominent than individual cost components.
- Low stock should be visually obvious in inventory.
- A mechanic's current assigned workload should be immediately visible.

Use:

- Size
- Weight
- Contrast
- Spacing
- Position
- Accent colors

to create hierarchy.

---

## 3.4 Modular Panels

The interface should use modular cards and panels inspired by racing timing screens.

Typical structure:

```text
┌───────────────────────────┐
│ SERVICE ORDER             │
│ SO-00024                  │
│                           │
│ BMW M4                    │
│ B 1234 XYZ                │
│                           │
│ ● IN PROGRESS             │
│                           │
│ [ View Service ]          │
└───────────────────────────┘
```

Cards should contain one clear information group.

Avoid placing unrelated information into one large card.

---

# 4. Visual Direction

## 4.1 Motorsport Influence

The visual language may borrow concepts commonly seen in endurance-racing interfaces:

- Timing-board layouts
- Sector-like information blocks
- Technical metadata
- Lap/timing-inspired typography
- Progress bars
- Status lights
- Compact labels
- Large numeric values
- Grid-based layouts
- Diagonal accent shapes
- Thin technical lines
- Monospaced secondary information

These elements should be adapted into workshop terminology.

Examples:

```text
SERVICE STATUS
IN PROGRESS

VEHICLE
BMW M4

MECHANIC
Hamilton

TASK PROGRESS
████████░░ 80%
```

---

## 4.2 Racing-Inspired, Not Racing-Literal

Pitstop Garage must not look like an official FIA WEC application.

Do not use:

- Official FIA logos
- Official WEC logos
- FIA/WEC branding
- Team logos
- Driver photographs as primary UI decoration
- Official race graphics
- Unnecessary imitation of broadcast overlays

The inspiration comes from the **design language of professional motorsport**, not from reproducing an existing organization's branding.

---

# 5. Color System

The primary palette is blue-based with colorful accents.

The interface should normally use a neutral/light surface with strong blue elements.

## 5.1 Primary Colors

| Token | Purpose | Suggested Value |
|---|---|---|
| `primary900` | Deep navigation/header color | `#071A33` |
| `primary800` | Deep blue | `#0B2A50` |
| `primary700` | Main brand blue | `#0D47A1` |
| `primary600` | Primary action blue | `#1565C0` |
| `primary500` | Bright blue | `#1976D2` |
| `primary400` | Accent blue | `#42A5F5` |
| `primary300` | Light blue accent | `#90CAF9` |

The most important brand colors should remain in the **blue family**.

---

## 5.2 Accent Colors

Accent colors provide visual differentiation without replacing the primary blue identity.

| Token | Purpose | Suggested Value |
|---|---|---|
| `accentCyan` | Technical/data highlight | `#00BCD4` |
| `accentLime` | Positive/progress accent | `#8BC34A` |
| `accentYellow` | Attention/warning | `#FFC107` |
| `accentOrange` | High-priority warning | `#FF9800` |
| `accentRed` | Error/urgent/danger | `#F44336` |
| `accentPurple` | Secondary category accent | `#7E57C2` |

Accent colors must have semantic meaning wherever possible.

Do not randomly change colors between screens.

---

## 5.3 Neutral Colors

| Token | Purpose | Suggested Value |
|---|---|---|
| `background` | Application background | `#F4F7FB` |
| `surface` | Cards and panels | `#FFFFFF` |
| `surfaceAlt` | Secondary panel | `#EAF0F7` |
| `border` | Dividers and outlines | `#D8E0EA` |
| `textPrimary` | Main text | `#101828` |
| `textSecondary` | Secondary text | `#526173` |
| `textMuted` | Metadata | `#7B8794` |
| `textOnDark` | Text on dark surfaces | `#FFFFFF` |

---

# 6. Semantic Status Colors

Status colors must be consistent throughout the entire application.

## Service Order

| Status | Visual Treatment |
|---|---|
| `REQUESTED` | Blue |
| `INSPECTION` | Cyan |
| `DIAGNOSIS` | Purple |
| `WAITING_PARTS` | Yellow |
| `IN_PROGRESS` | Bright Blue |
| `QUALITY_CHECK` | Orange |
| `COMPLETED` | Green |
| `CANCELLED` | Red |

Status should normally appear as:

- A colored badge
- A small status indicator
- Text label

Color alone must never be the only way the status is communicated.

Example:

```text
● IN PROGRESS
```

rather than only displaying a blue circle.

---

# 7. Typography

Typography should feel technical and modern while remaining highly readable.

## 7.1 Primary UI Typeface

Recommended primary typeface:

**Inter**

Use it for:

- Body text
- Forms
- Navigation
- Buttons
- Labels
- Tables
- Descriptions
- General application text

A suitable system sans-serif equivalent may be used when necessary.

---

## 7.2 Display Typeface

A condensed or technical display typeface may be used sparingly for:

- Dashboard numbers
- Large statistics
- Section headings
- Racing-inspired labels

Recommended direction:

- Space Grotesk
- Roboto Condensed
- Another modern condensed sans-serif

The display typeface must not be used for long paragraphs.

---

## 7.3 Typography Hierarchy

Suggested hierarchy:

```text
Display       28–32 px / Bold
Headline      22–26 px / Bold
Title         18–20 px / Semibold
Body          14–16 px / Regular
Label         11–13 px / Semibold
Technical     10–12 px / Medium
```

Important numbers may use heavier weights than surrounding text.

Example:

```text
ACTIVE ORDERS

12
```

The `12` should dominate the visual hierarchy.

---

# 8. Spacing System

Use a consistent spacing system based primarily on multiples of 4.

Base spacing:

```text
4
8
12
16
20
24
32
40
48
```

Recommended defaults:

- Screen horizontal padding: `16 px`
- Card padding: `16 px`
- Small internal spacing: `8 px`
- Standard component gap: `12–16 px`
- Section spacing: `24–32 px`
- Major screen separation: `32 px`

Avoid arbitrary spacing values unless necessary.

---

# 9. Corners, Borders, and Surfaces

The design should feel modern and technical rather than overly rounded.

Recommended corner radius:

- Small controls: `8 px`
- Standard cards: `12 px`
- Large panels: `16 px`
- Bottom sheets/dialogs: `16–20 px`

Avoid excessive pill-shaped containers.

Pills should mainly be used for:

- Status badges
- Filter chips
- Compact categories
- Small tags

Cards should generally use:

- Light border
- Minimal shadow
- Strong spacing

Avoid large floating shadows.

---

# 10. Racing Graphic Language

Several graphic motifs may appear across the application.

## 10.1 Technical Labels

Small uppercase labels may be used above important data.

Example:

```text
SERVICE ORDER
SO-00024
```

and:

```text
CURRENT STATUS
IN PROGRESS
```

This creates a technical pit-wall feel.

---

## 10.2 Data Strips

Compact data rows can resemble timing-board information.

Example:

```text
VEHICLE        BMW M4
MECHANIC       HAMILTON
PRIORITY       HIGH
PROGRESS       75%
```

Use alignment to make information easy to scan.

---

## 10.3 Diagonal Accent Shapes

Small diagonal bars or stripes may be used in:

- Dashboard headers
- Empty-state graphics
- Section headers
- Background decorations

They should remain subtle.

Example:

```text
████
  ████
    ████
```

Do not cover large areas of the screen with decorative stripes.

---

## 10.4 Grid Motifs

Subtle technical grids may be used behind:

- Dashboard headers
- Summary sections
- Empty states

Grid opacity must remain low enough that it never interferes with text.

---

# 11. Navigation

The application uses **mobile navigation first**.

## 11.1 Bottom Navigation

Primary role-based destinations should use a bottom navigation bar when appropriate.

Example customer navigation:

```text
┌───────────────────────────────────┐
│ Home   Vehicles   Orders   History│
└───────────────────────────────────┘
```

Example mechanic navigation:

```text
┌───────────────────────────────────┐
│ Home   Orders   Tasks   Profile   │
└───────────────────────────────────┘
```

Example admin navigation may prioritize:

```text
Home
Orders
Customers
Inventory
More
```

Secondary destinations should be placed inside:

- "More"
- Context menus
- Detail screens
- Section navigation

Do not attempt to place every route into the bottom navigation bar.

---

## 11.2 Navigation Rules

Navigation should always make the current location obvious.

Recommended:

- Active navigation item uses primary blue
- Inactive items use muted neutral color
- Active icon may use filled style
- Navigation labels should remain visible
- Avoid icon-only navigation for primary destinations

---

# 12. Top App Bar

The top app bar should provide:

- Page title
- Optional subtitle
- Back navigation where appropriate
- Relevant action
- Profile/avatar access where appropriate

Example:

```text
←  SERVICE ORDER
    SO-00024
                           ⋮
```

For dashboard screens:

```text
GOOD MORNING
PITSTOP GARAGE

12 ACTIVE ORDERS
```

Avoid excessively tall headers.

---

# 13. Buttons

Buttons should be immediately recognizable.

## Primary Button

Used for the most important action.

Examples:

- Create Service Order
- Start Inspection
- Start Task
- Complete Service Order

Style:

- Primary blue background
- White text
- Medium/heavy text weight
- 44–52 px minimum height

---

## Secondary Button

Used for supporting actions.

Examples:

- Edit
- View Details
- Assign Mechanic

Style:

- Light surface or transparent background
- Blue text
- Border when necessary

---

## Destructive Button

Used for:

- Cancellation
- Deactivation
- Destructive administration actions

Use red only for genuinely destructive actions.

Do not make ordinary actions red.

---

# 14. Forms

Forms must be optimized for touch interaction.

Recommended minimum control height:

**44 px**

Preferred:

**48–52 px**

Inputs should provide:

- Clear label
- Optional helper text
- Validation message
- Visible focus state
- Appropriate keyboard type
- Clear required/optional indication

Example:

```text
VEHICLE BRAND *
┌─────────────────────────────┐
│ BMW                         │
└─────────────────────────────┘

MODEL *
┌─────────────────────────────┐
│ M4                          │
└─────────────────────────────┘
```

Avoid relying solely on placeholder text as the field label.

---

# 15. Service Order UI

Service orders are the central workflow of the application.

The UI must make these items immediately visible:

1. Service order identifier
2. Vehicle
3. Customer
4. Current status
5. Assigned mechanic
6. Priority
7. Task progress
8. Estimated/final cost
9. Available actions

Example mobile card:

```text
SERVICE ORDER
SO-00024

BMW M4
B 1234 XYZ

● IN PROGRESS        HIGH

MECHANIC
Hamilton

TASK PROGRESS
████████░░ 80%

Rp 4.250.000

[ VIEW DETAILS ]
```

The interface should prioritize current operational information before historical metadata.

---

# 16. Task UI

Tasks should visually communicate progress.

Example:

```text
TASK PROGRESS

4 / 5 COMPLETED

████████████████░░░░ 80%
```

Individual tasks:

```text
✓ Brake inspection
✓ Oil replacement
✓ Wheel alignment
◉ Engine diagnostics
○ Final road test
```

Task states should be recognizable through:

- Icon
- Text
- Status color
- Optional progress treatment

Do not rely on color alone.

---

# 17. Inventory UI

Inventory should feel more like an operational control screen than a traditional product catalog.

Example:

```text
BRAKE PAD FRONT
BP-BMW-M4-01

STOCK
4

MINIMUM
5

⚠ LOW STOCK

Rp 1.250.000
```

Low-stock items should receive clear visual emphasis.

Recommended hierarchy:

```text
Part Name
Part Number
Stock
Status
Price
```

Search and filtering should be prominent because inventory may grow significantly.

Useful filters:

- All
- Low Stock
- Active
- Inactive
- Category

---

# 18. Dashboard Design

Dashboards should function as **operational summaries**, not decorative analytics pages.

## Admin Dashboard

Primary information:

```text
ACTIVE ORDERS
12

WAITING PARTS
3

IN PROGRESS
7

LOW STOCK
5
```

Then:

- Recent service orders
- Orders requiring attention
- Low-stock parts
- Recent activity

---

## Mechanic Dashboard

Primary information:

```text
MY ACTIVE ORDERS
3

MY TASKS
8

COMPLETED TODAY
4
```

Then:

- Assigned service orders
- Current tasks
- Vehicles being serviced

---

## Customer Dashboard

Primary information:

```text
MY VEHICLES
2

ACTIVE SERVICES
1

SERVICE HISTORY
8
```

Then:

- Current service order
- Current vehicle status
- Recent history

---

# 19. Vehicle UI

Vehicle identity should be highly visible.

Example:

```text
BMW M4
B 1234 XYZ

2023
PASSENGER

82,450 km
```

Optional secondary metadata:

- Customer
- VIN or internal identifier if added later
- Notes
- Service history

Vehicle cards may use a subtle automotive graphic treatment, but photographs are not required.

---

# 20. Customer and Mechanic UI

People should be represented with clear identity blocks.

Example:

```text
HAMILTON

Mechanic
Brake & Engine Specialist

ACTIVE
```

For customers:

```text
CUSTOMER
Acme Motorsport

COMPANY
3 VEHICLES
5 SERVICE ORDERS
```

Use avatars optionally.

Do not make profile photographs a requirement for the design.

---

# 21. Status Badges

Status badges should use:

**Icon + Text + Semantic Color**

Example:

```text
● COMPLETED
```

rather than:

```text
[ GREEN ]
```

Recommended badge structure:

```text
┌───────────────────┐
│ ● IN PROGRESS     │
└───────────────────┘
```

Badges should remain compact.

---

# 22. Tables and Large Data Sets

Traditional desktop tables should not be used as the primary mobile interaction model.

Instead, transform rows into cards or compact list items.

Desktop-style:

```text
ID | Vehicle | Customer | Mechanic | Status
```

Mobile:

```text
SO-00024
BMW M4
Acme Motorsport

Hamilton
● IN PROGRESS

[ View ]
```

When a large data set is unavoidable:

- Use search
- Use filters
- Use sorting
- Use pagination or lazy loading
- Keep the primary fields visible
- Move secondary fields into the detail screen

---

# 23. Empty States

Empty states should be informative rather than blank.

Example:

```text
NO ACTIVE SERVICE ORDERS

Everything is clear in the workshop.

[ CREATE SERVICE ORDER ]
```

Empty states may use subtle technical/racing graphics.

Do not use giant decorative illustrations that consume most of the phone screen.

---

# 24. Loading States

Loading states should preserve the final layout as much as possible.

Use:

- Skeleton cards
- Placeholder rows
- Progress indicators
- Shimmer only when useful

Avoid blocking the entire application with a generic full-screen spinner for every operation.

---

# 25. Error States

Errors should explain:

1. What happened
2. What the user can do

Example:

```text
UNABLE TO LOAD SERVICE ORDERS

The service data could not be retrieved.

[ TRY AGAIN ]
```

Technical error messages should not be exposed directly to normal users.

Developer/debug information may be logged separately.

---

# 26. Confirmation Dialogs

Confirmation should be required for destructive or irreversible operations.

Examples:

- Cancel service order
- Deactivate customer
- Deactivate mechanic
- Deactivate part

Example:

```text
CANCEL SERVICE ORDER?

SO-00024 will be marked as cancelled.

[ KEEP ORDER ]   [ CANCEL ]
```

The destructive action should be clearly identifiable.

---

# 27. Touch and Accessibility

The interface must remain comfortable for touch interaction.

Minimum interactive target:

**44 × 44 px**

Preferred:

**48 × 48 px or larger**

Accessibility requirements:

- Do not rely on color alone
- Maintain readable contrast
- Use clear labels
- Provide meaningful icons
- Avoid extremely small text
- Avoid crowded controls
- Support system text scaling where practical

A colorful interface must remain usable for users with color-vision differences.

---

# 28. Icons

Icons should use one consistent icon family.

Icons should communicate meaning rather than act as decoration.

Examples:

- Dashboard → dashboard/home icon
- Vehicles → car icon
- Service Orders → clipboard/service icon
- Tasks → checklist icon
- Inventory → package/warehouse icon
- Reports → chart icon
- Profile → person icon

Do not mix unrelated icon styles.

Text labels should accompany important navigation icons.

---

# 29. Motion and Animation

Animation should reinforce status and interaction.

Appropriate uses:

- Screen transitions
- Progress updates
- Expanding cards
- Success confirmation
- Loading states
- Status changes

Optional racing-inspired effects:

- Small progress sweeps
- Subtle slide transitions
- Short status indicator animations

Avoid:

- Constant moving decorations
- Excessive parallax
- Long transitions
- Animations that slow down routine workshop tasks

The interface should feel **fast**, even on lower-end devices.

---

# 30. Responsive Behavior

The design is phone-first but should remain adaptable.

## Small Phone

Approximately:

**360–375 px**

- Single-column content
- Compact cards
- Stacked action buttons
- Minimal secondary information

## Standard Phone

Approximately:

**390–430 px**

- Primary reference layout
- Two-column summary cards where appropriate
- Comfortable spacing

## Large Screens / Tablets

May introduce:

- Wider cards
- Two-column content
- Expanded navigation
- Additional secondary information

Desktop support must not force desktop interaction patterns onto the phone layout.

---

# 31. Screen Layout Pattern

A standard Pitstop Garage screen should generally follow this structure:

```text
┌─────────────────────────────┐
│ APP BAR                     │
├─────────────────────────────┤
│                             │
│ PAGE TITLE                  │
│ Supporting description      │
│                             │
│ ┌─────────────────────────┐ │
│ │ PRIMARY INFORMATION     │ │
│ └─────────────────────────┘ │
│                             │
│ SECTION                     │
│                             │
│ ┌─────────────────────────┐ │
│ │ INFORMATION CARD        │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ INFORMATION CARD        │ │
│ └─────────────────────────┘ │
│                             │
│                             │
├─────────────────────────────┤
│ BOTTOM NAVIGATION           │
└─────────────────────────────┘
```

The exact structure may vary by feature, but hierarchy should remain consistent.

---

# 32. Role-Specific Design

## Admin

Admin screens prioritize:

- Operational overview
- Service order management
- Customer management
- Mechanic management
- Inventory
- Reports
- System-wide activity

Visual emphasis should be on **volume, status, exceptions, and actions**.

---

## Mechanic

Mechanic screens prioritize:

- Assigned vehicles
- Assigned service orders
- Current tasks
- Task completion
- Diagnosis
- Parts
- Service progress

Visual emphasis should be on **what needs to be done next**.

---

## Customer

Customer screens prioritize:

- Their vehicles
- Active service
- Current status
- Progress
- Assigned mechanic
- Estimated/final cost
- Service history

Visual emphasis should be on **clarity and reassurance**.

Customer screens should contain less administrative information than Admin screens.

---

# 33. Data Density

The application is an operational system, so it may contain substantial information.

However:

**Dense does not mean cramped.**

Use visual grouping to keep information understandable.

Prefer:

```text
VEHICLE
BMW M4

STATUS
IN PROGRESS

MECHANIC
Hamilton
```

over:

```text
BMW M4 | In Progress | Hamilton
```

when the screen is intended for quick mobile scanning.

---

# 34. Dark Mode

Dark mode may be supported later.

The visual language should translate into a dark theme using:

- Deep navy background
- Slightly lighter blue-gray surfaces
- White primary text
- Muted blue-gray secondary text
- Bright accent colors

The dark theme should preserve semantic status colors without excessive saturation.

Dark mode is secondary to the initial mobile light theme unless implementation priorities change.

---

# 35. Design Tokens

Visual values should eventually be centralized into application theme definitions rather than hardcoded throughout individual widgets.

Recommended categories:

```text
AppColors
AppTypography
AppSpacing
AppRadii
AppSizes
AppShadows
```

Examples:

```text
AppColors.primary
AppColors.background
AppColors.surface
AppColors.warning
AppColors.error

AppSpacing.sm
AppSpacing.md
AppSpacing.lg

AppRadii.card
AppRadii.button
```

This allows the visual system to remain consistent as the application grows.

---

# 36. Component Consistency

Reusable components should be preferred for repeated patterns.

Examples:

- `StatusBadge`
- `MetricCard`
- `ServiceOrderCard`
- `VehicleCard`
- `TaskProgress`
- `PrimaryButton`
- `SecondaryButton`
- `EmptyState`
- `ErrorState`
- `SectionHeader`
- `SearchField`
- `FilterChip`

A component that appears repeatedly should not be independently recreated on every screen.

---

# 37. Design Quality Rules

Before considering a screen visually complete, verify:

- The primary purpose of the screen is obvious.
- The most important information is visible without excessive scrolling.
- Status is clearly recognizable.
- Primary actions are easy to find.
- Text is readable on a phone.
- Controls are large enough for touch.
- Color has semantic meaning.
- Cards are visually consistent.
- Spacing follows the defined system.
- The screen still works without decorative graphics.
- No unnecessary desktop/table layout has been forced onto mobile.
- Motorsport styling does not reduce usability.

---

# 38. Design Philosophy

Pitstop Garage should feel like:

> **A professional workshop system built by people who love motorsport.**

It should not feel like:

> **A racing game pretending to be a workshop system.**

The final interface should combine:

**Workshop practicality  
+ Motorsport visual language  
+ Mobile usability  
+ Clear information hierarchy  
+ Professional software design**

The racing influence should be immediately recognizable, but the application should remain understandable to someone who has never watched an endurance race.

---

# 39. Visual Summary

The intended visual identity can be summarized as:

```text
PRIMARY MOOD
Technical / Professional / Motorsport

PRIMARY COLOR
Blue

ACCENTS
Cyan / Lime / Yellow / Orange / Red / Purple

SURFACES
Light / Clean / High Contrast

SHAPE LANGUAGE
Moderately rounded / Structured / Modular

TYPOGRAPHY
Modern sans-serif / Bold technical numbers

GRAPHICS
Timing screens / Technical labels / Subtle grids /
Diagonal accents / Progress indicators

LAYOUT
Mobile-first / Single-column / Modular cards

INTERACTION
Fast / Clear / Touch-friendly

INSPIRATION
Endurance racing / Pit wall / Telemetry / Timing systems

AVOID
Visual clutter / Excessive decoration /
Tiny controls / Desktop-first UI / Brand imitation
```

---

# 40. Source of Truth

This document defines the visual and interaction design direction of Pitstop Garage.

Implementation should follow this document unless a later design decision explicitly supersedes it.

Functional behavior remains governed by:

```text
docs/requirements.md
docs/state-machine.md
docs/task-system.md
docs/business-rules.md
docs/role-permissions.md
docs/route-architecture.md
```

The design system must not override business rules, role permissions, state transitions, or database constraints.

When visual design and usability conflict, **usability takes priority**.