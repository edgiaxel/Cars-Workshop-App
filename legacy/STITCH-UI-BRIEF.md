# PitMate — Google Stitch UI Reference Brief

## Objective

Generate a coherent set of **visual templates and reusable component references** for the existing PitMate Flutter app. These designs will be translated into Flutter by Greg. Do not generate or introduce a separate React/Next.js production app.

## Product context

PitMate is a single-workshop car service management app for three roles: Admin, Mechanic, and Customer. It uses a professional motorsport/endurance-racing visual language: technical, precise, data-aware, and restrained. Usability and clear operational state are more important than racing decoration.

## Design rules

- Use `DESIGN.md` as the token and visual direction reference; use `CUSTOMIZATION.md` for canonical ownership rules.
- Create matching dark and light variants. Dark is the default; light is a first-class theme, not a white recolor.
- Use the final agreed brand accent consistently. Do not introduce competing accent colors.
- Use semantic colors and never rely on color alone for status meaning.
- Keep labels short, specific, and operational. Avoid generic marketing copy.
- Design mobile-first, with safe areas, comfortable tap targets, responsive card/list behavior, and readable typography.
- Use realistic sample content but mark it as design-only; do not imply live metrics or real customers.
- Include loading, empty, error, disabled, and confirmation states where appropriate.
- Prefer reusable patterns over one-off decorative cards.

## First pass: establish a reusable design system

Ask Stitch to create a design-system reference containing:

- Light and dark semantic palette.
- Typography scale and hierarchy.
- Spacing/radius/elevation conventions.
- Primary, secondary, destructive, and icon buttons.
- Text fields, dropdowns, date/time controls, search, filter chips, segmented controls.
- Cards, KPI/metric cards, vehicle/service-order cards, status badges.
- Dialogs, confirmation dialogs, and bottom-sheet patterns.
- Navigation patterns suitable for Admin, Mechanic, and Customer roles.
- Empty/loading/error states.
- Chart containers with legends and readable labels.

## Screen template set

Generate these as separate screens or clearly separated frames, not one giant composite screen:

1. **Login / authentication** — restrained automotive identity, clear validation and password visibility affordance.
2. **Admin dashboard** — operational overview, active jobs, upcoming bookings, inventory alerts, quick actions.
3. **Admin Workshop Queue** — separate Upcoming, Waiting in workshop, In service, Blocked, and Recently completed. Each item shows origin, arrival time when applicable, vehicle, service, status, and next action.
4. **Admin booking management** — requested/approved/scheduled bookings, check-in action for eligible bookings, no confusion between approval and arrival.
5. **Service order detail** — timeline, status, assigned mechanics, tasks/checklists, parts/approval blockers, cost summary.
6. **Admin reports dashboard** — date range, booking vs walk-in vs legacy-unknown intake, service-volume trend, status distribution, mechanic workload. Use honest sample values and readable chart labels.
7. **Mechanic dashboard / assigned queue** — only assigned jobs, clear blockers, next task, task/checklist status.
8. **Customer dashboard** — vehicles, bookings, current service progress, reminders, service history.
9. **Reusable component gallery** — cards, status badges, form fields, dialogs, bottom sheets, filter chips, empty/error/loading states, light and dark.

## Iteration strategy

1. Generate the design system and component gallery first.
2. Review and approve the visual direction before generating the screen set.
3. Generate Admin dashboard and Workshop Queue next; these are the highest priority for the lecturer's queue requirement.
4. Generate reports and service detail after the queue direction is approved.
5. Generate login and role dashboards after shared tokens/components are stable.
6. Generate the alternate theme variants and compare contrast, not just color swaps.

## Handoff requirements for Greg

For each approved reference, Greg should identify:

- Which existing Flutter screen/file corresponds to the design.
- Which shared widgets can be reused or should be improved.
- Which values belong in `lib/app/customization/`.
- Which interactions require real repository/provider/database behavior.
- Which elements are visual-only and must not be presented as working functionality until implemented.
- How the screen adapts to narrow mobile widths and both themes.

Implement references incrementally in the existing architecture. Do not replace the current app, duplicate the design system, or add a web framework merely because Stitch outputs HTML/CSS.

---

## Copy-paste prompts for Stitch

### Prompt 1 — Design system and reusable components

