import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'AudioManager.dart';
import 'diary_summary_screens.dart';

final logger = Logger(printer: PrettyPrinter());

void configureAndroidPhotoPicker() {
  final ImagePickerPlatform imagePickerImplementation = ImagePickerPlatform.instance;
  if (imagePickerImplementation is ImagePickerAndroid) {
    imagePickerImplementation.useAndroidPhotoPicker = true;
  }
}

abstract class AddPhotoEvent {}

class AddPhotos extends AddPhotoEvent {}

class RemovePhoto extends AddPhotoEvent {
  final int index;
  RemovePhoto(this.index);
}

class TogglePlayPause extends AddPhotoEvent {}

class ChangeVolume extends AddPhotoEvent {
  final double volume;
  ChangeVolume(this.volume);
}

class CreateDiary extends AddPhotoEvent {}

class AddPhotoState {
  final List<File> imageFiles;
  final bool isPlaying;
  final double volume;
  final String userId;
  final String? error;
  final bool navigateToSummary;
  final int? diaryCode;
  final bool isUploading;

  const AddPhotoState({
    required this.imageFiles,
    required this.isPlaying,
    required this.volume,
    this.userId = "",
    this.error,
    this.navigateToSummary = false,
    this.diaryCode,
    this.isUploading = false,
  });

  AddPhotoState copyWith({
    List<File>? imageFiles,
    bool? isPlaying,
    double? volume,
    String? userId,
    String? error,
    bool? navigateToSummary,
    int? diaryCode,
    bool? isUploading,
  }) {
    return AddPhotoState(
      imageFiles: imageFiles ?? this.imageFiles,
      isPlaying: isPlaying ?? this.isPlaying,
      volume: volume ?? this.volume,
      userId: userId ?? this.userId,
      error: error ?? this.error,
      navigateToSummary: navigateToSummary ?? this.navigateToSummary,
      diaryCode: diaryCode ?? this.diaryCode,
      isUploading: isUploading ?? this.isUploading,
    );
  }
}

class AddPhotoBloc extends Bloc<AddPhotoEvent, AddPhotoState> {
  final AudioManager audioManager;
  final String transcription;
  final int diaryCode;

  AddPhotoBloc({required this.audioManager, required this.transcription, required this.diaryCode})
      : super(AddPhotoState(
    imageFiles: [],
    isPlaying: audioManager.player.playing,
    volume: audioManager.player.volume,
    diaryCode: diaryCode,
  )) {
    on<AddPhotos>(_onAddPhotos);
    on<RemovePhoto>(_onRemovePhoto);
    on<TogglePlayPause>(_onTogglePlayPause);
    on<ChangeVolume>(_onChangeVolume);
    on<CreateDiary>(_onCreateDiary);
    _fetchUserId();
  }

  Future<void> _onAddPhotos(AddPhotos event, Emitter<AddPhotoState> emit) async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> pickedFiles = await picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        final newFiles = pickedFiles.map((xFile) => File(xFile.path)).toList();
        final updatedFiles = List<File>.from(state.imageFiles)..addAll(newFiles);
        emit(state.copyWith(imageFiles: updatedFiles));
      }
    } catch (e) {
      logger.e('Error adding photos: $e');
      emit(state.copyWith(error: 'Failed to add photos: $e'));
    }
  }

  void _onRemovePhoto(RemovePhoto event, Emitter<AddPhotoState> emit) {
    final updatedFiles = List<File>.from(state.imageFiles)..removeAt(event.index);
    emit(state.copyWith(imageFiles: updatedFiles));
  }

  void _onTogglePlayPause(TogglePlayPause event, Emitter<AddPhotoState> emit) {
    final isPlaying = audioManager.player.playing;
    if (isPlaying) {
      audioManager.player.pause();
    } else {
      audioManager.player.play();
    }
    emit(state.copyWith(isPlaying: !isPlaying));
  }

  void _onChangeVolume(ChangeVolume event, Emitter<AddPhotoState> emit) {
    audioManager.player.setVolume(event.volume);
    emit(state.copyWith(volume: event.volume));
  }

  Future<void> _fetchUserId() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final memberResponse = await Supabase.instance.client
          .from('member')
          .select('member_id')
          .eq('member_id', user.id)
          .single();
      emit(state.copyWith(userId: memberResponse['member_id']));
    }
  }

  Future<void> _onCreateDiary(CreateDiary event, Emitter<AddPhotoState> emit) async {
    emit(state.copyWith(isUploading: true));
    try {
      await _uploadImages();
      audioManager.player.setVolume(0);
      emit(state.copyWith(navigateToSummary: true, isUploading: false));
    } catch (e) {
      logger.e('일기 생성 중 오류 발생: $e');
      emit(state.copyWith(error: '일기 생성 실패: $e', isUploading: false));
    }
  }

  Future<void> _uploadImages() async {
    final url = Uri.parse('http://43.203.173.116:8080/api/images/upload');
    var request = http.MultipartRequest('POST', url);

    request.fields['diaryCode'] = state.diaryCode.toString();

    if (state.imageFiles.isNotEmpty) {
      logger.i('이미지 업로드 시작: ${state.imageFiles.length}개의 파일');

      for (var i = 0; i < state.imageFiles.length; i++) {
        var file = state.imageFiles[i];
        var stream = http.ByteStream(file.openRead());
        var length = await file.length();

        var extension = path.extension(file.path).toLowerCase();
        var mimeType = _getMimeType(extension);

        var multipartFile = http.MultipartFile(
          'images',
          stream,
          length,
          filename: path.basename(file.path),
          contentType: mimeType,
        );

        request.files.add(multipartFile);
        logger.d('파일 추가됨: ${multipartFile.filename}, MIME 타입: ${mimeType.mimeType}');
      }
    } else {
      logger.i('이미지가 없습니다. diaryCode만 전송합니다.');
    }

    try {
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        logger.i('요청 성공: ${response.statusCode}, 응답: $responseBody');
      } else {
        logger.e('요청 실패: ${response.statusCode}, 응답: $responseBody');
        throw Exception('요청 실패: ${response.statusCode}, $responseBody');
      }
    } catch (e) {
      logger.e('요청 중 오류 발생: $e');
      rethrow;
    }
  }
}

