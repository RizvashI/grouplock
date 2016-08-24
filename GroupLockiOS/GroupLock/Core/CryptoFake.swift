//
//  CryptoFake.swift
//  GroupLock
//
//  Created by Sergej Jaskiewicz on 16.08.16.
//  Copyright © 2016 Lanit-Tercom School. All rights reserved.
//

import Foundation
import CoreGraphics
import ImageIO
import MobileCoreServices

class CryptoFake: CryptoWrapperProtocol {

    let maximumNumberOfKeys = 15

    /**
     Creates 120-digit random key and represents it as a String.

     - parameter min: Concrete value does not play a role for now
     - parameter max: Number of parts to divide the key into.

     - precondition: `max` is not greater than `maximumNumberOfKeys` and `min` is not greater than `max`

     - returns: String representation of the key
     */
    func getKeys(min: Int, max: Int) -> [String] {
        precondition(max <= maximumNumberOfKeys,
                     "Maximum number of keys provided exceeds the value of maximumNumberOfKeys")
        precondition(min <= max, "min should be less than or equal to max")

        let digitalKey = (0 ..< 40).map { _ in UInt8(arc4random_uniform(256)) }
        let stringKey = digitalKey.map { String(format: "%03d", $0) }.reduce("", +)

        return splitKey(stringKey, intoParts: max)
            .enumerated()
            .map { String(format: "%02d_%02d_", $0, max) + $1 }
    }

    private func splitKey(_ key: String, intoParts parts: Int) -> [String] {

        let splittedSize = Int(round(Double(key.characters.count) / Double(parts)))

        return (0 ..< parts - 1).map { (i: Int) -> String in
            let start = key.characters.index(key.startIndex, offsetBy: i * splittedSize)
            let end = key.characters.index(key.startIndex, offsetBy: (i + 1) * splittedSize)
            return key.substring(with: start ..< end)
            } + [key.substring(from: key.characters.index(key.startIndex, offsetBy: (parts - 1) * splittedSize))]
    }

    private func mergeKeys(_ keys: [String]) -> String {
        return keys.reduce("", +)
    }

    func validate(key: [String]) -> Bool {

        guard let processedKey = processKeys(key) else { return false }

        let parsedKey = parse(key: processedKey)
        // swiftlint:disable:next force_unwrapping (since we check for nil)
        return parsedKey != nil && parsedKey!.count > 3
    }

    func validatePart(_ key: String) -> Bool {
        let regex = try? NSRegularExpression(pattern: "[0-9]{2}_[0-9]{2}_[0-9]+", options: [])
        let stringToMatch = key as NSString
        return !(regex?.matches(in: key, options: [],
            range: NSRange(location: 0, length: stringToMatch.length)).isEmpty ?? true)
    }

    /**
     Encrypts given image with given key.

     Expands the key using linear congruential pseudorandom generator and encrypts the image
     using improved Kasenkov's cipher

     - parameter data: Image data to encrypt
     - parameter key:  Encryption key

     - precondition: `key` is at least 12 digits long.

     - returns: Encrypted data, or `nil` is something went wrong. For example, the key is invalid or the data is
     not image-representable
     */
    func encrypt(image data: Data, withEncryptionKey key: [String]) -> Data? {

        guard let mergedKey = processKeys(key),
            let parsedKey = parse(key: mergedKey),
            let cgImage = image(from: data) else { return nil }

        let expandedKey = expand(parsedKey, for: cgImage)

        let imagePixels = cgImage.pixels
        let encryptedPixels = encrypted(imagePixels, withKey: expandedKey)
        let width = cgImage.width
        let height = cgImage.height

        // swiftlint:disable:next force_unwrapping (because what can possibly go wrong)
        let encryptedImage = CGImage.fromPixels(encryptedPixels, width: width, height: height)!
        return encryptedImage.pngData
    }

    /**
     Decrypts given image with given decryption key.

     Expands the key using linear congruential pseudorandom generator and decrypts the image
     using improved Kasenkov's cipher

     - parameter data: Encrypted data
     - parameter key:  Decryption key

     - precondition: `key` is at least 12 digits long.

     - returns: Decrypted data, or `nil` is something went wrong. For example, the key is invalid or the data is
     not image-representable
     */
    func decrypt(image data: Data, withDecryptionKey key: [String]) -> Data? {

        guard let mergedKey = processKeys(key),
            let parsedKey = parse(key: mergedKey),
            let cgImage = image(from: data) else { return nil }

        let expandedKey = expand(parsedKey, for: cgImage)

        let imagePixels = cgImage.pixels
        let decryptedPixels = decrypted(imagePixels, withKey: expandedKey)
        let width = cgImage.width
        let height = cgImage.height
        let decryptedImage = CGImage.fromPixels(decryptedPixels, width: width, height: height)
        return decryptedImage?.pngData
    }

