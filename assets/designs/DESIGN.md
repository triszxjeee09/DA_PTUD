---
name: Nhà Thuốc Số
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#414753'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#727784'
  outline-variant: '#c1c6d5'
  surface-tint: '#005cba'
  primary: '#004e9f'
  on-primary: '#ffffff'
  primary-container: '#0066cc'
  on-primary-container: '#dfe8ff'
  inverse-primary: '#aac7ff'
  secondary: '#006d37'
  on-secondary: '#ffffff'
  secondary-container: '#6bfe9c'
  on-secondary-container: '#00743a'
  tertiary: '#9f1710'
  on-tertiary: '#ffffff'
  tertiary-container: '#c23225'
  on-tertiary-container: '#ffe2de'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d7e3ff'
  primary-fixed-dim: '#aac7ff'
  on-primary-fixed: '#001b3e'
  on-primary-fixed-variant: '#00458e'
  secondary-fixed: '#6bfe9c'
  secondary-fixed-dim: '#4ae183'
  on-secondary-fixed: '#00210c'
  on-secondary-fixed-variant: '#005228'
  tertiary-fixed: '#ffdad5'
  tertiary-fixed-dim: '#ffb4a9'
  on-tertiary-fixed: '#410000'
  on-tertiary-fixed-variant: '#910807'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  display-lg:
    fontFamily: Be Vietnam Pro
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Be Vietnam Pro
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-md:
    fontFamily: Be Vietnam Pro
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
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
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  headline-lg-mobile:
    fontFamily: Be Vietnam Pro
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 16px
  margin-mobile: 20px
  margin-tablet: 32px
---

## Brand & Style

The design system is centered on the principles of **Reliability, Vitality, and Accessibility**. As a digital pharmacy serving a Vietnamese audience, the UI must bridge the gap between clinical authority and modern convenience. 

The aesthetic follows a **Corporate / Modern** direction with a focus on high legibility and spaciousness. It utilizes a "Soft-Clinical" approach: professional enough for medical services, but warm enough to feel approachable for elderly users or those in a state of health-related stress. The interface prioritizes clarity, using ample white space to reduce cognitive load and a structured hierarchy to guide users through medication management and purchasing.

**Target Audience:** Vietnamese families, health-conscious individuals, and elderly users requiring clear, high-contrast interfaces.
**Emotional Response:** Safety, trust, cleanliness, and peace of mind.

## Colors

The palette is rooted in medical tradition but updated for digital clarity. 

- **Primary (Medical Blue):** Used for primary actions, headers, and brand identification. It signifies expertise and stability.
- **Secondary (Health Green):** Reserved for "Success" states, availability indicators, and holistic health categories.
- **Tertiary (Urgent Red):** Used sparingly for warnings, allergic reactions, or "Critical" medication alerts.
- **Background (Soft Tint):** A very light blue tint (#F0F7FF) is used for the main background to reduce eye strain and differentiate from the pure white surfaces of interactive cards.
- **Neutral:** A slate-based grey used for secondary text to maintain high contrast while avoiding the harshness of pure black.

## Typography

This design system uses **Be Vietnam Pro** for headlines to leverage its excellent Vietnamese diacritic handling and friendly, contemporary character. **Inter** is used for body text and labels to ensure maximum legibility at small sizes, particularly for drug dosages and instructions.

Large headlines should be used sparingly for screen titles and section headers. Body text must never drop below 14px to ensure accessibility for older users. Line heights are slightly generous to accommodate Vietnamese tonal marks without vertical crowding.

## Layout & Spacing

The layout utilizes a **fluid grid** optimized for mobile-first interactions. A 4-column grid is used for mobile devices, while a 12-column grid is applied for tablet views.

- **Mobile Margins:** 20px safe area on left and right edges.
- **Vertical Rhythm:** Elements are spaced in multiples of 4px. Use 16px (md) for standard padding between items in a list and 24px (lg) for spacing between distinct sections.
- **Card Padding:** All primary containers (Cards) should utilize 16px internal padding to ensure content feels breathable and organized.

## Elevation & Depth

Visual hierarchy is managed through **Ambient Shadows** and **Tonal Layers**. 

Interactive elements like product cards and consultation buttons sit on a pure white (#FFFFFF) surface with a soft, diffused shadow (Blur: 15px, Y: 4, Opacity: 5% of Primary Blue). This makes them appear to float slightly above the #F0F7FF background.

Inactive or secondary elements use low-contrast outlines (1px solid #E2E8F0) without shadows to remain grounded. Sticky bottom navigation bars use a subtle backdrop blur (10px) to maintain context while ensuring the "Buy Now" or "Consult" buttons remain prominent.

## Shapes

The shape language is purposefully **Rounded**. This softens the "clinical" feel of the app, making it more welcoming.

- **Standard UI Elements:** Buttons and input fields use a 0.5rem (8px) radius.
- **Content Containers:** Product cards and banners use a "rounded-lg" 1rem (16px) radius.
- **Search & Filter:** Search bars and category chips use a "rounded-xl" 1.5rem (24px) radius to create a distinct, pill-like shape that invites touch.

## Components

### Buttons
- **Primary:** Filled with #0066CC, white text, 8px border radius. Bold typography.
- **Secondary:** White fill, #0066CC border (1px), #0066CC text.
- **CTA:** For "Thêm vào giỏ hàng" (Add to cart), use the primary style with an added cart icon.

### Input Fields
- Use a soft light-grey background (#F8FAFC) with a 1px border. On focus, the border changes to Primary Blue with a subtle glow. Labels must always be visible above the input field.

### Cards
- **Product Cards:** White background, 16px radius, soft shadow. Should include a large product image, name in `label-lg`, and price in Primary Blue.
- **Dosage Cards:** Subtle blue border, uses `body-md` for clear instructions (e.g., "Uống sau khi ăn").

### Chips & Badges
- Used for categories (e.g., "Thực phẩm chức năng", "Chăm sóc cá nhân"). Pill-shaped with a light tint of the primary color and dark text.

### Prescription Upload
- A specialized component: a large dashed-border area with a soft blue background and a prominent camera icon to encourage users to upload their prescriptions.

### Iconography
- Use rounded, 2px stroke-width icons. Icons should be monochrome (Primary Blue) unless they represent a status (e.g., green for 'In Stock').