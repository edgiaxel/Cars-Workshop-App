# PitMate — Design System & UI/UX Guidelines

## 1. Purpose

This document defines the visual identity, UI/UX principles, design tokens, component guidelines, layout rules, and interaction patterns for the PitMate application.

PitMate is a car workshop management application designed around a motorsport-inspired visual identity while remaining practical for real workshop operations.

The design should communicate:

- Automotive and motorsport identity
- Technical precision
- Professional workshop operations
- Clear information hierarchy
- Fast access to important information
- Modern mobile application usability
- Consistency across Admin, Mechanic, and Customer interfaces

The design must prioritize **usability and information clarity over visual decoration**.

---

# 2. Design Direction

## 2.1 Core Visual Concept

PitMate uses a **modern motorsport / endurance-racing inspired interface**.

The visual language may take inspiration from:

- Race telemetry interfaces
- Pit wall dashboards
- Endurance racing timing systems
- Motorsport data displays
- Garage/workshop equipment
- Technical control panels
- Automotive instrumentation

The application should feel like a **professional digital pit system**, rather than a generic business-management application.

However, PitMate must not become visually overloaded with racing references.

The motorsport inspiration should primarily appear through:

- Typography
- Information density
- Status indicators
- Technical layouts
- Progress visualization
- Strong contrast
- Compact data presentation
- Subtle geometric elements

Avoid excessive racing decorations, checkered flags, tire graphics, racing stripes, or unnecessary automotive imagery.

---

# 3. Design Principles

## 3.1 Clarity First

Every interface element should have a clear purpose.

Users should be able to quickly understand:

- What screen they are on
- What information is important
- What action they can perform
- What the current status is
- What requires attention

Visual styling must never make important information harder to read.

---

## 3.2 Information Hierarchy

Information should be visually prioritized.

Use the following general hierarchy:

1. Page title / primary context
2. Important status or KPI
3. Primary action
4. Important operational information
5. Secondary information
6. Supporting metadata

Not every screen needs every level.

---

## 3.3 Consistency

The same concept must look the same throughout the application.

Examples:

- Service statuses use consistent colors.
- Primary buttons use the same visual treatment.
- Cards use consistent spacing and radius.
- Form fields behave consistently.
- Error messages use consistent styling.
- Vehicle information uses the same presentation pattern across screens.

Avoid creating one-off visual patterns for individual screens unless there is a clear usability reason.

---

## 3.4 Technical but Approachable

PitMate should feel technical without becoming intimidating.

The interface should resemble a professional workshop system rather than a developer tool.

Use:

- Clean typography
- Strong spacing
- Clear labels
- Compact information blocks
- Technical data presentation

Avoid:

- Excessive terminal-like interfaces
- Tiny unreadable text
- Excessive neon colors
- Excessive decorative borders
- Overly complex animations

---

# 4. Color System

PitMate uses a dark visual foundation.

The interface should primarily use dark backgrounds with elevated surfaces and controlled accent colors.

## 4.1 Base Colors

```text
Background Primary:   #0B0D10
Background Secondary: #11151A
Surface Primary:      #171C22
Surface Secondary:    #1E252D
Surface Elevated:     #252D36

Border Subtle:        #2D3742

Text Primary:         #F5F7FA
Text Secondary:       #AAB4C0
Text Muted:           #707B88
```

These colors establish the primary visual hierarchy.

---

## 4.2 Brand / Accent Colors

The primary PitMate accent should be inspired by motorsport instrumentation.

```text
Primary Accent:       #E10600
Primary Accent Light: #FF3B30
Primary Accent Dark:  #A80000
```

The red accent should be used intentionally for:

- Primary actions
- Active navigation
- Important highlights
- Selected controls
- Key visual indicators

Do not use the primary accent on every component.

Accent usage should remain controlled so important actions remain visually obvious.

---

## 4.3 Semantic Colors

Semantic colors must communicate system state.

```text
Success:  #22C55E
Warning:  #F59E0B
Error:    #EF4444
Info:     #3B82F6
Neutral:  #64748B
```

Semantic colors should be used consistently for:

- Status badges
- Alerts
- Validation messages
- Service states
- Inventory warnings
- Notifications
- Operational indicators

Semantic colors must not be used purely as decoration.

---

# 5. Status Color Guidelines

