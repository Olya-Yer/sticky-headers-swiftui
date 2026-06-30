//
//  StickyModifier.swift
//
//  A SwiftUI sticky-header system built on PreferenceKey + Environment.
//  Supports three modes per header: regular sticky, isFixed (always pinned,
//  stacks), and isRevers (hides on scroll up, reveals on scroll down).
//
//  Created by Olya Yeritspokhyan
//

import SwiftUI

extension View {
    func sticky(lastItemY: CGFloat, isFixed: Bool = false, isRevers: Bool = false, isSeeMore: Bool = false) -> some View {
        modifier(Sticky(lastItemY: lastItemY, isFixed: isFixed, isRevers: isRevers, isSeeMore: isSeeMore))
    }
}

struct Sticky: ViewModifier {
    @SwiftUI.Environment(\.stickyRects) var stickyRects
    var lastItemY: CGFloat
    var isFixed: Bool
    var isRevers: Bool
    var isSeeMore: Bool
    @State public var frame: CGRect = .zero
    @State var scrollAmount: CGFloat = 0
    @State public var isScrollingUp: Bool = false
    @Namespace var id
    
    var isSticking: Bool {
        frame.minY < fixedHeadersHeight
    }
    
    var reversViewOffset: CGFloat? {
        if let reversView, reversView.currentOffset + reversView.rect.minY > -reversView.rect.height {
            let revHeight = reversView.rect.height
            let revCurrentOff = reversView.currentOffset + reversView.rect.minY
            return min(revHeight + revCurrentOff, revHeight)
        }
        return nil
    }
    
    var fixedHeadersHeight: CGFloat {
        if isFixed {
            // For fixed headers, calculate space needed for other fixed headers above this one
            // Headers stick in order, so we can determine order by their current positions
            let previousFixedHeaders = stickyRects?
                .filter { item in
                    guard item.key != id && item.value.isFixed else { return false }
                    
                    // If both headers are sticking (minY < 0), the one with more negative minY came first
                    // If one is sticking and one isn't, the sticking one came first
                    // If neither is sticking, compare their natural positions
                    
                    let selfMinY = frame.minY
                    let otherMinY = item.value.rect.minY
                    
                    if selfMinY < 0 && otherMinY < 0 {
                        // Both sticking: more negative = came earlier
                        return otherMinY < selfMinY
                    } else if otherMinY < 0 && selfMinY >= 0 {
                        // Other is sticking, self is not: other came first
                        return true
                    } else if selfMinY < 0 && otherMinY >= 0 {
                        // Self is sticking, other is not: self came first
                        return false
                    } else {
                        // Neither sticking: smaller position = comes earlier
                        return otherMinY < selfMinY
                    }
                }
            
            // Sum up their heights
            let fixedHeadersOffset = previousFixedHeaders?
                .map { $0.value.rect.height }
                .reduce(0, +) ?? 0
            
            // Also consider reverse view if present
            if let reversViewOffset {
                return reversViewOffset + fixedHeadersOffset
            } else {
                return fixedHeadersOffset
            }
        }
        
        // For non-fixed headers, calculate all fixed headers height
        let stickyies = stickyRects?
            .filter { $0.value.isFixed }
            .sorted { $0.value.rect.minY < $1.value.rect.minY }
        
        // Calculate the height of all sticking fixed headers.
        // A fixed header counts as "sticking" if its geometric minY is negative
        // OR if it has a non-zero currentOffset (it's being held in place during
        // the transitional phase between minY < threshold and minY < 0).
        let fixedHeadersTotalHeight = stickyies?
            .compactMap { header -> CGFloat? in
                if header.value.rect.minY < 0 || header.value.currentOffset != 0 {
                    return header.value.rect.height
                } else {
                    return nil
                }
            }
            .reduce(0, +) ?? 0
        
        // Add reverse view offset if present
        let totalOffset = fixedHeadersTotalHeight + (reversViewOffset ?? 0)
        
        return totalOffset
    }
    
    var reversView: StickyRect? {
        stickyRects?.first { $0.value.isRevers }?.value
    }
    
