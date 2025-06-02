//
//  LToastView.swift
//  Cue
//
//  Created by Bibin Tom Joseph on 18/12/23.
//

import SwiftUI

struct LToastGroup: View {
    @StateObject var toastManager = LToastManager.shared
    var body: some View {
        GeometryReader {
            let safeArea = $0.safeAreaInsets

            ZStack {
                ForEach(toastManager.toasts) {
                    let transform = transform($0)
                    LToastView(item: $0)
                        .scaleEffect(transform.scale)
                        .offset(y: transform.yOffset)
                        .animation(.easeInOut, value: transform.scale)
                        .animation(.easeInOut, value: transform.yOffset)
                        .zIndex(Double(transform.index))
                }
            }
            .padding(.bottom, safeArea.top == .zero ? 15 : 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    func transform(_ item: LToastItem) -> (index: Int, scale: CGFloat, yOffset: CGFloat) {
        guard let indexInt: Int = (toastManager.toasts.firstIndex { $0.id == item.id }) else { return (0, 0, 0) }
        let index = CGFloat(indexInt)
        let totalCount = CGFloat(toastManager.toasts.count) - 1
        let yOffset = (totalCount - (index)) >= 2 ? -20 : ((totalCount - index) * -10)
        let scale: CGFloat = 1.0 - ((totalCount - index) >= 2 ? 0.2 : ((totalCount - index) * 0.1))
        return (indexInt, scale, yOffset)
    }
}

struct LToastView: View {
    @State private var yOffset: CGFloat = 0
    @State private var delayTask: DispatchWorkItem?
    @State var item: LToastItem
    

    var body: some View {
        HStack {
            HStack(spacing: 10) {
                if let image = item.image {
                    image
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: 20)
                        .offset(y: -1)
                        .foregroundStyle(item.tint)
                }
                Text(LocalizedStringKey(item.title))
                    .foregroundStyle(item.tint)
//                    .customFont(.primary, weight: .medium, textStyle: .subheadline)

                if item.primaryAction.isNotNil {
                    primaryActionView()
                }
            }
            .frame(height: 40)
            .padding(.leading)
            .if(item.primaryAction.isNil) {
                $0.padding(.trailing)
            }
            .if(item.primaryAction.isNotNil) {
                $0.padding(.trailing, 3)
            }
            .background(
                Capsule()
                    .foregroundStyle(.thickMaterial)
                    .overlay(
                        Capsule()
                            .stroke(lineWidth: 0.3)
                            .foregroundStyle(Color.accent.opacity(0.3))
                    )
                    .shadow(color: .black.opacity(0.15),
                            radius: 20, x: 0, y: 10)
            )

            if item.secondaryAction.isNotNil {
                secondaryActionView()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    withAnimation {
                        let yTranslation = value.translation.height
                        yOffset = max(0, yTranslation)
                    }
                }
                .onEnded { value in
                    let endY = value.translation.height
                    let velocityY = value.velocity.height
                    if (endY + velocityY) > 100 {
                        animateOutToast()
                    } else {
                        withAnimation(.snappy) {
                            yOffset = 0
                        }
                    }
                }
        )
        .offset(y: yOffset)
        .onAppear {
            guard delayTask.isNil else { return }
            delayTask = .init {
                animateOutToast()
            }

            if let delayTask {
                DispatchQueue.main.asyncAfter(deadline: .now() + item.timing.rawValue, execute: delayTask)
            }
        }
        .transition(.offset(y: 180))
        .transition(.scale(scale: 0.7))
    }

    func animateOutToast() {
        delayTask?.cancel()
        withAnimation(.snappy) {
            item.didFinishDisplaying?(item.actionExecuted)
            LToastManager.shared.toasts.removeAll { $0.id == item.id }
        }
    }

    func primaryActionView() -> some View {
        let primaryAction = item.primaryAction
        return Button {
            primaryAction?.action?()
            item.actionExecuted = true
            animateOutToast()
        } label: {
            HStack(spacing: 5) {
                if let primaryActionImage = primaryAction?.image {
                    primaryActionImage
                        .foregroundStyle(primaryAction?.tint ?? .accent)
                }
                if let primaryActiontitle = primaryAction?.title {
                    Text(LocalizedStringKey(primaryActiontitle))
//                        /*.customFont(.primary, weight*/: .medium, textStyle: .subheadline)
                        .foregroundStyle(primaryAction?.tint ?? .accent)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            .frame(height: 34)
            .padding(.horizontal)
            .background(
                Capsule()
                    .foregroundStyle(.thickMaterial)
                    .overlay(
                        Capsule()
                            .stroke(lineWidth: 0.3)
                            .foregroundStyle(Color.accent.opacity(0.3))
                    )

            )
        }
    }

    func secondaryActionView() -> some View {
        let secondaryAction = item.secondaryAction
        return Button(action: {
            secondaryAction?.action?()
            item.actionExecuted = true
            animateOutToast()
        }, label: {
            HStack {
                if let secondaryActionImage = secondaryAction?.image {
                    secondaryActionImage
                        .foregroundStyle(secondaryAction?.tint ?? Color.accent)
                        .frame(width: 35, height: 35)
                } else if let secondaryActiontitle = secondaryAction?.title {
                    Text(LocalizedStringKey(secondaryActiontitle))
                        .customFont(.headline)
                        .foregroundStyle(secondaryAction?.tint ?? Color.accent)
                }
            }
            .background(
                Capsule()
                    .foregroundStyle(.thickMaterial)
                    .overlay(
                        Capsule()
                            .stroke(lineWidth: 0.3)
                            .foregroundStyle(Color.accent.opacity(0.3))
                    )
                    .shadow(color: .black.opacity(0.15),
                            radius: 20, x: 0, y: 10)
            )
//            .colorScheme(.dark)
        })
        .zIndex(-1)
//                    .opacity(context.show ? 1 : 0)
    }
}
