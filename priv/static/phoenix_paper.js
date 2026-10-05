// PhoenixPaper — the LiveView hook.
//
// Part of PhoenixPaper's setup: components render phx-hook="PhoenixPaper"
// (wherever they have an id), and this hook adds the M3 Expressive
// behaviors CSS can't do, or can't do in every browser:
//
//   - Tabs: the active indicator slides from the old tab to the new one.
//   - TopAppBar: `data-pp-scrolled` while content is scrolled under it
//     (browsers without CSS scroll-driven animations, e.g. Firefox).
//   - LoadingIndicator: morphs its shape in JS (browsers that can't
//     animate SVG `d` in CSS, e.g. Safari).
//   - BottomSheet: drag the handle down to dismiss.
//   - Carousel: the Expressive item mask (browsers without `view()`
//     scroll timelines).
//   - TimePicker: drag the dial's hand, to any hour or exact minute.
//   - Menus, submenus and tooltips: flip to the other side when they'd
//     overflow the viewport.
//
// Every component still renders and works without it running (on
// controller-rendered pages, before LiveView connects); the hook only
// adds the behaviors above.
//
// Setup (Phoenix 1.8 esbuild resolves `deps/` packages by name):
//
//   // assets/js/app.js
//   import PhoenixPaperHooks from "phoenix_paper"
//   const liveSocket = new LiveSocket("/live", Socket, {
//     hooks: {...PhoenixPaperHooks, ...yourHooks},
//     ...
//   })
//
// One hook name, `PhoenixPaper`, dispatching on what it's mounted on.

const prefersReducedMotion = () =>
  window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches

// The expressive fast spatial spring as a CSS easing, read from the theme
// so `data-pp-motion="standard"` is respected too.
const spring = (el) => {
  const s = getComputedStyle(el)
  return {
    easing: s.getPropertyValue("--pp-spring-spatial-fast").trim() || "cubic-bezier(0.2, 0, 0, 1)",
    duration: s.getPropertyValue("--pp-spring-spatial-fast-duration").trim() || "350ms",
  }
}

// ---------------------------------------------------------------- Tabs

const visibleIndicator = (tab) =>
  Array.from(tab.querySelectorAll("[data-pp-tab-indicator]")).find(
    (el) => getComputedStyle(el).display !== "none"
  )

const Tabs = {
  mount(hook) {
    const el = hook.el
    let current = el.querySelector('[role="tab"][aria-selected="true"]')

    hook.observer = new MutationObserver(() => {
      const next = el.querySelector('[role="tab"][aria-selected="true"]')
      if (!next || next === current) return
      const from = current && visibleIndicator(current)
      const to = visibleIndicator(next)
      current = next
      if (!from || !to || prefersReducedMotion()) return

      const a = from.getBoundingClientRect()
      const b = to.getBoundingClientRect()
      if (!b.width) return
      const {easing, duration} = spring(el)

      to.style.transition = "none"
      to.style.transformOrigin = "left center"
      to.style.transform = `translateX(${a.left - b.left}px) scaleX(${a.width / b.width})`
      to.getBoundingClientRect()
      to.style.transition = `transform ${duration} ${easing}`
      to.style.transform = ""
    })

    hook.observer.observe(el, {subtree: true, attributes: true, attributeFilter: ["aria-selected"]})
  },
  destroy(hook) {
    hook.observer && hook.observer.disconnect()
  },
}

// --------------------------------------------------------- Top app bar

const scrollParent = (el) => {
  for (let p = el.parentElement; p; p = p.parentElement) {
    const o = getComputedStyle(p).overflowY
    if ((o === "auto" || o === "scroll") && p.scrollHeight > p.clientHeight) return p
  }
  return window
}

const TopAppBar = {
  mount(hook) {
    const target = scrollParent(hook.el)
    hook.scrollTarget = target
    hook.onScroll = () => {
      const y = target === window ? window.scrollY : target.scrollTop
      hook.el.toggleAttribute("data-pp-scrolled", y > 0)
    }
    target.addEventListener("scroll", hook.onScroll, {passive: true})
    hook.onScroll()
  },
  update(hook) {
    hook.onScroll && hook.onScroll()
  },
  destroy(hook) {
    hook.scrollTarget && hook.scrollTarget.removeEventListener("scroll", hook.onScroll)
  },
}

