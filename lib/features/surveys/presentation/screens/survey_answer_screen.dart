import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/survey.dart';
import '../../providers/surveys_provider.dart';

class SurveyAnswerScreen extends ConsumerStatefulWidget {
  const SurveyAnswerScreen({super.key, required this.surveyId});

  final int surveyId;

  @override
  ConsumerState<SurveyAnswerScreen> createState() => _SurveyAnswerScreenState();
}

class _SurveyAnswerScreenState extends ConsumerState<SurveyAnswerScreen> {
  final _pageController = PageController();

  int _currentPage = 0;
  bool _submitted = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  // answers: question_id → value (String for single/text, List<String> for multiple)
  final Map<int, dynamic> _answers = {};

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── Navigación ────────────────────────────────────────────────────────────────

  void _next(List<SurveyQuestion> questions) {
    if (!_validateCurrent(questions[_currentPage])) return;
    if (_currentPage < questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _showConfirmDialog(questions);
    }
  }

  void _prev() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrent(SurveyQuestion question) {
    final answer = _answers[question.id];
    if (answer == null) {
      setState(() => _errorMessage = 'Por favor responde esta pregunta.');
      return false;
    }
    if (answer is String && answer.trim().isEmpty) {
      setState(() => _errorMessage = 'Por favor responde esta pregunta.');
      return false;
    }
    if (answer is List && answer.isEmpty) {
      setState(() => _errorMessage = 'Selecciona al menos una opción.');
      return false;
    }
    setState(() => _errorMessage = null);
    return true;
  }

  // ── Confirmación y envío ───────────────────────────────────────────────────────

  Future<void> _showConfirmDialog(List<SurveyQuestion> questions) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar respuestas'),
        content: const Text(
          'Una vez enviadas, tus respuestas no podrán modificarse. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Revisar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirm == true) await _submit(questions);
  }

  Future<void> _submit(List<SurveyQuestion> questions) async {
    // Validate all
    for (final q in questions) {
      if (!_validateCurrent(q)) {
        // Jump to first unanswered question
        final idx = questions.indexOf(q);
        _pageController.jumpToPage(idx);
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final payload = questions.map((q) {
      final val = _answers[q.id];
      return {'question_id': q.id, 'value': val};
    }).toList();

    try {
      await ref
          .read(surveysProvider.notifier)
          .respond(widget.surveyId, payload);
      if (mounted) setState(() => _submitted = true);
    } on DioException catch (e) {
      if (!mounted) return;
      final statusCode = e.response?.statusCode;
      if (statusCode == 409) {
        // Already responded — treat as success
        setState(() => _submitted = true);
        return;
      }
      final msg = (e.response?.data as Map?)?['message'] as String? ??
          'No se pudo enviar la respuesta. Intenta de nuevo.';
      setState(() => _errorMessage = msg);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Error inesperado. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final asyncSurvey = ref.watch(surveyDetailProvider(widget.surveyId));

    return asyncSurvey.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Cargando…')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 48),
              const SizedBox(height: 12),
              const Text('No se pudo cargar la encuesta.'),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                onPressed: () =>
                    ref.invalidate(surveyDetailProvider(widget.surveyId)),
              ),
            ],
          ),
        ),
      ),
      data: (survey) {
        final questions = survey.questions ?? [];

        if (_submitted) return _SuccessView(survey: survey);

        if (questions.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(survey.title)),
            body: const Center(child: Text('Esta encuesta no tiene preguntas.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(survey.title),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(6),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / questions.length,
                minHeight: 5,
              ),
            ),
          ),
          body: Column(
            children: [
              // Contador de pregunta
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Text(
                      'Pregunta ${_currentPage + 1} de ${questions.length}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                    const Spacer(),
                    if (survey.isAnonymous)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility_off_outlined,
                            size: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Anónima',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Error de validación
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

              // Preguntas
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) =>
                      setState(() {
                        _currentPage = i;
                        _errorMessage = null;
                      }),
                  itemCount: questions.length,
                  itemBuilder: (context, i) =>
                      _QuestionPage(
                        question: questions[i],
                        answer: _answers[questions[i].id],
                        onChanged: (val) => setState(() {
                          _answers[questions[i].id] = val;
                          _errorMessage = null;
                        }),
                      ),
                ),
              ),

              // Botones de navegación
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.arrow_back, size: 18),
                            label: const Text('Anterior'),
                            onPressed: _isSubmitting ? null : _prev,
                          ),
                        ),
                      if (_currentPage > 0) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          icon: _isSubmitting
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  _currentPage < questions.length - 1
                                      ? Icons.arrow_forward
                                      : Icons.send_outlined,
                                  size: 18,
                                ),
                          label: Text(
                            _currentPage < questions.length - 1
                                ? 'Siguiente'
                                : 'Enviar respuestas',
                          ),
                          onPressed: _isSubmitting
                              ? null
                              : () => _next(questions),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Página de una pregunta ────────────────────────────────────────────────────

