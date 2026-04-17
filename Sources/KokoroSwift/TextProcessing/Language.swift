//
//  Kokoro-tts-lib
//
import Foundation

/// Supported languages for text-to-speech synthesis.
/// This enum defines the available language variants that can be used with the Kokoro TTS engine.
/// English uses MisakiSwift G2P; all other languages use eSpeak NG G2P.
public enum Language: String, CaseIterable {
  /// No language specified or language-independent processing.
  case none = ""
  /// US English (American English).
  case enUS = "en-us"
  /// GB English (British English).
  case enGB = "en-gb"
  /// Spanish.
  case es = "es"
  /// French (France).
  case frFR = "fr-fr"
  /// Hindi.
  case hi = "hi"
  /// Italian.
  case it = "it"
  /// Brazilian Portuguese.
  case ptBR = "pt-br"
  /// Mandarin Chinese (eSpeak NG uses "cmn").
  case zh = "cmn"
  /// Japanese.
  case ja = "ja"
}