    private func processKeys(_ keys: [String]) -> String? {

        guard keys.map(validatePart).reduce(true, { $0 && $1 }) else { return nil }

        return mergeKeys(
            keys.map { $0.characters.split(separator: "_") }.map { characters -> (Int, String) in

            // swiftlint:disable:next force_unwrapping (since we validate the key)
            let number = Int(String(characters[0]))!
            let key = String(characters[2])
            return (number, key)
            }.sorted { $0.0 < $0.0 }.map { $0.1 }
        )
    }

    private func expand(_ key: [UInt8], for image: CGImage) -> [UInt8] {

        let numberOfBytes = image.height * image.bytesPerRow

        let expandingFactor = numberOfBytes / key.count + 1

        func generateExpansion(for element: UInt8) -> [UInt8] {
            let lcg = LinearCongruentialGenerator(seed: Double(element))
            let expansion: [UInt8] = (0 ..< expandingFactor).map({ _ in return UInt8(lcg.random() * 255) })
            return expansion
        }

        return key.flatMap(generateExpansion)
    }

    private func image(from data: Data) -> CGImage? {

        // swiftlint:disable:next force_unwrapping (no failure case is documented, what can possibly go wrong)
        let cgDataProvider = CGDataProvider(data: data as CFData)!
        switch getImageType(from: data) {
        case .some("JPG"):
            return CGImage(jpegDataProviderSource: cgDataProvider,
                           decode: nil,
                           shouldInterpolate: false,
                           intent: .defaultIntent)!
            // swiftlint:disable:previous force_unwrapping (since we check for type)
        case .some("PNG"):
            return CGImage(pngDataProviderSource: cgDataProvider,
                           decode: nil,
                           shouldInterpolate: false,
                           intent: .defaultIntent)!
            // swiftlint:disable:previous force_unwrapping (since we check for type)
        default:
            return nil
        }
    }

    private func getImageType(from data: Data) -> String? {

        var acc: UInt8 = 0
        data.copyBytes(to: &acc, count: 1)

        switch acc {
        case 0xFF: return "JPG"
        case 0x89: return "PNG"
        case 0x47: return "GIF"
        case 0x49, 0x4D: return "TIFF"
        default: return nil
        }
    }

    private func parse(key: String) -> [UInt8]? {

        guard !key.characters.isEmpty else { return nil }
        let digits = key.characters.map { String.init($0) }
        var parsedKey = [UInt8](repeating: 0, count: digits.count / 3)
        for i in stride(from: 0, to: digits.count, by: 3) where i + 2 < digits.count {
            if let number = UInt8(digits[i] + digits[i + 1] + digits[i + 2]) {
                parsedKey[i / 3] = number
            } else { return nil }
        }
        return parsedKey
    }

    private struct ColorOffsets {
        static let red = 234
        static let green = -132
        static let blue = 17
    }

    func decrypted(_ pixels: [Pixel], withKey key: [UInt8]) -> [Pixel] {

        precondition(key.count > 3, "key is too short")

        func decrypted(_ pixel: Pixel, inIndex index: Int, withKey key: [UInt8]) -> Pixel {

            let _red = Int(pixel.red)     + Int(key[index % (key.count - 3)    ]) + 512 - ColorOffsets.red
            let _green = Int(pixel.green) + Int(key[index % (key.count - 3) + 1]) + 512 - ColorOffsets.green
            let _blue = Int(pixel.blue)   + Int(key[index % (key.count - 3) + 2]) + 512 - ColorOffsets.blue

            let red =   UInt8(_red % 256)
            let green = UInt8(_green % 256)
            let blue =  UInt8(_blue % 256)
            return Pixel(red: red, green: green, blue: blue, alpha: pixel.alpha)
        }

        var decryptedPixels = [Pixel](repeating: Pixel(red: 0, green: 0, blue: 0, alpha: 0),
                                      count: pixels.count)
        for index in 0 ..< decryptedPixels.count {
            decryptedPixels[index] = decrypted(pixels[index], inIndex: index, withKey: key)
        }
        return decryptedPixels
    }

    private func encrypted(_ pixels: [Pixel], withKey key: [UInt8]) -> [Pixel] {

        precondition(key.count > 3, "key is too short")

        func encrypted(_ pixel: Pixel, inIndex index: Int, withKey key: [UInt8]) -> Pixel {

            let _red = Int(pixel.red)     - Int(key[index % (key.count - 3)    ]) + 512 + ColorOffsets.red
            let _green = Int(pixel.green) - Int(key[index % (key.count - 3) + 1]) + 512 + ColorOffsets.green
            let _blue = Int(pixel.blue)   - Int(key[index % (key.count - 3) + 2]) + 512 + ColorOffsets.blue

            let red =   UInt8(_red % 256)
            let green = UInt8(_green % 256)
            let blue =  UInt8(_blue % 256)
            return Pixel(red: red, green: green, blue: blue, alpha: pixel.alpha)
        }

        var encryptedPixels = [Pixel](repeating: Pixel(red: 0, green: 0, blue: 0, alpha: 0),
                                      count: pixels.count)
        for index in 0 ..< encryptedPixels.count {
            encryptedPixels[index] = encrypted(pixels[index], inIndex: index, withKey: key)
        }
        return encryptedPixels
    }
}
