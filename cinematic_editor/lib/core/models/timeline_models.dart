// lib/core/models/timeline_models.dart
// بنية البيانات الكاملة لكل عناصر التايم لاين
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

// ════════════════════════════════════════
// VideoClip
// ════════════════════════════════════════
class VideoClip extends Equatable {
  final String id;
  final String originalPath;
  final String proxyPath;
  final double startTime;
  final double endTime;
  final double clipStartOffset;
  final double clipEndOffset;
  final int trackIndex;
  final double volume;
  final double speed;
  final List<VideoEffect> effects;
  final VideoTransform transform;
  final String? thumbnailPath;
  final bool isMuted;
  final ClipType clipType;

  const VideoClip({
    required this.id,
    required this.originalPath,
    required this.proxyPath,
    required this.startTime,
    required this.endTime,
    required this.clipStartOffset,
    required this.clipEndOffset,
    required this.trackIndex,
    this.volume = 1.0,
    this.speed  = 1.0,
    this.effects = const [],
    required this.transform,
    this.thumbnailPath,
    this.isMuted  = false,
    this.clipType = ClipType.video,
  });

  factory VideoClip.create({
    required String originalPath,
    required String proxyPath,
    required double startTime,
    required double duration,
    int trackIndex = 0,
  }) {
    return VideoClip(
      id: const Uuid().v4(),
      originalPath: originalPath,
      proxyPath: proxyPath,
      startTime: startTime,
      endTime: startTime + duration,
      clipStartOffset: 0.0,
      clipEndOffset: duration,
      trackIndex: trackIndex,
      transform: VideoTransform.identity(),
    );
  }

  double get duration => endTime - startTime;
  double get contentDuration => clipEndOffset - clipStartOffset;

  VideoClip copyWith({
    String? id, String? originalPath, String? proxyPath,
    double? startTime, double? endTime,
    double? clipStartOffset, double? clipEndOffset,
    int? trackIndex, double? volume, double? speed,
    List<VideoEffect>? effects, VideoTransform? transform,
    String? thumbnailPath, bool? isMuted, ClipType? clipType,
  }) => VideoClip(
    id: id ?? this.id,
    originalPath: originalPath ?? this.originalPath,
    proxyPath: proxyPath ?? this.proxyPath,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    clipStartOffset: clipStartOffset ?? this.clipStartOffset,
    clipEndOffset: clipEndOffset ?? this.clipEndOffset,
    trackIndex: trackIndex ?? this.trackIndex,
    volume: volume ?? this.volume,
    speed: speed ?? this.speed,
    effects: effects ?? this.effects,
    transform: transform ?? this.transform,
    thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    isMuted: isMuted ?? this.isMuted,
    clipType: clipType ?? this.clipType,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'originalPath': originalPath, 'proxyPath': proxyPath,
    'startTime': startTime, 'endTime': endTime,
    'clipStartOffset': clipStartOffset, 'clipEndOffset': clipEndOffset,
    'trackIndex': trackIndex, 'volume': volume, 'speed': speed,
    'effects': effects.map((e) => e.toJson()).toList(),
    'transform': transform.toJson(),
    'thumbnailPath': thumbnailPath, 'isMuted': isMuted,
    'clipType': clipType.name,
  };

  factory VideoClip.fromJson(Map<String, dynamic> j) => VideoClip(
    id: j['id'] as String,
    originalPath: j['originalPath'] as String,
    proxyPath: j['proxyPath'] as String,
    startTime: (j['startTime'] as num).toDouble(),
    endTime: (j['endTime'] as num).toDouble(),
    clipStartOffset: (j['clipStartOffset'] as num).toDouble(),
    clipEndOffset: (j['clipEndOffset'] as num).toDouble(),
    trackIndex: j['trackIndex'] as int,
    volume: (j['volume'] as num).toDouble(),
    speed: (j['speed'] as num).toDouble(),
    effects: (j['effects'] as List)
        .map((e) => VideoEffect.fromJson(e as Map<String, dynamic>)).toList(),
    transform: VideoTransform.fromJson(j['transform'] as Map<String, dynamic>),
    thumbnailPath: j['thumbnailPath'] as String?,
    isMuted: j['isMuted'] as bool,
    clipType: ClipType.values.byName(j['clipType'] as String),
  );

  @override
  List<Object?> get props => [id, startTime, endTime, effects, transform];
}

enum ClipType { video, image, solidColor }

