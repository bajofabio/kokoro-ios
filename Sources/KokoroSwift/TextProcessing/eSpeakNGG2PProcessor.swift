//
//  KokoroSwift
//

#if canImport(eSpeakNGLib)

import Foundation
import eSpeakNGLib
import MLXUtilsLibrary

/// A G2P processor that uses the eSpeak NG library for phonemization.
/// Requires the eSpeakNGLib framework to be available at compile time.
/// The eSpeak engine is initialized once and reused — only the language is switched.
final class eSpeakNGG2PProcessor : G2PProcessor {
  /// The underlying eSpeak NG engine instance.
  /// Initialized once on first setLanguage call and reused for all subsequent calls.
  private var eSpeakEngine: eSpeakNG?

  /// Configures the processor for the specified language.
  /// - Parameter language: The target language for phonemization.
  /// - Throws: `G2PProcessorError.unsupportedLanguage` if the language is not supported by eSpeak NG.
  func setLanguage(_ language: Language) throws {
    // Initialize engine once, then just switch languages
    if eSpeakEngine == nil {
      eSpeakEngine = try eSpeakNG()
    }

    if let lang = eSpeakNG.Language(rawValue: language.rawValue), let eSpeakEngine {
      try eSpeakEngine.setLanguage(language: lang)
    } else {
      throw G2PProcessorError.unsupportedLanguage
    }
  }
  
  /// Converts input text to phonetic representation.
  /// - Parameter input: The text string to be converted to phonemes.
  /// - Returns: A phonetic string representation of the input text.
  /// - Throws: `G2PProcessorError.processorNotInitialized` if `setLanguage(_:)` has not been called.
  func process(input: String) throws -> (String, [MToken]?) {
    guard let eSpeakEngine else { throw G2PProcessorError.processorNotInitialized }
    let phonemizedText = try eSpeakEngine.phonemize(text: input)
    return (phonemizedText, nil)
  }
}

#endif