// --------------------------------------------------- Loading indicator
//
// The same seven shapes as the CSS keyframes in phoenix_paper.css: 72
// points sampled from a polar function, so any two interpolate.

const N = 72
const C = 24
const R = 19

const lobes = (k, amp) => (t) => (1 + amp * Math.cos(k * t)) / (1 + amp)
const superellipse = (a, b, n, rot) => (t) => {
  const c = Math.abs(Math.cos(t - rot))
  const s = Math.abs(Math.sin(t - rot))
  return 1 / Math.pow(Math.pow(c / a, n) + Math.pow(s / b, n), 1 / n)
}

const SHAPES = [
  lobes(10, 0.1),
  lobes(9, 0.07),
  lobes(5, 0.1),
  superellipse(1, 0.56, 2.8, Math.PI / 4),
  lobes(8, 0.06),
  lobes(4, 0.12),
  superellipse(1, 0.74, 2, -Math.PI / 4),
].map((f) =>
  Array.from({length: N}, (_, i) => {
    const t = (2 * Math.PI * i) / N
    const r = R * f(t)
    return [C + r * Math.sin(t), C - r * Math.cos(t)]
  })
)

const toPath = (pts) =>
  "M" + pts.map(([x, y]) => `${x.toFixed(2)} ${y.toFixed(2)}`).join(" L") + " Z"

// Critically-damped-ish spring with a little overshoot (expressive fast
// spatial: damping 0.6, stiffness 800), sampled over the step duration.
const springStep = (t) => {
  const w = Math.sqrt(800)
  const z = 0.6
  const wd = w * Math.sqrt(1 - z * z)
  const s = t * 0.35
  return 1 - Math.exp(-z * w * s) * (Math.cos(wd * s) + ((z * w) / wd) * Math.sin(wd * s))
}

const LoadingIndicator = {
  mount(hook) {
    const path = hook.el.querySelector("path")
    if (!path || prefersReducedMotion()) return
    path.style.animation = "none"
    const step = 650
    let start = null

    const frame = (now) => {
      if (start === null) start = now
      const elapsed = now - start
      const i = Math.floor(elapsed / step) % SHAPES.length
      const t = springStep(Math.min((elapsed % step) / step, 1))
      const a = SHAPES[i]
      const b = SHAPES[(i + 1) % SHAPES.length]
      path.setAttribute("d", toPath(a.map(([x, y], k) => [x + (b[k][0] - x) * t, y + (b[k][1] - y) * t])))
      hook.raf = requestAnimationFrame(frame)
    }

    hook.raf = requestAnimationFrame(frame)
  },
  destroy(hook) {
    hook.raf && cancelAnimationFrame(hook.raf)
  },
}

// --------------------------------------------------------- Bottom sheet
//
// Mounted on the sheet's drag handle. Dragging moves the sheet; releasing
// past 30% of its height (or flicking) dismisses it by running the
// handle's own phx-click (the sheet's cancel), otherwise it springs back.
// The click that follows a drag is swallowed so a short drag doesn't
// dismiss.