> Design a cohesive, mobile-first design system for PitMate, a professional car workshop management app with Admin, Mechanic, and Customer roles. The visual identity is motorsport/endurance-racing inspired: precise, technical, restrained, and operational rather than flashy. Keep the existing PitMate brand accent motorsport red (#E10600); do not introduce amber as a competing brand accent. Create paired dark and light themes that feel like the same product. Dark uses near-black backgrounds and charcoal surfaces; light uses an off-white #F7F9FC background, white surfaces, graphite text, subtle cool-gray borders, and the same brand accent with contrast-safe variants. Define typography, spacing, radii, elevation, navigation, buttons, fields, filter chips, status badges, metric cards, vehicle/service cards, dialogs, bottom sheets, chart containers, and empty/loading/error states. Prioritize hierarchy, accessibility, readable density, mobile safe areas, and minimum comfortable touch targets. Avoid generic SaaS dashboard clichés, excessive gradients, glassmorphism, decorative racing stripes, checkered flags, and status conveyed by color alone. Show a component gallery with light and dark variants. Treat all values as design references to be translated into an existing Flutter app, not as a request to build a separate website.

### Prompt 2 — Admin dashboard template

> Using the approved PitMate design system, create a mobile-first Admin dashboard for a car workshop. Prioritize what the workshop owner needs to act on today: active service orders, vehicles waiting, upcoming bookings not yet arrived, blocked jobs (waiting for parts or customer approval), inventory alerts, and clear quick actions for Workshop Queue, Bookings, Services, Inventory, and Reports. Use concise operational labels, compact but readable metric cards, clear status badges, and a restrained motorsport aesthetic. Make it obvious that an upcoming booking is not the same as a vehicle that has arrived. Provide dark and light variants. Do not invent features outside this scope or imply sample numbers are live data.

### Prompt 3 — Workshop Queue (highest priority)

> Design PitMate's Admin Workshop Queue for a mobile car workshop management app. This screen must make physical vehicle presence unmistakable. Provide clearly separated sections or a segmented control for: Upcoming Bookings (not arrived), Waiting in Workshop (arrived, not actively being worked on), In Service (inspection, diagnosis, or in-progress work), Blocked / Awaiting Action (waiting for approval, waiting for parts, completion review), and Recently Completed. Each item should show vehicle name/model, customer, service/order reference, intake origin badge (BOOKING or WALK-IN), arrival time and wait duration when applicable, exact current service status, and a contextual next action. Upcoming bookings must not show a fake arrival time. Blocked jobs must visibly explain the blocker and must not look actively in progress. Include search and useful filters for status, mechanic, and intake origin without crowding the screen. Use FIFO queue language, not a manual priority score. Create matching light and dark variants. Make the layout realistic for Flutter mobile screens and scalable to wider screens.

### Prompt 4 — Reports dashboard template

> Design PitMate's Admin Reports dashboard using the same established design system. Include a date-range selector and a clear label showing the applied range. Required report visuals: booking-originated service orders versus walk-ins, with legacy/unknown origin shown separately; service volume over time; service status distribution; and mechanic workload. Use readable charts with legends, direct labels where practical, accessible summaries, and a textual or tabular alternative for key numbers. Do not merge estimated and final/settled revenue into one number. Avoid decorative 3D charts, ambiguous axes, and unlabeled color legends. Include loading, empty, and error states, plus light and dark variants. Treat all values as illustrative placeholders, not live data.

### Prompt 5 — Login, reusable cards, dialogs, and forms

> Create reusable PitMate authentication and form patterns consistent with the approved motorsport-inspired design system: login form, text fields, password visibility control, validation messages, primary/secondary/destructive buttons, vehicle card, service-order card, KPI card, status badge, search/filter controls, confirmation dialog, form dialog, bottom sheet, and empty/error/loading states. Keep the layout mobile-first, accessible, and restrained. Provide both dark and light variants. Dialogs must have clear titles, a concise explanation, and distinct cancel/confirm actions. Destructive actions must be visually clear without using color as the only signal. Do not add marketing slogans or decorative UI that competes with the user's task.

### Prompt 6 — Mechanic and Customer dashboard templates

> Create two role-specific PitMate dashboard references using the same shared design system. The Mechanic dashboard should prioritize assigned active work, next task/checklist actions, blocked jobs, and clear service status; it must not show the full workshop's private customer queue. The Customer dashboard should prioritize their own vehicles, upcoming bookings, current service progress, reminders, and service history with simpler language and lower information density than Admin. Use realistic placeholder content only. Keep the dark and light variants visually consistent with the Admin Queue and Reports screens. Do not create a separate app or change the shared brand system.
