import 'route_activity.dart';

enum ShareContentType {
  runningRoute,
  gymWorkout,
  calisthenicsWorkout,
  foodDish,
  thumbsUp,
}

enum InboxMessageStatus { pending, accepted, rejected }

ShareContentType? shareContentTypeFromString(String? raw) {
  switch (raw) {
    case 'runningRoute':
      return ShareContentType.runningRoute;
    case 'gymWorkout':
      return ShareContentType.gymWorkout;
    case 'calisthenicsWorkout':
      return ShareContentType.calisthenicsWorkout;
    case 'foodDish':
      return ShareContentType.foodDish;
    case 'thumbsUp':
      return ShareContentType.thumbsUp;
    default:
      return null;
  }
}

String shareContentTypeToString(ShareContentType type) {
  switch (type) {
    case ShareContentType.runningRoute:
      return 'runningRoute';
    case ShareContentType.gymWorkout:
      return 'gymWorkout';
    case ShareContentType.calisthenicsWorkout:
      return 'calisthenicsWorkout';
    case ShareContentType.foodDish:
      return 'foodDish';
    case ShareContentType.thumbsUp:
      return 'thumbsUp';
  }
}

InboxMessageStatus? inboxMessageStatusFromString(String? raw) {
  switch (raw) {
    case 'pending':
      return InboxMessageStatus.pending;
    case 'accepted':
      return InboxMessageStatus.accepted;
    case 'rejected':
      return InboxMessageStatus.rejected;
    default:
      return null;
  }
}

String inboxMessageStatusToString(InboxMessageStatus status) {
  switch (status) {
    case InboxMessageStatus.pending:
      return 'pending';
    case InboxMessageStatus.accepted:
      return 'accepted';
    case InboxMessageStatus.rejected:
      return 'rejected';
  }
}

class FriendConnection {
  const FriendConnection({
    required this.uid,
    required this.displayName,
    required this.friendCode,
    required this.notifyOnRunStart,
    required this.connectedAt,
  });

  final String uid;
  final String displayName;
  final String friendCode;
  final bool notifyOnRunStart;
  final DateTime connectedAt;