Service and operational statuses should have predictable visual meanings.

Example mapping:

```text
Requested              → Info
Approved               → Info
Scheduled              → Info
Inspection             → Warning
Diagnosis              → Warning
Waiting for Approval   → Warning
Waiting for Parts      → Warning
In Progress            → Primary Accent
Completion Review      → Info
Completed              → Success
Payment                → Success
Closed                 → Neutral
Cancelled              → Error
```

The exact mapping may be implemented centrally so that every screen uses the same status representation.

---

# 6. Typography

PitMate uses two primary typefaces:

- **Inter**
- **Space Grotesk**

## 6.1 Inter

Inter is the primary interface font.

Use Inter for:

- Body text
- Labels
- Form fields
- Buttons
- Navigation
- Tables
- Metadata
- General UI

Inter should be the default application font.

---

## 6.2 Space Grotesk

Space Grotesk is the display / technical font.

Use it selectively for:

- Large page titles
- Dashboard metrics
- Important numerical values
- Section headings
- Automotive/technical visual emphasis

Do not use Space Grotesk for every piece of text.

---

## 6.3 Typography Hierarchy

Recommended hierarchy:

```text
Display
32–40 px
Bold / SemiBold

Page Title
24–28 px
SemiBold / Bold

Section Title
18–22 px
SemiBold

Body
14–16 px
Regular / Medium

Label
12–14 px
Medium

Caption
11–12 px
Regular / Medium
```

Exact font sizes may be adjusted for device constraints, but the hierarchy must remain consistent.

---

# 7. Spacing System

Use a consistent spacing scale.

Base unit:

```text
4 px
```

Recommended spacing:

```text
4 px   → micro spacing
8 px   → compact spacing
12 px  → small spacing
16 px  → standard spacing
20 px  → medium spacing
24 px  → section spacing
32 px  → large spacing
40 px  → major separation
48 px+ → page-level separation
```

Avoid arbitrary spacing values unless necessary.

Consistent spacing should create predictable visual rhythm across the application.

---

# 8. Border Radius

Use moderate rounding.

Recommended values:

```text
Small controls:   8 px
Inputs:           10 px
Cards:            12–16 px
Dialogs:          16 px
Large containers: 20 px
```

Avoid excessive pill-shaped interfaces.

Pills should primarily be reserved for:

- Status badges
- Compact tags
- Filters
- Small indicators

---

# 9. Surfaces and Cards

Cards are an important component of the PitMate interface.

Cards should represent logical information groups rather than being used around every individual element.

Example:

```text
┌──────────────────────────────────────┐
│ SERVICE ORDER                        │
│                                      │
│ Toyota GR Yaris                      │
│ Oil & Filter Service                 │
│                                      │
│ ● IN PROGRESS                        │
│                                      │
│ Technician: Andi                     │
│ Estimated Cost: Rp 850.000           │
└──────────────────────────────────────┘
```

Cards should use:

- Dark elevated surfaces
- Subtle borders
- Moderate radius
- Clear internal spacing

Avoid heavy shadows.

---

# 10. Glass / Elevated Surface Style

PitMate may use subtle glass-like surfaces to reinforce the modern technical aesthetic.

Glass styling should be restrained.

Use:

- Semi-transparent dark surfaces
- Subtle borders
- Mild background blur where appropriate
- Low-opacity highlights

Do not turn the entire application into a glassmorphism interface.

Glass effects should enhance hierarchy rather than replace it.

---

# 11. Buttons

## 11.1 Primary Button

Used for the main action on a screen.

Examples:

- Create Booking
- Approve Service
- Assign Mechanic
- Save Changes
- Start Service

Primary buttons use the PitMate accent.

---

## 11.2 Secondary Button

Used for supporting actions.

Examples:

- Cancel
- Back
- View Details
- Edit

Secondary buttons should use neutral surfaces or outlined styling.

---

## 11.3 Destructive Button

Used for actions that may remove or permanently change information.

Examples:

- Delete Vehicle
- Cancel Service
- Remove Mechanic

Destructive actions should use the error semantic color.

Destructive actions should normally require confirmation when the operation cannot easily be undone.

---

# 12. Forms

Forms should be clean, compact, and easy to scan.

Input fields should include:

- Clear label
- Input area
- Optional supporting text
- Validation state
- Error message when necessary

Example:

```text
Vehicle Name
┌────────────────────────────────────┐
│ Toyota GR Yaris                    │
└────────────────────────────────────┘
```

Validation errors should appear close to the relevant field.

Avoid relying exclusively on color to communicate validation state.

---

# 13. Navigation

Navigation must reflect the user's role.

The application should provide role-appropriate navigation rather than exposing every feature to every user.

## Customer

Typical navigation:

```text
Home
Vehicles
Bookings
Services
History
Profile
```

## Mechanic

Typical navigation:

```text
Dashboard
Assigned Services
Tasks
Parts
History
Earnings
Profile
```

## Admin

Typical navigation:

```text
Dashboard
Bookings
Services
Customers
Mechanics
Vehicles
Inventory
Reports
Notifications
Profile
```

The exact navigation structure may evolve during implementation.

---

# 14. App Shell

The application shell should provide:

- Consistent page structure
- App branding
- Navigation
- Page title
- Optional contextual actions
- Scrollable content area

On mobile devices, prioritize:

- Bottom navigation
- Compact app bars
- Scrollable cards
- Full-width forms
- Bottom sheets where appropriate

Avoid desktop-style layouts being squeezed onto small mobile screens.

---

# 15. Dashboard Design

Dashboards should summarize information rather than reproduce entire management screens.

A dashboard should answer:

> "What do I need to know right now?"

Examples of dashboard information:

- Active service orders
- Pending bookings
- Services requiring attention
- Low-stock parts
- Today's scheduled work
- Earnings
- Recent activity

Use compact KPI cards and operational lists.

Example:

```text
TODAY

┌──────────────┐ ┌──────────────┐
│  08          │ │  03          │
│ Active Jobs  │ │ Waiting      │
└──────────────┘ └──────────────┘

SERVICE ACTIVITY

┌────────────────────────────────┐
│ Toyota Supra                   │
│ Brake Inspection               │
│ ● INSPECTION                   │
└────────────────────────────────┘
```

---

# 16. Service Order Interface

Service orders are one of the most important concepts in PitMate.

Their interface should clearly communicate:

- Vehicle
- Customer
- Service type
- Current status
- Assigned mechanics
- Tasks
- Parts
- Estimated cost
- Final cost
- Timeline/history

The service status should be visually prominent.

---

# 17. Service Progress Visualization

Service progression should use a clear timeline or progress representation.

Example:

```text
Requested
   │
   ● Approved
   │
   ● Scheduled
   │
   ● Inspection
   │
   ● Diagnosis
   │
   ◉ In Progress
   │
   ○ Completion Review
   │
   ○ Completed
   │
   ○ Payment
   │
   ○ Closed
```

The current state should be immediately recognizable.

Completed states should visually differ from pending states.

Do not make the visualization so decorative that the actual status becomes unclear.

---

# 18. Mechanic Task Interface

Mechanics should be able to quickly understand what work is assigned to them.

A task interface should prioritize:

1. Service vehicle
2. Task name
3. Current task status
4. Checklist
5. Notes
6. Parts required
7. Action

Example:

```text
BRAKE SYSTEM INSPECTION

Toyota GR Supra
Service #SP-0024

CHECKLIST

☑ Inspect brake pads
☐ Inspect brake discs
☐ Check brake fluid
☐ Test brake performance

[ Mark Task Complete ]
```

The interface should minimize unnecessary navigation while a mechanic is working.

---

# 19. Inventory Interface

Inventory information should prioritize operational relevance.

Important information includes:

- Part name
- SKU
- Current stock
- Minimum stock
- Unit price
- Stock status

Example:

```text
BRAKE PAD — FRONT

Stock
24 units

Minimum
10 units

STATUS
● Healthy
```

Low-stock parts should be clearly identifiable.

Inventory screens should support scanning rather than requiring users to read large amounts of text.

---

# 20. Cost Presentation

Costs should be visually separated into logical categories.

Example:

```text
SERVICE COST

Labor
Rp 350.000

Parts
Rp 420.000

Additional Charges
Rp 80.000
────────────────
Estimated Total
Rp 850.000
```

Final costs should be visually distinguished from estimates.

Currency formatting should consistently use Indonesian Rupiah formatting.

---

# 21. Vehicle Presentation

Vehicles should have a consistent information card.

Recommended information:

```text
Toyota GR Yaris
2023

Plate
B 1234 XYZ

VIN
••••••••1234

Mileage
24.500 km
```

Vehicle identity should be immediately recognizable.

If vehicle imagery is used, it should support identification rather than dominate the interface.

---

# 22. Tables and Lists

Dense data should be presented in a format appropriate for the device.

On mobile:

- Prefer cards
- Compact list rows
- Expandable sections
- Bottom sheets
- Horizontal scrolling only when necessary

Avoid forcing large desktop tables into narrow mobile screens.

On larger screens, tables may be used for administrative data such as:

- Customers
- Inventory
- Service orders
- Reports

---

# 23. Status Badges

Status badges should combine:

- Color
- Text
- Optional icon

Example:

```text
● IN PROGRESS
```

Do not rely on color alone.

Badges should remain readable in both normal and accessibility-focused conditions.

---

# 24. Icons

Use a consistent icon family throughout the application.

Icons should:

- Have consistent stroke/style
- Clearly communicate their meaning
- Be paired with text when ambiguity is possible

Avoid using automotive icons simply because they look decorative.

An icon should communicate information or action.

---

# 25. Empty States

Empty states should explain why there is no content and what the user can do next.

Example:

```text
No vehicles yet

Add your first vehicle to start
booking workshop services.

[ Add Vehicle ]
```

Avoid blank screens.

---

# 26. Loading States

Loading states should communicate that the application is working.

Preferred patterns:

- Skeleton cards
- Progress indicators
- Button loading states
- Inline loading indicators

Avoid blocking the entire interface with unnecessary loading screens.

---

# 27. Error States

Errors should be clear and actionable.

Example:

```text
Unable to load service orders.

Please check your connection
and try again.

[ Retry ]
```

Technical error details should not be exposed unnecessarily to normal users.

---

# 28. Notifications

Notifications should be concise and actionable.

Examples:

```text
Service Approved
Your Toyota GR Yaris service has been approved.

Low Stock
Brake pads are below the minimum inventory level.
```

Use notification priority appropriately.

Not every system event needs to interrupt the user.

---

# 29. Reminders

Reminder interfaces should emphasize:

- What needs attention
- When it is due
- Related vehicle/service
- Optional action

Example:

```text
SERVICE REMINDER

Toyota GR Yaris

Oil service recommended

Due in approximately
500 km

[ View Vehicle ]
```

---

# 30. Dialogs and Bottom Sheets

Dialogs should be reserved for focused decisions.

Good uses:

- Confirmation
- Destructive actions
- Important warnings
- Short forms

Bottom sheets may be used for:

- Filters
- Quick actions
- Status selection
- Compact contextual actions

Do not use dialogs for entire complex workflows.

---

# 31. Responsive Design

PitMate is primarily a mobile application.

Design for:

- Small phones
- Standard phones
- Large phones
- Tablets where practical

The layout should adapt rather than simply scale.

Important considerations:

- Safe areas
- Keyboard interaction
- Long text
- Dynamic content
- Different screen widths
- Touch targets

Interactive elements should have sufficiently large touch areas.

---

# 32. Accessibility

Accessibility is part of the design system.

The application should:

- Maintain readable contrast
- Avoid color-only communication
- Provide meaningful labels
- Support text scaling where practical
- Maintain sufficiently large touch targets
- Avoid tiny text
- Provide clear focus/interaction states

The motorsport aesthetic must never compromise readability.

---

# 33. Motion and Animation

Animations should communicate state or interaction.

Appropriate uses:

- Page transitions
- Loading
- Expanding cards
- Status changes
- Progress updates
- Button feedback

Animations should be:

- Short
- Subtle
- Functional

Avoid excessive racing-style animations.

PitMate should not constantly flash, pulse, or move simply to appear dynamic.

---

# 34. Imagery

Photography and illustrations are optional.

When imagery is used, prefer:

- Cars
- Workshop environments
- Mechanical components
- Garage environments
- Motorsport-inspired technical imagery

Images should support the interface rather than overpower operational information.

The core application must remain usable without relying on imagery.

---

# 35. Data Visualization

Reports should use simple, readable visualizations.

Potential visualizations include:

- Service counts
- Revenue summaries
- Service status distribution
- Inventory status
- Mechanic workload
- Completed services

Charts should prioritize:

