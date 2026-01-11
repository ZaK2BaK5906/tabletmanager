# MDT PREMIUM - DESIGN SYSTEM

## 🎨 COULEURS

### Primary Palette
```css
--primary-50: #EFF6FF;
--primary-100: #DBEAFE;
--primary-200: #BFDBFE;
--primary-300: #93C5FD;
--primary-400: #60A5FA;
--primary-500: #3B82F6;  /* Main */
--primary-600: #2563EB;
--primary-700: #1D4ED8;
--primary-800: #1E40AF;
--primary-900: #1E3A8A;
```

### Dark Mode (Base)
```css
--bg-primary: #0A0E1A;      /* Background principal */
--bg-secondary: #111827;    /* Cards, panels */
--bg-tertiary: #1F2937;     /* Hover states */
--bg-glass: rgba(17, 24, 39, 0.85);  /* Glassmorphism */
```

### Text Colors
```css
--text-primary: #F9FAFB;    /* Texte principal */
--text-secondary: #9CA3AF;  /* Texte secondaire */
--text-muted: #6B7280;      /* Texte désactivé */
```

### Borders & Dividers
```css
--border-default: #374151;
--border-light: #4B5563;
--divider: rgba(75, 85, 99, 0.3);
```

### Status Colors
```css
--success: #10B981;     /* Payé, validé */
--warning: #F59E0B;     /* En attente */
--danger: #EF4444;      /* Refusé, impayé */
--info: #06B6D4;        /* Info */
```

### Glassmorphism
```css
backdrop-filter: blur(20px) saturate(180%);
-webkit-backdrop-filter: blur(20px) saturate(180%);
background: rgba(17, 24, 39, 0.85);
border: 1px solid rgba(75, 85, 99, 0.3);
```

## 📝 TYPOGRAPHIE

### Font Family
```css
font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
```

### Font Sizes
```css
--text-xs: 0.75rem;    /* 12px */
--text-sm: 0.875rem;   /* 14px */
--text-base: 1rem;     /* 16px */
--text-lg: 1.125rem;   /* 18px */
--text-xl: 1.25rem;    /* 20px */
--text-2xl: 1.5rem;    /* 24px */
--text-3xl: 1.875rem;  /* 30px */
--text-4xl: 2.25rem;   /* 36px */
```

### Font Weights
```css
--font-light: 300;
--font-normal: 400;
--font-medium: 500;
--font-semibold: 600;
--font-bold: 700;
```

### Line Heights
```css
--leading-tight: 1.25;
--leading-normal: 1.5;
--leading-relaxed: 1.75;
```

## 🎯 SPACING SYSTEM

```css
--space-1: 0.25rem;   /* 4px */
--space-2: 0.5rem;    /* 8px */
--space-3: 0.75rem;   /* 12px */
--space-4: 1rem;      /* 16px */
--space-5: 1.25rem;   /* 20px */
--space-6: 1.5rem;    /* 24px */
--space-8: 2rem;      /* 32px */
--space-10: 2.5rem;   /* 40px */
--space-12: 3rem;     /* 48px */
--space-16: 4rem;     /* 64px */
```

## 🔘 BORDER RADIUS

```css
--radius-sm: 0.375rem;   /* 6px */
--radius-md: 0.5rem;     /* 8px */
--radius-lg: 0.75rem;    /* 12px */
--radius-xl: 1rem;       /* 16px */
--radius-2xl: 1.5rem;    /* 24px */
--radius-full: 9999px;   /* Circle */
```

## ✨ SHADOWS

```css
--shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
--shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
--shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.2);
--shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.3);
--shadow-2xl: 0 25px 50px -12px rgba(0, 0, 0, 0.4);
--shadow-glow: 0 0 20px rgba(59, 130, 246, 0.5);
```

## 🎭 ANIMATIONS

### Transitions
```css
--transition-fast: 150ms cubic-bezier(0.4, 0, 0.2, 1);
--transition-base: 200ms cubic-bezier(0.4, 0, 0.2, 1);
--transition-slow: 300ms cubic-bezier(0.4, 0, 0.2, 1);
```

