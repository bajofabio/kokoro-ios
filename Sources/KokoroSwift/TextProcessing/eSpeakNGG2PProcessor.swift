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
/// For Japanese, kanji is pre-converted to hiragana via CFStringTokenizer before
/// passing to eSpeak (which handles kana but not kanji).
final class eSpeakNGG2PProcessor : G2PProcessor {
  /// The underlying eSpeak NG engine instance.
  /// Initialized once on first setLanguage call and reused for all subsequent calls.
  private var eSpeakEngine: eSpeakNG?

  /// Currently active language (for Japanese pre-processing detection).
  private var currentLanguage: Language = .none

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
      currentLanguage = language
    } else {
      throw G2PProcessorError.unsupportedLanguage
    }
  }

  /// Converts input text to phonetic representation.
  /// For Japanese, kanji is converted to hiragana first using Apple's CFStringTokenizer.
  /// - Parameter input: The text string to be converted to phonemes.
  /// - Returns: A phonetic string representation of the input text.
  /// - Throws: `G2PProcessorError.processorNotInitialized` if `setLanguage(_:)` has not been called.
  func process(input: String) throws -> (String, [MToken]?) {
    guard let eSpeakEngine else { throw G2PProcessorError.processorNotInitialized }

    let textToPhonemize: String
    if currentLanguage == .ja {
      textToPhonemize = Self.kanjiToHiragana(input)
    } else {
      textToPhonemize = input
    }

    let phonemizedText = try eSpeakEngine.phonemize(text: textToPhonemize)
    return (phonemizedText, nil)
  }

  // MARK: - Japanese Kanji → Hiragana

  /// Converts Japanese text containing kanji to hiragana using Apple's built-in
  /// CFStringTokenizer. This allows eSpeak NG to phonemize Japanese correctly
  /// (eSpeak handles kana but not kanji — it would say "Chinese character" instead).
  ///
  /// Uses a two-step process: kanji → romaji (via CFStringTokenizer) → hiragana
  /// (via StringTransform). Preserves punctuation and whitespace.
  private static func kanjiToHiragana(_ text: String) -> String {
    let cfText = text as CFString
    let length = CFStringGetLength(cfText)
    guard length > 0 else { return text }

    let locale = Locale(identifier: "ja_JP") as CFLocale
    guard let tokenizer = CFStringTokenizerCreate(
      kCFAllocatorDefault,
      cfText,
      CFRangeMake(0, length),
      kCFStringTokenizerUnitWord,
      locale
    ) else { return text }

    var result = ""
    var lastEnd = 0

    while true {
      let tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
      if tokenType.isEmpty { break }

      let range = CFStringTokenizerGetCurrentTokenRange(tokenizer)
      let tokenStart = range.location
      let tokenEnd = range.location + range.length

      // Append any characters between tokens (punctuation, whitespace)
      if tokenStart > lastEnd {
        let startIdx = text.index(text.startIndex, offsetBy: lastEnd)
        let endIdx = text.index(text.startIndex, offsetBy: tokenStart)
        result += String(text[startIdx..<endIdx])
      }

      // Get the reading for this token
      if let latin = CFStringTokenizerCopyCurrentTokenAttribute(
        tokenizer,
        kCFStringTokenizerAttributeLatinTranscription
      ) as? String {
        // Convert romaji to hiragana
        if let hiragana = latin.applyingTransform(.latinToHiragana, reverse: false) {
          result += hiragana
        } else {
          result += latin
        }
      } else {
        // No reading available — keep original (likely already kana or punctuation)
        let startIdx = text.index(text.startIndex, offsetBy: tokenStart)
        let endIdx = text.index(text.startIndex, offsetBy: tokenEnd)
        result += String(text[startIdx..<endIdx])
      }

      lastEnd = tokenEnd
    }

    // Append any trailing characters
    if lastEnd < text.count {
      let startIdx = text.index(text.startIndex, offsetBy: lastEnd)
      result += String(text[startIdx...])
    }

    return result
  }
}

#endif
