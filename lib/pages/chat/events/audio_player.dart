import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:fluffychat/pangea/widgets/chat/message_audio_card.dart';
import 'package:fluffychat/utils/error_reporter.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';

import '../../../utils/matrix_sdk_extensions/event_extension.dart';

class AudioPlayerWidget extends StatefulWidget {
  final Color color;
  // #Pangea
  // final Event event;
  final Event? event;
  final PangeaAudioFile? matrixFile;
  // Pangea#

  static String? currentId;

  static const int wavesCount = 40;

  const AudioPlayerWidget(
    this.event, {
    this.color = Colors.black,
    // #Pangea
    this.matrixFile,
    // Pangea#
    super.key,
  });

  @override
  AudioPlayerState createState() => AudioPlayerState();
}

enum AudioPlayerStatus { notDownloaded, downloading, downloaded }

class AudioPlayerState extends State<AudioPlayerWidget> {
  AudioPlayerStatus status = AudioPlayerStatus.notDownloaded;
  AudioPlayer? audioPlayer;

  StreamSubscription? onAudioPositionChanged;
  StreamSubscription? onDurationChanged;
  StreamSubscription? onPlayerStateChanged;
  StreamSubscription? onPlayerError;

  String? statusText;
  int currentPosition = 0;
  double maxPosition = 0;

  MatrixFile? matrixFile;
  File? audioFile;

  @override
  void dispose() {
    if (audioPlayer?.playerState.playing == true) {
      audioPlayer?.stop();
    }
    onAudioPositionChanged?.cancel();
    onDurationChanged?.cancel();
    onPlayerStateChanged?.cancel();
    onPlayerError?.cancel();

    super.dispose();
  }

