# Twiddle
![twiddle_6 (1)](https://github.com/user-attachments/assets/e761196a-f843-4ed1-982c-db16383abfaa)



## 🧑‍🎤 一言紹介
指を動かして楽しむ、認知症予防ゲーム。
**Swift Student Challenge 2025 Winner** 選定作品。
<br>
<br>



## 🦦 アピールポイントと挑戦課題

<details>
<summary>① 非同期画像認識処理と信頼度フィルタリング</summary>

![세로_1](https://github.com/user-attachments/assets/a3d5be06-4bb8-4fd8-8df9-3e0eda6d3e58)


### 🔧 実装概要

VisionFrameworkの`VNImageRequestHandler` を使って `VNDetectHumanHandPoseRequest()` を実行し、非同期的に取得した指先位置情報を、`DispatchQueue.main.async` で UI に反映しています。

また、精度が0.3以上のデータのみをフィルタリングして使用しています。


### 💻 ソースコード

```swift
import AVFoundation
import Vision
import SwiftUI

class FrameHandler: NSObject, ObservableObject {

		/// Visionの手のポーズ検出リクエスト
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    /// 認識された指のポイント配列（リアルタイム更新）
    @Published var fingerPoints: [CGPoint] = []
}

extension FrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate {

		/// カメラからの映像フレームを受信し、手のポーズを検出する
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {

        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer,
                                            orientation: .up,
                                            options: [:])

        do {
            try handler.perform([handPoseRequest])
            guard let results = handPoseRequest.results, results.count > 1 else {
                DispatchQueue.main.async {
                    self.fingerPoints.removeAll()
                }
                return
            }

						// 両手の関節ポイントを抽出
            let firstHand = results[0]
            let secondHand = results[1]
            let allPointsA = try firstHand.recognizedPoints(.all)
            let allPointsB = try secondHand.recognizedPoints(.all)
						
						// 手首ポイントの有効性をチェック（信頼度が0.3以上）
            guard let wristPointA = allPointsA[.wrist],
                  let wristPointB = allPointsB[.wrist],
                  wristPointA.confidence > 0.3,
                  wristPointB.confidence > 0.3 else { return }

            // 手首座標の正規化（Visionは左上基準、UIKitは左下基準のためY軸反転）
            let wristA = CGPoint(x: wristPointA.location.x, y: 1 - wristPointA.location.y)
            let wristB = CGPoint(x: wristPointB.location.x, y: 1 - wristPointB.location.y)

            // 指先ポイントを抽出
            guard let thumbTipA = allPointsA[.thumbTip],
                  let indexTipA = allPointsA[.indexTip],
                  let thumbTipB = allPointsB[.thumbTip],
                  let indexTipB = allPointsB[.indexTip] else { return }

            let points: [CGPoint] = [
                CGPoint(x: thumbTipA.location.x, y: 1 - thumbTipA.location.y),
                CGPoint(x: indexTipA.location.x, y: 1 - indexTipA.location.y),
                CGPoint(x: thumbTipB.location.x, y: 1 - thumbTipB.location.y),
                CGPoint(x: indexTipB.location.x, y: 1 - indexTipB.location.y),
                wristA,
                wristB
            ]

            // 非同期: UIの更新は必ずメインスレッドで実行
            DispatchQueue.main.async {
                self.fingerPoints = points
            }

        } catch {
            print("\(error.localizedDescription)")
        }
    }
}
```

</details>

<details>
<summary>② 手のポーズ判定ロジック</summary>
    

### 🔧 実装概要
手の大きさを正規化し、ユークリッド距離の公式を用いて、3つの動作を判別しました。

### 💻 ソースコード
```swift
import CoreGraphics

class HandGestureProcessor {

    private var state = State.unknown
    private var switchCount: Int = 0
    
    /// 動作を検出フレーム数
    private var switchEvidenceCounter: Int = 0
    
    /// 動作を検出するために必要な連続フレーム数
    private let evidenceCounterStateTrigger = 5  

    /// 手の大きさを正規化
    private func handSize(of hand: HandPoints) -> CGFloat {
        guard let wrist = hand.wrist,
              let middleTip = hand.middleTip else { return 1.0 } // 0除算を防ぐためにデフォルト値1.0を返す
        return wrist.distance(from: middleTip)
    }

    /// 親指と小指を交互に開く動作をチェック
    func checkPinkyThumbCount(handA: HandPoints, handB: HandPoints) -> Int {
        let hand1: HandPoints
        let hand2: HandPoints
        
        // 左手・右手を判定
        if let wristA = handA.wrist, let wristB = handB.wrist {
            if wristA.x < wristB.x {
                hand1 = handA  // 左手
                hand2 = handB  // 右手
            } else {
                hand1 = handB  // 左手
                hand2 = handA  // 右手
            }
        } else {
            return switchCount
        }

        // 手のサイズを基準として正規化
        let hand1Size = handSize(of: hand1)
        let hand2Size = handSize(of: hand2)

        // 指先と手首の距離を正規化
        guard let distanceA1 = hand1.thumbTip?.distance(from: hand1.wrist!) else { return switchCount }
        guard let distanceA5 = hand1.littleTip?.distance(from: hand1.wrist!) else { return switchCount }
        guard let distanceB1 = hand2.thumbTip?.distance(from: hand2.wrist!) else { return switchCount }
        guard let distanceB5 = hand2.littleTip?.distance(from: hand2.wrist!) else { return switchCount }

        let normalizedA1 = distanceA1 / hand1Size
        let normalizedA5 = distanceA5 / hand1Size
        let normalizedB1 = distanceB1 / hand2Size
        let normalizedB5 = distanceB5 / hand2Size

        // 条件1: 左手の小指と右手の親指が開いている
        if normalizedA5 > 0.5 && normalizedB1 > 0.5 {
            if state != .ApinkyBthumb && switchCount % 2 == 0 {
                switchEvidenceCounter += 1
                
                /// 同じ動作が継続されたら、state変更
                if switchEvidenceCounter >= evidenceCounterStateTrigger {
                    state = .ApinkyBthumb
                    switchCount += 1
                    switchEvidenceCounter = 0
                }
            } else {
                switchEvidenceCounter = 0
            }

        // 条件2: 右手の小指と左手の親指が開いている
        } else if normalizedB5 > 0.5 && normalizedA1 > 0.5 {
            if state != .AthumbBpinky && switchCount % 2 == 1 {
                switchEvidenceCounter += 1
                
                /// 同じ動作が継続されたら、state変更
                if switchEvidenceCounter >= evidenceCounterStateTrigger {
                    state = .AthumbBpinky
                    switchCount += 1
                    switchEvidenceCounter = 0
                }
            } else {
                switchEvidenceCounter = 0
            }

        // いずれの条件も満たさない
        } else {
            switchEvidenceCounter = 0
        }

        return switchCount
    }
}
```
</details>


<br>
<br>

## Stage 01. グーからパーに
![twiddle](https://github.com/user-attachments/assets/3e06bcb1-cf46-4252-b82e-3ae9ff74633e)

## Stage 02. 親指と小指を交互に開く
![twiddle_8 (1)](https://github.com/user-attachments/assets/527eee59-4c6d-4df9-a750-09a7bf3dec70)
![twiddle_8 (1)](https://github.com/user-attachments/assets/875dc5ff-93ca-4959-b6f6-e1e8b972db42)

## Stage 03. 一本ずつ順番に指を開く
![Uploading twiddle_11.gif…]()

## 🔎 振り返り

### 学んだこと
- Vision Frameworkを活用した画像解析技術を扱ってみました。
- デバイスごとのカメラ仕様やセンサーの違い、特にLiDARの有無によって、AR機能に差が生じることを理解し、それを考慮した開発の必要性を学びました。
- 非同期タスク間の実行順序が乱れないようにフローを制御することの重要性を学びました。
<br>

### 改善点
- 今のロジックでは、多様な手のポーズに十分対応できません。今後は、より精度の高い判定を実現するために、Create ML を活用して機械学習モデルを自作し、柔軟かつ拡張性のあるポーズ判定に挑戦したいと考えています。
- 今は、2Dの平面的なエフェクトしか適用できていません。今後は、LiDARが搭載されたiPhoneデバイスの3D空間認識機能を活用し、より立体的なエフェクトを実現したいです。