// ════════════════════════════════════════
// VideoTransform
// ════════════════════════════════════════
class VideoTransform extends Equatable {
  final double x, y, scaleX, scaleY, rotation, opacity;
  const VideoTransform({
    required this.x, required this.y,
    required this.scaleX, required this.scaleY,
    required this.rotation, required this.opacity,
  });
  factory VideoTransform.identity() =>
      const VideoTransform(x:0,y:0,scaleX:1,scaleY:1,rotation:0,opacity:1);

  Map<String,dynamic> toJson() =>
      {'x':x,'y':y,'scaleX':scaleX,'scaleY':scaleY,'rotation':rotation,'opacity':opacity};

  factory VideoTransform.fromJson(Map<String,dynamic> j) => VideoTransform(
    x:(j['x'] as num).toDouble(), y:(j['y'] as num).toDouble(),
    scaleX:(j['scaleX'] as num).toDouble(), scaleY:(j['scaleY'] as num).toDouble(),
    rotation:(j['rotation'] as num).toDouble(), opacity:(j['opacity'] as num).toDouble(),
  );

  VideoTransform copyWith({double? x,double? y,double? scaleX,double? scaleY,
    double? rotation,double? opacity}) => VideoTransform(
    x:x??this.x, y:y??this.y, scaleX:scaleX??this.scaleX,
    scaleY:scaleY??this.scaleY, rotation:rotation??this.rotation,
    opacity:opacity??this.opacity,
  );
  @override List<Object?> get props => [x,y,scaleX,scaleY,rotation,opacity];
}

// ════════════════════════════════════════
// VideoEffect
// ════════════════════════════════════════
class VideoEffect extends Equatable {
  final String id;
  final EffectType type;
  final Map<String,dynamic> parameters;
  final bool isEnabled;

  const VideoEffect({
    required this.id, required this.type,
    required this.parameters, this.isEnabled = true,
  });

  factory VideoEffect.create({
    required EffectType type,
    Map<String,dynamic> parameters = const {},
  }) => VideoEffect(id: const Uuid().v4(), type: type, parameters: parameters);

  Map<String,dynamic> toJson() =>
      {'id':id,'type':type.name,'parameters':parameters,'isEnabled':isEnabled};

  factory VideoEffect.fromJson(Map<String,dynamic> j) => VideoEffect(
    id: j['id'] as String,
    type: EffectType.values.byName(j['type'] as String),
    parameters: Map<String,dynamic>.from(j['parameters'] as Map),
    isEnabled: j['isEnabled'] as bool,
  );

  VideoEffect copyWith({String? id,EffectType? type,
    Map<String,dynamic>? parameters,bool? isEnabled}) => VideoEffect(
    id:id??this.id, type:type??this.type,
    parameters:parameters??this.parameters, isEnabled:isEnabled??this.isEnabled,
  );
  @override List<Object?> get props => [id,type,parameters,isEnabled];
}

enum EffectType {
  colorGrade, blur, sharpen, brightness, contrast, saturation,
  temperature, vignette, filmGrain, glitch, chromaKey,
  backgroundRemoval, motionTracking, stabilization, speedRamp,
  lumaKey,
}

// ════════════════════════════════════════
// AudioClip
// ════════════════════════════════════════
class AudioClip extends Equatable {
  final String id;
  final String filePath;
  final double startTime, endTime, audioOffset;
  final double volume, fadeInDuration, fadeOutDuration;
  final int trackIndex;
  final bool isMuted;
  final AudioType audioType;

  const AudioClip({
    required this.id, required this.filePath,
    required this.startTime, required this.endTime,
    required this.audioOffset,
    this.volume = 1.0, this.fadeInDuration = 0.0, this.fadeOutDuration = 0.0,
    required this.trackIndex, this.isMuted = false,
    this.audioType = AudioType.music,
  });

  factory AudioClip.create({
    required String filePath, required double startTime,
    required double duration, int trackIndex = 1,
    AudioType audioType = AudioType.music,
  }) => AudioClip(
    id: const Uuid().v4(), filePath: filePath,
    startTime: startTime, endTime: startTime + duration,
    audioOffset: 0.0, trackIndex: trackIndex, audioType: audioType,
  );

  double get duration => endTime - startTime;