### Keyframes
```css
@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes slideInRight {
  from { transform: translateX(100%); }
  to { transform: translateX(0); }
}

@keyframes slideInLeft {
  from { transform: translateX(-100%); }
  to { transform: translateX(0); }
}

@keyframes scaleIn {
  from { transform: scale(0.95); opacity: 0; }
  to { transform: scale(1); opacity: 1; }
}
```

## 📦 COMPOSANTS RÉUTILISABLES

### 1. Button
- **Variants**: primary, secondary, danger, ghost, link
- **Sizes**: sm, md, lg
- **States**: default, hover, active, disabled, loading

### 2. Card
- **Types**: default, glass, elevated
- **Padding**: sm, md, lg
- **Border**: yes/no

### 3. Modal
- **Sizes**: sm (400px), md (600px), lg (800px), xl (1000px)
- **Animations**: fadeIn + scaleIn
- **Backdrop**: dark blur

### 4. Table
- **Features**: pagination, sorting, filters, search
- **Row states**: hover, selected
- **Responsive**: scroll horizontal mobile

### 5. Badge
- **Variants**: success, warning, danger, info, default
- **Sizes**: sm, md, lg

### 6. Input
- **Types**: text, number, textarea, select, date
- **States**: default, focus, error, disabled
- **Icons**: leading, trailing

### 7. Tabs
- **Styles**: underline, pills, boxed
- **Animation**: slide indicator

### 8. Toast/Alert
- **Types**: success, warning, error, info
- **Position**: top-right, top-center, bottom-right
- **Auto-dismiss**: 3s, 5s, manual

### 9. Drawer/Sidebar
- **Position**: left, right
- **Size**: 280px (default), 320px (wide)
- **Overlay**: yes/no

### 10. Dropdown
- **Trigger**: click, hover
- **Position**: bottom, top, left, right
- **Animation**: fadeIn + slideIn

## 🖥️ LAYOUT STRUCTURE

```
┌─────────────────────────────────────────┐
│  Topbar (64px)                          │
│  [Company] [Grade] [Balance] [Search]   │
├─────┬───────────────────────────────────┤
│     │                                   │
│ S   │  Main Content Area                │
│ I   │                                   │
│ D   │  Dashboard / Factures / etc.      │
│ E   │                                   │
│ B   │                                   │
│ A   │                                   │
│ R   │                                   │
│     │                                   │
│(64) │                                   │
└─────┴───────────────────────────────────┘
```

### Sidebar Icons
1. 📊 Dashboard
2. 📄 Factures
3. 👥 Employés
4. 💰 Taxes & DOJ
5. 💵 Commissions
6. 🚗 Concession
7. ⚖️ DOJ (si grade DOJ)

## 📱 RESPONSIVE BREAKPOINTS

```css
--mobile: 640px;
--tablet: 768px;
--laptop: 1024px;
--desktop: 1280px;
```

**Tablette optimized**: 1024x768 (4:3) et 1920x1080 (16:9)

## 🎨 EXEMPLE CARTE PREMIUM

```jsx
<div className="card-glass">
  <div className="card-header">
    <h3 className="card-title">Titre</h3>
    <Badge variant="success">Actif</Badge>
  </div>
  <div className="card-body">
    Contenu
  </div>
  <div className="card-footer">
    <Button variant="primary">Action</Button>
  </div>
</div>
```

```css
.card-glass {
  background: var(--bg-glass);
  backdrop-filter: blur(20px);
  border: 1px solid var(--border-default);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-lg);
  transition: var(--transition-base);
}

.card-glass:hover {
  box-shadow: var(--shadow-xl);
  transform: translateY(-2px);
}
```

## 🚀 PERFORMANCE OPTIMIZATIONS

- Lazy load pages (React.lazy)
- Debounce search (300ms)
- Virtual scrolling pour tables >100 rows
- Memoize components (React.memo)
- Use Zustand for state (pas Redux)
- Images optimized (WebP)
- CSS-in-JS évité (Tailwind only)

## ✅ ACCESSIBILITÉ

- Focus visible (ring-2 ring-primary-500)
- ARIA labels sur icônes
- Keyboard navigation (Tab, Enter, Esc)
- Color contrast ratio > 4.5:1
- Screen reader friendly

---

**NEXT STEPS**: Créer les maquettes HTML des écrans principaux avec ce design system.
