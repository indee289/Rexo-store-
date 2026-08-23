import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';

/// Service for uploading files to Cloudflare R2 (S3-compatible) storage.
/// Uses AWS Signature V4 for authentication.
class R2StorageService {
  R2StorageService._();

  static String get _accessKeyId => AppConstants.r2AccessKeyId;
  static String get _secretAccessKey => AppConstants.r2SecretAccessKey;
  static String get _accountId => AppConstants.r2AccountId;
  static String get _bucketName => AppConstants.r2BucketName;

  static String get _endpoint =>
      'https://$_accountId.r2.cloudflarestorage.com';

  /// Upload a file to R2 and return the public URL.
  ///
  /// [path] - The object key (e.g. "user-id/filename.jpg")
  /// [data] - The file bytes
  /// [contentType] - MIME type (e.g. "image/jpeg")
  ///
  /// Returns the public URL of the uploaded file.
  static Future<String> uploadFile(
    String path,
    Uint8List data,
    String contentType,
  ) async {
    final now = DateTime.now().toUtc();
    final dateStamp = _formatDateStamp(now);
    final amzDate = _formatAmzDate(now);
    final region = 'auto';
    final service = 's3';

    final url = Uri.parse('$_endpoint/$_bucketName/$path');

    final payloadHash = sha256.convert(data).toString();

    final headers = <String, String>{
      'Host': url.host,
      'x-amz-date': amzDate,
      'x-amz-content-sha256': payloadHash,
      'Content-Type': contentType,
      'Content-Length': data.length.toString(),
    };

    // Create canonical request
    final signedHeaderKeys = headers.keys.map((k) => k.toLowerCase()).toList()
      ..sort();
    final signedHeaders = signedHeaderKeys.join(';');

    final canonicalHeaders = signedHeaderKeys
        .map((k) => '$k:${headers[headers.keys.firstWhere((key) => key.toLowerCase() == k)]!.trim()}')
        .join('\n');

    final canonicalRequest = [
      'PUT',
      '/${_bucketName}/$path',
      '', // query string
      '$canonicalHeaders\n',
      signedHeaders,
      payloadHash,
    ].join('\n');

    // Create string to sign
    final credentialScope = '$dateStamp/$region/$service/aws4_request';
    final canonicalRequestHash =
        sha256.convert(utf8.encode(canonicalRequest)).toString();

    final stringToSign = [
      'AWS4-HMAC-SHA256',
      amzDate,
      credentialScope,
      canonicalRequestHash,
    ].join('\n');

    // Calculate signature
    final signingKey = _getSignatureKey(
      _secretAccessKey,
      dateStamp,
      region,
      service,
    );
    final signature = Hmac(sha256, signingKey)
        .convert(utf8.encode(stringToSign))
        .toString();

    // Build authorization header
    final authorization =
        'AWS4-HMAC-SHA256 Credential=$_accessKeyId/$credentialScope, '
        'SignedHeaders=$signedHeaders, Signature=$signature';

    headers['Authorization'] = authorization;

    // Execute PUT request
    final response = await http.put(
      url,
      headers: headers,
      body: data,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'R2 upload failed with status ${response.statusCode}: ${response.body}',
      );
    }

    // Return the PUBLIC URL when a public base is configured.
    //
    // The S3 API endpoint ($_endpoint/$_bucketName/$path) requires an
    // authenticated (SigV4-signed) request, so it is NOT viewable by an
    // <img>/CachedNetworkImage widget — that is why uploaded covers, product
    // images and avatars never rendered. When R2_PUBLIC_URL is set (the
    // bucket's public r2.dev URL or a custom domain), build the browsable URL
    // from it. Otherwise fall back to the private endpoint URL (dev only).
    final publicBase = AppConstants.r2PublicUrl.trim();
    if (publicBase.isNotEmpty) {
      final normalizedBase = publicBase.endsWith('/')
          ? publicBase.substring(0, publicBase.length - 1)
          : publicBase;
      return '$normalizedBase/$path';
    }
    return '$_endpoint/$_bucketName/$path';
  }

  /// Upload a file from a File object (convenience method).
  static Future<String> uploadFileFromBytes(
    String folder,
    String fileName,
    Uint8List data,
    String contentType,
  ) async {
    final path = '$folder/$fileName';
    return uploadFile(path, data, contentType);
  }

  static String _formatDateStamp(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String _formatAmzDate(DateTime date) {
    return '${_formatDateStamp(date)}T'
        '${date.hour.toString().padLeft(2, '0')}'
        '${date.minute.toString().padLeft(2, '0')}'
        '${date.second.toString().padLeft(2, '0')}Z';
  }

  static List<int> _getSignatureKey(
    String key,
    String dateStamp,
    String region,
    String service,
  ) {
    final kDate = Hmac(sha256, utf8.encode('AWS4$key'))
        .convert(utf8.encode(dateStamp))
        .bytes;
    final kRegion =
        Hmac(sha256, kDate).convert(utf8.encode(region)).bytes;
    final kService =
        Hmac(sha256, kRegion).convert(utf8.encode(service)).bytes;
    final kSigning =
        Hmac(sha256, kService).convert(utf8.encode('aws4_request')).bytes;
    return kSigning;
  }
}
