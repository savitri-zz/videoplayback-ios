//
//  VPKVideoToolBarView.swift
//  VideoPlaybackKit
//
//  Created by Sonam on 4/21/17.
//  Copyright © 2017 ustwo. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer
import ASValueTrackingSlider

public class VPKPlaybackControlView: UIView {
    
    //Protocol
    weak var presenter: VPKVideoPlaybackPresenterProtocol?
    
    var theme: ToolBarTheme = .normal
    var progressValue: Float = 0.0 {
        didSet {
            DispatchQueue.main.async {
                self.playbackProgressSlider.value = self.progressValue
                self.layoutIfNeeded()
            }
        }
    }
    var maximumSeconds: Float = 0.0 {
        didSet {
            playbackProgressSlider.maximumValue = maximumSeconds
        }
    }
    
    //Private
    fileprivate var playPauseButton = UIButton(frame: .zero)
    private let fullScreen = UIButton(frame: .zero)
    private let volumeCtrl = MPVolumeView()
    private let expandButton = UIButton(frame: .zero)
    fileprivate let timeProgressLabel = UILabel(frame: .zero)
    fileprivate let durationLabel = UILabel(frame: .zero)
    private let skipBackButton = UIButton(frame: .zero)
    private let skipForwardButton = UIButton(frame: .zero)
    
