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
							.frame(maxWidth: .infinity)
						}
						.contentShape(Rectangle())
						.clipped()
						.ignoresSafeArea()
						.transition(.move(edge: .top).combined(with: .opacity))
						.zIndex(peerModel.receivedCard != nil ? 2 : 1)
						.allowsHitTesting(peerModel.receivedCard != nil)
						.onTapGesture {
							peerModel.dismissReceivedCard()
						}
				}
				
				if ownModel.isDetailPresented {
					Color.black.opacity(0.45)
						.ignoresSafeArea()
						.transition(.opacity)
						.zIndex(1)
						.onTapGesture {
							if !ownModel.isEditMode {
								ownModel.dismissDetail()
							}
						}
				}
				
				CardView(
					data: $ownModel.ownCard,
					isRised: ownModel.isRised,
					isEditMode: ownModel.isEditMode,
					flipAngle: ownModel.flip.flipAngle,
					tiltAngle: ownModel.flip.tiltAngle
				)
				.offset(
					x: ownModel.isDetailPresented ? 0 : ownModel.cardScreenOffset.width,
					y: ownModel.isDetailPresented ? 0 : (ownModel.cardScreenOffset.height + ownModel.transferYOffset)
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
				
				if let receivedCard = peerModel.receivedCard {
					CardView(
						data: .constant(receivedCard),
						isRised: true,
						flipAngle: peerModel.flip.flipAngle,
						tiltAngle: peerModel.flip.tiltAngle
					)
					.scaleEffect(peerModel.receivedCardScale)
					.rotationEffect(.degrees(peerModel.receivedCardRotationAngle))
					.offset(y: peerModel.receivedCardYOffset)
					.zIndex(4)
					.gesture(
						DragGesture(minimumDistance: 0)
							.onChanged { value in
								guard peerModel.isReceivedCardInteractive else { return }
								peerModel.flip.dragChanged(value)
							}
							.onEnded { value in
								guard peerModel.isReceivedCardInteractive else { return }
								peerModel.flip.dragEnded(value)
							}
					)
				}
			}
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
				}
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.ignoresSafeArea()
			.animation(.easeInOut(duration: 1), value: ownModel.isAligned)
			.onChange(of: peerModel.receivedCard) {
				Task { @MainActor in
					ownModel.dismissDetail()
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