const BottomSheetHandle = {
  mount(hook) {
    const handle = hook.el
    const sheet = handle.closest("[data-pp-sheet]")
    if (!sheet) return
    let startY = null
    let lastY = 0
    let lastT = 0
    let velocity = 0
    let dragged = false

    const onDown = (e) => {
      startY = e.clientY
      lastY = e.clientY
      lastT = e.timeStamp
      dragged = false
      sheet.style.transition = "none"
      handle.setPointerCapture(e.pointerId)
    }

    const onMove = (e) => {
      if (startY === null) return
      const dy = Math.max(0, e.clientY - startY)
      if (dy > 4) dragged = true
      velocity = (e.clientY - lastY) / Math.max(e.timeStamp - lastT, 1)
      lastY = e.clientY
      lastT = e.timeStamp
      sheet.style.transform = `translateY(${dy}px)`
    }

    const onUp = (e) => {
      if (startY === null) return
      const dy = Math.max(0, e.clientY - startY)
      startY = null
      const {easing, duration} = spring(sheet)

      if (dy > sheet.offsetHeight * 0.3 || velocity > 0.8) {
        sheet.style.transition = "transform 200ms cubic-bezier(0.3, 0, 0.8, 0.15)"
        sheet.style.transform = "translateY(100%)"
        setTimeout(() => {
          hook.liveSocket.execJS(handle, handle.getAttribute("phx-click"))
          setTimeout(() => {
            sheet.style.transition = ""
            sheet.style.transform = ""
          }, 300)
        }, 200)
      } else {
        sheet.style.transition = `transform ${duration} ${easing}`
        sheet.style.transform = ""
      }
    }

    const onClick = (e) => {
      if (dragged) {
        e.preventDefault()
        e.stopImmediatePropagation()
        dragged = false
      }
    }

    handle.addEventListener("pointerdown", onDown)
    handle.addEventListener("pointermove", onMove)
    handle.addEventListener("pointerup", onUp)
    handle.addEventListener("pointercancel", onUp)
    handle.addEventListener("click", onClick, true)
  },
}

// ------------------------------------------------------------- Carousel

const supportsViewTimeline = () =>
  window.CSS && CSS.supports && CSS.supports("animation-timeline: view()")

const Carousel = {
  mount(hook) {
    if (supportsViewTimeline()) return
    const track = hook.el.querySelector("[data-pp-carousel-track]")
    if (!track || hook.el.dataset.ppLayout === "uncontained" || hook.el.dataset.ppLayout === "full_screen") return

    hook.onScroll = () => {
      const t = track.getBoundingClientRect()
      track.querySelectorAll("[data-pp-carousel-item]").forEach((item) => {
        const r = item.getBoundingClientRect()
        // 0 = entering at the end edge, 1 = fully left at the start edge.
        const p = Math.min(Math.max((t.right - r.left) / (t.width + r.width), 0), 1)
        let left = 0
        let right = 0
        if (p < 0.28) left = 72 * (1 - p / 0.28)
        if (p > 0.72) right = 72 * ((p - 0.72) / 0.28)
        item.style.clipPath = `inset(0 ${right}% 0 ${left}% round var(--radius-pp-xl))`
      })
    }

    track.addEventListener("scroll", hook.onScroll, {passive: true})
    window.addEventListener("resize", hook.onScroll)
    hook.track = track
    hook.onScroll()
  },
  update(hook) {
    hook.onScroll && hook.onScroll()
  },
  destroy(hook) {
    if (hook.track) hook.track.removeEventListener("scroll", hook.onScroll)
    if (hook.onScroll) window.removeEventListener("resize", hook.onScroll)
  },
}

// ---------------------------------------------------------- Time picker
//
// Mounted on the dial. Dragging maps the pointer's angle (12 o'clock = 0)
// to an hour or an exact minute — and, on a 24-hour dial, its distance
// from the center to the outer (1–12) or inner (13–00) ring — and pushes
// it to the TimePicker component as it changes. Releasing on an hour
// sends `done` so the picker moves on to the minutes, like a click.

const TimePickerDial = {
  mount(hook) {
    const el = hook.el
    let dragging = false
    let last = null

    const valueAt = (e) => {
      const r = el.getBoundingClientRect()
      const dx = e.clientX - (r.left + r.width / 2)
      const dy = e.clientY - (r.top + r.height / 2)
      let turn = Math.atan2(dx, -dy) / (2 * Math.PI)
      if (turn < 0) turn += 1
      const part = el.dataset.ppSelecting
      if (part === "minute") return {part, value: Math.round(turn * 60) % 60}
      let hour = Math.round(turn * 12) % 12
      if (el.dataset.ppCycle === "24") {
        // Inner ring (13–00) is the closer one: 64px vs 100px on a 256px dial.
        const inner = Math.hypot(dx, dy) < (r.width / 256) * 82
        hour = inner ? (hour === 0 ? 0 : hour + 12) : hour === 0 ? 12 : hour
      } else if (hour === 0) {
        hour = 12
      }
      return {part, value: hour}
    }

    const push = (e, done) => {
      const v = valueAt(e)
      const key = v.part + v.value
      if (key !== last || done) {
        last = key
        hook.pushEventTo(el, "dial", done ? {...v, done: true} : v)
      }
    }

    el.addEventListener("pointerdown", (e) => {
      if (e.button !== 0) return
      dragging = true
      last = null
      el.setPointerCapture(e.pointerId)
      e.preventDefault()
      push(e, false)
    })
    el.addEventListener("pointermove", (e) => dragging && push(e, false))
    const end = (e) => {
      if (!dragging) return
      dragging = false
      push(e, true)
    }
    el.addEventListener("pointerup", end)
    el.addEventListener("pointercancel", end)
  },
}