  FriendConnection copyWith({
    String? uid,
    String? displayName,
    String? friendCode,
    bool? notifyOnRunStart,
    DateTime? connectedAt,
  }) {
    return FriendConnection(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      friendCode: friendCode ?? this.friendCode,
      notifyOnRunStart: notifyOnRunStart ?? this.notifyOnRunStart,
      connectedAt: connectedAt ?? this.connectedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'displayName': displayName,
    'friendCode': friendCode,
    'notifyOnRunStart': notifyOnRunStart,
    'connectedAt': connectedAt.toIso8601String(),
  };

  factory FriendConnection.fromJson(Map<String, dynamic> json) {
    return FriendConnection(
      uid: json['uid']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? 'Friend',
      friendCode: json['friendCode']?.toString() ?? '',
      notifyOnRunStart: json['notifyOnRunStart'] == true,
      connectedAt:
          DateTime.tryParse(json['connectedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class FriendRequest {
  const FriendRequest({
    required this.uid,
    required this.displayName,
    required this.friendCode,
    required this.createdAt,
  });
  final String uid, displayName, friendCode;
  final DateTime createdAt;
  Map<String, dynamic> toJson() => {
    'uid': uid,
    'displayName': displayName,
    'friendCode': friendCode,
    'createdAt': createdAt.toIso8601String(),
  };
  factory FriendRequest.fromJson(Map<String, dynamic> json) => FriendRequest(
    uid: json['uid']?.toString() ?? '',
    displayName: json['displayName']?.toString() ?? 'Friend',
    friendCode: json['friendCode']?.toString() ?? '',
    createdAt:
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime(1970),
  );
}

class FriendLiveRun {
  const FriendLiveRun({
    required this.uid,
    required this.displayName,
    required this.routeId,
    required this.routeName,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.currentPaceSecPerKm,
    required this.avgPaceSecPerKm,
    required this.recordedPoints,
    required this.plannedPoints,
    required this.startedAt,
    required this.updatedAt,
    this.recordedPointTimestamps = const [],
    this.paused = false,
    this.positionUpdatedAt,
  });

  final String uid;
  final String displayName;
  final String routeId;
  final String routeName;
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final double? currentPaceSecPerKm;
  final double? avgPaceSecPerKm;
  final List<List<double>> recordedPoints;
  final List<List<double>> plannedPoints;

  /// Epoch milliseconds parallel to [recordedPoints], used to fade older trail segments.
  final List<int> recordedPointTimestamps;
  final DateTime startedAt;
  final DateTime updatedAt;
  final bool paused;
  final DateTime? positionUpdatedAt;

  bool get isStale =>
      DateTime.now().difference(updatedAt) > const Duration(minutes: 2);

  bool get positionIsStale =>
      DateTime.now().difference(positionUpdatedAt ?? updatedAt) >
      const Duration(seconds: 30);

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'displayName': displayName,
    'routeId': routeId,
    'routeName': routeName,
    'latitude': latitude,
    'longitude': longitude,
    'distanceMeters': distanceMeters,
    'currentPaceSecPerKm': currentPaceSecPerKm,
    'avgPaceSecPerKm': avgPaceSecPerKm,
    'recordedPoints': recordedPoints,
    'recordedPointTimestamps': recordedPointTimestamps,
    'plannedPoints': plannedPoints,
    'startedAt': startedAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'paused': paused,
    'positionUpdatedAt': positionUpdatedAt?.toIso8601String(),
  };

  factory FriendLiveRun.fromJson(Map<String, dynamic> json) {
    List<List<double>> decodePoints(dynamic raw) {
      if (raw is! List) return const [];
      final out = <List<double>>[];
      for (final entry in raw) {
        if (entry is List && entry.length >= 2) {
          final lat = (entry[0] as num?)?.toDouble();
          final lon = (entry[1] as num?)?.toDouble();
          if (lat != null && lon != null) out.add([lat, lon]);
        }
      }
      return out;
    }

    return FriendLiveRun(
      uid: json['uid']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? 'Friend',
      routeId: json['routeId']?.toString() ?? '',
      routeName: json['routeName']?.toString() ?? 'Run',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0,
      currentPaceSecPerKm: (json['currentPaceSecPerKm'] as num?)?.toDouble(),
      avgPaceSecPerKm: (json['avgPaceSecPerKm'] as num?)?.toDouble(),
      recordedPoints: decodePoints(json['recordedPoints']),
      recordedPointTimestamps: json['recordedPointTimestamps'] is List
          ? (json['recordedPointTimestamps'] as List)
                .whereType<num>()
                .map((value) => value.toInt())
                .toList(growable: false)
          : const [],
      plannedPoints: decodePoints(json['plannedPoints']),
      startedAt:
          DateTime.tryParse(json['startedAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      paused: json['paused'] == true,
      positionUpdatedAt: DateTime.tryParse(
        json['positionUpdatedAt']?.toString() ?? '',
      ),
    );
  }
}

/// A finished activity its owner explicitly shared with signed-in members.
class CommunityRun {
  const CommunityRun({
    required this.id,
    required this.uid,
    required this.displayName,
    required this.routeName,
    required this.distanceMeters,
    required this.ascentMeters,
    required this.points,
    required this.createdAt,
    this.activity,
  });

  final String id;
  final String uid;
  final String displayName;
  final String routeName;
  final double distanceMeters;
  final double ascentMeters;
  final List<List<double>> points;
  final DateTime createdAt;
  final RouteActivity? activity;
}

class MonthlyChallengeProgress {
  const MonthlyChallengeProgress({
    required this.uid,
    required this.displayName,
    required this.monthKey,
    required this.count,
    required this.updatedAt,
  });

  final String uid;
  final String displayName;
  final String monthKey;
  final int count;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'displayName': displayName,
    'monthKey': monthKey,
    'count': count,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory MonthlyChallengeProgress.fromJson(Map<String, dynamic> json) {
    final rawCount = json['count'];
    return MonthlyChallengeProgress(
      uid: json['uid']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? 'Friend',
      monthKey: json['monthKey']?.toString() ?? '',
      count: rawCount is int
          ? rawCount
          : int.tryParse(rawCount?.toString() ?? '') ?? 0,
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class InboxMessage {
  const InboxMessage({
    required this.id,
    required this.fromUid,
    required this.fromName,
    required this.type,
    required this.payload,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String fromUid;
  final String fromName;
  final ShareContentType type;
  final Map<String, dynamic> payload;
  final InboxMessageStatus status;
  final DateTime createdAt;

  bool get isPending => status == InboxMessageStatus.pending;

  InboxMessage copyWith({
    String? id,
    String? fromUid,
    String? fromName,
    ShareContentType? type,
    Map<String, dynamic>? payload,
    InboxMessageStatus? status,
    DateTime? createdAt,
  }) {
    return InboxMessage(
      id: id ?? this.id,
      fromUid: fromUid ?? this.fromUid,
      fromName: fromName ?? this.fromName,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromUid': fromUid,
    'fromName': fromName,
    'type': shareContentTypeToString(type),
    'payload': payload,
    'status': inboxMessageStatusToString(status),
    'createdAt': createdAt.toIso8601String(),
  };

  factory InboxMessage.fromJson(Map<String, dynamic> json) {
    return InboxMessage(
      id: json['id']?.toString() ?? '',
      fromUid: json['fromUid']?.toString() ?? '',
      fromName: json['fromName']?.toString() ?? 'Friend',
      type:
          shareContentTypeFromString(json['type']?.toString()) ??
          ShareContentType.gymWorkout,
      payload: json['payload'] is Map
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : const {},
      status:
          inboxMessageStatusFromString(json['status']?.toString()) ??
          InboxMessageStatus.pending,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
