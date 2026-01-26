
import 'package:skillsconnect/TPO/Model/tpo_video_model.dart';

abstract class VideoState {}

class VideoInitial extends VideoState {}

class VideoLoading extends VideoState {}

class VideoLoaded extends VideoState {
  final List<VideoModel> videos;

  VideoLoaded(this.videos);
}

class VideoError extends VideoState {
  final String message;

  VideoError(this.message);
}