// ------------------------------------------------------ Edge flipping
//
// Menus (and split buttons' menus), their submenus, and tooltips open on
// a fixed side. When the open panel would overflow the viewport, set
// `data-pp-flip` ("y", "x" or both) on it; phoenix_paper.css turns that
// into the opposite placement. Set through `hook.js()` so a LiveView patch
// doesn't strip it.

const overflow = (el) => {
  const r = el.getBoundingClientRect()
  const flips = []
  if (r.bottom > window.innerHeight || r.top < 0) flips.push("y")
  if (r.right > window.innerWidth || r.left < 0) flips.push("x")
  return flips
}

const place = (hook, panel) => {
  if (!panel) return
  hook.js().removeAttribute(panel, "data-pp-flip")
  const flips = overflow(panel)
  if (flips.length) hook.js().setAttribute(panel, "data-pp-flip", flips.join(" "))
}

// The panel gets its display in a requestAnimationFrame (JS.toggle), so
// measure two frames later.
const afterPaint = (fn) => requestAnimationFrame(() => requestAnimationFrame(fn))

const MenuFlip = {
  mount(hook) {
    const el = hook.el
    const trigger = document.getElementById(`${el.id}-trigger`)
    const panel = document.getElementById(`${el.id}-panel`)
    if (!trigger || !panel) return

    hook.observer = new MutationObserver(() => {
      if (trigger.getAttribute("aria-expanded") === "true") afterPaint(() => place(hook, panel))
    })
    hook.observer.observe(trigger, {attributes: true, attributeFilter: ["aria-expanded"]})

    const sub = (e) => {
      const wrapper = e.target.closest && e.target.closest('[data-pp-component="submenu"]')
      if (wrapper) afterPaint(() => place(hook, wrapper.querySelector(':scope > [role="menu"]')))
    }
    el.addEventListener("pointerover", sub)
    el.addEventListener("focusin", sub)
  },
  destroy(hook) {
    hook.observer && hook.observer.disconnect()
  },
}

const TooltipFlip = {
  mount(hook) {
    const bubble = hook.el.querySelector('[data-pp-component="tooltip-bubble"]')
    if (!bubble) return
    const check = () => place(hook, bubble)
    hook.el.addEventListener("pointerenter", check)
    hook.el.addEventListener("focusin", check)
  },
}

// ------------------------------------------------------------- dispatch

const behaviorFor = (el) => {
  if (el.hasAttribute("data-pp-sheet-handle")) return BottomSheetHandle
  switch (el.dataset.ppComponent) {
    case "tabs":
      return Tabs
    case "top-app-bar":
      return TopAppBar
    case "loading-indicator":
      return LoadingIndicator
    case "carousel":
      return Carousel
    case "time-picker-dial":
      return TimePickerDial
    case "menu":
    case "split-button":
      return MenuFlip
    case "tooltip":
      return TooltipFlip
    default:
      return null
  }
}

export const PhoenixPaper = {
  mounted() {
    this.behavior = behaviorFor(this.el)
    this.behavior && this.behavior.mount(this)
  },
  updated() {
    this.behavior && this.behavior.update && this.behavior.update(this)
  },
  destroyed() {
    this.behavior && this.behavior.destroy && this.behavior.destroy(this)
  },
}

export default {PhoenixPaper}
