import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skillsconnect/TPO/Model/tpo_video_model.dart';

import 'video_event.dart';
import 'video_state.dart';

class VideoBloc extends Bloc<VideoEvent, VideoState> {
  VideoBloc() : super(VideoInitial()) {
    on<LoadVideos>((event, emit) async {
      emit(VideoLoading());
      try {
        // Simulated fetch delay
        await Future.delayed(Duration(seconds: 1));

        final videos = [
          VideoModel(title: "Live Interview Mock Test – Real Questions"),
          VideoModel(title: "Job in Embedded Systems – Full Interview"),
          VideoModel(title: "Interview Secrets from a Senior Developer"),
        ];

        emit(VideoLoaded(videos));
      } catch (e) {
        emit(VideoError("Failed to load videos."));
      }
    });
  }
}
