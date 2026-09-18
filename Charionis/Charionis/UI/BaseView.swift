//
//  BaseView.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 14/09/26.
//

import SwiftUI
import SwiftData

struct BaseView: View {
	@State private var baseViewModel: BaseViewModel
	
	init(modelContext: ModelContext) {
		_baseViewModel = State(wrappedValue: BaseViewModel(modelContext: modelContext))
	}
	
	private var ownModel: OwnViewModel { baseViewModel.ownModel }
	private var peerModel: PeerViewModel { baseViewModel.peerModel }
	
	var body: some View {
		@Bindable var ownModel = ownModel
		
		NavigationStack {
			ZStack {
				BackgroundView(offset: CGSize(
					width: -ownModel.cameraOffset.width,
					height: -ownModel.cameraOffset.height
				))
				
				ZStack {
					// Backdrop overlay
					if ownModel.isAligned || peerModel.receivedCard != nil {
						Color.clear
							.overlay(alignment: .top) {
								VStack(spacing: 0) {
									Color.black.opacity(baseViewModel.backdropOpacity)
										.frame(height: peerModel.backdropSolidHeight)
									
									LinearGradient(
										colors: [
											.black.opacity(baseViewModel.backdropOpacity),
											.clear
										],
										startPoint: .top,
										endPoint: .bottom
									)
									.frame(height: baseViewModel.backdropFadeHeight)
								}
							}
							.frame(maxWidth: .infinity)
							.contentShape(Rectangle())
							.clipped()
							.ignoresSafeArea()
							.transition(.move(edge: .top).combined(with: .opacity))
							.zIndex(peerModel.receivedCard != nil ? 3 : 1)
							.allowsHitTesting(false)
					}
					
					// Own card backdrop detail
					if ownModel.isDetailPresented {
						Color.black.opacity(0.7)
							.ignoresSafeArea()
							.transition(.opacity)
							.zIndex(1)
							.onTapGesture {
								if !ownModel.isEditMode {
									ownModel.dismissDetail()
								}
							}
					}
					
					// Own Card
					CardView(
						data: $ownModel.ownCard,
						isRised: ownModel.isRised,
						isEditMode: ownModel.isEditMode,
						flipAngle: ownModel.flip.flipAngle,
						tiltAngle: ownModel.flip.tiltAngle
					)
					.overlay {
						if ownModel.isDetailPresented && !ownModel.isEditMode {
							IndicatorDots(isBackVisible: ownModel.flip.isBackVisible)
								.offset(y: 120)
						}
					}
					.offset(
						x: ownModel.isDetailPresented ? 0 : ownModel.cardScreenOffset.width,
						y: (ownModel.isDetailPresented ? 0 : (ownModel.cardScreenOffset.height + ownModel.transferYOffset))
						+ (ownModel.hasAppeared ? 0 : (DeviceMetrics.screenHeight + 100))
					)
					.scaleEffect(ownModel.isDetailPresented ? 1.15 : 1)
					.opacity(ownModel.cardOpacity)
					.zIndex(2)
					.allowsHitTesting(peerModel.receivedCard == nil)
					.gesture(
						DragGesture(minimumDistance: 0)
							.onChanged { value in
								if ownModel.isDetailPresented {
									if !ownModel.isEditMode {
										ownModel.flip.dragChanged(value)
									}
								} else {
									ownModel.handlePositionChange(translation: value.translation)
								}
							}
							.onEnded { value in
								if ownModel.isDetailPresented {
									if !ownModel.isEditMode {
										ownModel.flip.dragEnded(value)
									}
								} else {
									ownModel.handlePositionEnded(translation: value.translation)
								}
							}
					)
					.disabled(ownModel.isSending)
					
					// Received Card
					if let receivedCard = peerModel.receivedCard {
						CardView(
							data: .constant(receivedCard),
							isRised: true,
							flipAngle: peerModel.flip.flipAngle,
							tiltAngle: peerModel.flip.tiltAngle
						)
						.scaleEffect(peerModel.receivedCardScale * (1.0 - CGFloat(peerModel.dismissProgress) * 0.15))
						.rotationEffect(.degrees(peerModel.receivedCardRotationAngle))
						.offset(
							x: peerModel.cardDragOffset.width,
							y: peerModel.receivedCardYOffset + peerModel.cardDragOffset.height
						)
						.zIndex(4)
						.gesture(
							DragGesture(minimumDistance: 0)
								.onChanged { value in
									peerModel.handleCardDragChanged(value)
								}
								.onEnded { value in
									peerModel.handleCardDragEnded(value)
								}
						)
					}
					
					// Wallet Chevron Indicator
					if peerModel.receivedCard != nil {
						WalletChevronIndicator(
							isPresented: peerModel.isWalletPresented,
							walletYOffset: peerModel.walletYOffset,
							walletHeight: peerModel.walletHeight,
							walletPeekAmount: peerModel.walletPeekAmount
						)
						.zIndex(3.5)
					}
					
					// Bottom Peeking Wallet
					if peerModel.receivedCard != nil {
						VStack {
							Spacer()
				
							WalletView()
								.frame(height: peerModel.walletHeight)
								.offset(y: peerModel.walletYOffset)
						}
						.ignoresSafeArea(edges: .bottom)
						.zIndex(5)
						.allowsHitTesting(false)
					}
					
					if baseViewModel.isSavedCardShown {
						SavedCardsView(
							isVisible: baseViewModel.areSavedCardsVisible
						)
						.zIndex(6)
					}
				}
			}
			.animation(.easeInOut(duration: 1), value: ownModel.isAligned)
			.sensoryFeedback(.alignment, trigger: ownModel.isAligned)
			.toolbar {
				if ownModel.isDetailPresented {
					ToolbarItem(placement: .topBarTrailing) {
						Button {
							ownModel.toggleEditMode()
						} label: {
							Image(systemName: ownModel.isEditMode ? "checkmark" : "square.and.pencil")
						}
						.disabled(!ownModel.isCardValid)
					}
				} else if peerModel.receivedCard == nil {
					ToolbarItem(placement: .topBarLeading) {
						SavedCardsToolbarButton(
							isSavedCardShown: $baseViewModel.isSavedCardShown,
							onToggle: { baseViewModel.toggleSavedCards() }
						)
					}
				}
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.ignoresSafeArea()
			.onChange(of: peerModel.receivedCard) {
				Task { @MainActor in
					ownModel.dismissDetail()
					baseViewModel.dismissSavedCards()
				}
			}
			.task {
				guard !ownModel.hasAppeared else { return }
				try? await Task.sleep(for: .milliseconds(200))
				
				withAnimation(.spring(response: 0.75, dampingFraction: 0.75)) {
					ownModel.hasAppeared = true
				}
			}
		}
	}
}

#Preview {
	let container = try! ModelContainer(
		for: Card.self,
		configurations: ModelConfiguration(isStoredInMemoryOnly: true)
	)
	
	BaseView(modelContext: container.mainContext)
}