    fileprivate let playbackProgressSlider = ASValueTrackingSlider(frame: .zero)

    
    convenience init(theme: ToolBarTheme) {
        self.init(frame: .zero)
        self.theme = theme
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        playbackProgressSlider.dataSource = self
    }
    
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        switch theme {
        case .normal:
            setupNormalLayout()
        case let .transparent(backgroundColor: bgColor, foregroundColor: fgColor, alphaValue: alpha):
            setupTransparentThemeWith(bgColor, foreground: fgColor, atTransparency: alpha)
            setupNormalLayout()
        }
    }
    
    private func setupTransparentThemeWith(_ background: UIColor, foreground fg: UIColor, atTransparency alphaValue: CGFloat) {
        alpha = CGFloat(alphaValue)
        backgroundColor = background
        playbackProgressSlider.backgroundColor = fg
        playbackProgressSlider.popUpViewAnimatedColors = [fg, background, UIColor.white]
    }
    
    private func setupNormalLayout() {
        
        isUserInteractionEnabled = true

        let bottomControlContainer = UIView(frame: .zero)
        addSubview(bottomControlContainer)
        bottomControlContainer.backgroundColor = VPKColor.backgroundiOS11Default.rgbColor
        bottomControlContainer.snp.makeConstraints { (make) in
            make.left.equalTo(self).offset(6.5)
            make.right.equalTo(self).offset(-6.5)
            make.height.equalTo(47)
            make.bottom.equalTo(self.snp.bottom).offset(-6.5)
        }
        
        bottomControlContainer.layer.cornerRadius = 16.0
        bottomControlContainer.layer.borderColor = VPKColor.borderiOS11Default.rgbColor.cgColor
        bottomControlContainer.layer.borderWidth = 0.5

        let blurContainer = UIView(frame: .zero)
        bottomControlContainer.addSubview(blurContainer)
        blurContainer.snp.makeConstraints { (make) in
            make.edges.equalTo(bottomControlContainer)
        }
        blurContainer.backgroundColor = .clear
        blurContainer.isUserInteractionEnabled = true
        blurContainer.clipsToBounds = true
        
        let blurEffect = self.defaultBlurEffect()
        blurContainer.addSubview(blurEffect)
        blurEffect.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        blurContainer.layer.cornerRadius = bottomControlContainer.layer.cornerRadius
    
        bottomControlContainer.addSubview(skipBackButton)
        skipBackButton.snp.makeConstraints { (make) in
            make.left.equalTo(bottomControlContainer).offset(10)
            make.centerY.equalTo(bottomControlContainer)
            make.height.width.equalTo(30)
        }
        skipBackButton.setBackgroundImage(#imageLiteral(resourceName: "defaultSkipBack15"), for: .normal)
        skipBackButton.addTarget(self, action: #selector(didSkipBack(_:)), for: .touchUpInside)
        
        
        bottomControlContainer.addSubview(playPauseButton)
        playPauseButton.snp.makeConstraints { (make) in
            make.left.equalTo(skipBackButton.snp.right).offset(8.0)
            make.centerY.equalTo(bottomControlContainer)
            make.height.width.equalTo(28)
        }
        playPauseButton.setBackgroundImage(UIImage(named: PlayerState.paused.buttonImageName), for: .normal)
        playPauseButton.contentMode = .scaleAspectFit
        playPauseButton.addTarget(self, action: #selector(didTapPlayPause), for: .touchUpInside)
        
        bottomControlContainer.addSubview(skipForwardButton)
        skipForwardButton.snp.makeConstraints { (make) in
            make.left.equalTo(playPauseButton.snp.right).offset(8.0)
            make.centerY.equalTo(bottomControlContainer)
            make.height.width.equalTo(28)
        }
        
        skipForwardButton.setBackgroundImage(#imageLiteral(resourceName: "defaultSkipForward15"), for: .normal)
        skipForwardButton.addTarget(self, action: #selector(didSkipForward(_:)), for: .touchUpInside)
        
        
        bottomControlContainer.addSubview(timeProgressLabel)
        bottomControlContainer.addSubview(playbackProgressSlider)
        
        timeProgressLabel.snp.makeConstraints { (make) in
            make.left.equalTo(skipForwardButton.snp.right).offset(8.0)
            make.centerY.equalTo(bottomControlContainer)
            make.right.equalTo(playbackProgressSlider.snp.left).offset(-6.0)
        }
        
        timeProgressLabel.textColor = UIColor(white: 1.0, alpha: 0.75)
        timeProgressLabel.text = "0:00"
        //TODO: ADD FONT
        
        
        bottomControlContainer.addSubview(durationLabel)
        playbackProgressSlider.snp.makeConstraints { (make) in
            make.left.equalTo(timeProgressLabel.snp.right).offset(5.0)
            make.right.equalTo(durationLabel.snp.left).offset(5.0)
            make.centerY.equalTo(bottomControlContainer)
            make.height.equalTo(5.0)
        }
        playbackProgressSlider.addTarget(self, action: #selector(didScrub), for: .valueChanged)
        playbackProgressSlider.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .horizontal)
        
        playbackProgressSlider.textColor = VPKColor.borderiOS11Default.rgbColor
        playbackProgressSlider.backgroundColor = VPKColor.timeSliderBackground.rgbColor
        playbackProgressSlider.popUpViewColor = .white
        
        playbackProgressSlider.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        playbackProgressSlider.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .horizontal)
        
        
        bottomControlContainer.addSubview(durationLabel)
        durationLabel.snp.makeConstraints { (make) in
            make.right.equalTo(bottomControlContainer.snp.right).offset(-8.0)
            make.centerY.equalTo(bottomControlContainer)
        }
        durationLabel.textColor = UIColor(white: 1.0, alpha: 0.75)
        durationLabel.text = ""
        durationLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        
        
        addSubview(expandButton)
        expandButton.layer.cornerRadius = 16.0
        expandButton.backgroundColor = VPKColor.backgroundiOS11Default.rgbColor
        expandButton.snp.makeConstraints { (make) in
            make.left.equalTo(self).offset(8.0)
            make.width.equalTo(30)
            make.height.equalTo(30)
            make.top.equalTo(self).offset(23)
        }
        expandButton.setBackgroundImage(#imageLiteral(resourceName: "defaultExpand"), for: .normal)
        expandButton.addTarget(self, action: #selector(didTapExpandView), for: .touchUpInside)
        
    }
}

extension VPKPlaybackControlView: ASValueTrackingSliderDataSource {
    
    public func slider(_ slider: ASValueTrackingSlider!, stringForValue value: Float) -> String! {
        return presenter?.formattedProgressTime(from: TimeInterval(value))
    }
}

extension VPKPlaybackControlView: VPKPlaybackControlViewProtocol {
    
    
    func showDurationWith(_ time: String) {
        durationLabel.text = time
    }
    
    func didSkipBack(_ seconds: Float = 15.0) {
        presenter?.didSkipBack(seconds)
    }
    
    func didSkipForward(_ seconds: Float = 15.0) {
        presenter?.didSkipForward(seconds)
    }

    func updateTimePlayingCompletedTo(_ time: String) {
        timeProgressLabel.text = time
    }
    
    func didScrub() {
        #if DEBUG
            print("USER SCRUBBED TO \(playbackProgressSlider.value)")
        #endif
        presenter?.didScrubTo(TimeInterval(playbackProgressSlider.value))
    }
    
    func didTapExpandView() {
        presenter?.didExpand()
    }
    
    func toggleActionButton(_ imageName: String) {
        playPauseButton.setBackgroundImage(UIImage(named: imageName), for: .normal)
    }
    
    func didTapPlayPause() {
        presenter?.didTapVideoView()
    }
}

extension VPKPlaybackControlView {
    
    func defaultBlurEffect() -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.clipsToBounds = true
        return blurEffectView
    }
}