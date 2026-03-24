---
name: driverjs-guide
description: Complete reference for implementing Driver.js (driver.js) product tours, element highlighting, onboarding flows, and contextual help overlays. Use this skill whenever the user mentions "driver.js", "driverjs", "product tour", "onboarding tour", "guided tour", "element highlighting", "walkthrough", "feature introduction", "spotlight overlay", or asks to build step-by-step user guides, interactive walkthroughs, or highlight-and-explain UI flows in web applications. Also trigger when the user wants to add tooltips that walk users through a page, create async/dynamic tours, or implement "turn off the lights" focus effects. Do NOT use for unrelated tooltip libraries (Tippy.js, Floating UI) or for general CSS overlay questions that don't involve guided tours.
---

# Driver.js Complete Reference

Driver.js is a lightweight (~5kb gzipped), dependency-free, vanilla TypeScript library for guiding user focus across a web page. It draws an SVG overlay and cuts out a portion above the highlighted element, avoiding z-index and stacking-context issues entirely.

Use cases beyond product tours: contextual form help, feature announcements, focus-shifting overlays, simple modals, and "turn off the lights" effects.

Documentation source: https://driverjs.com

---

## Pre-flight: Project Dependency Check

Before writing any Driver.js code, check whether the current project already has `driver.js` installed:

1. **Check package.json** — Use Grep to search for `"driver.js"` in `package.json` (both `dependencies` and `devDependencies`).
2. **Check lock file** — If no match in `package.json`, also check `package-lock.json`, `yarn.lock`, or `pnpm-lock.yaml` for `driver.js`.
3. **Check existing imports** — Use Grep to search for `from "driver.js"` or `from 'driver.js'` across the codebase to see if it is already in use.

Based on results:
- **Already installed and imported:** Note the installed version. Skip installation instructions. Look at existing usage patterns in the project and follow the same conventions (import style, CSS import location, instance management).
- **Installed but not yet imported:** Skip installation. Proceed with usage guidance, matching the project's existing import conventions.
- **Not installed:** Include the appropriate install command for the project's package manager (check for `yarn.lock`, `pnpm-lock.yaml`, or default to `npm`).

---

## Installation

### Package manager

```bash
# npm
npm install driver.js

# pnpm
pnpm install driver.js

# yarn
yarn add driver.js
```

### CDN

```html
<script src="https://cdn.jsdelivr.net/npm/driver.js@latest/dist/driver.js.iife.js"></script>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/driver.js@latest/dist/driver.css"/>
```

### Import (ES modules)

```js
import { driver } from "driver.js";
import "driver.js/dist/driver.css";
```

The CSS import is required for default popover and overlay styling.

---

## Basic Usage

### Multi-step tour

```js
import { driver } from "driver.js";
import "driver.js/dist/driver.css";

const driverObj = driver({
  showProgress: true,
  steps: [
    { element: '.page-header', popover: { title: 'Title', description: 'Description' } },
    { element: '.top-nav', popover: { title: 'Title', description: 'Description' } },
    { element: '.sidebar', popover: { title: 'Title', description: 'Description' } },
    { element: '.footer', popover: { title: 'Title', description: 'Description' } },
  ]
});

driverObj.drive();
```

### Single element highlight

```js
const driverObj = driver();
driverObj.highlight({
  element: '#some-element',
  popover: {
    title: 'Title for the Popover',
    description: 'Description for it',
  },
});
```

### Floating popover (no element)

Omit the `element` property entirely to show a centered popover with no highlight cutout:

```js
driverObj.highlight({
  popover: {
    title: 'Welcome!',
    description: 'Let us show you around.',
  }
});
```

This also works as a step in a tour (just omit `element` from that step object).

---

## Configuration Reference

Driver.js has three configuration layers that can be combined:

1. **Driver config** -- global defaults passed to `driver({...})`
2. **Popover config** -- UI content and positioning per step
3. **DriveStep config** -- per-step element targeting and hooks

Step-level settings override driver-level settings for that step.

### Driver Configuration (global)

