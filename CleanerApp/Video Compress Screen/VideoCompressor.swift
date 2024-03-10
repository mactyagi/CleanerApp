//
//  VideoCompressor.swift
//  CleanerApp
//
//  Created by manu on 12/11/23.
//

import AVFoundation
import UIKit

public enum VideoQuality {
    case very_high
    case high
    case medium
    case low
    case very_low
}

// Compression Result
public enum CompressionResult {
    case onStart
    case onSuccess(URL)
    case onFailure(CompressionError)
    case onCancelled
}

// Compression Interruption Wrapper
public class Compression {
    public init() {}
    
    public var cancel = false
}

// Compression Error Messages
public struct CompressionError: LocalizedError {
    public let title: String
    
    init(title: String = "Compression Error") {
        self.title = title
    }
}

@available(iOS 14.0, *)
public class LightCompressor {
    var quality: VideoQuality
    var destinationURL: URL?
    var asset: AVAsset
    var fileType: AVFileType = .mov
    var compressionOperation = Compression()
    public init(quality: VideoQuality, asset: AVAsset) {
        self.quality = quality
        self.asset = asset
    }
    
    /**
     * This function compresses a given list of [video]  files and writes the compressed video file at
     * [destination]
     *
     * @param [videos] the list of videos  to be compressed. Each video object should have [source], [destination], and an optional [configuration] where:
     * - [source] is the source path of the video
     * - [destination] the path where the output compressed video file should be saved
     * - [configuration] is the custom configuration to control compression parameters for the video to be compressed. The configurations include:
     *      -  [quality] to allow choosing a video quality that can be [.very_low], [.low], [.medium],  [.high], and [very_high]. This defaults to [.medium]
     *      - [isMinBitrateCheckEnabled] to determine if the checking for a minimum bitrate threshold before compression is enabled or not. This default to `true`
     *      - [videoBitrateInMbps] which is a custom bitrate for the video
     *      - [keepOriginalResolution] to keep the original video height and width when compressing. This defaults to `false`
     *      - [VideoSize] which is a custom height and width for the video
     * @param [progressHandler] a compression progress  listener that listens to compression progress status
     * @param [completion] to return completion status that can be [onStart], [onSuccess], [onFailure],
     * and if the compression was [onCancelled]
     */
    
    public func estimatedOutputSize() -> Int64{
        guard let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first else {
            let error = CompressionError(title: "Cannot find video track")
            return 0
        }
        let bitrate = videoTrack.estimatedDataRate
        let newBitrate = getBitrate(bitrate: bitrate, quality: quality)
        let durationInSeconds = asset.duration.seconds
        let previousSize = Int64(bitrate * Float(durationInSeconds)).convertToFileString()
        let size = (Int64(newBitrate * Int(durationInSeconds)) / 8)
        return size
    }
    
    @discardableResult
    public func compressVideo(
                              progressQueue: DispatchQueue = .main,
                              progressHandler: ((Progress) -> ())?,
                              completion: @escaping (CompressionResult) -> ()) -> Compression {
                                  self.compressionOperation = Compression()
        
        guard let destinationURL else {
            completion(CompressionResult.onFailure( .init(title: "Destination URL is must")))
            return compressionOperation
        }
        
        var frameCount = 0
          
          // Compression started
          completion(.onStart)
          guard let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first else {
              let error = CompressionError(title: "Cannot find video track")
              completion(.onFailure(error))
              return compressionOperation
          }
          
          let bitrate = videoTrack.estimatedDataRate
          // Check for a min video bitrate before compression
//          if configuration.isMinBitrateCheckEnabled && bitrate <= MIN_BITRATE {
//              let error = CompressionError(title: "The provided bitrate is smaller than what is needed for compression try to set isMinBitRateEnabled to false")
//              completion(.onFailure(index, error))
//              continue
//          }
          
          // Generate a bitrate based on desired quality
          let newBitrate = getBitrate(bitrate: bitrate, quality: quality)
          
          // Handle new width and height values
          let videoSize = videoTrack.naturalSize
          
          // Total Frames
          let durationInSeconds = asset.duration.seconds
          let frameRate = videoTrack.nominalFrameRate
          let totalFrames = ceil(durationInSeconds * Double(frameRate))
          
          // Progress
          let totalUnits = Int64(totalFrames)
          let progress = Progress(totalUnitCount: totalUnits)
          
          // Setup video writer input
                                  let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: getVideoWriterSettings(bitrate: newBitrate, size: videoSize))
          videoWriterInput.expectsMediaDataInRealTime = true
          videoWriterInput.transform = videoTrack.preferredTransform
          
                                  let videoWriter = try? AVAssetWriter(outputURL: destinationURL, fileType: fileType)
          videoWriter?.add(videoWriterInput)
          