  Map<String,dynamic> toJson() => {
    'id':id,'filePath':filePath,'startTime':startTime,'endTime':endTime,
    'audioOffset':audioOffset,'volume':volume,
    'fadeInDuration':fadeInDuration,'fadeOutDuration':fadeOutDuration,
    'trackIndex':trackIndex,'isMuted':isMuted,'audioType':audioType.name,
  };

  factory AudioClip.fromJson(Map<String,dynamic> j) => AudioClip(
    id:j['id'] as String, filePath:j['filePath'] as String,
    startTime:(j['startTime'] as num).toDouble(),
    endTime:(j['endTime'] as num).toDouble(),
    audioOffset:(j['audioOffset'] as num).toDouble(),
    volume:(j['volume'] as num).toDouble(),
    fadeInDuration:(j['fadeInDuration'] as num).toDouble(),
    fadeOutDuration:(j['fadeOutDuration'] as num).toDouble(),
    trackIndex:j['trackIndex'] as int,
    isMuted:j['isMuted'] as bool,
    audioType:AudioType.values.byName(j['audioType'] as String),
  );

  AudioClip copyWith({
    String? id,String? filePath,double? startTime,double? endTime,
    double? audioOffset,double? volume,double? fadeInDuration,
    double? fadeOutDuration,int? trackIndex,bool? isMuted,AudioType? audioType,
  }) => AudioClip(
    id:id??this.id, filePath:filePath??this.filePath,
    startTime:startTime??this.startTime, endTime:endTime??this.endTime,
    audioOffset:audioOffset??this.audioOffset, volume:volume??this.volume,
    fadeInDuration:fadeInDuration??this.fadeInDuration,
    fadeOutDuration:fadeOutDuration??this.fadeOutDuration,
    trackIndex:trackIndex??this.trackIndex,
    isMuted:isMuted??this.isMuted, audioType:audioType??this.audioType,
  );
  @override List<Object?> get props =>
      [id,filePath,startTime,endTime,volume,trackIndex,isMuted];
}

enum AudioType { music, voiceOver, soundEffect, videoAudio }

// ════════════════════════════════════════
// TextLayer
// ════════════════════════════════════════
class TextLayer extends Equatable {
  final String id, text;
  final double startTime, endTime;
  final TextStyle style;
  final VideoTransform transform;
  final TextAnimation animation;
  final bool isSubtitle;

  const TextLayer({
    required this.id, required this.text,
    required this.startTime, required this.endTime,
    required this.style, required this.transform,
    required this.animation, this.isSubtitle = false,
  });

  factory TextLayer.create({
    required String text, required double startTime, double duration = 3.0,
  }) => TextLayer(
    id: const Uuid().v4(), text: text,
    startTime: startTime, endTime: startTime + duration,
    style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 24,
        fontWeight: FontWeight.bold),
    transform: const VideoTransform(x:0,y:0.8,scaleX:1,scaleY:1,rotation:0,opacity:1),
    animation: TextAnimation.fadeInOut,
  );

  double get duration => endTime - startTime;

  Map<String,dynamic> toJson() => {
    'id':id,'text':text,'startTime':startTime,'endTime':endTime,
    'styleColor':style.color?.value,'styleFontSize':style.fontSize,
    'styleFontWeight':style.fontWeight?.index,
    'transform':transform.toJson(),'animation':animation.name,'isSubtitle':isSubtitle,
  };

  factory TextLayer.fromJson(Map<String,dynamic> j) => TextLayer(
    id:j['id'] as String, text:j['text'] as String,
    startTime:(j['startTime'] as num).toDouble(),
    endTime:(j['endTime'] as num).toDouble(),
    style: TextStyle(
      color: Color(j['styleColor'] as int),
      fontSize: (j['styleFontSize'] as num).toDouble(),
      fontWeight: FontWeight.values[j['styleFontWeight'] as int],
    ),
    transform: VideoTransform.fromJson(j['transform'] as Map<String,dynamic>),
    animation: TextAnimation.values.byName(j['animation'] as String),
    isSubtitle: j['isSubtitle'] as bool,
  );

  TextLayer copyWith({
    String? id,String? text,double? startTime,double? endTime,
    TextStyle? style,VideoTransform? transform,
    TextAnimation? animation,bool? isSubtitle,
  }) => TextLayer(
    id:id??this.id, text:text??this.text,
    startTime:startTime??this.startTime, endTime:endTime??this.endTime,
    style:style??this.style, transform:transform??this.transform,
    animation:animation??this.animation, isSubtitle:isSubtitle??this.isSubtitle,
  );
  @override List<Object?> get props => [id,text,startTime,endTime,style,transform];
}

