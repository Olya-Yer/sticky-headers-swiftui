# Sticky Headers — SwiftUI

A small SwiftUI view modifier that gives a `ScrollView`'s section headers three
behaviours you can mix per call:

- **Regular sticky** — sticks at the top, gets pushed off when the next sticky
  arrives (its bottom edge glued to the next header's top until it slides out).
- **Fixed** (`isFixed: true`) — stays pinned forever. Multiple fixed headers
  stack on top of each other in the order they reach the top.
- **Reverse** (`isRevers: true`) — hides on scroll up, slides back in on
  scroll down. The iOS Mail / Safari filter-bar pattern.

Built on `PreferenceKey + Environment + GeometryReader` — no `UIScrollViewDelegate`,
no coordinator, no `ScrollViewReader`. Each header declares how it wants to
behave and the modifier figures out the rest from the live dictionary of
neighbouring frames.

The demo (`StickyHeasers/ContentView.swift`) is a Calendar-style screen showing
all three modes together: a filter chip row, three stacking month headers, and
weekly section headers under each.

Full write-up at: **[curlybraces.codes/blog/sticky-headers-swiftui](https://curlybraces.codes/blog/sticky-headers-swiftui/)**

## Usage

At the `ScrollView`'s root:

```swift
ScrollView(.vertical, showsIndicators: false) {
    VStack(spacing: 0) {
        // content
    }
}
.useStickyHeaders()
```

On each header:

```swift
monthBar
    .background(Color.white)
    .sticky(lastItemY: lastItemY, isFixed: true)
    .zIndex(100)   // optional — higher = renders over lower-priority stickies
```

## Notes

- `zIndex` at the call site is how you control which sticky renders on top
  when two overlap (e.g. a regular sticky sliding *under* a fixed bar on its
  way out). Set fixed > regular > content.
- `lastItemY` should be the y-position of the bottom of the scrollable
  content; sample wiring via `GeometryReader` is in `ContentView.swift`.
- iOS 17+ for the SwiftUI APIs used; the `.onChange(of:perform:)` calls
  still compile under the new two-parameter form with a deprecation warning.

## License

MIT.
