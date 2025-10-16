//
//  AESEncryption.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/15/25.
//

import Foundation
import CommonCrypto

struct AES128CBC {
    /// AES128 CBC 암호화
//    static func encrypt(_ text: String, key: String, iv: String) -> String? {
//        guard let dataToEncrypt = text.data(using: .utf8),
//              let keyData = key.data(using: .utf8),
//              let ivData = iv.data(using: .utf8) else { return nil } //  //IV(Initialization Vector)는 CBC 모드에서 사용하는 “초기화 벡터” (리프레시 토큰 처럼 주기적 변경이 필요함, 하지만 아두이노쪽에서 처리하기
//
//        // 🔹 패딩 제거 — "\0" 대신 " " (공백) 또는 실제 패딩바이트로 채우기
//        var padded = dataToEncrypt
//        let blockSize = 16
//        let paddingNeeded = blockSize - (dataToEncrypt.count % blockSize)
//        if paddingNeeded > 0 && paddingNeeded < blockSize {
//            padded.append(contentsOf: [UInt8](repeating: UInt8(paddingNeeded), count: paddingNeeded))
//        }
//
//        let bufferSize = padded.count + kCCBlockSizeAES128
//        var buffer = Data(count: bufferSize)
//        var numBytesEncrypted: size_t = 0
//
//        let status = buffer.withUnsafeMutableBytes { bufferPtr in
//            padded.withUnsafeBytes { dataPtr in
//                keyData.withUnsafeBytes { keyPtr in
//                    ivData.withUnsafeBytes { ivPtr in
//                        CCCrypt(CCOperation(kCCEncrypt),
//                                CCAlgorithm(kCCAlgorithmAES128),
//                                CCOptions(0),
//                                keyPtr.baseAddress, kCCKeySizeAES128,
//                                ivPtr.baseAddress,
//                                dataPtr.baseAddress, padded.count,
//                                bufferPtr.baseAddress, bufferSize,
//                                &numBytesEncrypted)
//                    }
//                }
//            }
//        }
//
//        guard status == kCCSuccess else {
//            print("❌ AES Encrypt Failed:", status)
//            return nil
//        }
//
//        let encryptedData = buffer.prefix(numBytesEncrypted)
//        return encryptedData.base64EncodedString()
//    }
    
    static func encrypt(_ text: String, key: String, iv: String) -> String? {
        guard let dataToEncrypt = text.data(using: .utf8),
              let keyData = key.data(using: .utf8),
              let ivData = iv.data(using: .utf8) else { return nil }

        let bufferSize = dataToEncrypt.count + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)
        var numBytesEncrypted: size_t = 0

        let cryptStatus = buffer.withUnsafeMutableBytes { bufferPtr in
            dataToEncrypt.withUnsafeBytes { dataPtr in
                keyData.withUnsafeBytes { keyPtr in
                    ivData.withUnsafeBytes { ivPtr in
                        CCCrypt(
                            CCOperation(kCCEncrypt),
                            CCAlgorithm(kCCAlgorithmAES128),
                            // ✅ PKCS7 Padding 활성화
                            CCOptions(kCCOptionPKCS7Padding),
                            keyPtr.baseAddress, kCCKeySizeAES128,
                            ivPtr.baseAddress,
                            dataPtr.baseAddress, dataToEncrypt.count,
                            bufferPtr.baseAddress, bufferSize,
                            &numBytesEncrypted
                        )
                    }
                }
            }
        }

        print("🔹 평문 바이트 수:", dataToEncrypt.count)
        print("🔹 블록 크기 단위로 자동 패딩됨 (PKCS7)")

        if cryptStatus == kCCSuccess {
            let encryptedData = buffer.prefix(numBytesEncrypted)
            return encryptedData.base64EncodedString()
        } else {
            print("❌ AES Encryption Failed: \(cryptStatus)")
            return nil
        }
    }
    /// AES128 CBC 복호화
    static func decrypt(_ encryptedData: Data, key: String, iv: String) -> String? {
        guard let keyData = key.data(using: .utf8),
              let ivData = iv.data(using: .utf8) else { return nil }

        let bufferSize = encryptedData.count + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)
        var numBytesDecrypted: size_t = 0

        let cryptStatus = buffer.withUnsafeMutableBytes { bufferPtr in
            encryptedData.withUnsafeBytes { encryptedPtr in
                keyData.withUnsafeBytes { keyPtr in
                    ivData.withUnsafeBytes { ivPtr in
                        CCCrypt(
                            CCOperation(kCCDecrypt),
                            CCAlgorithm(kCCAlgorithmAES128),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyPtr.baseAddress, kCCKeySizeAES128,
                            ivPtr.baseAddress,
                            encryptedPtr.baseAddress, encryptedData.count,
                            bufferPtr.baseAddress, bufferSize,
                            &numBytesDecrypted
                        )
                    }
                }
            }
        }

        if cryptStatus == kCCSuccess {
            return String(data: buffer.prefix(numBytesDecrypted), encoding: .utf8)
        } else {
            print("❌ AES Decrypt Failed:", cryptStatus)
            return nil
        }
    }
}