          // Setup video reader output
          let videoReaderSettings:[String : AnyObject] = [
              kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) as AnyObject
          ]
          let videoReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoReaderSettings)
          
          var videoReader: AVAssetReader?
          do {
              videoReader = try AVAssetReader(asset: asset)
          } catch {
              let compressionError = CompressionError(title: error.localizedDescription)
              completion(.onFailure(compressionError))
              return compressionOperation
          }
          
          videoReader?.add(videoReaderOutput)
          //setup audio writer
                                  let audioWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: nil)
          audioWriterInput.expectsMediaDataInRealTime = false
          videoWriter?.add(audioWriterInput)
          //setup audio reader
          let audioTrack = asset.tracks(withMediaType: AVMediaType.audio).first
          var audioReader: AVAssetReader?
          var audioReaderOutput: AVAssetReaderTrackOutput?
          if(audioTrack != nil) {
              audioReaderOutput = AVAssetReaderTrackOutput(track: audioTrack!, outputSettings: nil)
              audioReader = try? AVAssetReader(asset: asset)
              audioReader?.add(audioReaderOutput!)
          }
          videoWriter?.startWriting()
          
          //start writing from video reader
          videoReader?.startReading()
          videoWriter?.startSession(atSourceTime: CMTime.zero)
          let processingQueue = DispatchQueue(label: "processingQueue1", qos: .background)
          
          var isFirstBuffer = true
          videoWriterInput.requestMediaDataWhenReady(on: processingQueue, using: {() -> Void in
              while videoWriterInput.isReadyForMoreMediaData {
                  
                  // Observe any cancellation
                  if self.compressionOperation.cancel {
                      videoReader?.cancelReading()
                      videoWriter?.cancelWriting()
                      completion(.onCancelled)
                      return
                  }
                  
                  // Update progress based on number of processed frames
                  frameCount += 1
                  if let handler = progressHandler {
                      progress.completedUnitCount = Int64(frameCount)
                      progressQueue.async { handler(progress) }
                  }
                  
                  let sampleBuffer: CMSampleBuffer? = videoReaderOutput.copyNextSampleBuffer()
                  
                  if videoReader?.status == .reading && sampleBuffer != nil {
                      videoWriterInput.append(sampleBuffer!)
                  } else {
                      videoWriterInput.markAsFinished()
                      if videoReader?.status == .completed {
                          if audioReader != nil {
                              if !(audioReader!.status == .reading) || !(audioReader!.status == .completed) {
                                  //start writing from audio reader
                                  audioReader?.startReading()
                                  videoWriter?.startSession(atSourceTime: CMTime.zero)
                                  let processingQueue = DispatchQueue(label: "processingQueue2", qos: .background)
                                  
                                  audioWriterInput.requestMediaDataWhenReady(on: processingQueue, using: {
                                      while audioWriterInput.isReadyForMoreMediaData {
                                          let sampleBuffer: CMSampleBuffer? = audioReaderOutput?.copyNextSampleBuffer()
                                          if audioReader?.status == .reading && sampleBuffer != nil {
                                              if isFirstBuffer {
                                                  let dict = CMTimeCopyAsDictionary(CMTimeMake(value: 1024, timescale: 44100), allocator: kCFAllocatorDefault);
                                                  CMSetAttachment(sampleBuffer as CMAttachmentBearer, key: kCMSampleBufferAttachmentKey_TrimDurationAtStart, value: dict, attachmentMode: kCMAttachmentMode_ShouldNotPropagate);
                                                  isFirstBuffer = false
                                              }
                                              audioWriterInput.append(sampleBuffer!)
                                          } else {
                                              audioWriterInput.markAsFinished()
                                              
                                              videoWriter?.finishWriting {
                                                  completion(.onSuccess(destinationURL))
                                              }
                                          }
                                      }
                                  })
                              }
                          } else {
                              videoWriter?.finishWriting {
                                  completion(.onSuccess(destinationURL))
                              }
                          }
                      }
                  }
              }
          })
        
        return compressionOperation
    }
    
    private func getBitrate(bitrate: Float, quality: VideoQuality) -> Int {
        switch quality {
        case .very_high:
            return Int(bitrate * 0.6)
        case .high:
            return Int(bitrate * 0.4)
        case .medium:
            return Int(bitrate * 0.3)
        case .low:
            return Int(bitrate * 0.2)
        case .very_low:
            return Int(bitrate * 0.1)
        }
    }
    
//    private func generateWidthAndHeight(
//        width: CGFloat,
//        height: CGFloat,
//        keepOriginalResolution: Bool
//    ) -> (width: Int, height: Int) {
//        
//        if (keepOriginalResolution) {
//            return (Int(width), Int(height))
//        }
//        
//        var newWidth: Int
//        var newHeight: Int
//        
//        if width >= 1920 || height >= 1920 {
//            
//            newWidth = Int(width * 0.5 / 16) * 16
//            newHeight = Int(height * 0.5 / 16 ) * 16
//            
//        } else if width >= 1280 || height >= 1280 {
//            newWidth = Int(width * 0.75 / 16) * 16
//            newHeight = Int(height * 0.75 / 16) * 16
//        } else if width >= 960 || height >= 960 {
//            if(width > height){
//                newWidth = Int(MIN_HEIGHT * 0.95 / 16) * 16
//                newHeight = Int(MIN_WIDTH * 0.95 / 16) * 16
//            } else {
//                newWidth = Int(MIN_WIDTH * 0.95 / 16) * 16
//                newHeight = Int(MIN_HEIGHT * 0.95 / 16) * 16
//            }
//        } else {
//            newWidth = Int(width * 0.9 / 16) * 16
//            newHeight = Int(height * 0.9 / 16) * 16
//        }
//        
//        return (newWidth, newHeight)
//    }
    
    private func getVideoWriterSettings(bitrate: Int, size: CGSize) -> [String : AnyObject] {
        
        let videoWriterCompressionSettings = [
            AVVideoAverageBitRateKey : bitrate
        ]
        
        let videoWriterSettings: [String : AnyObject] = [
            AVVideoCodecKey : AVVideoCodecType.h264 as AnyObject,
            AVVideoCompressionPropertiesKey : videoWriterCompressionSettings as AnyObject,
            AVVideoWidthKey : size.width as AnyObject,
            AVVideoHeightKey : size.height as AnyObject
        ]
        
        return videoWriterSettings
    }
    
}