```ts
type Config = {
  steps?: DriveStep[];

  // Animation and scrolling
  animate?: boolean;                // default: true
  smoothScroll?: boolean;           // default: false

  // Overlay appearance
  overlayColor?: string;            // default: "black" (any CSS color)
  overlayOpacity?: number;          // default: 0.5

  // Overlay behavior
  allowClose?: boolean;             // default: true (close on backdrop click or Esc)
  overlayClickBehavior?: "close" | "nextStep"
    | ((element?: Element, step: DriveStep, options: { config: Config; state: State; driver: Driver }) => void);
    // default: "close"

  // Highlight cutout
  stagePadding?: number;            // default: 10 (px between element and cutout edge)
  stageRadius?: number;             // default: 5 (border-radius of cutout)

  // Keyboard
  allowKeyboardControl?: boolean;   // default: true (arrow keys, Esc)

  // Interaction
  disableActiveInteraction?: boolean; // default: false (if true, blocks clicks on highlighted element)

  // Popover defaults (can be overridden per step)
  popoverClass?: string;
  popoverOffset?: number;           // default: 10 (px gap between popover and element)
  showButtons?: AllowedButtons[];   // default: ["next","previous","close"] for tours, [] for highlight
  disableButtons?: AllowedButtons[];
  showProgress?: boolean;           // default: false
  progressText?: string;            // default: "{{current}} of {{total}}"
  nextBtnText?: string;
  prevBtnText?: string;
  doneBtnText?: string;             // shown on last step instead of nextBtnText

  // Hooks (all receive: element?, step, { config, state, driver })
  onPopoverRender?: (popover: PopoverDOM, options) => void;
  onHighlightStarted?: (element?, step, options) => void;
  onHighlighted?: (element?, step, options) => void;
  onDeselected?: (element?, step, options) => void;
  onDestroyStarted?: (element?, step, options) => void;
  onDestroyed?: (element?, step, options) => void;
  onNextClick?: (element?, step, options) => void;
  onPrevClick?: (element?, step, options) => void;
  onCloseClick?: (element?, step, options) => void;
};
```

**Critical behavior note on `onNextClick` / `onPrevClick`:** When you override these hooks, the default navigation is disabled. You MUST call `driverObj.moveNext()` or `driverObj.movePrevious()` yourself inside the handler, otherwise the buttons will appear to do nothing.

Same applies to `onCloseClick` -- you must call `driverObj.destroy()` yourself.

These hooks can be set at driver level (applies to all steps) or at step level (applies to that step only). Step-level overrides take precedence.

### Popover Configuration (per step or global)

```ts
type Popover = {
  title?: string;                   // supports HTML
  description?: string;             // supports HTML

  // Positioning
  side?: "top" | "right" | "bottom" | "left";
  align?: "start" | "center" | "end";

  // Buttons
  showButtons?: ("next" | "previous" | "close")[];
  disableButtons?: ("next" | "previous" | "close")[];
  nextBtnText?: string;
  prevBtnText?: string;
  doneBtnText?: string;

  // Progress
  showProgress?: boolean;
  progressText?: string;            // "{{current}} of {{total}}"

  // Styling
  popoverClass?: string;

  // Hooks
  onPopoverRender?: (popover: PopoverDOM, options) => void;
  onNextClick?: (element?, step, options) => void;
  onPrevClick?: (element?, step, options) => void;
  onCloseClick?: (element?, step, options) => void;
};
```

**Popover auto-positioning:** The popover automatically repositions itself if it does not fit in the viewport with the specified `side`/`align`. You do not need to handle edge cases manually.

### DriveStep Configuration (per step)

```ts
type DriveStep = {
  element?: Element | string | (() => Element);
  // CSS selector (first match), DOM element, or function returning one.
  // Omit for a floating popover with no highlight.

  popover?: Popover;

  disableActiveInteraction?: boolean; // default: false

  // Per-step hooks
  onDeselected?: (element?, step, options) => void;
  onHighlightStarted?: (element?, step, options) => void;
  onHighlighted?: (element?, step, options) => void;
};
```

### State Object

Accessible via `driverObj.getState()` and passed to all hooks:

```ts
type State = {
  isInitialized?: boolean;
  activeIndex?: number;
  activeElement?: Element;
  activeStep?: DriveStep;
  previousElement?: Element;
  previousStep?: DriveStep;
  popover?: PopoverDOM;
};
```

### PopoverDOM Object