  Future<void> _downloadAction() async {
    // #Pangea
    // if (status != AudioPlayerStatus.notDownloaded) return;
    if (status != AudioPlayerStatus.notDownloaded || widget.event == null) {
      return;
    }
    // Pangea#
    setState(() => status = AudioPlayerStatus.downloading);
    try {
      // #Pangea
      // final matrixFile = await widget.event.downloadAndDecryptAttachment();
      final matrixFile = await widget.event!.downloadAndDecryptAttachment();
      // Pangea#
      File? file;

      if (!kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        final fileName = Uri.encodeComponent(
          // #Pangea
          // widget.event.attachmentOrThumbnailMxcUrl()!.pathSegments.last,
          widget.event!.attachmentOrThumbnailMxcUrl()!.pathSegments.last,
          // Pangea#
        );
        file = File('${tempDir.path}/${fileName}_${matrixFile.name}');
        await file.writeAsBytes(matrixFile.bytes);
      }

      setState(() {
        audioFile = file;
        this.matrixFile = matrixFile;
        status = AudioPlayerStatus.downloaded;
      });
      _playAction();
    } catch (e, s) {
      // #Pangea
      debugger();
      // Pangea#
      Logs().v('Could not download audio file', e, s);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toLocalizedString(context)),
        ),
      );
    }
  }

  void _playAction() async {
    final audioPlayer = this.audioPlayer ??= AudioPlayer();
    // #Pangea
    // if (AudioPlayerWidget.currentId != widget.event.eventId) {
    // Pangea#
    if (AudioPlayerWidget.currentId != widget.event?.eventId) {
      if (AudioPlayerWidget.currentId != null) {
        if (audioPlayer.playerState.playing) {
          await audioPlayer.stop();
          setState(() {});
        }
      }
      AudioPlayerWidget.currentId = widget.event?.eventId;
    }
    if (audioPlayer.playerState.playing) {
      await audioPlayer.pause();
      return;
    } else if (audioPlayer.position != Duration.zero) {
      await audioPlayer.play();
      return;
    }

    onAudioPositionChanged ??= audioPlayer.positionStream.listen((state) {
      if (maxPosition <= 0) return;
      setState(() {
        statusText =
            '${state.inMinutes.toString().padLeft(2, '0')}:${(state.inSeconds % 60).toString().padLeft(2, '0')}';
        currentPosition = ((state.inMilliseconds.toDouble() / maxPosition) *
                AudioPlayerWidget.wavesCount)
            .round();
      });
      if (state.inMilliseconds.toDouble() == maxPosition) {
        audioPlayer.stop();
        audioPlayer.seek(null);
      }
    });
    onDurationChanged ??= audioPlayer.durationStream.listen((max) {
      if (max == null || max == Duration.zero) return;
      setState(() => maxPosition = max.inMilliseconds.toDouble());
    });
    onPlayerStateChanged ??=
        audioPlayer.playingStream.listen((_) => setState(() {}));
    final audioFile = this.audioFile;
    if (audioFile != null) {
      audioPlayer.setFilePath(audioFile.path);
    } else {
      // #Pangea
      try {
        if (widget.matrixFile != null) {
          await audioPlayer.setAudioSource(
            BytesAudioSource(
              widget.matrixFile!.bytes,
              widget.matrixFile!.mimeType,
            ),
          );
        } else {
          // Pangea#
          await audioPlayer.setAudioSource(MatrixFileAudioSource(matrixFile!));
          // #Pangea
        }
      } catch (e, _) {
        debugger(when: kDebugMode);
      }
      // Pangea#
    }
    audioPlayer.play().onError(
          ErrorReporter(context, 'Unable to play audio message')
              .onErrorCallback,
        );
  }

  static const double buttonSize = 36;

  String? get _durationString {
    // #Pangea
    int? durationInt;
    if (widget.matrixFile?.duration != null) {
      durationInt = widget.matrixFile!.duration;
    } else {
      // final durationInt = widget.event?.content
      durationInt = widget.event?.content
          .tryGetMap<String, dynamic>('info')
          ?.tryGet<int>('duration');
    }
    // Pangea#
    if (durationInt == null) return null;
    final duration = Duration(milliseconds: durationInt);
    return '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  List<int> _getWaveform() {
    // #Pangea
    final eventWaveForm = widget.matrixFile?.waveform ??
        widget.event?.content
            .tryGetMap<String, dynamic>('org.matrix.msc1767.audio')
            ?.tryGetList<int>('waveform');
    // final eventWaveForm = widget.event?.content
    //     .tryGetMap<String, dynamic>('org.matrix.msc1767.audio')
    //     ?.tryGetList<int>('waveform');
    // Pangea#
    if (eventWaveForm == null || eventWaveForm.isEmpty) {
      return List<int>.filled(AudioPlayerWidget.wavesCount, 500);
    }
    while (eventWaveForm.length < AudioPlayerWidget.wavesCount) {
      for (var i = 0; i < eventWaveForm.length; i = i + 2) {
        eventWaveForm.insert(i, eventWaveForm[i]);
      }
    }
    var i = 0;
    final step = (eventWaveForm.length / AudioPlayerWidget.wavesCount).round();
    while (eventWaveForm.length > AudioPlayerWidget.wavesCount) {
      eventWaveForm.removeAt(i);
      i = (i + step) % AudioPlayerWidget.wavesCount;
    }
    return eventWaveForm.map((i) => i > 1024 ? 1024 : i).toList();
  }

  late final List<int> waveform;

  @override
  void initState() {
    super.initState();
    waveform = _getWaveform();
    // #Pangea
    if (widget.matrixFile != null) {
      if (!kIsWeb) {
        getTemporaryDirectory().then((val) {
          final tempDir = val;
          final file = File('${tempDir.path}/${widget.matrixFile!.name}');
          file.writeAsBytesSync(widget.matrixFile!.bytes);
          audioFile = file;
        });
      }
      status = AudioPlayerStatus.downloaded;
      setState(() {});
    }
    // Pangea#
  }

  @override
  Widget build(BuildContext context) {
    final statusText = this.statusText ??= _durationString ?? '00:00';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(width: 4),
          SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: status == AudioPlayerStatus.downloading
                ? CircularProgressIndicator(strokeWidth: 2, color: widget.color)
                : InkWell(
                    borderRadius: BorderRadius.circular(64),
                    child: Material(
                      color: widget.color.withAlpha(64),
                      borderRadius: BorderRadius.circular(64),
                      child: Icon(
                        audioPlayer?.playerState.playing == true
                            ? Icons.pause_outlined
                            : Icons.play_arrow_outlined,
                        color: widget.color,
                      ),
                    ),
                    onLongPress: () => widget.event?.saveFile(context),
                    onTap: () {
                      if (status == AudioPlayerStatus.downloaded) {
                        _playAction();
                      } else {
                        _downloadAction();
                      }
                    },
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < AudioPlayerWidget.wavesCount; i++)
                  Expanded(
                    child: GestureDetector(
                      onTapDown: (_) => audioPlayer?.seek(
                        Duration(
                          milliseconds:
                              (maxPosition / AudioPlayerWidget.wavesCount)
                                      .round() *
                                  i,
                        ),
                      ),
                      child: Container(
                        height: 32,
                        alignment: Alignment.center,
                        child: Opacity(
                          opacity: currentPosition > i ? 1 : 0.5,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: widget.color,
                              borderRadius: BorderRadius.circular(64),
                            ),
                            height: 32 * (waveform[i] / 1024),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            alignment: Alignment.centerRight,
            width: 42,
            child: Text(
              statusText,
              style: TextStyle(
                color: widget.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// To use a MatrixFile as an AudioSource for the just_audio package
class MatrixFileAudioSource extends StreamAudioSource {
  final MatrixFile file;
  MatrixFileAudioSource(this.file);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= file.bytes.length;
    return StreamAudioResponse(
      sourceLength: file.bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(file.bytes.sublist(start, end)),
      contentType: file.mimeType,
    );
  }
}

// #Pangea
class BytesAudioSource extends StreamAudioSource {
  final Uint8List bytes;
  final String mimeType;
  BytesAudioSource(this.bytes, this.mimeType);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: mimeType,
    );
  }
}
// Pangea#
