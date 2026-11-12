# Design reference — Eskimo eSIM (Android v3.7.3)
Captured 2026-11-12 from the connected vivo V2344 (Android 14, 720×1612, 300 dpi).
**Layout reference only:** build Triptel screens with a similar layout and flow,
in Triptel purple/white (`../Design_System.md`). Don't reuse Eskimo artwork,
mascot, copy or colours. These are internal references; don't ship them in the app.

| File | Screen | Triptel FR |
|---|---|---|
| `01-home-promo-modal.png` | First-purchase promo modal over home | FR-201 (optional promo) |
| `02-home.png` | Home: dark hero, pill CTA, floating 3-action card, promo cards, chat bubble, 3-tab nav | FR-201, FR-004 |
| `03-explore-country.png` | Explore sheet: search pill, Global card, Country/Regional toggle, popular flag chips, A–Z rows | FR-202 |
| `04-explore-regional.png` | Regional tab: globe rows + "N countries" | FR-203 |
| `05-plans-data-wheel.png` | Country plans: curved header, data wheel picker, plan-type toggle, radio plan list, Checkout CTA | FR-204 |
| `06-plans-unlimited-days.png` | Same screen in Unlimited mode: wheel over days | FR-204 (Day Pass / Unlimited) |
| `07-checkout-compatibility-dialog.png` | "Buy now, use later" dialog on an unsupported phone | FR-301 |
| `08-checkout-review.png` | Checkout: voucher row, credit toggle, breakdown, sticky total bar | FR-302–FR-305 |
| `09-rewards-cashback.png` | Balance hero card + Earned/Pending/Used stats | FR-601 |
| `10-rewards-referral.png` | Referral card: code chip + Invite, How it works / My referrals | FR-801 |
| `11-notifications.png` | Notification list (no push backend in Triptel — style only) | — |
| `12-account-top.png` | Account hero: greeting card, split stats, Invite CTA, grouped list with "Not verified" | FR-1001 |
| `13-account-settings.png` | Account lower groups: Settings, Support (Check device compatibility), About, collapsing header | FR-1001, FR-953 |
| `14-device-compatibility.png` | Compatibility result: tinted top, device chip, verdict, info box, brand chips + list | FR-951, FR-952 |
| `15-help-sheet.png` | Support bottom sheet: title, text, primary CTA, text link | FR-1104 |

Note: the device owner's name (`12-account-top.png`) and referral code (`10-rewards-referral.png`)
are blurred out; this repo is public.