Passed to `onPopoverRender`. Use it to manipulate the popover before display:

```ts
type PopoverDOM = {
  wrapper: HTMLElement;
  arrow: HTMLElement;
  title: HTMLElement;
  description: HTMLElement;
  footer: HTMLElement;
  progress: HTMLElement;
  previousButton: HTMLElement;
  nextButton: HTMLElement;
  closeButton: HTMLElement;
  footerButtons: HTMLElement;
};
```

---

## API Methods

```js
const driverObj = driver({ /* config */ });

// Tour navigation
driverObj.drive();          // start from step 0
driverObj.drive(4);         // start from step 4
driverObj.moveNext();
driverObj.movePrevious();
driverObj.moveTo(4);

// Tour state queries
driverObj.hasNextStep();
driverObj.hasPreviousStep();
driverObj.isFirstStep();
driverObj.isLastStep();
driverObj.getActiveIndex();
driverObj.getActiveStep();
driverObj.getPreviousStep();
driverObj.getActiveElement();
driverObj.getPreviousElement();
driverObj.isActive();

// Runtime mutations
driverObj.refresh();                  // recalculate highlight position (useful after DOM changes)
driverObj.setConfig({ /* ... */ });   // update config on the fly
driverObj.getConfig();
driverObj.setSteps([ /* ... */ ]);    // replace steps array

// State
driverObj.getState();

// Single highlight (same DriveStep format)
driverObj.highlight({ element: '#el', popover: { title: '...' } });

// Teardown
driverObj.destroy();
```

---

## Theming and Styling

### CSS classes on the page

```css
/* Body classes while driver is active */
.driver-active {}     /* always present when active */
.driver-fade {}       /* when animate: true */
.driver-simple {}     /* when animate: false */

/* Overlay */
.driver-overlay {}

/* Highlighted element */
.driver-active-element {}
```

### Popover CSS classes

```css
.driver-popover {}
.driver-popover-arrow {}
.driver-popover-title {}
.driver-popover-description {}
.driver-popover-close-btn {}
.driver-popover-footer {}
.driver-popover-progress-text {}
.driver-popover-prev-btn {}
.driver-popover-next-btn {}
```

### Arrow color classes (for custom backgrounds)

When you change the popover background color, you must also update the arrow border color to match. The arrow side is indicated by a class:

```css
.driver-popover-arrow-side-left.driver-popover-arrow   { border-left-color: #yourColor; }
.driver-popover-arrow-side-right.driver-popover-arrow  { border-right-color: #yourColor; }
.driver-popover-arrow-side-top.driver-popover-arrow    { border-top-color: #yourColor; }
.driver-popover-arrow-side-bottom.driver-popover-arrow { border-bottom-color: #yourColor; }
```

### Custom theme example

Apply a custom class via `popoverClass`, then scope your CSS under it:

```js
const driverObj = driver({
  popoverClass: 'my-theme'
});
```

```css
.driver-popover.my-theme {
  background-color: #fde047;
  color: #000;
}
.driver-popover.my-theme .driver-popover-title {
  font-size: 20px;
}
.driver-popover.my-theme button {
  background-color: #000;
  color: #fff;
  border: 2px solid #000;
  border-radius: 6px;
  padding: 5px 8px;
  font-size: 14px;
  text-shadow: none;
}
.driver-popover.my-theme .driver-popover-close-btn {
  color: #9b9b9b;
}
.driver-popover.my-theme .driver-popover-close-btn:hover {
  color: #000;
}
.driver-popover.my-theme .driver-popover-navigation-btns {
  justify-content: space-between;
  gap: 3px;
}
/* Match arrow color to background */
.driver-popover.my-theme .driver-popover-arrow-side-left.driver-popover-arrow { border-left-color: #fde047; }
.driver-popover.my-theme .driver-popover-arrow-side-right.driver-popover-arrow { border-right-color: #fde047; }
.driver-popover.my-theme .driver-popover-arrow-side-top.driver-popover-arrow { border-top-color: #fde047; }
.driver-popover.my-theme .driver-popover-arrow-side-bottom.driver-popover-arrow { border-bottom-color: #fde047; }
```

### Modifying popover DOM via hook

For changes beyond CSS (adding elements, restructuring), use `onPopoverRender`:

```js
const driverObj = driver({
  onPopoverRender: (popover, { config, state }) => {
    const btn = document.createElement("button");
    btn.innerText = "Go to First";
    popover.footerButtons.appendChild(btn);
    btn.addEventListener("click", () => driverObj.drive(0));
  },
  steps: [/* ... */]
});
```

---

## Patterns and Recipes

### Animated tour (default)

```js
const driverObj = driver({
  showProgress: true,
  steps: [
    { element: '.header', popover: { title: 'Header', description: 'This is your app header.', side: 'left', align: 'start' } },
    { element: '.sidebar', popover: { title: 'Sidebar', description: 'Navigate here.', side: 'right', align: 'start' } },
    { popover: { title: 'Done!', description: 'You are all set.' } }
  ]
});
driverObj.drive();
```

### Static (non-animated) tour

Set `animate: false` to disable the smooth transition between steps:

```js
const driverObj = driver({
  animate: false,
  showProgress: false,
  showButtons: ['next', 'previous', 'close'],
  steps: [/* ... */]
});
driverObj.drive();
```

### Show tour progress

```js
const driverObj = driver({
  showProgress: true,
  // Optional custom template:
  progressText: 'Step {{current}} of {{total}}',
  steps: [/* ... */]
});
```

### Async / dynamic tour (load elements on the fly)

Override `onNextClick` at the step level to fetch data or render DOM before proceeding. You MUST call `driverObj.moveNext()` yourself:

```js
const driverObj = driver({
  showProgress: true,
  steps: [
    {
      popover: {
        title: 'Step 1',
        description: 'Next element will be loaded dynamically.',
        onNextClick: () => {
          // Load or render the element dynamically here
          const el = document.createElement('div');
          el.className = 'dynamic-el';
          el.textContent = 'I was loaded async!';
          document.body.appendChild(el);
          driverObj.moveNext();
        },
      },
    },
    {
      element: '.dynamic-el',
      popover: { title: 'Async Element', description: 'This was loaded dynamically.' },
      onDeselected: () => {
        document.querySelector('.dynamic-el')?.remove();
      }
    },
    { popover: { title: 'Last Step', description: 'Tour complete.' } }
  ]
});
driverObj.drive();
```

### Confirm before exit

Use `onDestroyStarted` to intercept exit attempts. You are responsible for calling `driverObj.destroy()`:

```js
const driverObj = driver({
  steps: [/* ... */],
  onDestroyStarted: () => {
    if (!driverObj.hasNextStep() || confirm("Are you sure you want to exit?")) {
      driverObj.destroy();
    }
  },
});
driverObj.drive();
```

### Prevent exit entirely

Set `allowClose: false` to block backdrop clicks and Esc key. The user must complete the tour:

```js
const driverObj = driver({
  allowClose: false,
  steps: [/* ... */]
});
driverObj.drive();
```

### Overlay color and opacity

```js
const driverObj = driver({
  overlayColor: 'red',     // any CSS color string
  overlayOpacity: 0.7,
});
driverObj.highlight({
  element: '#target',
  popover: { title: 'Red overlay', description: 'Custom color backdrop.' }
});
```

### Popover positioning

Control with `side` and `align` on each step's popover:

- `side`: "top" | "right" | "bottom" | "left"
- `align`: "start" | "center" | "end"

12 combinations total. The popover auto-adjusts if it overflows the viewport.

```js
driverObj.highlight({
  element: '#el',
  popover: {
    title: 'Positioned',
    description: 'Bottom-start placement.',
    side: 'bottom',
    align: 'start'
  }
});
```

### Button configuration

```js
// Show specific buttons
driver({ showButtons: ['next', 'previous'] });  // no close button

// Disable specific buttons
driver({ disableButtons: ['previous'] });        // previous visible but grayed out

// Custom button text
driver({
  nextBtnText: '-->',
  prevBtnText: '<--',
  doneBtnText: 'Finish',
});

// Completely custom buttons via onPopoverRender
driver({
  onPopoverRender: (popover, { config, state }) => {
    const btn = document.createElement("button");
    btn.innerText = "Go to First";
    popover.footerButtons.appendChild(btn);
    btn.addEventListener("click", () => driverObj.drive(0));
  },
  steps: [/* ... */]
});
```