    var offset: CGFloat {
        if isSeeMore {
            return 0
        }
        if isRevers, let reversView {
            let minY = frame.minY
            let height = frame.height
            guard minY < 0 else { return 0 }
            if isScrollingUp {
                if minY < -height && reversView.currentOffset == 0 {
                    return -minY - height
                } else {
                    let newOff = reversView.currentOffset + scrollAmount
                    return max(min(-minY, newOff), -minY - height)
                }
            } else {
                let off = reversView.currentOffset + scrollAmount
                return max(off, 0)
            }
        }
        
        guard isSticking else { return 0 }
        
        var adjustingConstant = 0.0
        if fixedHeadersHeight > 0 {
            adjustingConstant = 3.0
        }
        
        if isFixed {
            // For fixed headers, maintain position below other fixed headers
            let targetOffset = fixedHeadersHeight - adjustingConstant
            
            // When the header reaches or passes its sticky position
            if frame.minY < targetOffset {
                // Offset to keep it at the target position
                return targetOffset - frame.minY
            } else {
                // Header hasn't reached sticky position yet
                return 0
            }
        }
        
        // For regular sticky headers
        var o = -frame.minY + fixedHeadersHeight - adjustingConstant
        
        guard let stickyRects else { return o }
        
        // Push-off: when the next sticky's top enters the current sticky's region
        // (top of current = fixedHeadersHeight, bottom = fixedHeadersHeight + frame.height),
        // it pushes the current one upward so their edges stay glued: the bottom of
        // the current header touches the top of the next.
        let stickRegionBottom = fixedHeadersHeight + frame.height
        if let other = stickyRects.first(where: { (key, value) in
            key != id && value.rect.minY > frame.minY && value.rect.minY < stickRegionBottom
        }) {
            o -= stickRegionBottom - other.value.rect.minY
        }
        
        if lastItemY > frame.minY && lastItemY < frame.height + fixedHeadersHeight {
            o -= frame.height + fixedHeadersHeight - lastItemY
        }
        
        return o
    }
    
    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .zIndex(isSticking ? .infinity : 0)
            .overlay(GeometryReader { proxy in
                let f = proxy.frame(in: .named(UseStickyHeaders.container))
                Color.clear
                    .onAppear {
                        frame = f
                    }
                    .onChange(of: f) { newFrame in
                        isScrollingUp = newFrame.minY > frame.minY
                        scrollAmount = newFrame.minY - frame.minY
                        frame = newFrame
                    }
                    .preference(
                        key: FramePreference.self,
                        value: [id: .init(
                            rect: frame,
                            isFixed: isFixed,
                            isRevers: isRevers,
                            currentOffset: offset)]
                    )
            })
    }
}

struct FramePreference: PreferenceKey {
    static var defaultValue: [Namespace.ID: StickyRect] = [:]
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue()) { $1 }
    }
}

enum StickyRects: EnvironmentKey {
    static var defaultValue: [Namespace.ID: StickyRect]?
}

struct StickyRect: Equatable {
    let rect: CGRect
    let isFixed: Bool
    let isRevers: Bool
    let currentOffset: CGFloat
    
    init(rect: CGRect, isFixed: Bool = false, isRevers: Bool = false, currentOffset: CGFloat) {
        self.rect = rect
        self.isFixed = isFixed
        self.isRevers = isRevers
        self.currentOffset = currentOffset
    }
}

extension EnvironmentValues {
    var stickyRects: StickyRects.Value {
        get { self[StickyRects.self] }
        set { self[StickyRects.self] = newValue }
    }
}

struct UseStickyHeaders: ViewModifier {
    static let container = "stickyContainer"
    @State public var frames: StickyRects.Value = [:]
    
    func body(content: Content) -> some View {
        content
            .onPreferenceChange(FramePreference.self) { newValue in
                DispatchQueue.main.async {
                    frames = newValue
                }
            }
            .coordinateSpace(name: UseStickyHeaders.container)
            .environment(\.stickyRects, frames)
    }
}

extension View {
    func useStickyHeaders() -> some View {
        modifier(UseStickyHeaders())
    }
}