1. Readability
2. Accurate interpretation
3. Clear labels
4. Useful comparison

Avoid decorative charts that do not communicate meaningful information.

---

# 36. Role-Based Visual Priorities

## Admin

Admin interfaces prioritize:

- Operational overview
- Service management
- Customers
- Mechanics
- Inventory
- Costs
- Reports
- Exceptions requiring attention

The Admin interface may have higher information density.

---

## Mechanic

Mechanic interfaces prioritize:

- Assigned work
- Current service
- Tasks
- Checklists
- Parts
- Service progress
- Notes
- Earnings/history

The Mechanic interface should minimize unnecessary administrative information.

---

## Customer

Customer interfaces prioritize:

- Vehicles
- Bookings
- Service progress
- Service history
- Costs
- Reminders
- Notifications

The Customer interface should use simpler language and lower information density.

---

# 37. Design Tokens

Design tokens should be centralized rather than recreated throughout individual screens.

At minimum, centralize:

```text
Colors
Typography
Spacing
Border Radius
Elevation
Component dimensions
Status colors
```

Flutter theme configuration should provide the primary source for reusable visual tokens.

Individual screens should avoid defining arbitrary colors or typography values unless a specific exception is justified.

---

# 38. Component Reuse

Common UI patterns should become reusable components.

Potential shared components include:

```text
PitMateCard
PitMateButton
PitMateTextField
StatusBadge
ServiceStatusIndicator
VehicleCard
ServiceOrderCard
MetricCard
EmptyState
ErrorState
LoadingState
ConfirmationDialog
SectionHeader
```

Components should be introduced when repetition becomes meaningful.

Do not create abstractions solely for the sake of abstraction.

---

# 39. Design Rules for AI-Assisted Development

When implementing UI, the development agent must follow this document together with:

- `SPEC.md`
- `ARCHITECTURE.md`
- `AGENTS.md`

The agent must not invent a separate visual system for individual features.

Before implementing a new screen, the agent should:

1. Identify the user's role.
2. Identify the screen's primary purpose.
3. Identify the most important information.
4. Reuse existing design tokens.
5. Reuse existing components where appropriate.
6. Implement loading, empty, error, and success states where applicable.
7. Ensure the layout works on mobile screens.
8. Ensure actions are clearly distinguishable.
9. Verify that status colors follow the centralized status system.
10. Avoid unnecessary decorative elements.

If a new visual pattern is required, it should be introduced as part of the shared design system rather than implemented as an isolated one-off.

---

# 40. Visual Quality Checklist

Before considering a screen complete, verify:

### Layout
- [ ] Content hierarchy is obvious.
- [ ] Spacing is consistent.
- [ ] Important content is visible without unnecessary scrolling.
- [ ] Layout works on small mobile screens.
- [ ] Touch targets are practical.

### Typography
- [ ] Inter is used for normal UI text.
- [ ] Space Grotesk is used selectively for technical/display emphasis.
- [ ] Text hierarchy is consistent.
- [ ] No unnecessarily tiny text exists.

### Color
- [ ] Dark foundation is maintained.
- [ ] Primary accent is used intentionally.
- [ ] Semantic colors have consistent meaning.
- [ ] Color is not the only way information is communicated.

### Components
- [ ] Existing components are reused where appropriate.
- [ ] Buttons have clear hierarchy.
- [ ] Status badges are consistent.
- [ ] Forms provide clear validation.
- [ ] Loading, empty, and error states are handled.

### UX
- [ ] The user's primary action is obvious.
- [ ] Important information is easy to find.
- [ ] Destructive actions are clearly distinguished.
- [ ] Navigation matches the user's role.
- [ ] No unnecessary interaction steps were introduced.

### Visual Identity
- [ ] Motorsport influence is present but restrained.
- [ ] The interface feels technical and professional.
- [ ] Decorative elements do not interfere with usability.
- [ ] The application still feels like a workshop management system.

---

# 41. Final Design Principle

PitMate should feel like a **digital pit wall for a professional workshop**.

It should communicate:

> **Fast information. Clear status. Precise operations.**

The motorsport identity should make PitMate distinctive, while the underlying interface remains practical enough that a real workshop user could understand and operate it without needing to learn the visual language first.

**Usability comes first.  
Consistency comes second.  
Visual identity reinforces both.**