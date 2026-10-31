import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paimana/core/config/app_config.dart';
import 'package:paimana/features/ai_assistant/presentation/providers/ai_assistant_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum _AiAction {
  order('Order extraction', 'order-extraction', Icons.receipt_long_rounded),
  measurements(
    'Measurements',
    'measurement-extraction',
    Icons.straighten_rounded,
  ),
  design('Design ideas', 'design-suggestions', Icons.palette_outlined),
  fabric('Fabric estimate', 'fabric-calculator', Icons.texture_rounded),
  price('Price estimate', 'price-estimator', Icons.sell_outlined),
  delivery(
    'Delivery estimate',
    'delivery-prediction',
    Icons.local_shipping_outlined,
  ),
  message(
    'WhatsApp message',
    'whatsapp-message',
    Icons.chat_bubble_outline_rounded,
  ),
  insights('Business insights', 'business-dashboard', Icons.insights_rounded);

  const _AiAction(this.title, this.endpoint, this.icon);

  final String title;
  final String endpoint;
  final IconData icon;
}

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _promptController = TextEditingController();
  final _resultController = TextEditingController();
  final _speech = SpeechToText();
  _AiAction _action = _AiAction.order;
  bool _isLoading = false;
  bool _isListening = false;
  bool _speechAvailable = false;
  String? _errorMessage;

  @override
  void dispose() {
    _promptController.dispose();
    _resultController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 23),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'A thoughtful assistant for the details. Review every suggestion before using it.',
                  style: TextStyle(height: 1.45, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 21),
        Text('Choose a tool', style: theme.textTheme.titleMedium),
        const SizedBox(height: 11),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: _AiAction.values.map((action) {
            return ChoiceChip(
              avatar: Icon(action.icon, size: 17),
              label: Text(action.title),
              selected: action == _action,
              onSelected: (_) => setState(() {
                _action = action;
                _errorMessage = null;
              }),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _promptController,
          minLines: 5,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            alignLabelWithHint: true,
            labelText: 'Describe the order or question',
            hintText:
                'Example: Navy blue three-piece suit for Sana, ready in two weeks. Add lace to the sleeves.',
            suffixIcon: IconButton(
              tooltip: _isListening ? 'Stop voice input' : 'Speak your request',
              onPressed: _isListening ? _stopListening : _startListening,
              icon: Icon(
                _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              ),
            ),
          ),
        ),
        if (_isListening) ...[
          const SizedBox(height: 9),
          const Row(
            children: [
              SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 9),
              Text('Listening…'),
            ],
          ),
        ],
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _isLoading ? null : _runAssistant,
          icon: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome_rounded),
          label: Text(_isLoading ? 'Thinking…' : 'Generate suggestion'),
        ),
        if (_resultController.text.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Review and edit',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Copy suggestion',
                onPressed: () => Clipboard.setData(
                  ClipboardData(text: _resultController.text),
                ),
                icon: const Icon(Icons.copy_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _resultController,
            minLines: 5,
            maxLines: 12,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              alignLabelWithHint: true,
              hintText: 'The result will appear here for you to review.',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This suggestion is not saved automatically.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _runAssistant() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      setState(() => _errorMessage = 'Describe what you need help with first.');
      return;
    }
    if (!AppConfig.hasApi) {
      setState(
        () => _errorMessage =
            'AI needs your backend URL. Configure API_BASE_URL and restart the app.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final suggestion = await ref.read(aiAssistantProvider.notifier).run(
        action: _action.endpoint,
        prompt: prompt,
      );
      if (!mounted) return;
     setState(() => _resultController.text = _toReadable(suggestion));
    } on DioException catch (error) {
      if (!mounted) return;
      final responseMessage = error.response?.data;
      setState(() {
        _errorMessage =
            responseMessage is Map && responseMessage['message'] is String
            ? responseMessage['message'] as String
            : error.message ?? 'The assistant could not reach your server.';
      });
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startListening() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isListening = false;
              _errorMessage = error.errorMsg;
            });
          }
        },
      );
      if (!_speechAvailable) {
        setState(() => _errorMessage = 'Speech recognition is not available.');
        return;
      }
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          _promptController.text = result.recognizedWords;
          _promptController.selection = TextSelection.collapsed(
            offset: _promptController.text.length,
          );
          if (mounted) setState(() {});
        },
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(minutes: 2),
          pauseFor: const Duration(seconds: 4),
          listenMode: ListenMode.dictation,
        ),
      );
    } on Exception catch (error) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _errorMessage = 'Could not start speech recognition: $error';
        });
      }
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (mounted) setState(() => _isListening = false);
  }
}
String _toReadable(String raw) {
  var text = raw.trim();
  text = text
      .replaceAll(RegExp(r'^```[a-zA-Z]*\s*'), '')
      .replaceAll(RegExp(r'\s*```$'), '')
      .trim();
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map) return _formatValue(decoded, 0).trim();
  } catch (_) {}
  return text;
}

String _label(String key) {
  final spaced = key.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (m) => '${m[1]} ${m[2]}',
  );
  if (spaced.isEmpty) return key;
  return spaced[0].toUpperCase() + spaced.substring(1).toLowerCase();
}

String _formatValue(dynamic value, int depth) {
  final pad = '  ' * depth;
  if (value is Map) {
    final buffer = StringBuffer();
    value.forEach((key, v) {
      final label = _label(key.toString());
      if (v is Map) {
        buffer.writeln('$pad$label:');
        buffer.write(_formatValue(v, depth + 1));
      } else {
        buffer.writeln('$pad$label: ${_formatLeaf(v)}');
      }
    });
    return buffer.toString();
  }
  return '$pad${_formatLeaf(value)}\n';
}

String _formatLeaf(dynamic v) {
  if (v == null) return 'Not provided';
  if (v is List) return v.isEmpty ? 'None' : v.map(_formatLeaf).join(', ');
  return v.toString();
}
