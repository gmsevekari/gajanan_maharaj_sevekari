import 'package:cloud_firestore/cloud_firestore.dart';

class TypoReport {
  final String id;
  final String contentPath;
  final String contentTitle;
  final String contentType;
  final String deityId;
  final String typoText;
  final String suggestedCorrection;
  final String deviceId;
  final DateTime timestamp;

  const TypoReport({
    required this.id,
    required this.contentPath,
    required this.contentTitle,
    required this.contentType,
    required this.deityId,
    required this.typoText,
    required this.suggestedCorrection,
    required this.deviceId,
    required this.timestamp,
  });

  factory TypoReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TypoReport(
      id: doc.id,
      contentPath: data['contentPath'] ?? '',
      contentTitle: data['contentTitle'] ?? '',
      contentType: data['contentType'] ?? '',
      deityId: data['deityId'] ?? '',
      typoText: data['typoText'] ?? '',
      suggestedCorrection: data['suggestedCorrection'] ?? '',
      deviceId: data['deviceId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'contentPath': contentPath,
      'contentTitle': contentTitle,
      'contentType': contentType,
      'deityId': deityId,
      'typoText': typoText,
      'suggestedCorrection': suggestedCorrection,
      'deviceId': deviceId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
