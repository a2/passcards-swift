import CLibreSSL
import Foundation

func ECKeys(from privateKey: String) -> (privateKey: String, publicKey: String)? {
    guard var privateKeyData = privateKey.data(using: .utf8) else {
        return nil
    }

    let bp = privateKeyData.withUnsafeMutableBytes { ptr in
        BIO_new_mem_buf(UnsafeMutableRawPointer(ptr), Int32(privateKeyData.count))
    }

    var pKey = EVP_PKEY_new()
    defer { EVP_PKEY_free(pKey) }

    PEM_read_bio_PrivateKey(bp, &pKey, nil, nil)
    BIO_free(bp)

    let ecKey = EVP_PKEY_get1_EC_KEY(pKey)
    defer { EC_KEY_free(ecKey) }

    EC_KEY_set_conv_form(ecKey, POINT_CONVERSION_UNCOMPRESSED)

    var pub: UnsafeMutablePointer<UInt8>? = nil
    let pubLen = i2o_ECPublicKey(ecKey, &pub)
    let publicData = Data(buffer: UnsafeBufferPointer(start: pub, count: Int(pubLen)))

    let privBN = EC_KEY_get0_private_key(ecKey)
    let privLen = (BN_num_bits(privBN) + 7) / 8
    var privateData = Data(count: Int(privLen) + 1)
    privateData.withUnsafeMutableBytes { pointer in
        _ = BN_bn2bin(privBN, pointer.advanced(by: 1))
    }

    return (privateData.base64EncodedString(), publicData.base64EncodedString())
}