enum TextAnimation { none, fadeIn, fadeOut, fadeInOut, slideIn, typewriter, pop }

// ════════════════════════════════════════
// ProjectSettings
// ════════════════════════════════════════
class ProjectSettings extends Equatable {
  final String resolution, aspectRatio, colorProfile;
  final double frameRate;

  const ProjectSettings({
    required this.resolution, required this.frameRate,
    required this.aspectRatio, required this.colorProfile,
  });

  factory ProjectSettings.defaultSettings() => const ProjectSettings(
    resolution:'1080p', frameRate:30.0, aspectRatio:'9:16', colorProfile:'sRGB',
  );

  Map<String,dynamic> toJson() => {
    'resolution':resolution,'frameRate':frameRate,
    'aspectRatio':aspectRatio,'colorProfile':colorProfile,
  };
  factory ProjectSettings.fromJson(Map<String,dynamic> j) => ProjectSettings(
    resolution:j['resolution'] as String,
    frameRate:(j['frameRate'] as num).toDouble(),
    aspectRatio:j['aspectRatio'] as String,
    colorProfile:j['colorProfile'] as String,
  );
  @override List<Object?> get props => [resolution,frameRate,aspectRatio,colorProfile];
}

// ════════════════════════════════════════
// TimelineState
// ════════════════════════════════════════
class TimelineState extends Equatable {
  final String projectId;
  final List<VideoClip> videoClips;
  final List<AudioClip> audioClips;
  final List<TextLayer> textLayers;
  final double totalDuration;
  final int videoTrackCount, audioTrackCount;
  final ProjectSettings settings;

  const TimelineState({
    required this.projectId,
    required this.videoClips, required this.audioClips,
    required this.textLayers, required this.totalDuration,
    required this.videoTrackCount, required this.audioTrackCount,
    required this.settings,
  });

  factory TimelineState.empty(String projectId) => TimelineState(
    projectId: projectId, videoClips: const [], audioClips: const [],
    textLayers: const [], totalDuration: 0.0,
    videoTrackCount: 2, audioTrackCount: 3,
    settings: ProjectSettings.defaultSettings(),
  );

  Map<String,dynamic> toJson() => {
    'projectId':projectId,
    'videoClips':videoClips.map((c)=>c.toJson()).toList(),
    'audioClips':audioClips.map((c)=>c.toJson()).toList(),
    'textLayers':textLayers.map((t)=>t.toJson()).toList(),
    'totalDuration':totalDuration,
    'videoTrackCount':videoTrackCount,'audioTrackCount':audioTrackCount,
    'settings':settings.toJson(),
  };

  factory TimelineState.fromJson(Map<String,dynamic> j) => TimelineState(
    projectId: j['projectId'] as String,
    videoClips: (j['videoClips'] as List)
        .map((c) => VideoClip.fromJson(c as Map<String,dynamic>)).toList(),
    audioClips: (j['audioClips'] as List)
        .map((c) => AudioClip.fromJson(c as Map<String,dynamic>)).toList(),
    textLayers: (j['textLayers'] as List)
        .map((t) => TextLayer.fromJson(t as Map<String,dynamic>)).toList(),
    totalDuration: (j['totalDuration'] as num).toDouble(),
    videoTrackCount: j['videoTrackCount'] as int,
    audioTrackCount: j['audioTrackCount'] as int,
    settings: ProjectSettings.fromJson(j['settings'] as Map<String,dynamic>),
  );

  TimelineState copyWith({
    String? projectId, List<VideoClip>? videoClips,
    List<AudioClip>? audioClips, List<TextLayer>? textLayers,
    double? totalDuration, int? videoTrackCount, int? audioTrackCount,
    ProjectSettings? settings,
  }) => TimelineState(
    projectId: projectId ?? this.projectId,
    videoClips: videoClips ?? this.videoClips,
    audioClips: audioClips ?? this.audioClips,
    textLayers: textLayers ?? this.textLayers,
    totalDuration: totalDuration ?? this.totalDuration,
    videoTrackCount: videoTrackCount ?? this.videoTrackCount,
    audioTrackCount: audioTrackCount ?? this.audioTrackCount,
    settings: settings ?? this.settings,
  );

  @override List<Object?> get props =>
      [projectId, videoClips, audioClips, textLayers, totalDuration];
}