class _QuestionPage extends StatelessWidget {
  const _QuestionPage({
    required this.question,
    required this.answer,
    required this.onChanged,
  });

  final SurveyQuestion question;
  final dynamic answer;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Texto de la pregunta
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.text,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  question.typeLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Input según tipo
          if (question.isSingle) _SingleChoice(question: question, answer: answer, onChanged: onChanged),
          if (question.isMultiple) _MultipleChoice(question: question, answer: answer, onChanged: onChanged),
          if (question.isText) _TextAnswer(answer: answer, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ── Opción única ───────────────────────────────────────────────────────────────

class _SingleChoice extends StatelessWidget {
  const _SingleChoice({
    required this.question,
    required this.answer,
    required this.onChanged,
  });
  final SurveyQuestion question;
  final dynamic answer;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = question.options ?? [];
    return Column(
      children: options.map((opt) {
        final selected = answer == opt;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: selected
                ? BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : BorderSide.none,
          ),
          child: RadioListTile<String>(
            title: Text(opt, style: const TextStyle(fontSize: 14)),
            value: opt,
            groupValue: answer as String?,
            onChanged: (_) => onChanged(opt),
            activeColor: Theme.of(context).colorScheme.primary,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          ),
        );
      }).toList(),
    );
  }
}

// ── Opción múltiple ────────────────────────────────────────────────────────────

class _MultipleChoice extends StatelessWidget {
  const _MultipleChoice({
    required this.question,
    required this.answer,
    required this.onChanged,
  });
  final SurveyQuestion question;
  final dynamic answer;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = question.options ?? [];
    final selected = (answer as List?)?.cast<String>() ?? <String>[];

    return Column(
      children: options.map((opt) {
        final isChecked = selected.contains(opt);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: isChecked
                ? BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : BorderSide.none,
          ),
          child: CheckboxListTile(
            title: Text(opt, style: const TextStyle(fontSize: 14)),
            value: isChecked,
            onChanged: (checked) {
              final next = List<String>.from(selected);
              if (checked == true) {
                next.add(opt);
              } else {
                next.remove(opt);
              }
              onChanged(next);
            },
            activeColor: Theme.of(context).colorScheme.primary,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          ),
        );
      }).toList(),
    );
  }
}

// ── Texto libre ────────────────────────────────────────────────────────────────

class _TextAnswer extends StatefulWidget {
  const _TextAnswer({required this.answer, required this.onChanged});
  final dynamic answer;
  final ValueChanged<dynamic> onChanged;

  @override
  State<_TextAnswer> createState() => _TextAnswerState();
}

class _TextAnswerState extends State<_TextAnswer> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.answer as String? ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      maxLines: 5,
      minLines: 3,
      maxLength: 1000,
      decoration: InputDecoration(
        hintText: 'Escribe tu respuesta aquí…',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        alignLabelWithHint: true,
      ),
      onChanged: widget.onChanged,
    );
  }
}

// ── Pantalla de éxito ──────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.survey});
  final Survey survey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(survey.title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 64,
                  color: Color(0xFF059669),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '¡Gracias por participar!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Tus respuestas han sido registradas${survey.isAnonymous ? ' de forma anónima' : ''}.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 36),
              FilledButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver a encuestas'),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/surveys');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
