# Design System — Triptel (purple / white)
**Read when:** building or restyling any screen.

The UX reference is the **Eskimo eSIM** Android app (v3.7.3), walked through screen by
screen on the connected vivo V2344 on 2026-11-12. We **follow its structure and
interaction patterns, not its pixels or assets**: no Eskimo illustrations, mascot,
copy, brand blue or pink. Everything is re-skinned in Triptel's colours from the
real logo (`/settings/public.logo_light`).

## 1. Tokens

### Colour (from the Triptel logo)
| Token | Hex | Use |
|---|---|---|
| `primary` | `#5E3CDA` | CTAs, selected states, links, active tab |
| `primaryDeep` | `#452C9B` | Wordmark colour; headings on light, pressed CTA |
| `night` | `#1B1145` | Hero / header backgrounds (Eskimo's navy → Triptel night purple) |
| `nightSoft` | `#2A1A6B` | Glass cards on the hero |
| `sky` | `#3AA0F0` | Accent from the logo gradient: info chips, links on dark |
| `lilac50` | `#F5F2FF` | App background (Eskimo light-blue wash → lilac) |
| `lilac100` | `#EBE5FF` | Selected row fill, segmented track |
| `lilac200` | `#D6CCFF` | Borders on selected cards |
| `surface` | `#FFFFFF` | Cards, sheets, bottom bar |
| `ink` | `#16123A` | Primary text |
| `inkMuted` | `#6B6790` | Secondary text |
| `line` | `#E7E4F2` | Dividers, chip outlines |
| `success` | `#16A34A` | Supported device, completed |
| `warning` | `#F59E0B` | Unknown compatibility, preparing |
| `danger` | `#E5484D` | Not supported, failed, "Not verified" |
| `promo` | `#C026D3` | Badges like "Recommended"/"Best value" (Eskimo pink role, kept in the purple family) |
| `offerDeep` | `#C2720A` | `PromoBanner` gradient end only (2026-11-17 UI refresh, §5) -- never a status colour |

Gradients: hero `night → primaryDeep` (top → bottom, fading into `lilac50`);
balance card `primary → primaryDeep` with a subtle line pattern.

### Typography
`Plus Jakarta Sans` (Google Fonts; geometric like Eskimo's). Scale:
display 32/800 · title 24/800 · headline 20/700 · body 16/500 · label 14/600 ·
caption 12/500. Big numbers (data sizes, balances) 36–44/800.

### Shape & elevation
Radius: card 24, sheet 28 (top), pill 999, input 999, chip 999, small tag 8.
Shadow: `0 8 24 rgba(46, 23, 120, 0.08)`. Hero glass card: `nightSoft` 70 % + 1px
white 10 % border. Spacing grid 4; screen gutter 20 (Eskimo ≈ 38px @ 300dpi ≈ 20dp).

## 2. Screen patterns observed in Eskimo → Triptel mapping
Screenshots of every screen below are in [`design-reference/`](./design-reference/README.md).
**Aim for a similar layout** to those screenshots (same structure, hierarchy and
flow), in Triptel colours. Open the matching screenshot before building a screen.

| Eskimo screen | Pattern | Triptel use |
|---|---|---|
| Home | Dark hero with pill CTA ("Install your eSIM") + search icon; illustration; floating glass card with 3 round action buttons overlapping the hero edge; big white promo cards; floating chat bubble | FR-201 Home (actions: Buy data · My eSIMs · Top up; promos: referral, device check). Chat bubble → Support sheet |
| Explore | Full-height sheet over the hero: search pill + close, featured card (Global), segmented **Country/Regional**, Popular flag chips, A–Z sections with white rows (round flag, name, network + "5G" tag, chevron) | FR-202/203 |
| Regional tab | Globe icon rows, "N countries" link in accent | FR-203 |
| Country plans | Curved coloured header (back, flag, name, currency pill); **vertical wheel picker** of data sizes with the selected row in a white pill card carrying badges; segmented plan-type toggle; bottom panel (rounded top) with feature icons, info banner, **radio list** of plan options (title, coverage link, price + strike price), full-width pill **Checkout** | FR-204 (wheel over data for Data plans, over days for Day Pass/Unlimited) |
| Compatibility dialog at checkout | Centered dialog: icon, "Buy now, use later", explanation, primary Continue, secondary "View supported devices", tertiary Cancel | FR-301 |
| Checkout | Plan title + subtitle, card with voucher row (chevron) and toggle row (use credit), breakdown card, info pill, sticky bottom bar (Total, "You've saved …", pill CTA) | FR-302–305 (toggle row = "Use reward credit" display only; backend decides) |
| Rewards | Dark header title, segmented tabs, gradient balance card with Earned/Pending/Used stats strip, tier card | FR-601 Wallet hero, FR-801 stats |
| Free data | Dark card: icon, headline, code chip + Invite button, "How it works · My referrals" split | FR-801 |
| Account | Hero with greeting card (name, two split stats, Invite CTA); grouped white list cards (icon, title, red "Not verified" subtitle, chevron); collapsing header on scroll | FR-1001 |
| Device compatibility | Result-tinted top (red = not supported), white sheet: device chip, verdict title, body, grey info box, "Supported Devices" brand chips + list | FR-951/952 |
| Help sheet | Bottom sheet: title + close, text, primary pill CTA, text link | Support sheet (FR-1104) |
| Notifications | Simple list of white cards | Not built (no push backend) |

## 3. Interaction rules
- One primary pill CTA per screen, full width, 56 dp, bottom-anchored on task screens.
- Segmented controls: pill track `lilac100`, selected thumb `surface` with shadow.
- Selected card/radio: `lilac100` fill + `primary` 1.5 px border.
- Prices: current price `ink` 800; original (when discounted) strike-through `inkMuted`.
- Status chips: Active/Installed `success`, Not installed `sky`, Preparing `warning`,
  Suspended/Revoked/Cancelled/Expired/Failed `danger`.
- Bottom sheets for choices (payment method, currency, language, coverage); full
  screens for tasks.
- Motion: 200–300 ms ease-out; wheel snaps with light haptic.
- Empty states: illustration-free icon in a `lilac100` circle + one sentence + CTA.
- Loading: skeletons on lists, three-dot loader on sheets (Eskimo style).
- Accessibility: contrast ≥ 4.5:1 for body text (white on `primary` = 6.0:1 OK;
  `inkMuted` on `lilac50` must stay ≥ 4.5:1), tap targets ≥ 48 dp, all icons labelled.
- RTL: use `EdgeInsetsDirectional`/`AlignmentDirectional` only.

## 4. Shared components (build in FR-001, reuse everywhere)
`TriptelScaffold` (lilac background, optional hero) · `HeroHeader` (curved bottom
edge) · `PillButton` (primary/secondary/text) · `SegmentedPill` · `SearchPill` ·
`FlagAvatar` (network image / globe fallback) · `CountryRow` · `PlanWheelPicker` ·
`PlanOptionTile` (radio) · `PriceText` (EUR → display currency) · `StatusChip` ·
`BalanceCard` · `ListGroup`/`ListRow` · `InfoBox` · `StickyTotalBar` ·
`PaymentMethodSheet` · `EsimQr` · `UsageRing` · `EmptyState` · `ErrorState` ·
`StatusDot` · `PromoBanner` (both added 2026-11-17, §5).

## 5. 2026-11-17 UI refresh (client mockup)
The client sent an 8-panel branded mockup (`design-reference/
16-client-ui-refresh-reference.png`) asking for a visual-polish pass
"throughout the app." Scope was clarified with the user first (see
`DECISIONS.md`): **visual polish only** against existing screens/features --
no bottom-nav relabel, no new screens, no features not already in
`Functional_Requirements.md`.

**Already matched, confirmed, no change needed:** the purple palette
(`primary`/`primaryDeep` are within a few hex digits of the mockup's own
purple), card radius/shadow, Plus Jakarta Sans's bold weight, pill buttons,
segmented filter chips, white rounded list/promo rows (e.g.
`CompatibilityPromoCard` already matches the mockup's "Check device
compatibility" row almost exactly).

**Added as a direct result:**
- Home hero now carries a two-line bold tagline ("Travel smart. / Stay
  connected.") above the search pill -- pure branding text, no new data.
- `StatusDot` (small coloured dot + plain-text label) -- a lighter-weight
  sibling to `StatusChip` for live/presence-style indicators ("Active",
  "Online") on a card header, where a filled pill is too heavy. Added to
  §1/§4 above; not yet wired into a real screen (no existing screen has a
  presence-style indicator today) -- available for Support (FR-1101+)'s
  "Online" agent status when that's built.
- `PromoBanner` -- warm gradient CTA card (`warning -> offerDeep`, a new
  token added for this only) with icon/title/subtitle and a white pill CTA,
  matching the mockup's "Special Offer" banner. Not instantiated anywhere
  live yet: there's no real promotional-campaign data source today (Rules.md
  -- never fabricate banner copy). Ready for FR-801 (Refer & earn) or any
  future real-offer feature.

**Deliberately NOT done, and why:**
- **AI chat assistant, "Adapter Store," "Compare Plans"** -- real features
  shown in the mockup that don't exist in `Functional_Requirements.md`.
  Building them now would be scope creep outside the feature loop's own
  governance; they'd need their own FR entries (and, for the AI assistant,
  real backend support) before a maker/reviewer pass can verify them against
  anything.
- **Bottom-tab relabel** (mockup shows Home/Dashboard/Support/Profile) --
  the app's actual 4 tabs (Home/My eSIMs/Wallet/Account) map to real FRs;
  renaming/restructuring them is a navigation change, not a polish change,
  and was explicitly out of scope per the user's own clarification.
- **Per-row data-usage progress bar** on My eSIMs / any list view -- the
  mockup shows a usage bar on every list row, but `GET /orders/my-esims`
  (the list endpoint) carries no live usage figure, only the original
  purchase total (`esim_card_shape.dart`'s own doc comment). Only the detail
  screen's `GET /esims/{id}/status` has real telemetry, which is why
  `UsageRing` only ever appears there. Inventing a per-row bar from stale
  data would violate Rules.md ("never invent fields").
- **Personalized "Hello, Traveler! 👋" greeting** -- that's FR-201b's
  signed-in-hero variant, which is `blocked` (needs FR-402/403 usage data
  the Home tab doesn't have). Not added ahead of that FR being unblocked.

## 6. Assets
- App icon: Triptel mark from `/settings/public.favicon` (purple→sky ribbon "A"),
  not the wordmark. Splash: `night` background + white mark.
- Flags: `country.flag_url` (flagcdn 80 px) in a circle; regionals → globe icon.
- No third-party brand art (Eskimo, Klook, Trip.com...).