### Contextual form help (highlight on focus)

```js
const driverObj = driver({
  popoverClass: 'form-help-theme',
  stagePadding: 0,
  onDestroyed: () => document?.activeElement?.blur(),
});

document.getElementById('name').addEventListener('focus', () => {
  driverObj.highlight({
    element: '#name',
    popover: { title: 'Name', description: 'Enter your full name.' },
  });
});

document.getElementById('email').addEventListener('focus', () => {
  driverObj.highlight({
    element: '#email',
    popover: { title: 'Email', description: 'We will send a confirmation here.' },
  });
});
```

### HTML in popover content

Both `title` and `description` accept raw HTML:

```js
driverObj.highlight({
  popover: {
    description: '<img src="https://example.com/demo.gif" style="width:270px;" /><p>Watch the demo above.</p>',
  }
});
```

### Advance tour on overlay click (instead of close)

```js
const driverObj = driver({
  overlayClickBehavior: 'nextStep',
  steps: [/* ... */]
});
```

Or pass a custom function:

```js
overlayClickBehavior: (element, step, { config, state, driver }) => {
  // Custom logic on backdrop click
  console.log('Backdrop clicked on step', state.activeIndex);
}
```

### Using `element` as a function

Useful when the target element is rendered conditionally or changes between renders:

```js
{
  element: () => document.querySelector('.dynamic-class'),
  popover: { title: 'Dynamic', description: 'Element resolved at render time.' }
}
```

### Recalculate after DOM changes

If the highlighted element moves or resizes (e.g., after an accordion opens), call:

```js
driverObj.refresh();
```

### Update config or steps at runtime

```js
driverObj.setConfig({ animate: false });
driverObj.setSteps([
  { element: '#new-step', popover: { title: 'New', description: 'Replaced steps.' } }
]);
```

---

## Framework Integration Notes

Driver.js is vanilla TypeScript with zero dependencies. It works in any framework.

### React

Trigger tours inside `useEffect` or event handlers. Make sure the target elements are mounted before calling `drive()`:

```jsx
import { useEffect } from 'react';
import { driver } from 'driver.js';
import 'driver.js/dist/driver.css';

function App() {
  useEffect(() => {
    const driverObj = driver({
      steps: [
        { element: '#step1', popover: { title: 'Welcome', description: 'Start here.' } },
        { element: '#step2', popover: { title: 'Next', description: 'Then here.' } },
      ]
    });
    driverObj.drive();
    return () => driverObj.destroy();
  }, []);

  return (
    <div>
      <div id="step1">First</div>
      <div id="step2">Second</div>
    </div>
  );
}
```

### Vue

Use `onMounted` lifecycle hook:

```vue
<script setup>
import { onMounted, onUnmounted } from 'vue';
import { driver } from 'driver.js';
import 'driver.js/dist/driver.css';

let driverObj;
onMounted(() => {
  driverObj = driver({ steps: [/* ... */] });
  driverObj.drive();
});
onUnmounted(() => driverObj?.destroy());
</script>
```

### Important: cleanup

Always call `driverObj.destroy()` on component unmount to remove the overlay and event listeners.

---

## Common Pitfalls

1. **Buttons do nothing after overriding `onNextClick`/`onPrevClick`:** You must manually call `driverObj.moveNext()` or `driverObj.movePrevious()` inside your handler. The override disables default navigation entirely.

2. **Tour does not close after overriding `onDestroyStarted`:** You must call `driverObj.destroy()` yourself inside the handler.

3. **Popover arrow color mismatch:** When changing popover background via `popoverClass`, also set the matching `border-*-color` on the arrow side classes (see Theming section).

4. **Element not found:** If the CSS selector matches no element, that step will show a floating popover instead of highlighting. Use a function for `element` if the DOM is dynamic.

5. **Stale highlight position:** After layout shifts (accordion, tab switch, resize), call `driverObj.refresh()` to recalculate.

6. **CSS not loading:** You must import `driver.js/dist/driver.css` (or include the CDN link). Without it, the overlay and popover will not render correctly.

7. **Multiple driver instances:** Only one driver should be active at a time. Call `destroy()` on the previous instance before creating a new one.