MediaType _getMimeType(String extension) {
  switch (extension) {
    case '.jpg':
    case '.jpeg':
      return MediaType('image', 'jpeg');
    case '.png':
      return MediaType('image', 'png');
    case '.gif':
      return MediaType('image', 'gif');
    case '.bmp':
      return MediaType('image', 'bmp');
    case '.webp':
      return MediaType('image', 'webp');
    default:
      return MediaType('application', 'octet-stream');
  }
}


class AddPhotoScreen extends StatelessWidget {
  final String transcription;
  final int diaryCode;

  const AddPhotoScreen({Key? key, required this.transcription, required this.diaryCode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AddPhotoView(transcription: transcription);
  }
}

class AddPhotoView extends StatelessWidget {
  final String transcription;

  const AddPhotoView({Key? key, required this.transcription}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddPhotoBloc, AddPhotoState>(
      listener: (context, state) {
        if (state.navigateToSummary) {
          final diaryCode = state.diaryCode;

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => DiarySummaryScreen(
                userId: state.userId,
                transcription: transcription,
                imageFiles: state.imageFiles,
                diaryCode: diaryCode!,
              ),
            ),
          );
          context.read<AddPhotoBloc>().emit(state.copyWith(navigateToSummary: false));
        }
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: _buildAppBar(context, state),
          body: _buildBody(context, state),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, AddPhotoState state) {
    return AppBar(
      backgroundColor: const Color(0xfffdfbf0),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Image.asset(
        'assets/wisely-diary-logo.png',
        height: 30,
        fit: BoxFit.contain,
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: () => context.read<AddPhotoBloc>().add(TogglePlayPause()),
        ),
        SizedBox(
          width: 100,
          child: Slider(
            value: state.volume,
            min: 0.0,
            max: 1.0,
            onChanged: (newVolume) => context.read<AddPhotoBloc>().add(ChangeVolume(newVolume)),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, AddPhotoState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPhotoButtonWithInstruction(context),
          const SizedBox(height: 40),
          _buildCreateDiaryButton(context),
        ],
      ),
    );
  }

  Widget _buildPhotoButtonWithInstruction(BuildContext context) {
    return Column(
      children: [
        Text(
          '이미지를 첨부하려면 눌러주세요.',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => context.read<AddPhotoBloc>().add(AddPhotos()),
          child: Image.asset(
            'assets/File plus.png',
            height: 100,
            width: 100,
          ),
        ),
      ],
    );
  }

  Widget _buildTopButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => context.read<AddPhotoBloc>().add(AddPhotos()),
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('사진 추가'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => context.read<AddPhotoBloc>().add(CreateDiary()),
              child: const Text('일기 생성하기'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(BuildContext context, AddPhotoState state) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: state.imageFiles.length,
      itemBuilder: (context, index) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(state.imageFiles[index], fit: BoxFit.cover),
            Positioned(
              top: 5,
              right: 5,
              child: GestureDetector(
                onTap: () => context.read<AddPhotoBloc>().add(RemovePhoto(index)),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 20, color: Colors.red),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  Widget _buildCreateDiaryButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ElevatedButton(
        onPressed: () => context.read<AddPhotoBloc>().add(CreateDiary()),
        child: const Text('일기 생성하기'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          textStyle: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}